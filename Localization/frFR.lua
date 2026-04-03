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
	"Consider using the Edit Mode instead, it includes live preview of all settings.\nThese here are only present to allow editing in combat."
L.EditMode.TargetedSpellsSelfLabel = "Targeted Spells - Self"
L.EditMode.TargetedSpellsPartyLabel = "Targeted Spells - Party"

L.Functionality.CVarWarning = string.format(
	"%s\n\nThe Nameplate Setting '%s' was disabled.\n\nWithout it, %s will not work on off-screen enemies.\n\nClick '%s' to enable it again.",
	addonNameWithIcon,
	UNIT_NAMEPLATES_SHOW_OFFSCREEN,
	addonName,
	ENABLE
)

L.Functionality.V3DeprecationWarning = "TODO"

L.Settings.EnabledLabel = "Activé"
L.Settings.EnabledTooltip = nil
L.Settings.DisabledLabel = "Désactivé"

L.Settings.AddonCompartmentTooltipLine1 =
	string.format("%s is %s", WrapTextInColorCode(L.EditMode.TargetedSpellsSelfLabel, "ffeda55f"), "%s")
L.Settings.AddonCompartmentTooltipLine2 =
	string.format("%s is %s", WrapTextInColorCode(L.EditMode.TargetedSpellsPartyLabel, "ffeda55f"), "%s")

L.Settings.LoadConditionContentTypeLabel = "Condition de chargement: Type de contenu"
L.Settings.LoadConditionContentTypeLabelAbbreviated = "Charger dans le contenu"
L.Settings.LoadConditionContentTypeTooltip = nil
L.Settings.LoadConditionContentTypeLabels = {
	[Private.Enum.ContentType.OpenWorld] = "Monde ouvert",
	[Private.Enum.ContentType.Delve] = "Gouffre",
	[Private.Enum.ContentType.Dungeon] = "Donjon",
	[Private.Enum.ContentType.Raid] = "Raid",
	[Private.Enum.ContentType.Arena] = "Arène",
	[Private.Enum.ContentType.Battleground] = "Champ de bataille",
}

L.Settings.LoadConditionRoleLabel = "Condition de chargement: Rôle"
L.Settings.LoadConditionRoleLabelAbbreviated = "Chargement sur Rôle"
L.Settings.LoadConditionRoleTooltip = nil
L.Settings.LoadConditionRoleLabels = {
	[Private.Enum.Role.Healer] = "Healer",
	[Private.Enum.Role.Tank] = "Tank",
	[Private.Enum.Role.Damager] = "DPS",
}

L.Settings.FrameWidthLabel = "Largeur"
L.Settings.FrameWidthTooltip = nil

L.Settings.FrameHeightLabel = "Hauteur"
L.Settings.FrameHeightTooltip = nil

L.Settings.FontSizeLabel = "Taille de la police"
L.Settings.FontSizeTooltip = nil

L.Settings.FontFlagsLabel = "Font Options"
L.Settings.FontFlagsTooltip = nil
L.Settings.FontFlagsLabels = {
	[Private.Enum.FontFlags.OUTLINE] = "Outline",
	[Private.Enum.FontFlags.SHADOW] = "Shadow",
}

L.Settings.FrameGapLabel = "Ecart"
L.Settings.FrameGapTooltip = nil

L.Settings.FrameDirectionLabel = "Direction"
L.Settings.FrameDirectionTooltip = nil
L.Settings.FrameDirectionHorizontal = "Horizontal"
L.Settings.FrameDirectionVertical = "Vertical"

L.Settings.FrameSortOrderLabel = "Sort Order"
L.Settings.FrameSortOrderTooltip = nil
L.Settings.FrameSortOrderAscending = "Ascending"
L.Settings.FrameSortOrderDescending = "Descending"

L.Settings.FrameGrowLabel = "Grow"
L.Settings.FrameGrowTooltip = nil
L.Settings.FrameGrowLabels = {
	[Private.Enum.Grow.Start] = "Start",
	[Private.Enum.Grow.End] = "End",
}

L.Settings.GlowImportantLabel = "Faire briller les sorts important"
L.Settings.GlowImportantTooltip = "Ce qui est important ou non est déclaré par le jeu."

L.Settings.OnlyImportantLabel = "Only Show Important Spells"
L.Settings.OnlyImportantTooltip = "Note that you're relying on what the game considers important, use at your own risk."

L.Settings.GlowTypeLabel = "Glow Type"
L.Settings.GlowTypeTooltip = nil
L.Settings.GlowTypeLabels = {
	[Private.Enum.GlowType.PixelGlow] = "Pixel Glow",
	[Private.Enum.GlowType.AutoCastGlow] = "Auto Cast Glow",
	[Private.Enum.GlowType.ProcGlow] = "Proc Glow",
	[Private.Enum.GlowType.Star4] = "Star 4",
}

L.Settings.ShowDurationLabel = "Montrer la durée"
L.Settings.ShowDurationTooltip = nil

L.Settings.IndicateInterruptsLabel = "Montrer l'interruption"
L.Settings.IndicateInterruptsTooltip =
	"Désature l'icône, affiche un indicateur par-dessus et retarde sa disparition de 1 seconde. Ne marche pas avec les sorts canalisés."

L.Settings.RenderInterruptSourceNameLabel = "Render Interrupt Source Name"
L.Settings.RenderInterruptSourceNameTooltip = nil

L.Settings.ShowSwipeLabel = "Show Swipe"
L.Settings.ShowSwipeTooltip = nil

L.Settings.BorderStyleLabel = "Border Style"
L.Settings.BorderStyleTooltip = nil
L.Settings.BorderStyleSolid = "Solid"

L.Settings.OpacityLabel = "Opacité"
L.Settings.OpacityTooltip = nil

L.Settings.SpellNameWidthLabel = "Longueur du nom du sort"
L.Settings.SpellNameWidthTooltip = "Largeur maximale du texte du nom du sort. Mettre à 0 pour aucune limite."

L.Settings.TargetNameWidthLabel = "Longueur du nom de la cible"
L.Settings.TargetNameWidthTooltip = "Largeur maximale du texte du nom de la cible. Mettre à 0 pour aucune limite."

L.Settings.NameDividerLabel = "Séparateur de noms"
L.Settings.NameDividerNone = "Aucun"

L.Settings.IconZoomLabel = "Icon Zoom"
L.Settings.IconZoomTooltip = nil

L.Settings.FrameOffsetXLabel = "Offset X"
L.Settings.FrameOffsetXTooltip = nil

L.Settings.FrameOffsetYLabel = "Offset Y"
L.Settings.FrameOffsetYTooltip = nil

L.Settings.ClickToOpenSettingsLabel = "Cliquer pour ouvrir les paramètres"

L.Settings.Import = "Importer"
L.Settings.Export = "Exporter"

L.Settings.FontLabel = "Police"
L.Settings.FontTooltip = nil

L.Settings.TargetNamePreviewText = "Nom de la cible"

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
	[Private.Enum.FeatureFlag.ShowIcon] = "Afficher l'icône",
	[Private.Enum.FeatureFlag.ShowTargetMarker] = "Afficher le marqueur de cible",
	[Private.Enum.FeatureFlag.ShowSpellName] = "Afficher le nom du sort",
	[Private.Enum.FeatureFlag.ShowTargetName] = "Afficher le nom de la cible",
	[Private.Enum.FeatureFlag.ShowTargetClassColor] = "Afficher la couleur de classe de la cible",
}

L.Settings.FeatureFlagSettingTitles = {
	[Private.Enum.FeatureFlag.GlowImportant] = "Affichage",
	[Private.Enum.FeatureFlag.IndicateInterrupts] = "Paramètres d'interruption",
	[Private.Enum.FeatureFlag.IncludeSelfInParty] = "Paramètres de groupe",
}
