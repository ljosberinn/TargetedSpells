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
L.Designer.Title = "Targeted Spells - Concepteur de mise en page"
L.Designer.ElementPickerLabel = "Élément"
L.Designer.SelectHint = "Cliquez sur un élément dans l'aperçu ou sélectionnez-en un dans la liste des éléments."
L.Designer.ResetElement = "Réinitialiser l'élément"
L.Designer.CopyFrom = "Copier la mise en page depuis…"
L.Designer.CopyFromEmpty = "Aucun autre groupe de ce type"
L.Designer.Apply = "Enregistrer les modifications"
L.Designer.Revert = "Rétablir"
L.Designer.Discard = "Abandonner"
L.Designer.UnsavedHint = "Les modifications s'appliquent lors de l'enregistrement."
L.Designer.UnsavedPrompt = "Vous avez des modifications de mise en page non enregistrées."
L.Designer.SettingNames = { ELEMENT_ACTIVE = "Activé", ELEMENT_WIDTH = "Largeur", ELEMENT_HEIGHT = "Hauteur", ELEMENT_X = "Décalage X", ELEMENT_Y = "Décalage Y", ELEMENT_FONT_SIZE = "Taille de police", ELEMENT_FONT = "Police", ELEMENT_FONT_FLAGS = "Style de police", ELEMENT_TEXT_COLOR = "Couleur du texte", ELEMENT_JUSTIFY_H = "Alignement", ELEMENT_MAX_WIDTH = "Largeur maximale", ELEMENT_GAP = "Écart", ELEMENT_USE_CLASS_COLOR = "Utiliser la couleur de classe", ELEMENT_ICON_ZOOM = "Zoom de l'icône", ELEMENT_SHOW_SWIPE = "Afficher l'animation de balayage", ELEMENT_SHOW_COUNTDOWN = "Afficher la durée", ELEMENT_FRACTION_THRESHOLD = "Fraction sous (s)", ELEMENT_BORDER_TEXTURE = "Texture de bordure", ELEMENT_BORDER_COLOR = "Couleur de bordure", ELEMENT_BORDER_SIZE = "Taille de bordure", ELEMENT_BAR_TEXTURE = "Texture de barre", ELEMENT_BAR_COLOR_MODE = "Mode de couleur", ELEMENT_BAR_COLOR = "Couleur de barre", ELEMENT_INTERRUPTIBLE_COLOR = "Couleur interruptible", ELEMENT_UNINTERRUPTIBLE_COLOR = "Couleur non interruptible", ELEMENT_BACKGROUND_TEXTURE = "Texture d'arrière-plan", ELEMENT_BACKGROUND_COLOR = "Couleur d'arrière-plan" }
L.Designer.Options = { JUSTIFY_LEFT = "Gauche", JUSTIFY_CENTER = "Centre", JUSTIFY_RIGHT = "Droite", BAR_COLOR_STATIC = "Statique", BAR_COLOR_INTERRUPTIBILITY = "Interruptibilité", BAR_COLOR_TARGET_CLASS = "Couleur de classe de la cible" }
L.Designer.FontFlagNames = { [Private.Enum.FontFlags.OUTLINE] = "Contour", [Private.Enum.FontFlags.SHADOW] = "Ombre" }
L.Designer.FontFlagsNone = "Aucun"
L.Designer.ElementNames = { [Private.Enum.Element.Icon] = "Icône", [Private.Enum.Element.Overlay] = "Cadre du gestionnaire de temps de recharge", [Private.Enum.Element.Cooldown] = "Temps de recharge", [Private.Enum.Element.Border] = "Bordure", [Private.Enum.Element.InterruptSource] = "Nom de l'interrupteur", [Private.Enum.Element.ProgressBar] = "Barre de progression", [Private.Enum.Element.Background] = "Arrière-plan", [Private.Enum.Element.TargetMarker] = "Marqueur de cible", [Private.Enum.Element.DurationCooldown] = "Durée", [Private.Enum.Element.SpellName] = "Nom du sort", [Private.Enum.Element.TargetName] = "Nom de la cible", [Private.Enum.Element.InterruptShield] = "Bouclier d'interruption", [Private.Enum.Element.Duration] = "Durée" }
L.SlashCommands.Header = "Commandes de Targeted Spells :"
L.SlashCommands.OptionsDescription = "Ouvrir le panneau des paramètres"
L.SlashCommands.SettingsDescription = "Ouvrir le panneau des paramètres"
L.SlashCommands.DesignDescription = "Ouvrir le concepteur de mise en page"

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
L.Settings.GroupNameLabel = "Renommer le groupe"
L.Settings.GroupNamePrompt = "Saisissez un nom pour ce groupe :"
L.Settings.TemplateLabel = "Modèle"
L.Settings.TemplateTooltip = "Changer de modèle réinitialise la mise en page des éléments de ce groupe au modèle par défaut."
L.Settings.TemplateLabels = { [Private.Enum.Template.Icon] = "Icône", [Private.Enum.Template.Bar] = "Barre", [Private.Enum.Template.IconDuration] = "Icône + durée" }
L.Settings.FilterLabel = "Afficher les sorts ciblant"
L.Settings.FilterTooltip = "Les cibles des sorts que ce groupe affiche."
L.Settings.TargetClassLabels = { [Private.Enum.TargetClass.Player] = "vous", [Private.Enum.TargetClass.PartyMember] = "les membres du groupe", [Private.Enum.TargetClass.Nobody] = "personne (sans cible)" }
L.Settings.CreateGroup = "Créer un groupe"
L.Settings.DeleteGroup = "Supprimer le groupe"
L.Settings.DeleteGroupConfirm = "Supprimer ce groupe ? Cette action est irréversible."
L.Settings.CannotDeleteLastGroup = "Vous ne pouvez pas supprimer le dernier groupe restant."
