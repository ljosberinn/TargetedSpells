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
		OffsetX = "FRAME_OFFSET_X_SELF",
		OffsetY = "FRAME_OFFSET_Y_SELF",
		SortOrder = "FRAME_SORT_ORDER_SELF",
		GlowImportant = "GLOW_IMPORTANT_SELF",
		Grow = "FRAME_GROW_SELF",
		PlaySound = "PLAY_SOUND_SELF",
		Sound = "SOUND_SELF",
		SoundChannel = "SOUND_CHANNEL_SELF",
		ShowDuration = "SHOW_DURATION_SELF",
		MaxFrames = "MAX_FRAMES_SELF",
		Opacity = "OPACITY_SELF",
		ShowBorder = "BORDER_SELF",
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
		IncludeSelfInParty = "INCLUDE_SELF_IN_PARTY_PARTY",
		ShowDuration = "SHOW_DURATION_PARTY",
		Opacity = "OPACITY_PARTY",
		ShowBorder = "BORDER_PARTY",
	},
}

-- todo: streamline edit mode and general settings
function Private.Settings.GetSettingsDisplayOrder(kind)
	if kind == Private.Enum.FrameKind.Self then
		return {}
	end

	return {}
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

	return { point = "CENTER", x = 0, y = 0 }
end

function Private.Settings.GetSliderSettingsForOption(key)
	if key == Private.Settings.Keys.Self.MaxFrames then
		return {
			min = 1,
			max = 10,
			step = 1,
		}
	end

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
			step = 2,
		}
	end

	if key == Private.Settings.Keys.Party.Width or key == Private.Settings.Keys.Party.Height then
		return {
			min = 16,
			max = 60,
			step = 2,
		}
	end

	if key == Private.Settings.Keys.Self.Gap or key == Private.Settings.Keys.Party.Gap then
		return {
			min = -10,
			max = 40,
			step = 2,
		}
	end

	if key == Private.Settings.Keys.Party.OffsetX or key == Private.Settings.Keys.Party.OffsetY then
		return {
			min = -100,
			max = 100,
			step = 2,
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
		FontSize = 20,
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
		Position = Private.Settings.GetDefaultEditModeFramePosition(),
		MaxFrames = 5,
		Opacity = 1,
		ShowBorder = false,
		GlowImportant = true,
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

			table.insert(targetTable, { soundKitID = sound.path, text = sound.name })
		end
	end

	return soundInfo
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

	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Self"))

	do
		local generalCategoryEnabledInitializer

		local function IsSectionEnabled()
			return TargetedSpellsSaved.Settings.Self.Enabled
		end

		-- Enabled
		do
			local key = Private.Settings.Keys.Self.Enabled

			local function SetValue(value)
				TargetedSpellsSaved.Settings.Self.Enabled = not TargetedSpellsSaved.Settings.Self.Enabled
				Private.EventRegistry:TriggerEvent(
					Private.Enum.Events.SETTING_CHANGED,
					key,
					TargetedSpellsSaved.Settings.Self.Enabled
				)
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Boolean,
				L.Settings.EnabledLabel,
				Settings.Default.True,
				IsSectionEnabled,
				SetValue
			)
			generalCategoryEnabledInitializer = Settings.CreateCheckbox(category, setting, L.Settings.EnabledTooltip)
		end

		-- Load Condition Content Type
		do
			local key = Private.Settings.Keys.Self.LoadConditionContentType
			local defaults = Private.Settings.GetSelfDefaultSettings().LoadConditionContentType

			local defaultValue = GetMask(Private.Enum.ContentType, function(id)
				return defaults[id]
			end)

			local function GetValue()
				return GetMask(Private.Enum.ContentType, function(id)
					return TargetedSpellsSaved.Settings.Self.LoadConditionContentType[id]
				end)
			end

			local function SetValue(mask)
				local hasChanges = false

				for label, id in pairs(Private.Enum.ContentType) do
					local enabled = DecodeBitToBool(mask, id)

					if enabled ~= TargetedSpellsSaved.Settings.Self.LoadConditionContentType[id] then
						TargetedSpellsSaved.Settings.Self.LoadConditionContentType[id] = enabled
						hasChanges = true
					end
				end

				if hasChanges then
					Private.EventRegistry:TriggerEvent(
						Private.Enum.Events.SETTING_CHANGED,
						key,
						TargetedSpellsSaved.Settings.Self.LoadConditionContentType
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
						return TargetedSpellsSaved.Settings.Self.LoadConditionContentType[id]
					end

					local function Toggle()
						TargetedSpellsSaved.Settings.Self.LoadConditionContentType[id] =
							not TargetedSpellsSaved.Settings.Self.LoadConditionContentType[id]
					end

					local translated = L.Settings.LoadConditionContentTypeLabels[id]

					container:AddCheckbox(id, translated, L.Settings.LoadConditionContentTypeTooltip, IsEnabled, Toggle)
				end

				return container:GetData()
			end

			local initializer =
				Settings.CreateDropdown(category, setting, GetOptions, L.Settings.LoadConditionContentTypeTooltip)
			initializer.hideSteppers = true
			initializer:SetParentInitializer(generalCategoryEnabledInitializer, IsSectionEnabled)
		end

		-- Load Condition: Role
		do
			local key = Private.Settings.Keys.Self.LoadConditionRole
			local defaults = Private.Settings.GetSelfDefaultSettings().LoadConditionRole

			local defaultValue = GetMask(Private.Enum.Role, function(id)
				return defaults[id]
			end)

			local function GetValue()
				return GetMask(Private.Enum.Role, function(id)
					return TargetedSpellsSaved.Settings.Self.LoadConditionRole[id]
				end)
			end

			local function SetValue(mask)
				local hasChanges = false

				for label, id in pairs(Private.Enum.Role) do
					local enabled = DecodeBitToBool(mask, id)

					if enabled ~= TargetedSpellsSaved.Settings.Self.LoadConditionRole[id] then
						TargetedSpellsSaved.Settings.Self.LoadConditionRole[id] = enabled
						hasChanges = true
					end
				end

				if hasChanges then
					Private.EventRegistry:TriggerEvent(
						Private.Enum.Events.SETTING_CHANGED,
						key,
						TargetedSpellsSaved.Settings.Self.LoadConditionRole
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
			initializer.hideSteppers = true
			initializer:SetParentInitializer(generalCategoryEnabledInitializer, IsSectionEnabled)
		end

		-- Max Frames
		do
			local key = Private.Settings.Keys.Self.MaxFrames
			local defaultValue = Private.Settings.GetSelfDefaultSettings().MaxFrames
			local sliderSettings = Private.Settings.GetSliderSettingsForOption(key)

			local function GetValue()
				return TargetedSpellsSaved.Settings.Self.MaxFrames
			end

			local function SetValue(value)
				if value ~= TargetedSpellsSaved.Settings.Self.MaxFrames then
					TargetedSpellsSaved.Settings.Self.MaxFrames = value

					Private.EventRegistry:TriggerEvent(
						Private.Enum.Events.SETTING_CHANGED,
						key,
						TargetedSpellsSaved.Settings.Self.MaxFrames
					)
				end
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				L.Settings.MaxFramesLabel,
				defaultValue,
				GetValue,
				SetValue
			)
			local options = Settings.CreateSliderOptions(sliderSettings.min, sliderSettings.max, sliderSettings.step)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)

			local initializer = Settings.CreateSlider(category, setting, options, L.Settings.MaxFramesTooltip)
			initializer:SetParentInitializer(generalCategoryEnabledInitializer, IsSectionEnabled)
		end

		-- Frame Width
		do
			local key = Private.Settings.Keys.Self.Width
			local defaultValue = Private.Settings.GetSelfDefaultSettings().Width
			local sliderSettings = Private.Settings.GetSliderSettingsForOption(key)

			local function GetValue()
				return TargetedSpellsSaved.Settings.Self.Width
			end

			local function SetValue(value)
				if value ~= TargetedSpellsSaved.Settings.Self.Width then
					TargetedSpellsSaved.Settings.Self.Width = value

					Private.EventRegistry:TriggerEvent(
						Private.Enum.Events.SETTING_CHANGED,
						key,
						TargetedSpellsSaved.Settings.Self.Width
					)
				end
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				L.Settings.FrameWidthLabel,
				defaultValue,
				GetValue,
				SetValue
			)
			local options = Settings.CreateSliderOptions(sliderSettings.min, sliderSettings.max, sliderSettings.step)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)

			local initializer = Settings.CreateSlider(category, setting, options, L.Settings.FrameWidthTooltip)
			initializer:SetParentInitializer(generalCategoryEnabledInitializer, IsSectionEnabled)
		end

		-- Frame Height
		do
			local key = Private.Settings.Keys.Self.Height
			local defaultValue = Private.Settings.GetSelfDefaultSettings().Height
			local sliderSettings = Private.Settings.GetSliderSettingsForOption(key)

			local function GetValue()
				return TargetedSpellsSaved.Settings.Self.Height
			end

			local function SetValue(value)
				if TargetedSpellsSaved.Settings.Self.Height ~= value then
					TargetedSpellsSaved.Settings.Self.Height = value

					Private.EventRegistry:TriggerEvent(
						Private.Enum.Events.SETTING_CHANGED,
						key,
						TargetedSpellsSaved.Settings.Self.Height
					)
				end
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				L.Settings.FrameHeightLabel,
				defaultValue,
				GetValue,
				SetValue
			)
			local options = Settings.CreateSliderOptions(sliderSettings.min, sliderSettings.max, sliderSettings.step)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)

			local initializer = Settings.CreateSlider(category, setting, options, L.Settings.FrameHeightTooltip)
			initializer:SetParentInitializer(generalCategoryEnabledInitializer, IsSectionEnabled)
		end

		-- Font Size
		do
			local key = Private.Settings.Keys.Self.FontSize
			local defaultValue = Private.Settings.GetSelfDefaultSettings().FontSize
			local sliderSettings = Private.Settings.GetSliderSettingsForOption(key)

			local function GetValue()
				return TargetedSpellsSaved.Settings.Self.FontSize
			end

			local function SetValue(value)
				if value ~= TargetedSpellsSaved.Settings.Self.FontSize then
					TargetedSpellsSaved.Settings.Self.FontSize = value

					Private.EventRegistry:TriggerEvent(
						Private.Enum.Events.SETTING_CHANGED,
						key,
						TargetedSpellsSaved.Settings.Self.FontSize
					)
				end
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				L.Settings.FontSizeLabel,
				defaultValue,
				GetValue,
				SetValue
			)
			local options = Settings.CreateSliderOptions(sliderSettings.min, sliderSettings.max, sliderSettings.step)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)

			local initializer = Settings.CreateSlider(category, setting, options, L.Settings.FontSizeTooltip)
			initializer:SetParentInitializer(generalCategoryEnabledInitializer, IsSectionEnabled)
		end

		-- Frame Gap
		do
			local key = Private.Settings.Keys.Self.Gap
			local defaultValue = Private.Settings.GetSelfDefaultSettings().Gap
			local sliderSettings = Private.Settings.GetSliderSettingsForOption(key)

			local function GetValue()
				return TargetedSpellsSaved.Settings.Self.Gap
			end

			local function SetValue(value)
				if value ~= TargetedSpellsSaved.Settings.Self.Gap then
					TargetedSpellsSaved.Settings.Self.Gap = value

					Private.EventRegistry:TriggerEvent(
						Private.Enum.Events.SETTING_CHANGED,
						key,
						TargetedSpellsSaved.Settings.Self.Gap
					)
				end
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				L.Settings.FrameGapLabel,
				defaultValue,
				GetValue,
				SetValue
			)
			local options = Settings.CreateSliderOptions(sliderSettings.min, sliderSettings.max, sliderSettings.step)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)

			local initializer = Settings.CreateSlider(category, setting, options, L.Settings.FrameGapTooltip)
			initializer:SetParentInitializer(generalCategoryEnabledInitializer, IsSectionEnabled)
		end

		-- Frame Direction
		do
			local key = Private.Settings.Keys.Self.Direction
			local defaultValue = Private.Settings.GetSelfDefaultSettings().Direction

			local function GetValue()
				return TargetedSpellsSaved.Settings.Self.Direction
			end

			local function SetValue(value)
				TargetedSpellsSaved.Settings.Self.Direction = value

				Private.EventRegistry:TriggerEvent(
					Private.Enum.Events.SETTING_CHANGED,
					key,
					TargetedSpellsSaved.Settings.Self.Direction
				)
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
				defaultValue,
				GetValue,
				SetValue
			)
			local initializer = Settings.CreateDropdown(category, setting, GetOptions, L.Settings.FrameDirectionTooltip)
			initializer:SetParentInitializer(generalCategoryEnabledInitializer, IsSectionEnabled)
		end

		-- Frame Sort Order
		do
			local key = Private.Settings.Keys.Self.SortOrder
			local defaultValue = Private.Settings.GetSelfDefaultSettings().SortOrder

			local function GetValue()
				return TargetedSpellsSaved.Settings.Self.SortOrder
			end

			local function SetValue(value)
				TargetedSpellsSaved.Settings.Self.SortOrder = value

				Private.EventRegistry:TriggerEvent(
					Private.Enum.Events.SETTING_CHANGED,
					key,
					TargetedSpellsSaved.Settings.Self.SortOrder
				)
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
				defaultValue,
				GetValue,
				SetValue
			)
			local initializer = Settings.CreateDropdown(category, setting, GetOptions, L.Settings.FrameSortOrderTooltip)
			initializer:SetParentInitializer(generalCategoryEnabledInitializer, IsSectionEnabled)
		end

		-- Frame Grow
		do
			local key = Private.Settings.Keys.Self.Grow
			local defaultValue = Private.Settings.GetSelfDefaultSettings().Grow

			local function GetValue()
				return TargetedSpellsSaved.Settings.Self.Grow
			end

			local function SetValue(value)
				TargetedSpellsSaved.Settings.Self.Grow = value

				Private.EventRegistry:TriggerEvent(
					Private.Enum.Events.SETTING_CHANGED,
					key,
					TargetedSpellsSaved.Settings.Self.Grow
				)
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
				defaultValue,
				GetValue,
				SetValue
			)
			local initializer = Settings.CreateDropdown(category, setting, GetOptions, L.Settings.FrameGrowTooltip)
			initializer:SetParentInitializer(generalCategoryEnabledInitializer, IsSectionEnabled)
		end

		-- Glow Important
		do
			local key = Private.Settings.Keys.Self.GlowImportant

			local function GetValue()
				return TargetedSpellsSaved.Settings.Self.GlowImportant
			end

			local function SetValue(value)
				TargetedSpellsSaved.Settings.Self.GlowImportant = not TargetedSpellsSaved.Settings.Self.GlowImportant
				Private.EventRegistry:TriggerEvent(
					Private.Enum.Events.SETTING_CHANGED,
					key,
					TargetedSpellsSaved.Settings.Self.GlowImportant
				)
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Boolean,
				L.Settings.GlowImportantLabel,
				Settings.Default.True,
				GetValue,
				SetValue
			)
			local initializer = Settings.CreateCheckbox(category, setting, L.Settings.GlowImportantTooltip)
			initializer:SetParentInitializer(generalCategoryEnabledInitializer, IsSectionEnabled)
		end

		-- Play Sound
		do
			local key = Private.Settings.Keys.Self.PlaySound
			local defaultValue = Private.Settings.GetSelfDefaultSettings().PlaySound

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
				defaultValue,
				GetValue,
				SetValue
			)
			local initializer = Settings.CreateCheckbox(category, setting, L.Settings.PlaySoundTooltip)
			initializer:SetParentInitializer(generalCategoryEnabledInitializer, IsSectionEnabled)
		end

		-- Sound
		do
			local key = Private.Settings.Keys.Self.Sound

			local defaultValue = tostring(Private.Settings.GetSelfDefaultSettings().Sound)

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

					Private.EventRegistry:TriggerEvent(
						Private.Enum.Events.SETTING_CHANGED,
						key,
						TargetedSpellsSaved.Settings.Self.Sound
					)
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
				defaultValue,
				GetValue,
				SetValue
			)
			local initializer = Settings.CreateDropdown(category, setting, GetOptions, L.Settings.SoundTooltip)
			initializer:SetParentInitializer(generalCategoryEnabledInitializer, IsSectionEnabled)
		end

		-- Sound Channel
		do
			local key = Private.Settings.Keys.Self.SoundChannel
			local defaultValue = Private.Settings.GetSelfDefaultSettings().SoundChannel

			local function GetValue()
				return TargetedSpellsSaved.Settings.Self.SoundChannel
			end

			local function SetValue(value)
				TargetedSpellsSaved.Settings.Self.SoundChannel = value

				Private.EventRegistry:TriggerEvent(
					Private.Enum.Events.SETTING_CHANGED,
					key,
					TargetedSpellsSaved.Settings.Self.SoundChannel
				)
			end

			local function GetOptions()
				local container = Settings.CreateControlTextContainer()

				for k, v in pairs(Private.Enum.SoundChannel) do
					container:Add(v, k)
				end

				return container:GetData()
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.String,
				L.Settings.SoundChannelLabel,
				defaultValue,
				GetValue,
				SetValue
			)
			local initializer = Settings.CreateDropdown(category, setting, GetOptions, L.Settings.SoundChannelTooltip)
			initializer:SetParentInitializer(generalCategoryEnabledInitializer, IsSectionEnabled)
		end

		-- Show Duration
		do
			local key = Private.Settings.Keys.Self.ShowDuration
			local defaultValue = Private.Settings.GetSelfDefaultSettings().ShowDuration

			local function GetValue()
				return TargetedSpellsSaved.Settings.Self.ShowDuration
			end

			local function SetValue(value)
				TargetedSpellsSaved.Settings.Self.ShowDuration = not TargetedSpellsSaved.Settings.Self.ShowDuration
				Private.EventRegistry:TriggerEvent(
					Private.Enum.Events.SETTING_CHANGED,
					key,
					TargetedSpellsSaved.Settings.Self.ShowDuration
				)
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Boolean,
				L.Settings.ShowDurationLabel,
				defaultValue,
				GetValue,
				SetValue
			)
			local initializer = Settings.CreateCheckbox(category, setting, L.Settings.ShowDurationTooltip)
			initializer:SetParentInitializer(generalCategoryEnabledInitializer, IsSectionEnabled)
		end

		-- Show Border
		do
			local key = Private.Settings.Keys.Self.ShowBorder
			local defaultValue = Private.Settings.GetSelfDefaultSettings().ShowBorder

			local function GetValue()
				return TargetedSpellsSaved.Settings.Self.ShowBorder
			end

			local function SetValue(value)
				TargetedSpellsSaved.Settings.Self.ShowBorder = not TargetedSpellsSaved.Settings.Self.ShowBorder
				Private.EventRegistry:TriggerEvent(
					Private.Enum.Events.SETTING_CHANGED,
					key,
					TargetedSpellsSaved.Settings.Self.ShowBorder
				)
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Boolean,
				L.Settings.ShowBorderLabel,
				defaultValue,
				GetValue,
				SetValue
			)
			local initializer = Settings.CreateCheckbox(category, setting, L.Settings.ShowBorderTooltip)
			initializer:SetParentInitializer(generalCategoryEnabledInitializer, IsSectionEnabled)
		end

		-- Opacity
		do
			local key = Private.Settings.Keys.Self.Opacity
			local defaultValue = Private.Settings.GetSelfDefaultSettings().Opacity
			local sliderSettings = Private.Settings.GetSliderSettingsForOption(key)

			local function GetValue()
				return TargetedSpellsSaved.Settings.Self.Opacity
			end

			local function SetValue(value)
				if value ~= TargetedSpellsSaved.Settings.Self.Opacity then
					TargetedSpellsSaved.Settings.Self.Opacity = value

					Private.EventRegistry:TriggerEvent(
						Private.Enum.Events.SETTING_CHANGED,
						key,
						TargetedSpellsSaved.Settings.Self.Opacity
					)
				end
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				L.Settings.OpacityLabel,
				defaultValue,
				GetValue,
				SetValue
			)
			local options = Settings.CreateSliderOptions(sliderSettings.min, sliderSettings.max, sliderSettings.step)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, FormatPercentage)

			local initializer = Settings.CreateSlider(category, setting, options, L.Settings.OpacityTooltip)
			initializer:SetParentInitializer(generalCategoryEnabledInitializer, IsSectionEnabled)
		end
	end

	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Party"))

	do
		local generalCategoryEnabledInitializer

		local function IsSectionEnabled()
			return TargetedSpellsSaved.Settings.Party.Enabled
		end

		-- Enabled
		do
			local key = Private.Settings.Keys.Party.Enabled

			local function SetValue(value)
				TargetedSpellsSaved.Settings.Party.Enabled = not TargetedSpellsSaved.Settings.Party.Enabled
				Private.EventRegistry:TriggerEvent(
					Private.Enum.Events.SETTING_CHANGED,
					key,
					TargetedSpellsSaved.Settings.Party.Enabled
				)
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Boolean,
				L.Settings.EnabledLabel,
				Settings.Default.True,
				IsSectionEnabled,
				SetValue
			)
			generalCategoryEnabledInitializer = Settings.CreateCheckbox(category, setting, L.Settings.EnabledTooltip)
		end

		-- Load Condition: Content Type
		do
			local key = Private.Settings.Keys.Party.LoadConditionContentType

			local defaults = Private.Settings.GetPartyDefaultSettings().LoadConditionContentType
			local defaultValue = GetMask(Private.Enum.ContentType, function(id)
				return defaults[id]
			end)

			local function GetValue()
				return GetMask(Private.Enum.ContentType, function(id)
					return TargetedSpellsSaved.Settings.Party.LoadConditionContentType[id]
				end)
			end

			local function SetValue(mask)
				local hasChanges = false

				for label, id in pairs(Private.Enum.ContentType) do
					local enabled = DecodeBitToBool(mask, id)

					if enabled ~= TargetedSpellsSaved.Settings.Party.LoadConditionContentType[id] then
						TargetedSpellsSaved.Settings.Party.LoadConditionContentType[id] = enabled
						hasChanges = true
					end
				end

				if hasChanges then
					Private.EventRegistry:TriggerEvent(
						Private.Enum.Events.SETTING_CHANGED,
						key,
						TargetedSpellsSaved.Settings.Party.LoadConditionContentType
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
					local translated = L.Settings.LoadConditionContentTypeLabels[id]

					container:AddCheckbox(id, translated, L.Settings.LoadConditionContentTypeTooltip)
				end

				return container:GetData()
			end

			local initializer =
				Settings.CreateDropdown(category, setting, GetOptions, L.Settings.LoadConditionContentTypeTooltip)
			initializer.hideSteppers = true
			initializer:SetParentInitializer(generalCategoryEnabledInitializer, IsSectionEnabled)
		end

		-- Load Condition: Role
		do
			local key = Private.Settings.Keys.Party.LoadConditionRole
			local defaults = Private.Settings.GetPartyDefaultSettings().LoadConditionRole

			local defaultValue = GetMask(Private.Enum.Role, function(id)
				return defaults[id]
			end)

			local function GetValue()
				return GetMask(Private.Enum.Role, function(id)
					return TargetedSpellsSaved.Settings.Party.LoadConditionRole[id]
				end)
			end

			local function SetValue(mask)
				local hasChanges = false

				for label, id in pairs(Private.Enum.Role) do
					local enabled = DecodeBitToBool(mask, id)

					if enabled ~= TargetedSpellsSaved.Settings.Party.LoadConditionRole[id] then
						TargetedSpellsSaved.Settings.Party.LoadConditionRole[id] = enabled
						hasChanges = true
					end
				end

				if hasChanges then
					Private.EventRegistry:TriggerEvent(
						Private.Enum.Events.SETTING_CHANGED,
						key,
						TargetedSpellsSaved.Settings.Party.LoadConditionRole
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

					container:AddCheckbox(id, translated, L.Settings.LoadConditionRoleTooltip) --, IsEnabled, Toggle)
				end

				return container:GetData()
			end

			local initializer =
				Settings.CreateDropdown(category, setting, GetOptions, L.Settings.LoadConditionRoleTooltip)
			initializer.hideSteppers = true
			initializer:SetParentInitializer(generalCategoryEnabledInitializer, IsSectionEnabled)
		end

		-- Frame Width
		do
			local key = Private.Settings.Keys.Party.Width
			local defaultValue = Private.Settings.GetPartyDefaultSettings().Width
			local sliderSettings = Private.Settings.GetSliderSettingsForOption(key)

			local function GetValue()
				return TargetedSpellsSaved.Settings.Party.Width
			end

			local function SetValue(value)
				if value ~= TargetedSpellsSaved.Settings.Party.Width then
					TargetedSpellsSaved.Settings.Party.Width = value

					Private.EventRegistry:TriggerEvent(
						Private.Enum.Events.SETTING_CHANGED,
						key,
						TargetedSpellsSaved.Settings.Party.Width
					)
				end
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				L.Settings.FrameWidthLabel,
				defaultValue,
				GetValue,
				SetValue
			)
			local options = Settings.CreateSliderOptions(sliderSettings.min, sliderSettings.max, sliderSettings.step)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)

			local initializer = Settings.CreateSlider(category, setting, options, L.Settings.FrameWidthTooltip)
			initializer:SetParentInitializer(generalCategoryEnabledInitializer, IsSectionEnabled)
		end

		-- Frame Height
		do
			local key = Private.Settings.Keys.Party.Height
			local defaultValue = Private.Settings.GetPartyDefaultSettings().Height
			local sliderSettings = Private.Settings.GetSliderSettingsForOption(key)

			local function GetValue()
				return TargetedSpellsSaved.Settings.Party.Height
			end

			local function SetValue(value)
				if value ~= TargetedSpellsSaved.Settings.Party.Height then
					TargetedSpellsSaved.Settings.Party.Height = value

					Private.EventRegistry:TriggerEvent(
						Private.Enum.Events.SETTING_CHANGED,
						key,
						TargetedSpellsSaved.Settings.Party.Height
					)
				end
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				L.Settings.FrameHeightLabel,
				defaultValue,
				GetValue,
				SetValue
			)
			local options = Settings.CreateSliderOptions(sliderSettings.min, sliderSettings.max, sliderSettings.step)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)

			local initializer = Settings.CreateSlider(category, setting, options, L.Settings.FrameHeightTooltip)
			initializer:SetParentInitializer(generalCategoryEnabledInitializer, IsSectionEnabled)
		end

		-- Font Size
		do
			local key = Private.Settings.Keys.Party.FontSize
			local defaultValue = Private.Settings.GetPartyDefaultSettings().FontSize
			local sliderSettings = Private.Settings.GetSliderSettingsForOption(key)

			local function GetValue()
				return TargetedSpellsSaved.Settings.Party.FontSize
			end

			local function SetValue(value)
				if value ~= TargetedSpellsSaved.Settings.Party.FontSize then
					TargetedSpellsSaved.Settings.Party.FontSize = value

					Private.EventRegistry:TriggerEvent(
						Private.Enum.Events.SETTING_CHANGED,
						key,
						TargetedSpellsSaved.Settings.Party.FontSize
					)
				end
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				L.Settings.FontSizeLabel,
				defaultValue,
				GetValue,
				SetValue
			)
			local options = Settings.CreateSliderOptions(sliderSettings.min, sliderSettings.max, sliderSettings.step)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)

			local initializer = Settings.CreateSlider(category, setting, options, L.Settings.FontSizeTooltip)
			initializer:SetParentInitializer(generalCategoryEnabledInitializer, IsSectionEnabled)
		end

		-- Frame Gap
		do
			local key = Private.Settings.Keys.Party.Gap
			local defaultValue = Private.Settings.GetPartyDefaultSettings().Gap
			local sliderSettings = Private.Settings.GetSliderSettingsForOption(key)

			local function GetValue()
				return TargetedSpellsSaved.Settings.Party.Gap
			end

			local function SetValue(value)
				if value ~= TargetedSpellsSaved.Settings.Party.Gap then
					TargetedSpellsSaved.Settings.Party.Gap = value

					Private.EventRegistry:TriggerEvent(
						Private.Enum.Events.SETTING_CHANGED,
						key,
						TargetedSpellsSaved.Settings.Party.Gap
					)
				end
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				L.Settings.FrameGapLabel,
				defaultValue,
				GetValue,
				SetValue
			)
			local options = Settings.CreateSliderOptions(sliderSettings.min, sliderSettings.max, sliderSettings.step)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)

			local initializer = Settings.CreateSlider(category, setting, options, L.Settings.FrameGapTooltip)
			initializer:SetParentInitializer(generalCategoryEnabledInitializer, IsSectionEnabled)
		end

		-- Frame Direction
		do
			local key = Private.Settings.Keys.Party.Direction
			local defaultValue = Private.Settings.GetPartyDefaultSettings().Direction

			local function GetValue()
				return TargetedSpellsSaved.Settings.Party.Direction
			end

			local function SetValue(value)
				if value ~= TargetedSpellsSaved.Settings.Party.Direction then
					TargetedSpellsSaved.Settings.Party.Direction = value

					Private.EventRegistry:TriggerEvent(
						Private.Enum.Events.SETTING_CHANGED,
						key,
						TargetedSpellsSaved.Settings.Party.Direction
					)
				end
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
				defaultValue,
				GetValue,
				SetValue
			)
			local initializer = Settings.CreateDropdown(category, setting, GetOptions, L.Settings.FrameDirectionTooltip)
			initializer:SetParentInitializer(generalCategoryEnabledInitializer, IsSectionEnabled)
		end

		-- Frame OffsetX
		do
			local key = Private.Settings.Keys.Party.OffsetX
			local defaultValue = Private.Settings.GetPartyDefaultSettings().OffsetX
			local sliderSettings = Private.Settings.GetSliderSettingsForOption(key)

			local function GetValue()
				return TargetedSpellsSaved.Settings.Party.OffsetX
			end

			local function SetValue(value)
				if value ~= TargetedSpellsSaved.Settings.Party.OffsetX then
					TargetedSpellsSaved.Settings.Party.OffsetX = value

					Private.EventRegistry:TriggerEvent(
						Private.Enum.Events.SETTING_CHANGED,
						key,
						TargetedSpellsSaved.Settings.Party.OffsetX
					)
				end
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				L.Settings.FrameOffsetXLabel,
				defaultValue,
				GetValue,
				SetValue
			)
			local options = Settings.CreateSliderOptions(sliderSettings.min, sliderSettings.max, sliderSettings.step)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)

			local initializer = Settings.CreateSlider(category, setting, options, L.Settings.FrameOffsetXTooltip)
			initializer:SetParentInitializer(generalCategoryEnabledInitializer, IsSectionEnabled)
		end

		-- Frame OffsetY
		do
			local key = Private.Settings.Keys.Party.OffsetY
			local defaultValue = Private.Settings.GetPartyDefaultSettings().OffsetY
			local sliderSettings = Private.Settings.GetSliderSettingsForOption(key)

			local function GetValue()
				return TargetedSpellsSaved.Settings.Party.OffsetY
			end

			local function SetValue(value)
				if value ~= TargetedSpellsSaved.Settings.Party.OffsetY then
					TargetedSpellsSaved.Settings.Party.OffsetY = value

					Private.EventRegistry:TriggerEvent(
						Private.Enum.Events.SETTING_CHANGED,
						key,
						TargetedSpellsSaved.Settings.Party.OffsetY
					)
				end
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				L.Settings.FrameOffsetYLabel,
				defaultValue,
				GetValue,
				SetValue
			)
			local options = Settings.CreateSliderOptions(sliderSettings.min, sliderSettings.max, sliderSettings.step)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)

			local initializer = Settings.CreateSlider(category, setting, options, L.Settings.FrameOffsetYTooltip)
			initializer:SetParentInitializer(generalCategoryEnabledInitializer, IsSectionEnabled)
		end

		-- Frame Source Anchor
		do
			local key = Private.Settings.Keys.Party.SourceAnchor
			local defaultValue = Private.Settings.GetPartyDefaultSettings().SourceAnchor

			local function GetValue()
				return TargetedSpellsSaved.Settings.Party.SourceAnchor
			end

			local function SetValue(value)
				TargetedSpellsSaved.Settings.Party.SourceAnchor = value

				Private.EventRegistry:TriggerEvent(
					Private.Enum.Events.SETTING_CHANGED,
					key,
					TargetedSpellsSaved.Settings.Party.SourceAnchor
				)
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
				defaultValue,
				GetValue,
				SetValue
			)
			local initializer =
				Settings.CreateDropdown(category, setting, GetOptions, L.Settings.FrameSourceAnchorTooltip)
			initializer:SetParentInitializer(generalCategoryEnabledInitializer, IsSectionEnabled)
		end

		-- Frame Target Anchor
		do
			local key = Private.Settings.Keys.Party.TargetAnchor
			local defaultValue = Private.Settings.GetPartyDefaultSettings().TargetAnchor

			local function GetValue()
				return TargetedSpellsSaved.Settings.Party.TargetAnchor
			end

			local function SetValue(value)
				TargetedSpellsSaved.Settings.Party.TargetAnchor = value

				Private.EventRegistry:TriggerEvent(
					Private.Enum.Events.SETTING_CHANGED,
					key,
					TargetedSpellsSaved.Settings.Party.TargetAnchor
				)
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
				defaultValue,
				GetValue,
				SetValue
			)
			local initializer =
				Settings.CreateDropdown(category, setting, GetOptions, L.Settings.FrameTargetAnchorTooltip)
			initializer:SetParentInitializer(generalCategoryEnabledInitializer, IsSectionEnabled)
		end

		-- Frame Grow
		do
			local key = Private.Settings.Keys.Party.Grow
			local defaultValue = Private.Settings.GetPartyDefaultSettings().Grow

			local function GetValue()
				return TargetedSpellsSaved.Settings.Party.Grow
			end

			local function SetValue(value)
				TargetedSpellsSaved.Settings.Party.Grow = value

				Private.EventRegistry:TriggerEvent(
					Private.Enum.Events.SETTING_CHANGED,
					key,
					TargetedSpellsSaved.Settings.Party.Grow
				)
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
				defaultValue,
				GetValue,
				SetValue
			)
			local initializer = Settings.CreateDropdown(category, setting, GetOptions, L.Settings.FrameGrowTooltip)
			initializer:SetParentInitializer(generalCategoryEnabledInitializer, IsSectionEnabled)
		end

		-- Frame Sort Order
		do
			local key = Private.Settings.Keys.Party.SortOrder
			local defaultValue = Private.Settings.GetPartyDefaultSettings().SortOrder

			local function GetValue()
				return TargetedSpellsSaved.Settings.Party.SortOrder
			end

			local function SetValue(value)
				TargetedSpellsSaved.Settings.Party.SortOrder = value

				Private.EventRegistry:TriggerEvent(
					Private.Enum.Events.SETTING_CHANGED,
					key,
					TargetedSpellsSaved.Settings.Party.SortOrder
				)
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
				defaultValue,
				GetValue,
				SetValue
			)
			local initializer = Settings.CreateDropdown(category, setting, GetOptions, L.Settings.FrameSortOrderTooltip)
			initializer:SetParentInitializer(generalCategoryEnabledInitializer, IsSectionEnabled)
		end

		-- Glow Important
		do
			local key = Private.Settings.Keys.Party.GlowImportant

			local function SetValue(value)
				TargetedSpellsSaved.Settings.Party.GlowImportant = not TargetedSpellsSaved.Settings.Party.GlowImportant
				Private.EventRegistry:TriggerEvent(
					Private.Enum.Events.SETTING_CHANGED,
					key,
					TargetedSpellsSaved.Settings.Party.GlowImportant
				)
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Boolean,
				L.Settings.GlowImportantLabel,
				Settings.Default.True,
				IsSectionEnabled,
				SetValue
			)
			local initializer = Settings.CreateCheckbox(category, setting, L.Settings.GlowImportantTooltip)
			initializer:SetParentInitializer(generalCategoryEnabledInitializer, IsSectionEnabled)
		end

		-- Include Self in Party
		do
			local key = Private.Settings.Keys.Party.IncludeSelfInParty

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
				IsSectionEnabled,
				SetValue
			)
			local initializer = Settings.CreateCheckbox(category, setting, L.Settings.IncludeSelfInPartyTooltip)
			initializer:SetParentInitializer(generalCategoryEnabledInitializer, IsSectionEnabled)
		end

		-- Show Duration
		do
			local key = Private.Settings.Keys.Party.ShowDuration
			local defaultValue = Private.Settings.GetPartyDefaultSettings().ShowDuration

			local function GetValue()
				return TargetedSpellsSaved.Settings.Party.ShowDuration
			end

			local function SetValue(value)
				TargetedSpellsSaved.Settings.Party.ShowDuration = not TargetedSpellsSaved.Settings.Party.ShowDuration
				Private.EventRegistry:TriggerEvent(
					Private.Enum.Events.SETTING_CHANGED,
					key,
					TargetedSpellsSaved.Settings.Party.ShowDuration
				)
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Boolean,
				L.Settings.ShowDurationLabel,
				defaultValue,
				GetValue,
				SetValue
			)
			local initializer = Settings.CreateCheckbox(category, setting, L.Settings.ShowDurationTooltip)
			initializer:SetParentInitializer(generalCategoryEnabledInitializer, IsSectionEnabled)
		end

		-- Show Border
		do
			local key = Private.Settings.Keys.Party.ShowBorder
			local defaultValue = Private.Settings.GetPartyDefaultSettings().ShowBorder

			local function GetValue()
				return TargetedSpellsSaved.Settings.Party.ShowBorder
			end

			local function SetValue(value)
				TargetedSpellsSaved.Settings.Party.ShowBorder = not TargetedSpellsSaved.Settings.Party.ShowBorder
				Private.EventRegistry:TriggerEvent(
					Private.Enum.Events.SETTING_CHANGED,
					key,
					TargetedSpellsSaved.Settings.Party.ShowBorder
				)
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Boolean,
				L.Settings.ShowBorderLabel,
				defaultValue,
				GetValue,
				SetValue
			)
			local initializer = Settings.CreateCheckbox(category, setting, L.Settings.ShowBorderTooltip)
			initializer:SetParentInitializer(generalCategoryEnabledInitializer, IsSectionEnabled)
		end

		-- Opacity
		do
			local key = Private.Settings.Keys.Party.Opacity
			local defaultValue = Private.Settings.GetPartyDefaultSettings().Opacity
			local sliderSettings = Private.Settings.GetSliderSettingsForOption(key)

			local function GetValue()
				return TargetedSpellsSaved.Settings.Party.Opacity
			end

			local function SetValue(value)
				if value ~= TargetedSpellsSaved.Settings.Party.Opacity then
					TargetedSpellsSaved.Settings.Party.Opacity = value

					Private.EventRegistry:TriggerEvent(
						Private.Enum.Events.SETTING_CHANGED,
						key,
						TargetedSpellsSaved.Settings.Party.Opacity
					)
				end
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				L.Settings.OpacityLabel,
				defaultValue,
				GetValue,
				SetValue
			)
			local options = Settings.CreateSliderOptions(sliderSettings.min, sliderSettings.max, sliderSettings.step)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, FormatPercentage)

			local initializer = Settings.CreateSlider(category, setting, options, L.Settings.OpacityTooltip)
			initializer:SetParentInitializer(generalCategoryEnabledInitializer, IsSectionEnabled)
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

				tooltip:AddLine(
					L.Settings.AddonCompartmentTooltipLine1:format(
						WrapTextInColorCode(
							string.lower(
								TargetedSpellsSaved.Settings.Self.Enabled and L.Settings.EnabledLabel
									or L.Settings.DisabledLabel
							),
							TargetedSpellsSaved.Settings.Self.Enabled and enabledColor or disabledColor
						)
					)
				)
				tooltip:AddLine(
					L.Settings.AddonCompartmentTooltipLine2:format(
						WrapTextInColorCode(
							string.lower(
								TargetedSpellsSaved.Settings.Party.Enabled and L.Settings.EnabledLabel
									or L.Settings.DisabledLabel
							),
							TargetedSpellsSaved.Settings.Party.Enabled and enabledColor or disabledColor
						)
					)
				)
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
