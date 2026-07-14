---@type string, TargetedSpells
local addonName, Private = ...

-- Standalone, movable layout designer (Platynator-style). A self-contained
-- ButtonFrameTemplate dialog on UIParent — NOT an edit-mode overlay, and it does
-- not touch LibEditMode. This file holds the frame/UI; the model (schemas,
-- defaults, scratch copies) lives in Design.lua / Groups.lua.
--
-- Phase 5 lands incrementally: step 2 here is the outer window scaffold (title
-- bar, close, drag, Esc-to-close). Group tabs, the InsetFrameTemplate canvas, the
-- demo frame and the schema-driven widget panel arrive in the following steps.

-- Lazily built on first Toggle so nothing is created for users who never open it.
local designerFrame

---@return Frame
local function BuildFrame()
	local frame = CreateFrame("Frame", "TargetedSpellsDesigner", UIParent, "ButtonFrameTemplate")

	-- Strip the game-panel weight ButtonFrameTemplate carries but we don't want:
	-- the portrait, the bottom button bar, and the default inset (the canvas
	-- supplies its own InsetFrameTemplate in a later step).
	ButtonFrameTemplate_HidePortrait(frame)
	ButtonFrameTemplate_HideButtonBar(frame)
	frame.Inset:Hide()

	frame:SetTitle(Private.L.Designer.Title)
	frame:SetSize(720, 480)
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

	frame:Hide()

	return frame
end

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
