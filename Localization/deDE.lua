---@type string, TargetedSpells
local addonName, Private = ...

local addonNameWithIcon = ""

do
	local icon = C_AddOns.GetAddOnMetadata(addonName, "IconTexture")
	-- width, height, offsetX, offsetY
	addonNameWithIcon = string.format("|T%s:%d:%d:%d:%d|t %s", icon, 20, 20, 0, -4, addonName)
end

local L = Private.L

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

L.Functionality.V2DeprecationWarning = string.format(
	"%s\n\nAufgrund der Änderungeon von v2 wurden die folgenden Einstellungen zurückgesetzt:\n\n%s\n\nZusätzlich raten wir die Positionierung zu überprüfen da es auch dort ggf. zu Anpassungen gekommen sein kann.",
	addonNameWithIcon,
	"%s"
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

L.Settings.RoleFilterLabel = "Rollenfilter"
L.Settings.RoleFilterTooltip =
	"Erlaubt Zauber die auf bestimmte Rollen zielen nicht anzuzeigen. Nutzung auf eigene Gefahr."
L.Settings.RoleFilterLabels = L.Settings.LoadConditionRoleLabels

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
L.Settings.GlowImportantTooltip =
	"Was wichtig und was nicht wichtig ist wird ausschließlich vom Spiel selbst kommuniziert."

L.Settings.OnlyImportantLabel = "Nur wichtige Zauber anzeigen"
L.Settings.OnlyImportantTooltip = "Beachte dass nur das Spiel festlegen kann was wichtig ist - mit Vorsicht genießen."

L.Settings.GlowTypeLabel = "Hervorhebungsanimation"
L.Settings.GlowTypeTooltip = nil
L.Settings.GlowTypeLabels = {
	[Private.Enum.GlowType.PixelGlow] = "Pixel Glow",
	[Private.Enum.GlowType.AutoCastGlow] = "Auto Cast Glow",
	[Private.Enum.GlowType.ProcGlow] = "Proc Glow",
	[Private.Enum.GlowType.Star4] = "Star 4",
}

L.Settings.ShowDurationLabel = "Dauer anzeigen"
L.Settings.ShowDurationTooltip = nil

L.Settings.ShowDurationFractionsLabel = "Sekundenbruchteile anzeigen"
L.Settings.ShowDurationFractionsTooltip = nil

L.Settings.IndicateInterruptsLabel = "Unterbrechungen anzeigen"
L.Settings.IndicateInterruptsTooltip =
	"Desaturiert das Icon, zeigt einen Indikator an und verzögert das Ausblenden des Icons um eine Sekunde. Funktioniert nicht bei kanalisierten Zaubern."

L.Settings.RenderInterruptSourceNameLabel = "Unterbrechungsquellnamen anzeigen"
L.Settings.RenderInterruptSourceNameTooltip = nil

L.Settings.ShowSwipeLabel = "Abklingzeitsanimation anzeigen"
L.Settings.ShowSwipeTooltip = nil

L.Settings.BorderStyleLabel = "Border Style"
L.Settings.BorderStyleTooltip = nil
L.Settings.BorderStyleSolid = "Solid"

L.Settings.OpacityLabel = "Deckkraft"
L.Settings.OpacityTooltip = nil

L.Settings.IconZoomLabel = "Icon Zoom"
L.Settings.IconZoomTooltip = nil

L.Settings.FrameOffsetXLabel = "Versatz X-Achse"
L.Settings.FrameOffsetXTooltip = nil

L.Settings.FrameOffsetYLabel = "Versatz Y-Achse"
L.Settings.FrameOffsetYTooltip = nil

L.Settings.FrameSourceAnchorLabel = "Ursprungsanker"
L.Settings.FrameSourceAnchorTooltip = nil

L.Settings.FrameTargetAnchorLabel = "Zielanker"
L.Settings.FrameTargetAnchorTooltip = nil

L.Settings.IncludeSelfInPartyLabel = "Spieler auch in Gruppe anzeigen"
L.Settings.IncludeSelfInPartyTooltip =
	"Funktioniert nur wenn Gruppen im selben Stil wie Schlachtzüge angezeigt werden."

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
	[Private.Enum.FeatureFlag.ShowDurationFractions] = L.Settings.ShowDurationFractionsLabel,
	[Private.Enum.FeatureFlag.ShowSwipe] = L.Settings.ShowSwipeLabel,
	[Private.Enum.FeatureFlag.IndicateInterrupts] = L.Settings.IndicateInterruptsLabel,
	[Private.Enum.FeatureFlag.RenderInterruptSourceName] = L.Settings.RenderInterruptSourceNameLabel,
	[Private.Enum.FeatureFlag.IncludeSelfInParty] = L.Settings.IncludeSelfInPartyLabel,
}

L.Settings.FeatureFlagSettingTitles = {
	[Private.Enum.FeatureFlag.GlowImportant] = "Anzeige",
	[Private.Enum.FeatureFlag.IndicateInterrupts] = "Unterbrechungseinstellungen",
	[Private.Enum.FeatureFlag.IncludeSelfInParty] = "Gruppeneinstellungen",
}
