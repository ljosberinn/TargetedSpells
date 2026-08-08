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
L.Designer.Title = "Targeted Spells - Designer del layout"
L.Designer.ElementPickerLabel = "Elemento"
L.Designer.SelectHint = "Fai clic su un elemento nell'anteprima oppure scegline uno dal menu degli elementi."
L.Designer.ResetElement = "Reimposta elemento"
L.Designer.CopyFrom = "Copia layout da…"
L.Designer.CopyFromEmpty = "Nessun altro gruppo di questo tipo"
L.Designer.Apply = "Salva modifiche"
L.Designer.Revert = "Ripristina"
L.Designer.Discard = "Scarta"
L.Designer.UnsavedHint = "Le modifiche vengono applicate al salvataggio."
L.Designer.UnsavedPrompt = "Hai modifiche al layout non salvate."
L.Designer.SettingNames = { ELEMENT_ACTIVE = "Abilitato", ELEMENT_WIDTH = "Larghezza", ELEMENT_HEIGHT = "Altezza", ELEMENT_X = "Offset X", ELEMENT_Y = "Offset Y", ELEMENT_FONT_SIZE = "Dimensione carattere", ELEMENT_FONT = "Carattere", ELEMENT_FONT_FLAGS = "Stile carattere", ELEMENT_TEXT_COLOR = "Colore testo", ELEMENT_JUSTIFY_H = "Allineamento", ELEMENT_MAX_WIDTH = "Larghezza massima", ELEMENT_GAP = "Spaziatura", ELEMENT_USE_CLASS_COLOR = "Usa colore classe", ELEMENT_ICON_ZOOM = "Zoom icona", ELEMENT_SHOW_SWIPE = "Mostra scorrimento", ELEMENT_SHOW_COUNTDOWN = "Mostra durata", ELEMENT_FRACTION_THRESHOLD = "Frazione sotto (s)", ELEMENT_BORDER_TEXTURE = "Texture bordo", ELEMENT_BORDER_COLOR = "Colore bordo", ELEMENT_BORDER_SIZE = "Dimensione bordo", ELEMENT_BAR_TEXTURE = "Texture barra", ELEMENT_BAR_COLOR_MODE = "Modalità colore", ELEMENT_BAR_COLOR = "Colore barra", ELEMENT_INTERRUPTIBLE_COLOR = "Colore interrompibile", ELEMENT_UNINTERRUPTIBLE_COLOR = "Colore non interrompibile", ELEMENT_BACKGROUND_TEXTURE = "Texture sfondo", ELEMENT_BACKGROUND_COLOR = "Colore sfondo" }
L.Designer.Options = { JUSTIFY_LEFT = "Sinistra", JUSTIFY_CENTER = "Centro", JUSTIFY_RIGHT = "Destra", BAR_COLOR_STATIC = "Statico", BAR_COLOR_INTERRUPTIBILITY = "Interrompibilità", BAR_COLOR_TARGET_CLASS = "Colore classe bersaglio" }
L.Designer.FontFlagNames = { [Private.Enum.FontFlags.OUTLINE] = "Contorno", [Private.Enum.FontFlags.SHADOW] = "Ombra" }
L.Designer.FontFlagsNone = "Nessuno"
L.Designer.ElementNames = { [Private.Enum.Element.Icon] = "Icona", [Private.Enum.Element.Overlay] = "Cornice del Gestore dei tempi di recupero", [Private.Enum.Element.Cooldown] = "Tempo di recupero", [Private.Enum.Element.Border] = "Bordo", [Private.Enum.Element.InterruptSource] = "Nome dell'interruttore", [Private.Enum.Element.ProgressBar] = "Barra di avanzamento", [Private.Enum.Element.Background] = "Sfondo", [Private.Enum.Element.TargetMarker] = "Indicatore bersaglio", [Private.Enum.Element.DurationCooldown] = "Durata", [Private.Enum.Element.SpellName] = "Nome incantesimo", [Private.Enum.Element.TargetName] = "Nome bersaglio", [Private.Enum.Element.InterruptShield] = "Scudo d'interruzione", [Private.Enum.Element.Duration] = "Durata" }
L.SlashCommands.Header = "Comandi di Targeted Spells:"
L.SlashCommands.OptionsDescription = "Apri il pannello delle impostazioni"
L.SlashCommands.SettingsDescription = "Apri il pannello delle impostazioni"
L.SlashCommands.DesignDescription = "Apri il designer del layout"

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
L.Settings.DisabledLabel = "Disabilitato"

L.Settings.AddonCompartmentTooltipLine1 =
	string.format("%s è %s", WrapTextInColorCode(L.EditMode.TargetedSpellsSelfLabel, "ffeda55f"), "%s")
L.Settings.AddonCompartmentTooltipLine2 =
	string.format("%s è %s", WrapTextInColorCode(L.EditMode.TargetedSpellsPartyLabel, "ffeda55f"), "%s")

L.Settings.LoadConditionContentTypeLabel = "Condizione di caricamento: Tipo di contenuto"
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
L.Settings.LoadConditionRoleTooltip = nil
L.Settings.LoadConditionRoleLabels = {
	[Private.Enum.Role.Healer] = "Guaritore",
	[Private.Enum.Role.Tank] = "Difensore",
	[Private.Enum.Role.Damager] = "Attaccante",
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

L.Settings.UseTargetClassColorLabel = "Usa colore classe del bersaglio"
L.Settings.UseTargetClassColorTooltip =
	"Colora la barra con il colore di classe dell'unità bersaglio al 75% di opacità. Gli incantesimi senza bersaglio utilizzeranno un Colore Barra di Sfondo più luminoso."

L.Settings.ClickToOpenSettingsLabel = "Clicca per aprire le impostazioni"

L.Settings.Import = "Importa"
L.Settings.Export = "Esporta"

L.Settings.FeatureFlagsLabel = "Funzionalità"
L.Settings.FeatureFlagsTooltip = nil
L.Settings.GroupNameLabel = "Rinomina gruppo"
L.Settings.GroupNamePrompt = "Inserisci un nome per questo gruppo:"
L.Settings.TemplateLabel = "Modello"
L.Settings.TemplateTooltip = "Cambiare modello reimposta il layout degli elementi del gruppo al modello predefinito."
L.Settings.TemplateLabels = { [Private.Enum.Template.Icon] = "Icona", [Private.Enum.Template.Bar] = "Barra", [Private.Enum.Template.IconDuration] = "Icona + durata" }
L.Settings.FilterLabel = "Mostra incantesimi che bersagliano"
L.Settings.FilterTooltip = "Quali bersagli degli incantesimi mostra questo gruppo."
L.Settings.TargetClassLabels = { [Private.Enum.TargetClass.Player] = "te", [Private.Enum.TargetClass.PartyMember] = "membri del gruppo", [Private.Enum.TargetClass.Nobody] = "nessuno (senza bersaglio)" }
L.Settings.CreateGroup = "Crea gruppo"
L.Settings.DeleteGroup = "Elimina gruppo"
L.Settings.DeleteGroupConfirm = "Eliminare questo gruppo? L'azione non può essere annullata."
L.Settings.CannotDeleteLastGroup = "Non puoi eliminare l'ultimo gruppo rimasto."
