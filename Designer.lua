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

-- Draws the selected group into the canvas. Step 5 replaces the placeholder text
-- with a looping demo frame rendered from self.scratchElements via the injected
-- layout-override seam (TargetedSpellsMixin:SetLayoutOverride).
function DesignerMixin:RefreshCanvas()
	local group = self.selectedGroupId and TargetedSpellsSaved.Groups[self.selectedGroupId]
	if group == nil then
		return
	end

	-- Lua's string.format (not FontString:SetFormattedText, which is C printf and
	-- rejects %q) so the group name is quoted safely.
	self.Canvas.PlaceholderText:SetText(string.format(
		"Editing group %q (template %d)\n\nElement preview & widgets arrive in the next steps.",
		group.Name,
		group.Template
	))
end

function DesignerMixin:Initialize()
	-- Canvas: a bordered inset that will hold the demo frame + selection markers.
	-- Elevated above the ButtonFrame's own regions so preview elements take mouse.
	self.Canvas = CreateFrame("Frame", nil, self, "InsetFrameTemplate")
	self.Canvas:SetPoint("TOPLEFT", self, "TOPLEFT", 12, -32)
	self.Canvas:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -12, 12)
	self.Canvas:EnableMouse(true)
	self.Canvas:SetFrameLevel(self:GetFrameLevel() + 10)

	self.Canvas.PlaceholderText = self.Canvas:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	self.Canvas.PlaceholderText:SetPoint("CENTER")
	self.Canvas.PlaceholderText:SetJustifyH("CENTER")

	-- One PanelTabButton per group. The template auto-resizes to its text on show
	-- and appends itself to self.Tabs; we track our own active set in self.tabs and
	-- drive selection with PanelTemplates_SelectTab/DeselectTab directly.
	self.tabPool = CreateFramePool("Button", self, "PanelTabButtonTemplate")
	---@type table<integer, Button>
	self.tabs = {}
	self.selectedGroupId = nil

	self:SetScript("OnShow", self.RebuildTabs)

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
