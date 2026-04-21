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
	"Pensez à utiliser le Mode Édition, il inclut un aperçu en direct de tous les paramètres.\nCeux-ci sont uniquement présents pour permettre l'édition en combat."
L.EditMode.TargetedSpellsSelfLabel = "Targeted Spells - Self"
L.EditMode.TargetedSpellsPartyLabel = "Targeted Spells - Party"

L.Functionality.CVarWarning = string.format(
	"%s\n\nLe paramètre des plaques de nom '%s' a été désactivé.\n\nSans lui, %s ne fonctionnera pas sur les ennemis hors de l'écran.\n\nCliquez sur '%s' pour le réactiver.",
	addonNameWithIcon,
	UNIT_NAMEPLATES_SHOW_OFFSCREEN,
	addonName,
	ENABLE
)

L.Functionality.V3MigrationWarning = string.format(
	"%s\n\nEn raison de mises à jour des restrictions de l'API, la fonctionnalité Groupe de Targeted Spells a dû être entièrement revue. Consultez le Mode Édition pour un aperçu.",
	addonNameWithIcon
)

L.Settings.EnabledLabel = "Activé"
L.Settings.EnabledTooltip = nil
L.Settings.DisabledLabel = "Désactivé"

L.Settings.AddonCompartmentTooltipLine1 =
	string.format("%s est %s", WrapTextInColorCode(L.EditMode.TargetedSpellsSelfLabel, "ffeda55f"), "%s")
L.Settings.AddonCompartmentTooltipLine2 =
	string.format("%s est %s", WrapTextInColorCode(L.EditMode.TargetedSpellsPartyLabel, "ffeda55f"), "%s")

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

L.Settings.FontFlagsLabel = "Options de police"
L.Settings.FontFlagsTooltip = nil
L.Settings.FontFlagsLabels = {
	[Private.Enum.FontFlags.OUTLINE] = "Contour",
	[Private.Enum.FontFlags.SHADOW] = "Ombre",
}

L.Settings.FrameGapLabel = "Ecart"
L.Settings.FrameGapTooltip = nil

L.Settings.FrameDirectionLabel = "Direction"
L.Settings.FrameDirectionTooltip = nil
L.Settings.FrameDirectionHorizontal = "Horizontal"
L.Settings.FrameDirectionVertical = "Vertical"

L.Settings.FrameSortOrderLabel = "Ordre de tri"
L.Settings.FrameSortOrderTooltip = nil
L.Settings.FrameSortOrderAscending = "Croissant"
L.Settings.FrameSortOrderDescending = "Décroissant"

L.Settings.FrameGrowLabel = "Extension"
L.Settings.FrameGrowTooltip = nil
L.Settings.FrameGrowLabels = {
	[Private.Enum.Grow.Start] = "Début",
	[Private.Enum.Grow.End] = "Fin",
}

L.Settings.GlowImportantLabel = "Faire briller les sorts important"

L.Settings.OnlyImportantLabel = "Afficher uniquement les sorts importants"

L.Settings.GlowTypeLabel = "Type de lueur"
L.Settings.GlowTypeTooltip = nil
L.Settings.GlowTypeLabels = {
	[Private.Enum.GlowType.PixelGlow] = "Pixel Glow",
	[Private.Enum.GlowType.AutoCastGlow] = "Auto Cast Glow",
	[Private.Enum.GlowType.ProcGlow] = "Proc Glow",
	[Private.Enum.GlowType.Star4] = "Star 4",
}

L.Settings.ShowDurationLabel = "Montrer la durée"

L.Settings.IndicateInterruptsLabel = "Montrer l'interruption"

L.Settings.RenderInterruptSourceNameLabel = "Afficher la source d'interruption"

L.Settings.ShowSwipeLabel = "Afficher le balayage"

L.Settings.BorderStyleLabel = "Style de bordure"
L.Settings.BorderStyleTooltip = nil

L.Settings.ForegroundBarTextureLabel = "Texture de la barre de progression"
L.Settings.ForegroundBarTextureTooltip = nil

L.Settings.BackgroundBarTextureLabel = "Texture de fond de la barre"
L.Settings.BackgroundBarTextureTooltip = nil

L.Settings.BackgroundBarColorLabel = "Couleur de fond de la barre"
L.Settings.BackgroundBarColorTooltip =
	"L'opacité n'est disponible qu'en Mode Édition, car l'interface des paramètres par défaut ne l'expose pas."

L.Settings.ProgressBarColorLabel = "Couleur de la barre"
L.Settings.ProgressBarColorTooltip =
	"L'opacité n'est disponible qu'en Mode Édition, car l'interface des paramètres par défaut ne l'expose pas."

L.Settings.MirrorLayoutLabel = "Disposition en miroir"

L.Settings.TextToSpeechVoiceLabel = "Voix TTS"
L.Settings.TextToSpeechVoiceTooltip =
	"Voix utilisée pour les annonces de synthèse vocale. Partagée entre les paramètres Self et Party."

L.Settings.AnnounceUntargetedSpellsLabel = "Paramètres TTS non ciblés"
L.Settings.AnnounceUntargetedSpellsTooltip =
	"Synthèse vocale pour les sorts sans cible (AoE, frontaux, etc.) par type de PNJ."

L.Settings.AnnounceTargetedSpellsLabel = "Paramètres TTS ciblés"
L.Settings.AnnounceTargetedSpellsTooltip =
	"Synthèse vocale pour les sorts ciblant un joueur spécifique, par type de PNJ."

L.Settings.NpcTypeLabels = {
	[Private.Enum.NpcType.Boss] = "Boss",
	[Private.Enum.NpcType.Lieutenant] = "Lieutenants",
	[Private.Enum.NpcType.Caster] = "A du mana",
	[Private.Enum.NpcType.Melee] = "Melee normal",
	[Private.Enum.NpcType.Minion] = "Sbires",
}

L.Settings.HideUntargetedSpellsLabel = "Masquer les sorts sans cible"

L.Settings.HideTargetedSpellsLabel = "Masquer les sorts avec cible"

L.Settings.SelfOnlyLabel = "Afficher uniquement les sorts ciblant le joueur"

L.Settings.InlineDurationLabel = "Durée en position intégrée"

L.Settings.UseInterruptabilityColorsLabel = "Utiliser les couleurs d'interruption"
L.Settings.UseInterruptabilityColorsTooltip = nil

L.Settings.UseTargetClassColorLabel = "Utiliser la couleur de classe de la cible"
L.Settings.UseTargetClassColorTooltip =
	"Colore la barre avec la couleur de classe de l'unité ciblée à 75 % d'opacité. Les sorts sans cible utiliseront une Couleur de Barre de Fond éclaircie."

L.Settings.UninterruptibleColorLabel = "Couleur ininterruptible"
L.Settings.UninterruptibleColorTooltip = nil

L.Settings.InterruptibleColorLabel = "Couleur interruptible"
L.Settings.InterruptibleColorTooltip = nil

L.Settings.IconZoomLabel = "Zoom de l'icône"
L.Settings.IconZoomTooltip = nil

L.Settings.ClickToOpenSettingsLabel = "Cliquer pour ouvrir les paramètres"

L.Settings.Import = "Importer"
L.Settings.Export = "Exporter"

L.Settings.FontLabel = "Police"
L.Settings.FontTooltip = nil

L.Settings.FeatureFlagsLabel = "Fonctionnalités"
L.Settings.FeatureFlagsTooltip = nil

L.Settings.FeatureFlagLabels = {
	[Private.Enum.FeatureFlag.GlowImportant] = L.Settings.GlowImportantLabel,
	[Private.Enum.FeatureFlag.OnlyImportant] = L.Settings.OnlyImportantLabel,
	[Private.Enum.FeatureFlag.ShowDuration] = L.Settings.ShowDurationLabel,
	[Private.Enum.FeatureFlag.ShowSwipe] = L.Settings.ShowSwipeLabel,
	[Private.Enum.FeatureFlag.IndicateInterrupts] = L.Settings.IndicateInterruptsLabel,
	[Private.Enum.FeatureFlag.RenderInterruptSourceName] = L.Settings.RenderInterruptSourceNameLabel,
	[Private.Enum.FeatureFlag.ShowIcon] = "Afficher l'icône",
	[Private.Enum.FeatureFlag.ShowTargetMarker] = "Afficher le marqueur de cible",
	[Private.Enum.FeatureFlag.ShowSpellName] = "Afficher le nom du sort",
	[Private.Enum.FeatureFlag.ShowTargetName] = "Afficher le nom de la cible",
	[Private.Enum.FeatureFlag.ShowTargetClassColor] = "Afficher la couleur de classe de la cible",
	[Private.Enum.FeatureFlag.MirrorLayout] = L.Settings.MirrorLayoutLabel,
	[Private.Enum.FeatureFlag.InlineDuration] = L.Settings.InlineDurationLabel,
	[Private.Enum.FeatureFlag.HideUntargetedSpells] = L.Settings.HideUntargetedSpellsLabel,
	[Private.Enum.FeatureFlag.HideTargetedSpells] = L.Settings.HideTargetedSpellsLabel,
	[Private.Enum.FeatureFlag.SelfOnly] = L.Settings.SelfOnlyLabel,
}

L.Settings.FeatureFlagSettingTitles = {
	[Private.Enum.FeatureFlag.GlowImportant] = "Affichage",
	[Private.Enum.FeatureFlag.IndicateInterrupts] = "Paramètres d'interruption",
}
