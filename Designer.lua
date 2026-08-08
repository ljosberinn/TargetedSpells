---@type string, TargetedSpells
local _, Private = ...

local LibSharedMedia = LibStub("LibSharedMedia-3.0")

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

-- Widget-panel geometry.
local PANEL_PAD = 12
local PANEL_ROW_GAP = 6
local PANEL_LABEL_WIDTH = 92

-- Setting types a schema record can request. Mirrors Design.lua's local SettingType
-- (the record `type` strings are the contract between the two files).
local SettingType = {
	Boolean = "boolean",
	Number = "number",
	Color = "color",
	Enum = "enum",
	Font = "font",
	FontFlags = "fontFlags",
	Texture = "texture",
}

local Element = Private.Enum.Element

-- Font-style flags in display order for the multi-select fontFlags widget.
local FONT_FLAG_ORDER = { Private.Enum.FontFlags.OUTLINE, Private.Enum.FontFlags.SHADOW }

-- Max drop-down popup height before it scrolls; LSM font/texture lists can be long.
local MEDIA_MENU_MAX_HEIGHT = 400

-- Inline media preview dims for texture dropdown rows (WoW |T escape is
-- height:width). A wide strip reads a bar/background texture better than a square.
local TEXTURE_PREVIEW_HEIGHT = 14
local TEXTURE_PREVIEW_WIDTH = 64

-- Font preview objects (one per font path) so each font's menu row renders its own
-- name in that font — mirrors AdvancedFocusCastBar. Built as a font *family* so a
-- non-Latin client still renders the roman label, overriding only the active
-- locale's alphabet with the previewed file.
local previewFontCache = {}
local previewFontCounter = 0

---@param path string
---@return string globalFontName
local function PreviewFontObject(path)
	if previewFontCache[path] then
		return previewFontCache[path]
	end

	previewFontCounter = previewFontCounter + 1
	local globalName = "TargetedSpellsDesignerPreviewFont" .. previewFontCounter

	local overrideAlphabet = ({
		koKR = "korean",
		zhCN = "simplifiedchinese",
		zhTW = "traditionalchinese",
		ruRU = "russian",
	})[GAME_LOCALE or GetLocale()] or "roman"

	---@type CreateFontFamilyMemberInfo[]
	local members = {}
	for _, alphabet in ipairs({ "roman", "korean", "simplifiedchinese", "traditionalchinese", "russian" }) do
		local file, size = GameFontNormal:GetFontObjectForAlphabet(alphabet):GetFont()
		members[#members + 1] = {
			alphabet = alphabet,
			file = alphabet == overrideAlphabet and path or file,
			height = size,
			flags = "",
		}
	end

	local font = CreateFontFamily(globalName, members)
	font:SetTextColor(1, 1, 1)

	previewFontCache[path] = globalName
	return globalName
end

-- Display order for the element picker (and the fallback core selection). Every
-- configurable element of each template, including footprint-less ones (Overlay /
-- Background / Cooldown) that have no canvas marker and are only reachable here.
local ELEMENT_ORDER = {
	[Private.Enum.Template.Icon] = {
		Element.Icon,
		Element.Overlay,
		Element.Cooldown,
		Element.Border,
		Element.InterruptSource,
	},
	[Private.Enum.Template.Bar] = {
		Element.ProgressBar,
		Element.Background,
		Element.Icon,
		Element.TargetMarker,
		Element.DurationCooldown,
		Element.SpellName,
		Element.TargetName,
		Element.InterruptSource,
		Element.InterruptShield,
		Element.Border,
	},
	-- one Icon entry, deliberately: a single Icon element drives both cells, so listing it
	-- once is what makes "edit the icon, both mirror" the only possible behaviour
	[Private.Enum.Template.IconDuration] = {
		Element.Icon,
		Element.Duration,
		Element.Overlay,
		Element.Cooldown,
		Element.Border,
	},
}

-- The core (always-selected fallback) element per template.
local CORE_ELEMENT = {
	[Private.Enum.Template.Icon] = Element.Icon,
	[Private.Enum.Template.Bar] = Element.ProgressBar,
	[Private.Enum.Template.IconDuration] = Element.Icon,
}

---@class TargetedSpellsDesignerFrame : Frame
local DesignerMixin = {}

-- Group ids in ascending order — the tab order and the "first group" fallback.
-- Shares the cached order from Groups (invalidated on create/delete/import), so
-- reopening the designer or rebuilding tabs does no fresh sort. Read-only: callers
-- iterate the result and must not mutate it.
---@return integer[]
function DesignerMixin:SortedGroupIds()
	return Private.Groups.SortedIds(TargetedSpellsSaved.Groups)
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
			self:RequestSelectGroup(clickedTab:GetID())
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
	self.dirty = false
	self:UpdateApplyState()

	self:RefreshCanvas()
end

-- Tab-click entry point: if the current group has unsaved scratch edits, prompt
-- before leaving it; otherwise switch straight away. Programmatic selection
-- (RebuildTabs → SelectGroup) bypasses this, so a rebuild never prompts.
---@param groupId integer
function DesignerMixin:RequestSelectGroup(groupId)
	if groupId == self.selectedGroupId then
		return
	end

	if self.dirty then
		self:PromptUnsavedSwitch(groupId)
	else
		self:SelectGroup(groupId)
	end
end

-- The pool a group's demo frame comes from, following its current template.
---@param group TargetedSpellsGroup
function DesignerMixin:GroupPool(group)
	if group.Template == Private.Enum.Template.Icon then
		return Private.Utils.Pools.Icon
	elseif group.Template == Private.Enum.Template.IconDuration then
		return Private.Utils.Pools.IconDuration
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

	-- a fixed sample raid marker for the run so TargetMarker previews steadily (a
	-- non-casting unit has none of its own)
	self.demoMarkerIndex = math.random(1, 8)

	self:PlayDemoCast()

	-- loop the cast right as it finishes so the preview never dwells on an empty bar
	self.demoTicker = C_Timer.NewTicker(DEMO_CAST_TIME, function()
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

	if self.demoFrame.SetPreviewBarColor then
		self.demoFrame:SetPreviewBarColor()
	end

	-- player-based sample content for the text elements + the raid marker, so they
	-- preview steadily instead of vanishing when the cast loops (PostCreate resolves
	-- them from the non-casting "player" unit, which yields nothing)
	self:PopulateDemoContent()

	local group = self.selectedGroupId and TargetedSpellsSaved.Groups[self.selectedGroupId]
	if group ~= nil and group.GlowImportant then
		-- randomize importance per cast so the preview shows both the full-alpha
		-- (important) and reduced-alpha states, like the edit-mode preview does
		self.demoFrame:ShowGlow(self.demoFrame:IsSpellImportant(Private.Utils.RollDice()))
	else
		self.demoFrame:HideGlow()
	end
end

-- Fills the demo frame's text elements with the player's own info (name, and class
-- colour where the element opts in) and re-applies the sample raid marker. Used
-- both on each cast loop and after a widget edit, so these elements preview
-- persistently and reflect the player — a real cast on a non-player unit is what
-- PostCreate expects, and there is none in the designer.
function DesignerMixin:PopulateDemoContent()
	local frame = self.demoFrame
	if frame == nil then
		return
	end

	local playerName = UnitName("player")
	local _, classToken = UnitClass("player")
	local classColor = classToken and C_ClassColor.GetClassColor(classToken)

	if frame.ProgressBar then
		-- bar template
		self:StyleDemoText(frame.ProgressBar.TargetName, self.scratchElements[Element.TargetName], playerName, classColor)
		self:StyleDemoText(frame.ProgressBar.InterruptSource, self.scratchElements[Element.InterruptSource], playerName,
			classColor)

		-- StyleDemoText above just settled TargetName's visibility, which is what decides
		-- whether SpellName keeps its cap; re-apply it so the preview matches a live bar
		frame:ApplySpellNameWidth()

		local shield = self.scratchElements[Element.InterruptShield]
		frame.CustomElementsFrame.InterruptShield:Show()
		frame.CustomElementsFrame.InterruptShield:SetAlphaFromBoolean(secretwrap(shield ~= nil and shield.active == true))
	else
		-- icon template
		self:StyleDemoText(frame.InterruptSource, self.scratchElements[Element.InterruptSource], playerName, classColor)
	end

	if frame.SetTargetMarker then
		frame:SetTargetMarker(self.demoMarkerIndex)
	end
end

-- Sets a demo text region's sample text + colour, honouring the element's `active`
-- toggle and its class-colour / static-colour choice.
---@param region FontString?
---@param element table<string, any>?
---@param sampleText string
---@param classColor colorRGB?
function DesignerMixin:StyleDemoText(region, element, sampleText, classColor)
	if region == nil then
		return
	end

	if element == nil or element.active == false then
		region:Hide()
		return
	end

	region:SetText(sampleText)

	if element.useClassColor and classColor then
		region:SetTextColor(classColor.r, classColor.g, classColor.b)
	elseif element.textColor then
		local color = CreateColorFromHexString(element.textColor)
		region:SetTextColor(color.r, color.g, color.b, color.a)
	end

	region:Show()
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

-- The marker rectangle (centre x/y, width, height in preview-centre coords) for an
-- element, or nil for a footprint-less element / an inactive gutter slot. Computed purely
-- from the stored record (never by querying the demo frame — its sizes are secret-tainted
-- by the cast path and error on arithmetic).
--
-- The reflowing templates (bar, icon+duration) take their geometry from the shared
-- Private.Utils layout (passed in as `layout`) rather than the raw record, keeping the
-- markers on top of what the preview actually draws. The icon template has no reflow and
-- uses the record directly: boxes use their stored size/offset; text is edge-anchored by
-- justifyH, so the CENTER-placed marker is shifted half its nominal width to put the
-- justify edge on x.
---@param record table<string, any>
---@param tag Element?
---@param layout table?
function DesignerMixin:ElementMarkerRect(record, tag, layout)
	if layout ~= nil then
		local geom = layout[tag]
		if geom == nil then
			return nil -- footprint-less element, or an inactive gutter slot (no marker)
		end

		if geom.text then
			local width = (geom.maxWidth ~= nil and geom.maxWidth > 0) and geom.maxWidth or 120
			local x = geom.edgeX
			if geom.justifyH == "LEFT" then
				x = x + width / 2
			elseif geom.justifyH == "RIGHT" then
				x = x - width / 2
			end
			return x, geom.centerY, width, (geom.fontSize or record.fontSize or 0) * 1.8
		end

		return geom.centerX, geom.centerY, geom.width, geom.height
	end

	local x = record.x or 0
	local y = record.y or 0

	if record.width ~= nil and record.height ~= nil then
		return x, y, record.width, record.height
	end

	if record.fontSize ~= nil then
		local capped = record.maxWidth ~= nil and record.maxWidth > 0
		local width = capped and record.maxWidth or 120

		local justifyH = record.justifyH or "CENTER"
		if justifyH == "LEFT" then
			x = x + width / 2
		elseif justifyH == "RIGHT" then
			x = x - width / 2
		end

		return x, y, width, record.fontSize * 1.8
	end

	return nil
end

-- The reflow layout for the current scratch elements, or nil for the icon template (which
-- does not reflow, and whose markers come straight off each record's x/y). Markers derive
-- their positions from this so they track exactly what the renderer will draw.
function DesignerMixin:ScratchLayout()
	if self.scratchElements == nil then
		return nil
	end

	if self.scratchTemplate == Private.Enum.Template.Bar then
		return Private.Utils.ComputeBarLayout(self.scratchElements)
	elseif self.scratchTemplate == Private.Enum.Template.IconDuration then
		return Private.Utils.ComputeIconDurationLayout(self.scratchElements)
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
		{ points = { "TOPLEFT", "TOPRIGHT" },       height = 2 },
		{ points = { "BOTTOMLEFT", "BOTTOMRIGHT" }, height = 2 },
		{ points = { "TOPLEFT", "BOTTOMLEFT" },     width = 2 },
		{ points = { "TOPRIGHT", "BOTTOMRIGHT" },   width = 2 },
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

	local layout = self:ScratchLayout()

	for elementTag in pairs(Private.Design.GetSchema(self.scratchTemplate)) do
		local record = self.scratchElements[elementTag]
		local x, y, width, height = nil, nil, nil, nil

		if record ~= nil then
			x, y, width, height = self:ElementMarkerRect(record, elementTag, layout)
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

	-- keep the current selection if it still exists in this template, else fall back
	-- to the core element so the panel is never empty (SelectElement handles the rest)
	local schema = Private.Design.GetSchema(self.scratchTemplate)
	if self.selectedElement == nil or schema[self.selectedElement] == nil then
		self.selectedElement = CORE_ELEMENT[self.scratchTemplate]
	end

	self:SelectElement(self.selectedElement)
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

	self:RefreshElementDropdown()
	self:BuildPanel()
end

-- Installs the element-picker dropdown's menu. The generator reads the current
-- template/selection each time it runs, so switching templates just needs a
-- RefreshElementDropdown to re-list.
function DesignerMixin:SetupElementDropdown()
	self.Panel.ElementDropdown:SetupMenu(function(_, rootDescription)
		local order = self.scratchTemplate and ELEMENT_ORDER[self.scratchTemplate]
		if order == nil then
			return
		end

		for _, elementTag in ipairs(order) do
			rootDescription:CreateRadio(
				Private.L.Designer.ElementNames[elementTag] or elementTag,
				function()
					return self.selectedElement == elementTag
				end,
				function()
					self:SelectElement(elementTag)
				end
			)
		end
	end)
end

-- Regenerates the picker so its shown text matches the current selection (needed
-- after a selection driven from the preview markers rather than the dropdown).
function DesignerMixin:RefreshElementDropdown()
	if self.Panel.ElementDropdown ~= nil then
		self.Panel.ElementDropdown:GenerateMenu()
	end
end

-- ── Copy layout from another group ───────────────────────────────────────────
-- Deep-copies a same-template group's Elements into the scratch copy (never the
-- live group — so it lands in the Apply/Cancel flow, undoable via Revert). Groups
-- of a different template aren't offered: an icon layout can't map onto a bar.

-- The other groups sharing the current scratch template — the valid copy sources.
---@return integer[]
function DesignerMixin:CopyableSourceGroups()
	local sources = {}

	for _, id in ipairs(self:SortedGroupIds()) do
		local group = TargetedSpellsSaved.Groups[id]
		if id ~= self.selectedGroupId and group.Template == self.scratchTemplate then
			sources[#sources + 1] = id
		end
	end

	return sources
end

-- Installs the copy-from menu. The generator reads the live group list + current
-- selection each time it opens, so it always reflects the current sources; the
-- button text stays a fixed prompt (OverrideText ignores selection state).
function DesignerMixin:SetupCopyFromDropdown()
	local dropdown = self.Preview.CopyFromDropdown

	dropdown:SetupMenu(function(_, rootDescription)
		local sources = self:CopyableSourceGroups()

		if #sources == 0 then
			rootDescription:CreateTitle(Private.L.Designer.CopyFromEmpty)
			return
		end

		for _, id in ipairs(sources) do
			local group = TargetedSpellsSaved.Groups[id]
			rootDescription:CreateButton(group.Name, function()
				self:CopyLayoutFromGroup(id)
			end)
		end
	end)

	dropdown:OverrideText(Private.L.Designer.CopyFrom)
end

-- Copies a source group's layout into the scratch copy and redraws. Same-template
-- only; the source is already schema-complete (BackfillElements runs on load).
---@param sourceGroupId integer
function DesignerMixin:CopyLayoutFromGroup(sourceGroupId)
	local source = TargetedSpellsSaved.Groups[sourceGroupId]
	if source == nil or source.Template ~= self.scratchTemplate then
		return
	end

	self.scratchElements = Private.Design.CopyElements(source.Elements)
	self:MarkDirty()
	self:RefreshCanvas()
end

-- ── Schema-driven widget panel ───────────────────────────────────────────────
-- The selected element's schema is walked into a stack of widgets; each edit
-- mutates the scratch record in place and previews live (the demo frame already
-- renders from the same scratch table via SetLayoutOverride). This round covers
-- boolean/number/enum; color/font/texture render as placeholder rows until their
-- widgets land (color swatch next, the rest in Phase 6).

-- The current selected element's scratch record (nil if nothing selected).
---@return table<string, any>?
function DesignerMixin:SelectedScratchRecord()
	if self.selectedElement == nil or self.scratchElements == nil then
		return nil
	end
	return self.scratchElements[self.selectedElement]
end

---@param record table
function DesignerMixin:SettingLabel(record)
	return Private.L.Designer.SettingNames[record.name] or record.name
end

---@param option { value: any, name: string }
function DesignerMixin:OptionLabel(option)
	return Private.L.Designer.Options[option.name] or _G[option.name] or option.name
end

-- Lazily creates (and shows) a widget's row label, reused across pool acquires.
---@param widget Frame
function DesignerMixin:WidgetLabel(widget)
	if widget.tsLabel == nil then
		widget.tsLabel = widget:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	end
	widget.tsLabel:Show()
	return widget.tsLabel
end

-- Writes an edited value into the selected element's scratch record and previews
-- it live (re-apply layout to the demo + reposition the selection markers).
---@param setting string
---@param value any
function DesignerMixin:OnWidgetValueChanged(setting, value)
	-- ignore callbacks fired while the panel is (re)building its widgets
	if self.buildingPanel then
		return
	end

	local record = self:SelectedScratchRecord()
	if record == nil then
		return
	end

	-- no-op if the value is unchanged (a slider reporting the same snapped value, a
	-- dropdown re-picking the current option) — avoids a needless re-render, which
	-- would visibly re-roll the demo's random spell icon
	if record[setting] == value then
		return
	end

	record[setting] = value
	-- the scratch table is mutated in place and previewed live, so its memoised bar layout
	-- has to be dropped explicitly (Utils.ComputeBarLayout keys the memo on the table)
	Private.Utils.InvalidateLayout(self.scratchElements)
	self:ApplyScratchToDemo()

	-- toggling `active` changes the bar's reflow gutter set, which adds/removes a marker
	-- (and shifts the others) — a full rebuild; any other edit just repositions.
	if setting == "active" and self.scratchTemplate == Private.Enum.Template.Bar then
		self:BuildMarkers()
	else
		self:UpdateMarkerRects()
	end

	self:MarkDirty()
end

-- Boolean → checkbox, label in the left column.
---@param record table
---@param yOffset number
function DesignerMixin:BuildCheckbox(record, yOffset)
	local checkbox = self.widgetPools[SettingType.Boolean]:Acquire()

	local label = self:WidgetLabel(checkbox)
	label:ClearAllPoints()
	label:SetPoint("RIGHT", checkbox, "LEFT", -6, 0)
	label:SetWidth(PANEL_LABEL_WIDTH)
	label:SetJustifyH("RIGHT")
	label:SetText(self:SettingLabel(record))

	checkbox:ClearAllPoints()
	checkbox:SetPoint("TOPLEFT", self.Panel.Content, "TOPLEFT", PANEL_PAD + PANEL_LABEL_WIDTH + 10, -yOffset)
	checkbox:SetChecked(self:SelectedScratchRecord()[record.setting] == true)
	checkbox:SetScript("OnClick", function(box)
		self:OnWidgetValueChanged(record.setting, box:GetChecked() and true or false)
	end)
	checkbox:Show()

	return 26
end

-- Number → MinimalSliderWithSteppers, label above the slider (two-line row).
---@param record table
---@param yOffset number
function DesignerMixin:BuildSlider(record, yOffset)
	local slider = self.widgetPools[SettingType.Number]:Acquire()
	local controlWidth = self.Panel.Content:GetWidth() - 2 * PANEL_PAD

	local label = self:WidgetLabel(slider)
	label:ClearAllPoints()
	label:SetPoint("BOTTOMLEFT", slider, "TOPLEFT", 0, 2)
	label:SetWidth(controlWidth)
	label:SetJustifyH("LEFT")
	label:SetText(self:SettingLabel(record))

	slider:ClearAllPoints()
	slider:SetPoint("TOPLEFT", self.Panel.Content, "TOPLEFT", PANEL_PAD, -yOffset - 16)
	slider:SetWidth(controlWidth)

	local numberFormat = record.step < 1 and "%.2f" or "%d"
	local steps = math.max(1, math.floor((record.max - record.min) / record.step + 0.5))
	local formatters = {
		[MinimalSliderWithSteppersMixin.Label.Top] = function(value)
			return string.format(numberFormat, value)
		end,
		[MinimalSliderWithSteppersMixin.Label.Min] = function()
			return string.format(numberFormat, record.min)
		end,
		[MinimalSliderWithSteppersMixin.Label.Max] = function()
			return string.format(numberFormat, record.max)
		end,
	}

	slider:Init(self:SelectedScratchRecord()[record.setting] or record.default, record.min, record.max, steps, formatters)

	-- Init installs its own OnValueChanged on the inner slider (it calls FormatValue then
	-- fires Event.OnValueChanged); override it so edits also flow to the scratch record.
	-- We replicate FormatValue here — that is the entirety of Init's visual refresh; there
	-- is no stepper-state hook to replay (MinimalSliderWithSteppersMixin has none).
	slider.Slider:SetScript("OnValueChanged", function(_, value)
		slider:FormatValue(value)
		self:OnWidgetValueChanged(record.setting, math.floor(value / record.step + 0.5) * record.step)
	end)

	slider:Show()

	return 52
end

-- Acquires a WowStyle1Dropdown from `poolKey` (default the Enum pool) and positions it
-- with a right-aligned label in the left column. Shared by every dropdown-based row
-- (enum, texture, font, fontFlags); the caller installs the menu. Returns the dropdown.
-- fontFlags uses its own pool: OverrideText latches `disableSelectionText`, which would
-- otherwise leak the summary text onto a reused radio dropdown.
---@param record table
---@param yOffset number
---@param poolKey string?
function DesignerMixin:AcquireDropdownRow(record, yOffset, poolKey)
	local dropdown = self.widgetPools[poolKey or SettingType.Enum]:Acquire()
	local controlX = PANEL_PAD + PANEL_LABEL_WIDTH + 10
	local controlWidth = self.Panel.Content:GetWidth() - controlX - PANEL_PAD

	local label = self:WidgetLabel(dropdown)
	label:ClearAllPoints()
	label:SetPoint("RIGHT", dropdown, "LEFT", -6, 0)
	label:SetWidth(PANEL_LABEL_WIDTH)
	label:SetJustifyH("RIGHT")
	label:SetText(self:SettingLabel(record))

	dropdown:ClearAllPoints()
	dropdown:SetPoint("TOPLEFT", self.Panel.Content, "TOPLEFT", controlX, -yOffset)
	dropdown:SetWidth(controlWidth)

	return dropdown
end

-- Builds a single-select radio menu on `dropdown` from `options` (a value+label list);
-- long lists (font/texture) scroll. Each pick routes through OnWidgetValueChanged.
---@param dropdown table
---@param setting string
---@param options table[] each { value = any, label = string }
-- Builds the radio menu for an enum / texture / font dropdown. An option may carry
-- an inline preview: `option.texture` (a resolved media path) prefixes the label with
-- a |T texture escape; `option.font` (a font path) renders that row's label in the
-- font itself. Both mirror AdvancedFocusCastBar's media pickers.
function DesignerMixin:PopulateRadioMenu(dropdown, setting, options)
	dropdown:SetupMenu(function(_, rootDescription)
		if #options > 12 then
			rootDescription:SetScrollMode(MEDIA_MENU_MAX_HEIGHT)
		end

		for _, option in ipairs(options) do
			local label = option.label
			if option.texture then
				label = string.format("|T%s:%d:%d|t %s", option.texture, TEXTURE_PREVIEW_HEIGHT, TEXTURE_PREVIEW_WIDTH,
					option.label)
			end

			local radio = rootDescription:CreateRadio(label, function()
				return self:SelectedScratchRecord()[setting] == option.value
			end, function()
				self:OnWidgetValueChanged(setting, option.value)
			end)

			if option.font then
				radio:AddInitializer(function(button)
					button.fontString:SetFontObject(PreviewFontObject(option.font))
				end)
			end
		end
	end)

	dropdown:Show()
end

-- Enum → WowStyle1Dropdown of radio options bound to the scratch value.
---@param record table
---@param yOffset number
function DesignerMixin:BuildDropdown(record, yOffset)
	local dropdown = self:AcquireDropdownRow(record, yOffset)

	local options = {}
	for _, option in ipairs(record.options) do
		options[#options + 1] = { value = option.value, label = self:OptionLabel(option) }
	end

	self:PopulateRadioMenu(dropdown, record.setting, options)

	return 30
end

-- Texture → WowStyle1Dropdown of LSM media names for the record's mediaType (statusbar
-- / background / border). The stored value is the LSM *name*, resolved to a path by the
-- mixins via LibSharedMedia:Fetch. Media lists come from the existing Settings getters.
---@param record table
---@param yOffset number
function DesignerMixin:BuildTextureDropdown(record, yOffset)
	local dropdown = self:AcquireDropdownRow(record, yOffset)

	local options = {}
	for _, name in ipairs(self:MediaNameList(record.mediaType)) do
		-- inline texture preview: the stored value is the LSM name; Fetch resolves the
		-- path the |T escape needs (record.mediaType == the LSM MediaType string)
		options[#options + 1] = { value = name, label = name, texture = LibSharedMedia:Fetch(record.mediaType, name) }
	end

	self:PopulateRadioMenu(dropdown, record.setting, options)

	return 30
end

-- Font → WowStyle1Dropdown of LSM font names. The stored value is the font *path*
-- (what SafelySetFont / SetFont consume, matching the v3 storage), so each radio's
-- value is the resolved path while its label is the friendly name, rendered in the
-- font itself as an inline preview.
---@param record table
---@param yOffset number
function DesignerMixin:BuildFontDropdown(record, yOffset)
	local dropdown = self:AcquireDropdownRow(record, yOffset)
	local fontInfo = Private.Settings.GetFontOptions()

	local options = {}
	for _, name in ipairs(fontInfo.fonts) do
		local path = fontInfo.byLabel[name]
		options[#options + 1] = { value = path, label = name, font = path }
	end

	self:PopulateRadioMenu(dropdown, record.setting, options)

	return 30
end

-- FontFlags → WowStyle1Dropdown of checkboxes (Outline / Shadow). The value is a
-- nested { [flag] = bool } table mutated in place, so it can't use the value-equality
-- path in OnWidgetValueChanged; toggles preview + dirty directly (OnFontFlagChanged).
-- The button text summarises the enabled flags (OverrideText).
---@param record table
---@param yOffset number
function DesignerMixin:BuildFontFlagsDropdown(record, yOffset)
	local dropdown = self:AcquireDropdownRow(record, yOffset, SettingType.FontFlags)
	local flags = self:SelectedScratchRecord()[record.setting]

	dropdown:SetupMenu(function(_, rootDescription)
		for _, flag in ipairs(FONT_FLAG_ORDER) do
			rootDescription:CreateCheckbox(Private.L.Designer.FontFlagNames[flag], function()
				return flags[flag] == true
			end, function()
				flags[flag] = not flags[flag]
				self:OnFontFlagChanged(dropdown, record)
			end)
		end
	end)

	dropdown:OverrideText(self:FontFlagsSummary(flags))
	dropdown:Show()

	return 30
end

-- Comma-joined names of the enabled font flags (or the "none" label), for the
-- fontFlags dropdown's summary text.
---@param flags table<integer, boolean>
function DesignerMixin:FontFlagsSummary(flags)
	local parts = {}
	for _, flag in ipairs(FONT_FLAG_ORDER) do
		if flags[flag] then
			parts[#parts + 1] = Private.L.Designer.FontFlagNames[flag]
		end
	end

	if #parts == 0 then
		return Private.L.Designer.FontFlagsNone
	end

	return table.concat(parts, ", ")
end

-- Applies a fontFlags toggle: refresh the summary text, preview live, mark dirty.
-- Bypasses OnWidgetValueChanged because the value is a mutated-in-place table.
---@param dropdown table
---@param record table
function DesignerMixin:OnFontFlagChanged(dropdown, record)
	if self.buildingPanel then
		return
	end

	dropdown:OverrideText(self:FontFlagsSummary(self:SelectedScratchRecord()[record.setting]))
	Private.Utils.InvalidateLayout(self.scratchElements)
	self:ApplyScratchToDemo()
	self:UpdateMarkerRects()
	self:MarkDirty()
end

-- LSM media names for a texture record's mediaType, via the existing Settings getters
-- (no duplication) — the border list includes the synthetic "Solid".
---@param mediaType string
---@return string[]
function DesignerMixin:MediaNameList(mediaType)
	if mediaType == "statusbar" then
		return Private.Settings.GetStatusBarOptions()
	elseif mediaType == "background" then
		return Private.Settings.GetBackgroundOptions()
	elseif mediaType == "border" then
		return Private.Settings.GetBorderOptions()
	end

	return {}
end

-- Color → ColorSwatchTemplate; clicking opens the shared ColorPickerFrame. The
-- stored value is an AARRGGBB hex string (CreateColorFromHexString round-trips with
-- ColorMixin:GenerateHexColor), the same format the mixins and demo text consume.
---@param record table
---@param yOffset number
function DesignerMixin:BuildColorSwatch(record, yOffset)
	local swatch = self.widgetPools[SettingType.Color]:Acquire()

	local label = self:WidgetLabel(swatch)
	label:ClearAllPoints()
	label:SetPoint("RIGHT", swatch, "LEFT", -6, 0)
	label:SetWidth(PANEL_LABEL_WIDTH)
	label:SetJustifyH("RIGHT")
	label:SetText(self:SettingLabel(record))

	swatch:ClearAllPoints()
	swatch:SetPoint("TOPLEFT", self.Panel.Content, "TOPLEFT", PANEL_PAD + PANEL_LABEL_WIDTH + 10, -yOffset)

	local color = CreateColorFromHexString(self:SelectedScratchRecord()[record.setting] or record.default)
	swatch:SetColorRGB(color.r, color.g, color.b)

	swatch:EnableMouse(true)
	swatch:SetScript("OnMouseUp", function()
		self:OpenColorPicker(record, swatch)
	end)
	swatch:Show()

	return 24
end

-- Opens the shared color picker seeded from the record's current value. Every change
-- (live drag, opacity, and the picker's own Cancel) writes the resulting hex back
-- through OnWidgetValueChanged, so the demo and swatch preview immediately.
---@param record table
---@param swatch table
function DesignerMixin:OpenColorPicker(record, swatch)
	local startColor = CreateColorFromHexString(self:SelectedScratchRecord()[record.setting] or record.default)

	local function commit()
		local r, g, b = ColorPickerFrame:GetColorRGB()
		local a = ColorPickerFrame:GetColorAlpha()
		swatch:SetColorRGB(r, g, b)
		self:OnWidgetValueChanged(record.setting, CreateColor(r, g, b, a):GenerateHexColor())
	end

	ColorPickerFrame:SetupColorPickerAndShow({
		r = startColor.r,
		g = startColor.g,
		b = startColor.b,
		opacity = startColor.a,
		hasOpacity = true,
		swatchFunc = commit,
		opacityFunc = commit,
		cancelFunc = function(previous)
			swatch:SetColorRGB(previous.r, previous.g, previous.b)
			self:OnWidgetValueChanged(
				record.setting,
				CreateColor(previous.r, previous.g, previous.b, previous.a):GenerateHexColor()
			)
		end,
	})
end

-- Fallback for any setting type without a dedicated widget — a labelled placeholder
-- row so the setting stays visible. No schema type currently reaches this.
---@param record table
---@param yOffset number
function DesignerMixin:BuildPlaceholder(record, yOffset)
	local row = self.widgetPools.placeholder:Acquire()
	row:ClearAllPoints()
	row:SetPoint("TOPLEFT", self.Panel.Content, "TOPLEFT", PANEL_PAD, -yOffset)
	row:SetSize(self.Panel.Content:GetWidth() - 2 * PANEL_PAD, 18)

	local label = self:WidgetLabel(row)
	label:ClearAllPoints()
	label:SetPoint("LEFT", row, "LEFT", 0, 0)
	label:SetWidth(row:GetWidth())
	label:SetJustifyH("LEFT")
	label:SetText(self:SettingLabel(record) .. "  |cff808080(editing soon)|r")

	row:Show()

	return 20
end

-- Dispatches a schema record to its widget builder, returning the row height.
---@param record table
---@param yOffset number
function DesignerMixin:BuildWidget(record, yOffset)
	if record.type == SettingType.Boolean then
		return self:BuildCheckbox(record, yOffset)
	elseif record.type == SettingType.Number then
		return self:BuildSlider(record, yOffset)
	elseif record.type == SettingType.Enum then
		return self:BuildDropdown(record, yOffset)
	elseif record.type == SettingType.Color then
		return self:BuildColorSwatch(record, yOffset)
	elseif record.type == SettingType.Texture then
		return self:BuildTextureDropdown(record, yOffset)
	elseif record.type == SettingType.Font then
		return self:BuildFontDropdown(record, yOffset)
	elseif record.type == SettingType.FontFlags then
		return self:BuildFontFlagsDropdown(record, yOffset)
	end

	return self:BuildPlaceholder(record, yOffset)
end

-- Rebuilds the widget stack for the selected element by walking its schema. The
-- `buildingPanel` guard suppresses value-change callbacks that fire while widgets
-- are being (re)initialised — notably a pooled slider's OnValueChanged firing on
-- Init:SetValue, which would otherwise write into the newly-selected element.
function DesignerMixin:BuildPanel()
	self.buildingPanel = true

	for _, pool in pairs(self.widgetPools) do
		pool:ReleaseAll()
	end

	local record = self:SelectedScratchRecord()
	if record == nil then
		self.buildingPanel = false
		return
	end

	-- match the scroll child to the viewport width so widgets size correctly
	self.Panel.Content:SetWidth(self.Panel.Scroll:GetWidth())

	local yOffset = 8

	for _, schemaRecord in ipairs(Private.Design.GetSchema(self.scratchTemplate)[self.selectedElement]) do
		yOffset = yOffset + self:BuildWidget(schemaRecord, yOffset) + PANEL_ROW_GAP
	end

	-- grow the scroll child to the full content height so nothing clips
	self.Panel.Content:SetHeight(yOffset + 8)
	self.Panel.Scroll:UpdateScrollChildRect()

	self.buildingPanel = false
end

-- Restores the selected element's scratch record to the template default and
-- refreshes the demo, markers and panel. Scoped to one element (GetDefault returns
-- a fresh deep copy, so the assignment is safe to mutate later).
function DesignerMixin:ResetSelectedElement()
	if self.selectedElement == nil or self.scratchElements == nil or self.scratchTemplate == nil then
		return
	end

	local defaultRecord = Private.Design.GetDefault(self.scratchTemplate)[self.selectedElement]
	if defaultRecord == nil then
		return
	end

	self.scratchElements[self.selectedElement] = defaultRecord
	Private.Utils.InvalidateLayout(self.scratchElements)
	self:ApplyScratchToDemo()
	-- BuildMarkers repositions markers from the reset offsets and re-runs
	-- SelectElement, which rebuilds the panel widgets with the restored values
	self:BuildMarkers()
	self:MarkDirty()
end

-- Re-renders the demo frame from the (mutated) scratch layout without restarting
-- the cast loop. ApplyLayout re-reads the override for size/position/textures/
-- colours/font; the runtime-visibility setters catch the rest.
function DesignerMixin:ApplyScratchToDemo()
	if self.demoFrame == nil then
		return
	end

	self.demoFrame:ApplyLayout()

	-- ApplyLayout only re-runs OnSizeChanged when the frame's size actually changed;
	-- call it directly so icon-zoom / overlay (icon) and offset reflow (bar) update
	-- when a setting other than width/height was edited.
	self.demoFrame:OnSizeChanged()

	-- SetSpellId refreshes the SpellName text (bar) but also re-rolls the random demo
	-- icon when spellId is nil, which makes edits like icon-zoom look like the whole
	-- icon changed. Preserve the current texture across the refresh so only the edited
	-- property (e.g. the zoom texcoord) visibly changes.
	-- restore through SetIconTexture, not self.Icon: a template may draw the icon more than
	-- once (icon+duration), and writing the region directly would leave its copies disagreeing
	local previousTexture = self.demoFrame.Icon and self.demoFrame.Icon:GetTexture()
	self.demoFrame:SetSpellId(self.demoFrame:GetSpellId())
	if previousTexture ~= nil then
		self.demoFrame:SetIconTexture(previousTexture)
	end

	if self.demoFrame.SetPreviewBarColor then
		self.demoFrame:SetPreviewBarColor()
	end

	-- re-apply the player-based sample text + marker so colour/active/useClassColor
	-- edits preview immediately
	self:PopulateDemoContent()
end

-- Repositions/resizes existing selection markers from the scratch layout (cheaper
-- than a full BuildMarkers rebuild for a value edit).
function DesignerMixin:UpdateMarkerRects()
	local layout = self:ScratchLayout()

	for elementTag, marker in pairs(self.markers) do
		local record = self.scratchElements[elementTag]

		if record ~= nil then
			local x, y, width, height = self:ElementMarkerRect(record, elementTag, layout)

			if width ~= nil then
				marker:Show()
				PixelUtil.SetSize(marker, width, height)
				marker:ClearAllPoints()
				PixelUtil.SetPoint(marker, "CENTER", self.Preview, "CENTER", x, y)
			else
				-- lost its slot (a gutter element toggled off) → no marker this reflow
				marker:Hide()
			end
		end
	end
end

-- ── Scratch-copy lifecycle (Apply / Revert / unsaved prompts) ─────────────────
-- Edits mutate the scratch Elements copy taken on tab-select, never the live group;
-- the live frames keep showing the last-applied layout until Apply writes the scratch
-- back and fires GROUP_CHANGED (which drives Driver:RefreshGroup). Revert re-copies
-- the group, discarding pending edits. `dirty` gates the footer buttons and the
-- unsaved-changes prompts on close / tab-switch.

-- Flags the scratch copy as diverged from the live group and refreshes button state.
function DesignerMixin:MarkDirty()
	self.dirty = true
	self:UpdateApplyState()
end

-- Enables the Apply/Revert footer buttons only when there are pending edits.
function DesignerMixin:UpdateApplyState()
	if self.ApplyButton == nil then
		return
	end
	self.ApplyButton:SetEnabled(self.dirty == true)
	self.RevertButton:SetEnabled(self.dirty == true)
end

-- Writes the scratch layout back to the live group and refreshes its frames. A deep
-- copy keeps the group's Elements independent of the scratch table, so later edits
-- don't leak onto live frames before the next Apply.
function DesignerMixin:ApplyScratch()
	local group = self.selectedGroupId and TargetedSpellsSaved.Groups[self.selectedGroupId]
	if group == nil or self.scratchElements == nil then
		return
	end

	group.Elements = Private.Design.CopyElements(self.scratchElements)
	self.dirty = false
	self:UpdateApplyState()

	Private.EventRegistry:TriggerEvent(Private.Enum.Events.GROUP_CHANGED, self.selectedGroupId)
end

-- Discards scratch edits by re-copying the live group's layout, then redraws.
function DesignerMixin:RevertScratch()
	local group = self.selectedGroupId and TargetedSpellsSaved.Groups[self.selectedGroupId]
	if group == nil then
		return
	end

	self.scratchTemplate = group.Template
	self.scratchElements = Private.Design.CopyElements(group.Elements)
	self.dirty = false
	self:UpdateApplyState()
	self:RefreshCanvas()
end

-- Unsaved-changes prompt when switching tabs: Save applies then switches, Discard
-- switches (SelectGroup re-copies scratch, dropping edits), Cancel stays put — the
-- current tab keeps its selection because only SelectGroup drives PanelTemplates.
---@param groupId integer
function DesignerMixin:PromptUnsavedSwitch(groupId)
	Private.Utils.ShowStaticPopup({
		text = Private.L.Designer.UnsavedPrompt,
		button1 = SAVE,
		button2 = CANCEL,
		button3 = Private.L.Designer.Discard,
		OnAccept = function()
			self:ApplyScratch()
			self:SelectGroup(groupId)
		end,
		OnAlt = function()
			self:SelectGroup(groupId)
		end,
	})
end

-- Closing (Esc / close button / Toggle) stops the loop and frees the demo frame; if
-- scratch edits are pending it prompts to Save or Discard them. The window is already
-- hidden, so the choice only decides the fate of the pending edits (Discard reverts
-- the scratch so the next open starts clean).
function DesignerMixin:OnDesignerHide()
	self:EndDemo()

	if not self.dirty then
		return
	end

	Private.Utils.ShowStaticPopup({
		text = Private.L.Designer.UnsavedPrompt,
		button1 = SAVE,
		button2 = Private.L.Designer.Discard,
		OnAccept = function()
			self:ApplyScratch()
		end,
		OnCancel = function()
			self:RevertScratch()
		end,
	})
end

function DesignerMixin:Initialize()
	-- Canvas: a bordered inset split into a Preview (left, holds the demo frame +
	-- selection markers) and a Panel (right, the schema-driven widget list in step 7).
	self.Canvas = CreateFrame("Frame", nil, self, "InsetFrameTemplate")
	self.Canvas:SetPoint("TOPLEFT", self, "TOPLEFT", 12, -32)
	-- leave a footer strip for the Apply/Revert controls + unsaved hint
	self.Canvas:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -12, 42)
	self.Canvas:SetFrameLevel(self:GetFrameLevel() + 10)

	-- Footer: Apply writes the scratch layout to the live group, Revert discards it.
	-- Both stay disabled until an edit dirties the scratch copy (UpdateApplyState).
	self.ApplyButton = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
	self.ApplyButton:SetSize(130, 22)
	self.ApplyButton:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -12, 12)
	self.ApplyButton:SetText(Private.L.Designer.Apply)
	self.ApplyButton:SetScript("OnClick", function()
		self:ApplyScratch()
	end)

	self.RevertButton = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
	self.RevertButton:SetSize(100, 22)
	self.RevertButton:SetPoint("RIGHT", self.ApplyButton, "LEFT", -6, 0)
	self.RevertButton:SetText(Private.L.Designer.Revert)
	self.RevertButton:SetScript("OnClick", function()
		self:RevertScratch()
	end)

	-- Reminder that live frames keep their last-applied layout while edits are unsaved.
	self.UnsavedHint = self:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
	self.UnsavedHint:SetPoint("LEFT", self, "BOTTOMLEFT", 14, 23)
	self.UnsavedHint:SetText(Private.L.Designer.UnsavedHint)

	self.Panel = CreateFrame("Frame", nil, self.Canvas, "InsetFrameTemplate")
	self.Panel:SetPoint("TOPRIGHT", self.Canvas, "TOPRIGHT", -6, -6)
	self.Panel:SetPoint("BOTTOMRIGHT", self.Canvas, "BOTTOMRIGHT", -6, 6)
	self.Panel:SetWidth(260)

	self.Panel.Header = self.Panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	self.Panel.Header:SetPoint("TOP", self.Panel, "TOP", 0, -8)
	self.Panel.Header:SetText(Private.L.Designer.ElementPickerLabel)

	-- Element picker: selects any element of the template — including footprint-less
	-- ones (Overlay / Background / Cooldown) that have no canvas marker, and layered
	-- ones that are awkward to click in the preview.
	self.Panel.ElementDropdown = CreateFrame("DropdownButton", nil, self.Panel, "WowStyle1DropdownTemplate")
	self.Panel.ElementDropdown:SetPoint("TOP", self.Panel.Header, "BOTTOM", 0, -4)
	self.Panel.ElementDropdown:SetWidth(self.Panel:GetWidth() - 24)
	self:SetupElementDropdown()

	-- Per-element reset: restores the selected element to its template default.
	self.Panel.ResetButton = CreateFrame("Button", nil, self.Panel, "UIPanelButtonTemplate")
	self.Panel.ResetButton:SetSize(140, 22)
	self.Panel.ResetButton:SetPoint("BOTTOM", self.Panel, "BOTTOM", 0, 8)
	self.Panel.ResetButton:SetText(Private.L.Designer.ResetElement)
	self.Panel.ResetButton:SetScript("OnClick", function()
		self:ResetSelectedElement()
	end)

	-- Scrollable content region — some elements (ProgressBar, text) carry more rows
	-- than the panel is tall, so the widget stack lives in a scroll child. Its bottom
	-- sits above the reset button. ScrollFrameTemplate (Blizzard_SharedXML) auto-builds
	-- a modern MinimalScrollBar as `.ScrollBar` and wires mouse-wheel + scroll through
	-- ScrollFrame_OnLoad -> ScrollUtil.InitScrollFrameWithScrollBar, so no manual
	-- OnMouseWheel handler is needed. The slim bar is anchored just outside the frame's
	-- right edge (+6px), so the right inset is tighter than the old fat scrollbar's.
	self.Panel.Scroll = CreateFrame("ScrollFrame", nil, self.Panel, "ScrollFrameTemplate")
	self.Panel.Scroll:SetPoint("TOPLEFT", self.Panel, "TOPLEFT", 8, -56)
	self.Panel.Scroll:SetPoint("BOTTOMRIGHT", self.Panel, "BOTTOMRIGHT", -20, 38)
	self.Panel.Scroll.ScrollBar:SetHideIfUnscrollable(true)
	self.Panel.Content = CreateFrame("Frame", nil, self.Panel.Scroll)
	self.Panel.Content:SetSize(1, 1)
	self.Panel.Scroll:SetScrollChild(self.Panel.Content)
	-- ScrollFrame_OnLoad wires the OnMouseWheel script but doesn't enable the wheel.
	self.Panel.Scroll:EnableMouseWheel(true)

	-- Preview holds the demo frame + the selection markers. It stays mouse-passive
	-- itself (its markers, as mouse-enabled children, still receive clicks) so empty
	-- space doesn't swallow input.
	self.Preview = CreateFrame("Frame", nil, self.Canvas)
	self.Preview:SetPoint("TOPLEFT", self.Canvas, "TOPLEFT", 6, -6)
	self.Preview:SetPoint("BOTTOMRIGHT", self.Panel, "BOTTOMLEFT", -6, 6)

	self.Preview.Hint = self.Preview:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
	self.Preview.Hint:SetPoint("BOTTOM", self.Preview, "BOTTOM", 0, 6)
	self.Preview.Hint:SetText(Private.L.Designer.SelectHint)

	-- Copy-layout-from-group: an action dropdown (fixed prompt via OverrideText) listing
	-- every OTHER group of the same template. Picking one deep-copies its Elements into
	-- the scratch copy, so it flows through Apply/Cancel like any edit — the lightweight
	-- reuse affordance that replaces shared Designs. Raised above the selection markers
	-- so a top-left element's marker can't steal its clicks.
	self.Preview.CopyFromDropdown = CreateFrame("DropdownButton", nil, self.Preview, "WowStyle1DropdownTemplate")
	self.Preview.CopyFromDropdown:SetPoint("TOPLEFT", self.Preview, "TOPLEFT", 4, -4)
	self.Preview.CopyFromDropdown:SetWidth(200)
	self.Preview.CopyFromDropdown:SetFrameLevel(self.Preview:GetFrameLevel() + 500)
	self:SetupCopyFromDropdown()

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

	-- Widget pools for the schema-driven panel, one per control type. Each control
	-- carries its own row Label (a child, so it hides with the control on release).
	local function HideWidget(_, widget)
		widget:Hide()
		widget:ClearAllPoints()
		-- a pooled slider keeps the OnValueChanged we set; clear it so a later Init on
		-- a different setting can't fire the stale handler
		if widget.Slider ~= nil then
			widget.Slider:SetScript("OnValueChanged", nil)
		end
	end
	self.widgetPools = {
		[SettingType.Boolean] = CreateFramePool("CheckButton", self.Panel.Content, "UICheckButtonTemplate", HideWidget),
		[SettingType.Number] = CreateFramePool("Frame", self.Panel.Content, "MinimalSliderWithSteppersTemplate",
			HideWidget),
		[SettingType.Enum] = CreateFramePool("DropdownButton", self.Panel.Content, "WowStyle1DropdownTemplate",
			HideWidget),
		-- fontFlags gets its own dropdown pool (its OverrideText must not leak onto a
		-- reused radio dropdown — see AcquireDropdownRow)
		[SettingType.FontFlags] = CreateFramePool("DropdownButton", self.Panel.Content, "WowStyle1DropdownTemplate",
			HideWidget),
		[SettingType.Color] = CreateFramePool("Frame", self.Panel.Content, "ColorSwatchTemplate", HideWidget),
		placeholder = CreateFramePool("Frame", self.Panel.Content, nil, HideWidget),
	}

	-- One PanelTabButton per group. The template auto-resizes to its text on show
	-- and appends itself to self.Tabs; we track our own active set in self.tabs and
	-- drive selection with PanelTemplates_SelectTab/DeselectTab directly.
	self.tabPool = CreateFramePool("Button", self, "PanelTabButtonTemplate")
	---@type table<integer, Button>
	self.tabs = {}
	self.selectedGroupId = nil
	self.dirty = false
	self:UpdateApplyState()

	self:SetScript("OnShow", self.RebuildTabs)
	-- closing stops the demo loop and, if edits are pending, prompts Save/Discard
	self:HookScript("OnHide", self.OnDesignerHide)

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

---@class TargetedSpellsDesigner
Private.Designer = {}

do
	---@type TargetedSpellsDesignerFrame?
	local designerFrame

	-- Opens the designer if hidden, closes it if shown. Builds the window on first use.
	function Private.Designer.Toggle()
		if designerFrame == nil then
			designerFrame = CreateFrame("Frame", "TargetedSpellsDesigner", UIParent, "ButtonFrameTemplate")

			-- Strip the game-panel weight ButtonFrameTemplate carries but we don't want:
			-- the portrait, the bottom button bar, and the default inset (the canvas
			-- supplies its own InsetFrameTemplate).
			ButtonFrameTemplate_HidePortrait(designerFrame)
			ButtonFrameTemplate_HideButtonBar(designerFrame)
			designerFrame.Inset:Hide()

			designerFrame:SetTitle(Private.L.Designer.Title)
			designerFrame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
			designerFrame:SetPoint("CENTER")
			designerFrame:SetFrameStrata("HIGH")
			designerFrame:SetClampedToScreen(true)
			designerFrame:SetMovable(true)
			designerFrame:EnableMouse(true)
			designerFrame:RegisterForDrag("LeftButton")
			designerFrame:SetScript("OnDragStart", designerFrame.StartMoving)
			designerFrame:SetScript("OnDragStop", designerFrame.StopMovingOrSizing)

			-- Esc closes it, like a native panel.
			table.insert(UISpecialFrames, designerFrame:GetName())

			Mixin(designerFrame, DesignerMixin)
			designerFrame:Initialize()

			designerFrame:Hide()
		end

		designerFrame:SetShown(not designerFrame:IsShown())
	end
end

Private.Utils.RegisterSlashCommand("design", Private.L.SlashCommands.DesignDescription, function()
	Private.Designer.Toggle()
end)
