---@type string, TargetedSpells
local addonName, Private = ...

local L = Private.L

L.Settings = {}
L.Settings.EnabledLabel = "Enabled"
L.Settings.EnabledTooltip = "Tooltip"

L.Settings.LoadConditionContentTypeLabel = "Load Condition: Content Type"
L.Settings.LoadConditionContentTypeLabelAbbreviated = "Load in Content"
-- todo: individual content type tooltips
L.Settings.LoadConditionContentTypeTooltip = "Tooltip"

L.Settings.LoadConditionRoleLabel = "Load Condition: Role"
L.Settings.LoadConditionRoleLabelAbbreviated = "Load on Role"
-- todo: individual role tooltips
L.Settings.LoadConditionRoleTooltip = "Tooltip"

L.Settings.MaxFramesLabel = "Max Frames"
L.Settings.MaxFramesTooltip = "Tooltip"

L.Settings.FrameWidthLabel = "Width"
L.Settings.FrameWidthTooltip = "Tooltip"

L.Settings.FrameHeightLabel = "Height"
L.Settings.FrameHeightTooltip = "Tooltip"

L.Settings.FontSizeLabel = "Font Size"
L.Settings.FontSizeTooltip = "Tooltip"

L.Settings.FrameGapLabel = "Gap"
L.Settings.FrameGapTooltip = "Tooltip"

L.Settings.FrameDirectionLabel = "Direction"
L.Settings.FrameDirectionTooltip = "Tooltip"

L.Settings.FrameSortOrderLabel = "Sort Order"
L.Settings.FrameSortOrderTooltip = "Tooltip"

L.Settings.FrameGrowLabel = "Grow"
L.Settings.FrameGrowTooltip = "Tooltip"

L.Settings.PlaySoundLabel = "Play Sound"
L.Settings.PlaySoundTooltip = "Tooltip"

L.Settings.SoundLabel = "Sound"
L.Settings.SoundCategoryCustom = "Custom"
L.Settings.SoundTooltip = "Tooltip"

L.Settings.SoundChannelLabel = "Sound Channel"
L.Settings.SoundChannelTooltip = "Tooltip"

L.Settings.ShowDurationLabel = "Show Duration"
L.Settings.ShowDurationTooltip = "Tooltip"

L.Settings.OpacityLabel = "Opacity"
L.Settings.OpacityTooltip = "Tooltip"

L.Settings.FrameOffsetXLabel = "Offset X"
L.Settings.FrameOffsetXTooltip = "Tooltip"

L.Settings.FrameOffsetYLabel = "Offset Y"
L.Settings.FrameOffsetYTooltip = "Tooltip"

L.Settings.FrameSourceAnchorLabel = "Source Anchor"
L.Settings.FrameSourceAnchorTooltip = "Tooltip"

L.Settings.FrameTargetAnchorLabel = "Target Anchor"
L.Settings.FrameTargetAnchorTooltip = "Tooltip"

L.Settings.IncludeSelfInPartyLabel = "Include Self In Party"
L.Settings.IncludeSelfInPartyTooltip = "Tooltip"

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
