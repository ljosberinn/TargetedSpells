---@type string, TargetedSpells
local addonName, Private = ...

local L = Private.L

L.EditMode = {}
L.Functionality = {}
L.Settings = {}

L.EditMode.TargetedSpellsSelfLabel = "Targeted Spells - Self"
L.EditMode.TargetedSpellsPartyLabel = "Targeted Spells - Party"

L.Functionality.CVarWarning = string.format(
	"The Nameplate Setting '%s' was disabled.\n\nWithout it, %s will not work on off-screen enemies.\n\nClick '%s' to enable it.",
	UNIT_NAMEPLATES_SHOW_OFFSCREEN,
	addonName,
	ACCEPT
)

L.Settings.EnabledLabel = "Enabled"
L.Settings.EnabledTooltip = nil
L.Settings.DisabledLabel = "Disabled"

L.Settings.AddonCompartmentTooltipLine1 =
	string.format("%s is %s", WrapTextInColorCode(L.EditMode.TargetedSpellsSelfLabel, "ffeda55f"), "%s")
L.Settings.AddonCompartmentTooltipLine2 =
	string.format("%s is %s", WrapTextInColorCode(L.EditMode.TargetedSpellsPartyLabel, "ffeda55f"), "%s")

L.Settings.LoadConditionContentTypeLabel = "Load Condition: Content Type"
L.Settings.LoadConditionContentTypeLabelAbbreviated = "Load in Content"
L.Settings.LoadConditionContentTypeTooltip = Private.IsMidnight and nil
	or "This setting is only configurable via Edit Mode until the Midnight Pre-Patch due to lacking the settings primitives until then."
L.Settings.LoadConditionContentTypeLabels = {
	[Private.Enum.ContentType.OpenWorld] = "Open World",
	[Private.Enum.ContentType.Delve] = "Delves",
	[Private.Enum.ContentType.Dungeon] = "Dungeon",
	[Private.Enum.ContentType.Raid] = "Raid",
	[Private.Enum.ContentType.Arena] = "Arena",
	[Private.Enum.ContentType.Battleground] = "Battleground",
}

L.Settings.LoadConditionRoleLabel = "Load Condition: Role"
L.Settings.LoadConditionRoleLabelAbbreviated = "Load on Role"
L.Settings.LoadConditionRoleTooltip = Private.IsMidnight and nil
	or "This setting is only configurable via Edit Mode until the Midnight Pre-Patch due to lacking the settings primitives until then."
L.Settings.LoadConditionRoleLabels = {
	[Private.Enum.Role.Healer] = "Healer",
	[Private.Enum.Role.Tank] = "Tank",
	[Private.Enum.Role.Damager] = "DPS",
}

L.Settings.MaxFramesLabel = "Max Frames"
L.Settings.MaxFramesTooltip = nil

L.Settings.FrameWidthLabel = "Width"
L.Settings.FrameWidthTooltip = nil

L.Settings.FrameHeightLabel = "Height"
L.Settings.FrameHeightTooltip = nil

L.Settings.FontSizeLabel = "Font Size"
L.Settings.FontSizeTooltip = nil

L.Settings.FrameGapLabel = "Gap"
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
	[Private.Enum.Grow.Center] = "Center",
	[Private.Enum.Grow.Start] = "Start",
	[Private.Enum.Grow.End] = "End",
}

L.Settings.GlowImportantLabel = "Glow Important Spells"
L.Settings.GlowImportantTooltip = "What's important and what isn't is declared by the game."

L.Settings.PlaySoundLabel = "Play Sound"
L.Settings.PlaySoundTooltip = nil

L.Settings.SoundLabel = "Sound"
L.Settings.SoundCategoryCustom = "Custom"
L.Settings.SoundTooltip = "Click to change, but also click to preview sound. Warning: Master channel volume!"

L.Settings.SoundChannelLabel = "Sound Channel"
L.Settings.SoundChannelTooltip = nil

L.Settings.ShowDurationLabel = "Show Duration"
L.Settings.ShowDurationTooltip = nil

L.Settings.ShowBorderLabel = "Show Border"
L.Settings.ShowBorderTooltip = nil

L.Settings.OpacityLabel = "Opacity"
L.Settings.OpacityTooltip = nil

L.Settings.FrameOffsetXLabel = "Offset X"
L.Settings.FrameOffsetXTooltip = nil

L.Settings.FrameOffsetYLabel = "Offset Y"
L.Settings.FrameOffsetYTooltip = nil

L.Settings.FrameSourceAnchorLabel = "Source Anchor"
L.Settings.FrameSourceAnchorTooltip = nil

L.Settings.FrameTargetAnchorLabel = "Target Anchor"
L.Settings.FrameTargetAnchorTooltip = nil

L.Settings.IncludeSelfInPartyLabel = "Include Self In Party"
L.Settings.IncludeSelfInPartyTooltip = "Only works when using Raid-Style Party Frames."

L.Settings.ClickToOpenSettingsLabel = "Click to open settings"

local locale = GAME_LOCALE or GetLocale()

if locale == "deDE" then
	L.EditMode.TargetedSpellsSelfLabel = "Targeted Spells - Spieler"
	L.EditMode.TargetedSpellsPartyLabel = "Targeted Spells - Gruppe"

	L.Functionality.CVarWarning = string.format(
		"Die Namensplaketteneinstellung '%s' wurde deaktiviert.\n\nOhne sie funktioniert %s nicht bei Gegnern die außerhalb des Bildschirms stehen.\n\nKlicke '%s' um die Einstellung zu aktivieren.",
		UNIT_NAMEPLATES_SHOW_OFFSCREEN,
		addonName,
		ACCEPT
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
	L.Settings.LoadConditionContentTypeTooltip = Private.IsMidnight and nil
		or "Diese Einstellung ist bis zum Midnight Pre-Patch nur via Edit Mode konfigurierbar."
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
	L.Settings.LoadConditionRoleTooltip = Private.IsMidnight and nil
		or "Diese Einstellung ist bis zum Midnight Pre-Patch nur via Edit Mode konfigurierbar."
	L.Settings.LoadConditionRoleLabels = {
		[Private.Enum.Role.Healer] = "Heiler",
		[Private.Enum.Role.Tank] = "Panzer",
		[Private.Enum.Role.Damager] = "Schadensverursacher",
	}

	L.Settings.MaxFramesLabel = "Maximalanzahl angezeigter Zauber"
	L.Settings.MaxFramesTooltip = nil

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

	L.Settings.PlaySoundLabel = "Ton abspielen"
	L.Settings.PlaySoundTooltip = nil
	L.Settings.SoundTooltip = "Klicken für Vorschau und ändern. Warnung: nutzt Master Tonkanal!"

	L.Settings.SoundLabel = "Ton"
	L.Settings.SoundCategoryCustom = "Custom"
	L.Settings.SoundTooltip = nil

	L.Settings.SoundChannelLabel = "Tonkanal"
	L.Settings.SoundChannelTooltip = nil

	L.Settings.ShowDurationLabel = "Dauer anzeigen"
	L.Settings.ShowDurationTooltip = nil

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
elseif locale == "esES" or locale == "esMX" then
elseif locale == "frFR" then
	L.EditMode.TargetedSpellsSelfLabel = "Targeted Spells - Self"
	L.EditMode.TargetedSpellsPartyLabel = "Targeted Spells - Party"

	L.Functionality.CVarWarning = string.format(
		"The Nameplate Setting '%s' was disabled.\n\nWithout it, %s will not work on off-screen enemies.\n\nClick '%s' to enable it.",
		UNIT_NAMEPLATES_SHOW_OFFSCREEN,
		addonName,
		ACCEPT
	)

	L.Settings.EnabledLabel = "Actif/Activé"
	L.Settings.EnabledTooltip = nil
	L.Settings.DisabledLabel = "Disabled"

	L.Settings.AddonCompartmentTooltipLine1 =
		string.format("%s is %s", WrapTextInColorCode(L.EditMode.TargetedSpellsSelfLabel, "ffeda55f"), "%s")
	L.Settings.AddonCompartmentTooltipLine2 =
		string.format("%s is %s", WrapTextInColorCode(L.EditMode.TargetedSpellsPartyLabel, "ffeda55f"), "%s")

	L.Settings.LoadConditionContentTypeLabel = "Condition de chargement: Type de contenu"
	L.Settings.LoadConditionContentTypeLabelAbbreviated = "Charger dans le contenu"
	L.Settings.LoadConditionContentTypeTooltip = Private.IsMidnight and nil
		or "This setting is only configurable via Edit Mode until the Midnight Pre-Patch due to lacking the settings primitives until then."
	L.Settings.LoadConditionContentTypeLabels = {
		[Private.Enum.ContentType.OpenWorld] = "Open World",
		[Private.Enum.ContentType.Delve] = "Delves",
		[Private.Enum.ContentType.Dungeon] = "Dungeon",
		[Private.Enum.ContentType.Raid] = "Raid",
		[Private.Enum.ContentType.Arena] = "Arena",
		[Private.Enum.ContentType.Battleground] = "Battleground",
	}

	L.Settings.LoadConditionRoleLabel = "Condition de chargement: Rôle"
	L.Settings.LoadConditionRoleLabelAbbreviated = "Chargement sur Rôle"
	L.Settings.LoadConditionRoleTooltip = Private.IsMidnight and nil
		or "This setting is only configurable via Edit Mode until the Midnight Pre-Patch due to lacking the settings primitives until then."
	L.Settings.LoadConditionRoleLabels = {
		[Private.Enum.Role.Healer] = "Healer",
		[Private.Enum.Role.Tank] = "Tank",
		[Private.Enum.Role.Damager] = "DPS",
	}

	L.Settings.MaxFramesLabel = "Max Frames"
	L.Settings.MaxFramesTooltip = nil

	L.Settings.FrameWidthLabel = "Largeur"
	L.Settings.FrameWidthTooltip = nil

	L.Settings.FrameHeightLabel = "Hauteur"
	L.Settings.FrameHeightTooltip = nil

	L.Settings.FontSizeLabel = "Taille de la police"
	L.Settings.FontSizeTooltip = nil

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
		[Private.Enum.Grow.Center] = "Center",
		[Private.Enum.Grow.Start] = "Start",
		[Private.Enum.Grow.End] = "End",
	}

	L.Settings.GlowImportantLabel = "Faire briller les sorts important"
	L.Settings.GlowImportantTooltip = "Ce qui est important ou non est déclaré par le jeu."

	L.Settings.PlaySoundLabel = "Jouer le son"
	L.Settings.SoundCategoryCustom = "Custom"
	L.Settings.SoundTooltip = "Click to change, but also click to preview sound. Warning: Master channel volume!"

	L.Settings.SoundLabel = "Son"
	L.Settings.SoundCategoryCustom = "Personnalisé"

	L.Settings.SoundChannelLabel = "Sound Channel"

	L.Settings.ShowDurationLabel = "Montrer la durée"

	L.Settings.ShowBorderLabel = "Montrer les contours"

	L.Settings.OpacityLabel = "Opacité"

	L.Settings.FrameOffsetXLabel = "Offset X"

	L.Settings.FrameOffsetYLabel = "Offset Y"

	L.Settings.FrameSourceAnchorLabel = "Source Anchor"

	L.Settings.FrameTargetAnchorLabel = "Target Anchor"

	L.Settings.IncludeSelfInPartyLabel = "Include Self In Party"
	L.Settings.IncludeSelfInPartyTooltip = "Only works when using Raid-Style Party Frames."

	L.Settings.ClickToOpenSettingsLabel = "Cliquer pour ouvrir les paramètres"
elseif locale == "itIT" then
elseif locale == "koKO" then
elseif locale == "ptBR" then
elseif locale == "ruRU" then
elseif locale == "zhCN" then
elseif locale == "zhTW" then
end
