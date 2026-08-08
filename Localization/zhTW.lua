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
