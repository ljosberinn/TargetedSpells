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
L.Migration = {}
L.SlashCommands = {}
L.Designer = {}
L.Designer.Title = "Targeted Spells - 布局设计器"
L.Designer.ElementPickerLabel = "元素"
L.Designer.SelectHint = "点击预览中的元素，或从元素下拉菜单中选择。"
L.Designer.ResetElement = "重置元素"
L.Designer.CopyFrom = "从其他组复制布局…"
L.Designer.CopyFromEmpty = "没有其他同类型的组"
L.Designer.Apply = "保存更改"
L.Designer.Revert = "还原"
L.Designer.Discard = "放弃"
L.Designer.UnsavedHint = "保存后更改才会生效。"
L.Designer.UnsavedPrompt = "你有未保存的布局更改。"
L.Designer.SettingNames = { ELEMENT_ACTIVE = "启用", ELEMENT_WIDTH = "宽度", ELEMENT_HEIGHT = "高度", ELEMENT_X = "X 偏移", ELEMENT_Y = "Y 偏移", ELEMENT_FONT_SIZE = "字体大小", ELEMENT_FONT = "字体", ELEMENT_FONT_FLAGS = "字体样式", ELEMENT_TEXT_COLOR = "文字颜色", ELEMENT_JUSTIFY_H = "对齐", ELEMENT_MAX_WIDTH = "最大宽度", ELEMENT_GAP = "间距", ELEMENT_USE_CLASS_COLOR = "使用职业颜色", ELEMENT_ICON_ZOOM = "图标缩放", ELEMENT_SHOW_SWIPE = "显示扫过动画", ELEMENT_SHOW_COUNTDOWN = "显示持续时间", ELEMENT_FRACTION_THRESHOLD = "低于此值显示小数（秒）", ELEMENT_BORDER_TEXTURE = "边框材质", ELEMENT_BORDER_COLOR = "边框颜色", ELEMENT_BORDER_SIZE = "边框大小", ELEMENT_BAR_TEXTURE = "条材质", ELEMENT_BAR_COLOR_MODE = "颜色模式", ELEMENT_BAR_COLOR = "条颜色", ELEMENT_INTERRUPTIBLE_COLOR = "可打断颜色", ELEMENT_UNINTERRUPTIBLE_COLOR = "不可打断颜色", ELEMENT_BACKGROUND_TEXTURE = "背景材质", ELEMENT_BACKGROUND_COLOR = "背景颜色" }
L.Designer.Options = { JUSTIFY_LEFT = "左", JUSTIFY_CENTER = "中", JUSTIFY_RIGHT = "右", BAR_COLOR_STATIC = "固定", BAR_COLOR_INTERRUPTIBILITY = "可打断性", BAR_COLOR_TARGET_CLASS = "目标职业颜色" }
L.Designer.FontFlagNames = { [Private.Enum.FontFlags.OUTLINE] = "描边", [Private.Enum.FontFlags.SHADOW] = "阴影" }
L.Designer.FontFlagsNone = "无"
L.Designer.ElementNames = { [Private.Enum.Element.Icon] = "图标", [Private.Enum.Element.Overlay] = "冷却管理器边框", [Private.Enum.Element.Cooldown] = "冷却", [Private.Enum.Element.Border] = "边框", [Private.Enum.Element.InterruptSource] = "打断者姓名", [Private.Enum.Element.ProgressBar] = "进度条", [Private.Enum.Element.Background] = "背景", [Private.Enum.Element.TargetMarker] = "目标标记", [Private.Enum.Element.DurationCooldown] = "持续时间", [Private.Enum.Element.SpellName] = "法术名称", [Private.Enum.Element.TargetName] = "目标名称", [Private.Enum.Element.InterruptShield] = "打断护盾", [Private.Enum.Element.Duration] = "持续时间" }
L.SlashCommands.Header = "Targeted Spells 命令："
L.SlashCommands.OptionsDescription = "打开设置面板"
L.SlashCommands.SettingsDescription = "打开设置面板"
L.SlashCommands.DesignDescription = "打开布局设计器"

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
L.Settings.GroupNameLabel = "重命名组"
L.Settings.GroupNamePrompt = "输入此组的名称："
L.Settings.TemplateLabel = "模板"
L.Settings.TemplateTooltip = "切换模板会将此组的元素布局重置为模板默认值。"
L.Settings.TemplateLabels = { [Private.Enum.Template.Icon] = "图标", [Private.Enum.Template.Bar] = "条", [Private.Enum.Template.IconDuration] = "图标 + 持续时间" }
L.Settings.FilterLabel = "显示以其为目标的法术"
L.Settings.FilterTooltip = "此组显示哪些目标的法术。"
L.Settings.TargetClassLabels = { [Private.Enum.TargetClass.Player] = "你", [Private.Enum.TargetClass.PartyMember] = "小队成员", [Private.Enum.TargetClass.Nobody] = "无（无目标）" }
L.Settings.CreateGroup = "创建组"
L.Settings.DeleteGroup = "删除组"
L.Settings.DeleteGroupConfirm = "删除此组？此操作无法撤销。"
L.Settings.CannotDeleteLastGroup = "无法删除最后剩余的组。"
