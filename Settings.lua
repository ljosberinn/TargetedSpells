---@type string, TargetedSpells
local addonName, Private = ...

Private.Settings = {}

Private.Settings.Keys = {
	Self = {
		Enabled = "ENABLED_SELF",
		LoadConditionContentType = "LOAD_CONDITION_CONTENT_TYPE_SELF",
		LoadConditionRole = "LOAD_CONDITION_ROLE_SELF",
		Width = "FRAME_WIDTH_SELF",
		Height = "FRAME_HEIGHT_SELF",
		Spacing = "FRAME_SPACING_SELF",
		GrowDirection = "GROW_DIRECTION_SELF",
		OffsetX = "FRAME_OFFSET_X_SELF",
		OffsetY = "FRAME_OFFSET_Y_SELF",
	},
	Party = {
		Enabled = "ENABLED_PARTY",
		LoadConditionContentType = "LOAD_CONDITION_CONTENT_TYPE_PARTY",
		LoadConditionRole = "LOAD_CONDITION_ROLE_PARTY",
		Width = "FRAME_WIDTH_PARTY",
		Height = "FRAME_HEIGHT_PARTY",
		Spacing = "FRAME_SPACING_PARTY",
		GrowDirection = "GROW_DIRECTION_PARTY",
	},
}

function Private.Settings.GetSliderSettingsForOption(key)
	if key == Private.Settings.Keys.Self.Width or key == Private.Settings.Keys.Self.Height then
		return {
			min = 36,
			max = 100,
			step = 2,
		}
	end

	if key == Private.Settings.Keys.Self.Spacing then
		return {
			min = -10,
			max = 40,
			step = 2,
		}
	end

	error(
		string.format(
			"Slider Settings for key '%s' are either not implemented or you're calling this with the wrong key.",
			addonName,
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
		Spacing = 2,
		GrowDirection = Private.Enum.GrowDirection.Horizontal,
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
		Sound = "bloop",
		LoadConditionSoundContentType = {
			[Private.Enum.ContentType.OpenWorld] = false,
			[Private.Enum.ContentType.Delve] = true,
			[Private.Enum.ContentType.Dungeon] = true,
			[Private.Enum.ContentType.Raid] = false,
			[Private.Enum.ContentType.Arena] = false,
			[Private.Enum.ContentType.Battleground] = false,
		},
	}
end

---@return SavedVariablesSettingsParty
function Private.Settings.GetPartyDefaultSettings()
	return {
		Enabled = true,
		Width = 24,
		Height = 24,
		Spacing = 2,
		GrowDirection = Private.Enum.GrowDirection.Horizontal,
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
	}
end

table.insert(Private.LoginFnQueue, function()
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
					Private.Events.SETTING_CHANGED,
					key,
					TargetedSpellsSaved.Settings.Self.Enabled
				)
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Boolean,
				"Enabled",
				Settings.Default.True,
				IsSectionEnabled,
				SetValue
			)
			generalCategoryEnabledInitializer = Settings.CreateCheckbox(category, setting, "Tooltip")
		end

		-- Preview
		do
			---@type TargetedSpellsSelfPreviewFrame?
			local previewContainer = nil

			local function RepositionPreviewFrames()
				if previewContainer == nil then
					return
				end

				---@type TargetedSpellsMixin[]
				local activeFrames = {}

				for i, frame in ipairs({ previewContainer:GetChildren() }) do
					if frame:ShouldBeShown() then
						table.insert(activeFrames, frame)
					end
				end

				local width, height, spacing, growDirection =
					TargetedSpellsSaved.Settings.Self.Width,
					TargetedSpellsSaved.Settings.Self.Height,
					TargetedSpellsSaved.Settings.Self.Spacing,
					TargetedSpellsSaved.Settings.Self.GrowDirection

				local isHorizontal = growDirection == Private.Enum.GrowDirection.Horizontal

				table.sort(
					activeFrames,
					---@param a TargetedSpellsMixin
					---@param b TargetedSpellsMixin
					function(a, b)
						if a:GetStartTime() and b:GetStartTime() then
							if isHorizontal then
								return a:GetStartTime() < b:GetStartTime()
							end

							return a:GetStartTime() > b:GetStartTime()
						end

						return false
					end
				)

				local activeFrameCount = #activeFrames

				if isHorizontal then
					local totalWidth = (activeFrameCount * width) + (activeFrameCount - 1) * spacing

					for i, frame in ipairs(activeFrames) do
						local x = (i - 1) * width + (i - 1) * spacing - totalWidth / 2
						frame:Reposition("LEFT", previewContainer, "CENTER", x, 0)
					end
				else
					local totalHeight = (activeFrameCount * height) + (activeFrameCount - 1) * spacing

					for i, frame in ipairs(activeFrames) do
						local y = (i - 1) * height + (i - 1) * spacing - totalHeight / 2
						frame:Reposition("BOTTOM", previewContainer, "CENTER", 0, y)
					end
				end
			end

			local playing = false

			local function ToggleDemo()
				if previewContainer == nil then
					return
				end

				for i, frame in pairs({ previewContainer:GetChildren() }) do
					if playing then
						frame:StopPreviewLoop()
					else
						frame:StartPreviewLoop(RepositionPreviewFrames)
					end
				end

				playing = not playing
			end

			EventRegistry:RegisterCallback("Settings.CategoryChanged", function(ownerId, categoryData)
				if categoryData == category then
					if not playing then
						if previewContainer == nil then
							previewContainer = TargetedSpellsSelfPreviewSettings1:GetParent()

							Private.EventRegistry:RegisterCallback(
								Private.Events.SETTING_CHANGED,
								function(self, key, value)
									if
										key == Private.Settings.Keys.Self.Spacing
										or key == Private.Settings.Keys.Self.GrowDirection
										or key == Private.Settings.Keys.Self.OffsetX
										or key == Private.Settings.Keys.Self.OffsetY
										or key == Private.Settings.Keys.Self.Width
										or key == Private.Settings.Keys.Self.Height
									then
										RepositionPreviewFrames()
									elseif key == Private.Settings.Keys.Self.Enabled then
									end
								end,
								previewContainer
							)
						end

						ToggleDemo()
					end
				elseif playing then
					ToggleDemo()
				end
			end)

			local data = {}
			local initializer = Settings.CreatePanelInitializer("TargetedSpellsSelfPreviewTemplate", data)
			layout:AddInitializer(initializer)
		end

		-- Load Condition Content Type
		if Private.IsMidnight then
			do
				local key = Private.Settings.Keys.Self.LoadConditionContentType

				local function ResetToDefault()
					local defaults = Private.Settings.GetSelfDefaultSettings().LoadConditionContentType

					for id, value in pairs(defaults) do
						TargetedSpellsSaved.Settings.Self.LoadConditionContentType[id] = value
					end

					Private.EventRegistry:TriggerEvent(
						Private.Events.SETTING_CHANGED,
						key,
						TargetedSpellsSaved.Settings.Self.LoadConditionContentType
					)

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
					"Load Condition: Content Type",
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

				local initializer = Settings.CreateDropdown(category, setting, GetOptions, "Tooltip")
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

					for id, value in pairs(defaults) do
						TargetedSpellsSaved.Settings.Self.LoadConditionRole[id] = value
					end

					Private.EventRegistry:TriggerEvent(
						Private.Events.SETTING_CHANGED,
						key,
						TargetedSpellsSaved.Settings.Self.LoadConditionRole
					)

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
					"Load Condition: Role",
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

				local initializer = Settings.CreateDropdown(category, setting, GetOptions, "Tooltip")
				initializer.hideSteppers = true
				initializer:SetParentInitializer(generalCategoryEnabledInitializer, IsSectionEnabled)
			end
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
					Private.Events.SETTING_CHANGED,
					key,
					TargetedSpellsSaved.Settings.Self.Width
				)
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				"Width",
				defaultValue,
				GetValue,
				SetValue
			)
			local options = Settings.CreateSliderOptions(sliderSettings.min, sliderSettings.max, sliderSettings.step)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)

			local initializer = Settings.CreateSlider(category, setting, options, "Tooltip")
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
					Private.Events.SETTING_CHANGED,
					key,
					TargetedSpellsSaved.Settings.Self.Height
				)
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				"Height",
				defaultValue,
				GetValue,
				SetValue
			)
			local options = Settings.CreateSliderOptions(sliderSettings.min, sliderSettings.max, sliderSettings.step)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)

			local initializer = Settings.CreateSlider(category, setting, options, "Tooltip")
			initializer:SetParentInitializer(generalCategoryEnabledInitializer, IsSectionEnabled)
		end

		-- Frame Spacing
		do
			local key = Private.Settings.Keys.Self.Spacing
			local defaultValue = Private.Settings.GetSelfDefaultSettings().Spacing
			local sliderSettings = Private.Settings.GetSliderSettingsForOption(key)

			local function GetValue()
				return TargetedSpellsSaved.Settings.Self.Spacing
			end

			local function SetValue(value)
				TargetedSpellsSaved.Settings.Self.Spacing = value

				Private.EventRegistry:TriggerEvent(
					Private.Events.SETTING_CHANGED,
					key,
					TargetedSpellsSaved.Settings.Self.Spacing
				)
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				"Spacing",
				defaultValue,
				GetValue,
				SetValue
			)
			local options = Settings.CreateSliderOptions(sliderSettings.min, sliderSettings.max, sliderSettings.step)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)

			local initializer = Settings.CreateSlider(category, setting, options, "Tooltip")
			initializer:SetParentInitializer(generalCategoryEnabledInitializer, IsSectionEnabled)
		end

		-- Grow Direction
		do
			local key = Private.Settings.Keys.Self.GrowDirection
			local defaultValue = Private.Settings.GetSelfDefaultSettings().GrowDirection

			local function GetValue()
				return TargetedSpellsSaved.Settings.Self.GrowDirection
			end

			local function SetValue(value)
				TargetedSpellsSaved.Settings.Self.GrowDirection = value

				Private.EventRegistry:TriggerEvent(
					Private.Events.SETTING_CHANGED,
					key,
					TargetedSpellsSaved.Settings.Self.GrowDirection
				)
			end

			local function GetOptions()
				local container = Settings.CreateControlTextContainer()

				container:Add(1, "Horizontal")
				container:Add(2, "Vertical")

				return container:GetData()
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				"Grow Direction",
				defaultValue,
				GetValue,
				SetValue
			)
			local initializer = Settings.CreateDropdown(category, setting, GetOptions, "Tooltip")
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
					Private.Events.SETTING_CHANGED,
					key,
					TargetedSpellsSaved.Settings.Party.Enabled
				)
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Boolean,
				"Enabled",
				Settings.Default.True,
				IsSectionEnabled,
				SetValue
			)
			generalCategoryEnabledInitializer = Settings.CreateCheckbox(category, setting, "Tooltip")
		end

		-- Preview
		do
			-- local data = {}
			-- local initializer = Settings.CreatePanelInitializer("TargetedSpellsPartyPreviewTemplate", data)
			-- layout:AddInitializer(initializer)
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
						Private.Events.SETTING_CHANGED,
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
					"Load Condition: Content Type",
					ResetToDefault,
					GetValueDummy,
					SetValueDummy
				)

				local initializer = Settings.CreateDropdown(category, setting, GetOptions, "Tooltip")
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
						Private.Events.SETTING_CHANGED,
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
					"Load Condition: Role",
					ResetToDefault,
					GetValueDummy,
					SetValueDummy
				)

				local initializer = Settings.CreateDropdown(category, setting, GetOptions, "Tooltip")
				initializer.hideSteppers = true
				initializer:SetParentInitializer(generalCategoryEnabledInitializer, IsSectionEnabled)
			end
		end

		-- Frame Width
		do
			local key = Private.Settings.Keys.Party.Width
			local defaultValue = Private.Settings.GetPartyDefaultSettings().Width
			local minValue, maxValue, step = 16, 60, 2

			local function GetValue()
				return TargetedSpellsSaved.Settings.Party.Width
			end

			local function SetValue(value)
				TargetedSpellsSaved.Settings.Party.Width = value

				Private.EventRegistry:TriggerEvent(
					Private.Events.SETTING_CHANGED,
					key,
					TargetedSpellsSaved.Settings.Party.Width
				)
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				"Width",
				defaultValue,
				GetValue,
				SetValue
			)
			local options = Settings.CreateSliderOptions(minValue, maxValue, step)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)

			local initializer = Settings.CreateSlider(category, setting, options, "Tooltip")
			initializer:SetParentInitializer(generalCategoryEnabledInitializer, IsSectionEnabled)
		end

		-- Frame Height
		do
			local key = Private.Settings.Keys.Party.Height
			local defaultValue = Private.Settings.GetPartyDefaultSettings().Height
			local minValue, maxValue, step = 16, 60, 2

			local function GetValue()
				return TargetedSpellsSaved.Settings.Party.Height
			end

			local function SetValue(value)
				TargetedSpellsSaved.Settings.Party.Height = value

				Private.EventRegistry:TriggerEvent(
					Private.Events.SETTING_CHANGED,
					key,
					TargetedSpellsSaved.Settings.Party.Height
				)
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				"Height",
				defaultValue,
				GetValue,
				SetValue
			)
			local options = Settings.CreateSliderOptions(minValue, maxValue, step)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)

			local initializer = Settings.CreateSlider(category, setting, options, "Tooltip")
			initializer:SetParentInitializer(generalCategoryEnabledInitializer, IsSectionEnabled)
		end

		-- Frame Spacing
		do
			local key = Private.Settings.Keys.Party.Spacing
			local defaultValue = Private.Settings.GetPartyDefaultSettings().Spacing
			local minValue, maxValue, step = 0, 20, 2

			local function GetValue()
				return TargetedSpellsSaved.Settings.Party.Spacing
			end

			local function SetValue(value)
				TargetedSpellsSaved.Settings.Party.Spacing = value

				Private.EventRegistry:TriggerEvent(
					Private.Events.SETTING_CHANGED,
					key,
					TargetedSpellsSaved.Settings.Party.Spacing
				)
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				"Spacing",
				defaultValue,
				GetValue,
				SetValue
			)
			local options = Settings.CreateSliderOptions(minValue, maxValue, step)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)

			local initializer = Settings.CreateSlider(category, setting, options, "Tooltip")
			initializer:SetParentInitializer(generalCategoryEnabledInitializer, IsSectionEnabled)
		end

		-- Grow Direction
		do
			local key = Private.Settings.Keys.Party.GrowDirection
			local defaultValue = Private.Settings.GetPartyDefaultSettings().GrowDirection

			local function GetValue()
				return TargetedSpellsSaved.Settings.Party.GrowDirection
			end

			local function SetValue(value)
				TargetedSpellsSaved.Settings.Party.GrowDirection = value

				Private.EventRegistry:TriggerEvent(
					Private.Events.SETTING_CHANGED,
					key,
					TargetedSpellsSaved.Settings.Party.GrowDirection
				)
			end

			local function GetOptions()
				local container = Settings.CreateControlTextContainer()

				container:Add(1, "Horizontal")
				container:Add(2, "Vertical")

				return container:GetData()
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				"Grow Direction",
				defaultValue,
				GetValue,
				SetValue
			)
			local initializer = Settings.CreateDropdown(category, setting, GetOptions, "Tooltip")
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
				tooltip:AddLine("Click to open settings")
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
