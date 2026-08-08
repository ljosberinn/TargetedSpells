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
L.Designer.Title = "Targeted Spells - Designer de layout"
L.Designer.ElementPickerLabel = "Elemento"
L.Designer.SelectHint = "Clique em um elemento na prévia ou escolha um no menu suspenso de elementos."
L.Designer.ResetElement = "Redefinir elemento"
L.Designer.CopyFrom = "Copiar layout de…"
L.Designer.CopyFromEmpty = "Nenhum outro grupo deste tipo"
L.Designer.Apply = "Salvar alterações"
L.Designer.Revert = "Reverter"
L.Designer.Discard = "Descartar"
L.Designer.UnsavedHint = "As alterações são aplicadas ao salvar."
L.Designer.UnsavedPrompt = "Você tem alterações de layout não salvas."
L.Designer.SettingNames = { ELEMENT_ACTIVE = "Ativado", ELEMENT_WIDTH = "Largura", ELEMENT_HEIGHT = "Altura", ELEMENT_X = "Deslocamento X", ELEMENT_Y = "Deslocamento Y", ELEMENT_FONT_SIZE = "Tamanho da fonte", ELEMENT_FONT = "Fonte", ELEMENT_FONT_FLAGS = "Estilo da fonte", ELEMENT_TEXT_COLOR = "Cor do texto", ELEMENT_JUSTIFY_H = "Alinhamento", ELEMENT_MAX_WIDTH = "Largura máxima", ELEMENT_GAP = "Espaçamento", ELEMENT_USE_CLASS_COLOR = "Usar cor de classe", ELEMENT_ICON_ZOOM = "Zoom do ícone", ELEMENT_SHOW_SWIPE = "Mostrar varredura", ELEMENT_SHOW_COUNTDOWN = "Mostrar duração", ELEMENT_FRACTION_THRESHOLD = "Fração abaixo de (s)", ELEMENT_BORDER_TEXTURE = "Textura da borda", ELEMENT_BORDER_COLOR = "Cor da borda", ELEMENT_BORDER_SIZE = "Tamanho da borda", ELEMENT_BAR_TEXTURE = "Textura da barra", ELEMENT_BAR_COLOR_MODE = "Modo de cor", ELEMENT_BAR_COLOR = "Cor da barra", ELEMENT_INTERRUPTIBLE_COLOR = "Cor interrompível", ELEMENT_UNINTERRUPTIBLE_COLOR = "Cor não interrompível", ELEMENT_BACKGROUND_TEXTURE = "Textura do fundo", ELEMENT_BACKGROUND_COLOR = "Cor do fundo" }
L.Designer.Options = { JUSTIFY_LEFT = "Esquerda", JUSTIFY_CENTER = "Centro", JUSTIFY_RIGHT = "Direita", BAR_COLOR_STATIC = "Estático", BAR_COLOR_INTERRUPTIBILITY = "Interrompibilidade", BAR_COLOR_TARGET_CLASS = "Cor de classe do alvo" }
L.Designer.FontFlagNames = { [Private.Enum.FontFlags.OUTLINE] = "Contorno", [Private.Enum.FontFlags.SHADOW] = "Sombra" }
L.Designer.FontFlagsNone = "Nenhum"
L.Designer.ElementNames = { [Private.Enum.Element.Icon] = "Ícone", [Private.Enum.Element.Overlay] = "Moldura do Gerenciador de Recargas", [Private.Enum.Element.Cooldown] = "Recarga", [Private.Enum.Element.Border] = "Borda", [Private.Enum.Element.InterruptSource] = "Nome do interruptor", [Private.Enum.Element.ProgressBar] = "Barra de progresso", [Private.Enum.Element.Background] = "Fundo", [Private.Enum.Element.TargetMarker] = "Marcador de alvo", [Private.Enum.Element.DurationCooldown] = "Duração", [Private.Enum.Element.SpellName] = "Nome do feitiço", [Private.Enum.Element.TargetName] = "Nome do alvo", [Private.Enum.Element.InterruptShield] = "Escudo de interrupção", [Private.Enum.Element.Duration] = "Duração" }
L.SlashCommands.Header = "Comandos do Targeted Spells:"
L.SlashCommands.OptionsDescription = "Abrir o painel de configurações"
L.SlashCommands.SettingsDescription = "Abrir o painel de configurações"
L.SlashCommands.DesignDescription = "Abrir o designer de layout"

L.Settings.EditModeReminder =
	"Todas as configurações estão disponíveis através do Modo de Edição e \"/targetedspells design\"."
L.EditMode.TargetedSpellsSelfLabel = "Targeted Spells - Próprio"
L.EditMode.TargetedSpellsPartyLabel = "Targeted Spells - Grupo"

L.Functionality.CVarWarning = string.format(
	"%s\n\nA configuração de identificações '%s' foi desativada.\n\nSem ela, %s não funcionará em inimigos fora da tela.\n\nClique em '%s' para reativá-la.",
	addonNameWithIcon,
	UNIT_NAMEPLATES_SHOW_OFFSCREEN,
	addonName,
	ENABLE
)

L.Functionality.V3MigrationWarning = string.format(
	"%s\n\nDevido a atualizações nas restrições de API, a funcionalidade de Grupo do Targeted Spells precisou ser completamente reformulada. Confira o Modo de Edição para uma prévia.",
	addonNameWithIcon
)

L.Settings.EnabledLabel = "Habilitado"
L.Settings.DisabledLabel = "Desabilitado"

L.Settings.AddonCompartmentTooltipLine1 =
	string.format("%s está %s", WrapTextInColorCode(L.EditMode.TargetedSpellsSelfLabel, "ffeda55f"), "%s")
L.Settings.AddonCompartmentTooltipLine2 =
	string.format("%s está %s", WrapTextInColorCode(L.EditMode.TargetedSpellsPartyLabel, "ffeda55f"), "%s")

L.Settings.LoadConditionContentTypeLabel = "Condição de carregamento: Tipo de conteúdo"
L.Settings.LoadConditionContentTypeTooltip = nil
L.Settings.LoadConditionContentTypeLabels = {
	[Private.Enum.ContentType.OpenWorld] = "Mundo aberto",
	[Private.Enum.ContentType.Delve] = "Masmorra de desbravamento",
	[Private.Enum.ContentType.Dungeon] = "Masmorra",
	[Private.Enum.ContentType.Raid] = "Raide",
	[Private.Enum.ContentType.Arena] = "Arena",
	[Private.Enum.ContentType.Battleground] = "Campo de batalha",
}

L.Settings.LoadConditionRoleLabel = "Condição de carregamento: Função"
L.Settings.LoadConditionRoleTooltip = nil
L.Settings.LoadConditionRoleLabels = {
	[Private.Enum.Role.Healer] = "Curandeiro",
	[Private.Enum.Role.Tank] = "Guardião",
	[Private.Enum.Role.Damager] = "DPS",
}

L.Settings.FrameGapLabel = "Espaçamento"
L.Settings.FrameGapTooltip = nil

L.Settings.FrameDirectionLabel = "Direção"
L.Settings.FrameDirectionTooltip = nil
L.Settings.FrameDirectionHorizontal = "Horizontal"
L.Settings.FrameDirectionVertical = "Vertical"

L.Settings.FrameSortOrderLabel = "Ordem de classificação"
L.Settings.FrameSortOrderTooltip = nil
L.Settings.FrameSortOrderAscending = "Crescente"
L.Settings.FrameSortOrderDescending = "Decrescente"

L.Settings.FrameGrowLabel = "Expansão"
L.Settings.FrameGrowTooltip = nil
L.Settings.FrameGrowLabels = {
	[Private.Enum.Grow.Start] = "Início",
	[Private.Enum.Grow.End] = "Fim",
}

L.Settings.GlowImportantLabel = "Realçar feitiços importantes"

L.Settings.OnlyImportantLabel = "Mostrar apenas feitiços importantes"

L.Settings.GlowTypeLabel = "Tipo de brilho"
L.Settings.GlowTypeTooltip = nil
L.Settings.GlowTypeLabels = {
	[Private.Enum.GlowType.PixelGlow] = "Pixel Glow",
	[Private.Enum.GlowType.AutoCastGlow] = "Auto Cast Glow",
	[Private.Enum.GlowType.ProcGlow] = "Proc Glow",
	[Private.Enum.GlowType.Star4] = "Estrela 4",
}

L.Settings.IndicateInterruptsLabel = "Indicar interrupções"

L.Settings.TextToSpeechVoiceLabel = "Voz TTS"
L.Settings.TextToSpeechVoiceTooltip =
	"Voz usada para os anúncios de texto para voz. Compartilhada entre as configurações Self e Party."

L.Settings.AnnounceUntargetedSpellsLabel = "Configurações TTS sem alvo"
L.Settings.AnnounceUntargetedSpellsTooltip =
	"Voz sintetizada para feitiços sem alvo (AoE, frontais, etc.) por tipo de NPC."

L.Settings.AnnounceTargetedSpellsLabel = "Configurações TTS com alvo"
L.Settings.AnnounceTargetedSpellsTooltip =
	"Voz sintetizada para feitiços que miram um jogador específico, por tipo de NPC."

L.Settings.NpcTypeLabels = {
	[Private.Enum.NpcType.Boss] = "Chefes",
	[Private.Enum.NpcType.Lieutenant] = "Tenentes",
	[Private.Enum.NpcType.Other] = "Todos os outros",
	[Private.Enum.NpcType.Minion] = "Capangas",
}

L.Settings.UseTargetClassColorLabel = "Usar cor de classe do alvo"
L.Settings.UseTargetClassColorTooltip =
	"Colorize a barra com a cor de classe da unidade alvo com 75% de opacidade. Feitiços sem alvo usarão uma Cor de Barra de Fundo mais clara."

L.Settings.ClickToOpenSettingsLabel = "Clique para abrir as configurações"

L.Settings.Import = "Importar"
L.Settings.Export = "Exportar"

L.Settings.FeatureFlagsLabel = "Funcionalidades"
L.Settings.FeatureFlagsTooltip = nil
L.Settings.GroupNameLabel = "Renomear grupo"
L.Settings.GroupNamePrompt = "Digite um nome para este grupo:"
L.Settings.TemplateLabel = "Modelo"
L.Settings.TemplateTooltip = "Trocar o modelo redefine o layout dos elementos deste grupo para o padrão do modelo."
L.Settings.TemplateLabels = { [Private.Enum.Template.Icon] = "Ícone", [Private.Enum.Template.Bar] = "Barra", [Private.Enum.Template.IconDuration] = "Ícone + duração" }
L.Settings.FilterLabel = "Mostrar lançamentos que têm como alvo"
L.Settings.FilterTooltip = "Quais alvos de lançamento este grupo exibe."
L.Settings.TargetClassLabels = { [Private.Enum.TargetClass.Player] = "você", [Private.Enum.TargetClass.PartyMember] = "membros do grupo", [Private.Enum.TargetClass.Nobody] = "ninguém (sem alvo)" }
L.Settings.CreateGroup = "Criar grupo"
L.Settings.DeleteGroup = "Excluir grupo"
L.Settings.DeleteGroupConfirm = "Excluir este grupo? Isso não pode ser desfeito."
L.Settings.CannotDeleteLastGroup = "Você não pode excluir o último grupo restante."
