---@type string, TargetedSpells
local addonName, Private = ...
local LibSharedMedia = LibStub("LibSharedMedia-3.0")

---@class TargetedSpellsSettings
Private.Settings = {}

function Private.Settings.GetDefaultEditModeFramePosition(kind)
	if kind == Private.Enum.FrameKind.Self then
		return { point = "CENTER", x = 0, y = 100 }
	end

	return { point = "CENTER", x = 0, y = 325 }
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

				-- Migrated groups may have been deleted.
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
