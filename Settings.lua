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
		Gap = "FRAME_GAP_SELF",
		Direction = "GROW_DIRECTION_SELF",
		OffsetX = "FRAME_OFFSET_X_SELF",
		OffsetY = "FRAME_OFFSET_Y_SELF",
		SortOrder = "FRAME_SORT_ORDER_SELF",
		Grow = "FRAME_GROW_SELF",
	},
	Party = {
		Enabled = "ENABLED_PARTY",
		LoadConditionContentType = "LOAD_CONDITION_CONTENT_TYPE_PARTY",
		LoadConditionRole = "LOAD_CONDITION_ROLE_PARTY",
		Width = "FRAME_WIDTH_PARTY",
		Height = "FRAME_HEIGHT_PARTY",
		Gap = "FRAME_GAP_PARTY",
		Direction = "GROW_DIRECTION_PARTY",
		OffsetX = "FRAME_OFFSET_X_PARTY",
		OffsetY = "FRAME_OFFSET_Y_PARTY",
		SourceAnchor = "FRAME_SOURCE_ANCHOR_PARTY",
		TargetAnchor = "FRAME_TARGET_ANCHOR_PARTY",
		SortOrder = "FRAME_SORT_ORDER_PARTY",
		Grow = "FRAME_GROW_PARTY",
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
		Sound = "bloop",
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
	}
end

---@return SavedVariablesSettingsParty
function Private.Settings.GetPartyDefaultSettings()
	return {
		Enabled = true,
		Width = 24,
		Height = 24,
		Gap = 6,
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

				local width, height, gap, direction =
					TargetedSpellsSaved.Settings.Self.Width,
					TargetedSpellsSaved.Settings.Self.Height,
					TargetedSpellsSaved.Settings.Self.Gap,
					TargetedSpellsSaved.Settings.Self.Direction

				local isHorizontal = direction == Private.Enum.Direction.Horizontal

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
					local totalWidth = (activeFrameCount * width) + (activeFrameCount - 1) * gap

					for i, frame in ipairs(activeFrames) do
						local x = (i - 1) * width + (i - 1) * gap - totalWidth / 2
						frame:Reposition("LEFT", previewContainer, "CENTER", x, 0)
					end
				else
					local totalHeight = (activeFrameCount * height) + (activeFrameCount - 1) * gap

					for i, frame in ipairs(activeFrames) do
						local y = (i - 1) * height + (i - 1) * gap - totalHeight / 2
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
										key == Private.Settings.Keys.Self.Gap
										or key == Private.Settings.Keys.Self.Direction
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
					local hasChanges = false

					for id, value in pairs(defaults) do
						if TargetedSpellsSaved.Settings.Self.LoadConditionContentType[id] ~= value then
							TargetedSpellsSaved.Settings.Self.LoadConditionContentType[id] = value
							hasChanges = true
						end
					end

					if hasChanges then
						Private.EventRegistry:TriggerEvent(
							Private.Events.SETTING_CHANGED,
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
					local hasChanges = false

					for id, value in pairs(defaults) do
						if TargetedSpellsSaved.Settings.Self.LoadConditionRole[id] ~= value then
							TargetedSpellsSaved.Settings.Self.LoadConditionRole[id] = value
							hasChanges = true
						end
					end

					if hasChanges then
						Private.EventRegistry:TriggerEvent(
							Private.Events.SETTING_CHANGED,
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
					Private.Events.SETTING_CHANGED,
					key,
					TargetedSpellsSaved.Settings.Self.Gap
				)
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				"Gap",
				defaultValue,
				GetValue,
				SetValue
			)
			local options = Settings.CreateSliderOptions(sliderSettings.min, sliderSettings.max, sliderSettings.step)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)

			local initializer = Settings.CreateSlider(category, setting, options, "Tooltip")
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
					Private.Events.SETTING_CHANGED,
					key,
					TargetedSpellsSaved.Settings.Self.Direction
				)
			end

			local function GetOptions()
				local container = Settings.CreateControlTextContainer()

				for k in pairs(Private.Enum.Direction) do
					container:Add(k, k)
				end

				return container:GetData()
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.String,
				"Direction",
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

		-- Frame Gap
		do
			local key = Private.Settings.Keys.Party.Gap
			local defaultValue = Private.Settings.GetPartyDefaultSettings().Gap
			local minValue, maxValue, step = 0, 20, 2

			local function GetValue()
				return TargetedSpellsSaved.Settings.Party.Gap
			end

			local function SetValue(value)
				TargetedSpellsSaved.Settings.Party.Gap = value

				Private.EventRegistry:TriggerEvent(
					Private.Events.SETTING_CHANGED,
					key,
					TargetedSpellsSaved.Settings.Party.Gap
				)
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				"Gap",
				defaultValue,
				GetValue,
				SetValue
			)
			local options = Settings.CreateSliderOptions(minValue, maxValue, step)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)

			local initializer = Settings.CreateSlider(category, setting, options, "Tooltip")
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
					Private.Events.SETTING_CHANGED,
					key,
					TargetedSpellsSaved.Settings.Party.Direction
				)
			end

			local function GetOptions()
				local container = Settings.CreateControlTextContainer()

				for k in pairs(Private.Enum.Direction) do
					container:Add(k, k)
				end

				return container:GetData()
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.String,
				"Direction",
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
