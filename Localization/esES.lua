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

L.Functionality.V3DeprecationWarning = "TODO"

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

L.Settings.FontFlagsLabel = "Font Options"
L.Settings.FontFlagsTooltip = nil
L.Settings.FontFlagsLabels = {
	[Private.Enum.FontFlags.OUTLINE] = "Outline",
	[Private.Enum.FontFlags.SHADOW] = "Shadow",
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
L.Settings.GlowImportantTooltip = "Lo que es importante y lo que no lo es lo declara el juego."

L.Settings.OnlyImportantLabel = "Only Show Important Spells"
L.Settings.OnlyImportantTooltip = "Note that you're relying on what the game considers important, use at your own risk."

L.Settings.GlowTypeLabel = "Tipo de resplandor"
L.Settings.GlowTypeTooltip = nil
L.Settings.GlowTypeLabels = {
	[Private.Enum.GlowType.PixelGlow] = "Resplandor de píxeles",
	[Private.Enum.GlowType.AutoCastGlow] = "Resplandor de lanzamiento automático",
	[Private.Enum.GlowType.ProcGlow] = "Resplandor de proc",
	[Private.Enum.GlowType.Star4] = "Estrella 4",
}

L.Settings.ShowDurationLabel = "Mostrar duración"
L.Settings.ShowDurationTooltip = nil

L.Settings.IndicateInterruptsLabel = "Indicar interrupciones"
L.Settings.IndicateInterruptsTooltip =
	"Desatura el icono, muestra un indicador encima del icono y retrasa ocultar el icono 1 segundo. No funciona con hechizos canalizados."

L.Settings.RenderInterruptSourceNameLabel = "Render Interrupt Source Name"
L.Settings.RenderInterruptSourceNameTooltip = nil

L.Settings.ShowSwipeLabel = "Mostrar barrido"
L.Settings.ShowSwipeTooltip = nil

L.Settings.BorderStyleLabel = "Border Style"
L.Settings.BorderStyleTooltip = nil
L.Settings.BorderStyleSolid = "Solid"

L.Settings.OpacityLabel = "Opacidad"
L.Settings.OpacityTooltip = nil

L.Settings.SpellNameWidthLabel = "Longitud del nombre del hechizo"
L.Settings.SpellNameWidthTooltip = "Anchura máxima del texto del nombre del hechizo. Establece 0 para sin límite."

L.Settings.TargetNameWidthLabel = "Longitud del nombre del objetivo"
L.Settings.TargetNameWidthTooltip = "Anchura máxima del texto del nombre del objetivo. Establece 0 para sin límite."

L.Settings.NameDividerLabel = "Separador de nombres"
L.Settings.NameDividerNone = "Ninguno"

L.Settings.IconZoomLabel = "Icon Zoom"
L.Settings.IconZoomTooltip = nil

L.Settings.FrameOffsetXLabel = "Desplazamiento X"
L.Settings.FrameOffsetXTooltip = nil

L.Settings.FrameOffsetYLabel = "Desplazamiento Y"
L.Settings.FrameOffsetYTooltip = nil

L.Settings.ClickToOpenSettingsLabel = "Haz clic para abrir la configuración"

L.Settings.Import = "Importar"
L.Settings.Export = "Exportar"

L.Settings.FontLabel = "Fuente"
L.Settings.FontTooltip = nil

L.Settings.TargetNamePreviewText = "Nombre del objetivo"

L.Settings.FeatureFlagsLabel = "Features"
L.Settings.FeatureFlagsTooltip = nil

L.Settings.FeatureFlagLabels = {
	[Private.Enum.FeatureFlag.GlowImportant] = L.Settings.GlowImportantLabel,
	[Private.Enum.FeatureFlag.OnlyImportant] = L.Settings.OnlyImportantLabel,
	[Private.Enum.FeatureFlag.ShowDuration] = L.Settings.ShowDurationLabel,
	[Private.Enum.FeatureFlag.ShowSwipe] = L.Settings.ShowSwipeLabel,
	[Private.Enum.FeatureFlag.IndicateInterrupts] = L.Settings.IndicateInterruptsLabel,
	[Private.Enum.FeatureFlag.RenderInterruptSourceName] = L.Settings.RenderInterruptSourceNameLabel,
	[Private.Enum.FeatureFlag.IncludeSelfInParty] = L.Settings.IncludeSelfInPartyLabel,
	[Private.Enum.FeatureFlag.ShowIcon] = "Mostrar icono",
	[Private.Enum.FeatureFlag.ShowTargetMarker] = "Mostrar marcador de objetivo",
	[Private.Enum.FeatureFlag.ShowSpellName] = "Mostrar nombre del hechizo",
	[Private.Enum.FeatureFlag.ShowTargetName] = "Mostrar nombre del objetivo",
	[Private.Enum.FeatureFlag.ShowTargetClassColor] = "Mostrar color de clase del objetivo",
}

L.Settings.FeatureFlagSettingTitles = {
	[Private.Enum.FeatureFlag.GlowImportant] = "Display",
	[Private.Enum.FeatureFlag.IndicateInterrupts] = "Interrupt Settings",
	[Private.Enum.FeatureFlag.IncludeSelfInParty] = "Party Settings",
}
