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

L.Designer.Title = "Targeted Spells - Layout-Designer"
L.Designer.ElementPickerLabel = "Element"
L.Designer.SelectHint = "Klicke ein Element in der Vorschau an oder wähle eines aus dem Element-Dropdown aus."
L.Designer.ResetElement = "Element zurücksetzen"
L.Designer.CopyFrom = "Layout kopieren von…"
L.Designer.CopyFromEmpty = "Keine anderen Gruppen dieses Typs"
L.Designer.Apply = "Änderungen speichern"
L.Designer.Revert = "Zurücksetzen"
L.Designer.Discard = "Verwerfen"
L.Designer.UnsavedHint = "Änderungen werden beim Speichern angewendet."
L.Designer.UnsavedPrompt = "Du hast ungespeicherte Layoutänderungen."
L.Designer.SettingNames = {
	ELEMENT_ACTIVE = "Aktiviert",
	ELEMENT_WIDTH = "Breite",
	ELEMENT_HEIGHT = "Höhe",
	ELEMENT_X = "X-Versatz",
	ELEMENT_Y = "Y-Versatz",
	ELEMENT_FONT_SIZE = "Schriftgröße",
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
	[Private.Enum.Element.Icon] = "Symbol",
	[Private.Enum.Element.Overlay] = "Cooldown-Manager-Rahmen",
	[Private.Enum.Element.Cooldown] = "Abklingzeit",
	[Private.Enum.Element.Border] = "Rahmen",
	[Private.Enum.Element.InterruptSource] = "Unterbrechername",
	[Private.Enum.Element.ProgressBar] = "Fortschrittsbalken",
	[Private.Enum.Element.Background] = "Hintergrund",
	[Private.Enum.Element.TargetMarker] = "Zielmarkierung",
	[Private.Enum.Element.DurationCooldown] = "Dauer",
	[Private.Enum.Element.SpellName] = "Zaubername",
	[Private.Enum.Element.TargetName] = "Zielname",
	[Private.Enum.Element.InterruptShield] = "Unterbrechungsschild",
	[Private.Enum.Element.Duration] = "Dauer",
}

L.SlashCommands.Header = "Targeted-Spells-Befehle:"
L.SlashCommands.OptionsDescription = "Einstellungsfenster öffnen"
L.SlashCommands.SettingsDescription = "Einstellungsfenster öffnen"
L.SlashCommands.DesignDescription = "Layout-Designer öffnen"

L.Settings.EditModeReminder =
"Alle Einstellungen sind über den Bearbeitungsmodus und \"/targetedspells design\" erreichbar."
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
	"%s\n\nAufgrund von API-Einschränkungen musste die Gruppen-Funktionalität von Targeted Spells vollständig überarbeitet werden. Bitte den Bearbeitungsmodus für eine Vorschau aufrufen.",
	addonNameWithIcon
)

L.Settings.EnabledLabel = "Aktiviert"
L.Settings.DisabledLabel = "Deaktiviert"

L.Settings.AddonCompartmentTooltipLine1 =
	string.format("%s ist %s", WrapTextInColorCode(L.EditMode.TargetedSpellsSelfLabel, "ffeda55f"), "%s")
L.Settings.AddonCompartmentTooltipLine2 =
	string.format("%s ist %s", WrapTextInColorCode(L.EditMode.TargetedSpellsPartyLabel, "ffeda55f"), "%s")

L.Settings.LoadConditionContentTypeLabel = "Ladebedingung: Spielbereich"
L.Settings.LoadConditionContentTypeTooltip = nil
L.Settings.LoadConditionContentTypeLabels = {
	[Private.Enum.ContentType.OpenWorld] = "Offene Welt",
	[Private.Enum.ContentType.Delve] = "Tiefen",
	[Private.Enum.ContentType.Dungeon] = "Instanz",
	[Private.Enum.ContentType.Raid] = "Schlachtzug",
	[Private.Enum.ContentType.Arena] = "Arena",
	[Private.Enum.ContentType.Battleground] = "Schlachtfeld",
}

L.Settings.LoadConditionRoleLabel = "Ladebedingung: Rolle"
L.Settings.LoadConditionRoleTooltip = nil

L.Settings.LoadConditionRoleLabels = {
	[Private.Enum.Role.Healer] = "Heiler",
	[Private.Enum.Role.Tank] = "Panzer",
	[Private.Enum.Role.Damager] = "Schadensverursacher",
}

L.Settings.FrameGapLabel = "Abstand"
L.Settings.FrameGapTooltip = nil

L.Settings.FrameDirectionLabel = "Richtung"
L.Settings.FrameDirectionTooltip = nil
L.Settings.FrameDirectionHorizontal = "Horizontal"
L.Settings.FrameDirectionVertical = "Vertikal"

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
L.Settings.TextToSpeechVoiceTooltip =
"Stimme für Text-zu-Sprache-Ansagen. Gilt für Selbst- und Gruppen-Einstellungen."

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

L.Settings.UseTargetClassColorLabel = "Zielklassenfarbe verwenden"
L.Settings.UseTargetClassColorTooltip =
"Färbt den Balken in der Klassenfarbe der Zieleinheit mit 75 % Transparenz. Zauber ohne Ziel verwenden eine aufgehellte Hintergrundbalken-Farbe."

L.Settings.ClickToOpenSettingsLabel = "Klicken um Einstellungen zu öffnen"

L.Settings.Import = "Importieren"
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

