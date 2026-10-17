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
L.SlashCommands = {}
L.Designer = {}
L.Groups = {}

L.Designer.Title = "Targeted Spells - Concepteur de mise en page"
L.Designer.ElementPickerLabel = "Élément"
L.Designer.SelectHint = "Cliquez sur un élément dans l'aperçu ou sélectionnez-en un dans la liste des éléments."
L.Designer.ResetElement = "Réinitialiser l'élément"
L.Designer.CopyFrom = "Copier la mise en page depuis…"
L.Designer.CopyFromEmpty = "Aucun autre groupe de ce type"
L.Designer.Apply = SAVE_CHANGES
L.Designer.Revert = HUD_EDIT_MODE_REVERT_CHANGES
L.Designer.Discard = "Abandonner"
L.Designer.UnsavedHint = "Les modifications s'appliquent lors de l'enregistrement."
L.Designer.UnsavedPrompt = "Vous avez des modifications de mise en page non enregistrées."

L.Designer.SettingNames = {
	ELEMENT_ACTIVE = VIDEO_OPTIONS_ENABLED,
	ELEMENT_WIDTH = "Largeur",
	ELEMENT_HEIGHT = "Hauteur",
	ELEMENT_X = "Décalage X",
	ELEMENT_Y = "Décalage Y",
	ELEMENT_FONT_SIZE = FONT_SIZE,
	ELEMENT_FONT = "Police",
	ELEMENT_FONT_FLAGS = "Style de police",
	ELEMENT_TEXT_COLOR = "Couleur du texte",
	ELEMENT_JUSTIFY_H = "Alignement",
	ELEMENT_MAX_WIDTH = "Largeur maximale",
	ELEMENT_GAP = "Écart",
	ELEMENT_USE_CLASS_COLOR = "Utiliser la couleur de classe",
	ELEMENT_ICON_ZOOM = "Zoom de l'icône",
	ELEMENT_SHOW_SWIPE = "Afficher l'animation de balayage",
	ELEMENT_SHOW_COUNTDOWN = "Afficher la durée",
	ELEMENT_FRACTION_THRESHOLD = "Fraction sous (s)",
	ELEMENT_BORDER_TEXTURE = "Texture de bordure",
	ELEMENT_BORDER_COLOR = "Couleur de bordure",
	ELEMENT_BORDER_SIZE = "Taille de bordure",
	ELEMENT_BAR_TEXTURE = "Texture de barre",
	ELEMENT_BAR_COLOR_MODE = "Mode de couleur",
	ELEMENT_BAR_COLOR = "Couleur de barre",
	ELEMENT_INTERRUPTIBLE_COLOR = "Couleur interruptible",
	ELEMENT_UNINTERRUPTIBLE_COLOR = "Couleur non interruptible",
	ELEMENT_BACKGROUND_TEXTURE = "Texture d'arrière-plan",
	ELEMENT_BACKGROUND_COLOR = "Couleur d'arrière-plan",
}

L.Designer.Options = {
	JUSTIFY_LEFT = "Gauche",
	JUSTIFY_CENTER = "Centre",
	JUSTIFY_RIGHT = "Droite",
	BAR_COLOR_STATIC = "Statique",
	BAR_COLOR_INTERRUPTIBILITY = "Interruptibilité",
	BAR_COLOR_TARGET_CLASS = "Couleur de classe de la cible",
}

L.Designer.FontFlagNames = {
	[Private.Enum.FontFlags.OUTLINE] = "Contour",
	[Private.Enum.FontFlags.SHADOW] = "Ombre",
}
L.Designer.FontFlagsNone = "Aucun"

L.Designer.ElementNames = {
	[Private.Enum.Element.Icon] = UNIT_NAMEPLATES_CAST_BAR_DISPLAY_SPELL_ICON,
	[Private.Enum.Element.Overlay] = "Cadre du gestionnaire de temps de recharge",
	[Private.Enum.Element.Cooldown] = "Temps de recharge",
	[Private.Enum.Element.Border] = "Bordure",
	[Private.Enum.Element.InterruptSource] = "Nom de l'auteur de l'interruption",
	[Private.Enum.Element.ProgressBar] = "Barre de progression",
	[Private.Enum.Element.Background] = "Arrière-plan",
	[Private.Enum.Element.TargetMarker] = "Marqueur de cible",
	[Private.Enum.Element.DurationCooldown] = "Durée",
	[Private.Enum.Element.SpellName] = UNIT_NAMEPLATES_CAST_BAR_DISPLAY_SPELL_NAME,
	[Private.Enum.Element.TargetName] = UNIT_NAMEPLATES_CAST_BAR_DISPLAY_SPELL_TARGET,
	[Private.Enum.Element.InterruptShield] = "Bouclier d'interruption",
	[Private.Enum.Element.Duration] = "Durée",
}

L.SlashCommands.Header = "Commandes de Targeted Spells :"
L.SlashCommands.OptionsDescription = "Ouvrir le panneau des paramètres"
L.SlashCommands.SettingsDescription = "Ouvrir le panneau des paramètres"
L.SlashCommands.DesignDescription = "Ouvrir le concepteur de mise en page"

L.Settings.EditModeReminder = string.format(
	"Tous les paramètres sont accessibles via le %s et \"/targetedspells design\".",
	HUD_EDIT_MODE_MENU
)
L.EditMode.TargetedSpellsSelfLabel = "Targeted Spells - Joueur"
L.EditMode.TargetedSpellsPartyLabel = "Targeted Spells - Groupe"

L.Functionality.CVarWarning = string.format(
	"%s\n\nLe paramètre des barres d'info '%s' a été désactivé.\n\nSans lui, %s ne fonctionnera pas sur les ennemis hors de l'écran.\n\nCliquez sur '%s' pour le réactiver.",
	addonNameWithIcon,
	UNIT_NAMEPLATES_SHOW_OFFSCREEN,
	addonName,
	ENABLE
)

L.Functionality.V3MigrationWarning = string.format(
	"%s\n\nEn raison de mises à jour des restrictions de l'API, la fonctionnalité Groupe de Targeted Spells a dû être entièrement revue. Consultez le %s pour un aperçu.",
	addonNameWithIcon,
	HUD_EDIT_MODE_MENU
)

L.Settings.EnabledLabel = VIDEO_OPTIONS_ENABLED
L.Settings.DisabledLabel = VIDEO_OPTIONS_DISABLED

L.Settings.AddonCompartmentTooltipLine1 =
	string.format("%s est %s", WrapTextInColorCode(L.EditMode.TargetedSpellsSelfLabel, "ffeda55f"), "%s")
L.Settings.AddonCompartmentTooltipLine2 =
	string.format("%s est %s", WrapTextInColorCode(L.EditMode.TargetedSpellsPartyLabel, "ffeda55f"), "%s")

L.Settings.LoadConditionContentTypeLabel = "Condition de chargement : Type de contenu"
L.Settings.LoadConditionContentTypeTooltip = nil
L.Settings.LoadConditionContentTypeLabels = {
	[Private.Enum.ContentType.OpenWorld] = "Monde ouvert",
	[Private.Enum.ContentType.Delve] = "Gouffres",
	[Private.Enum.ContentType.Dungeon] = DUNGEONS,
	[Private.Enum.ContentType.Raid] = RAIDS,
	[Private.Enum.ContentType.Arena] = ARENA,
	[Private.Enum.ContentType.Battleground] = BATTLEGROUNDS,
}

L.Settings.LoadConditionRoleLabel = "Condition de chargement : Rôle"
L.Settings.LoadConditionRoleTooltip = nil
L.Settings.LoadConditionRoleLabels = {
	[Private.Enum.Role.Healer] = HEALER,
	[Private.Enum.Role.Tank] = TANK,
	[Private.Enum.Role.Damager] = DAMAGER,
}

L.Settings.FrameGapLabel = "Écart"
L.Settings.FrameGapTooltip = nil

L.Settings.FrameDirectionLabel = HUD_EDIT_MODE_SETTING_AURA_FRAME_ORIENTATION
L.Settings.FrameDirectionTooltip = nil
L.Settings.FrameDirectionHorizontal = HUD_EDIT_MODE_SETTING_AURA_FRAME_ORIENTATION_HORIZONTAL
L.Settings.FrameDirectionVertical = HUD_EDIT_MODE_SETTING_AURA_FRAME_ORIENTATION_VERTICAL

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

L.Settings.GlowImportantLabel = "Faire briller les sorts importants"

L.Settings.OnlyImportantLabel = "Afficher uniquement les sorts importants"

L.Settings.GlowTypeLabel = "Type de lueur"
L.Settings.GlowTypeTooltip = nil
L.Settings.GlowTypeLabels = {
	[Private.Enum.GlowType.PixelGlow] = "Pixel Glow",
	[Private.Enum.GlowType.AutoCastGlow] = "Auto Cast Glow",
	[Private.Enum.GlowType.ProcGlow] = "Proc Glow",
	[Private.Enum.GlowType.Star4] = "Star 4",
}

L.Settings.IndicateInterruptsLabel = "Indiquer les interruptions"

L.Settings.TextToSpeechVoiceLabel = "Voix TTS"
L.Settings.TextToSpeechVoiceTooltip =
	"Voix utilisée pour les annonces de synthèse vocale. Partagée entre tous les groupes."

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

L.Settings.ClickToOpenSettingsLabel = "Cliquer pour ouvrir les paramètres"

L.Settings.Import = HUD_EDIT_MODE_IMPORT_LAYOUT
L.Settings.Export = "Exporter"

L.Settings.FeatureFlagsLabel = "Fonctionnalités"
L.Settings.FeatureFlagsTooltip = nil

L.Settings.GroupNameLabel = "Renommer le groupe"
L.Settings.GroupNamePrompt = "Saisissez un nom pour ce groupe :"

L.Settings.TemplateLabel = "Modèle"
L.Settings.TemplateTooltip = "Changer de modèle réinitialise la mise en page des éléments de ce groupe au modèle par défaut."
L.Settings.TemplateLabels = {
	[Private.Enum.Template.Icon] = "Icône",
	[Private.Enum.Template.Bar] = "Barre",
	[Private.Enum.Template.IconDuration] = "Icône + durée",
}

L.Settings.FilterLabel = "Afficher les sorts ciblant"
L.Settings.FilterTooltip = "Les cibles des sorts que ce groupe affiche."
L.Settings.TargetClassLabels = {
	[Private.Enum.TargetClass.Player] = "vous",
	[Private.Enum.TargetClass.PartyMember] = "les membres du groupe",
	[Private.Enum.TargetClass.Nobody] = "personne (sans cible)",
}

L.Settings.CreateGroup = "Créer un groupe"
L.Settings.DeleteGroup = "Supprimer le groupe"
L.Settings.DeleteGroupConfirm = "Supprimer ce groupe ? Cette action est irréversible."
L.Settings.CannotDeleteLastGroup = "Vous ne pouvez pas supprimer le dernier groupe restant."

L.Groups.DefaultName = "Groupe %d"
L.Groups.StarterSelfName = "Joueur - Icône"
L.Groups.StarterUntargetedName = "AoE sans cible - Barre"
L.Groups.MigratedSelfName = "Joueur"
L.Groups.MigratedPartyName = "Groupe"
