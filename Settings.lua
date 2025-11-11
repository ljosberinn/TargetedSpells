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
		OffsetX = "FRAME_OFFSET_X_SELF",
		OffsetY = "FRAME_OFFSET_Y_SELF",
		SortOrder = "FRAME_SORT_ORDER_SELF",
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
		Sound = Private.IsMidnight and 316493 or "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\WaterDrop.ogg",
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
	}
end

function Private.Settings.GetCustomSoundList()
	return LibSharedMedia:HashTable(LibSharedMedia.MediaType.SOUND)
end

table.insert(Private.LoginFnQueue, function()
	local L = Private.L
	local settingsName = C_AddOns.GetAddOnMetadata(addonName, "Title")
	local category, layout = Settings.RegisterVerticalLayoutCategory(settingsName)

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
		if Private.IsMidnight then
			do
				local key = Private.Settings.Keys.Self.LoadConditionContentType

				local function ResetToDefault()
					local defaults = Private.Settings.GetSelfDefaultSettings().LoadConditionContentType
					local hasChanges = false

					for id, value in pairs(defaults) do
						if TargetedSpellsSaved.Settings.Self.LoadConditionContentType[id] ~= value then
							TargetedSpellsSaved.Settings.Self.LoadConditionContentType[id] = value
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

					return 0
				end

				local function GetValueDummy()
					return true
				end

				local function SetValueDummy() end

				local setting = Settings.RegisterProxySetting(
					category,
					key,
					Settings.VarType.Number,
					L.Settings.LoadConditionContentTypeLabel,
					ResetToDefault,
					GetValueDummy,
					SetValueDummy
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

						container:AddCheckbox(id, label, "Tooltip", IsEnabled, Toggle)
					end

					return container:GetData()
				end

				local initializer =
					Settings.CreateDropdown(category, setting, GetOptions, L.Settings.LoadConditionContentTypeTooltip)
				initializer.hideSteppers = true
				initializer:SetParentInitializer(generalCategoryEnabledInitializer, IsSectionEnabled)
			end
		end

		-- Load Condition: Role
		if Private.IsMidnight then
			do
				local key = Private.Settings.Keys.Self.LoadConditionRole

				local function ResetToDefault()
					local defaults = Private.Settings.GetSelfDefaultSettings().LoadConditionRole
					local hasChanges = false

					for id, value in pairs(defaults) do
						if TargetedSpellsSaved.Settings.Self.LoadConditionRole[id] ~= value then
							TargetedSpellsSaved.Settings.Self.LoadConditionRole[id] = value
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

					return 0
				end

				local function GetValueDummy()
					return true
				end

				local function SetValueDummy() end

				local setting = Settings.RegisterProxySetting(
					category,
					key,
					Settings.VarType.Number,
					L.Settings.LoadConditionRoleLabel,
					ResetToDefault,
					GetValueDummy,
					SetValueDummy
				)

				local function GetOptions()
					local container = Settings.CreateControlTextContainer()

					for label, id in pairs(Private.Enum.Role) do
						local function IsEnabled()
							return TargetedSpellsSaved.Settings.Self.LoadConditionRole[id]
						end

						local function Toggle()
							TargetedSpellsSaved.Settings.Self.LoadConditionRole[id] =
								not TargetedSpellsSaved.Settings.Self.LoadConditionRole[id]
						end

						container:AddCheckbox(id, label, "Tooltip", IsEnabled, Toggle)
					end

					return container:GetData()
				end

				local initializer =
					Settings.CreateDropdown(category, setting, GetOptions, L.Settings.LoadConditionRoleTooltip)
				initializer.hideSteppers = true
				initializer:SetParentInitializer(generalCategoryEnabledInitializer, IsSectionEnabled)
			end
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
				TargetedSpellsSaved.Settings.Self.MaxFrames = value

				Private.EventRegistry:TriggerEvent(
					Private.Enum.Events.SETTING_CHANGED,
					key,
					TargetedSpellsSaved.Settings.Self.MaxFrames
				)
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
				TargetedSpellsSaved.Settings.Self.Width = value

				Private.EventRegistry:TriggerEvent(
					Private.Enum.Events.SETTING_CHANGED,
					key,
					TargetedSpellsSaved.Settings.Self.Width
				)
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
				TargetedSpellsSaved.Settings.Self.Height = value

				Private.EventRegistry:TriggerEvent(
					Private.Enum.Events.SETTING_CHANGED,
					key,
					TargetedSpellsSaved.Settings.Self.Height
				)
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
				TargetedSpellsSaved.Settings.Self.FontSize = value

				Private.EventRegistry:TriggerEvent(
					Private.Enum.Events.SETTING_CHANGED,
					key,
					TargetedSpellsSaved.Settings.Self.FontSize
				)
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
				TargetedSpellsSaved.Settings.Self.Gap = value

				Private.EventRegistry:TriggerEvent(
					Private.Enum.Events.SETTING_CHANGED,
					key,
					TargetedSpellsSaved.Settings.Self.Gap
				)
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

				for k, v in pairs(Private.Enum.Direction) do
					container:Add(v, k)
				end

				return container:GetData()
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.String,
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

				for k, v in pairs(Private.Enum.SortOrder) do
					container:Add(v, k)
				end

				return container:GetData()
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.String,
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

				for k, v in pairs(Private.Enum.Grow) do
					container:Add(v, k)
				end

				return container:GetData()
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.String,
				L.Settings.FrameGrowLabel,
				defaultValue,
				GetValue,
				SetValue
			)
			local initializer = Settings.CreateDropdown(category, setting, GetOptions, L.Settings.FrameGrowTooltip)
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
				TargetedSpellsSaved.Settings.Self.Sound = IsNumeric(value) and tonumber(value) or value

				Private.EventRegistry:TriggerEvent(
					Private.Enum.Events.SETTING_CHANGED,
					key,
					TargetedSpellsSaved.Settings.Self.Sound
				)
			end

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
				local soundCategoryKeyToText = {
					Animals = COOLDOWN_VIEWER_SETTINGS_SOUND_ALERT_CATEGORY_ANIMALS,
					Devices = COOLDOWN_VIEWER_SETTINGS_SOUND_ALERT_CATEGORY_DEVICES,
					Impacts = COOLDOWN_VIEWER_SETTINGS_SOUND_ALERT_CATEGORY_IMPACTS,
					Instruments = COOLDOWN_VIEWER_SETTINGS_SOUND_ALERT_CATEGORY_INSTRUMENTS,
					War2 = COOLDOWN_VIEWER_SETTINGS_SOUND_ALERT_CATEGORY_WAR2,
					War3 = COOLDOWN_VIEWER_SETTINGS_SOUND_ALERT_CATEGORY_WAR3,
				}

				RecursiveAddSounds(container, soundCategoryKeyToText, CooldownViewerSoundData)
			end

			local function AddCustomSounds(container)
				-- this follows the structure of `CooldownViewerSoundData` in `Blizzard_CooldownViewer/CooldownViewerSoundAlertData.lua` for ease of function reuse
				local customSoundData = {
					Custom = {},
				}

				local soundCategoryKeyToText = {
					Custom = L.Settings.SoundCategoryCustom,
				}

				local sounds = Private.Settings.GetCustomSoundList()

				for name, path in pairs(sounds) do
					if path ~= 1 then
						table.insert(customSoundData.Custom, { soundKitID = path, text = name })
					end
				end

				RecursiveAddSounds(container, soundCategoryKeyToText, customSoundData)
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
				"Sound",
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
				TargetedSpellsSaved.Settings.Self.Opacity = value

				Private.EventRegistry:TriggerEvent(
					Private.Enum.Events.SETTING_CHANGED,
					key,
					TargetedSpellsSaved.Settings.Self.Opacity
				)
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
		if Private.IsMidnight then
			do
				local key = Private.Settings.Keys.Party.LoadConditionContentType

				local function ResetToDefault()
					local defaults = Private.Settings.GetPartyDefaultSettings().LoadConditionContentType

					for id, value in pairs(defaults) do
						TargetedSpellsSaved.Settings.Party.LoadConditionContentType[id] = value
					end

					Private.EventRegistry:TriggerEvent(
						Private.Enum.Events.SETTING_CHANGED,
						key,
						TargetedSpellsSaved.Settings.Party.LoadConditionContentType
					)

					return 0
				end

				local function GetOptions()
					local container = Settings.CreateControlTextContainer()

					for label, id in pairs(Private.Enum.ContentType) do
						local function IsEnabled()
							return TargetedSpellsSaved.Settings.Party.LoadConditionContentType[id]
						end

						local function Toggle()
							TargetedSpellsSaved.Settings.Party.LoadConditionContentType[id] =
								not TargetedSpellsSaved.Settings.Party.LoadConditionContentType[id]
						end

						container:AddCheckbox(id, label, "Tooltip", IsEnabled, Toggle)
					end

					return container:GetData()
				end

				local function GetValueDummy()
					return true
				end

				local function SetValueDummy() end

				local setting = Settings.RegisterProxySetting(
					category,
					key,
					Settings.VarType.Number,
					L.Settings.LoadConditionContentTypeLabel,
					ResetToDefault,
					GetValueDummy,
					SetValueDummy
				)

				local initializer =
					Settings.CreateDropdown(category, setting, GetOptions, L.Settings.LoadConditionContentTypeTooltip)
				initializer.hideSteppers = true
				initializer:SetParentInitializer(generalCategoryEnabledInitializer, IsSectionEnabled)
			end
		end

		-- Load Condition: Role
		if Private.IsMidnight then
			do
				local key = Private.Settings.Keys.Party.LoadConditionRole

				local function ResetToDefault()
					local defaults = Private.Settings.GetPartyDefaultSettings().LoadConditionRole

					for id, value in pairs(defaults) do
						TargetedSpellsSaved.Settings.Party.LoadConditionRole[id] = value
					end

					Private.EventRegistry:TriggerEvent(
						Private.Enum.Events.SETTING_CHANGED,
						key,
						TargetedSpellsSaved.Settings.Party.LoadConditionRole
					)

					return 0
				end

				local function GetValueDummy()
					return true
				end

				local function SetValueDummy() end

				local function GetOptions()
					local container = Settings.CreateControlTextContainer()

					for label, id in pairs(Private.Enum.Role) do
						local function IsEnabled()
							return TargetedSpellsSaved.Settings.Party.LoadConditionRole[id]
						end

						local function Toggle()
							TargetedSpellsSaved.Settings.Party.LoadConditionRole[id] =
								not TargetedSpellsSaved.Settings.Party.LoadConditionRole[id]
						end

						container:AddCheckbox(id, label, "Tooltip", IsEnabled, Toggle)
					end

					return container:GetData()
				end

				local setting = Settings.RegisterProxySetting(
					category,
					key,
					Settings.VarType.Number,
					L.Settings.LoadConditionRoleLabel,
					ResetToDefault,
					GetValueDummy,
					SetValueDummy
				)

				local initializer =
					Settings.CreateDropdown(category, setting, GetOptions, L.Settings.LoadConditionRoleTooltip)
				initializer.hideSteppers = true
				initializer:SetParentInitializer(generalCategoryEnabledInitializer, IsSectionEnabled)
			end
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
				TargetedSpellsSaved.Settings.Party.Width = value

				Private.EventRegistry:TriggerEvent(
					Private.Enum.Events.SETTING_CHANGED,
					key,
					TargetedSpellsSaved.Settings.Party.Width
				)
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
				TargetedSpellsSaved.Settings.Party.Height = value

				Private.EventRegistry:TriggerEvent(
					Private.Enum.Events.SETTING_CHANGED,
					key,
					TargetedSpellsSaved.Settings.Party.Height
				)
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
				TargetedSpellsSaved.Settings.Party.FontSize = value

				Private.EventRegistry:TriggerEvent(
					Private.Enum.Events.SETTING_CHANGED,
					key,
					TargetedSpellsSaved.Settings.Party.FontSize
				)
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
				TargetedSpellsSaved.Settings.Party.Gap = value

				Private.EventRegistry:TriggerEvent(
					Private.Enum.Events.SETTING_CHANGED,
					key,
					TargetedSpellsSaved.Settings.Party.Gap
				)
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
				TargetedSpellsSaved.Settings.Party.Direction = value

				Private.EventRegistry:TriggerEvent(
					Private.Enum.Events.SETTING_CHANGED,
					key,
					TargetedSpellsSaved.Settings.Party.Direction
				)
			end

			local function GetOptions()
				local container = Settings.CreateControlTextContainer()

				for k, v in pairs(Private.Enum.Direction) do
					container:Add(v, k)
				end

				return container:GetData()
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.String,
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
				TargetedSpellsSaved.Settings.Party.OffsetX = value

				Private.EventRegistry:TriggerEvent(
					Private.Enum.Events.SETTING_CHANGED,
					key,
					TargetedSpellsSaved.Settings.Party.OffsetX
				)
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
				TargetedSpellsSaved.Settings.Party.OffsetY = value

				Private.EventRegistry:TriggerEvent(
					Private.Enum.Events.SETTING_CHANGED,
					key,
					TargetedSpellsSaved.Settings.Party.OffsetY
				)
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

				for k, v in pairs(Private.Enum.Grow) do
					container:Add(v, k)
				end

				return container:GetData()
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.String,
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

				for k, v in pairs(Private.Enum.SortOrder) do
					container:Add(v, k)
				end

				return container:GetData()
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.String,
				L.Settings.FrameSortOrderLabel,
				defaultValue,
				GetValue,
				SetValue
			)
			local initializer = Settings.CreateDropdown(category, setting, GetOptions, L.Settings.FrameSortOrderTooltip)
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
				TargetedSpellsSaved.Settings.Party.Opacity = value

				Private.EventRegistry:TriggerEvent(
					Private.Enum.Events.SETTING_CHANGED,
					key,
					TargetedSpellsSaved.Settings.Party.Opacity
				)
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
		funcOnEnter = function()
			MenuUtil.ShowTooltip(AddonCompartmentFrame, function(tooltip)
				tooltip:SetText(settingsName, 1, 1, 1)
				tooltip:AddLine(L.Settings.ClickToOpenSettingsLabel)
			end)
		end,
		funcOnLeave = function()
			MenuUtil.HideTooltip(AddonCompartmentFrame)
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
