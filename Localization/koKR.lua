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
	"편집 모드를 사용하는 것을 권장합니다. 모든 설정의 실시간 미리보기가 포함되어 있습니다.\n여기 있는 설정은 전투 중에도 편집할 수 있도록 제공됩니다."
L.EditMode.TargetedSpellsSelfLabel = "대상 지정 주문 - 자신"
L.EditMode.TargetedSpellsPartyLabel = "대상 지정 주문 - 파티"

L.Functionality.CVarWarning = string.format(
	"%s\n\n이름표 설정 '%s' 비활성화되었습니다.\n\n이 설정 없이는 %s 화면 밖의 적에게 작동하지 않습니다.\n\n'%s' 클릭하여 다시 활성화하세요.",
	addonNameWithIcon,
	UNIT_NAMEPLATES_SHOW_OFFSCREEN,
	addonName,
	ENABLE
)

L.Functionality.V3MigrationWarning = string.format(
	"%s\n\nAPI 제한 업데이트로 인해 Targeted Spells의 파티 기능이 완전히 개편되었습니다. 편집 모드에서 미리보기를 확인하세요.",
	addonNameWithIcon
)

L.Settings.EnabledLabel = "활성화"
L.Settings.EnabledTooltip = nil
L.Settings.DisabledLabel = "비활성화"

L.Settings.AddonCompartmentTooltipLine1 =
	string.format("%s: %s", WrapTextInColorCode(L.EditMode.TargetedSpellsSelfLabel, "ffeda55f"), "%s")
L.Settings.AddonCompartmentTooltipLine2 =
	string.format("%s: %s", WrapTextInColorCode(L.EditMode.TargetedSpellsPartyLabel, "ffeda55f"), "%s")

L.Settings.LoadConditionContentTypeLabel = "로드 조건: 콘텐츠 유형"
L.Settings.LoadConditionContentTypeLabelAbbreviated = "콘텐츠별 로드"
L.Settings.LoadConditionContentTypeTooltip = nil
L.Settings.LoadConditionContentTypeLabels = {
	[Private.Enum.ContentType.OpenWorld] = "필드",
	[Private.Enum.ContentType.Delve] = "구렁",
	[Private.Enum.ContentType.Dungeon] = "던전",
	[Private.Enum.ContentType.Raid] = "공격대",
	[Private.Enum.ContentType.Arena] = "투기장",
	[Private.Enum.ContentType.Battleground] = "전장",
}

L.Settings.LoadConditionRoleLabel = "로드 조건: 역할"
L.Settings.LoadConditionRoleLabelAbbreviated = "역할별 로드"
L.Settings.LoadConditionRoleTooltip = nil
L.Settings.LoadConditionRoleLabels = {
	[Private.Enum.Role.Healer] = "힐러",
	[Private.Enum.Role.Tank] = "탱커",
	[Private.Enum.Role.Damager] = "딜러",
}

L.Settings.FrameWidthLabel = "너비"
L.Settings.FrameWidthTooltip = nil

L.Settings.FrameHeightLabel = "높이"
L.Settings.FrameHeightTooltip = nil

L.Settings.FontSizeLabel = "글꼴 크기"
L.Settings.FontSizeTooltip = nil

L.Settings.FontFlagsLabel = "글꼴 옵션"
L.Settings.FontFlagsTooltip = nil
L.Settings.FontFlagsLabels = {
	[Private.Enum.FontFlags.OUTLINE] = "외곽선",
	[Private.Enum.FontFlags.SHADOW] = "그림자",
}

L.Settings.FrameGapLabel = "간격"
L.Settings.FrameGapTooltip = nil

L.Settings.FrameDirectionLabel = "방향"
L.Settings.FrameDirectionTooltip = nil
L.Settings.FrameDirectionHorizontal = "가로"
L.Settings.FrameDirectionVertical = "세로"

L.Settings.FrameSortOrderLabel = "정렬 순서"
L.Settings.FrameSortOrderTooltip = nil
L.Settings.FrameSortOrderAscending = "오름차순"
L.Settings.FrameSortOrderDescending = "내림차순"

L.Settings.FrameGrowLabel = "성장 방향"
L.Settings.FrameGrowTooltip = nil
L.Settings.FrameGrowLabels = {
	[Private.Enum.Grow.Start] = "시작",
	[Private.Enum.Grow.End] = "끝",
}

L.Settings.GlowImportantLabel = "중요 주문 강조"

L.Settings.OnlyImportantLabel = "중요 주문만 표시"

L.Settings.GlowTypeLabel = "반짝임 유형"
L.Settings.GlowTypeTooltip = nil
L.Settings.GlowTypeLabels = {
	[Private.Enum.GlowType.PixelGlow] = "픽셀 반짝임",
	[Private.Enum.GlowType.AutoCastGlow] = "자동시전 반짝임",
	[Private.Enum.GlowType.ProcGlow] = "스킬 발동 반짝임",
	[Private.Enum.GlowType.Star4] = "별 4",
}

L.Settings.ShowDurationLabel = "지속시간 표시"

L.Settings.IndicateInterruptsLabel = "차단 표시"

L.Settings.RenderInterruptSourceNameLabel = "차단자 이름 표시"

L.Settings.ShowSwipeLabel = "회전 표시"

L.Settings.BorderStyleLabel = "테두리 스타일"
L.Settings.BorderStyleTooltip = nil

L.Settings.ForegroundBarTextureLabel = "진행 바 텍스처"
L.Settings.ForegroundBarTextureTooltip = nil

L.Settings.BackgroundBarTextureLabel = "배경 바 텍스처"
L.Settings.BackgroundBarTextureTooltip = nil

L.Settings.BackgroundBarColorLabel = "배경 바 색상"
L.Settings.BackgroundBarColorTooltip =
	"불투명도는 기본 설정 UI에서 표시되지 않기 때문에 편집 모드에서만 사용할 수 있습니다."

L.Settings.ProgressBarColorLabel = "바 색상"
L.Settings.ProgressBarColorTooltip =
	"불투명도는 기본 설정 UI에서 표시되지 않기 때문에 편집 모드에서만 사용할 수 있습니다."

L.Settings.MirrorLayoutLabel = "레이아웃 반전"

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

L.Settings.HideUntargetedSpellsLabel = "대상 없는 주문 숨기기"

L.Settings.HideTargetedSpellsLabel = "대상 있는 주문 숨기기"

L.Settings.SelfOnlyLabel = "플레이어를 대상으로 하는 주문만 표시"

L.Settings.InlineDurationLabel = "지속시간 인라인 위치"

L.Settings.UseInterruptabilityColorsLabel = "방해 색상 사용"
L.Settings.UseInterruptabilityColorsTooltip = nil

L.Settings.UseTargetClassColorLabel = "대상 직업 색상 사용"
L.Settings.UseTargetClassColorTooltip =
	"대상 유닛의 직업 색상을 75% 불투명도로 바에 적용합니다. 대상이 없는 주문은 밝기가 높아진 배경 바 색상을 사용합니다."

L.Settings.UninterruptibleColorLabel = "방해 불가 색상"
L.Settings.UninterruptibleColorTooltip = nil

L.Settings.InterruptibleColorLabel = "방해 가능 색상"
L.Settings.InterruptibleColorTooltip = nil

L.Settings.IconZoomLabel = "아이콘 확대"
L.Settings.IconZoomTooltip = nil

L.Settings.ClickToOpenSettingsLabel = "클릭 설정 열기"

L.Settings.Import = "가져오기"
L.Settings.Export = "내보내기"

L.Settings.FontLabel = "글꼴"

L.Settings.FontTooltip = nil

L.Settings.FeatureFlagsLabel = "기능"
L.Settings.FeatureFlagsTooltip = nil

L.Settings.FeatureFlagLabels = {
	[Private.Enum.FeatureFlag.GlowImportant] = L.Settings.GlowImportantLabel,
	[Private.Enum.FeatureFlag.OnlyImportant] = L.Settings.OnlyImportantLabel,
	[Private.Enum.FeatureFlag.ShowDuration] = L.Settings.ShowDurationLabel,
	[Private.Enum.FeatureFlag.ShowSwipe] = L.Settings.ShowSwipeLabel,
	[Private.Enum.FeatureFlag.IndicateInterrupts] = L.Settings.IndicateInterruptsLabel,
	[Private.Enum.FeatureFlag.RenderInterruptSourceName] = L.Settings.RenderInterruptSourceNameLabel,
	[Private.Enum.FeatureFlag.ShowIcon] = "아이콘 표시",
	[Private.Enum.FeatureFlag.ShowTargetMarker] = "대상 마커 표시",
	[Private.Enum.FeatureFlag.ShowSpellName] = "주문 이름 표시",
	[Private.Enum.FeatureFlag.ShowTargetName] = "대상 이름 표시",
	[Private.Enum.FeatureFlag.ShowTargetClassColor] = "대상 직업 색상 표시",
	[Private.Enum.FeatureFlag.MirrorLayout] = L.Settings.MirrorLayoutLabel,
	[Private.Enum.FeatureFlag.InlineDuration] = L.Settings.InlineDurationLabel,
	[Private.Enum.FeatureFlag.HideUntargetedSpells] = L.Settings.HideUntargetedSpellsLabel,
	[Private.Enum.FeatureFlag.HideTargetedSpells] = L.Settings.HideTargetedSpellsLabel,
	[Private.Enum.FeatureFlag.SelfOnly] = L.Settings.SelfOnlyLabel,
}

L.Settings.FeatureFlagSettingTitles = {
	[Private.Enum.FeatureFlag.GlowImportant] = "표시",
	[Private.Enum.FeatureFlag.IndicateInterrupts] = "차단 설정",
}
