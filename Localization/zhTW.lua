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
	"建議使用編輯模式，它包含所有設定的即時預覽。\n這些設定僅在此處提供，以便在戰鬥中也能編輯。"
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
L.Settings.EnabledTooltip = nil
L.Settings.DisabledLabel = "停用"

L.Settings.AddonCompartmentTooltipLine1 =
	string.format("%s 已%s", WrapTextInColorCode(L.EditMode.TargetedSpellsSelfLabel, "ffeda55f"), "%s")
L.Settings.AddonCompartmentTooltipLine2 =
	string.format("%s 已%s", WrapTextInColorCode(L.EditMode.TargetedSpellsPartyLabel, "ffeda55f"), "%s")

L.Settings.LoadConditionContentTypeLabel = "載入條件：區域"
L.Settings.LoadConditionContentTypeLabelAbbreviated = "在以下區域中載入"
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
L.Settings.LoadConditionRoleLabelAbbreviated = "在以下職責載入"
L.Settings.LoadConditionRoleTooltip = nil
L.Settings.LoadConditionRoleLabels = {
	[Private.Enum.Role.Healer] = "治療",
	[Private.Enum.Role.Tank] = "坦克",
	[Private.Enum.Role.Damager] = "輸出",
}

L.Settings.FrameWidthLabel = "寬度"
L.Settings.FrameWidthTooltip = nil

L.Settings.FrameHeightLabel = "高度"
L.Settings.FrameHeightTooltip = nil

L.Settings.FontSizeLabel = "字型大小"
L.Settings.FontSizeTooltip = nil

L.Settings.FontFlagsLabel = "字型選項"
L.Settings.FontFlagsTooltip = nil
L.Settings.FontFlagsLabels = {
	[Private.Enum.FontFlags.OUTLINE] = "外框",
	[Private.Enum.FontFlags.SHADOW] = "陰影",
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

L.Settings.ShowDurationLabel = "顯示持續時間"

L.Settings.IndicateInterruptsLabel = "標記可打斷法術"

L.Settings.RenderInterruptSourceNameLabel = "顯示打斷來源名稱"

L.Settings.ShowSwipeLabel = "顯示冷卻掃光"

L.Settings.BorderStyleLabel = "邊框樣式"
L.Settings.BorderStyleTooltip = nil

L.Settings.ForegroundBarTextureLabel = "進度條材質"
L.Settings.ForegroundBarTextureTooltip = nil

L.Settings.BackgroundBarTextureLabel = "背景條材質"
L.Settings.BackgroundBarTextureTooltip = nil

L.Settings.BackgroundBarColorLabel = "背景條顏色"
L.Settings.BackgroundBarColorTooltip =
	"透明度僅在編輯模式中可用，因為預設設定介面未公開此選項。"

L.Settings.ProgressBarColorLabel = "進度條顏色"
L.Settings.ProgressBarColorTooltip =
	"透明度僅在編輯模式中可用，因為預設設定介面未公開此選項。"

L.Settings.MirrorLayoutLabel = "鏡像排版"

L.Settings.TextToSpeechVoiceLabel = "TTS 語音"
L.Settings.TextToSpeechVoiceTooltip = "TTS 播報所使用的語音。自身與小隊設定共用。"

L.Settings.AnnounceUntargetedSpellsLabel = "未目標法術 TTS 設定"
L.Settings.AnnounceUntargetedSpellsTooltip = "依 NPC 類型設定未目標法術的 TTS 播報。"

L.Settings.AnnounceTargetedSpellsLabel = "已目標法術 TTS 設定"
L.Settings.AnnounceTargetedSpellsTooltip = "依 NPC 類型設定已目標法術的 TTS 播報。"

L.Settings.NpcTypeLabels = {
	[Private.Enum.NpcType.Boss] = "首領",
	[Private.Enum.NpcType.Lieutenant] = "副官",
	[Private.Enum.NpcType.Caster] = "施法單位",
	[Private.Enum.NpcType.Melee] = "普通近戰",
	[Private.Enum.NpcType.Minion] = "從屬單位",
}

L.Settings.HideUntargetedSpellsLabel = "隱藏無目標法術"

L.Settings.HideTargetedSpellsLabel = "隱藏有目標法術"

L.Settings.SelfOnlyLabel = "僅顯示針對玩家的法術"

L.Settings.InlineDurationLabel = "內嵌持續時間位置"

L.Settings.UseInterruptabilityColorsLabel = "使用打斷顏色"
L.Settings.UseInterruptabilityColorsTooltip = nil

L.Settings.UseTargetClassColorLabel = "使用目標職業顏色"
L.Settings.UseTargetClassColorTooltip =
	"以 75% 透明度將條形顏色設為目標單位的職業顏色。未選中目標的法術將使用加亮後的背景條顏色。"

L.Settings.UninterruptibleColorLabel = "不可打斷顏色"
L.Settings.UninterruptibleColorTooltip = nil

L.Settings.InterruptibleColorLabel = "可打斷顏色"
L.Settings.InterruptibleColorTooltip = nil

L.Settings.IconZoomLabel = "圖示縮放"
L.Settings.IconZoomTooltip = nil

L.Settings.ClickToOpenSettingsLabel = "點擊開啟設定"

L.Settings.Import = "匯入"
L.Settings.Export = "匯出"

L.Settings.FontLabel = "字型"
L.Settings.FontTooltip = nil

L.Settings.FeatureFlagsLabel = "功能選項"
L.Settings.FeatureFlagsTooltip = nil

L.Settings.FeatureFlagLabels = {
	[Private.Enum.FeatureFlag.GlowImportant] = L.Settings.GlowImportantLabel,
	[Private.Enum.FeatureFlag.OnlyImportant] = L.Settings.OnlyImportantLabel,
	[Private.Enum.FeatureFlag.ShowDuration] = L.Settings.ShowDurationLabel,
	[Private.Enum.FeatureFlag.ShowSwipe] = L.Settings.ShowSwipeLabel,
	[Private.Enum.FeatureFlag.IndicateInterrupts] = L.Settings.IndicateInterruptsLabel,
	[Private.Enum.FeatureFlag.RenderInterruptSourceName] = L.Settings.RenderInterruptSourceNameLabel,
	[Private.Enum.FeatureFlag.ShowIcon] = "顯示圖示",
	[Private.Enum.FeatureFlag.ShowTargetMarker] = "顯示目標標記",
	[Private.Enum.FeatureFlag.ShowSpellName] = "顯示法術名稱",
	[Private.Enum.FeatureFlag.ShowTargetName] = "顯示目標名稱",
	[Private.Enum.FeatureFlag.ShowTargetClassColor] = "顯示目標職業顏色",
	[Private.Enum.FeatureFlag.MirrorLayout] = L.Settings.MirrorLayoutLabel,
	[Private.Enum.FeatureFlag.InlineDuration] = L.Settings.InlineDurationLabel,
	[Private.Enum.FeatureFlag.HideUntargetedSpells] = L.Settings.HideUntargetedSpellsLabel,
	[Private.Enum.FeatureFlag.HideTargetedSpells] = L.Settings.HideTargetedSpellsLabel,
	[Private.Enum.FeatureFlag.SelfOnly] = L.Settings.SelfOnlyLabel,
}

L.Settings.FeatureFlagSettingTitles = {
	[Private.Enum.FeatureFlag.GlowImportant] = "顯示",
	[Private.Enum.FeatureFlag.IndicateInterrupts] = "打斷設定",
}
