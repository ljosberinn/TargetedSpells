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

L.EditMode.TargetedSpellsSelfLabel = "Targeted Spells - Self"
L.EditMode.TargetedSpellsPartyLabel = "Targeted Spells - Party"

L.Functionality.CVarWarning = Private.IsMidnight
		and string.format(
			"%s\n\nThe Nameplate Setting '%s' was disabled.\n\nWithout it, %s will not work on off-screen enemies.\n\nClick '%s' to enable it again.",
			addonNameWithIcon,
			UNIT_NAMEPLATES_SHOW_OFFSCREEN,
			addonName,
			ENABLE
		)
	or nil

L.Functionality.CAAEnabledWarning = Private.IsMidnight
		and string.format(
			"%s\n\nThis addon automatically enabled '%s' and configured it as you've enabled Sound/TTS.\n\nYou can find the settings under %s -> %s -> left side %s > %s.\n\nAlternatively, type: /run Settings.OpenToCategory(18)",
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
			"%s\n\nYou disabled '%s', but this addon relies on it for its sound-related functionality.\n\nPlease either turn it on again by clicking %s or adjust your %s sound settings.",
			addonNameWithIcon,
			CAA_COMBAT_AUDIO_ALERTS_LABEL,
			ENABLE,
			L.EditMode.TargetedSpellsSelfLabel
		)
	or nil
L.Functionality.CAASayIfTargetedDisabledWarning = Private.IsMidnight
		and string.format(
			"%s\n\nYou disabled '%s', but this addon relies on it for its sound-related functionality.\n\nPlease either turn it on again by clicking %s or adjust your %s sound settings.",
			addonNameWithIcon,
			CAA_SAY_IF_TARGETED_LABEL,
			ENABLE,
			L.EditMode.TargetedSpellsSelfLabel
		)
	or nil

L.Settings.EnabledLabel = "Actif/Activé"
L.Settings.EnabledTooltip = nil
L.Settings.DisabledLabel = "Disabled"

L.Settings.AddonCompartmentTooltipLine1 =
	string.format("%s is %s", WrapTextInColorCode(L.EditMode.TargetedSpellsSelfLabel, "ffeda55f"), "%s")
L.Settings.AddonCompartmentTooltipLine2 =
	string.format("%s is %s", WrapTextInColorCode(L.EditMode.TargetedSpellsPartyLabel, "ffeda55f"), "%s")

L.Settings.LoadConditionContentTypeLabel = "Condition de chargement: Type de contenu"
L.Settings.LoadConditionContentTypeLabelAbbreviated = "Charger dans le contenu"
L.Settings.LoadConditionContentTypeTooltip = not Private.IsMidnight
		and "This setting is only configurable via Edit Mode until the Midnight Pre-Patch due to lacking the settings primitives until then."
	or nil
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
L.Settings.LoadConditionRoleTooltip = not Private.IsMidnight
		and "This setting is only configurable via Edit Mode until the Midnight Pre-Patch due to lacking the settings primitives until then."
	or nil
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

L.Settings.GlowTypeLabel = "Glow Type"
L.Settings.GlowTypeTooltip = nil
L.Settings.GlowTypeLabels = {
	[Private.Enum.GlowType.PixelGlow] = "Pixel Glow",
	[Private.Enum.GlowType.AutoCastGlow] = "Auto Cast Glow",
	[Private.Enum.GlowType.ButtonGlow] = "Button Glow",
	[Private.Enum.GlowType.ProcGlow] = "Proc Glow",
	[Private.Enum.GlowType.Star4] = "Star 4",
}

L.Settings.PlaySoundLabel = "Jouer le son"
L.Settings.PlaySoundTooltip = "Play a sound when a spell targeting you is started. DISABLES TTS!"

L.Settings.PlayTTSLabel = "Play TTS"
L.Settings.PlayTTSTooltip =
	"Plays the spell name using Text-To-Speech when a spell targeting you is started. DISABLES SOUND!"

L.Settings.TTSVoiceLabel = "TTS Voice"
L.Settings.TTSVoiceTooltip = "Select the voice used for Text-To-Speech."

L.Settings.SoundLabel = "Son"
L.Settings.SoundCategoryCustom = "Personnalisé"
L.Settings.SoundTooltip = "Click to change, but also click to preview sound. Warning: Master channel volume!"

L.Settings.SoundChannelLabel = "Sound Channel"
L.Settings.SoundChannelTooltip = nil
L.Settings.SoundChannelLabels = {
	[Private.Enum.SoundChannel.Master] = MASTER_VOLUME,
	[Private.Enum.SoundChannel.Music] = MUSIC_VOLUME,
	[Private.Enum.SoundChannel.SFX] = FX_VOLUME,
	[Private.Enum.SoundChannel.Ambience] = AMBIENCE_VOLUME,
	[Private.Enum.SoundChannel.Dialog] = DIALOG_VOLUME,
}

L.Settings.LoadConditionSoundContentTypeLabel = "Load Condition: Sound"
L.Settings.LoadConditionSoundContentTypeLabelAbbreviated = "Play Sound in Content"
L.Settings.LoadConditionSoundContentTypeTooltip = not Private.IsMidnight
		and "This setting is only configurable via Edit Mode until the Midnight Pre-Patch due to lacking the settings primitives until then."
	or "Under which circumstances the above sound settings (both custom sound and TTS) should apply."
L.Settings.LoadConditionSoundContentTypeLabels = L.Settings.LoadConditionContentTypeLabels

L.Settings.ShowDurationLabel = "Montrer la durée"
L.Settings.ShowDurationTooltip = nil

L.Settings.ShowDurationFractionsLabel = "Show Fractions"
L.Settings.ShowDurationFractionsTooltip = nil

L.Settings.IndicateInterruptsLabel = "Indicate Interrupts"
L.Settings.IndicateInterruptsTooltip =
	"Desaturates the icon, shows an indicator on top of the icon and delays hiding the icon by 1 second. Does not work with channeled spells."

L.Settings.ShowBorderLabel = "Montrer les contours"
L.Settings.ShowBorderTooltip = nil

L.Settings.OpacityLabel = "Opacité"
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

L.Settings.ClickToOpenSettingsLabel = "Cliquer pour ouvrir les paramètres"
