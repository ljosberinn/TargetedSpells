---@type string, TargetedSpells
local addonName, Private = ...

local addonNameWithIcon = ""

do
	local icon = C_AddOns.GetAddOnMetadata(addonName, "IconTexture")
	-- width, height, offsetX, offsetY
	addonNameWithIcon = string.format("|T%s:%d:%d:%d:%d|t %s", icon, 20, 20, 0, -4, addonName)
end

local L = Private.L

L.EditMode = {}
L.Functionality = {}
L.Settings = {}

L.Settings.EditModeReminder =
	"Consider using the Edit Mode instead, it includes live preview of all settings.\nThese here are only present to allow editing in combat."
L.EditMode.TargetedSpellsSelfLabel = "Targeted Spells - Self"
L.EditMode.TargetedSpellsPartyLabel = "Targeted Spells - Party"

L.Functionality.CVarWarning = string.format(
	"%s\n\nThe Nameplate Setting '%s' was disabled.\n\nWithout it, %s will not work on off-screen enemies.\n\nClick '%s' to enable it again.",
	addonNameWithIcon,
	UNIT_NAMEPLATES_SHOW_OFFSCREEN,
	addonName,
	ENABLE
)

L.Functionality.V3DeprecationWarning = "TODO"

L.Settings.EnabledLabel = "Enabled"
L.Settings.EnabledTooltip = nil
L.Settings.DisabledLabel = "Disabled"

L.Settings.AddonCompartmentTooltipLine1 =
	string.format("%s is %s", WrapTextInColorCode(L.EditMode.TargetedSpellsSelfLabel, "ffeda55f"), "%s")
L.Settings.AddonCompartmentTooltipLine2 =
	string.format("%s is %s", WrapTextInColorCode(L.EditMode.TargetedSpellsPartyLabel, "ffeda55f"), "%s")

L.Settings.LoadConditionContentTypeLabel = "Load Condition: Content Type"
L.Settings.LoadConditionContentTypeLabelAbbreviated = "Load in Content"
L.Settings.LoadConditionContentTypeTooltip = nil
L.Settings.LoadConditionContentTypeLabels = {
	[Private.Enum.ContentType.OpenWorld] = "Open World",
	[Private.Enum.ContentType.Delve] = "Delves",
	[Private.Enum.ContentType.Dungeon] = "Dungeon",
	[Private.Enum.ContentType.Raid] = "Raid",
	[Private.Enum.ContentType.Arena] = "Arena",
	[Private.Enum.ContentType.Battleground] = "Battleground",
}

L.Settings.LoadConditionRoleLabel = "Load Condition: Role"
L.Settings.LoadConditionRoleLabelAbbreviated = "Load on Role"
L.Settings.LoadConditionRoleTooltip = nil
L.Settings.LoadConditionRoleLabels = {
	[Private.Enum.Role.Healer] = "Healer",
	[Private.Enum.Role.Tank] = "Tank",
	[Private.Enum.Role.Damager] = "DPS",
}

L.Settings.FrameWidthLabel = "Width"
L.Settings.FrameWidthTooltip = nil

L.Settings.FrameHeightLabel = "Height"
L.Settings.FrameHeightTooltip = nil

L.Settings.FontSizeLabel = "Font Size"
L.Settings.FontSizeTooltip = nil

L.Settings.FontFlagsLabel = "Font Options"
L.Settings.FontFlagsTooltip = nil
L.Settings.FontFlagsLabels = {
	[Private.Enum.FontFlags.OUTLINE] = "Outline",
	[Private.Enum.FontFlags.SHADOW] = "Shadow",
}

L.Settings.FrameGapLabel = "Gap"
L.Settings.FrameGapTooltip = nil

L.Settings.FrameDirectionLabel = "Direction"
L.Settings.FrameDirectionTooltip = nil
L.Settings.FrameDirectionHorizontal = "Horizontal"
L.Settings.FrameDirectionVertical = "Vertical"

L.Settings.FrameSortOrderLabel = "Sort Order"
L.Settings.FrameSortOrderTooltip = nil
L.Settings.FrameSortOrderAscending = "Ascending"
L.Settings.FrameSortOrderDescending = "Descending"

L.Settings.FrameGrowLabel = "Grow"
L.Settings.FrameGrowTooltip = nil
L.Settings.FrameGrowLabels = {
	[Private.Enum.Grow.Start] = "Start",
	[Private.Enum.Grow.End] = "End",
}

L.Settings.GlowImportantLabel = "Glow Important Spells"
L.Settings.GlowImportantTooltip = "What's important and what isn't is declared by the game."

L.Settings.OnlyImportantLabel = "Only Show Important Spells"
L.Settings.OnlyImportantTooltip = "Note that you're relying on what the game considers important, use at your own risk."

L.Settings.GlowTypeLabel = "Glow Type"
L.Settings.GlowTypeTooltip = nil
L.Settings.GlowTypeLabels = {
	[Private.Enum.GlowType.PixelGlow] = "Pixel Glow",
	[Private.Enum.GlowType.AutoCastGlow] = "Auto Cast Glow",
	[Private.Enum.GlowType.ProcGlow] = "Proc Glow",
	[Private.Enum.GlowType.Star4] = "Star 4",
}

L.Settings.ShowDurationLabel = "Show Duration"
L.Settings.ShowDurationTooltip = nil

L.Settings.IndicateInterruptsLabel = "Indicate Interrupts"
L.Settings.IndicateInterruptsTooltip =
	"Desaturates the icon, shows an indicator on top of the icon and delays hiding the icon by 1 second. Does not work with channeled spells."

L.Settings.RenderInterruptSourceNameLabel = "Render Interrupt Source Name"
L.Settings.RenderInterruptSourceNameTooltip = nil

L.Settings.ShowSwipeLabel = "Show Swipe"
L.Settings.ShowSwipeTooltip = nil

L.Settings.BorderStyleLabel = "Border Style"
L.Settings.BorderStyleTooltip = nil

L.Settings.OpacityLabel = "Opacity"
L.Settings.OpacityTooltip = nil

L.Settings.SpellNameWidthLabel = "Spell Name Length"
L.Settings.SpellNameWidthTooltip = "Maximum width of the spell name text. Set to 0 for no limit."

L.Settings.TargetNameWidthLabel = "Target Name Length"
L.Settings.TargetNameWidthTooltip = "Maximum width of the target name text. Set to 0 for no limit."

L.Settings.NameDividerLabel = "Name Divider"
L.Settings.NameDividerTooltip = nil
L.Settings.NameDividerNone = "None"

L.Settings.ForegroundBarTextureLabel = "Progress Bar Texture"
L.Settings.ForegroundBarTextureTooltip = nil

L.Settings.BackgroundBarTextureLabel = "Background Bar Texture"
L.Settings.BackgroundBarTextureTooltip = nil

L.Settings.BackgroundBarColorLabel = "Background Bar Color"
L.Settings.BackgroundBarColorTooltip =
	"Opacity is only available in Edit Mode due to the default settings UI not exposing it."

L.Settings.IconZoomLabel = "Icon Zoom"
L.Settings.IconZoomTooltip = nil

L.Settings.ClickToOpenSettingsLabel = "Click to open settings"

L.Settings.Import = "Import"
L.Settings.Export = "Export"

L.Settings.FontLabel = "Font"
L.Settings.FontTooltip = nil

L.Settings.TargetNamePreviewText = "Target Name"

L.Settings.FeatureFlagsLabel = "Features"
L.Settings.FeatureFlagsTooltip = nil

L.Settings.FeatureFlagLabels = {
	[Private.Enum.FeatureFlag.GlowImportant] = L.Settings.GlowImportantLabel,
	[Private.Enum.FeatureFlag.OnlyImportant] = L.Settings.OnlyImportantLabel,
	[Private.Enum.FeatureFlag.ShowDuration] = L.Settings.ShowDurationLabel,
	[Private.Enum.FeatureFlag.ShowSwipe] = L.Settings.ShowSwipeLabel,
	[Private.Enum.FeatureFlag.IndicateInterrupts] = L.Settings.IndicateInterruptsLabel,
	[Private.Enum.FeatureFlag.RenderInterruptSourceName] = L.Settings.RenderInterruptSourceNameLabel,
	[Private.Enum.FeatureFlag.ShowIcon] = "Show Icon",
	[Private.Enum.FeatureFlag.ShowTargetMarker] = "Show Target Marker",
	[Private.Enum.FeatureFlag.ShowSpellName] = "Show Spell Name",
	[Private.Enum.FeatureFlag.ShowTargetName] = "Show Target Name",
	[Private.Enum.FeatureFlag.ShowTargetClassColor] = "Show Target Class Color",
}

L.Settings.FeatureFlagSettingTitles = {
	[Private.Enum.FeatureFlag.GlowImportant] = "Display",
	[Private.Enum.FeatureFlag.IndicateInterrupts] = "Interrupt Settings",
}
