---@type string, TargetedSpells
local addonName, Private = ...
local LibSharedMedia = LibStub("LibSharedMedia-3.0")

table.insert(Private.LoginFnQueue, function()
	LibSharedMedia:Register("sound", "Water Drop", "Interface\\AddOns\\TargetedSpells\\Media\\Sounds\\WaterDrop.ogg")
end)

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
		GlowImportant = "GLOW_IMPORTANT_SELF",
		GlowType = "GLOW_TYPE_SELF",
		Grow = "FRAME_GROW_SELF",
		PlaySound = "PLAY_SOUND_SELF",
		Sound = "SOUND_SELF",
		SoundChannel = "SOUND_CHANNEL_SELF",
		ShowDuration = "SHOW_DURATION_SELF",
		LoadConditionSoundContentType = "LOAD_CONDITION_SOUND_CONTENT_TYPE_SELF",
		Opacity = "OPACITY_SELF",
		ShowBorder = "BORDER_SELF",
		PlayTTS = "PLAY_TTS_SELF",
		TTSVoice = "TTS_VOICE_SELF",
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
		OffsetX = "FRAME_OFFSET_X_PARTY",
		OffsetY = "FRAME_OFFSET_Y_PARTY",
		SourceAnchor = "FRAME_SOURCE_ANCHOR_PARTY",
		TargetAnchor = "FRAME_TARGET_ANCHOR_PARTY",
		SortOrder = "FRAME_SORT_ORDER_PARTY",
		Grow = "FRAME_GROW_PARTY",
		GlowImportant = "GLOW_IMPORTANT_PARTY",
		GlowType = "GLOW_TYPE_PARTY",
		IncludeSelfInParty = "INCLUDE_SELF_IN_PARTY_PARTY",
		ShowDuration = "SHOW_DURATION_PARTY",
		Opacity = "OPACITY_PARTY",
		ShowBorder = "BORDER_PARTY",
	},
}

function Private.Settings.GetSettingsDisplayOrder(kind)
	if kind == Private.Enum.FrameKind.Self then
		return {
			Private.Settings.Keys.Self.Enabled,
			Private.Settings.Keys.Self.LoadConditionContentType,
			Private.Settings.Keys.Self.LoadConditionRole,
			Private.Settings.Keys.Self.Width,
			Private.Settings.Keys.Self.Height,
			Private.Settings.Keys.Self.Gap,
			Private.Settings.Keys.Self.Direction,
			Private.Settings.Keys.Self.SortOrder,
			Private.Settings.Keys.Self.Grow,
			Private.Settings.Keys.Self.GlowImportant,
			Private.Settings.Keys.Self.GlowType,
			Private.Settings.Keys.Self.PlaySound,
			Private.Settings.Keys.Self.Sound,
			Private.Settings.Keys.Self.SoundChannel,
			Private.Settings.Keys.Self.PlayTTS,
			Private.Settings.Keys.Self.TTSVoice,
			Private.Settings.Keys.Self.LoadConditionSoundContentType,
			Private.Settings.Keys.Self.ShowDuration,
			Private.Settings.Keys.Self.FontSize,
			Private.Settings.Keys.Self.ShowBorder,
			Private.Settings.Keys.Self.Opacity,
		}
	end

	return {
		Private.Settings.Keys.Party.Enabled,
		Private.Settings.Keys.Party.LoadConditionContentType,
		Private.Settings.Keys.Party.LoadConditionRole,
		Private.Settings.Keys.Party.IncludeSelfInParty,
		Private.Settings.Keys.Party.Width,
		Private.Settings.Keys.Party.Height,
		Private.Settings.Keys.Party.Gap,
		Private.Settings.Keys.Party.Direction,
		Private.Settings.Keys.Party.SourceAnchor,
		Private.Settings.Keys.Party.TargetAnchor,
		Private.Settings.Keys.Party.Grow,
		Private.Settings.Keys.Party.OffsetX,
		Private.Settings.Keys.Party.OffsetY,
		Private.Settings.Keys.Party.SortOrder,
		Private.Settings.Keys.Party.GlowImportant,
		Private.Settings.Keys.Party.GlowType,
		Private.Settings.Keys.Party.ShowDuration,
		Private.Settings.Keys.Party.FontSize,
		Private.Settings.Keys.Party.ShowBorder,
		Private.Settings.Keys.Party.Opacity,
	}
end

function Private.Settings.GetDefaultEditModeFramePosition()
	-- if possible, position below Encounter Warnings - Minor
	local encounterEventsEditModeSystemId = Enum.EditModeSystem.EncounterEvents
	local encounterEventsSystemMapEntry = encounterEventsEditModeSystemId
		and EDIT_MODE_MODERN_SYSTEM_MAP[encounterEventsEditModeSystemId]
	local normalWarningsIndex = Enum.EditModeEncounterEventsSystemIndices
		and Enum.EditModeEncounterEventsSystemIndices.NormalWarnings
	local normalWarningsInfo = encounterEventsSystemMapEntry
		and normalWarningsIndex
		and encounterEventsSystemMapEntry[normalWarningsIndex]

	if normalWarningsInfo and normalWarningsInfo.anchorInfo then
		return {
			point = normalWarningsInfo.anchorInfo.point,
			x = normalWarningsInfo.anchorInfo.offsetX,
			y = normalWarningsInfo.anchorInfo.offsetY - 48,
		}
	end

	return { point = "CENTER", x = 0, y = 100 }
end

function Private.Settings.GetSliderSettingsForOption(key)
	if key == Private.Settings.Keys.Self.Opacity or key == Private.Settings.Keys.Party.Opacity then
		return {
			min = 0.2,
			max = 1,
			step = 0.01,
		}
	end

	if key == Private.Settings.Keys.Self.FontSize or key == Private.Settings.Keys.Party.FontSize then
		return {
			min = 8,
			max = key == Private.Settings.Keys.Self.FontSize and 32 or 24,
			step = 1,
		}
	end

	if key == Private.Settings.Keys.Self.Width or key == Private.Settings.Keys.Self.Height then
		return {
			min = 36,
			max = 100,
			step = 1,
		}
	end

	if key == Private.Settings.Keys.Party.Width or key == Private.Settings.Keys.Party.Height then
		return {
			min = 16,
			max = 60,
			step = 1,
		}
	end

	if key == Private.Settings.Keys.Self.Gap or key == Private.Settings.Keys.Party.Gap then
		return {
			min = -10,
			max = 40,
			step = 1,
		}
	end

	if key == Private.Settings.Keys.Party.OffsetX or key == Private.Settings.Keys.Party.OffsetY then
		return {
			min = -100,
			max = 100,
			step = 1,
		}
	end

	error(
		string.format(
			"Slider Settings for key '%s' are either not implemented or you're calling this with the wrong key.",
			key
		)
	)
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
		PlaySound = true,
		Sound = "Interface\\AddOns\\TargetedSpells\\Media\\Sounds\\WaterDrop.ogg",
		SoundChannel = Private.Enum.SoundChannel.Master,
		LoadConditionSoundContentType = {
			[Private.Enum.ContentType.OpenWorld] = false,
			[Private.Enum.ContentType.Delve] = true,
			[Private.Enum.ContentType.Dungeon] = true,
			[Private.Enum.ContentType.Raid] = false,
			[Private.Enum.ContentType.Arena] = false,
			[Private.Enum.ContentType.Battleground] = false,
		},
		SortOrder = Private.Enum.SortOrder.Ascending,
		Grow = Private.Enum.Grow.Center,
		ShowDuration = true,
		FontSize = 20,
		Position = Private.Settings.GetDefaultEditModeFramePosition(),
		Opacity = 1,
		ShowBorder = false,
		GlowImportant = true,
		GlowType = Private.Enum.GlowType.PixelGlow,
		PlayTTS = false,
		TTSVoice = Private.Utils.FindAppropriateTTSVoiceId(),
	}
end

---@return SavedVariablesSettingsParty
function Private.Settings.GetPartyDefaultSettings()
	return {
		Enabled = true,
		Width = 24,
		Height = 24,
		FontSize = 14,
		Gap = 2,
		Direction = Private.Enum.Direction.Horizontal,
		LoadConditionContentType = {
			[Private.Enum.ContentType.OpenWorld] = false,
			[Private.Enum.ContentType.Delve] = true,
			[Private.Enum.ContentType.Dungeon] = true,
			[Private.Enum.ContentType.Raid] = true,
			[Private.Enum.ContentType.Arena] = true,
			[Private.Enum.ContentType.Battleground] = false,
		},
		LoadConditionRole = {
			[Private.Enum.Role.Healer] = true,
			[Private.Enum.Role.Tank] = true,
			[Private.Enum.Role.Damager] = true,
		},
		OffsetX = 0,
		OffsetY = 0,
		SourceAnchor = Private.Enum.Anchor.Left,
		TargetAnchor = Private.Enum.Anchor.Center,
		SortOrder = Private.Enum.SortOrder.Ascending,
		Grow = Private.Enum.Grow.Center,
		IncludeSelfInParty = true,
		ShowDuration = true,
		Opacity = 1,
		ShowBorder = false,
		GlowImportant = true,
		GlowType = Private.Enum.GlowType.PixelGlow,
	}
end

function Private.Settings.GetCooldownViewerSounds()
	local soundCategoryKeyToLabel = {
		Animals = COOLDOWN_VIEWER_SETTINGS_SOUND_ALERT_CATEGORY_ANIMALS,
		Devices = COOLDOWN_VIEWER_SETTINGS_SOUND_ALERT_CATEGORY_DEVICES,
		Impacts = COOLDOWN_VIEWER_SETTINGS_SOUND_ALERT_CATEGORY_IMPACTS,
		Instruments = COOLDOWN_VIEWER_SETTINGS_SOUND_ALERT_CATEGORY_INSTRUMENTS,
		War2 = COOLDOWN_VIEWER_SETTINGS_SOUND_ALERT_CATEGORY_WAR2,
		War3 = COOLDOWN_VIEWER_SETTINGS_SOUND_ALERT_CATEGORY_WAR3,
	}

	return {
		soundCategoryKeyToLabel = soundCategoryKeyToLabel,
		data = CooldownViewerSoundData,
	}
end

do
	---@type table<string|number, true>
	local soundIsFileCache = {}

	function Private.Settings.SoundIsFile(sound)
		return soundIsFileCache[sound] or false
	end

	local function CacheCustomSoundsByPath()
		local soundInfo = Private.Settings.GetCustomSoundGroups()

		for group, sounds in pairs(soundInfo.data) do
			for _, sound in pairs(sounds) do
				soundIsFileCache[sound.soundKitID] = true
			end
		end
	end

	table.insert(Private.LoginFnQueue, CacheCustomSoundsByPath)

	LibSharedMedia.RegisterCallback(Private, "LibSharedMedia_Registered", function(_, mediaType, key)
		if mediaType ~= "sound" then
			return
		end

		local path = LibSharedMedia:Fetch("sound", key)

		if path == nil or path == 1 then
			return
		end

		soundIsFileCache[path] = true
	end)
end

-- this follows the structure of `CooldownViewerSoundData` in `Blizzard_CooldownViewer/CooldownViewerSoundAlertData.lua` for ease of function reuse
function Private.Settings.GetCustomSoundGroups(groupThreshold)
	---@type SoundInfo
	local soundInfo = {
		data = {},
		soundCategoryKeyToLabel = {},
	}

	local source = LibSharedMedia:HashTable(LibSharedMedia.MediaType.SOUND)
	local groupedSounds = {}

	---@param str string
	---@param prefix string
	---@return boolean
	local function StartsWith(str, prefix)
		return str:find(prefix, 1, true) == 1
	end

	for label, path in pairs(source) do
		if path ~= 1 then
			---@type string
			local key = Private.L.Settings.SoundCategoryCustom

			if type(path) == "string" and StartsWith(path, "Interface") then
				-- path is case insensitive, normalize it
				path = path:gsub([[\Addons\]], "\\AddOns\\")

				---@type string|nil
				local maybeAddonName = path:match([[AddOns[\/]([^\/]+)]])

				if maybeAddonName then
					key = maybeAddonName
				end
			elseif StartsWith(label, "BigWigs") then -- BW ships a couple game sound id references that are still prefixed with "BigWigs: (...)"
				key = "BigWigs"
			end

			-- some sounds are labelled e.g. `Plater Steel` and get patched to only render `Steel`
			if string.find(label, key) ~= nil then
				label = label:gsub(key .. ": ", ""):gsub(key, ""):trim()
			end

			if groupedSounds[key] == nil then
				groupedSounds[key] = {}
			end

			table.insert(groupedSounds[key], {
				name = label,
				path = path,
			})
		end
	end

	for groupName, sounds in pairs(groupedSounds) do
		local needsSplitting = groupThreshold ~= nil and #sounds > groupThreshold or false
		local groupCount = 0
		local isCustomGroup = groupName == Private.L.Settings.SoundCategoryCustom
		local tableKey = groupName

		-- edit mode dropdowns need splitting as there's a max amount of elements to render within a dropdown
		if needsSplitting then
			groupCount = groupCount + 1
			tableKey = isCustomGroup and string.format("%s %d", Private.L.Settings.SoundCategoryCustom, groupCount)
				or string.format("%s %d", groupName, groupCount)
		end

		if soundInfo.data[tableKey] == nil then
			soundInfo.data[tableKey] = {}
			soundInfo.soundCategoryKeyToLabel[tableKey] = tableKey
		end

		local targetTable = soundInfo.data[tableKey]

		for _, sound in pairs(sounds) do
			if groupThreshold ~= nil then
				if #targetTable >= groupThreshold then
					groupCount = groupCount + 1

					tableKey = isCustomGroup
							and string.format("%s %d", Private.L.Settings.SoundCategoryCustom, groupCount)
						or string.format("%s %d", groupName, groupCount)

					if soundInfo.data[tableKey] == nil then
						soundInfo.data[tableKey] = {}
						soundInfo.soundCategoryKeyToLabel[tableKey] = tableKey
					end

					targetTable = soundInfo.data[tableKey]
				end
			end

			table.insert(targetTable, {
				soundKitID = sound.path,
				text = sound.name,
			})
		end
	end

	return soundInfo
end

function Private.Settings.SampleTTSVoice(voiceId)
	-- iterate spellbook until we find the first spec-connected page.
	-- play TTS for the first spell we find on that page to demo voice
	for i = 1, C_SpellBook.GetNumSpellBookSkillLines() do
		local skillLineInfo = C_SpellBook.GetSpellBookSkillLineInfo(i)

		if skillLineInfo.specID then
			for j = skillLineInfo.itemIndexOffset + 1, skillLineInfo.itemIndexOffset + skillLineInfo.numSpellBookItems do
				local spellBookItemInfo = C_SpellBook.GetSpellBookItemInfo(j, Enum.SpellBookSpellBank.Player)
				if
					spellBookItemInfo.itemType == Enum.SpellBookItemType.Spell
					or spellBookItemInfo.itemType == Enum.SpellBookItemType.FutureSpell
				then
					local name = C_Spell.GetSpellName(spellBookItemInfo.actionID)

					C_VoiceChat.SpeakText(voiceId, name, 1.5, C_TTSSettings.GetSpeechVolume())
					return
				end
			end
		end
	end
end

table.insert(Private.LoginFnQueue, function()
	local L = Private.L
	local settingsName = C_AddOns.GetAddOnMetadata(addonName, "Title")
	local category, layout = Settings.RegisterVerticalLayoutCategory(settingsName)

	---@param enum table<string, number>
	---@param IsEnabled fun(id: number): boolean
	---@return number
	local function GetMask(enum, IsEnabled)
		local mask = 0

		for label, id in pairs(enum) do
			if IsEnabled(id) then
				mask = bit.bor(mask, bit.lshift(1, id - 1))
			end
		end

		return mask
	end

	---@param value number
	---@return boolean
	local function DecodeBitToBool(mask, value)
		return bit.band(mask, bit.lshift(1, value - 1)) ~= 0
	end

	---@class SettingConfig
	---@field initializer table
	---@field hideSteppers boolean
	---@field IsSectionEnabled nil|fun(): boolean

	---@param key string
	---@param defaults SavedVariablesSettingsSelf|SavedVariablesSettingsParty
	---@return SettingConfig
	local function CreateSetting(key, defaults)
		if key == Private.Settings.Keys.Self.Enabled or key == Private.Settings.Keys.Party.Enabled then
			local tableRef = key == Private.Settings.Keys.Self.Enabled and TargetedSpellsSaved.Settings.Self
				or TargetedSpellsSaved.Settings.Party

			local function GetValue()
				return tableRef.Enabled
			end

			local function SetValue(value)
				tableRef.Enabled = not tableRef.Enabled
				Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, tableRef.Enabled)
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Boolean,
				L.Settings.EnabledLabel,
				Settings.Default.True,
				GetValue,
				SetValue
			)

			local initializer = Settings.CreateCheckbox(category, setting, L.Settings.EnabledTooltip)

			return {
				initializer = initializer,
				hideSteppers = false,
				IsSectionEnabled = nil,
			}
		end

		if key == Private.Settings.Keys.Party.IncludeSelfInParty then
			local function GetValue()
				return TargetedSpellsSaved.Settings.Party.IncludeSelfInParty
			end

			local function SetValue(value)
				TargetedSpellsSaved.Settings.Party.IncludeSelfInParty =
					not TargetedSpellsSaved.Settings.Party.IncludeSelfInParty
				Private.EventRegistry:TriggerEvent(
					Private.Enum.Events.SETTING_CHANGED,
					key,
					TargetedSpellsSaved.Settings.Party.IncludeSelfInParty
				)
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Boolean,
				L.Settings.IncludeSelfInPartyLabel,
				Settings.Default.True,
				GetValue,
				SetValue
			)

			local initializer = Settings.CreateCheckbox(category, setting, L.Settings.IncludeSelfInPartyTooltip)

			return {
				initializer = initializer,
				hideSteppers = false,
				IsSectionEnabled = nil,
			}
		end

		if key == Private.Settings.Keys.Party.TargetAnchor then
			local function GetValue()
				return TargetedSpellsSaved.Settings.Party.TargetAnchor
			end

			local function SetValue(value)
				TargetedSpellsSaved.Settings.Party.TargetAnchor = value

				Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
			end

			local function GetOptions()
				local container = Settings.CreateControlTextContainer()

				for k, v in pairs(Private.Enum.Anchor) do
					container:Add(v, k)
				end

				return container:GetData()
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.String,
				L.Settings.FrameTargetAnchorLabel,
				defaults.TargetAnchor,
				GetValue,
				SetValue
			)
			local initializer =
				Settings.CreateDropdown(category, setting, GetOptions, L.Settings.FrameTargetAnchorTooltip)

			return {
				initializer = initializer,
				hideSteppers = false,
				IsSectionEnabled = nil,
			}
		end

		if key == Private.Settings.Keys.Party.SourceAnchor then
			local function GetValue()
				return TargetedSpellsSaved.Settings.Party.SourceAnchor
			end

			local function SetValue(value)
				TargetedSpellsSaved.Settings.Party.SourceAnchor = value

				Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
			end

			local function GetOptions()
				local container = Settings.CreateControlTextContainer()

				for k, v in pairs(Private.Enum.Anchor) do
					container:Add(v, k)
				end

				return container:GetData()
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.String,
				L.Settings.FrameSourceAnchorLabel,
				defaults.SourceAnchor,
				GetValue,
				SetValue
			)
			local initializer =
				Settings.CreateDropdown(category, setting, GetOptions, L.Settings.FrameSourceAnchorTooltip)
			return {
				initializer = initializer,
				hideSteppers = false,
				IsSectionEnabled = nil,
			}
		end

		if key == Private.Settings.Keys.Party.OffsetY then
			local sliderSettings = Private.Settings.GetSliderSettingsForOption(key)

			local function GetValue()
				return TargetedSpellsSaved.Settings.Party.OffsetY
			end

			local function SetValue(value)
				if value ~= TargetedSpellsSaved.Settings.Party.OffsetY then
					TargetedSpellsSaved.Settings.Party.OffsetY = value

					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				L.Settings.FrameOffsetYLabel,
				defaults.OffsetY,
				GetValue,
				SetValue
			)
			local options = Settings.CreateSliderOptions(sliderSettings.min, sliderSettings.max, sliderSettings.step)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)

			local initializer = Settings.CreateSlider(category, setting, options, L.Settings.FrameOffsetYTooltip)

			return {
				initializer = initializer,
				hideSteppers = false,
				IsSectionEnabled = nil,
			}
		end

		if key == Private.Settings.Keys.Party.OffsetX then
			local sliderSettings = Private.Settings.GetSliderSettingsForOption(key)

			local function GetValue()
				return TargetedSpellsSaved.Settings.Party.OffsetX
			end

			local function SetValue(value)
				if value ~= TargetedSpellsSaved.Settings.Party.OffsetX then
					TargetedSpellsSaved.Settings.Party.OffsetX = value

					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				L.Settings.FrameOffsetXLabel,
				defaults.OffsetX,
				GetValue,
				SetValue
			)
			local options = Settings.CreateSliderOptions(sliderSettings.min, sliderSettings.max, sliderSettings.step)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)

			local initializer = Settings.CreateSlider(category, setting, options, L.Settings.FrameOffsetXTooltip)

			return {
				initializer = initializer,
				hideSteppers = false,
				IsSectionEnabled = nil,
			}
		end

		if key == Private.Settings.Keys.Self.Opacity or key == Private.Settings.Keys.Party.Opacity then
			local tableRef = key == Private.Settings.Keys.Self.Opacity and TargetedSpellsSaved.Settings.Self
				or TargetedSpellsSaved.Settings.Party
			local sliderSettings = Private.Settings.GetSliderSettingsForOption(key)

			local function GetValue()
				return tableRef.Opacity
			end

			local function SetValue(value)
				if value ~= tableRef.Opacity then
					tableRef.Opacity = value

					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				L.Settings.OpacityLabel,
				defaults.Opacity,
				GetValue,
				SetValue
			)
			local options = Settings.CreateSliderOptions(sliderSettings.min, sliderSettings.max, sliderSettings.step)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, FormatPercentage)

			local initializer = Settings.CreateSlider(category, setting, options, L.Settings.OpacityTooltip)

			return {
				initializer = initializer,
				hideSteppers = false,
				IsSectionEnabled = nil,
			}
		end

		if key == Private.Settings.Keys.Self.ShowBorder or key == Private.Settings.Keys.Party.ShowBorder then
			local tableRef = key == Private.Settings.Keys.Self.ShowBorder and TargetedSpellsSaved.Settings.Self
				or TargetedSpellsSaved.Settings.Party

			local function GetValue()
				return tableRef.ShowBorder
			end

			local function SetValue(value)
				tableRef.ShowBorder = not tableRef.ShowBorder
				Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, tableRef.ShowBorder)
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Boolean,
				L.Settings.ShowBorderLabel,
				defaults.ShowBorder,
				GetValue,
				SetValue
			)

			local initializer = Settings.CreateCheckbox(category, setting, L.Settings.ShowBorderTooltip)

			return {
				initializer = initializer,
				hideSteppers = false,
				IsSectionEnabled = nil,
			}
		end

		if key == Private.Settings.Keys.Self.ShowDuration or key == Private.Settings.Keys.Party.ShowDuration then
			local tableRef = key == Private.Settings.Keys.Self.ShowDuration and TargetedSpellsSaved.Settings.Self
				or TargetedSpellsSaved.Settings.Party

			local function GetValue()
				return tableRef.ShowDuration
			end

			local function SetValue(value)
				tableRef.ShowDuration = not tableRef.ShowDuration
				Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, tableRef.ShowDuration)
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Boolean,
				L.Settings.ShowDurationLabel,
				defaults.ShowDuration,
				GetValue,
				SetValue
			)

			local initializer = Settings.CreateCheckbox(category, setting, L.Settings.ShowDurationTooltip)

			return {
				initializer = initializer,
				hideSteppers = false,
				IsSectionEnabled = nil,
			}
		end

		if key == Private.Settings.Keys.Self.PlayTTS then
			local function GetValue()
				return TargetedSpellsSaved.Settings.Self.PlayTTS
			end

			local function SetValue(value)
				TargetedSpellsSaved.Settings.Self.PlayTTS = not TargetedSpellsSaved.Settings.Self.PlayTTS
				Private.EventRegistry:TriggerEvent(
					Private.Enum.Events.SETTING_CHANGED,
					key,
					TargetedSpellsSaved.Settings.Self.PlayTTS
				)
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Boolean,
				L.Settings.PlayTTSLabel,
				defaults.PlayTTS,
				GetValue,
				SetValue
			)
			local initializer = Settings.CreateCheckbox(category, setting, L.Settings.PlayTTSTooltip)

			return {
				initializer = initializer,
				hideSteppers = false,
				IsSectionEnabled = nil,
			}
		end

		if key == Private.Settings.Keys.Self.LoadConditionSoundContentType then
			if Private.IsMidnight then
				local defaultValue = GetMask(Private.Enum.ContentType, function(id)
					return defaults.LoadConditionSoundContentType[id]
				end)

				local function GetValue()
					return GetMask(Private.Enum.ContentType, function(id)
						return TargetedSpellsSaved.Settings.Self.LoadConditionSoundContentType[id]
					end)
				end

				local function SetValue(mask)
					local hasChanges = false
					local anyEnabled = false

					for label, id in pairs(Private.Enum.ContentType) do
						local enabled = DecodeBitToBool(mask, id)

						if enabled ~= TargetedSpellsSaved.Settings.Self.LoadConditionSoundContentType[id] then
							TargetedSpellsSaved.Settings.Self.LoadConditionSoundContentType[id] = enabled
							hasChanges = true
						end

						if enabled then
							anyEnabled = true
						end
					end

					if not hasChanges then
						return
					end

					Private.EventRegistry:TriggerEvent(
						Private.Enum.Events.SETTING_CHANGED,
						key,
						TargetedSpellsSaved.Settings.Self.LoadConditionSoundContentType
					)

					if anyEnabled ~= TargetedSpellsSaved.Settings.Self.PlaySound then
						TargetedSpellsSaved.Settings.Self.PlaySound = anyEnabled
						Private.EventRegistry:TriggerEvent(
							Private.Enum.Events.SETTING_CHANGED,
							Private.Settings.Keys.Self.PlaySound,
							anyEnabled
						)
					end
				end

				local setting = Settings.RegisterProxySetting(
					category,
					key,
					Settings.VarType.Number,
					L.Settings.LoadConditionSoundContentTypeLabel,
					defaultValue,
					GetValue,
					SetValue
				)

				local function GetOptions()
					local container = Settings.CreateControlTextContainer()

					for label, id in pairs(Private.Enum.ContentType) do
						local function IsEnabled()
							return TargetedSpellsSaved.Settings.Self.LoadConditionSoundContentType[id]
						end

						local function Toggle()
							TargetedSpellsSaved.Settings.Self.LoadConditionSoundContentType[id] =
								not TargetedSpellsSaved.Settings.Self.LoadConditionSoundContentType[id]
						end

						local translated = L.Settings.LoadConditionSoundContentTypeLabels[id]

						container:AddCheckbox(
							id,
							translated,
							L.Settings.LoadConditionSoundContentTypeTooltip,
							IsEnabled,
							Toggle
						)
					end

					return container:GetData()
				end

				local initializer = Settings.CreateDropdown(
					category,
					setting,
					GetOptions,
					L.Settings.LoadConditionSoundContentTypeTooltip
				)

				return {
					initializer = initializer,
					hideSteppers = true,
					IsSectionEnabled = nil,
				}
			end

			local function GetValue()
				return 0
			end

			local function SetValue() end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				L.Settings.LoadConditionSoundContentTypeLabel,
				0,
				GetValue,
				SetValue
			)

			local function GetOptions()
				local container = Settings.CreateControlTextContainer()

				for label, id in pairs(Private.Enum.ContentType) do
					local translated = L.Settings.LoadConditionSoundContentTypeLabels[id]

					container:Add(id, translated, L.Settings.LoadConditionSoundContentTypeTooltip)
				end

				return container:GetData()
			end

			local initializer =
				Settings.CreateDropdown(category, setting, GetOptions, L.Settings.LoadConditionSoundContentTypeTooltip)

			return {
				initializer = initializer,
				hideSteppers = true,
				IsSectionEnabled = function()
					return false
				end,
			}
		end

		if key == Private.Settings.Keys.Self.TTSVoice then
			local function GetValue()
				return TargetedSpellsSaved.Settings.Self.TTSVoice
			end

			local function SetValue(value)
				TargetedSpellsSaved.Settings.Self.TTSVoice = value
				Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)

				Private.Settings.SampleTTSVoice(value)
			end

			local function GetOptions()
				local container = Settings.CreateControlTextContainer()

				for _, voice in pairs(C_VoiceChat.GetTtsVoices()) do
					container:Add(voice.voiceID, voice.name)
				end

				return container:GetData()
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				L.Settings.TTSVoiceLabel,
				defaults.TTSVoice or 0,
				GetValue,
				SetValue
			)
			local initializer = Settings.CreateDropdown(category, setting, GetOptions, L.Settings.TTSVoiceTooltip)

			return {
				initializer = initializer,
				hideSteppers = false,
				IsSectionEnabled = nil,
			}
		end

		if key == Private.Settings.Keys.Self.SoundChannel then
			local function GetValue()
				return TargetedSpellsSaved.Settings.Self.SoundChannel
			end

			local function SetValue(value)
				TargetedSpellsSaved.Settings.Self.SoundChannel = value

				Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
			end

			local function GetOptions()
				local container = Settings.CreateControlTextContainer()

				for label, value in pairs(Private.Enum.SoundChannel) do
					local translated = L.Settings.SoundChannelLabels[value]
					container:Add(value, translated)
				end

				return container:GetData()
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.String,
				L.Settings.SoundChannelLabel,
				defaults.SoundChannel,
				GetValue,
				SetValue
			)
			local initializer = Settings.CreateDropdown(category, setting, GetOptions, L.Settings.SoundChannelTooltip)

			return {
				initializer = initializer,
				hideSteppers = false,
				IsSectionEnabled = nil,
			}
		end

		if key == Private.Settings.Keys.Self.Sound then
			local function GetValue()
				return tostring(TargetedSpellsSaved.Settings.Self.Sound)
			end

			local function IsNumeric(str)
				return tonumber(str) ~= nil
			end

			local function SetValue(value)
				local sound = IsNumeric(value) and tonumber(value) or value

				Private.Utils.AttemptToPlaySound(sound, Private.Enum.SoundChannel.Master)

				if TargetedSpellsSaved.Settings.Self.Sound ~= sound then
					TargetedSpellsSaved.Settings.Self.Sound = sound

					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, sound)
				end
			end

			---@param soundCategoryKeyToText table<string, string>
			---@param currentTable table<string, CustomSound[]> | CustomSound[]
			---@param categoryName string?
			local function RecursiveAddSounds(container, soundCategoryKeyToText, currentTable, categoryName)
				for tableKey, value in pairs(currentTable) do
					if value.soundKitID and value.text then
						container:Add(tostring(value.soundKitID), string.format("%s - %s", categoryName, value.text))
					elseif type(value) == "table" and soundCategoryKeyToText[tableKey] then
						RecursiveAddSounds(container, soundCategoryKeyToText, value, soundCategoryKeyToText[tableKey])
					end
				end
			end

			local function AddCooldownViewerSounds(container)
				local soundInfo = Private.Settings.GetCooldownViewerSounds()

				RecursiveAddSounds(container, soundInfo.soundCategoryKeyToLabel, soundInfo.data)
			end

			local function AddCustomSounds(container)
				local soundInfo = Private.Settings.GetCustomSoundGroups()

				RecursiveAddSounds(container, soundInfo.soundCategoryKeyToLabel, soundInfo.data)
			end

			local function GetOptions()
				local container = Settings.CreateControlTextContainer()

				pcall(AddCooldownViewerSounds, container)
				AddCustomSounds(container)

				return container:GetData()
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.String,
				L.Settings.SoundLabel,
				tostring(defaults.Sound),
				GetValue,
				SetValue
			)
			local initializer = Settings.CreateDropdown(category, setting, GetOptions, L.Settings.SoundTooltip)

			return {
				initializer = initializer,
				hideSteppers = false,
				IsSectionEnabled = nil,
			}
		end

		if key == Private.Settings.Keys.Self.PlaySound then
			local function GetValue()
				return TargetedSpellsSaved.Settings.Self.PlaySound
			end

			local function SetValue(value)
				TargetedSpellsSaved.Settings.Self.PlaySound = not TargetedSpellsSaved.Settings.Self.PlaySound
				Private.EventRegistry:TriggerEvent(
					Private.Enum.Events.SETTING_CHANGED,
					key,
					TargetedSpellsSaved.Settings.Self.PlaySound
				)
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Boolean,
				L.Settings.PlaySoundLabel,
				defaults.PlaySound,
				GetValue,
				SetValue
			)
			local initializer = Settings.CreateCheckbox(category, setting, L.Settings.PlaySoundTooltip)

			return {
				initializer = initializer,
				hideSteppers = false,
				IsSectionEnabled = nil,
			}
		end

		if key == Private.Settings.Keys.Self.GlowType or key == Private.Settings.Keys.Party.GlowType then
			local tableRef = key == Private.Settings.Keys.Self.GlowType and TargetedSpellsSaved.Settings.Self
				or TargetedSpellsSaved.Settings.Party

			local function GetValue()
				return tableRef.GlowType
			end

			local function SetValue(value)
				tableRef.GlowType = value

				Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
			end

			local function GetOptions()
				local container = Settings.CreateControlTextContainer()

				for label, id in pairs(Private.Enum.GlowType) do
					local translated = L.Settings.GlowTypeLabels[id]

					container:Add(id, translated)
				end

				return container:GetData()
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				L.Settings.GlowTypeLabel,
				defaults.GlowType,
				GetValue,
				SetValue
			)
			local initializer = Settings.CreateDropdown(category, setting, GetOptions, L.Settings.GlowTypeTooltip)

			return {
				initializer = initializer,
				hideSteppers = false,
				IsSectionEnabled = nil,
			}
		end

		if key == Private.Settings.Keys.Self.GlowImportant or key == Private.Settings.Keys.Party.GlowImportant then
			local tableRef = key == Private.Settings.Keys.Self.GlowImportant and TargetedSpellsSaved.Settings.Self
				or TargetedSpellsSaved.Settings.Party

			local function GetValue()
				return tableRef.GlowImportant
			end

			local function SetValue(value)
				tableRef.GlowImportant = not tableRef.GlowImportant
				Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, tableRef.GlowImportant)
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Boolean,
				L.Settings.GlowImportantLabel,
				defaults.GlowImportant,
				GetValue,
				SetValue
			)
			local initializer = Settings.CreateCheckbox(category, setting, L.Settings.GlowImportantTooltip)

			return {
				initializer = initializer,
				hideSteppers = false,
				IsSectionEnabled = nil,
			}
		end

		if key == Private.Settings.Keys.Self.Grow or key == Private.Settings.Keys.Party.Grow then
			local tableRef = key == Private.Settings.Keys.Self.Grow and TargetedSpellsSaved.Settings.Self
				or TargetedSpellsSaved.Settings.Party

			local function GetValue()
				return tableRef.Grow
			end

			local function SetValue(value)
				tableRef.Grow = value

				Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
			end

			local function GetOptions()
				local container = Settings.CreateControlTextContainer()

				for label, id in pairs(Private.Enum.Grow) do
					local translated = L.Settings.FrameGrowLabels[id]
					container:Add(id, translated)
				end

				return container:GetData()
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				L.Settings.FrameGrowLabel,
				defaults.Grow,
				GetValue,
				SetValue
			)
			local initializer = Settings.CreateDropdown(category, setting, GetOptions, L.Settings.FrameGrowTooltip)

			return {
				initializer = initializer,
				hideSteppers = false,
				IsSectionEnabled = nil,
			}
		end

		if key == Private.Settings.Keys.Self.SortOrder or key == Private.Settings.Keys.Party.SortOrder then
			local tableRef = key == Private.Settings.Keys.Self.SortOrder and TargetedSpellsSaved.Settings.Self
				or TargetedSpellsSaved.Settings.Party

			local function GetValue()
				return tableRef.SortOrder
			end

			local function SetValue(value)
				tableRef.SortOrder = value
				Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
			end

			local function GetOptions()
				local container = Settings.CreateControlTextContainer()

				for label, id in pairs(Private.Enum.SortOrder) do
					local translated = id == Private.Enum.SortOrder.Ascending and L.Settings.FrameSortOrderAscending
						or L.Settings.FrameSortOrderDescending
					container:Add(id, translated)
				end

				return container:GetData()
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				L.Settings.FrameSortOrderLabel,
				defaults.SortOrder,
				GetValue,
				SetValue
			)
			local initializer = Settings.CreateDropdown(category, setting, GetOptions, L.Settings.FrameSortOrderTooltip)

			return {
				initializer = initializer,
				hideSteppers = false,
				IsSectionEnabled = nil,
			}
		end

		if key == Private.Settings.Keys.Self.Direction or key == Private.Settings.Keys.Party.Direction then
			local tableRef = key == Private.Settings.Keys.Self.Direction and TargetedSpellsSaved.Settings.Self
				or TargetedSpellsSaved.Settings.Party

			local function GetValue()
				return tableRef.Direction
			end

			local function SetValue(value)
				tableRef.Direction = value

				Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
			end

			local function GetOptions()
				local container = Settings.CreateControlTextContainer()

				for label, id in pairs(Private.Enum.Direction) do
					local translated = id == Private.Enum.Direction.Horizontal and L.Settings.FrameDirectionHorizontal
						or L.Settings.FrameDirectionVertical
					container:Add(id, translated)
				end

				return container:GetData()
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				L.Settings.FrameDirectionLabel,
				defaults.Direction,
				GetValue,
				SetValue
			)
			local initializer = Settings.CreateDropdown(category, setting, GetOptions, L.Settings.FrameDirectionTooltip)

			return {
				initializer = initializer,
				hideSteppers = false,
				IsSectionEnabled = nil,
			}
		end

		if key == Private.Settings.Keys.Self.Gap or key == Private.Settings.Keys.Party.Gap then
			local sliderSettings = Private.Settings.GetSliderSettingsForOption(key)
			local tableRef = key == Private.Settings.Keys.Self.Gap and TargetedSpellsSaved.Settings.Self
				or TargetedSpellsSaved.Settings.Party

			local function GetValue()
				return tableRef.Gap
			end

			local function SetValue(value)
				if value ~= tableRef.Gap then
					tableRef.Gap = value

					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				L.Settings.FrameGapLabel,
				defaults.Gap,
				GetValue,
				SetValue
			)
			local options = Settings.CreateSliderOptions(sliderSettings.min, sliderSettings.max, sliderSettings.step)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)

			local initializer = Settings.CreateSlider(category, setting, options, L.Settings.FrameGapTooltip)

			return {
				initializer = initializer,
				hideSteppers = false,
				IsSectionEnabled = nil,
			}
		end

		if key == Private.Settings.Keys.Self.FontSize or key == Private.Settings.Keys.Party.FontSize then
			local sliderSettings = Private.Settings.GetSliderSettingsForOption(key)
			local tableRef = key == Private.Settings.Keys.Self.FontSize and TargetedSpellsSaved.Settings.Self
				or TargetedSpellsSaved.Settings.Party

			local function GetValue()
				return tableRef.FontSize
			end

			local function SetValue(value)
				if value ~= tableRef.FontSize then
					tableRef.FontSize = value

					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				L.Settings.FontSizeLabel,
				defaults.FontSize,
				GetValue,
				SetValue
			)
			local options = Settings.CreateSliderOptions(sliderSettings.min, sliderSettings.max, sliderSettings.step)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)

			local initializer = Settings.CreateSlider(category, setting, options, L.Settings.FontSizeTooltip)

			return {
				initializer = initializer,
				hideSteppers = false,
				IsSectionEnabled = nil,
			}
		end

		if key == Private.Settings.Keys.Self.Height or key == Private.Settings.Keys.Party.Height then
			local sliderSettings = Private.Settings.GetSliderSettingsForOption(key)
			local tableRef = key == Private.Settings.Keys.Self.Height and TargetedSpellsSaved.Settings.Self
				or TargetedSpellsSaved.Settings.Party

			local function GetValue()
				return tableRef.Height
			end

			local function SetValue(value)
				if tableRef.Height ~= value then
					tableRef.Height = value

					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				L.Settings.FrameHeightLabel,
				defaults.Height,
				GetValue,
				SetValue
			)
			local options = Settings.CreateSliderOptions(sliderSettings.min, sliderSettings.max, sliderSettings.step)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)

			local initializer = Settings.CreateSlider(category, setting, options, L.Settings.FrameHeightTooltip)

			return {
				initializer = initializer,
				hideSteppers = false,
				IsSectionEnabled = nil,
			}
		end

		if key == Private.Settings.Keys.Self.Width or key == Private.Settings.Keys.Party.Width then
			local sliderSettings = Private.Settings.GetSliderSettingsForOption(key)
			local tableRef = key == Private.Settings.Keys.Self.Width and TargetedSpellsSaved.Settings.Self
				or TargetedSpellsSaved.Settings.Party

			local function GetValue()
				return tableRef.Width
			end

			local function SetValue(value)
				if value ~= tableRef.Width then
					tableRef.Width = value

					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				L.Settings.FrameWidthLabel,
				defaults.Width,
				GetValue,
				SetValue
			)
			local options = Settings.CreateSliderOptions(sliderSettings.min, sliderSettings.max, sliderSettings.step)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)

			local initializer = Settings.CreateSlider(category, setting, options, L.Settings.FrameWidthTooltip)

			return {
				initializer = initializer,
				hideSteppers = false,
				IsSectionEnabled = nil,
			}
		end

		if
			key == Private.Settings.Keys.Self.LoadConditionRole
			or key == Private.Settings.Keys.Party.LoadConditionRole
		then
			if Private.IsMidnight then
				local isSelf = key == Private.Settings.Keys.Self.LoadConditionRole
				local kindTableRef = isSelf and TargetedSpellsSaved.Settings.Self or TargetedSpellsSaved.Settings.Party

				local defaultValue = GetMask(Private.Enum.Role, function(id)
					return defaults.LoadConditionRole[id]
				end)

				local function GetValue()
					return GetMask(Private.Enum.Role, function(id)
						return kindTableRef.LoadConditionRole[id]
					end)
				end

				local function SetValue(mask)
					local hasChanges = false
					local anyEnabled = false

					for label, id in pairs(Private.Enum.Role) do
						local enabled = DecodeBitToBool(mask, id)

						if enabled ~= kindTableRef.LoadConditionRole[id] then
							kindTableRef.LoadConditionRole[id] = enabled
							hasChanges = true
						end

						if enabled then
							anyEnabled = true
						end
					end

					if not hasChanges then
						return
					end

					Private.EventRegistry:TriggerEvent(
						Private.Enum.Events.SETTING_CHANGED,
						key,
						kindTableRef.LoadConditionRole
					)

					if anyEnabled ~= kindTableRef.Enabled then
						kindTableRef.Enabled = anyEnabled
						Private.EventRegistry:TriggerEvent(
							Private.Enum.Events.SETTING_CHANGED,
							isSelf and Private.Settings.Keys.Self.Enabled or Private.Settings.Keys.Party.Enabled,
							anyEnabled
						)
					end
				end

				local setting = Settings.RegisterProxySetting(
					category,
					key,
					Settings.VarType.Number,
					L.Settings.LoadConditionRoleLabel,
					defaultValue,
					GetValue,
					SetValue
				)

				local function GetOptions()
					local container = Settings.CreateControlTextContainer()

					for label, id in pairs(Private.Enum.Role) do
						local translated = L.Settings.LoadConditionRoleLabels[id]

						container:AddCheckbox(id, translated, L.Settings.LoadConditionRoleTooltip)
					end

					return container:GetData()
				end

				local initializer =
					Settings.CreateDropdown(category, setting, GetOptions, L.Settings.LoadConditionRoleTooltip)

				return {
					initializer = initializer,
					hideSteppers = true,
					IsSectionEnabled = nil,
				}
			end

			local function GetValue()
				return 0
			end

			local function SetValue() end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				L.Settings.LoadConditionRoleLabel,
				0,
				GetValue,
				SetValue
			)

			local function GetOptions()
				local container = Settings.CreateControlTextContainer()

				for label, id in pairs(Private.Enum.Role) do
					local translated = L.Settings.LoadConditionRoleLabels[id]

					container:Add(id, translated, L.Settings.LoadConditionRoleTooltip)
				end

				return container:GetData()
			end

			local initializer =
				Settings.CreateDropdown(category, setting, GetOptions, L.Settings.LoadConditionRoleTooltip)

			return {
				initializer = initializer,
				hideSteppers = true,
				IsSectionEnabled = function()
					return false
				end,
			}
		end

		if
			key == Private.Settings.Keys.Self.LoadConditionContentType
			or key == Private.Settings.Keys.Party.LoadConditionContentType
		then
			if Private.IsMidnight then
				local isSelf = key == Private.Settings.Keys.Self.LoadConditionContentType
				local kindTableRef = isSelf and TargetedSpellsSaved.Settings.Self or TargetedSpellsSaved.Settings.Party

				local defaultValue = GetMask(Private.Enum.ContentType, function(id)
					return defaults.LoadConditionContentType[id]
				end)

				local function GetValue()
					return GetMask(Private.Enum.ContentType, function(id)
						return kindTableRef.LoadConditionContentType[id]
					end)
				end

				local function SetValue(mask)
					local hasChanges = false
					local anyEnabled = false

					for label, id in pairs(Private.Enum.ContentType) do
						local enabled = DecodeBitToBool(mask, id)

						if enabled ~= kindTableRef.LoadConditionContentType[id] then
							kindTableRef.LoadConditionContentType[id] = enabled
							hasChanges = true
						end

						if enabled then
							anyEnabled = true
						end
					end

					if not hasChanges then
						return
					end

					Private.EventRegistry:TriggerEvent(
						Private.Enum.Events.SETTING_CHANGED,
						key,
						kindTableRef.LoadConditionContentType
					)

					if anyEnabled ~= kindTableRef.Enabled then
						kindTableRef.Enabled = anyEnabled
						Private.EventRegistry:TriggerEvent(
							Private.Enum.Events.SETTING_CHANGED,
							isSelf and Private.Settings.Keys.Self.Enabled or Private.Settings.Keys.Party.Enabled,
							anyEnabled
						)
					end
				end

				local setting = Settings.RegisterProxySetting(
					category,
					key,
					Settings.VarType.Number,
					L.Settings.LoadConditionContentTypeLabel,
					defaultValue,
					GetValue,
					SetValue
				)

				local function GetOptions()
					local container = Settings.CreateControlTextContainer()

					for label, id in pairs(Private.Enum.ContentType) do
						local function IsEnabled()
							return kindTableRef.LoadConditionContentType[id]
						end

						local function Toggle()
							kindTableRef.LoadConditionContentType[id] = not kindTableRef.LoadConditionContentType[id]
						end

						local translated = L.Settings.LoadConditionContentTypeLabels[id]

						container:AddCheckbox(
							id,
							translated,
							L.Settings.LoadConditionContentTypeTooltip,
							IsEnabled,
							Toggle
						)
					end

					return container:GetData()
				end

				local initializer =
					Settings.CreateDropdown(category, setting, GetOptions, L.Settings.LoadConditionContentTypeTooltip)

				return {
					initializer = initializer,
					hideSteppers = true,
					IsSectionEnabled = nil,
				}
			end

			local function GetValue()
				return 0
			end

			local function SetValue() end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				L.Settings.LoadConditionContentTypeLabel,
				0,
				GetValue,
				SetValue
			)

			local function GetOptions()
				local container = Settings.CreateControlTextContainer()

				for label, id in pairs(Private.Enum.ContentType) do
					local translated = L.Settings.LoadConditionRoleLabels[id]

					container:Add(id, translated, L.Settings.LoadConditionContentTypeTooltip)
				end

				return container:GetData()
			end

			local initializer =
				Settings.CreateDropdown(category, setting, GetOptions, L.Settings.LoadConditionContentTypeTooltip)

			return {
				initializer = initializer,
				hideSteppers = true,
				IsSectionEnabled = function()
					return false
				end,
			}
		end

		error(string.format("CreateSetting not implemented for key '%s'", key))
	end

	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Self"))

	do
		local generalCategoryEnabledInitializer

		local function IsSectionEnabled()
			return TargetedSpellsSaved.Settings.Self.Enabled
		end

		local settingsOrder = Private.Settings.GetSettingsDisplayOrder(Private.Enum.FrameKind.Self)
		local defaults = Private.Settings.GetSelfDefaultSettings()

		for i, key in ipairs(settingsOrder) do
			local config = CreateSetting(key, defaults)

			if key == Private.Settings.Keys.Self.Enabled then
				generalCategoryEnabledInitializer = config.initializer
			else
				if config.hideSteppers then
					config.initializer.hideSteppers = true
				end

				config.initializer:SetParentInitializer(
					generalCategoryEnabledInitializer,
					config.IsSectionEnabled or IsSectionEnabled
				)
			end
		end
	end

	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Party"))

	do
		local generalCategoryEnabledInitializer

		local function IsSectionEnabled()
			return TargetedSpellsSaved.Settings.Party.Enabled
		end

		local settingsOrder = Private.Settings.GetSettingsDisplayOrder(Private.Enum.FrameKind.Party)
		local defaults = Private.Settings.GetPartyDefaultSettings()

		for i, key in ipairs(settingsOrder) do
			local config = CreateSetting(key, defaults)

			if key == Private.Settings.Keys.Party.Enabled then
				generalCategoryEnabledInitializer = config.initializer
			else
				if config.hideSteppers then
					config.initializer.hideSteppers = true
				end

				config.initializer:SetParentInitializer(
					generalCategoryEnabledInitializer,
					config.IsSectionEnabled or IsSectionEnabled
				)
			end
		end
	end

	Settings.RegisterAddOnCategory(category)

	local function OpenSettings()
		Settings.OpenToCategory(category.ID)
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

				tooltip:AddLine(L.Settings.AddonCompartmentTooltipLine1:format(WrapTextInColorCode(
					string.lower(
						---@diagnostic disable-next-line: param-type-mismatch
						TargetedSpellsSaved.Settings.Self.Enabled and L.Settings.EnabledLabel
							or L.Settings.DisabledLabel
					),
					TargetedSpellsSaved.Settings.Self.Enabled and enabledColor or disabledColor
				)))
				tooltip:AddLine(L.Settings.AddonCompartmentTooltipLine2:format(WrapTextInColorCode(
					string.lower(
						---@diagnostic disable-next-line: param-type-mismatch
						TargetedSpellsSaved.Settings.Party.Enabled and L.Settings.EnabledLabel
							or L.Settings.DisabledLabel
					),
					TargetedSpellsSaved.Settings.Party.Enabled and enabledColor or disabledColor
				)))
			end)
		end,
		funcOnLeave = function(button)
			MenuUtil.HideTooltip(button)
		end,
	})

	local uppercased = string.upper(settingsName)
	local lowercased = string.lower(settingsName)

	SlashCmdList[uppercased] = function(message)
		local command, rest = message:match("^(%S+)%s*(.*)$")

		if command == "options" or command == "settings" then
			OpenSettings()
		end
	end

	_G[string.format("SLASH_%s1", uppercased)] = string.format("/%s", lowercased)
end)
