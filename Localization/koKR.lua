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

L.Designer.Title = "Targeted Spells - 레이아웃 디자이너"
L.Designer.ElementPickerLabel = "요소"
L.Designer.SelectHint = "미리보기에서 요소를 클릭하거나 요소 목록에서 선택하세요."
L.Designer.ResetElement = "요소 초기화"
L.Designer.CopyFrom = "레이아웃 복사 원본…"
L.Designer.CopyFromEmpty = "이 유형의 다른 그룹 없음"
L.Designer.Apply = SAVE_CHANGES
L.Designer.Revert = HUD_EDIT_MODE_REVERT_CHANGES
L.Designer.Discard = "취소"
L.Designer.UnsavedHint = "변경 사항은 저장 시 적용됩니다."
L.Designer.UnsavedPrompt = "저장하지 않은 레이아웃 변경 사항이 있습니다."

L.Designer.SettingNames = {
	ELEMENT_ACTIVE = VIDEO_OPTIONS_ENABLED,
	ELEMENT_WIDTH = "너비",
	ELEMENT_HEIGHT = "높이",
	ELEMENT_X = "X 오프셋",
	ELEMENT_Y = "Y 오프셋",
	ELEMENT_FONT_SIZE = FONT_SIZE,
	ELEMENT_FONT = "글꼴",
	ELEMENT_FONT_FLAGS = "글꼴 스타일",
	ELEMENT_TEXT_COLOR = "글자 색상",
	ELEMENT_JUSTIFY_H = "정렬",
	ELEMENT_MAX_WIDTH = "최대 너비",
	ELEMENT_GAP = "간격",
	ELEMENT_USE_CLASS_COLOR = "직업 색상 사용",
	ELEMENT_ICON_ZOOM = "아이콘 확대",
	ELEMENT_SHOW_SWIPE = "스와이프 표시",
	ELEMENT_SHOW_COUNTDOWN = "지속시간 표시",
	ELEMENT_FRACTION_THRESHOLD = "소수점 표시 기준 (초)",
	ELEMENT_BORDER_TEXTURE = "테두리 텍스처",
	ELEMENT_BORDER_COLOR = "테두리 색상",
	ELEMENT_BORDER_SIZE = "테두리 크기",
	ELEMENT_BAR_TEXTURE = "바 텍스처",
	ELEMENT_BAR_COLOR_MODE = "색상 모드",
	ELEMENT_BAR_COLOR = "바 색상",
	ELEMENT_INTERRUPTIBLE_COLOR = "차단 가능 색상",
	ELEMENT_UNINTERRUPTIBLE_COLOR = "차단 불가 색상",
	ELEMENT_BACKGROUND_TEXTURE = "배경 텍스처",
	ELEMENT_BACKGROUND_COLOR = "배경 색상",
}

L.Designer.Options = {
	JUSTIFY_LEFT = "왼쪽",
	JUSTIFY_CENTER = "가운데",
	JUSTIFY_RIGHT = "오른쪽",
	BAR_COLOR_STATIC = "고정",
	BAR_COLOR_INTERRUPTIBILITY = "차단 가능 여부",
	BAR_COLOR_TARGET_CLASS = "대상 직업 색상",
}

L.Designer.FontFlagNames = {
	[Private.Enum.FontFlags.OUTLINE] = "외곽선",
	[Private.Enum.FontFlags.SHADOW] = "그림자",
}
L.Designer.FontFlagsNone = "없음"

L.Designer.ElementNames = {
	[Private.Enum.Element.Icon] = UNIT_NAMEPLATES_CAST_BAR_DISPLAY_SPELL_ICON,
	[Private.Enum.Element.Overlay] = "재사용 대기시간 관리자 테두리",
	[Private.Enum.Element.Cooldown] = "재사용 대기시간",
	[Private.Enum.Element.Border] = "테두리",
	[Private.Enum.Element.InterruptSource] = "차단자 이름",
	[Private.Enum.Element.ProgressBar] = "진행 표시줄",
	[Private.Enum.Element.Background] = "배경",
	[Private.Enum.Element.TargetMarker] = "대상 징표",
	[Private.Enum.Element.DurationCooldown] = "지속시간",
	[Private.Enum.Element.SpellName] = UNIT_NAMEPLATES_CAST_BAR_DISPLAY_SPELL_NAME,
	[Private.Enum.Element.TargetName] = UNIT_NAMEPLATES_CAST_BAR_DISPLAY_SPELL_TARGET,
	[Private.Enum.Element.InterruptShield] = "차단 보호막",
	[Private.Enum.Element.IconBorder] = "주문 아이콘 테두리",
	[Private.Enum.Element.Duration] = "지속시간",
}

L.Designer.TemplateElementNames = {
	[Private.Enum.Template.Bar] = {
		[Private.Enum.Element.Border] = "바 테두리",
	},
}

L.SlashCommands.Header = "Targeted Spells 명령어:"
L.SlashCommands.OptionsDescription = "설정 패널 열기"
L.SlashCommands.SettingsDescription = "설정 패널 열기"
L.SlashCommands.DesignDescription = "레이아웃 디자이너 열기"

L.Settings.EditModeReminder =
	string.format("모든 설정은 %s와 \"/targetedspells design\"에서 조정할 수 있습니다.", HUD_EDIT_MODE_MENU)
L.EditMode.TargetedSpellsSelfLabel = "Targeted Spells - 자신"
L.EditMode.TargetedSpellsPartyLabel = "Targeted Spells - 파티"

L.Functionality.CVarWarning = string.format(
	"%s\n\n이름표 설정 '%s'이(가) 비활성화되었습니다.\n\n이 설정이 없으면 %s은(는) 화면 밖의 적에게 작동하지 않습니다.\n\n'%s'을(를) 클릭하여 다시 활성화하세요.",
	addonNameWithIcon,
	UNIT_NAMEPLATES_SHOW_OFFSCREEN,
	addonName,
	ENABLE
)

L.Functionality.V3MigrationWarning = string.format(
	"%s\n\nAPI 제한 업데이트로 인해 Targeted Spells의 파티 기능이 완전히 개편되었습니다. %s에서 미리보기를 확인하세요.",
	addonNameWithIcon,
	HUD_EDIT_MODE_MENU
)

L.Settings.EnabledLabel = VIDEO_OPTIONS_ENABLED
L.Settings.DisabledLabel = VIDEO_OPTIONS_DISABLED

L.Settings.AddonCompartmentTooltipLine1 =
	string.format("%s: %s", WrapTextInColorCode(L.EditMode.TargetedSpellsSelfLabel, "ffeda55f"), "%s")
L.Settings.AddonCompartmentTooltipLine2 =
	string.format("%s: %s", WrapTextInColorCode(L.EditMode.TargetedSpellsPartyLabel, "ffeda55f"), "%s")

L.Settings.LoadConditionContentTypeLabel = "로드 조건: 콘텐츠 유형"
L.Settings.LoadConditionContentTypeTooltip = nil
L.Settings.LoadConditionContentTypeLabels = {
	[Private.Enum.ContentType.OpenWorld] = "필드",
	[Private.Enum.ContentType.Delve] = "구렁",
	[Private.Enum.ContentType.Dungeon] = DUNGEONS,
	[Private.Enum.ContentType.Raid] = RAIDS,
	[Private.Enum.ContentType.Arena] = ARENA,
	[Private.Enum.ContentType.Battleground] = BATTLEGROUNDS,
}

L.Settings.LoadConditionRoleLabel = "로드 조건: 역할"
L.Settings.LoadConditionRoleTooltip = nil
L.Settings.LoadConditionRoleLabels = {
	[Private.Enum.Role.Healer] = HEALER,
	[Private.Enum.Role.Tank] = TANK,
	[Private.Enum.Role.Damager] = DAMAGER,
}

L.Settings.FrameGapLabel = "간격"
L.Settings.FrameGapTooltip = nil

L.Settings.FrameDirectionLabel = HUD_EDIT_MODE_SETTING_AURA_FRAME_ORIENTATION
L.Settings.FrameDirectionTooltip = nil
L.Settings.FrameDirectionHorizontal = HUD_EDIT_MODE_SETTING_AURA_FRAME_ORIENTATION_HORIZONTAL
L.Settings.FrameDirectionVertical = HUD_EDIT_MODE_SETTING_AURA_FRAME_ORIENTATION_VERTICAL

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

L.Settings.IndicateInterruptsLabel = "차단 표시"

L.Settings.TextToSpeechVoiceLabel = "TTS 음성"
L.Settings.TextToSpeechVoiceTooltip = "TTS 알림에 사용할 음성입니다. 모든 그룹에서 공유됩니다."

L.Settings.AnnounceUntargetedSpellsLabel = "대상 없는 주문 TTS 설정"
L.Settings.AnnounceUntargetedSpellsTooltip =
	"대상이 없는 주문(광역기, 전방 공격 등)에 대한 TTS 알림을 NPC 유형별로 설정합니다."

L.Settings.AnnounceTargetedSpellsLabel = "대상 지정 주문 TTS 설정"
L.Settings.AnnounceTargetedSpellsTooltip =
	"특정 플레이어를 대상으로 하는 주문에 대한 TTS 알림을 NPC 유형별로 설정합니다."

L.Settings.NpcTypeLabels = {
	[Private.Enum.NpcType.Boss] = "우두머리",
	[Private.Enum.NpcType.Lieutenant] = "부관",
	[Private.Enum.NpcType.Other] = "그 외 모든 대상",
	[Private.Enum.NpcType.Minion] = "하수인",
}

L.Settings.ClickToOpenSettingsLabel = "클릭하여 설정 열기"

L.Settings.Import = HUD_EDIT_MODE_IMPORT_LAYOUT
L.Settings.Export = "내보내기"

L.Settings.FeatureFlagsLabel = "기능"
L.Settings.FeatureFlagsTooltip = nil

L.Settings.GroupNameLabel = "그룹 이름 변경"
L.Settings.GroupNamePrompt = "이 그룹의 이름을 입력하세요:"

L.Settings.TemplateLabel = "템플릿"
L.Settings.TemplateTooltip = "템플릿을 변경하면 이 그룹의 요소 배치가 템플릿 기본값으로 초기화됩니다."
L.Settings.TemplateLabels = {
	[Private.Enum.Template.Icon] = "아이콘",
	[Private.Enum.Template.Bar] = "바",
	[Private.Enum.Template.IconDuration] = "아이콘 + 지속시간",
}

L.Settings.FilterLabel = "다음을 대상으로 하는 주문 표시"
L.Settings.FilterTooltip = "이 그룹에 표시할 주문 대상입니다."
L.Settings.TargetClassLabels = {
	[Private.Enum.TargetClass.Player] = "자신",
	[Private.Enum.TargetClass.PartyMember] = "파티원",
	[Private.Enum.TargetClass.Nobody] = "없음 (대상 없음)",
}

L.Settings.CreateGroup = "그룹 생성"
L.Settings.DeleteGroup = "그룹 삭제"
L.Settings.DeleteGroupConfirm = "이 그룹을 삭제하시겠습니까? 되돌릴 수 없습니다."
L.Settings.CannotDeleteLastGroup = "마지막 그룹은 삭제할 수 없습니다."

L.Groups.DefaultName = "그룹 %d"
L.Groups.StarterSelfName = "자신 - 아이콘"
L.Groups.StarterUntargetedName = "대상 없는 광역기 - 바"
L.Groups.MigratedSelfName = "자신"
L.Groups.MigratedPartyName = "파티"
