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
L.Designer.Title = "Targeted Spells - 版面設計師"
L.Designer.ElementPickerLabel = "元素"
L.Designer.SelectHint = "點擊預覽中的元素，或從元素下拉選單中選擇。"
L.Designer.ResetElement = "重設元素"
L.Designer.CopyFrom = "從其他群組複製版面…"
L.Designer.CopyFromEmpty = "沒有其他相同類型的群組"
L.Designer.Apply = "儲存變更"
L.Designer.Revert = "還原"
L.Designer.Discard = "放棄"
L.Designer.UnsavedHint = "儲存後變更才會生效。"
L.Designer.UnsavedPrompt = "你有尚未儲存的版面變更。"
L.Designer.SettingNames = { ELEMENT_ACTIVE = "啟用", ELEMENT_WIDTH = "寬度", ELEMENT_HEIGHT = "高度", ELEMENT_X = "X 偏移", ELEMENT_Y = "Y 偏移", ELEMENT_FONT_SIZE = "字型大小", ELEMENT_FONT = "字型", ELEMENT_FONT_FLAGS = "字型樣式", ELEMENT_TEXT_COLOR = "文字顏色", ELEMENT_JUSTIFY_H = "對齊", ELEMENT_MAX_WIDTH = "最大寬度", ELEMENT_GAP = "間距", ELEMENT_USE_CLASS_COLOR = "使用職業顏色", ELEMENT_ICON_ZOOM = "圖示縮放", ELEMENT_SHOW_SWIPE = "顯示掃過動畫", ELEMENT_SHOW_COUNTDOWN = "顯示持續時間", ELEMENT_FRACTION_THRESHOLD = "低於此值顯示小數（秒）", ELEMENT_BORDER_TEXTURE = "邊框材質", ELEMENT_BORDER_COLOR = "邊框顏色", ELEMENT_BORDER_SIZE = "邊框大小", ELEMENT_BAR_TEXTURE = "條材質", ELEMENT_BAR_COLOR_MODE = "顏色模式", ELEMENT_BAR_COLOR = "條顏色", ELEMENT_INTERRUPTIBLE_COLOR = "可打斷顏色", ELEMENT_UNINTERRUPTIBLE_COLOR = "不可打斷顏色", ELEMENT_BACKGROUND_TEXTURE = "背景材質", ELEMENT_BACKGROUND_COLOR = "背景顏色" }
L.Designer.Options = { JUSTIFY_LEFT = "靠左", JUSTIFY_CENTER = "置中", JUSTIFY_RIGHT = "靠右", BAR_COLOR_STATIC = "固定", BAR_COLOR_INTERRUPTIBILITY = "可打斷性", BAR_COLOR_TARGET_CLASS = "目標職業顏色" }
L.Designer.FontFlagNames = { [Private.Enum.FontFlags.OUTLINE] = "外框", [Private.Enum.FontFlags.SHADOW] = "陰影" }
L.Designer.FontFlagsNone = "無"
L.Designer.ElementNames = { [Private.Enum.Element.Icon] = "圖示", [Private.Enum.Element.Overlay] = "冷卻管理器邊框", [Private.Enum.Element.Cooldown] = "冷卻時間", [Private.Enum.Element.Border] = "邊框", [Private.Enum.Element.InterruptSource] = "打斷者名稱", [Private.Enum.Element.ProgressBar] = "進度條", [Private.Enum.Element.Background] = "背景", [Private.Enum.Element.TargetMarker] = "目標標記", [Private.Enum.Element.DurationCooldown] = "持續時間", [Private.Enum.Element.SpellName] = "法術名稱", [Private.Enum.Element.TargetName] = "目標名稱", [Private.Enum.Element.InterruptShield] = "打斷護盾", [Private.Enum.Element.Duration] = "持續時間" }
L.SlashCommands.Header = "Targeted Spells 指令："
L.SlashCommands.OptionsDescription = "開啟設定面板"
L.SlashCommands.SettingsDescription = "開啟設定面板"
L.SlashCommands.DesignDescription = "開啟版面設計師"

L.Settings.EditModeReminder =
	"所有設定均可透過編輯模式和 \"/targetedspells design\" 進行調整。"
L.EditMode.TargetedSpellsSelfLabel = "目標法術 - 自身"
L.EditMode.TargetedSpellsPartyLabel = "目標法術 - 小隊"

L.Functionality.CVarWarning = string.format(
	"%s\n\n姓名板設定 '%s' 已被停用。\n\n沒有它，%s 將無法對螢幕外的敵人生效。\n\n點擊 '%s' 以重新啟用。",
	addonNameWithIcon,
	UNIT_NAMEPLATES_SHOW_OFFSCREEN,
	addonName,
	ENABLE
)

L.Functionality.V3MigrationWarning = string.format(
	"%s\n\n由於 API 限制更新，Targeted Spells 的小隊功能已完全重新設計。請查看編輯模式以預覽效果。",
	addonNameWithIcon
)

L.Settings.EnabledLabel = "啟用"
L.Settings.DisabledLabel = "停用"

L.Settings.AddonCompartmentTooltipLine1 =
	string.format("%s 已%s", WrapTextInColorCode(L.EditMode.TargetedSpellsSelfLabel, "ffeda55f"), "%s")
L.Settings.AddonCompartmentTooltipLine2 =
	string.format("%s 已%s", WrapTextInColorCode(L.EditMode.TargetedSpellsPartyLabel, "ffeda55f"), "%s")

L.Settings.LoadConditionContentTypeLabel = "載入條件：區域"
L.Settings.LoadConditionContentTypeTooltip = nil
L.Settings.LoadConditionContentTypeLabels = {
	[Private.Enum.ContentType.OpenWorld] = "開放世界",
	[Private.Enum.ContentType.Delve] = "探究",
	[Private.Enum.ContentType.Dungeon] = "地下城",
	[Private.Enum.ContentType.Raid] = "團隊副本",
	[Private.Enum.ContentType.Arena] = "競技場",
	[Private.Enum.ContentType.Battleground] = "戰場",
}

L.Settings.LoadConditionRoleLabel = "載入條件：職責"
L.Settings.LoadConditionRoleTooltip = nil
L.Settings.LoadConditionRoleLabels = {
	[Private.Enum.Role.Healer] = "治療",
	[Private.Enum.Role.Tank] = "坦克",
	[Private.Enum.Role.Damager] = "輸出",
}

L.Settings.FrameGapLabel = "間距"
L.Settings.FrameGapTooltip = nil

L.Settings.FrameDirectionLabel = "方向"
L.Settings.FrameDirectionTooltip = nil
L.Settings.FrameDirectionHorizontal = "水平"
L.Settings.FrameDirectionVertical = "垂直"

L.Settings.FrameSortOrderLabel = "排序方式"
L.Settings.FrameSortOrderTooltip = nil
L.Settings.FrameSortOrderAscending = "升冪"
L.Settings.FrameSortOrderDescending = "降冪"

L.Settings.FrameGrowLabel = "延伸方向"
L.Settings.FrameGrowTooltip = nil
L.Settings.FrameGrowLabels = {
	[Private.Enum.Grow.Start] = "從起始端",
	[Private.Enum.Grow.End] = "從末端",
}

L.Settings.GlowImportantLabel = "重要法術發光"

L.Settings.OnlyImportantLabel = "僅顯示重要法術"

L.Settings.GlowTypeLabel = "發光效果類型"
L.Settings.GlowTypeTooltip = nil
L.Settings.GlowTypeLabels = {
	[Private.Enum.GlowType.PixelGlow] = "像素發光",
	[Private.Enum.GlowType.AutoCastGlow] = "自動施法發光",
	[Private.Enum.GlowType.ProcGlow] = "觸發發光",
	[Private.Enum.GlowType.Star4] = "四角星發光",
}

L.Settings.IndicateInterruptsLabel = "標記可打斷法術"

L.Settings.TextToSpeechVoiceLabel = "TTS 語音"
L.Settings.TextToSpeechVoiceTooltip = "TTS 播報所使用的語音。自身與小隊設定共用。"

L.Settings.AnnounceUntargetedSpellsLabel = "未目標法術 TTS 設定"
L.Settings.AnnounceUntargetedSpellsTooltip = "依 NPC 類型設定未目標法術的 TTS 播報。"

L.Settings.AnnounceTargetedSpellsLabel = "已目標法術 TTS 設定"
L.Settings.AnnounceTargetedSpellsTooltip = "依 NPC 類型設定已目標法術的 TTS 播報。"

L.Settings.NpcTypeLabels = {
	[Private.Enum.NpcType.Boss] = "首領",
	[Private.Enum.NpcType.Lieutenant] = "副官",
	[Private.Enum.NpcType.Other] = "其他單位",
	[Private.Enum.NpcType.Minion] = "從屬單位",
}

L.Settings.UseTargetClassColorLabel = "使用目標職業顏色"
L.Settings.UseTargetClassColorTooltip =
	"以 75% 透明度將條形顏色設為目標單位的職業顏色。未選中目標的法術將使用加亮後的背景條顏色。"

L.Settings.ClickToOpenSettingsLabel = "點擊開啟設定"

L.Settings.Import = "匯入"
L.Settings.Export = "匯出"

L.Settings.FeatureFlagsLabel = "功能選項"
L.Settings.FeatureFlagsTooltip = nil
L.Settings.GroupNameLabel = "重新命名群組"
L.Settings.GroupNamePrompt = "輸入此群組的名稱："
L.Settings.TemplateLabel = "範本"
L.Settings.TemplateTooltip = "切換範本會將此群組的元素版面重設為範本預設值。"
L.Settings.TemplateLabels = { [Private.Enum.Template.Icon] = "圖示", [Private.Enum.Template.Bar] = "條", [Private.Enum.Template.IconDuration] = "圖示 + 持續時間" }
L.Settings.FilterLabel = "顯示以其為目標的法術"
L.Settings.FilterTooltip = "此群組顯示哪些目標的法術。"
L.Settings.TargetClassLabels = { [Private.Enum.TargetClass.Player] = "你", [Private.Enum.TargetClass.PartyMember] = "小隊成員", [Private.Enum.TargetClass.Nobody] = "無（未指定目標）" }
L.Settings.CreateGroup = "建立群組"
L.Settings.DeleteGroup = "刪除群組"
L.Settings.DeleteGroupConfirm = "刪除此群組？此操作無法復原。"
L.Settings.CannotDeleteLastGroup = "無法刪除最後剩餘的群組。"
