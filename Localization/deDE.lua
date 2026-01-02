---@type string, TargetedSpells
local addonName, Private = ...

local addonNameWithIcon = ""

do
	local icon = C_AddOns.GetAddOnMetadata(addonName, "IconTexture")
	-- width, height, offsetX, offsetY
	addonNameWithIcon = string.format("|T%s:%d:%d:%d:%d|t %s", icon, 20, 20, 0, -4, addonName)
end

local L = Private.L

L.EditMode.TargetedSpellsSelfLabel = "Targeted Spells - Spieler"
L.EditMode.TargetedSpellsPartyLabel = "Targeted Spells - Gruppe"

L.Functionality.CVarWarning = Private.IsMidnight
		and string.format(
			"%s\n\nDie Namensplaketteneinstellung '%s' wurde deaktiviert.\n\nOhne funktioniert %s nicht bei Gegnern die außerhalb des Bildschirms anfangen zu wirken.\n\nKlicke '%s' um die Einstellung wieder zu aktivieren.",
			addonNameWithIcon,
			UNIT_NAMEPLATES_SHOW_OFFSCREEN,
			addonName,
			ENABLE
		)
	or nil

L.Functionality.CAAEnabledWarning = Private.IsMidnight
		and string.format(
			"%s\n\nDieses AddOn hat automatisch die Einstellungen für '%s' aktiviert und konfiguriert da sie für Ton und Text-zur-Sprache benötigt werden.\n\nDu kannst sie an folgender Stelle finden: %s -> %s -> links %s > %s.\n\nAlternativ, gib folgendes in den Chat ein: /run Settings.OpenToCategory(18)",
			addonNameWithIcon,
			CAA_COMBAT_AUDIO_ALERTS_LABEL,
			KEY_ESCAPE,
			OPTIONS_MENU,
			ACCESSIBILITY_LABEL,
			ACCESSIBILITY_AUDIO_LABEL
		)
	or nil

-- L.Functionality.CAADisabledWarning = Private.IsMidnight
-- 		and string.format(
-- 			"%s This addon automatically disabled '%s' as you're no longer using neither Sound nor TTS.",
-- 			addonNameWithIcon,
-- 			CAA_COMBAT_AUDIO_ALERTS_LABEL
-- 		)
-- 	or nil
L.Functionality.CAAManuallyDisabledWarning = Private.IsMidnight
		and string.format(
			"%s\n\nDu hast '%s' deaktiviert, aber dieses AddOn benötigt es für die tonbezogenen Funktionen.\n\nBitte schalte die Einstellung durch einen Klick auf %s wieder ein oder passe deine Toneinstellungen für %s an.",
			addonNameWithIcon,
			CAA_COMBAT_AUDIO_ALERTS_LABEL,
			ENABLE,
			L.EditMode.TargetedSpellsSelfLabel
		)
	or nil
L.Functionality.CAASayIfTargetedDisabledWarning = Private.IsMidnight
		and string.format(
			"%s\nDu hast '%s' deaktiviert, aber dieses AddOn benötigt es für die tonbezogenen Funktionen.\n\nBitte schalte die Einstellung durch einen Klick auf %s wieder ein oder passe deine Toneinstellungen für %s an.",
			addonNameWithIcon,
			CAA_SAY_IF_TARGETED_LABEL,
			ENABLE,
			L.EditMode.TargetedSpellsSelfLabel
		)
	or nil

L.Settings.EnabledLabel = "Aktiviert"
L.Settings.EnabledTooltip = nil
L.Settings.DisabledLabel = "Deaktiviert"

L.Settings.AddonCompartmentTooltipLine1 =
	string.format("%s ist %s", WrapTextInColorCode(L.EditMode.TargetedSpellsSelfLabel, "ffeda55f"), "%s")
L.Settings.AddonCompartmentTooltipLine2 =
	string.format("%s ist %s", WrapTextInColorCode(L.EditMode.TargetedSpellsPartyLabel, "ffeda55f"), "%s")

L.Settings.LoadConditionContentTypeLabel = "Ladebedingung: Spielbereich"
L.Settings.LoadConditionContentTypeLabelAbbreviated = "In Spielbereich laden"
L.Settings.LoadConditionContentTypeTooltip = not Private.IsMidnight
		and "Diese Einstellung ist bis zum Midnight Pre-Patch nur via Bearbeitungsmodus konfigurierbar."
	or nil
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
L.Settings.LoadConditionRoleTooltip = not Private.IsMidnight
		and "Diese Einstellung ist bis zum Midnight Pre-Patch nur via Bearbeitungsmodus konfigurierbar."
	or nil

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
	[Private.Enum.Grow.Center] = "Zentriert",
	[Private.Enum.Grow.Start] = "Anfang",
	[Private.Enum.Grow.End] = "Ende",
}

L.Settings.GlowImportantLabel = "Wichtige Zauber hervorheben"
L.Settings.GlowImportantTooltip =
	"Was wichtig und was nicht wichtig ist wird ausschließlich vom Spiel selbst kommuniziert."

L.Settings.GlowTypeLabel = "Hervorhebungsanimation"
L.Settings.GlowTypeTooltip = nil
L.Settings.GlowTypeLabels = {
	[Private.Enum.GlowType.PixelGlow] = "Pixel Glow",
	[Private.Enum.GlowType.AutoCastGlow] = "Auto Cast Glow",
	[Private.Enum.GlowType.ButtonGlow] = "Button Glow",
	[Private.Enum.GlowType.ProcGlow] = "Proc Glow",
	[Private.Enum.GlowType.Star4] = "Star 4",
}

L.Settings.PlaySoundLabel = "Ton abspielen"
L.Settings.PlaySoundTooltip =
	"Spielt den ausgewählten Ton ab wenn euch ein Zauber anvisiert. DEAKTIVIERT TEXT-ZU-SPRACHE!"
L.Settings.SoundTooltip = "Klicken für Vorschau und ändern. Warnung: nutzt Master Tonkanal!"

L.Settings.PlayTTSLabel = "Text-zu-Sprache abspielen"
L.Settings.PlayTTSTooltip =
	"Spricht den Zaubernamen via Text-zu-Sprache wenn euch ein Zauber anvisiert. DEAKTIVIERT TONEINSTELLUNG!"

L.Settings.SoundLabel = "Ton"
L.Settings.SoundCategoryCustom = "Extra"
L.Settings.SoundTooltip =
	"Klicken um zu ändern - spielt Ton als Vorschau ab. Achtung: Master Tonkanallautstärke wird genutzt!"

L.Settings.SoundChannelLabel = "Tonkanal"
L.Settings.SoundChannelTooltip = nil
L.Settings.SoundChannelLabels = {
	[Private.Enum.SoundChannel.Master] = MASTER_VOLUME,
	[Private.Enum.SoundChannel.Music] = MUSIC_VOLUME,
	[Private.Enum.SoundChannel.SFX] = FX_VOLUME,
	[Private.Enum.SoundChannel.Ambience] = AMBIENCE_VOLUME,
	[Private.Enum.SoundChannel.Dialog] = DIALOG_VOLUME,
}

L.Settings.LoadConditionSoundContentTypeLabel = "Ladebedinging: Ton"
L.Settings.LoadConditionSoundContentTypeLabelAbbreviated = "Ton in Spielbereich abspielen"
L.Settings.LoadConditionSoundContentTypeTooltip = not Private.IsMidnight
		and "Diese Einstellung ist bis zum Midnight Pre-Patch nur via Bearbeitungsmodus konfigurierbar."
	or "Bestimmt in welchen Situationen die obigen Toneinstellungen genutzt werden, sowohl eigene Töne als auch Text-zu-Sprache."
L.Settings.LoadConditionSoundContentTypeLabels = L.Settings.LoadConditionContentTypeLabels

L.Settings.ShowDurationLabel = "Dauer anzeigen"
L.Settings.ShowDurationTooltip = "Nur ganze Zahlen, keine Sekundenbruchteile möglich."

L.Settings.ShowBorderLabel = "Rahmen"
L.Settings.ShowBorderTooltip = nil

L.Settings.OpacityLabel = "Deckkraft"
L.Settings.OpacityTooltip = nil

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
