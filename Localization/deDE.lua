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
	"Der Bearbeitungsmodus beinhaltet eine Echtzeitvorschau aller Einstellungen.\nDiese Einstellungen sind hier nur damit man sie auch im Kampf bearbeiten kann."
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
L.Settings.EnabledTooltip = nil
L.Settings.DisabledLabel = "Deaktiviert"

L.Settings.AddonCompartmentTooltipLine1 =
	string.format("%s ist %s", WrapTextInColorCode(L.EditMode.TargetedSpellsSelfLabel, "ffeda55f"), "%s")
L.Settings.AddonCompartmentTooltipLine2 =
	string.format("%s ist %s", WrapTextInColorCode(L.EditMode.TargetedSpellsPartyLabel, "ffeda55f"), "%s")

L.Settings.LoadConditionContentTypeLabel = "Ladebedingung: Spielbereich"
L.Settings.LoadConditionContentTypeLabelAbbreviated = "In Spielbereich laden"
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
L.Settings.LoadConditionRoleLabelAbbreviated = "In Rolle laden"
L.Settings.LoadConditionRoleTooltip = nil

L.Settings.LoadConditionRoleLabels = {
	[Private.Enum.Role.Healer] = "Heiler",
	[Private.Enum.Role.Tank] = "Panzer",
	[Private.Enum.Role.Damager] = "Schadensverursacher",
}

L.Settings.FrameWidthLabel = "Breite"
L.Settings.FrameWidthTooltip = nil

L.Settings.FrameHeightLabel = "Höhe"
L.Settings.FrameHeightTooltip = nil

L.Settings.FontSizeLabel = "Schriftgröße"
L.Settings.FontSizeTooltip = nil

L.Settings.FontFlagsLabel = "Schriftoptionen"
L.Settings.FontFlagsTooltip = nil
L.Settings.FontFlagsLabels = {
	[Private.Enum.FontFlags.OUTLINE] = "Umriss",
	[Private.Enum.FontFlags.SHADOW] = "Schatten",
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

L.Settings.ShowDurationLabel = "Dauer anzeigen"

L.Settings.IndicateInterruptsLabel = "Unterbrechungen anzeigen"

L.Settings.RenderInterruptSourceNameLabel = "Unterbrechungsquellnamen anzeigen"

L.Settings.ShowSwipeLabel = "Abklingzeitsanimation anzeigen"

L.Settings.BorderStyleLabel = "Border Style"
L.Settings.BorderStyleTooltip = nil

L.Settings.ForegroundBarTextureLabel = "Fortschrittsbalken-Textur"
L.Settings.ForegroundBarTextureTooltip = nil

L.Settings.BackgroundBarTextureLabel = "Hintergrundbalken-Textur"
L.Settings.BackgroundBarTextureTooltip = nil

L.Settings.BackgroundBarColorLabel = "Hintergrundbalken-Farbe"
L.Settings.BackgroundBarColorTooltip =
	"Deckkraft ist nur im Bearbeitungsmodus verfügbar, da die standardmäßige Einstellungsoberfläche sie nicht anzeigt."

L.Settings.ProgressBarColorLabel = "Statusbalkenfarbe"
L.Settings.ProgressBarColorTooltip =
	"Deckkraft ist nur im Bearbeitungsmodus verfügbar, da die standardmäßige Einstellungsoberfläche sie nicht anzeigt."

L.Settings.MirrorLayoutLabel = "Layout spiegeln"

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
	[Private.Enum.NpcType.Caster] = "Hat Mana",
	[Private.Enum.NpcType.Melee] = "Normale Gegner",
	[Private.Enum.NpcType.Minion] = "Schergen",
}

L.Settings.HideUntargetedSpellsLabel = "Zauber ohne Ziel ausblenden"

L.Settings.HideTargetedSpellsLabel = "Zauber mit Ziel ausblenden"

L.Settings.SelfOnlyLabel = "Nur Zauber anzeigen, die auf den Spieler zielen"

L.Settings.InlineDurationLabel = "Dauer inline anzeigen"

L.Settings.UseInterruptabilityColorsLabel = "Farbkodierung für Unterbrechungsstatus nutzen"
L.Settings.UseInterruptabilityColorsTooltip = nil

L.Settings.UseTargetClassColorLabel = "Zielklassenfarbe verwenden"
L.Settings.UseTargetClassColorTooltip =
	"Färbt den Balken in der Klassenfarbe der Zieleinheit mit 75 % Transparenz. Zauber ohne Ziel verwenden eine aufgehellte Hintergrundbalken-Farbe."

L.Settings.UninterruptibleColorLabel = "Farbe Ununterbrechbar"
L.Settings.UninterruptibleColorTooltip = nil

L.Settings.InterruptibleColorLabel = "Farbe Unterbrechbar"
L.Settings.InterruptibleColorTooltip = nil

L.Settings.IconZoomLabel = "Icon Zoom"
L.Settings.IconZoomTooltip = nil

L.Settings.ClickToOpenSettingsLabel = "Klicken um Einstellungen zu öffnen"

L.Settings.Import = "Importieren"
L.Settings.Export = "Exportieren"

L.Settings.FontLabel = "Schriftart"
L.Settings.FontTooltip = nil

L.Settings.FeatureFlagsLabel = "Features"
L.Settings.FeatureFlagsTooltip = nil

L.Settings.FeatureFlagLabels = {
	[Private.Enum.FeatureFlag.GlowImportant] = L.Settings.GlowImportantLabel,
	[Private.Enum.FeatureFlag.OnlyImportant] = L.Settings.OnlyImportantLabel,
	[Private.Enum.FeatureFlag.ShowDuration] = L.Settings.ShowDurationLabel,
	[Private.Enum.FeatureFlag.ShowSwipe] = L.Settings.ShowSwipeLabel,
	[Private.Enum.FeatureFlag.IndicateInterrupts] = L.Settings.IndicateInterruptsLabel,
	[Private.Enum.FeatureFlag.RenderInterruptSourceName] = L.Settings.RenderInterruptSourceNameLabel,
	[Private.Enum.FeatureFlag.ShowIcon] = "Symbol anzeigen",
	[Private.Enum.FeatureFlag.ShowTargetMarker] = "Zielmarkierung anzeigen",
	[Private.Enum.FeatureFlag.ShowSpellName] = "Zaubernamen anzeigen",
	[Private.Enum.FeatureFlag.ShowTargetName] = "Zielnamen anzeigen",
	[Private.Enum.FeatureFlag.ShowTargetClassColor] = "Zielklassenfarbe anzeigen",
	[Private.Enum.FeatureFlag.MirrorLayout] = L.Settings.MirrorLayoutLabel,
	[Private.Enum.FeatureFlag.InlineDuration] = L.Settings.InlineDurationLabel,
	[Private.Enum.FeatureFlag.HideUntargetedSpells] = L.Settings.HideUntargetedSpellsLabel,
	[Private.Enum.FeatureFlag.HideTargetedSpells] = L.Settings.HideTargetedSpellsLabel,
	[Private.Enum.FeatureFlag.SelfOnly] = L.Settings.SelfOnlyLabel,
}

L.Settings.FeatureFlagSettingTitles = {
	[Private.Enum.FeatureFlag.GlowImportant] = "Anzeige",
	[Private.Enum.FeatureFlag.IndicateInterrupts] = "Unterbrechungseinstellungen",
}
