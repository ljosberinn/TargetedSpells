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

L.Functionality.V3MigrationWarning = string.format(
	"%s\n\n由于 API 限制更新，Targeted Spells 的小队功能已被完全重新设计。请查看编辑模式以预览效果。",
	addonNameWithIcon
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

L.Settings.OnlyImportantLabel = "仅显示重要法术"

L.Settings.GlowTypeLabel = "高亮类型"
L.Settings.GlowTypeTooltip = nil
L.Settings.GlowTypeLabels = {
	[Private.Enum.GlowType.PixelGlow] = "像素发光",
	[Private.Enum.GlowType.AutoCastGlow] = "自动施法发光",
	[Private.Enum.GlowType.ProcGlow] = "脉冲发光",
	[Private.Enum.GlowType.Star4] = "四星发光",
}

L.Settings.ShowDurationLabel = "显示持续时间"

L.Settings.IndicateInterruptsLabel = "标记可打断法术"

L.Settings.RenderInterruptSourceNameLabel = "显示打断来源名称"

L.Settings.ShowSwipeLabel = "显示滑动"

L.Settings.BorderStyleLabel = "边框样式"
L.Settings.BorderStyleTooltip = nil

L.Settings.ForegroundBarTextureLabel = "进度条纹理"
L.Settings.ForegroundBarTextureTooltip = nil

L.Settings.BackgroundBarTextureLabel = "背景条纹理"
L.Settings.BackgroundBarTextureTooltip = nil

L.Settings.BackgroundBarColorLabel = "背景条颜色"
L.Settings.BackgroundBarColorTooltip =
	"不透明度仅在编辑模式中可用，因为默认设置界面未公开此选项。"

L.Settings.ProgressBarColorLabel = "进度条颜色"
L.Settings.ProgressBarColorTooltip =
	"不透明度仅在编辑模式中可用，因为默认设置界面未公开此选项。"

L.Settings.MirrorLayoutLabel = "镜像布局"

L.Settings.TextToSpeechVoiceLabel = "TTS Voice"
L.Settings.TextToSpeechVoiceTooltip = "Voice for TTS announcements. Shared between Self and Party settings."

L.Settings.AnnounceUntargetedSpellsLabel = "Untargeted TTS Settings"
L.Settings.AnnounceUntargetedSpellsTooltip = "TTS for untargeted spells by NPC type."

L.Settings.AnnounceTargetedSpellsLabel = "Targeted TTS Settings"
L.Settings.AnnounceTargetedSpellsTooltip = "TTS for targeted spells by NPC type."

L.Settings.NpcTypeLabels = {
	[Private.Enum.NpcType.Boss] = "Bosses",
	[Private.Enum.NpcType.Lieutenant] = "Lieutenants",
	[Private.Enum.NpcType.Caster] = "Has Mana",
	[Private.Enum.NpcType.Melee] = "Regular Melee",
	[Private.Enum.NpcType.Minion] = "Minions",
}

L.Settings.HideUntargetedSpellsLabel = "隐藏无目标法术"

L.Settings.HideTargetedSpellsLabel = "隐藏有目标法术"

L.Settings.SelfOnlyLabel = "仅显示针对玩家的法术"

L.Settings.InlineDurationLabel = "内嵌持续时间位置"

L.Settings.UseInterruptabilityColorsLabel = "使用打断颜色"
L.Settings.UseInterruptabilityColorsTooltip = nil

L.Settings.UseTargetClassColorLabel = "使用目标职业颜色"
L.Settings.UseTargetClassColorTooltip =
	"以75%不透明度将条形颜色设为目标单位的职业颜色。未选中目标的法术将使用加亮后的背景条颜色。"

L.Settings.UninterruptibleColorLabel = "不可打断颜色"
L.Settings.UninterruptibleColorTooltip = nil

L.Settings.InterruptibleColorLabel = "可打断颜色"
L.Settings.InterruptibleColorTooltip = nil

L.Settings.IconZoomLabel = "图标缩放"
L.Settings.IconZoomTooltip = nil

L.Settings.ClickToOpenSettingsLabel = "点击打开设置"

L.Settings.Import = "导入"
L.Settings.Export = "导出"

L.Settings.FontLabel = "字体"
L.Settings.FontTooltip = nil

L.Settings.FeatureFlagsLabel = "功能"
L.Settings.FeatureFlagsTooltip = nil

L.Settings.FeatureFlagLabels = {
	[Private.Enum.FeatureFlag.GlowImportant] = L.Settings.GlowImportantLabel,
	[Private.Enum.FeatureFlag.OnlyImportant] = L.Settings.OnlyImportantLabel,
	[Private.Enum.FeatureFlag.ShowDuration] = L.Settings.ShowDurationLabel,
	[Private.Enum.FeatureFlag.ShowSwipe] = L.Settings.ShowSwipeLabel,
	[Private.Enum.FeatureFlag.IndicateInterrupts] = L.Settings.IndicateInterruptsLabel,
	[Private.Enum.FeatureFlag.RenderInterruptSourceName] = L.Settings.RenderInterruptSourceNameLabel,
	[Private.Enum.FeatureFlag.ShowIcon] = "显示图标",
	[Private.Enum.FeatureFlag.ShowTargetMarker] = "显示目标标记",
	[Private.Enum.FeatureFlag.ShowSpellName] = "显示法术名称",
	[Private.Enum.FeatureFlag.ShowTargetName] = "显示目标名称",
	[Private.Enum.FeatureFlag.ShowTargetClassColor] = "显示目标职业颜色",
	[Private.Enum.FeatureFlag.MirrorLayout] = L.Settings.MirrorLayoutLabel,
	[Private.Enum.FeatureFlag.InlineDuration] = L.Settings.InlineDurationLabel,
	[Private.Enum.FeatureFlag.HideUntargetedSpells] = L.Settings.HideUntargetedSpellsLabel,
	[Private.Enum.FeatureFlag.HideTargetedSpells] = L.Settings.HideTargetedSpellsLabel,
	[Private.Enum.FeatureFlag.SelfOnly] = L.Settings.SelfOnlyLabel,
}

L.Settings.FeatureFlagSettingTitles = {
	[Private.Enum.FeatureFlag.GlowImportant] = "显示",
	[Private.Enum.FeatureFlag.IndicateInterrupts] = "打断设置",
}
