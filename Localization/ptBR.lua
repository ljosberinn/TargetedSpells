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
