---@type string, TargetedSpells
local addonName, Private = ...

do
	local settingsName = "Targeted Spells"
	local category, layout = Settings.RegisterVerticalLayoutCategory(settingsName)

	local loadContexts = {
		{
			id = 1,
			label = "Open World",
			tooltip = "Tooltip",
			enabled = function()
				return TargetedSpellsSaved.Settings.Self.LoadConditionContentType[Private.Enum.ContentType.OpenWorld]
					== true
			end,
			toggle = function()
				TargetedSpellsSaved.LoadConditionContentType[Private.Enum.ContentType.OpenWorld] =
					not TargetedSpellsSaved.LoadConditionContentType[Private.Enum.ContentType.OpenWorld]
			end,
			soundEnabled = function()
				return TargetedSpellsSaved.SoundLoadContexts[Private.Enum.ContentType.OpenWorld] == true
			end,
			toggleSound = function()
				TargetedSpellsSaved.SoundLoadContexts[Private.Enum.ContentType.OpenWorld] =
					not TargetedSpellsSaved.SoundLoadContexts[Private.Enum.ContentType.OpenWorld]
			end,
		},
		{
			id = 2,
			label = "Delve",
			tooltip = "Tooltip",
			enabled = function()
				return TargetedSpellsSaved.LoadConditionContentType[2] == true
			end,
			toggle = function()
				TargetedSpellsSaved.LoadConditionContentType[2] = not TargetedSpellsSaved.LoadConditionContentType[2]
			end,
			soundEnabled = function()
				return TargetedSpellsSaved.SoundLoadContexts[2] == true
			end,
			toggleSound = function()
				TargetedSpellsSaved.SoundLoadContexts[2] = not TargetedSpellsSaved.SoundLoadContexts[2]
			end,
		},
		{
			id = 3,
			label = "Dungeon",
			tooltip = "Tooltip",
			enabled = function()
				return TargetedSpellsSaved.LoadConditionContentType[3] == true
			end,
			toggle = function()
				TargetedSpellsSaved.LoadConditionContentType[3] = not TargetedSpellsSaved.LoadConditionContentType[3]
			end,
			soundEnabled = function()
				return TargetedSpellsSaved.SoundLoadContexts[3] == true
			end,
			toggleSound = function()
				TargetedSpellsSaved.SoundLoadContexts[3] = not TargetedSpellsSaved.SoundLoadContexts[3]
			end,
		},
		{
			id = 4,
			label = "Raid",
			tooltip = "Tooltip",
			enabled = function()
				return TargetedSpellsSaved.LoadConditionContentType[4] == true
			end,
			toggle = function()
				TargetedSpellsSaved.LoadConditionContentType[4] = not TargetedSpellsSaved.LoadConditionContentType[4]
			end,
			soundEnabled = function()
				return TargetedSpellsSaved.SoundLoadContexts[4] == true
			end,
			toggleSound = function()
				TargetedSpellsSaved.SoundLoadContexts[4] = not TargetedSpellsSaved.SoundLoadContexts[4]
			end,
		},
		{
			id = 5,
			label = "Arena",
			tooltip = "Tooltip",
			enabled = function()
				return TargetedSpellsSaved.LoadConditionContentType[5] == true
			end,
			toggle = function()
				TargetedSpellsSaved.LoadConditionContentType[5] = not TargetedSpellsSaved.LoadConditionContentType[5]
			end,
			soundEnabled = function()
				return TargetedSpellsSaved.SoundLoadContexts[5] == true
			end,
			toggleSound = function()
				TargetedSpellsSaved.SoundLoadContexts[5] = not TargetedSpellsSaved.SoundLoadContexts[5]
			end,
		},
		{
			id = 6,
			label = "Battleground",
			tooltip = "Tooltip",
			enabled = function()
				return TargetedSpellsSaved.LoadConditionContentType[6] == true
			end,
			toggle = function()
				TargetedSpellsSaved.LoadConditionContentType[6] = not TargetedSpellsSaved.LoadConditionContentType[6]
			end,
			soundEnabled = function()
				return TargetedSpellsSaved.SoundLoadContexts[6] == true
			end,
			toggleSound = function()
				TargetedSpellsSaved.SoundLoadContexts[6] = not TargetedSpellsSaved.SoundLoadContexts[6]
			end,
		},
	}

	local roleOptions = {
		{
			id = 1,
			label = "Healer",
			tooltip = "Tooltip",
			enabled = function()
				return TargetedSpellsSaved.RoleLoadContext.Healer == true
			end,
			toggle = function()
				TargetedSpellsSaved.RoleLoadContext.Healer = not TargetedSpellsSaved.RoleLoadContext.Healer
			end,
		},
		{
			id = 2,
			label = "Tank",
			tooltip = "Tooltip",
			enabled = function()
				return TargetedSpellsSaved.RoleLoadContext.Tank == true
			end,
			toggle = function()
				TargetedSpellsSaved.RoleLoadContext.Tank = not TargetedSpellsSaved.RoleLoadContext.Tank
			end,
		},
		{
			id = 3,
			label = "DPS",
			tooltip = "Tooltip",
			enabled = function()
				return TargetedSpellsSaved.RoleLoadContext.Damager == true
			end,
			toggle = function()
				TargetedSpellsSaved.RoleLoadContext.Damager = not TargetedSpellsSaved.RoleLoadContext.Damager
			end,
		},
	}

	if Private.IsMidnight then
		-- Active In Content...
		do
			-- todo: test whether this needs an impl
			local function ResetToDefault()
				return 0
			end

			local function GetOptions()
				local container = Settings.CreateControlTextContainer()

				for _, context in pairs(loadContexts) do
					container:AddCheckbox(context.id, context.label, context.tooltip, context.enabled, context.toggle)
				end

				return container:GetData()
			end

			local setting = Settings.RegisterProxySetting(
				category,
				"ACTIVE_FOR_CONTENT_TYPES",
				Settings.VarType.Number,
				"Load Context",
				ResetToDefault,
				function()
					return true
				end,
				function() end
			)
			local initializer = Settings.CreateDropdown(category, setting, GetOptions, "Tooltip")
			initializer.hideSteppers = true
		end

		-- Active As Roles
		do
			-- todo: test whether this needs an impl
			local function ResetToDefault()
				return 0
			end

			local function GetValueDummy()
				return true
			end
			local function SetValueDummy() end

			local function GetOptions()
				local container = Settings.CreateControlTextContainer()

				for _, context in pairs(roleOptions) do
					container:AddCheckbox(context.id, context.label, context.tooltip, context.enabled, context.toggle)
				end

				return container:GetData()
			end

			local setting = Settings.RegisterProxySetting(
				category,
				"ACTIVE_FOR_ROLES",
				Settings.VarType.Number,
				"Active As Roles",
				ResetToDefault,
				GetValueDummy,
				SetValueDummy
			)
			local initializer = Settings.CreateDropdown(category, setting, GetOptions, "Tooltip")
			initializer.hideSteppers = true
		end
	end

	-- Frame Selection
	do
		local minValue, maxValue, step = 4, 100, 2

		local function GetValue()
			return TargetedSpellsSaved.Dimensions
		end

		local function SetValue(value)
			TargetedSpellsSaved.Dimensions = value
		end

		local setting = Settings.RegisterProxySetting(
			category,
			"FRAME_DIMENSIONS",
			Settings.VarType.Number,
			"Frame Dimensions",
			48,
			GetValue,
			SetValue
		)
		local options = Settings.CreateSliderOptions(minValue, maxValue, step)
		options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)

		Settings.CreateSlider(category, setting, options, "Tooltip")
	end

	-- Frame Gap
	do
		local minValue, maxValue, step = 0, 16, 2

		local function GetValue()
			return TargetedSpellsSaved.Gap
		end

		local function SetValue(value)
			TargetedSpellsSaved.Spacing = value
		end

		local setting = Settings.RegisterProxySetting(
			category,
			"FRAME_SPACING",
			Settings.VarType.Number,
			"Frame Spacing",
			2,
			GetValue,
			SetValue
		)
		local options = Settings.CreateSliderOptions(minValue, maxValue, step)
		options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)

		Settings.CreateSlider(category, setting, options, "Tooltip")
	end

	-- Play Sound
	do
		local function GetValue()
			return TargetedSpellsSaved.PlaySound
		end

		local function SetValue(value)
			TargetedSpellsSaved.PlaySound = value
		end

		local setting = Settings.RegisterProxySetting(
			category,
			"PLAY_SOUND",
			Settings.VarType.Boolean,
			"Play Sound",
			Settings.Default.True,
			GetValue,
			SetValue
		)

		local function GetOptions()
			local container = Settings.CreateControlTextContainer()
			container:Add("bloop", "Bloop")
			return container:GetData()
		end

		local function GetDropdownValue()
			return TargetedSpellsSaved.Sound
		end

		local function SetDropdownValue(value)
			TargetedSpellsSaved.Sound = value
		end
		local defaultValue = "Bloop"

		local dropdownSetting = Settings.RegisterProxySetting(
			category,
			"SOUND",
			Settings.VarType.String,
			"Sound",
			defaultValue,
			GetDropdownValue,
			SetDropdownValue
		)

		local playSoundInitializer = CreateSettingsCheckboxDropdownInitializer(
			setting,
			"Play Sound",
			"Play Sound Tooltip",
			dropdownSetting,
			GetOptions,
			"Dropdown Label?",
			"Dropdown Tooltip?"
		)

		layout:AddInitializer(playSoundInitializer)

		if Private.IsMidnight then
			-- Sound in Content
			do
				local function ResetToDefault()
					return 0
				end

				local function GetValueDummy()
					return true
				end
				local function SetValueDummy() end

				local function GetSoundContextOptions()
					local container = Settings.CreateControlTextContainer()

					for _, context in pairs(loadContexts) do
						container:AddCheckbox(
							context.id,
							context.label,
							context.tooltip,
							context.soundEnabled,
							context.toggleSound
						)
					end

					return container:GetData()
				end

				local playSoundInContextSetting = Settings.RegisterProxySetting(
					category,
					"SOUND_ACTIVE_FOR_CONTENT_TYPES",
					Settings.VarType.Number,
					"Play Sound In Context",
					ResetToDefault,
					GetValueDummy,
					SetValueDummy
				)
				local initializer =
					Settings.CreateDropdown(category, playSoundInContextSetting, GetSoundContextOptions, "Tooltip")
				initializer.hideSteppers = true

				local function IsParentSelected()
					return TargetedSpellsSaved.PlaySound
				end

				-- by default, returns nil but needs to return the checkbox to make the IsParentSelected check reactive on parent state change
				function playSoundInitializer:GetSetting()
					return setting
				end

				initializer:SetParentInitializer(playSoundInitializer, IsParentSelected)
			end
		end
	end

	-- Show Border
	do
		local function GetValue()
			return TargetedSpellsSaved.ShowBorder
		end

		local function SetValue(value)
			TargetedSpellsSaved.ShowBorder = value
		end

		local setting = Settings.RegisterProxySetting(
			category,
			"SHOW_FRAME_BORDER",
			Settings.VarType.Boolean,
			"Border",
			Settings.Default.True,
			GetValue,
			SetValue
		)

		Settings.CreateCheckbox(category, setting, "Tooltip")
	end

	-- Show Swipe
	do
		local function GetValue()
			return TargetedSpellsSaved.ShowSwipe
		end

		local function SetValue(value)
			TargetedSpellsSaved.ShowSwipe = value
		end

		local setting = Settings.RegisterProxySetting(
			category,
			"SHOW_FRAME_SWIPE",
			Settings.VarType.Boolean,
			"Swipe",
			Settings.Default.True,
			GetValue,
			SetValue
		)

		Settings.CreateCheckbox(category, setting, "Tooltip")
	end

	-- Show Remaining Time
	do
		local function GetValue()
			return TargetedSpellsSaved.ShowRemainingTime
		end

		local function SetValue(value)
			TargetedSpellsSaved.ShowRemainingTime = value
		end

		local setting = Settings.RegisterProxySetting(
			category,
			"SHOW_REMAINING_TIME",
			Settings.VarType.Boolean,
			"Display Remaining Time",
			Settings.Default.True,
			GetValue,
			SetValue
		)

		Settings.CreateCheckbox(category, setting, "Tooltip")
	end
end
