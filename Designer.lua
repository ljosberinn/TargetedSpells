---@type string, TargetedSpells
local _, Private = ...

-- Standalone, movable layout designer (Platynator-style). A self-contained
-- ButtonFrameTemplate dialog on UIParent — NOT an edit-mode overlay, and it does
-- not touch LibEditMode. This file holds the frame/UI; the model (schemas,
-- defaults, scratch copies) lives in Design.lua / Groups.lua.
--
-- Phase 5 lands incrementally:
--   step 2  outer window scaffold (title, drag, Esc-close)          [done]
--   step 3  group tabs, one per group, labelled by group.Name       [done]
--   step 4  InsetFrameTemplate canvas                               [done]
--   step 5+ looping demo frame, selection, schema-driven widgets    [pending]

local FRAME_WIDTH = 760
local FRAME_HEIGHT = 520

-- seconds per looping demo cast in the canvas
local DEMO_CAST_TIME = 6

---@class TargetedSpellsDesignerFrame : Frame
local DesignerMixin = {}

-- Group ids in ascending order — the tab order and the "first group" fallback.
---@return integer[]
function DesignerMixin:SortedGroupIds()
	local ids = {}
	for id in pairs(TargetedSpellsSaved.Groups) do
		ids[#ids + 1] = id
	end
	table.sort(ids)
	return ids
end

-- Rebuilds the tab strip from the current group list. Called on show and whenever
-- groups are renamed/created/deleted while the designer is open. Tabs come from a
-- pool, so this is cheap to re-run wholesale.
function DesignerMixin:RebuildTabs()
	self.tabPool:ReleaseAll()
	table.wipe(self.tabs)

	local ids = self:SortedGroupIds()
	local previousTab

	for _, id in ipairs(ids) do
		local group = TargetedSpellsSaved.Groups[id]
		local tab = self.tabPool:Acquire()

		tab:SetID(id)
		tab:SetText(group.Name)
		tab:SetScript("OnClick", function(clickedTab)
			self:SelectGroup(clickedTab:GetID())
		end)
		tab:Show()
		PanelTemplates_TabResize(tab, 0)

		tab:ClearAllPoints()
		if previousTab then
			tab:SetPoint("TOPLEFT", previousTab, "TOPRIGHT", 3, 0)
		else
			tab:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 11, 2)
		end

		previousTab = tab
		self.tabs[id] = tab
	end

	-- keep the current selection if its group still exists, else fall back to the
	-- first group (there is always at least one)
	if self.selectedGroupId == nil or self.tabs[self.selectedGroupId] == nil then
		self.selectedGroupId = ids[1]
	end

	self:SelectGroup(self.selectedGroupId)
end

-- Selects a group's tab: marks the tab active, takes a fresh scratch copy of that
-- group's Elements (edits mutate the copy, not the live group, until Apply — the
-- Apply/Cancel lifecycle lands in step 8) and refreshes the canvas.
---@param groupId integer
function DesignerMixin:SelectGroup(groupId)
	local group = groupId and TargetedSpellsSaved.Groups[groupId]
	if group == nil then
		return
	end

	self.selectedGroupId = groupId

	for id, tab in pairs(self.tabs) do
		if id == groupId then
			PanelTemplates_SelectTab(tab)
		else
			PanelTemplates_DeselectTab(tab)
		end
	end

	self.scratchTemplate = group.Template
	self.scratchElements = Private.Design.CopyElements(group.Elements)

	self:RefreshCanvas()
end

-- The pool a group's demo frame comes from, following its current template.
---@param group TargetedSpellsGroup
function DesignerMixin:GroupPool(group)
	if group.Template == Private.Enum.Template.Icon then
		return Private.Utils.Pools.Icon
	end

	return Private.Utils.Pools.Bar
end

-- Redraws the canvas for the current selection by restarting the looping demo. The
-- template (hence pool) can differ between groups, so the frame is released and
-- re-acquired rather than reused across a tab switch.
function DesignerMixin:RefreshCanvas()
	self:EndDemo()
	self:StartDemo()
	self:BuildMarkers()
end

-- Acquires a single demo frame from the selected group's pool, parents it into the
-- canvas centred on its core element, and drives a looping cast. Crucially it
-- renders from the scratch Elements copy via SetLayoutOverride — not the group's
-- saved layout — so later widget edits preview before Apply (v4 plan step 3a).
function DesignerMixin:StartDemo()
	local group = self.selectedGroupId and TargetedSpellsSaved.Groups[self.selectedGroupId]
	if group == nil or not self:IsShown() then
		return
	end

	self.demoPool = self:GroupPool(group)
	self.demoFrame = self.demoPool:Acquire()

	self.demoFrame:SetGroup(group)
	self.demoFrame:SetLayoutOverride(self.scratchElements)
	self.demoFrame:SetParent(self.Preview)
	self.demoFrame:ClearAllPoints()
	self.demoFrame:SetPoint("CENTER", self.Preview, "CENTER", 0, 0)
	self.demoFrame:SetFrameStrata(self.Preview:GetFrameStrata())
	self.demoFrame:SetFrameLevel(self.Preview:GetFrameLevel() + 5)

	self:PlayDemoCast()

	-- restart the cast a beat after each one finishes, so the preview keeps looping
	self.demoTicker = C_Timer.NewTicker(DEMO_CAST_TIME + 1, function()
		self:PlayDemoCast()
	end)
end

-- One demo cast on the current demo frame (reused across loops, like the edit-mode
-- demo). A player "cast" of unbounded duration with a random preview colour/marker.
function DesignerMixin:PlayDemoCast()
	if self.demoFrame == nil then
		return
	end

	local duration = C_DurationUtil.CreateDuration()
	duration:SetTimeFromStart(GetTime(), DEMO_CAST_TIME)

	self.demoFrame:PostCreate({
		unit = "player",
		spellId = nil,
		startTime = GetTime(),
		id = 1,
		duration = duration,
		isChannel = false,
	})

	self.demoFrame:Show()
	self.demoFrame:SetAlpha(secretwrap(1))

	-- bar demo frames get their preview colour + a random raid marker
	if self.demoFrame.SetPreviewBarColor then
		self.demoFrame:SetPreviewBarColor()
		self.demoFrame:SetTargetMarker(Private.Utils.RollDice() and math.random(1, 8) or nil)
	end

	local group = self.selectedGroupId and TargetedSpellsSaved.Groups[self.selectedGroupId]
	if group ~= nil and group.GlowImportant then
		self.demoFrame:ShowGlow(secretwrap(true))
	else
		self.demoFrame:HideGlow()
	end
end

-- Stops the loop and returns the demo frame to its pool (Reset reparents it to
-- UIParent and clears the layout override). Only ever releases our own frame.
function DesignerMixin:EndDemo()
	if self.demoTicker ~= nil then
		self.demoTicker:Cancel()
		self.demoTicker = nil
	end

	if self.demoFrame ~= nil then
		self.demoPool:Release(self.demoFrame)
		self.demoFrame = nil
	end
end

-- ── Element selection ────────────────────────────────────────────────────────
-- Markers are mouse-enabled buttons floating over the preview at each element's
-- CENTER→CENTER offset, computed from the scratch record (never from the live
-- frame's regions). Elements with no spatial footprint (welded / active-only, e.g.
-- Overlay / Background / Cooldown) get no marker — they are reachable from the
-- panel once step 7's element list lands.

-- The marker rectangle for an element record, or nil for a footprint-less element.
---@param record table<string, any>
function DesignerMixin:ElementMarkerRect(record)
	local x = record.x or 0
	local y = record.y or 0

	if record.width ~= nil and record.height ~= nil then
		return x, y, record.width, record.height
	end

	if record.fontSize ~= nil then
		-- text element: no stored size, so use a nominal clickable box (maxWidth if
		-- the user has capped it, else a default) scaled to the font.
		local width = (record.maxWidth ~= nil and record.maxWidth > 0) and record.maxWidth or 120
		return x, y, width, record.fontSize * 1.8
	end

	return nil
end

-- Lazily builds a marker's visuals on first acquire: a mouseover fill (auto-shown
-- on the HIGHLIGHT layer) and a gold selection border of four thin solid edges
-- (no authored art — SetColorTexture only), hidden until the marker is selected.
---@param marker Button
function DesignerMixin:EnsureMarkerVisuals(marker)
	if marker.SelectedBorder ~= nil then
		return
	end

	marker:RegisterForClicks("LeftButtonUp")

	local highlight = marker:CreateTexture(nil, "HIGHLIGHT")
	highlight:SetAllPoints()
	highlight:SetColorTexture(1, 1, 1, 0.10)

	marker.SelectedBorder = {}
	local edges = {
		{ points = { "TOPLEFT", "TOPRIGHT" }, height = 2 },
		{ points = { "BOTTOMLEFT", "BOTTOMRIGHT" }, height = 2 },
		{ points = { "TOPLEFT", "BOTTOMLEFT" }, width = 2 },
		{ points = { "TOPRIGHT", "BOTTOMRIGHT" }, width = 2 },
	}

	for _, edge in ipairs(edges) do
		local line = marker:CreateTexture(nil, "OVERLAY")
		line:SetColorTexture(1, 0.82, 0, 0.9)
		line:SetPoint(edge.points[1])
		line:SetPoint(edge.points[2])

		if edge.height ~= nil then
			line:SetHeight(edge.height)
		else
			line:SetWidth(edge.width)
		end

		line:Hide()
		table.insert(marker.SelectedBorder, line)
	end
end

-- Rebuilds the selection markers from the scratch layout. Called after every canvas
-- refresh (tab switch / template swap / future edits) since offsets can change.
function DesignerMixin:BuildMarkers()
	self.selectorPool:ReleaseAll()
	table.wipe(self.markers)

	if self.scratchElements == nil then
		return
	end

	for elementTag in pairs(Private.Design.GetSchema(self.scratchTemplate)) do
		local record = self.scratchElements[elementTag]
		local x, y, width, height = nil, nil, nil, nil

		if record ~= nil then
			x, y, width, height = self:ElementMarkerRect(record)
		end

		if width ~= nil then
			local marker = self.selectorPool:Acquire()
			self:EnsureMarkerVisuals(marker)

			marker.element = elementTag
			marker:ClearAllPoints()
			PixelUtil.SetSize(marker, width, height)
			PixelUtil.SetPoint(marker, "CENTER", self.Preview, "CENTER", x, y)
			-- stack smaller markers on top so a small element centred inside a large
			-- one (e.g. the interrupt shield over the progress bar) stays clickable
			local areaLevel = math.min(200, math.floor(50000 / math.max(1, width * height)))
			marker:SetFrameLevel(self.Preview:GetFrameLevel() + 20 + areaLevel)
			marker:SetScript("OnClick", function(clicked)
				self:SelectElement(clicked.element)
			end)
			marker:Show()

			self.markers[elementTag] = marker
		end
	end

	-- keep the current selection if its marker survived, else clear it
	if self.selectedElement ~= nil and self.markers[self.selectedElement] ~= nil then
		self:SelectElement(self.selectedElement)
	else
		self.selectedElement = nil
		self:UpdatePanelHeader()
	end
end

-- Selects an element: highlights its marker and points the panel header (and, in
-- step 7, the widget list) at that element's scratch record.
---@param elementTag Element
function DesignerMixin:SelectElement(elementTag)
	self.selectedElement = elementTag

	for tag, marker in pairs(self.markers) do
		local isSelected = tag == elementTag
		for _, line in ipairs(marker.SelectedBorder) do
			line:SetShown(isSelected)
		end
	end

	self:UpdatePanelHeader()
end

-- The panel header names the selected element (or prompts for a selection).
function DesignerMixin:UpdatePanelHeader()
	if self.selectedElement == nil then
		self.Panel.Header:SetText(Private.L.Designer.NoElementSelected)
		return
	end

	self.Panel.Header:SetText(
		Private.L.Designer.ElementNames[self.selectedElement] or self.selectedElement
	)
end

function DesignerMixin:Initialize()
	-- Canvas: a bordered inset split into a Preview (left, holds the demo frame +
	-- selection markers) and a Panel (right, the schema-driven widget list in step 7).
	self.Canvas = CreateFrame("Frame", nil, self, "InsetFrameTemplate")
	self.Canvas:SetPoint("TOPLEFT", self, "TOPLEFT", 12, -32)
	self.Canvas:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -12, 12)
	self.Canvas:SetFrameLevel(self:GetFrameLevel() + 10)

	self.Panel = CreateFrame("Frame", nil, self.Canvas, "InsetFrameTemplate")
	self.Panel:SetPoint("TOPRIGHT", self.Canvas, "TOPRIGHT", -6, -6)
	self.Panel:SetPoint("BOTTOMRIGHT", self.Canvas, "BOTTOMRIGHT", -6, 6)
	self.Panel:SetWidth(260)

	self.Panel.Header = self.Panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	self.Panel.Header:SetPoint("TOP", self.Panel, "TOP", 0, -10)

	-- Preview holds the demo frame + the selection markers. It stays mouse-passive
	-- itself (its markers, as mouse-enabled children, still receive clicks) so empty
	-- space doesn't swallow input.
	self.Preview = CreateFrame("Frame", nil, self.Canvas)
	self.Preview:SetPoint("TOPLEFT", self.Canvas, "TOPLEFT", 6, -6)
	self.Preview:SetPoint("BOTTOMRIGHT", self.Panel, "BOTTOMLEFT", -6, 6)

	self.Preview.Hint = self.Preview:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
	self.Preview.Hint:SetPoint("BOTTOM", self.Preview, "BOTTOM", 0, 6)
	self.Preview.Hint:SetText(Private.L.Designer.SelectHint)

	-- Selection markers: mouse-enabled buttons floating over the preview at each
	-- element's stored offset. Pooled + rebuilt whenever the layout/template changes.
	self.selectorPool = CreateFramePool("Button", self.Preview, nil, function(_, marker)
		marker:Hide()
		marker:ClearAllPoints()
		marker:SetScript("OnClick", nil)
		if marker.SelectedBorder ~= nil then
			for _, line in ipairs(marker.SelectedBorder) do
				line:Hide()
			end
		end
	end)
	---@type table<Element, Button>
	self.markers = {}
	self.selectedElement = nil

	-- One PanelTabButton per group. The template auto-resizes to its text on show
	-- and appends itself to self.Tabs; we track our own active set in self.tabs and
	-- drive selection with PanelTemplates_SelectTab/DeselectTab directly.
	self.tabPool = CreateFramePool("Button", self, "PanelTabButtonTemplate")
	---@type table<integer, Button>
	self.tabs = {}
	self.selectedGroupId = nil

	self:SetScript("OnShow", self.RebuildTabs)
	-- closing (Esc / close button / Toggle) stops the loop and frees the demo frame
	self:HookScript("OnHide", self.EndDemo)

	-- Keep the tab strip current if groups change while the designer is open. A
	-- rename fires GROUP_CHANGED; create/delete route through PROFILE_IMPORTED.
	local function RebuildIfShown()
		if self:IsShown() then
			self:RebuildTabs()
		end
	end
	Private.EventRegistry:RegisterCallback(Private.Enum.Events.GROUP_CHANGED, RebuildIfShown)
	Private.EventRegistry:RegisterCallback(Private.Enum.Events.PROFILE_IMPORTED, RebuildIfShown)
end

-- Lazily built on first Toggle so nothing is created for users who never open it.
local designerFrame

---@return TargetedSpellsDesignerFrame
local function BuildFrame()
	local frame = CreateFrame("Frame", "TargetedSpellsDesigner", UIParent, "ButtonFrameTemplate")

	-- Strip the game-panel weight ButtonFrameTemplate carries but we don't want:
	-- the portrait, the bottom button bar, and the default inset (the canvas
	-- supplies its own InsetFrameTemplate).
	ButtonFrameTemplate_HidePortrait(frame)
	ButtonFrameTemplate_HideButtonBar(frame)
	frame.Inset:Hide()

	frame:SetTitle(Private.L.Designer.Title)
	frame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("HIGH")
	frame:SetClampedToScreen(true)

	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

	-- Esc closes it, like a native panel.
	table.insert(UISpecialFrames, frame:GetName())

	Mixin(frame, DesignerMixin)
	frame:Initialize()

	frame:Hide()

	return frame
end

---@class TargetedSpellsDesigner
Private.Designer = {}

-- Opens the designer if hidden, closes it if shown. Builds the window on first use.
function Private.Designer.Toggle()
	designerFrame = designerFrame or BuildFrame()
	designerFrame:SetShown(not designerFrame:IsShown())
end

-- The `design` subcommand routes here. SlashCommands.lua and the localization
-- files both load before this one, so the registry and the string are ready.
Private.SlashCommands.Register("design", Private.L.SlashCommands.DesignDescription, function()
	Private.Designer.Toggle()
end)
