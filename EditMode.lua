---@type string, TargetedSpells
local addonName, Private = ...
local LEM = LibStub("LibEditMode")

---@class TargetedSpellsEditModeMixin
local TargetedSpellsEditModeMixin = {}

function TargetedSpellsEditModeMixin:Init(displayName, frameKind)
	self.frameKind = frameKind
	self.demoPlaying = false
	self.framePool = CreateFramePool("Frame", UIParent, "TargetedSpellsFrameTemplate")
	self.frames = {}
	self.demoTimers = {
		tickers = {},
		timers = {},
	}
	self.editModeFrame = CreateFrame("Frame", displayName, UIParent)
	self.editModeFrame:SetClampedToScreen(true)

	Private.EventRegistry:RegisterCallback(Private.Enum.Events.SETTING_CHANGED, self.OnSettingsChanged, self)

	LEM:RegisterCallback("enter", GenerateClosure(self.StartDemo, self))
	LEM:RegisterCallback("exit", GenerateClosure(self.EndDemo, self))

	self:AppendSettings()
end

function TargetedSpellsEditModeMixin:OnSettingsChanged(key, value)
	if
		-- self
		key == Private.Settings.Keys.Self.Gap
		or key == Private.Settings.Keys.Self.Direction
		or key == Private.Settings.Keys.Self.Width
		or key == Private.Settings.Keys.Self.Height
		or key == Private.Settings.Keys.Self.SortOrder
		or key == Private.Settings.Keys.Self.Grow
		or key == Private.Settings.Keys.Self.MaxFrames
		or key == Private.Settings.Keys.Self.GlowImportant
		-- party
		or key == Private.Settings.Keys.Party.Gap
		or key == Private.Settings.Keys.Party.Direction
		or key == Private.Settings.Keys.Party.Width
		or key == Private.Settings.Keys.Party.Height
		or key == Private.Settings.Keys.Party.OffsetX
		or key == Private.Settings.Keys.Party.OffsetY
		or key == Private.Settings.Keys.Party.SourceAnchor
		or key == Private.Settings.Keys.Party.TargetAnchor
		or key == Private.Settings.Keys.Party.SortOrder
		or key == Private.Settings.Keys.Party.Grow
		or key == Private.Settings.Keys.Party.GlowImportant
	then
		self:OnLayoutSettingChanged(key, value)

		if key == Private.Settings.Keys.Self.MaxFrames then
			if not LEM:IsInEditMode() then
				return
			end

			self:EndDemo()
			self:StartDemo()
		end
	elseif key == Private.Settings.Keys.Self.Enabled or key == Private.Settings.Keys.Party.Enabled then
		if not LEM:IsInEditMode() then
			return
		end

		if
			(key == Private.Settings.Keys.Self.Enabled and self.frameKind == Private.Enum.FrameKind.Self)
			or (key == Private.Settings.Keys.Party.Enabled and self.frameKind == Private.Enum.FrameKind.Party)
		then
			if value then
				self:StartDemo()
			else
				self:EndDemo()
			end
		end
	elseif key == Private.Settings.Keys.Party.IncludeSelfInParty and self.frameKind == Private.Enum.FrameKind.Party then
		if not LEM:IsInEditMode() then
			return
		end

		self:EndDemo()
		self:StartDemo()
	end
end

function TargetedSpellsEditModeMixin:CreateSetting(key)
	local L = Private.L

	if key == Private.Settings.Keys.Self.Opacity or key == Private.Settings.Keys.Party.Opacity then
		local isSelf = key == Private.Settings.Keys.Self.Opacity
		local tableRef = isSelf and TargetedSpellsSaved.Settings.Self or TargetedSpellsSaved.Settings.Party
		local sliderSettings = Private.Settings.GetSliderSettingsForOption(key)

		---@type LibEditModeSlider
		return {
			name = L.Settings.OpacityLabel,
			kind = Enum.EditModeSettingDisplayType.Slider,
			default = isSelf and Private.Settings.GetSelfDefaultSettings().Opacity
				or Private.Settings.GetPartyDefaultSettings().Opacity,
			get = function(layoutName)
				return tableRef.Opacity
			end,
			set = function(layoutName, value)
				if value ~= tableRef.Opacity then
					tableRef.Opacity = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end,
			minValue = sliderSettings.min,
			maxValue = sliderSettings.max,
			valueStep = sliderSettings.step,
			formatter = FormatPercentage,
		}
	end

	if key == Private.Settings.Keys.Self.GlowImportant or key == Private.Settings.Keys.Party.GlowImportant then
		local isSelf = key == Private.Settings.Keys.Self.GlowImportant
		local tableRef = isSelf and TargetedSpellsSaved.Settings.Self or TargetedSpellsSaved.Settings.Party

		---@type LibEditModeCheckbox
		return {
			name = L.Settings.GlowImportantLabel,
			kind = Enum.EditModeSettingDisplayType.Checkbox,
			desc = L.Settings.GlowImportantTooltip,
			default = isSelf and Private.Settings.GetSelfDefaultSettings().GlowImportant
				or Private.Settings.GetPartyDefaultSettings().GlowImportant,
			get =
				---@param layoutName string
				function(layoutName)
					return tableRef.GlowImportant
				end,
			---@param layoutName string
			---@param value boolean
			set = function(layoutName, value)
				if value ~= tableRef.GlowImportant then
					tableRef.GlowImportant = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end,
		}
	end

	if key == Private.Settings.Keys.Self.ShowBorder or key == Private.Settings.Keys.Party.ShowBorder then
		local isSelf = key == Private.Settings.Keys.Self.ShowBorder
		local tableRef = isSelf and TargetedSpellsSaved.Settings.Self or TargetedSpellsSaved.Settings.Party

		---@type LibEditModeCheckbox
		return {
			name = L.Settings.ShowBorderLabel,
			kind = Enum.EditModeSettingDisplayType.Checkbox,
			default = isSelf and Private.Settings.GetSelfDefaultSettings().ShowBorder
				or Private.Settings.GetPartyDefaultSettings().ShowBorder,
			get =
				---@param layoutName string
				function(layoutName)
					return tableRef.ShowBorder
				end,
			---@param layoutName string
			---@param value boolean
			set = function(layoutName, value)
				if value ~= tableRef.ShowBorder then
					tableRef.ShowBorder = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end,
		}
	end

	if key == Private.Settings.Keys.Self.ShowDuration or key == Private.Settings.Keys.Party.ShowDuration then
		local isSelf = key == Private.Settings.Keys.Self.ShowDuration
		local tableRef = isSelf and TargetedSpellsSaved.Settings.Self or TargetedSpellsSaved.Settings.Party

		---@type LibEditModeCheckbox
		return {
			name = L.Settings.ShowDurationLabel,
			kind = Enum.EditModeSettingDisplayType.Checkbox,
			default = isSelf and Private.Settings.GetSelfDefaultSettings().ShowDuration
				or Private.Settings.GetPartyDefaultSettings().ShowDuration,
			get =
				---@param layoutName string
				function(layoutName)
					return tableRef.ShowDuration
				end,
			---@param layoutName string
			---@param value boolean
			set = function(layoutName, value)
				if value ~= tableRef.ShowDuration then
					tableRef.ShowDuration = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end,
		}
	end

	if key == Private.Settings.Keys.Self.PlaySound then
		---@type LibEditModeCheckbox
		return {
			name = L.Settings.PlaySoundLabel,
			kind = Enum.EditModeSettingDisplayType.Checkbox,
			default = Private.Settings.GetSelfDefaultSettings().Enabled,
			get =
				---@param layoutName string
				function(layoutName)
					return TargetedSpellsSaved.Settings.Self.PlaySound
				end,
			---@param layoutName string
			---@param value boolean
			set = function(layoutName, value)
				if value ~= TargetedSpellsSaved.Settings.Self.PlaySound then
					TargetedSpellsSaved.Settings.Self.PlaySound = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end,
		}
	end

	if key == Private.Settings.Keys.Self.SoundChannel then
		---@param layoutName string
		---@param value string
		local function Set(layoutName, value)
			if TargetedSpellsSaved.Settings.Self.SoundChannel ~= value then
				TargetedSpellsSaved.Settings.Self.SoundChannel = value
				Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
			end
		end

		---@type LibEditModeDropdown
		return {
			name = L.Settings.SoundChannelLabel,
			kind = Enum.EditModeSettingDisplayType.Dropdown,
			default = Private.Settings.GetSelfDefaultSettings().SoundChannel,
			generator = function(owner, rootDescription, data)
				for label, enumValue in pairs(Private.Enum.SoundChannel) do
					local function IsEnabled()
						return TargetedSpellsSaved.Settings.Self.SoundChannel == enumValue
					end

					local function SetProxy()
						Set(LEM:GetActiveLayoutName(), enumValue)
					end

					rootDescription:CreateCheckbox(label, IsEnabled, SetProxy, {
						value = label,
						multiple = false,
					})
				end
			end,
			set = Set,
		}
	end

	if key == Private.Settings.Keys.Self.Sound then
		---@param soundCategoryKeyToText table<string, string>
		---@param currentTable table<string, CustomSound[]> | CustomSound[]
		---@param forcePlayOnSelection boolean
		local function RecursiveAddSounds(description, soundCategoryKeyToText, currentTable, forcePlayOnSelection)
			for tableKey, value in pairs(currentTable) do
				if value.soundKitID and value.text then
					local function IsEnabled()
						return value.soundKitID == TargetedSpellsSaved.Settings.Self.Sound
					end

					local function Set()
						if forcePlayOnSelection then
							Private.Utils.AttemptToPlaySound(value.soundKitID, Private.Enum.SoundChannel.Master)
						end

						if value.soundKitID ~= TargetedSpellsSaved.Settings.Self.Sound then
							TargetedSpellsSaved.Settings.Self.Sound = value.soundKitID

							Private.EventRegistry:TriggerEvent(
								Private.Enum.Events.SETTING_CHANGED,
								key,
								TargetedSpellsSaved.Settings.Self.Sound
							)
						end
					end

					local selectPayloadCheckbox = description:CreateCheckbox(value.text, IsEnabled, Set, {
						value = value.text,
						multiple = false,
					})

					if Private.IsMidnight then
						selectPayloadCheckbox:AddInitializer(function(button, description, menu)
							local playSampleButton = MenuTemplates.AttachUtilityButton(button)
							playSampleButton.Texture:Hide()
							playSampleButton:SetNormalTexture("common-icon-sound")
							playSampleButton:SetPushedTexture("common-icon-sound-pressed")
							playSampleButton:SetDisabledTexture("common-icon-sound-disabled")
							playSampleButton:SetHighlightTexture("common-icon-sound", "ADD")
							playSampleButton:GetHighlightTexture():SetAlpha(0.4)

							MenuTemplates.SetUtilityButtonTooltipText(
								playSampleButton,
								COOLDOWN_VIEWER_SETTINGS_ALERT_MENU_PLAY_SAMPLE
							)
							MenuTemplates.SetUtilityButtonAnchor(
								playSampleButton,
								MenuVariants.GearButtonAnchor,
								button
							) -- gear means throw on the right
							MenuTemplates.SetUtilityButtonClickHandler(playSampleButton, function()
								Private.Utils.AttemptToPlaySound(value.soundKitID, Private.Enum.SoundChannel.Master)
							end)
						end)
					end
				elseif type(value) == "table" and soundCategoryKeyToText[tableKey] then
					local nestedDescription = description:CreateButton(soundCategoryKeyToText[tableKey], nop, -1)
					RecursiveAddSounds(nestedDescription, soundCategoryKeyToText, value, forcePlayOnSelection)
				end
			end
		end

		local function AddCooldownViewerSounds(rootDescription)
			local soundInfo = Private.Settings.GetCooldownViewerSounds()

			RecursiveAddSounds(rootDescription, soundInfo.soundCategoryKeyToLabel, soundInfo.data, false)
		end

		local function AddCustomSounds(rootDescription)
			local soundInfo = Private.Settings.GetCustomSoundGroups(34)

			RecursiveAddSounds(rootDescription, soundInfo.soundCategoryKeyToLabel, soundInfo.data, true)
		end

		---@type LibEditModeDropdown
		return {
			name = L.Settings.SoundLabel,
			kind = Enum.EditModeSettingDisplayType.Dropdown,
			desc = L.Settings.SoundTooltip,
			default = Private.Settings.GetSelfDefaultSettings().Sound,
			generator = function(owner, rootDescription, data)
				-- pcall this to guard against internal changes on the cd viewer side
				pcall(AddCooldownViewerSounds, rootDescription)
				-- intentionally separated so if the above fails, we can always at least show Custom sounds
				AddCustomSounds(rootDescription)
			end,
			-- technically is a reset only
			set =
				---@param layoutName string
				---@param values table<string, boolean>
				function(layoutName, values)
					local defaultSound = Private.Settings.GetSelfDefaultSettings().Sound

					if defaultSound ~= TargetedSpellsSaved.Settings.Self.Sound then
						TargetedSpellsSaved.Settings.Self.Sound = defaultSound
						Private.EventRegistry:TriggerEvent(
							Private.Enum.Events.SETTING_CHANGED,
							key,
							TargetedSpellsSaved.Settings.Self.Sound
						)
					end
				end,
		}
	end

	if key == Private.Settings.Keys.Party.IncludeSelfInParty then
		---@type LibEditModeCheckbox
		return {
			name = L.Settings.IncludeSelfInPartyLabel,
			kind = Enum.EditModeSettingDisplayType.Checkbox,
			desc = L.Settings.IncludeSelfInPartyTooltip,
			default = Private.Settings.GetPartyDefaultSettings().IncludeSelfInParty,
			get =
				---@param layoutName string
				function(layoutName)
					return TargetedSpellsSaved.Settings.Party.IncludeSelfInParty
				end,
			---@param layoutName string
			---@param value boolean
			set = function(layoutName, value)
				if value ~= TargetedSpellsSaved.Settings.Party.IncludeSelfInParty then
					TargetedSpellsSaved.Settings.Party.IncludeSelfInParty = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end,
		}
	end

	if key == Private.Settings.Keys.Self.Enabled or key == Private.Settings.Keys.Party.Enabled then
		local isSelf = key == Private.Settings.Keys.Self.Enabled
		local tableRef = isSelf and TargetedSpellsSaved.Settings.Self or TargetedSpellsSaved.Settings.Party

		---@type LibEditModeCheckbox
		return {
			name = L.Settings.EnabledLabel,
			kind = Enum.EditModeSettingDisplayType.Checkbox,
			default = isSelf and Private.Settings.GetSelfDefaultSettings().Enabled
				or Private.Settings.GetPartyDefaultSettings().Enabled,
			get =
				---@param layoutName string
				function(layoutName)
					return tableRef.Enabled
				end,
			---@param layoutName string
			---@param value boolean
			set = function(layoutName, value)
				if value ~= tableRef.Enabled then
					tableRef.Enabled = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end,
		}
	end

	if
		key == Private.Settings.Keys.Self.LoadConditionContentType
		or key == Private.Settings.Keys.Party.LoadConditionContentType
	then
		local isSelf = key == Private.Settings.Keys.Self.LoadConditionContentType
		local kindTableRef = isSelf and TargetedSpellsSaved.Settings.Self or TargetedSpellsSaved.Settings.Party
		local tableRef = isSelf and TargetedSpellsSaved.Settings.Self.LoadConditionContentType
			or TargetedSpellsSaved.Settings.Party.LoadConditionContentType

		---@type LibEditModeDropdown
		return {
			name = L.Settings.LoadConditionContentTypeLabelAbbreviated,
			kind = Enum.EditModeSettingDisplayType.Dropdown,
			default = isSelf and Private.Settings.GetSelfDefaultSettings().LoadConditionContentType
				or Private.Settings.GetPartyDefaultSettings().LoadConditionContentType,
			generator = function(owner, rootDescription, data)
				for label, id in pairs(Private.Enum.ContentType) do
					local function IsEnabled()
						return tableRef[id]
					end

					local function Toggle()
						tableRef[id] = not tableRef[id]

						Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, tableRef)

						local anyEnabled = false
						for role, loadCondition in pairs(tableRef) do
							if loadCondition then
								anyEnabled = true
								break
							end
						end

						if anyEnabled ~= kindTableRef.Enabled then
							kindTableRef.Enabled = anyEnabled
							local enabledKey = isSelf and Private.Settings.Keys.Self.Enabled
								or Private.Settings.Keys.Party.Enabled
							Private.EventRegistry:TriggerEvent(
								Private.Enum.Events.SETTING_CHANGED,
								enabledKey,
								anyEnabled
							)
						end
					end

					local translated = L.Settings.LoadConditionContentTypeLabels[id]
					rootDescription:CreateCheckbox(translated, IsEnabled, Toggle, {
						value = label,
						multiple = true,
					})
				end
			end,
			-- technically is a reset only
			set =
				---@param layoutName string
				---@param values table<string, boolean>
				function(layoutName, values)
					local hasChanges = false

					for id, bool in pairs(values) do
						if tableRef[id] ~= bool then
							tableRef[id] = bool
							hasChanges = true
						end
					end

					if hasChanges then
						Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, tableRef)
					end
				end,
		}
	end

	if key == Private.Settings.Keys.Self.LoadConditionSoundContentType then
		---@type LibEditModeDropdown
		return {
			name = L.Settings.LoadConditionSoundContentTypeLabelAbbreviated,
			kind = Enum.EditModeSettingDisplayType.Dropdown,
			default = Private.Settings.GetSelfDefaultSettings().LoadConditionSoundContentType,
			generator = function(owner, rootDescription, data)
				for label, id in pairs(Private.Enum.ContentType) do
					local function IsEnabled()
						return TargetedSpellsSaved.Settings.Self.LoadConditionSoundContentType[id]
					end

					local function Toggle()
						TargetedSpellsSaved.Settings.Self.LoadConditionSoundContentType[id] =
							not TargetedSpellsSaved.Settings.Self.LoadConditionSoundContentType[id]

						Private.EventRegistry:TriggerEvent(
							Private.Enum.Events.SETTING_CHANGED,
							key,
							TargetedSpellsSaved.Settings.Self.LoadConditionSoundContentType
						)

						local anyEnabled = false
						for role, loadCondition in
							pairs(TargetedSpellsSaved.Settings.Self.LoadConditionSoundContentType)
						do
							if loadCondition then
								anyEnabled = true
								break
							end
						end

						if anyEnabled ~= TargetedSpellsSaved.Settings.Self.PlaySound then
							TargetedSpellsSaved.Settings.Self.PlaySound = anyEnabled
							Private.EventRegistry:TriggerEvent(
								Private.Enum.Events.SETTING_CHANGED,
								Private.Settings.Keys.Self.PlaySound,
								anyEnabled
							)
						end
					end

					local translated = L.Settings.LoadConditionSoundContentTypeLabels[id]
					rootDescription:CreateCheckbox(translated, IsEnabled, Toggle, {
						value = label,
						multiple = true,
					})
				end
			end,
			-- technically is a reset only
			set =
				---@param layoutName string
				---@param values table<string, boolean>
				function(layoutName, values)
					local hasChanges = false

					for id, bool in pairs(values) do
						if TargetedSpellsSaved.Settings.Self.LoadConditionSoundContentType[id] ~= bool then
							TargetedSpellsSaved.Settings.Self.LoadConditionSoundContentType[id] = bool
							hasChanges = true
						end
					end

					if hasChanges then
						Private.EventRegistry:TriggerEvent(
							Private.Enum.Events.SETTING_CHANGED,
							key,
							TargetedSpellsSaved.Settings.Self.LoadConditionSoundContentType
						)
					end
				end,
		}
	end

	if key == Private.Settings.Keys.Self.LoadConditionRole or key == Private.Settings.Keys.Party.LoadConditionRole then
		local isSelf = key == Private.Settings.Keys.Self.LoadConditionRole
		local tableRef = isSelf and TargetedSpellsSaved.Settings.Self.LoadConditionRole
			or TargetedSpellsSaved.Settings.Party.LoadConditionRole

		---@type LibEditModeDropdown
		return {
			name = L.Settings.LoadConditionRoleLabelAbbreviated,
			kind = Enum.EditModeSettingDisplayType.Dropdown,
			default = Private.Settings.GetSelfDefaultSettings().LoadConditionRole,
			generator = function(owner, rootDescription, data)
				for label, id in pairs(Private.Enum.Role) do
					local function IsEnabled()
						return tableRef[id]
					end

					local function Toggle()
						tableRef[id] = not tableRef[id]

						Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, tableRef)
					end

					local translated = L.Settings.LoadConditionRoleLabels[id]

					rootDescription:CreateCheckbox(translated, IsEnabled, Toggle, {
						value = label,
						multiple = true,
					})
				end
			end,
			-- technically is a reset only
			set = function(layoutName, values)
				local hasChanges = false

				for id, bool in pairs(values) do
					if tableRef[id] ~= bool then
						tableRef[id] = bool
						hasChanges = true
					end
				end

				if hasChanges then
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, tableRef)
				end
			end,
		}
	end

	if key == Private.Settings.Keys.Self.FontSize or key == Private.Settings.Keys.Party.FontSize then
		local isSelf = key == Private.Settings.Keys.Self.FontSize
		local tableRef = isSelf and TargetedSpellsSaved.Settings.Self or TargetedSpellsSaved.Settings.Party
		local sliderSettings = Private.Settings.GetSliderSettingsForOption(key)

		---@type LibEditModeSlider
		return {
			name = L.Settings.FontSizeLabel,
			kind = Enum.EditModeSettingDisplayType.Slider,
			default = isSelf and Private.Settings.GetSelfDefaultSettings().FontSize
				or Private.Settings.GetPartyDefaultSettings().FontSize,
			get = function(layoutName)
				return tableRef.FontSize
			end,
			set = function(layoutName, value)
				if value ~= tableRef.FontSize then
					tableRef.FontSize = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end,
			minValue = sliderSettings.min,
			maxValue = sliderSettings.max,
			valueStep = sliderSettings.step,
		}
	end

	if key == Private.Settings.Keys.Self.Width or key == Private.Settings.Keys.Party.Width then
		local isSelf = key == Private.Settings.Keys.Self.Width
		local tableRef = isSelf and TargetedSpellsSaved.Settings.Self or TargetedSpellsSaved.Settings.Party
		local sliderSettings = Private.Settings.GetSliderSettingsForOption(key)

		---@type LibEditModeSlider
		return {
			name = L.Settings.FrameWidthLabel,
			kind = Enum.EditModeSettingDisplayType.Slider,
			default = isSelf and Private.Settings.GetSelfDefaultSettings().Width
				or Private.Settings.GetPartyDefaultSettings().Width,
			get = function(layoutName)
				return tableRef.Width
			end,
			set = function(layoutName, value)
				if value ~= tableRef.Width then
					tableRef.Width = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end,
			minValue = sliderSettings.min,
			maxValue = sliderSettings.max,
			valueStep = sliderSettings.step,
		}
	end

	if key == Private.Settings.Keys.Self.Height or key == Private.Settings.Keys.Party.Height then
		local isSelf = key == Private.Settings.Keys.Self.Height
		local tableRef = isSelf and TargetedSpellsSaved.Settings.Self or TargetedSpellsSaved.Settings.Party
		local sliderSettings = Private.Settings.GetSliderSettingsForOption(key)

		---@type LibEditModeSlider
		return {
			name = L.Settings.FrameHeightLabel,
			kind = Enum.EditModeSettingDisplayType.Slider,
			default = isSelf and Private.Settings.GetSelfDefaultSettings().Height
				or Private.Settings.GetPartyDefaultSettings().Height,
			get = function(layoutName)
				return tableRef.Height
			end,
			set = function(layoutName, value)
				if value ~= tableRef.Height then
					tableRef.Height = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end,
			minValue = sliderSettings.min,
			maxValue = sliderSettings.max,
			valueStep = sliderSettings.step,
		}
	end

	if key == Private.Settings.Keys.Self.Gap or key == Private.Settings.Keys.Party.Gap then
		local isSelf = key == Private.Settings.Keys.Self.Gap
		local tableRef = isSelf and TargetedSpellsSaved.Settings.Self or TargetedSpellsSaved.Settings.Party
		local sliderSettings = Private.Settings.GetSliderSettingsForOption(key)

		---@type LibEditModeSlider
		return {
			name = L.Settings.FrameGapLabel,
			kind = Enum.EditModeSettingDisplayType.Slider,
			default = isSelf and Private.Settings.GetSelfDefaultSettings().Gap
				or Private.Settings.GetPartyDefaultSettings().Gap,
			get = function(layoutName)
				return tableRef.Gap
			end,
			set = function(layoutName, value)
				if value ~= tableRef.Gap then
					tableRef.Gap = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end,
			minValue = sliderSettings.min,
			maxValue = sliderSettings.max,
			valueStep = sliderSettings.step,
		}
	end

	if key == Private.Settings.Keys.Self.Direction or key == Private.Settings.Keys.Party.Direction then
		local isSelf = key == Private.Settings.Keys.Self.Direction
		local tableRef = isSelf and TargetedSpellsSaved.Settings.Self or TargetedSpellsSaved.Settings.Party

		---@param layoutName string
		---@param value number
		local function Set(layoutName, value)
			if tableRef.Direction ~= value then
				tableRef.Direction = value
				Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
			end
		end

		---@type LibEditModeDropdown
		return {
			name = L.Settings.FrameDirectionLabel,
			kind = Enum.EditModeSettingDisplayType.Dropdown,
			default = Private.Settings.GetPartyDefaultSettings().Direction,
			generator = function(owner, rootDescription, data)
				for label, id in pairs(Private.Enum.Direction) do
					local function IsEnabled()
						return tableRef.Direction == id
					end

					local function SetProxy()
						Set(LEM:GetActiveLayoutName(), id)
					end

					local translated = id == Private.Enum.Direction.Horizontal and L.Settings.FrameDirectionHorizontal
						or L.Settings.FrameDirectionVertical

					rootDescription:CreateCheckbox(translated, IsEnabled, SetProxy, {
						value = id,
						multiple = false,
					})
				end
			end,
			set = Set,
		}
	end

	if key == Private.Settings.Keys.Party.OffsetX then
		local sliderSettings = Private.Settings.GetSliderSettingsForOption(key)

		---@type LibEditModeSlider
		return {
			name = L.Settings.FrameOffsetXLabel,
			kind = Enum.EditModeSettingDisplayType.Slider,
			default = Private.Settings.GetPartyDefaultSettings().OffsetX,
			get =
				---@param layoutName string
				function(layoutName)
					return TargetedSpellsSaved.Settings.Party.OffsetX
				end,
			set =
				---@param layoutName string
				---@param value number
				function(layoutName, value)
					if value ~= TargetedSpellsSaved.Settings.Party.OffsetX then
						TargetedSpellsSaved.Settings.Party.OffsetX = value
						Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
					end
				end,
			minValue = sliderSettings.min,
			maxValue = sliderSettings.max,
			valueStep = sliderSettings.step,
		}
	end

	if key == Private.Settings.Keys.Party.OffsetY then
		local sliderSettings = Private.Settings.GetSliderSettingsForOption(key)

		---@type LibEditModeSlider
		return {
			name = L.Settings.FrameOffsetYLabel,
			kind = Enum.EditModeSettingDisplayType.Slider,
			default = Private.Settings.GetPartyDefaultSettings().OffsetY,
			get =
				---@param layoutName string
				function(layoutName)
					return TargetedSpellsSaved.Settings.Party.OffsetY
				end,
			set =
				---@param layoutName string
				---@param value number
				function(layoutName, value)
					if value ~= TargetedSpellsSaved.Settings.Party.OffsetY then
						TargetedSpellsSaved.Settings.Party.OffsetY = value
						Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
					end
				end,
			minValue = sliderSettings.min,
			maxValue = sliderSettings.max,
			valueStep = sliderSettings.step,
		}
	end

	if key == Private.Settings.Keys.Party.SourceAnchor then
		---@param layoutName string
		---@param value string
		local function Set(layoutName, value)
			if TargetedSpellsSaved.Settings.Party.SourceAnchor ~= value then
				TargetedSpellsSaved.Settings.Party.SourceAnchor = value
				Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
			end
		end

		---@type LibEditModeDropdown
		return {
			name = L.Settings.FrameSourceAnchorLabel,
			kind = Enum.EditModeSettingDisplayType.Dropdown,
			default = Private.Settings.GetPartyDefaultSettings().SourceAnchor,
			generator = function(owner, rootDescription, data)
				for label, enumValue in pairs(Private.Enum.Anchor) do
					local function IsEnabled()
						return TargetedSpellsSaved.Settings.Party.SourceAnchor == enumValue
					end

					local function SetProxy()
						Set(LEM:GetActiveLayoutName(), enumValue)
					end

					rootDescription:CreateCheckbox(label, IsEnabled, SetProxy, {
						value = label,
						multiple = false,
					})
				end
			end,
			set = Set,
		}
	end

	if key == Private.Settings.Keys.Party.TargetAnchor then
		---@param layoutName string
		---@param value string
		local function Set(layoutName, value)
			if TargetedSpellsSaved.Settings.Party.TargetAnchor ~= value then
				TargetedSpellsSaved.Settings.Party.TargetAnchor = value
				Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
			end
		end

		---@type LibEditModeDropdown
		return {
			name = L.Settings.FrameTargetAnchorLabel,
			kind = Enum.EditModeSettingDisplayType.Dropdown,
			default = Private.Settings.GetPartyDefaultSettings().TargetAnchor,
			generator = function(owner, rootDescription, data)
				for label, enumValue in pairs(Private.Enum.Anchor) do
					local function IsEnabled()
						return TargetedSpellsSaved.Settings.Party.TargetAnchor == enumValue
					end

					local function SetProxy()
						Set(LEM:GetActiveLayoutName(), enumValue)
					end

					rootDescription:CreateCheckbox(label, IsEnabled, SetProxy, {
						value = label,
						multiple = false,
					})
				end
			end,
			set = Set,
		}
	end

	if key == Private.Settings.Keys.Self.SortOrder or key == Private.Settings.Keys.Party.SortOrder then
		local isSelf = key == Private.Settings.Keys.Self.SortOrder
		local tableRef = isSelf and TargetedSpellsSaved.Settings.Self or TargetedSpellsSaved.Settings.Party

		---@param layoutName string
		---@param value number
		local function Set(layoutName, value)
			if tableRef.SortOrder ~= value then
				tableRef.SortOrder = value
				Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
			end
		end

		---@type LibEditModeDropdown
		return {
			name = L.Settings.FrameSortOrderLabel,
			kind = Enum.EditModeSettingDisplayType.Dropdown,
			default = Private.Settings.GetPartyDefaultSettings().SortOrder,
			generator = function(owner, rootDescription, data)
				for label, id in pairs(Private.Enum.SortOrder) do
					local function IsEnabled()
						return tableRef.SortOrder == id
					end

					local function SetProxy()
						Set(LEM:GetActiveLayoutName(), id)
					end

					local translated = id == Private.Enum.SortOrder.Ascending and L.Settings.FrameSortOrderAscending
						or L.Settings.FrameSortOrderDescending

					rootDescription:CreateCheckbox(translated, IsEnabled, SetProxy, {
						value = id,
						multiple = false,
					})
				end
			end,
			set = Set,
		}
	end

	if key == Private.Settings.Keys.Self.Grow or key == Private.Settings.Keys.Party.Grow then
		local isSelf = key == Private.Settings.Keys.Self.Grow
		local tableRef = isSelf and TargetedSpellsSaved.Settings.Self or TargetedSpellsSaved.Settings.Party

		---@param layoutName string
		---@param value string
		local function Set(layoutName, value)
			if tableRef.Grow ~= value then
				tableRef.Grow = value
				Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
			end
		end

		---@type LibEditModeDropdown
		return {
			name = L.Settings.FrameGrowLabel,
			kind = Enum.EditModeSettingDisplayType.Dropdown,
			default = Private.Settings.GetPartyDefaultSettings().Grow,
			generator = function(owner, rootDescription, data)
				for label, id in pairs(Private.Enum.Grow) do
					local function IsEnabled()
						return tableRef.Grow == id
					end

					local function SetProxy()
						Set(LEM:GetActiveLayoutName(), id)
					end

					local translated = L.Settings.FrameGrowLabels[id]

					rootDescription:CreateCheckbox(translated, IsEnabled, SetProxy, {
						value = id,
						multiple = false,
					})
				end
			end,
			set = Set,
		}
	end

	error(
		string.format(
			"Edit Mode Settings for key '%s' are either not implemented or you're calling this with the wrong key.",
			key or "NO KEY"
		)
	)
end

function TargetedSpellsEditModeMixin:OnLayoutSettingChanged(key, value)
	-- Implement in your derived mixin.
end

function TargetedSpellsEditModeMixin:AppendSettings()
	-- Implement in your derived mixin.
end

function TargetedSpellsEditModeMixin:AcquireFrame()
	local frame = self.framePool:Acquire()

	frame:PostCreate("preview", self.frameKind, nil)

	return frame
end

function TargetedSpellsEditModeMixin:ReleaseFrame(frame)
	frame:Reset()

	self.framePool:Release(frame)
end

function TargetedSpellsEditModeMixin:OnEditModePositionChanged(frame, layoutName, point, x, y)
	-- Implement in your derived mixin.
end

function TargetedSpellsEditModeMixin:RepositionPreviewFrames()
	-- Implement in your derived mixin.
end

function TargetedSpellsEditModeMixin:LoopFrame(frame, index)
	frame:SetSpellId()
	frame:SetStartTime()
	local castTime = 4 + index / 2
	frame:SetCastTime(castTime)
	frame:RefreshSpellCooldownInfo()
	frame:Show()
	self:RepositionPreviewFrames()

	if
		(
			(self.frameKind == Private.Enum.FrameKind.Self and TargetedSpellsSaved.Settings.Self.GlowImportant)
			or (self.frameKind == Private.Enum.FrameKind.Party and TargetedSpellsSaved.Settings.Party.GlowImportant)
		) and Private.Utils.FlipCoin()
	then
		frame:ShowGlow()
	end

	table.insert(
		self.demoTimers.timers,
		C_Timer.NewTimer(castTime, function()
			frame:ClearStartTime()
			frame:Hide()
			self:RepositionPreviewFrames()
		end)
	)
end

function TargetedSpellsEditModeMixin:StartDemo()
	-- Implement in your derived mixin.
end

function TargetedSpellsEditModeMixin:ReleaseAllFrames()
	-- Implement in your derived mixin.
end

function TargetedSpellsEditModeMixin:EndDemo()
	if not self.demoPlaying then
		return
	end

	for _, ticker in pairs(self.demoTimers.tickers) do
		ticker:Cancel()
	end

	for _, timer in pairs(self.demoTimers.timers) do
		timer:Cancel()
	end

	table.wipe(self.demoTimers.tickers)
	table.wipe(self.demoTimers.timers)

	self:ReleaseAllFrames()

	self.demoPlaying = false
end

---@class TargetedSpellsSelfEditMode
local SelfEditModeMixin = CreateFromMixins(TargetedSpellsEditModeMixin)

function SelfEditModeMixin:Init()
	TargetedSpellsEditModeMixin.Init(self, Private.L.EditMode.TargetedSpellsSelfLabel, Private.Enum.FrameKind.Self)

	self.editModeFrame:SetPoint("CENTER", UIParent)
	self:ResizeEditModeFrame()
end

function SelfEditModeMixin:ResizeEditModeFrame()
	local width, gap, height, direction, maxFrames =
		TargetedSpellsSaved.Settings.Self.Width,
		TargetedSpellsSaved.Settings.Self.Gap,
		TargetedSpellsSaved.Settings.Self.Height,
		TargetedSpellsSaved.Settings.Self.Direction,
		TargetedSpellsSaved.Settings.Self.MaxFrames

	if direction == Private.Enum.Direction.Horizontal then
		local totalWidth = (maxFrames * width) + (maxFrames - 1) * gap
		self.editModeFrame:SetSize(totalWidth, height)
	else
		local totalHeight = (maxFrames * height) + (maxFrames - 1) * gap
		self.editModeFrame:SetSize(width, totalHeight)
	end
end

function SelfEditModeMixin:ReleaseAllFrames()
	for index, frame in pairs(self.frames) do
		if frame then
			self:ReleaseFrame(frame)
			self.frames[index] = nil
		end
	end
end

function SelfEditModeMixin:AppendSettings()
	LEM:AddFrame(
		self.editModeFrame,
		GenerateClosure(self.OnEditModePositionChanged, self),
		Private.Settings.GetDefaultEditModeFramePosition(),
		Private.L.EditMode.TargetedSpellsSelfLabel
	)

	LEM:RegisterCallback("layout", GenerateClosure(self.RestoreEditModePosition, self))

	LEM:AddFrameSettings(self.editModeFrame, {
		self:CreateSetting(Private.Settings.Keys.Self.Enabled),
		self:CreateSetting(Private.Settings.Keys.Self.LoadConditionContentType),
		self:CreateSetting(Private.Settings.Keys.Self.LoadConditionRole),
		self:CreateSetting(Private.Settings.Keys.Self.Width),
		self:CreateSetting(Private.Settings.Keys.Self.Height),
		self:CreateSetting(Private.Settings.Keys.Self.Gap),
		self:CreateSetting(Private.Settings.Keys.Self.Direction),
		self:CreateSetting(Private.Settings.Keys.Self.SortOrder),
		self:CreateSetting(Private.Settings.Keys.Self.Grow),
		self:CreateSetting(Private.Settings.Keys.Self.GlowImportant),
		self:CreateSetting(Private.Settings.Keys.Self.PlaySound),
		self:CreateSetting(Private.Settings.Keys.Self.Sound),
		self:CreateSetting(Private.Settings.Keys.Self.SoundChannel),
		self:CreateSetting(Private.Settings.Keys.Self.LoadConditionSoundContentType),
		self:CreateSetting(Private.Settings.Keys.Self.ShowDuration),
		self:CreateSetting(Private.Settings.Keys.Self.FontSize),
		self:CreateSetting(Private.Settings.Keys.Self.ShowBorder),
		self:CreateSetting(Private.Settings.Keys.Self.Opacity),
	})
end

function SelfEditModeMixin:RestoreEditModePosition()
	self.editModeFrame:ClearAllPoints()
	self.editModeFrame:SetPoint(
		TargetedSpellsSaved.Settings.Self.Position.point,
		TargetedSpellsSaved.Settings.Self.Position.x,
		TargetedSpellsSaved.Settings.Self.Position.y
	)
end

---@param frame Frame
function SelfEditModeMixin:OnEditModePositionChanged(frame, layoutName, point, x, y)
	TargetedSpellsSaved.Settings.Self.Position.point = point
	TargetedSpellsSaved.Settings.Self.Position.x = x
	TargetedSpellsSaved.Settings.Self.Position.y = y

	Private.EventRegistry:TriggerEvent(Private.Enum.Events.EDIT_MODE_POSITION_CHANGED, point, x, y)
end

function SelfEditModeMixin:RepositionPreviewFrames()
	if not self.demoPlaying then
		return
	end

	-- await for the setup to be finished
	if self.buildingFrames ~= nil then
		return
	end

	---@type TargetedSpellsMixin[]
	local activeFrames = {}

	for index, frame in pairs(self.frames) do
		if frame and frame:ShouldBeShown() then
			table.insert(activeFrames, frame)
		end
	end

	local activeFrameCount = #activeFrames

	if activeFrameCount == 0 then
		return
	end

	local width, height, gap, direction, sortOrder, grow =
		TargetedSpellsSaved.Settings.Self.Width,
		TargetedSpellsSaved.Settings.Self.Height,
		TargetedSpellsSaved.Settings.Self.Gap,
		TargetedSpellsSaved.Settings.Self.Direction,
		TargetedSpellsSaved.Settings.Self.SortOrder,
		TargetedSpellsSaved.Settings.Self.Grow

	Private.Utils.SortFrames(activeFrames, sortOrder)

	local isHorizontal = direction == Private.Enum.Direction.Horizontal

	local point = isHorizontal and "LEFT" or "BOTTOM"
	local total = (activeFrameCount * (isHorizontal and width or height)) + (activeFrameCount - 1) * gap
	local parentDimension = isHorizontal and self.editModeFrame:GetWidth() or self.editModeFrame:GetHeight()

	for i, frame in ipairs(activeFrames) do
		local x = 0
		local y = 0

		if isHorizontal then
			x = Private.Utils.CalculateCoordinate(i, width, gap, parentDimension, total, 0, grow)
		else
			y = Private.Utils.CalculateCoordinate(i, width, gap, parentDimension, total, 0, grow)
		end

		frame:Reposition(point, self.editModeFrame, "CENTER", x, y)
	end
end

function SelfEditModeMixin:StartDemo()
	if self.demoPlaying or not TargetedSpellsSaved.Settings.Self.Enabled then
		return
	end

	self.demoPlaying = true
	self.buildingFrames = true

	for index = 1, TargetedSpellsSaved.Settings.Self.MaxFrames do
		self.frames[index] = self.frames[index] or self:AcquireFrame()
		local frame = self.frames[index]

		if frame then
			table.insert(
				self.demoTimers.tickers,
				C_Timer.NewTicker(5 + index, GenerateClosure(self.LoopFrame, self, frame, index))
			)

			self:LoopFrame(frame, index)
		end
	end

	self.buildingFrames = nil

	self:RepositionPreviewFrames()
end

function SelfEditModeMixin:OnLayoutSettingChanged(key, value)
	if
		key == Private.Settings.Keys.Self.Gap
		or key == Private.Settings.Keys.Self.Direction
		or key == Private.Settings.Keys.Self.Width
		or key == Private.Settings.Keys.Self.Height
		or key == Private.Settings.Keys.Self.SortOrder
		or key == Private.Settings.Keys.Self.Grow
		or key == Private.Settings.Keys.Self.MaxFrames
	then
		if
			key == Private.Settings.Keys.Self.Width
			or key == Private.Settings.Keys.Self.Height
			or key == Private.Settings.Keys.Self.Gap
			or key == Private.Settings.Keys.Self.Direction
			or key == Private.Settings.Keys.Self.MaxFrames
		then
			self:ResizeEditModeFrame()
		end

		self:RepositionPreviewFrames()
	elseif key == Private.Settings.Keys.Self.GlowImportant then
		local glowEnabled = value

		for _, frame in pairs(self.frames) do
			if frame then
				if glowEnabled then
					if Private.Utils.FlipCoin() then
						frame:ShowGlow()
					end
				else
					frame:HideGlow()
				end
			end
		end
	end
end

table.insert(Private.LoginFnQueue, GenerateClosure(SelfEditModeMixin.Init, SelfEditModeMixin))

---@class TargetedSpellsPartyEditMode
local PartyEditModeMixin = CreateFromMixins(TargetedSpellsEditModeMixin)

function PartyEditModeMixin:Init()
	TargetedSpellsEditModeMixin.Init(self, Private.L.EditMode.TargetedSpellsPartyLabel, Private.Enum.FrameKind.Party)
	self.maxUnitCount = 5
	self.amountOfPreviewFramesPerUnit = 3
	self.useRaidStylePartyFrames = self.useRaidStylePartyFrames or EditModeManagerFrame:UseRaidStylePartyFrames()
	self:RepositionEditModeFrame()

	-- when this executes, layouts aren't loaded yet
	hooksecurefunc(EditModeManagerFrame, "UpdateLayoutInfo", function(editModeManagerSelf)
		local useRaidStylePartyFrames = EditModeManagerFrame:UseRaidStylePartyFrames()

		if useRaidStylePartyFrames == self.useRaidStylePartyFrames then
			return
		end

		self.useRaidStylePartyFrames = useRaidStylePartyFrames
		self:RepositionEditModeFrame()
	end)

	-- dirtying settings while edit mode is opened doesn't fire any events
	hooksecurefunc(EditModeSystemSettingsDialog, "OnSettingValueChanged", function(settingsSelf, setting, checked)
		if setting ~= Enum.EditModeUnitFrameSetting.UseRaidStylePartyFrames then
			return
		end

		local useRaidStylePartyFrames = checked == 1

		if useRaidStylePartyFrames == self.useRaidStylePartyFrames then
			return
		end

		self.useRaidStylePartyFrames = useRaidStylePartyFrames
		self:RepositionEditModeFrame()

		if TargetedSpellsSaved.Settings.Party.Enabled then
			self:EndDemo()
			self:StartDemo()
		end
	end)
end

function PartyEditModeMixin:AppendSettings()
	LEM:AddFrame(
		self.editModeFrame,
		GenerateClosure(self.OnEditModePositionChanged, self),
		Private.Settings.GetDefaultEditModeFramePosition(),
		"Targeted Spells - Party"
	)

	self.editModeFrame:SetScript("OnDragStart", nil)
	self.editModeFrame:SetScript("OnDragStop", nil)

	LEM:AddFrameSettings(self.editModeFrame, {
		self:CreateSetting(Private.Settings.Keys.Party.Enabled),
		self:CreateSetting(Private.Settings.Keys.Party.LoadConditionContentType),
		self:CreateSetting(Private.Settings.Keys.Party.LoadConditionRole),
		self:CreateSetting(Private.Settings.Keys.Party.Width),
		self:CreateSetting(Private.Settings.Keys.Party.Height),
		self:CreateSetting(Private.Settings.Keys.Party.Gap),
		self:CreateSetting(Private.Settings.Keys.Party.Direction),
		self:CreateSetting(Private.Settings.Keys.Party.OffsetX),
		self:CreateSetting(Private.Settings.Keys.Party.OffsetY),
		self:CreateSetting(Private.Settings.Keys.Party.SourceAnchor),
		self:CreateSetting(Private.Settings.Keys.Party.TargetAnchor),
		self:CreateSetting(Private.Settings.Keys.Party.Grow),
		self:CreateSetting(Private.Settings.Keys.Party.SortOrder),
		self:CreateSetting(Private.Settings.Keys.Party.GlowImportant),
		self:CreateSetting(Private.Settings.Keys.Party.IncludeSelfInParty),
		self:CreateSetting(Private.Settings.Keys.Party.ShowDuration),
		self:CreateSetting(Private.Settings.Keys.Party.FontSize),
		self:CreateSetting(Private.Settings.Keys.Party.ShowBorder),
		self:CreateSetting(Private.Settings.Keys.Party.Opacity),
	})
end

function PartyEditModeMixin:RepositionEditModeFrame()
	local parent = PartyFrame
	local width = 125
	local height = 16

	if self.useRaidStylePartyFrames then
		parent = CompactPartyFrame
		width = CompactPartyFrame.memberUnitFrames[1]:GetWidth()
	end

	self.editModeFrame:SetSize(width, height)
	self.editModeFrame:ClearAllPoints()
	self.editModeFrame:SetPoint("CENTER", parent, "TOP", 0, 16)
end

function PartyEditModeMixin:OnEditModePositionChanged()
	self:RepositionEditModeFrame()
end

function PartyEditModeMixin:OnLayoutSettingChanged(key, value)
	if
		key == Private.Settings.Keys.Party.Gap
		or key == Private.Settings.Keys.Party.Direction
		or key == Private.Settings.Keys.Party.Width
		or key == Private.Settings.Keys.Party.Height
		or key == Private.Settings.Keys.Party.OffsetX
		or key == Private.Settings.Keys.Party.OffsetY
		or key == Private.Settings.Keys.Party.SourceAnchor
		or key == Private.Settings.Keys.Party.TargetAnchor
		or key == Private.Settings.Keys.Party.SortOrder
		or key == Private.Settings.Keys.Party.Grow
	then
		self:RepositionPreviewFrames()
	elseif key == Private.Settings.Keys.Party.GlowImportant then
		local glowEnabled = value

		for _, frames in pairs(self.frames) do
			for _, frame in pairs(frames) do
				if frame then
					if glowEnabled then
						if Private.Utils.FlipCoin() then
							frame:ShowGlow()
						end
					else
						frame:HideGlow()
					end
				end
			end
		end
	end
end

function PartyEditModeMixin:RepositionPreviewFrames()
	if not self.demoPlaying then
		return
	end

	-- await for the setup to be finished
	if self.buildingFrames ~= nil then
		return
	end

	local width, height, gap, direction, offsetX, offsetY, sortOrder, sourceAnchor, targetAnchor, grow =
		TargetedSpellsSaved.Settings.Party.Width,
		TargetedSpellsSaved.Settings.Party.Height,
		TargetedSpellsSaved.Settings.Party.Gap,
		TargetedSpellsSaved.Settings.Party.Direction,
		TargetedSpellsSaved.Settings.Party.OffsetX,
		TargetedSpellsSaved.Settings.Party.OffsetY,
		TargetedSpellsSaved.Settings.Party.SortOrder,
		TargetedSpellsSaved.Settings.Party.SourceAnchor,
		TargetedSpellsSaved.Settings.Party.TargetAnchor,
		TargetedSpellsSaved.Settings.Party.Grow

	local isHorizontal = direction == Private.Enum.Direction.Horizontal

	for i = 1, self.maxUnitCount do
		if i == self.maxUnitCount and not self.useRaidStylePartyFrames then
			break
		end

		---@type TargetedSpellsMixin[]
		local activeFrames = {}

		for j = 1, self.amountOfPreviewFramesPerUnit do
			local frame = self.frames[i][j]

			if frame and frame:ShouldBeShown() then
				table.insert(activeFrames, frame)
			end
		end

		local activeFrameCount = #activeFrames

		if activeFrameCount > 0 then
			Private.Utils.SortFrames(activeFrames, sortOrder)

			local parentFrame = nil

			if self.useRaidStylePartyFrames then
				parentFrame = CompactPartyFrame.memberUnitFrames[i]
			else
				for memberFrame in PartyFrame.PartyMemberFramePool:EnumerateActive() do
					if memberFrame.layoutIndex == i then
						parentFrame = memberFrame
						break
					end
				end
			end

			-- cannot happen
			if parentFrame == nil then
				error("couldn't establish a parent frame")
			end

			local total = (activeFrameCount * (isHorizontal and width or height)) + (activeFrameCount - 1) * gap
			local parentDimension = isHorizontal and parentFrame:GetWidth() or parentFrame:GetHeight()

			for j, frame in ipairs(activeFrames) do
				local x = offsetX
				local y = offsetY

				if isHorizontal then
					x = Private.Utils.CalculateCoordinate(j, width, gap, parentDimension, total, offsetX, grow)
				else
					y = Private.Utils.CalculateCoordinate(j, width, gap, parentDimension, total, offsetY, grow)
				end

				frame:Reposition(sourceAnchor, parentFrame, targetAnchor, x, y)
			end
		end
	end
end

function PartyEditModeMixin:StartDemo()
	if self.demoPlaying or not TargetedSpellsSaved.Settings.Party.Enabled then
		return
	end

	self.demoPlaying = true
	self.buildingFrames = true

	for unit = 1, self.maxUnitCount do
		if unit > 1 or TargetedSpellsSaved.Settings.Party.IncludeSelfInParty then
			self.frames[unit] = self.frames[unit] or {}

			if unit == self.maxUnitCount and not self.useRaidStylePartyFrames then
				break
			end

			for index = 1, self.amountOfPreviewFramesPerUnit do
				self.frames[unit][index] = self.frames[unit][index] or self:AcquireFrame()
				local frame = self.frames[unit][index]

				if frame then
					table.insert(
						self.demoTimers.tickers,
						C_Timer.NewTicker(5 + index + unit, GenerateClosure(self.LoopFrame, self, frame, index + unit))
					)

					self:LoopFrame(frame, index + unit)
				end
			end
		end
	end

	self.buildingFrames = nil

	self:RepositionPreviewFrames()
end

function PartyEditModeMixin:ReleaseAllFrames()
	for unit = 1, self.maxUnitCount do
		for index = 1, self.amountOfPreviewFramesPerUnit do
			local frame = self.frames[unit][index]

			if frame then
				self:ReleaseFrame(frame)
				self.frames[unit][index] = nil
			end
		end
	end
end

table.insert(Private.LoginFnQueue, GenerateClosure(PartyEditModeMixin.Init, PartyEditModeMixin))
