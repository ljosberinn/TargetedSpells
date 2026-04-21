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
	"Considere usar o Modo de Edição, ele inclui visualização em tempo real de todas as configurações.\nEstas estão presentes apenas para permitir edição em combate."
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
L.Settings.EnabledTooltip = nil
L.Settings.DisabledLabel = "Desabilitado"

L.Settings.AddonCompartmentTooltipLine1 =
	string.format("%s está %s", WrapTextInColorCode(L.EditMode.TargetedSpellsSelfLabel, "ffeda55f"), "%s")
L.Settings.AddonCompartmentTooltipLine2 =
	string.format("%s está %s", WrapTextInColorCode(L.EditMode.TargetedSpellsPartyLabel, "ffeda55f"), "%s")

L.Settings.LoadConditionContentTypeLabel = "Condição de carregamento: Tipo de conteúdo"
L.Settings.LoadConditionContentTypeLabelAbbreviated = "Carregar no conteúdo"
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
L.Settings.LoadConditionRoleLabelAbbreviated = "Carregar na função"
L.Settings.LoadConditionRoleTooltip = nil
L.Settings.LoadConditionRoleLabels = {
	[Private.Enum.Role.Healer] = "Curandeiro",
	[Private.Enum.Role.Tank] = "Guardião",
	[Private.Enum.Role.Damager] = "DPS",
}

L.Settings.FrameWidthLabel = "Largura"
L.Settings.FrameWidthTooltip = nil

L.Settings.FrameHeightLabel = "Altura"
L.Settings.FrameHeightTooltip = nil

L.Settings.FontSizeLabel = "Tamanho da fonte"
L.Settings.FontSizeTooltip = nil

L.Settings.FontFlagsLabel = "Opções de fonte"
L.Settings.FontFlagsTooltip = nil
L.Settings.FontFlagsLabels = {
	[Private.Enum.FontFlags.OUTLINE] = "Contorno",
	[Private.Enum.FontFlags.SHADOW] = "Sombra",
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

L.Settings.ShowDurationLabel = "Mostrar duração"

L.Settings.IndicateInterruptsLabel = "Indicar interrupções"

L.Settings.RenderInterruptSourceNameLabel = "Mostrar nome da fonte de interrupção"

L.Settings.ShowSwipeLabel = "Mostrar animação de recarga"

L.Settings.BorderStyleLabel = "Estilo de borda"
L.Settings.BorderStyleTooltip = nil

L.Settings.ForegroundBarTextureLabel = "Textura da barra de progresso"
L.Settings.ForegroundBarTextureTooltip = nil

L.Settings.BackgroundBarTextureLabel = "Textura de fundo da barra"
L.Settings.BackgroundBarTextureTooltip = nil

L.Settings.BackgroundBarColorLabel = "Cor de fundo da barra"
L.Settings.BackgroundBarColorTooltip =
	"A opacidade só está disponível no Modo de Edição, pois a interface de configurações padrão não a expõe."

L.Settings.ProgressBarColorLabel = "Cor da barra"
L.Settings.ProgressBarColorTooltip =
	"A opacidade só está disponível no Modo de Edição, pois a interface de configurações padrão não a expõe."

L.Settings.MirrorLayoutLabel = "Layout espelhado"

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
	[Private.Enum.NpcType.Caster] = "Tem Mana",
	[Private.Enum.NpcType.Melee] = "Inimigos normais",
	[Private.Enum.NpcType.Minion] = "Capangas",
}

L.Settings.HideUntargetedSpellsLabel = "Ocultar feitiços sem alvo"

L.Settings.HideTargetedSpellsLabel = "Ocultar feitiços com alvo"

L.Settings.SelfOnlyLabel = "Mostrar apenas feitiços direcionados ao jogador"

L.Settings.InlineDurationLabel = "Posição de duração integrada"

L.Settings.UseInterruptabilityColorsLabel = "Usar cores de interrupção"
L.Settings.UseInterruptabilityColorsTooltip = nil

L.Settings.UseTargetClassColorLabel = "Usar cor de classe do alvo"
L.Settings.UseTargetClassColorTooltip =
	"Colorize a barra com a cor de classe da unidade alvo com 75% de opacidade. Feitiços sem alvo usarão uma Cor de Barra de Fundo mais clara."

L.Settings.UninterruptibleColorLabel = "Cor ininterruptível"
L.Settings.UninterruptibleColorTooltip = nil

L.Settings.InterruptibleColorLabel = "Cor interruptível"
L.Settings.InterruptibleColorTooltip = nil

L.Settings.IconZoomLabel = "Zoom do ícone"
L.Settings.IconZoomTooltip = nil

L.Settings.ClickToOpenSettingsLabel = "Clique para abrir as configurações"

L.Settings.Import = "Importar"
L.Settings.Export = "Exportar"

L.Settings.FontLabel = "Fonte"
L.Settings.FontTooltip = nil

L.Settings.FeatureFlagsLabel = "Funcionalidades"
L.Settings.FeatureFlagsTooltip = nil

L.Settings.FeatureFlagLabels = {
	[Private.Enum.FeatureFlag.GlowImportant] = L.Settings.GlowImportantLabel,
	[Private.Enum.FeatureFlag.OnlyImportant] = L.Settings.OnlyImportantLabel,
	[Private.Enum.FeatureFlag.ShowDuration] = L.Settings.ShowDurationLabel,
	[Private.Enum.FeatureFlag.ShowSwipe] = L.Settings.ShowSwipeLabel,
	[Private.Enum.FeatureFlag.IndicateInterrupts] = L.Settings.IndicateInterruptsLabel,
	[Private.Enum.FeatureFlag.RenderInterruptSourceName] = L.Settings.RenderInterruptSourceNameLabel,
	[Private.Enum.FeatureFlag.ShowIcon] = "Mostrar ícone",
	[Private.Enum.FeatureFlag.ShowTargetMarker] = "Mostrar marcador de alvo",
	[Private.Enum.FeatureFlag.ShowSpellName] = "Mostrar nome do feitiço",
	[Private.Enum.FeatureFlag.ShowTargetName] = "Mostrar nome do alvo",
	[Private.Enum.FeatureFlag.ShowTargetClassColor] = "Mostrar cor de classe do alvo",
	[Private.Enum.FeatureFlag.MirrorLayout] = L.Settings.MirrorLayoutLabel,
	[Private.Enum.FeatureFlag.InlineDuration] = L.Settings.InlineDurationLabel,
	[Private.Enum.FeatureFlag.HideUntargetedSpells] = L.Settings.HideUntargetedSpellsLabel,
	[Private.Enum.FeatureFlag.HideTargetedSpells] = L.Settings.HideTargetedSpellsLabel,
	[Private.Enum.FeatureFlag.SelfOnly] = L.Settings.SelfOnlyLabel,
}

L.Settings.FeatureFlagSettingTitles = {
	[Private.Enum.FeatureFlag.GlowImportant] = "Exibição",
	[Private.Enum.FeatureFlag.IndicateInterrupts] = "Configurações de interrupção",
}
