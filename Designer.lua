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
	self.demoFrame:SetParent(self.Canvas)
	self.demoFrame:ClearAllPoints()
	self.demoFrame:SetPoint("CENTER", self.Canvas, "CENTER", 0, 0)
	self.demoFrame:SetFrameStrata(self.Canvas:GetFrameStrata())
	self.demoFrame:SetFrameLevel(self.Canvas:GetFrameLevel() + 5)

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

function DesignerMixin:Initialize()
	-- Canvas: a bordered inset that will hold the demo frame + selection markers.
	-- Elevated above the ButtonFrame's own regions so preview elements take mouse.
	self.Canvas = CreateFrame("Frame", nil, self, "InsetFrameTemplate")
	self.Canvas:SetPoint("TOPLEFT", self, "TOPLEFT", 12, -32)
	self.Canvas:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -12, 12)
	self.Canvas:EnableMouse(true)
	self.Canvas:SetFrameLevel(self:GetFrameLevel() + 10)

	self.Canvas.Hint = self.Canvas:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
	self.Canvas.Hint:SetPoint("BOTTOM", self.Canvas, "BOTTOM", 0, 10)
	self.Canvas.Hint:SetText("Live preview - element selection & widgets arrive in the next steps.")

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
