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
		Opacity = "OPACITY_SELF",
		IconZoom = "ICON_ZOOM_SELF",
		Import = "IMPORT_SELF",
		Export = "EXPORT_SELF",
		Font = "FONT_SELF",
		FontFlags = "FONT_FLAGS_SELF",
		FeatureFlags = "FEATURE_FLAGS_SELF",
		BorderStyle = "BORDER_STYLE_SELF",
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
		Opacity = "OPACITY_PARTY",
		Import = "IMPORT_PARTY",
		Export = "EXPORT_PARTY",
		Font = "FONT_PARTY",
		FontFlags = "FONT_FLAGS_PARTY",
		FeatureFlags = "FEATURE_FLAGS_PARTY",
		-- todo: implement these
		-- TankColor = "TANK_COLOR_PARTY",
		-- HealerColor = "HEALER_COLOR_PARTY",
		-- DamageColor = "DAMAGE_COLOR_PARTY",
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
			Private.Settings.Keys.Self.GlowType,
			Private.Settings.Keys.Self.FeatureFlags,
			Private.Settings.Keys.Self.BorderStyle,
			Private.Settings.Keys.Self.Font,
			Private.Settings.Keys.Self.FontSize,
			Private.Settings.Keys.Self.FontFlags,
			Private.Settings.Keys.Self.Opacity,
			Private.Settings.Keys.Self.IconZoom,
		}
	end

	return {
		Private.Settings.Keys.Party.Enabled,
		Private.Settings.Keys.Party.LoadConditionContentType,
		Private.Settings.Keys.Party.LoadConditionRole,
		Private.Settings.Keys.Party.Width,
		Private.Settings.Keys.Party.Height,
		Private.Settings.Keys.Party.Gap,
		Private.Settings.Keys.Party.Direction,
		Private.Settings.Keys.Party.SortOrder,
		Private.Settings.Keys.Party.GlowType,
		Private.Settings.Keys.Party.FeatureFlags,
		Private.Settings.Keys.Party.Font,
		Private.Settings.Keys.Party.FontSize,
		Private.Settings.Keys.Party.FontFlags,
		Private.Settings.Keys.Party.Opacity,
	}
end

function Private.Settings.GetFeatureFlagsForKind(kind)
	if kind == Private.Enum.FrameKind.Self then
		return {
			Private.Enum.FeatureFlag.GlowImportant,
			Private.Enum.FeatureFlag.OnlyImportant,
			Private.Enum.FeatureFlag.ShowDuration,
			Private.Enum.FeatureFlag.ShowDurationFractions,
			Private.Enum.FeatureFlag.ShowSwipe,
			Private.Enum.FeatureFlag.IndicateInterrupts,
			Private.Enum.FeatureFlag.RenderInterruptSourceName,
		}
	end

	return {
		Private.Enum.FeatureFlag.IndicateInterrupts,
		Private.Enum.FeatureFlag.RenderInterruptSourceName,
		Private.Enum.FeatureFlag.ShowIcon,
		Private.Enum.FeatureFlag.ShowTargetMarker,
		Private.Enum.FeatureFlag.ShowName,
	}
end

function Private.Settings.GetDefaultSelfEditModeFramePosition()
	return { point = "CENTER", x = 0, y = 100 }
end

function Private.Settings.GetDefaultBarsEditModeFramePosition()
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

	if key == Private.Settings.Keys.Self.IconZoom or key == Private.Settings.Keys.Party.IconZoom then
		return {
			min = 1,
			max = 2,
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

	if key == Private.Settings.Keys.Party.Width then
		return {
			min = 60,
			max = 400,
			step = 1,
		}
	end

	if key == Private.Settings.Keys.Party.Height then
		return {
			min = 10,
			max = 60,
			step = 1,
		}
	end

	if key == Private.Settings.Keys.Self.Gap then
		return {
			min = -100,
			max = 100,
			step = 1,
		}
	end

	if key == Private.Settings.Keys.Party.Gap then
		return {
			min = -60,
			max = 60,
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
		SortOrder = Private.Enum.SortOrder.Ascending,
		Grow = Private.Enum.Grow.Start,
		FontSize = 20,
		Position = Private.Settings.GetDefaultSelfEditModeFramePosition(),
		Opacity = 1,
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
			[Private.Enum.FeatureFlag.ShowDurationFractions] = true,
			[Private.Enum.FeatureFlag.ShowSwipe] = true,
			[Private.Enum.FeatureFlag.IndicateInterrupts] = false,
			[Private.Enum.FeatureFlag.RenderInterruptSourceName] = false,
		},
		BorderStyle = "Blizzard Tooltip Border",
	}
end

---@return SavedVariablesSettingsParty
function Private.Settings.GetPartyDefaultSettings()
	return {
		Enabled = true,
		Width = 200,
		Height = 20,
		FontSize = 14,
		Gap = 2,
		Direction = Private.Enum.Direction.Vertical,
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
		Opacity = 1,
		GlowType = Private.Enum.GlowType.PixelGlow,
		Font = "Fonts\\FRIZQT__.TTF",
		FontFlags = {
			[Private.Enum.FontFlags.OUTLINE] = true,
			[Private.Enum.FontFlags.SHADOW] = false,
		},
		FeatureFlags = {
			[Private.Enum.FeatureFlag.IndicateInterrupts] = true,
			[Private.Enum.FeatureFlag.RenderInterruptSourceName] = true,
			[Private.Enum.FeatureFlag.ShowIcon] = true,
			[Private.Enum.FeatureFlag.ShowTargetMarker] = true,
			[Private.Enum.FeatureFlag.ShowName] = true,
		},
		Position = Private.Settings.GetDefaultBarsEditModeFramePosition(),
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

function Private.Settings.IsContentTypeAvailableForKind(kind, contentTypeId)
	if kind == Private.Enum.FrameKind.Self then
		return true
	end

	if kind == Private.Enum.FrameKind.Party then
		return contentTypeId ~= Private.Enum.ContentType.Raid
	end

	return true
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
		if key == Private.Settings.Keys.Self.FontFlags or key == Private.Settings.Keys.Party.FontFlags then
			local kindTableRef = key == Private.Settings.Keys.Self.FontFlags and TargetedSpellsSaved.Settings.Self
				or TargetedSpellsSaved.Settings.Party

			local defaultValue = GetMask(Private.Enum.FontFlags, function(id)
				return defaults.FontFlags[id]
			end)

			local function GetValue()
				return GetMask(Private.Enum.FontFlags, function(id)
					return kindTableRef.FontFlags[id]
				end)
			end

			local function SetValue(mask)
				local hasChanges = false

				for label, id in pairs(Private.Enum.FontFlags) do
					local enabled = DecodeBitToBool(mask, id)

					if enabled ~= kindTableRef.FontFlags[id] then
						kindTableRef.FontFlags[id] = enabled
						hasChanges = true
					end
				end

				if hasChanges then
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, kindTableRef.FontFlags)
				end
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				L.Settings.FontFlagsLabel,
				defaultValue,
				GetValue,
				SetValue
			)

			local function GetOptions()
				local container = Settings.CreateControlTextContainer()

				for label, id in pairs(Private.Enum.FontFlags) do
					local translated = L.Settings.FontFlagsLabels[id]

					container:AddCheckbox(id, translated, L.Settings.FontFlagsTooltip)
				end

				return container:GetData()
			end

			local initializer = Settings.CreateDropdown(category, setting, GetOptions, L.Settings.FontFlagsTooltip)

			return {
				initializer = initializer,
				hideSteppers = true,
				IsSectionEnabled = nil,
			}
		end

		if key == Private.Settings.Keys.Self.Font or key == Private.Settings.Keys.Party.Font then
			local tableRef = key == Private.Settings.Keys.Self.Font and TargetedSpellsSaved.Settings.Self
				or TargetedSpellsSaved.Settings.Party

			local function GetValue()
				return tableRef.Font
			end

			local function SetValue(value)
				if value ~= tableRef.Font then
					tableRef.Font = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end

			local function GetOptions()
				local container = Settings.CreateControlTextContainer()
				local fontInfo = Private.Settings.GetFontOptions()

				for label, path in pairs(fontInfo.byLabel) do
					container:Add(path, label)
				end

				return container:GetData()
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.String,
				L.Settings.FontLabel,
				defaults.Font,
				GetValue,
				SetValue
			)
			local initializer = Settings.CreateDropdown(category, setting, GetOptions, L.Settings.FontTooltip)

			return {
				initializer = initializer,
				hideSteppers = false,
				IsSectionEnabled = nil,
			}
		end

		if key == Private.Settings.Keys.Self.BorderStyle or key == Private.Settings.Keys.Party.BorderStyle then
			local tableRef = key == Private.Settings.Keys.Self.BorderStyle and TargetedSpellsSaved.Settings.Self
				or TargetedSpellsSaved.Settings.Party

			local function GetValue()
				return tableRef.BorderStyle
			end

			local function SetValue(value)
				if value ~= tableRef.BorderStyle then
					tableRef.BorderStyle = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end

			local function GetOptions()
				local container = Settings.CreateControlTextContainer()

				for _, label in ipairs(Private.Settings.GetBorderOptions()) do
					container:Add(label, label)
				end

				return container:GetData()
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.String,
				L.Settings.BorderStyleLabel,
				defaults.BorderStyle,
				GetValue,
				SetValue
			)
			local initializer = Settings.CreateDropdown(category, setting, GetOptions, L.Settings.BorderStyleTooltip)

			return {
				initializer = initializer,
				hideSteppers = false,
				IsSectionEnabled = nil,
			}
		end

		if key == Private.Settings.Keys.Self.FeatureFlags or key == Private.Settings.Keys.Party.FeatureFlags then
			local kind = key == Private.Settings.Keys.Self.FeatureFlags and Private.Enum.FrameKind.Self
				or Private.Enum.FrameKind.Party
			local kindTableRef = kind == Private.Enum.FrameKind.Self and TargetedSpellsSaved.Settings.Self
				or TargetedSpellsSaved.Settings.Party
			local applicableFlags = Private.Settings.GetFeatureFlagsForKind(kind)

			local defaultValue = GetMask(applicableFlags, function(id)
				return defaults.FeatureFlags[id]
			end)

			local function GetValue()
				return GetMask(applicableFlags, function(id)
					return kindTableRef.FeatureFlags[id]
				end)
			end

			local function SetValue(mask)
				for _, id in ipairs(applicableFlags) do
					local enabled = DecodeBitToBool(mask, id)
					if enabled ~= kindTableRef.FeatureFlags[id] then
						kindTableRef.FeatureFlags[id] = enabled
						Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, id, enabled)
					end
				end
			end

			local function GetOptions()
				local container = Settings.CreateControlTextContainer()

				for _, id in ipairs(applicableFlags) do
					container:AddCheckbox(id, L.Settings.FeatureFlagLabels[id], L.Settings.FeatureFlagsTooltip)
				end

				return container:GetData()
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				L.Settings.FeatureFlagsLabel,
				defaultValue,
				GetValue,
				SetValue
			)

			local initializer = Settings.CreateDropdown(category, setting, GetOptions, L.Settings.FeatureFlagsTooltip)

			return {
				initializer = initializer,
				hideSteppers = true,
				IsSectionEnabled = nil,
			}
		end

		if key == Private.Settings.Keys.Self.Enabled or key == Private.Settings.Keys.Party.Enabled then
			local tableRef = key == Private.Settings.Keys.Self.Enabled and TargetedSpellsSaved.Settings.Self
				or TargetedSpellsSaved.Settings.Party

			local function GetValue()
				return tableRef.Enabled
			end

			local function SetValue(value)
				if value ~= tableRef.Enabled then
					tableRef.Enabled = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, tableRef.Enabled)
				end
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

		if key == Private.Settings.Keys.Party.TargetAnchor then
			local function GetValue()
				return TargetedSpellsSaved.Settings.Party.TargetAnchor
			end

			local function SetValue(value)
				if value ~= TargetedSpellsSaved.Settings.Party.TargetAnchor then
					TargetedSpellsSaved.Settings.Party.TargetAnchor = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
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
				if value ~= TargetedSpellsSaved.Settings.Party.SourceAnchor then
					TargetedSpellsSaved.Settings.Party.SourceAnchor = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
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

		if key == Private.Settings.Keys.Self.IconZoom or key == Private.Settings.Keys.Party.IconZoom then
			local tableRef = key == Private.Settings.Keys.Self.IconZoom and TargetedSpellsSaved.Settings.Self
				or TargetedSpellsSaved.Settings.Party
			local sliderSettings = Private.Settings.GetSliderSettingsForOption(key)

			local function GetValue()
				return tableRef.IconZoom
			end

			local function SetValue(value)
				if value ~= tableRef.IconZoom then
					tableRef.IconZoom = value

					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				L.Settings.IconZoomLabel,
				defaults.IconZoom,
				GetValue,
				SetValue
			)
			local options = Settings.CreateSliderOptions(sliderSettings.min, sliderSettings.max, sliderSettings.step)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, FormatPercentage)

			local initializer = Settings.CreateSlider(category, setting, options, L.Settings.IconZoomTooltip)

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
				if value ~= tableRef.GlowType then
					tableRef.GlowType = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
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

		if key == Private.Settings.Keys.Self.Grow or key == Private.Settings.Keys.Party.Grow then
			local tableRef = key == Private.Settings.Keys.Self.Grow and TargetedSpellsSaved.Settings.Self
				or TargetedSpellsSaved.Settings.Party

			local function GetValue()
				return tableRef.Grow
			end

			local function SetValue(value)
				if value ~= tableRef.Grow then
					tableRef.Grow = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
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
				if value ~= tableRef.SortOrder then
					tableRef.SortOrder = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
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
				if value ~= tableRef.Direction then
					tableRef.Direction = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
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

		if
			key == Private.Settings.Keys.Self.LoadConditionContentType
			or key == Private.Settings.Keys.Party.LoadConditionContentType
		then
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

					container:AddCheckbox(id, translated, L.Settings.LoadConditionContentTypeTooltip, IsEnabled, Toggle)
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

		error(string.format("CreateSetting not implemented for key '%s'", key))
	end

	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L.Settings.EditModeReminder))

	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L.EditMode.TargetedSpellsSelfLabel))

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

	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L.EditMode.TargetedSpellsPartyLabel))

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
