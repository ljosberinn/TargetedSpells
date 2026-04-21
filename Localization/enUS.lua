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

L.Functionality.V3MigrationWarning = string.format(
	"%s\n\nDue to API restriction updates, the Party functionality for Targeted Spells had to be completely overhauled. Please check out Edit Mode for a preview.",
	addonNameWithIcon
)

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

L.Settings.OnlyImportantLabel = "Only Show Important Spells"

L.Settings.GlowTypeLabel = "Glow Type"
L.Settings.GlowTypeTooltip = nil
L.Settings.GlowTypeLabels = {
	[Private.Enum.GlowType.PixelGlow] = "Pixel Glow",
	[Private.Enum.GlowType.AutoCastGlow] = "Auto Cast Glow",
	[Private.Enum.GlowType.ProcGlow] = "Proc Glow",
	[Private.Enum.GlowType.Star4] = "Star 4",
}

L.Settings.ShowDurationLabel = "Show Duration"

L.Settings.IndicateInterruptsLabel = "Indicate Interrupts"

L.Settings.RenderInterruptSourceNameLabel = "Render Interrupt Source Name"

L.Settings.ShowSwipeLabel = "Show Swipe"

L.Settings.BorderStyleLabel = "Border Style"
L.Settings.BorderStyleTooltip = nil

L.Settings.ForegroundBarTextureLabel = "Progress Bar Texture"
L.Settings.ForegroundBarTextureTooltip = nil

L.Settings.BackgroundBarTextureLabel = "Background Bar Texture"
L.Settings.BackgroundBarTextureTooltip = nil

L.Settings.BackgroundBarColorLabel = "Background Bar Color"
L.Settings.BackgroundBarColorTooltip =
	"Opacity is only available in Edit Mode due to the default settings UI not exposing it."

L.Settings.ProgressBarColorLabel = "Bar Color"
L.Settings.ProgressBarColorTooltip =
	"Opacity is only available in Edit Mode due to the default settings UI not exposing it."

L.Settings.MirrorLayoutLabel = "Mirror Layout"

L.Settings.TextToSpeechVoiceLabel = "TTS Voice"
L.Settings.TextToSpeechVoiceTooltip =
	"Voice used for Text-To-Speech announcements. Shared between Self and Party settings."

L.Settings.AnnounceUntargetedSpellsLabel = "Untargeted TTS Settings"
L.Settings.AnnounceUntargetedSpellsTooltip = "Text-To-Speech for untargeted spells (AoE, frontals, etc.) by NPC type."

L.Settings.AnnounceTargetedSpellsLabel = "Targeted TTS Settings"
L.Settings.AnnounceTargetedSpellsTooltip = "Text-To-Speech for spells that target a specific player, by NPC type."

L.Settings.NpcTypeLabels = {
	[Private.Enum.NpcType.Boss] = "Bosses",
	[Private.Enum.NpcType.Lieutenant] = "Lieutenants",
	[Private.Enum.NpcType.Caster] = "Has Mana",
	[Private.Enum.NpcType.Melee] = "Regular Melee",
	[Private.Enum.NpcType.Minion] = "Minions",
}

L.Settings.HideUntargetedSpellsLabel = "Hide Untargeted Spells"

L.Settings.HideTargetedSpellsLabel = "Hide Targeted Spells"

L.Settings.SelfOnlyLabel = "Only Show Player-Targeting Spells"

L.Settings.InlineDurationLabel = "Inline Duration Position"

L.Settings.UseInterruptabilityColorsLabel = "Use Interrupt Colors"
L.Settings.UseInterruptabilityColorsTooltip = nil

L.Settings.UseTargetClassColorLabel = "Use Target Class Color"
L.Settings.UseTargetClassColorTooltip =
	"Colors the bar in the class color of the targeted unit at 75% alpha. Untargeted spells will use a brightened Background Bar Color"

L.Settings.UninterruptibleColorLabel = "Uninterruptible Color"
L.Settings.UninterruptibleColorTooltip = nil

L.Settings.InterruptibleColorLabel = "Interruptible Color"
L.Settings.InterruptibleColorTooltip = nil

L.Settings.IconZoomLabel = "Icon Zoom"
L.Settings.IconZoomTooltip = nil

L.Settings.ClickToOpenSettingsLabel = "Click to open settings"

L.Settings.Import = "Import"
L.Settings.Export = "Export"

L.Settings.FontLabel = "Font"
L.Settings.FontTooltip = nil

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
	[Private.Enum.FeatureFlag.MirrorLayout] = L.Settings.MirrorLayoutLabel,
	[Private.Enum.FeatureFlag.InlineDuration] = L.Settings.InlineDurationLabel,
	[Private.Enum.FeatureFlag.HideUntargetedSpells] = L.Settings.HideUntargetedSpellsLabel,
	[Private.Enum.FeatureFlag.HideTargetedSpells] = L.Settings.HideTargetedSpellsLabel,
	[Private.Enum.FeatureFlag.SelfOnly] = L.Settings.SelfOnlyLabel,
}

L.Settings.FeatureFlagSettingTitles = {
	[Private.Enum.FeatureFlag.GlowImportant] = "Display",
	[Private.Enum.FeatureFlag.IndicateInterrupts] = "Interrupt Settings",
}
