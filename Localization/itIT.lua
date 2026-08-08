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
	"Tutte le impostazioni sono disponibili tramite la Modalità Modifica e \"/targetedspells design\"."
L.EditMode.TargetedSpellsSelfLabel = "Targeted Spells - Sé"
L.EditMode.TargetedSpellsPartyLabel = "Targeted Spells - Gruppo"

L.Functionality.CVarWarning = string.format(
	"%s\n\nL'impostazione delle targhette '%s' è stata disabilitata.\n\nSenza di essa, %s non funzionerà sui nemici fuori schermo.\n\nFai clic su '%s' per riattivarla.",
	addonNameWithIcon,
	UNIT_NAMEPLATES_SHOW_OFFSCREEN,
	addonName,
	ENABLE
)

L.Functionality.V3MigrationWarning = string.format(
	"%s\n\nA causa di aggiornamenti alle restrizioni API, la funzionalità Gruppo di Targeted Spells ha dovuto essere completamente revisionata. Controlla la Modalità Modifica per un'anteprima.",
	addonNameWithIcon
)

L.Settings.EnabledLabel = "Abilitato"
L.Settings.EnabledTooltip = nil
L.Settings.DisabledLabel = "Disabilitato"

L.Settings.AddonCompartmentTooltipLine1 =
	string.format("%s è %s", WrapTextInColorCode(L.EditMode.TargetedSpellsSelfLabel, "ffeda55f"), "%s")
L.Settings.AddonCompartmentTooltipLine2 =
	string.format("%s è %s", WrapTextInColorCode(L.EditMode.TargetedSpellsPartyLabel, "ffeda55f"), "%s")

L.Settings.LoadConditionContentTypeLabel = "Condizione di caricamento: Tipo di contenuto"
L.Settings.LoadConditionContentTypeLabelAbbreviated = "Carica nel contenuto"
L.Settings.LoadConditionContentTypeTooltip = nil
L.Settings.LoadConditionContentTypeLabels = {
	[Private.Enum.ContentType.OpenWorld] = "Mondo aperto",
	[Private.Enum.ContentType.Delve] = "Abisso",
	[Private.Enum.ContentType.Dungeon] = "Dungeon",
	[Private.Enum.ContentType.Raid] = "Incursione",
	[Private.Enum.ContentType.Arena] = "Arena",
	[Private.Enum.ContentType.Battleground] = "Campo di battaglia",
}

L.Settings.LoadConditionRoleLabel = "Condizione di caricamento: Ruolo"
L.Settings.LoadConditionRoleLabelAbbreviated = "Carica nel ruolo"
L.Settings.LoadConditionRoleTooltip = nil
L.Settings.LoadConditionRoleLabels = {
	[Private.Enum.Role.Healer] = "Guaritore",
	[Private.Enum.Role.Tank] = "Difensore",
	[Private.Enum.Role.Damager] = "Attaccante",
}

L.Settings.FrameWidthLabel = "Larghezza"
L.Settings.FrameWidthTooltip = nil

L.Settings.FrameHeightLabel = "Altezza"
L.Settings.FrameHeightTooltip = nil

L.Settings.FontSizeLabel = "Dimensione carattere"
L.Settings.FontSizeTooltip = nil

L.Settings.FontFlagsLabel = "Opzioni carattere"
L.Settings.FontFlagsTooltip = nil
L.Settings.FontFlagsLabels = {
	[Private.Enum.FontFlags.OUTLINE] = "Contorno",
	[Private.Enum.FontFlags.SHADOW] = "Ombra",
}

L.Settings.FrameGapLabel = "Spaziatura"
L.Settings.FrameGapTooltip = nil

L.Settings.FrameDirectionLabel = "Direzione"
L.Settings.FrameDirectionTooltip = nil
L.Settings.FrameDirectionHorizontal = "Orizzontale"
L.Settings.FrameDirectionVertical = "Verticale"

L.Settings.FrameSortOrderLabel = "Ordinamento"
L.Settings.FrameSortOrderTooltip = nil
L.Settings.FrameSortOrderAscending = "Crescente"
L.Settings.FrameSortOrderDescending = "Decrescente"

L.Settings.FrameGrowLabel = "Espansione"
L.Settings.FrameGrowTooltip = nil
L.Settings.FrameGrowLabels = {
	[Private.Enum.Grow.Start] = "Inizio",
	[Private.Enum.Grow.End] = "Fine",
}

L.Settings.GlowImportantLabel = "Illumina incantesimi importanti"

L.Settings.OnlyImportantLabel = "Mostra solo incantesimi importanti"

L.Settings.GlowTypeLabel = "Tipo di bagliore"
L.Settings.GlowTypeTooltip = nil
L.Settings.GlowTypeLabels = {
	[Private.Enum.GlowType.PixelGlow] = "Pixel Glow",
	[Private.Enum.GlowType.AutoCastGlow] = "Auto Cast Glow",
	[Private.Enum.GlowType.ProcGlow] = "Proc Glow",
	[Private.Enum.GlowType.Star4] = "Stella 4",
}

L.Settings.IndicateInterruptsLabel = "Indica interruzioni"

L.Settings.BorderStyleLabel = "Stile bordo"
L.Settings.BorderStyleTooltip = nil

L.Settings.ForegroundBarTextureLabel = "Texture barra progressione"
L.Settings.ForegroundBarTextureTooltip = nil

L.Settings.BackgroundBarTextureLabel = "Texture sfondo barra"
L.Settings.BackgroundBarTextureTooltip = nil

L.Settings.BackgroundBarColorLabel = "Colore sfondo barra"
L.Settings.BackgroundBarColorTooltip =
	"L'opacità è disponibile solo in Modalità Modifica, poiché l'interfaccia delle impostazioni predefinita non la espone."

L.Settings.ProgressBarColorLabel = "Colore barra"
L.Settings.ProgressBarColorTooltip =
	"L'opacità è disponibile solo in Modalità Modifica, poiché l'interfaccia delle impostazioni predefinita non la espone."

L.Settings.TextToSpeechVoiceLabel = "Voce TTS"
L.Settings.TextToSpeechVoiceTooltip =
	"Voce utilizzata per gli annunci di sintesi vocale. Condivisa tra le impostazioni Self e Party."

L.Settings.AnnounceUntargetedSpellsLabel = "Impostazioni TTS non mirati"
L.Settings.AnnounceUntargetedSpellsTooltip =
	"Sintesi vocale per le magie senza bersaglio (AoE, frontali, ecc.) per tipo di PNG."

L.Settings.AnnounceTargetedSpellsLabel = "Impostazioni TTS mirati"
L.Settings.AnnounceTargetedSpellsTooltip =
	"Sintesi vocale per le magie che colpiscono un giocatore specifico, per tipo di PNG."

L.Settings.NpcTypeLabels = {
	[Private.Enum.NpcType.Boss] = "Boss",
	[Private.Enum.NpcType.Lieutenant] = "Luogotenenti",
	[Private.Enum.NpcType.Other] = "Tutti gli altri",
	[Private.Enum.NpcType.Minion] = "Scagnozzi",
}

L.Settings.UseInterruptabilityColorsLabel = "Usa colori interruzione"
L.Settings.UseInterruptabilityColorsTooltip = nil

L.Settings.UseTargetClassColorLabel = "Usa colore classe del bersaglio"
L.Settings.UseTargetClassColorTooltip =
	"Colora la barra con il colore di classe dell'unità bersaglio al 75% di opacità. Gli incantesimi senza bersaglio utilizzeranno un Colore Barra di Sfondo più luminoso."

L.Settings.UninterruptibleColorLabel = "Colore non interrompibile"
L.Settings.UninterruptibleColorTooltip = nil

L.Settings.InterruptibleColorLabel = "Colore interrompibile"
L.Settings.InterruptibleColorTooltip = nil

L.Settings.IconZoomLabel = "Zoom icona"
L.Settings.IconZoomTooltip = nil

L.Settings.ClickToOpenSettingsLabel = "Clicca per aprire le impostazioni"

L.Settings.Import = "Importa"
L.Settings.Export = "Esporta"

L.Settings.FontLabel = "Carattere"
L.Settings.FontTooltip = nil

L.Settings.FeatureFlagsLabel = "Funzionalità"
L.Settings.FeatureFlagsTooltip = nil

