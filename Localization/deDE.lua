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

L.Designer.Title = "Targeted Spells - Layout-Designer"
L.Designer.ElementPickerLabel = "Element"
L.Designer.SelectHint = "Klicke ein Element in der Vorschau an oder wähle eines aus dem Element-Dropdown aus."
L.Designer.ResetElement = "Element zurücksetzen"
L.Designer.CopyFrom = "Layout kopieren von…"
L.Designer.CopyFromEmpty = "Keine anderen Gruppen dieses Typs"
L.Designer.Apply = SAVE_CHANGES
L.Designer.Revert = HUD_EDIT_MODE_REVERT_CHANGES
L.Designer.Discard = "Verwerfen"
L.Designer.UnsavedHint = "Änderungen werden beim Speichern angewendet."
L.Designer.UnsavedPrompt = "Du hast ungespeicherte Layoutänderungen."

L.Designer.SettingNames = {
	ELEMENT_ACTIVE = VIDEO_OPTIONS_ENABLED,
	ELEMENT_WIDTH = "Breite",
	ELEMENT_HEIGHT = "Höhe",
	ELEMENT_X = "X-Versatz",
	ELEMENT_Y = "Y-Versatz",
	ELEMENT_FONT_SIZE = FONT_SIZE,
	ELEMENT_FONT = "Schriftart",
	ELEMENT_FONT_FLAGS = "Schriftstil",
	ELEMENT_TEXT_COLOR = "Textfarbe",
	ELEMENT_JUSTIFY_H = "Ausrichtung",
	ELEMENT_MAX_WIDTH = "Maximale Breite",
	ELEMENT_GAP = "Abstand",
	ELEMENT_USE_CLASS_COLOR = "Klassenfarbe verwenden",
	ELEMENT_ICON_ZOOM = "Symbolzoom",
	ELEMENT_SHOW_SWIPE = "Wischanimation anzeigen",
	ELEMENT_SHOW_COUNTDOWN = "Dauer anzeigen",
	ELEMENT_FRACTION_THRESHOLD = "Bruchwert unter (s)",
	ELEMENT_BORDER_TEXTURE = "Rahmentextur",
	ELEMENT_BORDER_COLOR = "Rahmenfarbe",
	ELEMENT_BORDER_SIZE = "Rahmenbreite",
	ELEMENT_BAR_TEXTURE = "Balkentextur",
	ELEMENT_BAR_COLOR_MODE = "Farbmodus",
	ELEMENT_BAR_COLOR = "Balkenfarbe",
	ELEMENT_INTERRUPTIBLE_COLOR = "Unterbrechbare Farbe",
	ELEMENT_UNINTERRUPTIBLE_COLOR = "Nicht unterbrechbare Farbe",
	ELEMENT_BACKGROUND_TEXTURE = "Hintergrundtextur",
	ELEMENT_BACKGROUND_COLOR = "Hintergrundfarbe",
}

L.Designer.Options = {
	JUSTIFY_LEFT = "Links",
	JUSTIFY_CENTER = "Mittig",
	JUSTIFY_RIGHT = "Rechts",
	BAR_COLOR_STATIC = "Statisch",
	BAR_COLOR_INTERRUPTIBILITY = "Unterbrechbarkeit",
	BAR_COLOR_TARGET_CLASS = "Zielklassenfarbe",
}

L.Designer.FontFlagNames = {
	[Private.Enum.FontFlags.OUTLINE] = "Kontur",
	[Private.Enum.FontFlags.SHADOW] = "Schatten",
}
L.Designer.FontFlagsNone = "Keine"

L.Designer.ElementNames = {
	[Private.Enum.Element.Icon] = UNIT_NAMEPLATES_CAST_BAR_DISPLAY_SPELL_ICON,
	[Private.Enum.Element.Overlay] = "Abklingzeitmanager-Rahmen",
	[Private.Enum.Element.Cooldown] = "Abklingzeit",
	[Private.Enum.Element.Border] = "Rahmen",
	[Private.Enum.Element.InterruptSource] = "Unterbrechername",
	[Private.Enum.Element.ProgressBar] = "Fortschrittsbalken",
	[Private.Enum.Element.Background] = "Hintergrund",
	[Private.Enum.Element.TargetMarker] = "Zielmarkierung",
	[Private.Enum.Element.DurationCooldown] = "Dauer",
	[Private.Enum.Element.SpellName] = UNIT_NAMEPLATES_CAST_BAR_DISPLAY_SPELL_NAME,
	[Private.Enum.Element.TargetName] = UNIT_NAMEPLATES_CAST_BAR_DISPLAY_SPELL_TARGET,
	[Private.Enum.Element.InterruptShield] = "Unterbrechungsschild",
	[Private.Enum.Element.Duration] = "Dauer",
}

L.SlashCommands.Header = "Targeted-Spells-Befehle:"
L.SlashCommands.OptionsDescription = "Einstellungsfenster öffnen"
L.SlashCommands.SettingsDescription = "Einstellungsfenster öffnen"
L.SlashCommands.DesignDescription = "Layout-Designer öffnen"

L.Settings.EditModeReminder = string.format(
	"Alle Einstellungen sind über den %s und \"/targetedspells design\" erreichbar.",
	HUD_EDIT_MODE_MENU
)
L.EditMode.TargetedSpellsSelfLabel = "Targeted Spells - Spieler"
L.EditMode.TargetedSpellsPartyLabel = "Targeted Spells - Gruppe"

L.Functionality.CVarWarning = string.format(
	"%s\n\nDie Namensplaketteneinstellung '%s' wurde deaktiviert.\n\nOhne funktioniert %s nicht bei Gegnern die außerhalb des Bildschirms anfangen zu wirken.\n\nKlicke '%s' um die Einstellung wieder zu aktivieren.",
	addonNameWithIcon,
	UNIT_NAMEPLATES_SHOW_OFFSCREEN,
	addonName,
	ENABLE
)

L.Functionality.V3MigrationWarning = string.format(
	"%s\n\nAufgrund von API-Einschränkungen musste die Gruppen-Funktionalität von Targeted Spells vollständig überarbeitet werden. Bitte den %s für eine Vorschau aufrufen.",
	addonNameWithIcon,
	HUD_EDIT_MODE_MENU
)

L.Settings.EnabledLabel = VIDEO_OPTIONS_ENABLED
L.Settings.DisabledLabel = VIDEO_OPTIONS_DISABLED

L.Settings.AddonCompartmentTooltipLine1 =
	string.format("%s ist %s", WrapTextInColorCode(L.EditMode.TargetedSpellsSelfLabel, "ffeda55f"), "%s")
L.Settings.AddonCompartmentTooltipLine2 =
	string.format("%s ist %s", WrapTextInColorCode(L.EditMode.TargetedSpellsPartyLabel, "ffeda55f"), "%s")

L.Settings.LoadConditionContentTypeLabel = "Ladebedingung: Spielbereich"
L.Settings.LoadConditionContentTypeTooltip = nil
L.Settings.LoadConditionContentTypeLabels = {
	[Private.Enum.ContentType.OpenWorld] = "Offene Welt",
	[Private.Enum.ContentType.Delve] = "Tiefen",
	[Private.Enum.ContentType.Dungeon] = DUNGEONS,
	[Private.Enum.ContentType.Raid] = RAIDS,
	[Private.Enum.ContentType.Arena] = ARENA,
	[Private.Enum.ContentType.Battleground] = BATTLEGROUNDS,
}

L.Settings.LoadConditionRoleLabel = "Ladebedingung: Rolle"
L.Settings.LoadConditionRoleTooltip = nil
L.Settings.LoadConditionRoleLabels = {
	[Private.Enum.Role.Healer] = HEALER,
	[Private.Enum.Role.Tank] = TANK,
	[Private.Enum.Role.Damager] = DAMAGER,
}

L.Settings.FrameGapLabel = "Abstand"
L.Settings.FrameGapTooltip = nil

L.Settings.FrameDirectionLabel = HUD_EDIT_MODE_SETTING_AURA_FRAME_ORIENTATION
L.Settings.FrameDirectionTooltip = nil
L.Settings.FrameDirectionHorizontal = HUD_EDIT_MODE_SETTING_AURA_FRAME_ORIENTATION_HORIZONTAL
L.Settings.FrameDirectionVertical = HUD_EDIT_MODE_SETTING_AURA_FRAME_ORIENTATION_VERTICAL

L.Settings.FrameSortOrderLabel = "Sortierung"
L.Settings.FrameSortOrderTooltip = nil
L.Settings.FrameSortOrderAscending = "Aufsteigend"
L.Settings.FrameSortOrderDescending = "Absteigend"

L.Settings.FrameGrowLabel = "Wachstumsrichtung"
L.Settings.FrameGrowTooltip = nil
L.Settings.FrameGrowLabels = {
	[Private.Enum.Grow.Start] = "Anfang",
	[Private.Enum.Grow.End] = "Ende",
}

L.Settings.GlowImportantLabel = "Wichtige Zauber hervorheben"

L.Settings.OnlyImportantLabel = "Nur wichtige Zauber anzeigen"

L.Settings.GlowTypeLabel = "Hervorhebungsanimation"
L.Settings.GlowTypeTooltip = nil
L.Settings.GlowTypeLabels = {
	[Private.Enum.GlowType.PixelGlow] = "Pixel Glow",
	[Private.Enum.GlowType.AutoCastGlow] = "Auto Cast Glow",
	[Private.Enum.GlowType.ProcGlow] = "Proc Glow",
	[Private.Enum.GlowType.Star4] = "Star 4",
}

L.Settings.IndicateInterruptsLabel = "Unterbrechungen anzeigen"

L.Settings.TextToSpeechVoiceLabel = "TTS-Stimme"
L.Settings.TextToSpeechVoiceTooltip = "Stimme für Text-zu-Sprache-Ansagen. Gilt für alle Gruppen."

L.Settings.AnnounceUntargetedSpellsLabel = "Ungezielte TTS-Einstellungen"
L.Settings.AnnounceUntargetedSpellsTooltip = "Text-zu-Sprache für ungezielte Zauber (AoE, Frontals usw.) nach NPC-Typ."

L.Settings.AnnounceTargetedSpellsLabel = "Gezielte TTS-Einstellungen"
L.Settings.AnnounceTargetedSpellsTooltip =
	"Text-zu-Sprache für Zauber, die einen bestimmten Spieler anvisieren, nach NPC-Typ."

L.Settings.NpcTypeLabels = {
	[Private.Enum.NpcType.Boss] = "Bosse",
	[Private.Enum.NpcType.Lieutenant] = "Leutnants",
	[Private.Enum.NpcType.Other] = "Alle Weiteren",
	[Private.Enum.NpcType.Minion] = "Schergen",
}

L.Settings.ClickToOpenSettingsLabel = "Klicken um Einstellungen zu öffnen"

L.Settings.Import = HUD_EDIT_MODE_IMPORT_LAYOUT
L.Settings.Export = "Exportieren"

L.Settings.FeatureFlagsLabel = "Features"
L.Settings.FeatureFlagsTooltip = nil

L.Settings.GroupNameLabel = "Gruppe umbenennen"
L.Settings.GroupNamePrompt = "Gib einen Namen für diese Gruppe ein:"

L.Settings.TemplateLabel = "Vorlage"
L.Settings.TemplateTooltip = "Der Wechsel der Vorlage setzt das Element-Layout dieser Gruppe auf die Standardvorlage zurück."
L.Settings.TemplateLabels = {
	[Private.Enum.Template.Icon] = "Symbol",
	[Private.Enum.Template.Bar] = "Balken",
	[Private.Enum.Template.IconDuration] = "Symbol + Dauer",
}

L.Settings.FilterLabel = "Zauber anzeigen, die auf"
L.Settings.FilterTooltip = "Welche Ziele dieser Gruppe angezeigte Zauber haben."
L.Settings.TargetClassLabels = {
	[Private.Enum.TargetClass.Player] = "dich",
	[Private.Enum.TargetClass.PartyMember] = "Gruppenmitglieder",
	[Private.Enum.TargetClass.Nobody] = "niemanden (ohne Ziel)",
}

L.Settings.CreateGroup = "Gruppe erstellen"
L.Settings.DeleteGroup = "Gruppe löschen"
L.Settings.DeleteGroupConfirm = "Diese Gruppe löschen? Dies kann nicht rückgängig gemacht werden."
L.Settings.CannotDeleteLastGroup = "Die letzte verbleibende Gruppe kann nicht gelöscht werden."

L.Groups.DefaultName = "Gruppe %d"
L.Groups.StarterSelfName = "Spieler - Symbol"
L.Groups.StarterUntargetedName = "Ungezielte AoE - Balken"
L.Groups.MigratedSelfName = "Spieler"
L.Groups.MigratedPartyName = "Gruppe"
