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

L.Settings.ClickToOpenSettingsLabel = "Haz clic para abrir la configuración"

L.Settings.Import = "Importar"
L.Settings.Export = "Exportar"

L.Settings.FeatureFlagsLabel = "Características"
L.Settings.FeatureFlagsTooltip = nil
