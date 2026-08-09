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
L.Designer.Title = "Targeted Spells — Редактор раскладки"
L.Designer.ElementPickerLabel = "Элемент"
L.Designer.SelectHint = "Нажмите на элемент в окне предварительного просмотра или выберите его в списке элементов."
L.Designer.ResetElement = "Сбросить элемент"
L.Designer.CopyFrom = "Копировать раскладку из…"
L.Designer.CopyFromEmpty = "Нет других групп этого типа"
L.Designer.Apply = "Сохранить изменения"
L.Designer.Revert = "Отменить"
L.Designer.Discard = "Отбросить"
L.Designer.UnsavedHint = "Изменения применяются после сохранения."
L.Designer.UnsavedPrompt = "У вас есть несохранённые изменения раскладки."
L.Designer.SettingNames = { ELEMENT_ACTIVE = "Включено", ELEMENT_WIDTH = "Ширина", ELEMENT_HEIGHT = "Высота", ELEMENT_X = "Смещение по X", ELEMENT_Y = "Смещение по Y", ELEMENT_FONT_SIZE = "Размер шрифта", ELEMENT_FONT = "Шрифт", ELEMENT_FONT_FLAGS = "Стиль шрифта", ELEMENT_TEXT_COLOR = "Цвет текста", ELEMENT_JUSTIFY_H = "Выравнивание", ELEMENT_MAX_WIDTH = "Максимальная ширина", ELEMENT_GAP = "Отступ", ELEMENT_USE_CLASS_COLOR = "Использовать цвет класса", ELEMENT_ICON_ZOOM = "Масштаб значка", ELEMENT_SHOW_SWIPE = "Показывать анимацию", ELEMENT_SHOW_COUNTDOWN = "Показывать длительность", ELEMENT_FRACTION_THRESHOLD = "Дробная часть ниже (с)", ELEMENT_BORDER_TEXTURE = "Текстура рамки", ELEMENT_BORDER_COLOR = "Цвет рамки", ELEMENT_BORDER_SIZE = "Размер рамки", ELEMENT_BAR_TEXTURE = "Текстура полосы", ELEMENT_BAR_COLOR_MODE = "Режим цвета", ELEMENT_BAR_COLOR = "Цвет полосы", ELEMENT_INTERRUPTIBLE_COLOR = "Цвет прерываемого", ELEMENT_UNINTERRUPTIBLE_COLOR = "Цвет непрерываемого", ELEMENT_BACKGROUND_TEXTURE = "Текстура фона", ELEMENT_BACKGROUND_COLOR = "Цвет фона" }
L.Designer.Options = { JUSTIFY_LEFT = "Слева", JUSTIFY_CENTER = "По центру", JUSTIFY_RIGHT = "Справа", BAR_COLOR_STATIC = "Статический", BAR_COLOR_INTERRUPTIBILITY = "Прерываемость", BAR_COLOR_TARGET_CLASS = "Цвет класса цели" }
L.Designer.FontFlagNames = { [Private.Enum.FontFlags.OUTLINE] = "Контур", [Private.Enum.FontFlags.SHADOW] = "Тень" }
L.Designer.FontFlagsNone = "Нет"
L.Designer.ElementNames = { [Private.Enum.Element.Icon] = "Значок", [Private.Enum.Element.Overlay] = "Рамка менеджера восстановления", [Private.Enum.Element.Cooldown] = "Восстановление", [Private.Enum.Element.Border] = "Рамка", [Private.Enum.Element.InterruptSource] = "Имя прерывающего", [Private.Enum.Element.ProgressBar] = "Индикатор прогресса", [Private.Enum.Element.Background] = "Фон", [Private.Enum.Element.TargetMarker] = "Метка цели", [Private.Enum.Element.DurationCooldown] = "Длительность", [Private.Enum.Element.SpellName] = "Название заклинания", [Private.Enum.Element.TargetName] = "Имя цели", [Private.Enum.Element.InterruptShield] = "Щит прерывания", [Private.Enum.Element.Duration] = "Длительность" }
L.SlashCommands.Header = "Команды Targeted Spells:"
L.SlashCommands.OptionsDescription = "Открыть панель настроек"
L.SlashCommands.SettingsDescription = "Открыть панель настроек"
L.SlashCommands.DesignDescription = "Открыть редактор раскладки"

L.Settings.EditModeReminder =
	"Все настройки доступны через Режим редактирования и \"/targetedspells design\"."
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
L.Settings.DisabledLabel = "Отключено"

L.Settings.AddonCompartmentTooltipLine1 =
	string.format("%s: %s", WrapTextInColorCode(L.EditMode.TargetedSpellsSelfLabel, "ffeda55f"), "%s")
L.Settings.AddonCompartmentTooltipLine2 =
	string.format("%s: %s", WrapTextInColorCode(L.EditMode.TargetedSpellsPartyLabel, "ffeda55f"), "%s")

L.Settings.LoadConditionContentTypeLabel = "Условие загрузки: Тип контента"
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
L.Settings.LoadConditionRoleTooltip = nil
L.Settings.LoadConditionRoleLabels = {
	[Private.Enum.Role.Healer] = "Целитель",
	[Private.Enum.Role.Tank] = "Танк",
	[Private.Enum.Role.Damager] = "ДД",
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

L.Settings.IndicateInterruptsLabel = "Показывать прерывания"

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
	[Private.Enum.NpcType.Other] = "Все остальные",
	[Private.Enum.NpcType.Minion] = "Миньоны",
}

L.Settings.UseTargetClassColorLabel = "Использовать цвет класса цели"
L.Settings.UseTargetClassColorTooltip =
	"Окрашивает полосу в цвет класса целевого юнита с прозрачностью 75 %. Заклинания без цели будут использовать осветлённый Цвет Фоновой Полосы."

L.Settings.ClickToOpenSettingsLabel = "Нажмите для открытия настроек"

L.Settings.Import = "Импорт"
L.Settings.Export = "Экспорт"

L.Settings.FeatureFlagsLabel = "Функции"
L.Settings.FeatureFlagsTooltip = nil
L.Settings.GroupNameLabel = "Переименовать группу"
L.Settings.GroupNamePrompt = "Введите название этой группы:"
L.Settings.TemplateLabel = "Шаблон"
L.Settings.TemplateTooltip = "Смена шаблона сбрасывает раскладку элементов этой группы к настройкам шаблона по умолчанию."
L.Settings.TemplateLabels = { [Private.Enum.Template.Icon] = "Значок", [Private.Enum.Template.Bar] = "Полоса", [Private.Enum.Template.IconDuration] = "Значок + длительность" }
L.Settings.FilterLabel = "Показывать заклинания, нацеленные на"
L.Settings.FilterTooltip = "Цели заклинаний, которые показывает эта группа."
L.Settings.TargetClassLabels = { [Private.Enum.TargetClass.Player] = "вас", [Private.Enum.TargetClass.PartyMember] = "членов группы", [Private.Enum.TargetClass.Nobody] = "никого (без цели)" }
L.Settings.CreateGroup = "Создать группу"
L.Settings.DeleteGroup = "Удалить группу"
L.Settings.DeleteGroupConfirm = "Удалить эту группу? Это действие нельзя отменить."
L.Settings.CannotDeleteLastGroup = "Нельзя удалить последнюю оставшуюся группу."
