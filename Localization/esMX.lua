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

L.Designer.Title = "Targeted Spells - Diseñador de diseño"
L.Designer.ElementPickerLabel = "Elemento"
L.Designer.SelectHint = "Haz clic en un elemento de la vista previa o elige uno en el menú desplegable de elementos."
L.Designer.ResetElement = "Restablecer elemento"
L.Designer.CopyFrom = "Copiar diseño de…"
L.Designer.CopyFromEmpty = "No hay otros grupos de este tipo"
L.Designer.Apply = "Guardar cambios"
L.Designer.Revert = "Revertir"
L.Designer.Discard = "Descartar"
L.Designer.UnsavedHint = "Los cambios se aplican al guardar."
L.Designer.UnsavedPrompt = "Tienes cambios de diseño sin guardar."
L.Designer.SettingNames = {
	ELEMENT_ACTIVE = "Habilitado", ELEMENT_WIDTH = "Ancho", ELEMENT_HEIGHT = "Alto", ELEMENT_X = "Desplazamiento X", ELEMENT_Y = "Desplazamiento Y", ELEMENT_FONT_SIZE = "Tamaño de fuente", ELEMENT_FONT = "Fuente", ELEMENT_FONT_FLAGS = "Estilo de fuente", ELEMENT_TEXT_COLOR = "Color del texto", ELEMENT_JUSTIFY_H = "Alineación", ELEMENT_MAX_WIDTH = "Ancho máximo", ELEMENT_GAP = "Espaciado", ELEMENT_USE_CLASS_COLOR = "Usar color de clase", ELEMENT_ICON_ZOOM = "Zoom del icono", ELEMENT_SHOW_SWIPE = "Mostrar barrido", ELEMENT_SHOW_COUNTDOWN = "Mostrar duración", ELEMENT_FRACTION_THRESHOLD = "Fracción inferior (s)", ELEMENT_BORDER_TEXTURE = "Textura del borde", ELEMENT_BORDER_COLOR = "Color del borde", ELEMENT_BORDER_SIZE = "Tamaño del borde", ELEMENT_BAR_TEXTURE = "Textura de la barra", ELEMENT_BAR_COLOR_MODE = "Modo de color", ELEMENT_BAR_COLOR = "Color de la barra", ELEMENT_INTERRUPTIBLE_COLOR = "Color interrumpible", ELEMENT_UNINTERRUPTIBLE_COLOR = "Color no interrumpible", ELEMENT_BACKGROUND_TEXTURE = "Textura del fondo", ELEMENT_BACKGROUND_COLOR = "Color del fondo",
}
L.Designer.Options = { JUSTIFY_LEFT = "Izquierda", JUSTIFY_CENTER = "Centro", JUSTIFY_RIGHT = "Derecha", BAR_COLOR_STATIC = "Estático", BAR_COLOR_INTERRUPTIBILITY = "Interrumpibilidad", BAR_COLOR_TARGET_CLASS = "Color de clase del objetivo" }
L.Designer.FontFlagNames = { [Private.Enum.FontFlags.OUTLINE] = "Contorno", [Private.Enum.FontFlags.SHADOW] = "Sombra" }
L.Designer.FontFlagsNone = "Ninguno"
L.Designer.ElementNames = { [Private.Enum.Element.Icon] = "Icono", [Private.Enum.Element.Overlay] = "Bisel del gestor de enfriamientos", [Private.Enum.Element.Cooldown] = "Enfriamiento", [Private.Enum.Element.Border] = "Borde", [Private.Enum.Element.InterruptSource] = "Nombre del interruptor", [Private.Enum.Element.ProgressBar] = "Barra de progreso", [Private.Enum.Element.Background] = "Fondo", [Private.Enum.Element.TargetMarker] = "Marcador de objetivo", [Private.Enum.Element.DurationCooldown] = "Duración", [Private.Enum.Element.SpellName] = "Nombre del hechizo", [Private.Enum.Element.TargetName] = "Nombre del objetivo", [Private.Enum.Element.InterruptShield] = "Escudo de interrupción", [Private.Enum.Element.Duration] = "Duración" }
L.SlashCommands.Header = "Comandos de Targeted Spells:"
L.SlashCommands.OptionsDescription = "Abrir el panel de configuración"
L.SlashCommands.SettingsDescription = "Abrir el panel de configuración"
L.SlashCommands.DesignDescription = "Abrir el diseñador de diseño"

L.Settings.EditModeReminder =
	"Todas las configuraciones están disponibles a través del modo edición y \"/targetedspells design\"."
L.EditMode.TargetedSpellsSelfLabel = "Targeted Spells - Uno mismo"
L.EditMode.TargetedSpellsPartyLabel = "Targeted Spells - Grupo"

L.Functionality.CVarWarning = string.format(
	"%s\n\nLa configuración de placas de nombre '%s' fue deshabilitada.\n\nSin ella, %s no funcionará en enemigos fuera de la pantalla.\n\nHaz clic en '%s' para habilitarla de nuevo.",
	addonNameWithIcon,
	UNIT_NAMEPLATES_SHOW_OFFSCREEN,
	addonName,
	ENABLE
)

L.Functionality.V3MigrationWarning = string.format(
	"%s\n\nDebido a actualizaciones en las restricciones de la API, la funcionalidad de Grupo de Targeted Spells tuvo que ser completamente revisada. Consulta el Modo de Edición para una vista previa.",
	addonNameWithIcon
)

L.Settings.EnabledLabel = "Activado"
L.Settings.DisabledLabel = "Desactivado"

L.Settings.AddonCompartmentTooltipLine1 =
	string.format("%s es %s", WrapTextInColorCode(L.EditMode.TargetedSpellsSelfLabel, "ffeda55f"), "%s")
L.Settings.AddonCompartmentTooltipLine2 =
	string.format("%s es %s", WrapTextInColorCode(L.EditMode.TargetedSpellsPartyLabel, "ffeda55f"), "%s")

L.Settings.LoadConditionContentTypeLabel = "Condición de carga: Tipo de contenido"
L.Settings.LoadConditionContentTypeTooltip = nil
L.Settings.LoadConditionContentTypeLabels = {
	[Private.Enum.ContentType.OpenWorld] = "Mundo abierto",
	[Private.Enum.ContentType.Delve] = "Profundidades",
	[Private.Enum.ContentType.Dungeon] = "Mazmorra",
	[Private.Enum.ContentType.Raid] = "Banda",
	[Private.Enum.ContentType.Arena] = "Arena",
	[Private.Enum.ContentType.Battleground] = "Campo de batalla",
}

L.Settings.LoadConditionRoleLabel = "Condición de carga: Rol"
L.Settings.LoadConditionRoleTooltip = nil
L.Settings.LoadConditionRoleLabels = {
	[Private.Enum.Role.Healer] = "Sanador",
	[Private.Enum.Role.Tank] = "Tanque",
	[Private.Enum.Role.Damager] = "Daño",
}

L.Settings.FrameGapLabel = "Espaciado"
L.Settings.FrameGapTooltip = nil

L.Settings.FrameDirectionLabel = "Dirección"
L.Settings.FrameDirectionTooltip = nil
L.Settings.FrameDirectionHorizontal = "Horizontal"
L.Settings.FrameDirectionVertical = "Vertical"

L.Settings.FrameSortOrderLabel = "Orden"
L.Settings.FrameSortOrderTooltip = nil
L.Settings.FrameSortOrderAscending = "Ascendente"
L.Settings.FrameSortOrderDescending = "Descendente"

L.Settings.FrameGrowLabel = "Crecimiento"
L.Settings.FrameGrowTooltip = nil
L.Settings.FrameGrowLabels = {
	[Private.Enum.Grow.Start] = "Inicio",
	[Private.Enum.Grow.End] = "Fin",
}

L.Settings.GlowImportantLabel = "Resaltar hechizos importantes"

L.Settings.OnlyImportantLabel = "Mostrar solo hechizos importantes"

L.Settings.GlowTypeLabel = "Tipo de resplandor"
L.Settings.GlowTypeTooltip = nil
L.Settings.GlowTypeLabels = {
	[Private.Enum.GlowType.PixelGlow] = "Resplandor de píxeles",
	[Private.Enum.GlowType.AutoCastGlow] = "Resplandor de lanzamiento automático",
	[Private.Enum.GlowType.ProcGlow] = "Resplandor de proc",
	[Private.Enum.GlowType.Star4] = "Estrella 4",
}

L.Settings.IndicateInterruptsLabel = "Indicar interrupciones"

L.Settings.TextToSpeechVoiceLabel = "Voz TTS"
L.Settings.TextToSpeechVoiceTooltip =
	"Voz usada para los anuncios de texto a voz. Compartida entre las configuraciones de Self y Party."

L.Settings.AnnounceUntargetedSpellsLabel = "Configuración TTS sin objetivo"
L.Settings.AnnounceUntargetedSpellsTooltip =
	"Texto a voz para hechizos sin objetivo (AoE, frontales, etc.) por tipo de PNJ."

L.Settings.AnnounceTargetedSpellsLabel = "Configuración TTS con objetivo"
L.Settings.AnnounceTargetedSpellsTooltip =
	"Texto a voz para hechizos que apuntan a un jugador específico, por tipo de PNJ."

L.Settings.NpcTypeLabels = {
	[Private.Enum.NpcType.Boss] = "Jefes",
	[Private.Enum.NpcType.Lieutenant] = "Lugartenientes",
	[Private.Enum.NpcType.Other] = "Todos los demás",
	[Private.Enum.NpcType.Minion] = "Secuaces",
}

L.Settings.UseTargetClassColorLabel = "Usar color de clase del objetivo"
L.Settings.UseTargetClassColorTooltip =
	"Colorea la barra con el color de clase de la unidad objetivo al 75 % de opacidad. Los hechizos sin objetivo usarán un Color de Barra de Fondo más brillante."

L.Settings.ClickToOpenSettingsLabel = "Haga clic para abrir la configuración"

L.Settings.Import = "Importar"
L.Settings.Export = "Exportar"

L.Settings.FeatureFlagsLabel = "Características"
L.Settings.FeatureFlagsTooltip = nil
L.Settings.GroupNameLabel = "Cambiar nombre del grupo"
L.Settings.GroupNamePrompt = "Introduce un nombre para este grupo:"
L.Settings.TemplateLabel = "Plantilla"
L.Settings.TemplateTooltip = "Cambiar la plantilla restablece el diseño de elementos de este grupo al predeterminado."
L.Settings.TemplateLabels = { [Private.Enum.Template.Icon] = "Icono", [Private.Enum.Template.Bar] = "Barra", [Private.Enum.Template.IconDuration] = "Icono + duración" }
L.Settings.FilterLabel = "Mostrar lanzamientos dirigidos a"
L.Settings.FilterTooltip = "Qué objetivos de lanzamiento muestra este grupo."
L.Settings.TargetClassLabels = { [Private.Enum.TargetClass.Player] = "ti", [Private.Enum.TargetClass.PartyMember] = "miembros del grupo", [Private.Enum.TargetClass.Nobody] = "nadie (sin objetivo)" }
L.Settings.CreateGroup = "Crear grupo"
L.Settings.DeleteGroup = "Eliminar grupo"
L.Settings.DeleteGroupConfirm = "¿Eliminar este grupo? Esta acción no se puede deshacer."
L.Settings.CannotDeleteLastGroup = "No puedes eliminar el último grupo restante."
