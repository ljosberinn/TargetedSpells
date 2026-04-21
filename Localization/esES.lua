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
	"Puedes usar el modo edición, incluye una vista previa en vivo de todas las configuraciones.\nLas de aquí solo están presentes para permitir la edición en combate."
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
L.Settings.EnabledTooltip = nil
L.Settings.DisabledLabel = "Desactivado"

L.Settings.AddonCompartmentTooltipLine1 =
	string.format("%s es %s", WrapTextInColorCode(L.EditMode.TargetedSpellsSelfLabel, "ffeda55f"), "%s")
L.Settings.AddonCompartmentTooltipLine2 =
	string.format("%s es %s", WrapTextInColorCode(L.EditMode.TargetedSpellsPartyLabel, "ffeda55f"), "%s")

L.Settings.LoadConditionContentTypeLabel = "Condición de carga: Tipo de contenido"
L.Settings.LoadConditionContentTypeLabelAbbreviated = "Cargar en contenido"
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
L.Settings.LoadConditionRoleLabelAbbreviated = "Cargar en rol"
L.Settings.LoadConditionRoleTooltip = nil
L.Settings.LoadConditionRoleLabels = {
	[Private.Enum.Role.Healer] = "Sanador",
	[Private.Enum.Role.Tank] = "Tanque",
	[Private.Enum.Role.Damager] = "Daño",
}

L.Settings.FrameWidthLabel = "Ancho"
L.Settings.FrameWidthTooltip = nil

L.Settings.FrameHeightLabel = "Altura"
L.Settings.FrameHeightTooltip = nil

L.Settings.FontSizeLabel = "Tamaño de fuente"
L.Settings.FontSizeTooltip = nil

L.Settings.FontFlagsLabel = "Opciones de fuente"
L.Settings.FontFlagsTooltip = nil
L.Settings.FontFlagsLabels = {
	[Private.Enum.FontFlags.OUTLINE] = "Contorno",
	[Private.Enum.FontFlags.SHADOW] = "Sombra",
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

L.Settings.ShowDurationLabel = "Mostrar duración"

L.Settings.IndicateInterruptsLabel = "Indicar interrupciones"

L.Settings.RenderInterruptSourceNameLabel = "Mostrar nombre de fuente de interrupción"

L.Settings.ShowSwipeLabel = "Mostrar barrido"

L.Settings.BorderStyleLabel = "Estilo de borde"
L.Settings.BorderStyleTooltip = nil

L.Settings.ForegroundBarTextureLabel = "Textura de la barra de progreso"
L.Settings.ForegroundBarTextureTooltip = nil

L.Settings.BackgroundBarTextureLabel = "Textura de fondo de la barra"
L.Settings.BackgroundBarTextureTooltip = nil

L.Settings.BackgroundBarColorLabel = "Color de fondo de la barra"
L.Settings.BackgroundBarColorTooltip =
	"La opacidad solo está disponible en el Modo de Edición, ya que la interfaz de configuración predeterminada no la muestra."

L.Settings.ProgressBarColorLabel = "Color de barra"
L.Settings.ProgressBarColorTooltip =
	"La opacidad solo está disponible en el Modo de Edición, ya que la interfaz de configuración predeterminada no la muestra."

L.Settings.MirrorLayoutLabel = "Invertir diseño"

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
	[Private.Enum.NpcType.Caster] = "Tiene maná",
	[Private.Enum.NpcType.Melee] = "Enemigos normales",
	[Private.Enum.NpcType.Minion] = "Secuaces",
}

L.Settings.HideUntargetedSpellsLabel = "Ocultar hechizos sin objetivo"
L.Settings.HideTargetedSpellsLabel = "Ocultar hechizos con objetivo"

L.Settings.SelfOnlyLabel = "Mostrar solo hechizos dirigidos al jugador"

L.Settings.InlineDurationLabel = "Posición de duración integrada"

L.Settings.UseInterruptabilityColorsLabel = "Usar colores de interrupción"
L.Settings.UseInterruptabilityColorsTooltip = nil

L.Settings.UseTargetClassColorLabel = "Usar color de clase del objetivo"
L.Settings.UseTargetClassColorTooltip =
	"Colorea la barra con el color de clase de la unidad objetivo al 75 % de opacidad. Los hechizos sin objetivo usarán un Color de Barra de Fondo más brillante."

L.Settings.UninterruptibleColorLabel = "Color ininterrumpible"
L.Settings.UninterruptibleColorTooltip = nil

L.Settings.InterruptibleColorLabel = "Color interrumpible"
L.Settings.InterruptibleColorTooltip = nil

L.Settings.IconZoomLabel = "Zoom del icono"
L.Settings.IconZoomTooltip = nil

L.Settings.ClickToOpenSettingsLabel = "Haz clic para abrir la configuración"

L.Settings.Import = "Importar"
L.Settings.Export = "Exportar"

L.Settings.FontLabel = "Fuente"
L.Settings.FontTooltip = nil

L.Settings.FeatureFlagsLabel = "Características"
L.Settings.FeatureFlagsTooltip = nil

L.Settings.FeatureFlagLabels = {
	[Private.Enum.FeatureFlag.GlowImportant] = L.Settings.GlowImportantLabel,
	[Private.Enum.FeatureFlag.OnlyImportant] = L.Settings.OnlyImportantLabel,
	[Private.Enum.FeatureFlag.ShowDuration] = L.Settings.ShowDurationLabel,
	[Private.Enum.FeatureFlag.ShowSwipe] = L.Settings.ShowSwipeLabel,
	[Private.Enum.FeatureFlag.IndicateInterrupts] = L.Settings.IndicateInterruptsLabel,
	[Private.Enum.FeatureFlag.RenderInterruptSourceName] = L.Settings.RenderInterruptSourceNameLabel,
	[Private.Enum.FeatureFlag.ShowIcon] = "Mostrar icono",
	[Private.Enum.FeatureFlag.ShowTargetMarker] = "Mostrar marcador de objetivo",
	[Private.Enum.FeatureFlag.ShowSpellName] = "Mostrar nombre del hechizo",
	[Private.Enum.FeatureFlag.ShowTargetName] = "Mostrar nombre del objetivo",
	[Private.Enum.FeatureFlag.ShowTargetClassColor] = "Mostrar color de clase del objetivo",
	[Private.Enum.FeatureFlag.MirrorLayout] = L.Settings.MirrorLayoutLabel,
	[Private.Enum.FeatureFlag.InlineDuration] = L.Settings.InlineDurationLabel,
	[Private.Enum.FeatureFlag.HideUntargetedSpells] = L.Settings.HideUntargetedSpellsLabel,
	[Private.Enum.FeatureFlag.HideTargetedSpells] = L.Settings.HideTargetedSpellsLabel,
	[Private.Enum.FeatureFlag.SelfOnly] = L.Settings.SelfOnlyLabel,
}

L.Settings.FeatureFlagSettingTitles = {
	[Private.Enum.FeatureFlag.GlowImportant] = "Visualización",
	[Private.Enum.FeatureFlag.IndicateInterrupts] = "Configuración de interrupción",
}
