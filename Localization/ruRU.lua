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
	"Рекомендуем использовать Режим редактирования — он включает предварительный просмотр всех настроек в реальном времени.\nЗдесь настройки представлены только для возможности изменения в бою."
L.EditMode.TargetedSpellsSelfLabel = "Targeted Spells - Свой"
L.EditMode.TargetedSpellsPartyLabel = "Targeted Spells - Группа"

L.Functionality.CVarWarning = string.format(
	"%s\n\nНастройка именных табличек '%s' была отключена.\n\nБез неё %s не будет работать на врагах за пределами экрана.\n\nНажмите '%s', чтобы включить её снова.",
	addonNameWithIcon,
	UNIT_NAMEPLATES_SHOW_OFFSCREEN,
	addonName,
	ENABLE
)

L.Functionality.V3MigrationWarning = string.format(
	"%s\n\nВ связи с обновлением ограничений API функциональность группы в Targeted Spells была полностью переработана. Загляните в Режим редактирования для предварительного просмотра.",
	addonNameWithIcon
)

L.Settings.EnabledLabel = "Включено"
L.Settings.EnabledTooltip = nil
L.Settings.DisabledLabel = "Отключено"

L.Settings.AddonCompartmentTooltipLine1 =
	string.format("%s: %s", WrapTextInColorCode(L.EditMode.TargetedSpellsSelfLabel, "ffeda55f"), "%s")
L.Settings.AddonCompartmentTooltipLine2 =
	string.format("%s: %s", WrapTextInColorCode(L.EditMode.TargetedSpellsPartyLabel, "ffeda55f"), "%s")

L.Settings.LoadConditionContentTypeLabel = "Условие загрузки: Тип контента"
L.Settings.LoadConditionContentTypeLabelAbbreviated = "Загружать в контенте"
L.Settings.LoadConditionContentTypeTooltip = nil
L.Settings.LoadConditionContentTypeLabels = {
	[Private.Enum.ContentType.OpenWorld] = "Открытый мир",
	[Private.Enum.ContentType.Delve] = "Погружение",
	[Private.Enum.ContentType.Dungeon] = "Подземелье",
	[Private.Enum.ContentType.Raid] = "Рейд",
	[Private.Enum.ContentType.Arena] = "Арена",
	[Private.Enum.ContentType.Battleground] = "Поле боя",
}

L.Settings.LoadConditionRoleLabel = "Условие загрузки: Роль"
L.Settings.LoadConditionRoleLabelAbbreviated = "Загружать для роли"
L.Settings.LoadConditionRoleTooltip = nil
L.Settings.LoadConditionRoleLabels = {
	[Private.Enum.Role.Healer] = "Целитель",
	[Private.Enum.Role.Tank] = "Танк",
	[Private.Enum.Role.Damager] = "ДД",
}

L.Settings.FrameWidthLabel = "Ширина"
L.Settings.FrameWidthTooltip = nil

L.Settings.FrameHeightLabel = "Высота"
L.Settings.FrameHeightTooltip = nil

L.Settings.FontSizeLabel = "Размер шрифта"
L.Settings.FontSizeTooltip = nil

L.Settings.FontFlagsLabel = "Параметры шрифта"
L.Settings.FontFlagsTooltip = nil
L.Settings.FontFlagsLabels = {
	[Private.Enum.FontFlags.OUTLINE] = "Контур",
	[Private.Enum.FontFlags.SHADOW] = "Тень",
}

L.Settings.FrameGapLabel = "Отступ"
L.Settings.FrameGapTooltip = nil

L.Settings.FrameDirectionLabel = "Направление"
L.Settings.FrameDirectionTooltip = nil
L.Settings.FrameDirectionHorizontal = "Горизонтально"
L.Settings.FrameDirectionVertical = "Вертикально"

L.Settings.FrameSortOrderLabel = "Порядок сортировки"
L.Settings.FrameSortOrderTooltip = nil
L.Settings.FrameSortOrderAscending = "По возрастанию"
L.Settings.FrameSortOrderDescending = "По убыванию"

L.Settings.FrameGrowLabel = "Рост"
L.Settings.FrameGrowTooltip = nil
L.Settings.FrameGrowLabels = {
	[Private.Enum.Grow.Start] = "Начало",
	[Private.Enum.Grow.End] = "Конец",
}

L.Settings.GlowImportantLabel = "Подсвечивать важные заклинания"

L.Settings.OnlyImportantLabel = "Показывать только важные заклинания"

L.Settings.GlowTypeLabel = "Тип подсветки"
L.Settings.GlowTypeTooltip = nil
L.Settings.GlowTypeLabels = {
	[Private.Enum.GlowType.PixelGlow] = "Pixel Glow",
	[Private.Enum.GlowType.AutoCastGlow] = "Auto Cast Glow",
	[Private.Enum.GlowType.ProcGlow] = "Proc Glow",
	[Private.Enum.GlowType.Star4] = "Звезда 4",
}

L.Settings.ShowDurationLabel = "Показывать длительность"

L.Settings.IndicateInterruptsLabel = "Показывать прерывания"

L.Settings.RenderInterruptSourceNameLabel = "Показывать имя источника прерывания"

L.Settings.ShowSwipeLabel = "Показывать анимацию перезарядки"

L.Settings.BorderStyleLabel = "Стиль рамки"
L.Settings.BorderStyleTooltip = nil

L.Settings.ForegroundBarTextureLabel = "Текстура полосы прогресса"
L.Settings.ForegroundBarTextureTooltip = nil

L.Settings.BackgroundBarTextureLabel = "Текстура фона полосы"
L.Settings.BackgroundBarTextureTooltip = nil

L.Settings.BackgroundBarColorLabel = "Цвет фона полосы"
L.Settings.BackgroundBarColorTooltip =
	"Прозрачность доступна только в Режиме редактирования, так как стандартный интерфейс настроек её не предоставляет."

L.Settings.ProgressBarColorLabel = "Цвет полосы"
L.Settings.ProgressBarColorTooltip =
	"Прозрачность доступна только в Режиме редактирования, так как стандартный интерфейс настроек её не предоставляет."

L.Settings.MirrorLayoutLabel = "Зеркальный макет"
L.Settings.MirrorLayoutTooltip = nil

L.Settings.TextToSpeechVoiceLabel = "Голос TTS"
L.Settings.TextToSpeechVoiceTooltip =
	"Голос для Text-to-Speech оповещений. Общий для настроек Self и Party."

L.Settings.AnnounceUntargetedSpellsLabel = "Настройки TTS (без цели)"
L.Settings.AnnounceUntargetedSpellsTooltip =
	"Озвучивание заклинаний без цели (AoE, лобовые атаки и т.п.) по типу моба."

L.Settings.AnnounceTargetedSpellsLabel = "Настройки TTS (с целью)"
L.Settings.AnnounceTargetedSpellsTooltip =
	"Озвучивание заклинаний, нацеленных на конкретного игрока, по типу моба."

L.Settings.NpcTypeLabels = {
	[Private.Enum.NpcType.Boss] = "Боссы",
	[Private.Enum.NpcType.Lieutenant] = "Лейтенанты",
	[Private.Enum.NpcType.Caster] = "Есть мана",
	[Private.Enum.NpcType.Melee] = "Обычные мобы",
	[Private.Enum.NpcType.Minion] = "Миньоны",
}

L.Settings.HideUntargetedSpellsLabel = "Скрыть заклинания без цели"

L.Settings.HideTargetedSpellsLabel = "Скрыть заклинания с целью"

L.Settings.SelfOnlyLabel =
	"Показывать только заклинания, нацеленные на игрока"

L.Settings.InlineDurationLabel = "Встроенное отображение длительности"

L.Settings.UseInterruptabilityColorsLabel = "Использовать цвета прерывания"
L.Settings.UseInterruptabilityColorsTooltip = nil

L.Settings.UseTargetClassColorLabel = "Использовать цвет класса цели"
L.Settings.UseTargetClassColorTooltip =
	"Окрашивает полосу в цвет класса целевого юнита с прозрачностью 75 %. Заклинания без цели будут использовать осветлённый Цвет Фоновой Полосы."

L.Settings.UninterruptibleColorLabel = "Цвет непрерываемого"
L.Settings.UninterruptibleColorTooltip = nil

L.Settings.InterruptibleColorLabel = "Цвет прерываемого"
L.Settings.InterruptibleColorTooltip = nil

L.Settings.IconZoomLabel = "Масштаб иконки"
L.Settings.IconZoomTooltip = nil

L.Settings.ClickToOpenSettingsLabel = "Нажмите для открытия настроек"

L.Settings.Import = "Импорт"
L.Settings.Export = "Экспорт"

L.Settings.FontLabel = "Шрифт"
L.Settings.FontTooltip = nil

L.Settings.FeatureFlagsLabel = "Функции"
L.Settings.FeatureFlagsTooltip = nil

L.Settings.FeatureFlagLabels = {
	[Private.Enum.FeatureFlag.GlowImportant] = L.Settings.GlowImportantLabel,
	[Private.Enum.FeatureFlag.OnlyImportant] = L.Settings.OnlyImportantLabel,
	[Private.Enum.FeatureFlag.ShowDuration] = L.Settings.ShowDurationLabel,
	[Private.Enum.FeatureFlag.ShowSwipe] = L.Settings.ShowSwipeLabel,
	[Private.Enum.FeatureFlag.IndicateInterrupts] = L.Settings.IndicateInterruptsLabel,
	[Private.Enum.FeatureFlag.RenderInterruptSourceName] = L.Settings.RenderInterruptSourceNameLabel,
	[Private.Enum.FeatureFlag.ShowIcon] = "Показывать иконку",
	[Private.Enum.FeatureFlag.ShowTargetMarker] = "Показывать маркер цели",
	[Private.Enum.FeatureFlag.ShowSpellName] = "Показывать название заклинания",
	[Private.Enum.FeatureFlag.ShowTargetName] = "Показывать имя цели",
	[Private.Enum.FeatureFlag.ShowTargetClassColor] = "Показывать цвет класса цели",
	[Private.Enum.FeatureFlag.MirrorLayout] = L.Settings.MirrorLayoutLabel,
	[Private.Enum.FeatureFlag.InlineDuration] = L.Settings.InlineDurationLabel,
	[Private.Enum.FeatureFlag.HideUntargetedSpells] = L.Settings.HideUntargetedSpellsLabel,
	[Private.Enum.FeatureFlag.HideTargetedSpells] = L.Settings.HideTargetedSpellsLabel,
	[Private.Enum.FeatureFlag.SelfOnly] = L.Settings.SelfOnlyLabel,
}

L.Settings.FeatureFlagSettingTitles = {
	[Private.Enum.FeatureFlag.GlowImportant] = "Отображение",
	[Private.Enum.FeatureFlag.IndicateInterrupts] = "Настройки прерываний",
}
