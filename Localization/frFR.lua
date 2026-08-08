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
	"Tous les paramètres sont accessibles via le Mode Édition et \"/targetedspells design\"."
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
L.Settings.DisabledLabel = "Désactivé"

L.Settings.AddonCompartmentTooltipLine1 =
	string.format("%s est %s", WrapTextInColorCode(L.EditMode.TargetedSpellsSelfLabel, "ffeda55f"), "%s")
L.Settings.AddonCompartmentTooltipLine2 =
	string.format("%s est %s", WrapTextInColorCode(L.EditMode.TargetedSpellsPartyLabel, "ffeda55f"), "%s")

L.Settings.LoadConditionContentTypeLabel = "Condition de chargement: Type de contenu"
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
L.Settings.LoadConditionRoleTooltip = nil
L.Settings.LoadConditionRoleLabels = {
	[Private.Enum.Role.Healer] = "Healer",
	[Private.Enum.Role.Tank] = "Tank",
	[Private.Enum.Role.Damager] = "DPS",
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

L.Settings.IndicateInterruptsLabel = "Montrer l'interruption"

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
	[Private.Enum.NpcType.Other] = "Tous les autres",
	[Private.Enum.NpcType.Minion] = "Sbires",
}

L.Settings.UseTargetClassColorLabel = "Utiliser la couleur de classe de la cible"
L.Settings.UseTargetClassColorTooltip =
	"Colore la barre avec la couleur de classe de l'unité ciblée à 75 % d'opacité. Les sorts sans cible utiliseront une Couleur de Barre de Fond éclaircie."

L.Settings.ClickToOpenSettingsLabel = "Cliquer pour ouvrir les paramètres"

L.Settings.Import = "Importer"
L.Settings.Export = "Exporter"

L.Settings.FeatureFlagsLabel = "Fonctionnalités"
L.Settings.FeatureFlagsTooltip = nil
