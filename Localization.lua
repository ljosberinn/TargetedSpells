---@type string, TargetedSpells
local addonName, Private = ...

local L = Private.L

L.Settings = {}
L.Settings.EnabledLabel = "Enabled"
L.Settings.EnabledTooltip = nil

L.Settings.LoadConditionContentTypeLabel = "Load Condition: Content Type"
L.Settings.LoadConditionContentTypeLabelAbbreviated = "Load in Content"
-- todo: individual content type tooltips
L.Settings.LoadConditionContentTypeTooltip = nil

L.Settings.LoadConditionRoleLabel = "Load Condition: Role"
L.Settings.LoadConditionRoleLabelAbbreviated = "Load on Role"
-- todo: individual role tooltips
L.Settings.LoadConditionRoleTooltip = nil

L.Settings.MaxFramesLabel = "Max Frames"
L.Settings.MaxFramesTooltip = nil

L.Settings.FrameWidthLabel = "Width"
L.Settings.FrameWidthTooltip = nil

L.Settings.FrameHeightLabel = "Height"
L.Settings.FrameHeightTooltip = nil

L.Settings.FontSizeLabel = "Font Size"
L.Settings.FontSizeTooltip = nil

L.Settings.FrameGapLabel = "Gap"
L.Settings.FrameGapTooltip = nil

L.Settings.FrameDirectionLabel = "Direction"
L.Settings.FrameDirectionTooltip = nil

L.Settings.FrameSortOrderLabel = "Sort Order"
L.Settings.FrameSortOrderTooltip = nil

L.Settings.FrameGrowLabel = "Grow"
L.Settings.FrameGrowTooltip = nil

L.Settings.GlowImportantLabel = "Glow Important Spells"
L.Settings.GlowImportantTooltip = "What's important and what isn't is declared by the game."
L.Settings.GlowImportantWarning =
	"[Targeted Spells] this addon patched action button glows to fix a bug when they show. As you just disabled this feature, you may want to /reload to disable the fix too."

L.Settings.PlaySoundLabel = "Play Sound"
L.Settings.PlaySoundTooltip = nil

L.Settings.SoundLabel = "Sound"
L.Settings.SoundCategoryCustom = "Custom"
L.Settings.SoundTooltip = nil

L.Settings.SoundChannelLabel = "Sound Channel"
L.Settings.SoundChannelTooltip = nil

L.Settings.ShowDurationLabel = "Show Duration"
L.Settings.ShowDurationTooltip = nil

L.Settings.ShowBorderLabel = "Show Border"
L.Settings.ShowBorderTooltip = nil

L.Settings.OpacityLabel = "Opacity"
L.Settings.OpacityTooltip = nil

L.Settings.FrameOffsetXLabel = "Offset X"
L.Settings.FrameOffsetXTooltip = nil

L.Settings.FrameOffsetYLabel = "Offset Y"
L.Settings.FrameOffsetYTooltip = nil

L.Settings.FrameSourceAnchorLabel = "Source Anchor"
L.Settings.FrameSourceAnchorTooltip = nil

L.Settings.FrameTargetAnchorLabel = "Target Anchor"
L.Settings.FrameTargetAnchorTooltip = nil

L.Settings.IncludeSelfInPartyLabel = "Include Self In Party"
L.Settings.IncludeSelfInPartyTooltip = nil

L.Settings.ClickToOpenSettingsLabel = "Click to open settings"

local locale = GAME_LOCALE or GetLocale()

if locale == "deDE" then
elseif locale == "esES" or locale == "esMX" then
elseif locale == "frFR" then
elseif locale == "itIT" then
elseif locale == "koKO" then
elseif locale == "ptBR" then
elseif locale == "ruRU" then
elseif locale == "zhCN" then
elseif locale == "zhTW" then
end
