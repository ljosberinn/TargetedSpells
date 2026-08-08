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
	"所有设置均可通过编辑模式和 \"/targetedspells design\" 进行调整。"
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
L.Settings.DisabledLabel = "禁用"

L.Settings.AddonCompartmentTooltipLine1 =
	string.format("%s 已%s", WrapTextInColorCode(L.EditMode.TargetedSpellsSelfLabel, "ffeda55f"), "%s")
L.Settings.AddonCompartmentTooltipLine2 =
	string.format("%s 已%s", WrapTextInColorCode(L.EditMode.TargetedSpellsPartyLabel, "ffeda55f"), "%s")

L.Settings.LoadConditionContentTypeLabel = "加载条件：区域"
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
L.Settings.LoadConditionRoleTooltip = nil
L.Settings.LoadConditionRoleLabels = {
	[Private.Enum.Role.Healer] = "治疗",
	[Private.Enum.Role.Tank] = "坦克",
	[Private.Enum.Role.Damager] = "输出",
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

L.Settings.IndicateInterruptsLabel = "标记可打断法术"

L.Settings.TextToSpeechVoiceLabel = "TTS Voice"
L.Settings.TextToSpeechVoiceTooltip = "Voice for TTS announcements. Shared between Self and Party settings."

L.Settings.AnnounceUntargetedSpellsLabel = "Untargeted TTS Settings"
L.Settings.AnnounceUntargetedSpellsTooltip = "TTS for untargeted spells by NPC type."

L.Settings.AnnounceTargetedSpellsLabel = "Targeted TTS Settings"
L.Settings.AnnounceTargetedSpellsTooltip = "TTS for targeted spells by NPC type."

L.Settings.NpcTypeLabels = {
	[Private.Enum.NpcType.Boss] = "Bosses",
	[Private.Enum.NpcType.Lieutenant] = "Lieutenants",
	[Private.Enum.NpcType.Other] = "其他单位",
	[Private.Enum.NpcType.Minion] = "Minions",
}

L.Settings.UseTargetClassColorLabel = "使用目标职业颜色"
L.Settings.UseTargetClassColorTooltip =
	"以75%不透明度将条形颜色设为目标单位的职业颜色。未选中目标的法术将使用加亮后的背景条颜色。"

L.Settings.ClickToOpenSettingsLabel = "点击打开设置"

L.Settings.Import = "导入"
L.Settings.Export = "导出"

L.Settings.FeatureFlagsLabel = "功能"
L.Settings.FeatureFlagsTooltip = nil
