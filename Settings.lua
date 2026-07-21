---@type string, TargetedSpells
local addonName, Private = ...
local LibSharedMedia = LibStub("LibSharedMedia-3.0")

---@class TargetedSpellsSettings
Private.Settings = {}

Private.Settings.Keys = {
	Self = {
		Enabled = "ENABLED_SELF",
		LoadConditionContentType = "LOAD_CONDITION_CONTENT_TYPE_SELF",
		LoadConditionRole = "LOAD_CONDITION_ROLE_SELF",
		Width = "FRAME_WIDTH_SELF",
		Height = "FRAME_HEIGHT_SELF",
		FontSize = "FONT_SIZE_SELF",
		Gap = "FRAME_GAP_SELF",
		Direction = "GROW_DIRECTION_SELF",
		SortOrder = "FRAME_SORT_ORDER_SELF",
		GlowType = "GLOW_TYPE_SELF",
		Grow = "FRAME_GROW_SELF",
		Filter = "FILTER_SELF",
		Template = "TEMPLATE_SELF",
		Name = "NAME_SELF",
		IconZoom = "ICON_ZOOM_SELF",
		Import = "IMPORT_SELF",
		Export = "EXPORT_SELF",
		Font = "FONT_SELF",
		FontFlags = "FONT_FLAGS_SELF",
		FeatureFlags = "FEATURE_FLAGS_SELF",
		BorderStyle = "BORDER_STYLE_SELF",
		AnnounceUntargetedSpells = "ANNOUNCE_UNTARGETED_SPELLS_SELF",
		AnnounceTargetedSpells = "ANNOUNCE_TARGETED_SPELLS_SELF",
		TextToSpeechVoice = "TTS_VOICE_SELF",
	},
	Party = {
		Enabled = "ENABLED_PARTY",
		LoadConditionContentType = "LOAD_CONDITION_CONTENT_TYPE_PARTY",
		LoadConditionRole = "LOAD_CONDITION_ROLE_PARTY",
		Width = "FRAME_WIDTH_PARTY",
		Height = "FRAME_HEIGHT_PARTY",
		FontSize = "FONT_SIZE_PARTY",
		Gap = "FRAME_GAP_PARTY",
		Direction = "GROW_DIRECTION_PARTY",
		SortOrder = "FRAME_SORT_ORDER_PARTY",
		GlowType = "GLOW_TYPE_PARTY",
		Grow = "FRAME_GROW_PARTY",
		Filter = "FILTER_PARTY",
		Template = "TEMPLATE_PARTY",
		Name = "NAME_PARTY",
		ForegroundBarTexture = "FOREGROUND_BAR_TEXTURE_PARTY",
		BackgroundBarTexture = "BACKGROUND_BAR_TEXTURE_PARTY",
		BackgroundBarColor = "BACKGROUND_BAR_COLOR_PARTY",
		ProgressBarColor = "PROGRESS_BAR_COLOR_PARTY",
		UseInterruptabilityColors = "USE_INTERRUPTABILITY_COLORS_PARTY",
		UseTargetClassColor = "USE_TARGET_CLASS_COLOR_PARTY",
		UninterruptibleColor = "UNINTERRUPTIBLE_COLOR_PARTY",
		InterruptibleColor = "INTERRUPTIBLE_COLOR_PARTY",
		Import = "IMPORT_PARTY",
		Export = "EXPORT_PARTY",
		Font = "FONT_PARTY",
		FontFlags = "FONT_FLAGS_PARTY",
		FeatureFlags = "FEATURE_FLAGS_PARTY",
		AnnounceUntargetedSpells = "ANNOUNCE_UNTARGETED_SPELLS_PARTY",
		AnnounceTargetedSpells = "ANNOUNCE_TARGETED_SPELLS_PARTY",
		TextToSpeechVoice = "TTS_VOICE_PARTY",
	},
}

function Private.Settings.GetDefaultEditModeFramePosition(kind)
	if kind == Private.Enum.FrameKind.Self then
		return { point = "CENTER", x = 0, y = 100 }
	end

	return { point = "CENTER", x = 0, y = 325 }
end

---@return SavedVariablesSettingsSelf
function Private.Settings.GetSelfDefaultSettings()
	return {
		Enabled = true,
		Width = 48,
		Height = 48,
		Gap = 2,
		Direction = Private.Enum.Direction.Horizontal,
		LoadConditionContentType = {
			[Private.Enum.ContentType.OpenWorld] = false,
			[Private.Enum.ContentType.Delve] = true,
			[Private.Enum.ContentType.Dungeon] = true,
			[Private.Enum.ContentType.Raid] = false,
			[Private.Enum.ContentType.Arena] = true,
			[Private.Enum.ContentType.Battleground] = false,
		},
		LoadConditionRole = {
			[Private.Enum.Role.Healer] = true,
			[Private.Enum.Role.Tank] = true,
			[Private.Enum.Role.Damager] = true,
		},
		SortOrder = Private.Enum.SortOrder.Ascending,
		Grow = Private.Enum.Grow.Start,
		FontSize = 20,
		Position = Private.Settings.GetDefaultEditModeFramePosition(Private.Enum.FrameKind.Self),
		IconZoom = 1,
		GlowType = Private.Enum.GlowType.PixelGlow,
		Font = "Fonts\\FRIZQT__.TTF",
		FontFlags = {
			[Private.Enum.FontFlags.OUTLINE] = true,
			[Private.Enum.FontFlags.SHADOW] = false,
		},
		FeatureFlags = {
			[Private.Enum.FeatureFlag.GlowImportant] = true,
			[Private.Enum.FeatureFlag.OnlyImportant] = false,
			[Private.Enum.FeatureFlag.ShowDuration] = true,
			[Private.Enum.FeatureFlag.ShowSwipe] = true,
			[Private.Enum.FeatureFlag.IndicateInterrupts] = false,
			[Private.Enum.FeatureFlag.RenderInterruptSourceName] = false,
		},
		BorderStyle = "Blizzard Tooltip Border",
		AnnounceUntargetedSpells = {
			[Private.Enum.NpcType.Boss] = true,
			[Private.Enum.NpcType.Lieutenant] = true,
			[Private.Enum.NpcType.Caster] = true,
			[Private.Enum.NpcType.Melee] = true,
			[Private.Enum.NpcType.Minion] = false,
		},
		AnnounceTargetedSpells = {
			[Private.Enum.NpcType.Boss] = false,
			[Private.Enum.NpcType.Lieutenant] = false,
			[Private.Enum.NpcType.Caster] = false,
			[Private.Enum.NpcType.Melee] = false,
			[Private.Enum.NpcType.Minion] = false,
		},
		TextToSpeechVoice = -1,
	}
end

---@return SavedVariablesSettingsParty
function Private.Settings.GetPartyDefaultSettings()
	return {
		Enabled = true,
		Width = 300,
		Height = 30,
		FontSize = 14,
		Gap = 2,
		LoadConditionContentType = {
			[Private.Enum.ContentType.OpenWorld] = false,
			[Private.Enum.ContentType.Delve] = true,
			[Private.Enum.ContentType.Dungeon] = true,
			[Private.Enum.ContentType.Raid] = false,
			[Private.Enum.ContentType.Arena] = true,
			[Private.Enum.ContentType.Battleground] = false,
		},
		LoadConditionRole = {
			[Private.Enum.Role.Healer] = true,
			[Private.Enum.Role.Tank] = true,
			[Private.Enum.Role.Damager] = true,
		},
		SortOrder = Private.Enum.SortOrder.Ascending,
		Grow = Private.Enum.Grow.Start,
		GlowType = Private.Enum.GlowType.PixelGlow,
		Font = "Fonts\\FRIZQT__.TTF",
		FontFlags = {
			[Private.Enum.FontFlags.OUTLINE] = true,
			[Private.Enum.FontFlags.SHADOW] = false,
		},
		FeatureFlags = {
			[Private.Enum.FeatureFlag.GlowImportant] = true,
			[Private.Enum.FeatureFlag.OnlyImportant] = false,
			[Private.Enum.FeatureFlag.IndicateInterrupts] = true,
			[Private.Enum.FeatureFlag.RenderInterruptSourceName] = true,
			[Private.Enum.FeatureFlag.ShowDuration] = true,
			[Private.Enum.FeatureFlag.ShowIcon] = true,
			[Private.Enum.FeatureFlag.ShowTargetMarker] = false,
			[Private.Enum.FeatureFlag.ShowSpellName] = true,
			[Private.Enum.FeatureFlag.ShowTargetName] = true,
			[Private.Enum.FeatureFlag.ShowTargetClassColor] = true,
			[Private.Enum.FeatureFlag.MirrorLayout] = false,
			[Private.Enum.FeatureFlag.HideUntargetedSpells] = false,
			[Private.Enum.FeatureFlag.HideTargetedSpells] = false,
			[Private.Enum.FeatureFlag.SelfOnly] = false,
			[Private.Enum.FeatureFlag.InlineDuration] = true,
		},
		ForegroundBarTexture = "Blizzard Raid Bar",
		BackgroundBarTexture = "Solid",
		BackgroundBarColor = "FF1A1A1A",
		ProgressBarColor = "FFFFFF00",
		UseInterruptabilityColors = true,
		UseTargetClassColor = false,
		UninterruptibleColor = "FFFF4444",
		InterruptibleColor = "FF44FF44",
		AnnounceUntargetedSpells = {
			[Private.Enum.NpcType.Boss] = true,
			[Private.Enum.NpcType.Lieutenant] = true,
			[Private.Enum.NpcType.Caster] = true,
			[Private.Enum.NpcType.Melee] = true,
			[Private.Enum.NpcType.Minion] = false,
		},
		AnnounceTargetedSpells = {
			[Private.Enum.NpcType.Boss] = false,
			[Private.Enum.NpcType.Lieutenant] = false,
			[Private.Enum.NpcType.Caster] = false,
			[Private.Enum.NpcType.Melee] = false,
			[Private.Enum.NpcType.Minion] = false,
		},
		TextToSpeechVoice = -1,
		Position = Private.Settings.GetDefaultEditModeFramePosition(Private.Enum.FrameKind.Party),
	}
end

function Private.Settings.GetFontOptions()
	local fonts = CopyTable(LibSharedMedia:List(LibSharedMedia.MediaType.FONT))
	table.sort(fonts)
	local byLabel = LibSharedMedia:HashTable(LibSharedMedia.MediaType.FONT)

	return {
		fonts = fonts,
		byLabel = byLabel,
	}
end

function Private.Settings.GetStatusBarOptions()
	local bars = CopyTable(LibSharedMedia:List(LibSharedMedia.MediaType.STATUSBAR))
	table.sort(bars)

	return bars
end

function Private.Settings.GetBackgroundOptions()
	local backgrounds = CopyTable(LibSharedMedia:List(LibSharedMedia.MediaType.BACKGROUND))
	table.sort(backgrounds)

	return backgrounds
end

function Private.Settings.GetBorderOptions()
	local borders = {
		"Solid",
	}

	for _, border in pairs(CopyTable(LibSharedMedia:List(LibSharedMedia.MediaType.BORDER))) do
		table.insert(borders, border)
	end

	table.sort(borders)

	return borders
end

function Private.Settings.GetTtsVoiceOptions()
	local seen = {}
	local voices = {}

	for _, list in ipairs({ C_VoiceChat.GetTtsVoices(), C_VoiceChat.GetRemoteTtsVoices() }) do
		if list then
			for _, voice in ipairs(list) do
				if not seen[voice.voiceID] then
					seen[voice.voiceID] = true
					table.insert(voices, voice)
				end
			end
		end
	end

	table.sort(voices, function(a, b)
		return a.name < b.name
	end)

	return voices
end

function Private.Settings.GetGlowTypesForKind(kind)
	if kind == Private.Enum.FrameKind.Self then
		return {
			Private.Enum.GlowType.PixelGlow,
			Private.Enum.GlowType.Star4,
			Private.Enum.GlowType.AutoCastGlow,
			Private.Enum.GlowType.ProcGlow,
		}
	end

	return {
		Private.Enum.GlowType.PixelGlow,
		Private.Enum.GlowType.Star4,
	}
end

table.insert(Private.LoginFnQueue, function()
	LibSharedMedia:Register(
		LibSharedMedia.MediaType.BORDER,
		"Blizzard Tooltip Border",
		"Interface\\Tooltips\\UI-Tooltip-Border"
	)

	local L = Private.L
	local settingsName = C_AddOns.GetAddOnMetadata(addonName, "Title")
	local category, layout = Settings.RegisterVerticalLayoutCategory(settingsName)

	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L.Settings.EditModeReminder))

	Settings.RegisterAddOnCategory(category)

	local function OpenSettings()
		Settings.OpenToCategory(category:GetID())
	end

	AddonCompartmentFrame:RegisterAddon({
		text = settingsName,
		icon = C_AddOns.GetAddOnMetadata(addonName, "IconTexture"),
		registerForAnyClick = true,
		notCheckable = true,
		func = OpenSettings,
		funcOnEnter = function(button)
			MenuUtil.ShowTooltip(button, function(tooltip)
				tooltip:SetText(settingsName, 1, 1, 1)
				tooltip:AddLine(L.Settings.ClickToOpenSettingsLabel)
				tooltip:AddLine(" ")

				local enabledColor = "FF00FF00"
				local disabledColor = "00FF0000"

				-- The tooltip reflects the two migrated display slots (Groups[1]=Self,
				-- Groups[2]=Party); either may have been deleted, so guard for nil.
				local selfGroup = TargetedSpellsSaved.Groups[1]
				local partyGroup = TargetedSpellsSaved.Groups[2]
				local selfEnabled = selfGroup ~= nil and selfGroup.Enabled
				local partyEnabled = partyGroup ~= nil and partyGroup.Enabled

				tooltip:AddLine(L.Settings.AddonCompartmentTooltipLine1:format(WrapTextInColorCode(
					string.lower(
					---@diagnostic disable-next-line: param-type-mismatch
						selfEnabled and L.Settings.EnabledLabel
						or L.Settings.DisabledLabel
					),
					selfEnabled and enabledColor or disabledColor
				)))
				tooltip:AddLine(L.Settings.AddonCompartmentTooltipLine2:format(WrapTextInColorCode(
					string.lower(
					---@diagnostic disable-next-line: param-type-mismatch
						partyEnabled and L.Settings.EnabledLabel
						or L.Settings.DisabledLabel
					),
					partyEnabled and enabledColor or disabledColor
				)))
			end)
		end,
		funcOnLeave = function(button)
			MenuUtil.HideTooltip(button)
		end,
	})

	Private.Utils.RegisterSlashCommand("options", L.SlashCommands.OptionsDescription, OpenSettings)
	Private.Utils.RegisterSlashCommand("settings", L.SlashCommands.SettingsDescription, OpenSettings)
end)
