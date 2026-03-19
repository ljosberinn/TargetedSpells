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
	"建议使用编辑模式，它包含所有设置的实时预览。\n这些设置仅在此处提供，以便在战斗中也能编辑。"
L.EditMode.TargetedSpellsSelfLabel = "目标法术 - 自身"
L.EditMode.TargetedSpellsPartyLabel = "目标法术 - 小队"

L.Functionality.CVarWarning = string.format(
	"%s\n\n姓名板设置 '%s' 已被禁用。\n\n没有它，%s 将无法对屏幕外的敌人生效。\n\n点击 '%s' 以重新启用。",
	addonNameWithIcon,
	UNIT_NAMEPLATES_SHOW_OFFSCREEN,
	addonName,
	ENABLE
)

L.Functionality.V2DeprecationWarning = string.format(
	"%s\n\nDue to the changes in v2, the following settings were reset for you:\n\n%s\n\nAdditionally, we suggest verifying your layouting as it may also be impacted.",
	addonNameWithIcon,
	"%s"
)

L.Settings.EnabledLabel = "启用"
L.Settings.EnabledTooltip = nil
L.Settings.DisabledLabel = "禁用"

L.Settings.AddonCompartmentTooltipLine1 =
	string.format("%s 已%s", WrapTextInColorCode(L.EditMode.TargetedSpellsSelfLabel, "ffeda55f"), "%s")
L.Settings.AddonCompartmentTooltipLine2 =
	string.format("%s 已%s", WrapTextInColorCode(L.EditMode.TargetedSpellsPartyLabel, "ffeda55f"), "%s")

L.Settings.LoadConditionContentTypeLabel = "加载条件：区域"
L.Settings.LoadConditionContentTypeLabelAbbreviated = "在以下区域中加载"
L.Settings.LoadConditionContentTypeTooltip = nil
L.Settings.LoadConditionContentTypeLabels = {
	[Private.Enum.ContentType.OpenWorld] = "世界",
	[Private.Enum.ContentType.Delve] = "地下堡",
	[Private.Enum.ContentType.Dungeon] = "地下城",
	[Private.Enum.ContentType.Raid] = "团队副本",
	[Private.Enum.ContentType.Arena] = "竞技场",
	[Private.Enum.ContentType.Battleground] = "战场",
}

L.Settings.LoadConditionRoleLabel = "加载条件：职责"
L.Settings.LoadConditionRoleLabelAbbreviated = "在以下职责加载"
L.Settings.LoadConditionRoleTooltip = nil
L.Settings.LoadConditionRoleLabels = {
	[Private.Enum.Role.Healer] = "治疗",
	[Private.Enum.Role.Tank] = "坦克",
	[Private.Enum.Role.Damager] = "输出",
}

L.Settings.RoleFilterLabel = "Role Filter"
L.Settings.RoleFilterTooltip = "Allows you to ignore certain roles from being shown. Use at your own risk."
L.Settings.RoleFilterLabels = L.Settings.LoadConditionRoleLabels

L.Settings.FrameWidthLabel = "宽度"
L.Settings.FrameWidthTooltip = nil

L.Settings.FrameHeightLabel = "高度"
L.Settings.FrameHeightTooltip = nil

L.Settings.FontSizeLabel = "字体大小"
L.Settings.FontSizeTooltip = nil

L.Settings.FontFlagsLabel = "字体选项"
L.Settings.FontFlagsTooltip = nil
L.Settings.FontFlagsLabels = {
	[Private.Enum.FontFlags.OUTLINE] = "轮廓",
	[Private.Enum.FontFlags.SHADOW] = "阴影",
}

L.Settings.FrameGapLabel = "间距"
L.Settings.FrameGapTooltip = nil

L.Settings.FrameDirectionLabel = "方向"
L.Settings.FrameDirectionTooltip = nil
L.Settings.FrameDirectionHorizontal = "水平"
L.Settings.FrameDirectionVertical = "垂直"

L.Settings.FrameSortOrderLabel = "排序顺序"
L.Settings.FrameSortOrderTooltip = nil
L.Settings.FrameSortOrderAscending = "升序"
L.Settings.FrameSortOrderDescending = "降序"

L.Settings.FrameGrowLabel = "增长方向"
L.Settings.FrameGrowTooltip = nil
L.Settings.FrameGrowLabels = {
	[Private.Enum.Grow.Start] = "起始",
	[Private.Enum.Grow.End] = "末端",
}

L.Settings.GlowImportantLabel = "高亮重要法术"
L.Settings.GlowImportantTooltip = "重要与否完全由游戏本身决定。"

L.Settings.OnlyImportantLabel = "Only Show Important Spells"
L.Settings.OnlyImportantTooltip = "Note that you're relying on what the game considers important, use at your own risk."

L.Settings.GlowTypeLabel = "高亮类型"
L.Settings.GlowTypeTooltip = nil
L.Settings.GlowTypeLabels = {
	[Private.Enum.GlowType.PixelGlow] = "像素发光",
	[Private.Enum.GlowType.AutoCastGlow] = "自动施法发光",
	[Private.Enum.GlowType.ProcGlow] = "脉冲发光",
	[Private.Enum.GlowType.Star4] = "四星发光",
}

L.Settings.ShowDurationLabel = "显示持续时间"
L.Settings.ShowDurationTooltip = nil

L.Settings.ShowDurationFractionsLabel = "显示小数"
L.Settings.ShowDurationFractionsTooltip = nil

L.Settings.IndicateInterruptsLabel = "标记可打断法术"
L.Settings.IndicateInterruptsTooltip =
	"使图标去色，在图标上显示标记，并延迟1秒隐藏图标。对引导类法术无效。"

L.Settings.RenderInterruptSourceNameLabel = "Render Interrupt Source Name"
L.Settings.RenderInterruptSourceNameTooltip = nil

L.Settings.ShowSwipeLabel = "显示滑动"
L.Settings.ShowSwipeTooltip = nil

L.Settings.BorderStyleLabel = "Border Style"
L.Settings.BorderStyleTooltip = nil
L.Settings.BorderStyleSolid = "Solid"

L.Settings.OpacityLabel = "不透明度"
L.Settings.OpacityTooltip = nil

L.Settings.IconZoomLabel = "Icon Zoom"
L.Settings.IconZoomTooltip = nil

L.Settings.FrameOffsetXLabel = "X轴偏移"
L.Settings.FrameOffsetXTooltip = nil

L.Settings.FrameOffsetYLabel = "Y轴偏移"
L.Settings.FrameOffsetYTooltip = nil

L.Settings.FrameSourceAnchorLabel = "源锚点"
L.Settings.FrameSourceAnchorTooltip = nil

L.Settings.FrameTargetAnchorLabel = "目标锚点"
L.Settings.FrameTargetAnchorTooltip = nil

L.Settings.IncludeSelfInPartyLabel = "在小队中包含自己"
L.Settings.IncludeSelfInPartyTooltip = "仅在使用团队样式小队框架时生效。"

L.Settings.ClickToOpenSettingsLabel = "点击打开设置"

L.Settings.Import = "导入"
L.Settings.Export = "导出"

L.Settings.FontLabel = "字体"
L.Settings.FontTooltip = nil

L.Settings.FeatureFlagsLabel = "Features"
L.Settings.FeatureFlagsTooltip = nil

L.Settings.FeatureFlagLabels = {
	[Private.Enum.FeatureFlag.GlowImportant] = L.Settings.GlowImportantLabel,
	[Private.Enum.FeatureFlag.OnlyImportant] = L.Settings.OnlyImportantLabel,
	[Private.Enum.FeatureFlag.ShowDuration] = L.Settings.ShowDurationLabel,
	[Private.Enum.FeatureFlag.ShowDurationFractions] = L.Settings.ShowDurationFractionsLabel,
	[Private.Enum.FeatureFlag.ShowSwipe] = L.Settings.ShowSwipeLabel,
	[Private.Enum.FeatureFlag.IndicateInterrupts] = L.Settings.IndicateInterruptsLabel,
	[Private.Enum.FeatureFlag.RenderInterruptSourceName] = L.Settings.RenderInterruptSourceNameLabel,
	[Private.Enum.FeatureFlag.IncludeSelfInParty] = L.Settings.IncludeSelfInPartyLabel,
}

L.Settings.FeatureFlagSettingTitles = {
	[Private.Enum.FeatureFlag.GlowImportant] = "Display",
	[Private.Enum.FeatureFlag.IndicateInterrupts] = "Interrupt Settings",
	[Private.Enum.FeatureFlag.IncludeSelfInParty] = "Party Settings",
}
