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
L.SlashCommands = {}
L.Designer = {}
L.Groups = {}

L.Designer.Title = "Targeted Spells - 布局设计器"
L.Designer.ElementPickerLabel = "元素"
L.Designer.SelectHint = "点击预览中的元素，或从元素下拉菜单中选择。"
L.Designer.ResetElement = "重置元素"
L.Designer.CopyFrom = "从其他组复制布局…"
L.Designer.CopyFromEmpty = "没有其他同类型的组"
L.Designer.Apply = SAVE_CHANGES
L.Designer.Revert = HUD_EDIT_MODE_REVERT_CHANGES
L.Designer.Discard = "放弃"
L.Designer.UnsavedHint = "保存后更改才会生效。"
L.Designer.UnsavedPrompt = "你有未保存的布局更改。"

L.Designer.SettingNames = {
	ELEMENT_ACTIVE = VIDEO_OPTIONS_ENABLED,
	ELEMENT_WIDTH = "宽度",
	ELEMENT_HEIGHT = "高度",
	ELEMENT_X = "X 偏移",
	ELEMENT_Y = "Y 偏移",
	ELEMENT_FONT_SIZE = FONT_SIZE,
	ELEMENT_FONT = "字体",
	ELEMENT_FONT_FLAGS = "字体样式",
	ELEMENT_TEXT_COLOR = "文字颜色",
	ELEMENT_JUSTIFY_H = "对齐",
	ELEMENT_MAX_WIDTH = "最大宽度",
	ELEMENT_GAP = "间距",
	ELEMENT_USE_CLASS_COLOR = "使用职业颜色",
	ELEMENT_ICON_ZOOM = "图标缩放",
	ELEMENT_SHOW_SWIPE = "显示扫过动画",
	ELEMENT_SHOW_COUNTDOWN = "显示持续时间",
	ELEMENT_FRACTION_THRESHOLD = "低于此值显示小数（秒）",
	ELEMENT_BORDER_TEXTURE = "边框材质",
	ELEMENT_BORDER_COLOR = "边框颜色",
	ELEMENT_BORDER_SIZE = "边框大小",
	ELEMENT_BAR_TEXTURE = "条材质",
	ELEMENT_BAR_COLOR_MODE = "颜色模式",
	ELEMENT_BAR_COLOR = "条颜色",
	ELEMENT_INTERRUPTIBLE_COLOR = "可打断颜色",
	ELEMENT_UNINTERRUPTIBLE_COLOR = "不可打断颜色",
	ELEMENT_BACKGROUND_TEXTURE = "背景材质",
	ELEMENT_BACKGROUND_COLOR = "背景颜色",
}

L.Designer.Options = {
	JUSTIFY_LEFT = "左",
	JUSTIFY_CENTER = "中",
	JUSTIFY_RIGHT = "右",
	BAR_COLOR_STATIC = "固定",
	BAR_COLOR_INTERRUPTIBILITY = "可打断性",
	BAR_COLOR_TARGET_CLASS = "目标职业颜色",
}

L.Designer.FontFlagNames = {
	[Private.Enum.FontFlags.OUTLINE] = "描边",
	[Private.Enum.FontFlags.SHADOW] = "阴影",
}
L.Designer.FontFlagsNone = "无"

L.Designer.ElementNames = {
	[Private.Enum.Element.Icon] = UNIT_NAMEPLATES_CAST_BAR_DISPLAY_SPELL_ICON,
	[Private.Enum.Element.Overlay] = "冷却管理器边框",
	[Private.Enum.Element.Cooldown] = "冷却",
	[Private.Enum.Element.Border] = "边框",
	[Private.Enum.Element.InterruptSource] = "打断者姓名",
	[Private.Enum.Element.ProgressBar] = "进度条",
	[Private.Enum.Element.Background] = "背景",
	[Private.Enum.Element.TargetMarker] = "目标标记",
	[Private.Enum.Element.DurationCooldown] = "持续时间",
	[Private.Enum.Element.SpellName] = UNIT_NAMEPLATES_CAST_BAR_DISPLAY_SPELL_NAME,
	[Private.Enum.Element.TargetName] = UNIT_NAMEPLATES_CAST_BAR_DISPLAY_SPELL_TARGET,
	[Private.Enum.Element.InterruptShield] = "打断护盾",
	[Private.Enum.Element.IconBorder] = "法术图标边框",
	[Private.Enum.Element.Duration] = "持续时间",
}

L.Designer.TemplateElementNames = {
	[Private.Enum.Template.Bar] = {
		[Private.Enum.Element.Border] = "条边框",
	},
}

L.SlashCommands.Header = "Targeted Spells 命令："
L.SlashCommands.OptionsDescription = "打开设置面板"
L.SlashCommands.SettingsDescription = "打开设置面板"
L.SlashCommands.DesignDescription = "打开布局设计器"

L.Settings.EditModeReminder =
	string.format("所有设置均可通过%s和 \"/targetedspells design\" 进行调整。", HUD_EDIT_MODE_MENU)
L.EditMode.TargetedSpellsSelfLabel = "Targeted Spells - 自身"
L.EditMode.TargetedSpellsPartyLabel = "Targeted Spells - 小队"

L.Functionality.CVarWarning = string.format(
	"%s\n\n姓名板设置 '%s' 已被禁用。\n\n没有它，%s 将无法对屏幕外的敌人生效。\n\n点击 '%s' 以重新启用。",
	addonNameWithIcon,
	UNIT_NAMEPLATES_SHOW_OFFSCREEN,
	addonName,
	ENABLE
)

L.Functionality.V3MigrationWarning = string.format(
	"%s\n\n由于 API 限制更新，Targeted Spells 的小队功能已被完全重新设计。请查看%s以预览效果。",
	addonNameWithIcon,
	HUD_EDIT_MODE_MENU
)

L.Settings.EnabledLabel = VIDEO_OPTIONS_ENABLED
L.Settings.DisabledLabel = VIDEO_OPTIONS_DISABLED

L.Settings.AddonCompartmentTooltipLine1 =
	string.format("%s 已%s", WrapTextInColorCode(L.EditMode.TargetedSpellsSelfLabel, "ffeda55f"), "%s")
L.Settings.AddonCompartmentTooltipLine2 =
	string.format("%s 已%s", WrapTextInColorCode(L.EditMode.TargetedSpellsPartyLabel, "ffeda55f"), "%s")

L.Settings.LoadConditionContentTypeLabel = "加载条件：区域"
L.Settings.LoadConditionContentTypeTooltip = nil
L.Settings.LoadConditionContentTypeLabels = {
	[Private.Enum.ContentType.OpenWorld] = "开放世界",
	[Private.Enum.ContentType.Delve] = "地下堡",
	[Private.Enum.ContentType.Dungeon] = DUNGEONS,
	[Private.Enum.ContentType.Raid] = RAIDS,
	[Private.Enum.ContentType.Arena] = ARENA,
	[Private.Enum.ContentType.Battleground] = BATTLEGROUNDS,
}

L.Settings.LoadConditionRoleLabel = "加载条件：职责"
L.Settings.LoadConditionRoleTooltip = nil
L.Settings.LoadConditionRoleLabels = {
	[Private.Enum.Role.Healer] = HEALER,
	[Private.Enum.Role.Tank] = TANK,
	[Private.Enum.Role.Damager] = DAMAGER,
}

L.Settings.FrameGapLabel = "间距"
L.Settings.FrameGapTooltip = nil

L.Settings.FrameDirectionLabel = HUD_EDIT_MODE_SETTING_AURA_FRAME_ORIENTATION
L.Settings.FrameDirectionTooltip = nil
L.Settings.FrameDirectionHorizontal = HUD_EDIT_MODE_SETTING_AURA_FRAME_ORIENTATION_HORIZONTAL
L.Settings.FrameDirectionVertical = HUD_EDIT_MODE_SETTING_AURA_FRAME_ORIENTATION_VERTICAL

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
	[Private.Enum.GlowType.ProcGlow] = "触发发光",
	[Private.Enum.GlowType.Star4] = "四星发光",
}

L.Settings.IndicateInterruptsLabel = "显示打断"

L.Settings.TextToSpeechVoiceLabel = "TTS 语音"
L.Settings.TextToSpeechVoiceTooltip = "TTS 播报所使用的语音。所有组共用。"

L.Settings.AnnounceUntargetedSpellsLabel = "无目标法术 TTS 设置"
L.Settings.AnnounceUntargetedSpellsTooltip = "按 NPC 类型设置无目标法术（AoE、正面技能等）的 TTS 播报。"

L.Settings.AnnounceTargetedSpellsLabel = "有目标法术 TTS 设置"
L.Settings.AnnounceTargetedSpellsTooltip = "按 NPC 类型设置以特定玩家为目标的法术的 TTS 播报。"

L.Settings.NpcTypeLabels = {
	[Private.Enum.NpcType.Boss] = "首领",
	[Private.Enum.NpcType.Lieutenant] = "副官",
	[Private.Enum.NpcType.Other] = "其他单位",
	[Private.Enum.NpcType.Minion] = "仆从",
}

L.Settings.ClickToOpenSettingsLabel = "点击打开设置"

L.Settings.Import = HUD_EDIT_MODE_IMPORT_LAYOUT
L.Settings.Export = "导出"

L.Settings.FeatureFlagsLabel = "功能"
L.Settings.FeatureFlagsTooltip = nil

L.Settings.GroupNameLabel = "重命名组"
L.Settings.GroupNamePrompt = "输入此组的名称："

L.Settings.TemplateLabel = "模板"
L.Settings.TemplateTooltip = "切换模板会将此组的元素布局重置为模板默认值。"
L.Settings.TemplateLabels = {
	[Private.Enum.Template.Icon] = "图标",
	[Private.Enum.Template.Bar] = "条",
	[Private.Enum.Template.IconDuration] = "图标 + 持续时间",
}

L.Settings.FilterLabel = "显示目标为以下对象的法术"
L.Settings.FilterTooltip = "此组显示哪些目标的法术。"
L.Settings.TargetClassLabels = {
	[Private.Enum.TargetClass.Player] = "你",
	[Private.Enum.TargetClass.PartyMember] = "小队成员",
	[Private.Enum.TargetClass.Nobody] = "无（无目标）",
}

L.Settings.CreateGroup = "创建组"
L.Settings.DeleteGroup = "删除组"
L.Settings.DeleteGroupConfirm = "删除此组？此操作无法撤销。"
L.Settings.CannotDeleteLastGroup = "无法删除最后剩余的组。"

L.Groups.DefaultName = "组 %d"
L.Groups.StarterSelfName = "自身 - 图标"
L.Groups.StarterUntargetedName = "无目标 AoE - 条"
L.Groups.MigratedSelfName = "自身"
L.Groups.MigratedPartyName = "小队"
