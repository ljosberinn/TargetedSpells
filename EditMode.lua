---@type string, TargetedSpells
local addonName, Private = ...
local LibEditMode = LibStub("LibEditMode")

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

	LibEditMode:RegisterCallback("enter", GenerateClosure(self.StartDemo, self))
	LibEditMode:RegisterCallback("exit", GenerateClosure(self.EndDemo, self))

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
		or key == Private.Settings.Keys.Self.GlowImportant
		or key == Private.Settings.Keys.Self.GlowType
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
		or key == Private.Settings.Keys.Party.GlowType
	then
		self:OnLayoutSettingChanged(key, value)
	elseif key == Private.Settings.Keys.Self.Enabled or key == Private.Settings.Keys.Party.Enabled then
		if not LibEditMode:IsInEditMode() then
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
		if not LibEditMode:IsInEditMode() then
			return
		end

		self:EndDemo()
		self:StartDemo()
	end
end

function TargetedSpellsEditModeMixin:CreateSetting(key, defaults)
	local L = Private.L

	if key == Private.Settings.Keys.Self.Opacity or key == Private.Settings.Keys.Party.Opacity then
		local tableRef = key == Private.Settings.Keys.Self.Opacity and TargetedSpellsSaved.Settings.Self
			or TargetedSpellsSaved.Settings.Party
		local sliderSettings = Private.Settings.GetSliderSettingsForOption(key)

		---@param layoutName string
		local function Get(layoutName)
			return tableRef.Opacity
		end

		---@param layoutName string
		---@param value number
		local function Set(layoutName, value)
			if value ~= tableRef.Opacity then
				tableRef.Opacity = value
				Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
			end
		end

		---@type LibEditModeSlider
		return {
			name = L.Settings.OpacityLabel,
			kind = Enum.EditModeSettingDisplayType.Slider,
			default = defaults.Opacity,
			desc = L.Settings.OpacityTooltip,
			get = Get,
			set = Set,
			minValue = sliderSettings.min,
			maxValue = sliderSettings.max,
			valueStep = sliderSettings.step,
			formatter = FormatPercentage,
		}
	end

	if key == Private.Settings.Keys.Self.GlowImportant or key == Private.Settings.Keys.Party.GlowImportant then
		local tableRef = key == Private.Settings.Keys.Self.GlowImportant and TargetedSpellsSaved.Settings.Self
			or TargetedSpellsSaved.Settings.Party

		---@param layoutName string
		local function Get(layoutName)
			return tableRef.GlowImportant
		end

		---@param layoutName string
		---@param value boolean
		local function Set(layoutName, value)
			if value ~= tableRef.GlowImportant then
				tableRef.GlowImportant = value
				Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
			end

			if value then
				LibEditMode:EnableFrameSetting(self.editModeFrame, L.Settings.GlowTypeLabel)
			else
				LibEditMode:DisableFrameSetting(self.editModeFrame, L.Settings.GlowTypeLabel)
			end
		end

		---@type LibEditModeCheckbox
		return {
			name = L.Settings.GlowImportantLabel,
			kind = Enum.EditModeSettingDisplayType.Checkbox,
			desc = L.Settings.GlowImportantTooltip,
			default = defaults.GlowImportant,
			get = Get,
			set = Set,
		}
	end

	if key == Private.Settings.Keys.Self.GlowType or key == Private.Settings.Keys.Party.GlowType then
		local tableRef = key == Private.Settings.Keys.Self.GlowType and TargetedSpellsSaved.Settings.Self
			or TargetedSpellsSaved.Settings.Party

		---@param layoutName string
		---@param value number
		local function Set(layoutName, value)
			if tableRef.GlowType ~= value then
				tableRef.GlowType = value
				Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
			end
		end

		local function Generator(owner, rootDescription, data)
			for label, id in pairs(Private.Enum.GlowType) do
				local function IsEnabled()
					return tableRef.GlowType == id
				end

				local function SetProxy()
					Set(LibEditMode:GetActiveLayoutName(), id)
				end

				local translated = L.Settings.GlowTypeLabels[id]

				rootDescription:CreateCheckbox(translated, IsEnabled, SetProxy, {
					value = label,
					multiple = false,
				})
			end
		end

		---@type LibEditModeDropdown
		return {
			name = L.Settings.GlowTypeLabel,
			kind = Enum.EditModeSettingDisplayType.Dropdown,
			desc = L.Settings.GlowTypeTooltip,
			default = defaults.GlowType,
			multiple = false,
			generator = Generator,
			set = Set,
			disabled = not tableRef.GlowImportant,
		}
	end

	if key == Private.Settings.Keys.Self.ShowBorder or key == Private.Settings.Keys.Party.ShowBorder then
		local tableRef = key == Private.Settings.Keys.Self.ShowBorder and TargetedSpellsSaved.Settings.Self
			or TargetedSpellsSaved.Settings.Party

		---@param layoutName string
		local function Get(layoutName)
			return tableRef.ShowBorder
		end

		---@param layoutName string
		---@param value boolean
		local function Set(layoutName, value)
			if value ~= tableRef.ShowBorder then
				tableRef.ShowBorder = value
				Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
			end
		end

		---@type LibEditModeCheckbox
		return {
			name = L.Settings.ShowBorderLabel,
			kind = Enum.EditModeSettingDisplayType.Checkbox,
			desc = L.Settings.ShowBorderTooltip,
			default = defaults.ShowBorder,
			get = Get,
			set = Set,
		}
	end

	if key == Private.Settings.Keys.Self.ShowDuration or key == Private.Settings.Keys.Party.ShowDuration then
		local tableRef = key == Private.Settings.Keys.Self.ShowDuration and TargetedSpellsSaved.Settings.Self
			or TargetedSpellsSaved.Settings.Party

		---@param layoutName string
		local function Get(layoutName)
			return tableRef.ShowDuration
		end

		---@param layoutName string
		---@param value boolean
		local function Set(layoutName, value)
			if value ~= tableRef.ShowDuration then
				tableRef.ShowDuration = value
				Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
			end

			if value then
				LibEditMode:EnableFrameSetting(self.editModeFrame, L.Settings.FontSizeLabel)
			else
				LibEditMode:DisableFrameSetting(self.editModeFrame, L.Settings.FontSizeLabel)
			end
		end

		---@type LibEditModeCheckbox
		return {
			name = L.Settings.ShowDurationLabel,
			kind = Enum.EditModeSettingDisplayType.Checkbox,
			desc = L.Settings.ShowDurationTooltip,
			default = defaults.ShowDuration,
			get = Get,
			set = Set,
		}
	end

	if key == Private.Settings.Keys.Self.PlayTTS then
		---@param layoutName string
		local function Get(layoutName)
			return TargetedSpellsSaved.Settings.Self.PlayTTS
		end

		---@param layoutName string
		---@param value boolean
		local function Set(layoutName, value)
			if value ~= TargetedSpellsSaved.Settings.Self.PlayTTS then
				TargetedSpellsSaved.Settings.Self.PlayTTS = value
				Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
			end

			if value then
				if TargetedSpellsSaved.Settings.Self.PlaySound then
					TargetedSpellsSaved.Settings.Self.PlaySound = false
					Private.EventRegistry:TriggerEvent(
						Private.Enum.Events.SETTING_CHANGED,
						Private.Settings.Keys.Self.PlaySound,
						false
					)
				end

				LibEditMode:EnableFrameSetting(self.editModeFrame, L.Settings.TTSVoiceLabel)
				LibEditMode:DisableFrameSetting(self.editModeFrame, L.Settings.SoundLabel)
				LibEditMode:DisableFrameSetting(self.editModeFrame, L.Settings.SoundChannelLabel)
			else
				if TargetedSpellsSaved.Settings.Self.PlaySound then
					LibEditMode:EnableFrameSetting(self.editModeFrame, L.Settings.SoundLabel)
					LibEditMode:EnableFrameSetting(self.editModeFrame, L.Settings.SoundChannelLabel)
				end

				LibEditMode:DisableFrameSetting(self.editModeFrame, L.Settings.TTSVoiceLabel)
			end
		end

		---@type LibEditModeCheckbox
		return {
			name = L.Settings.PlayTTSLabel,
			kind = Enum.EditModeSettingDisplayType.Checkbox,
			desc = L.Settings.PlayTTSTooltip,
			default = defaults.PlayTTS,
			get = Get,
			set = Set,
		}
	end

	if key == Private.Settings.Keys.Self.TTSVoice then
		---@param layoutName string
		---@param value number
		local function Set(layoutName, value)
			if TargetedSpellsSaved.Settings.Self.TTSVoice ~= value then
				TargetedSpellsSaved.Settings.Self.TTSVoice = value
				Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)

				Private.Settings.SampleTTSVoice(value)
			end
		end

		local function Generator(owner, rootDescription, data)
			for _, voice in pairs(C_VoiceChat.GetTtsVoices()) do
				local function IsEnabled()
					return TargetedSpellsSaved.Settings.Self.TTSVoice == voice.voiceID
				end

				local function SetProxy()
					Set(LibEditMode:GetActiveLayoutName(), voice.voiceID)
				end

				rootDescription:CreateCheckbox(voice.name, IsEnabled, SetProxy, {
					value = voice.voiceID,
					multiple = false,
				})
			end
		end

		---@type LibEditModeDropdown
		return {
			name = L.Settings.TTSVoiceLabel,
			kind = Enum.EditModeSettingDisplayType.Dropdown,
			default = defaults.TTSVoice,
			desc = L.Settings.TTSVoiceTooltip,
			generator = Generator,
			set = Set,
			disabled = TargetedSpellsSaved.Settings.Self.PlaySound or not TargetedSpellsSaved.Settings.Self.PlayTTS,
		}
	end

	if key == Private.Settings.Keys.Self.PlaySound then
		---@param layoutName string
		local function Get(layoutName)
			return TargetedSpellsSaved.Settings.Self.PlaySound
		end

		---@param layoutName string
		---@param value boolean
		local function Set(layoutName, value)
			if value ~= TargetedSpellsSaved.Settings.Self.PlaySound then
				TargetedSpellsSaved.Settings.Self.PlaySound = value
				Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
			end

			if value then
				if TargetedSpellsSaved.Settings.Self.PlayTTS then
					TargetedSpellsSaved.Settings.Self.PlayTTS = false
					Private.EventRegistry:TriggerEvent(
						Private.Enum.Events.SETTING_CHANGED,
						Private.Settings.Keys.Self.PlayTTS,
						false
					)
				end

				LibEditMode:DisableFrameSetting(self.editModeFrame, L.Settings.TTSVoiceLabel)
				LibEditMode:EnableFrameSetting(self.editModeFrame, L.Settings.SoundLabel)
				LibEditMode:EnableFrameSetting(self.editModeFrame, L.Settings.SoundChannelLabel)
			else
				if TargetedSpellsSaved.Settings.Self.PlayTTS then
					LibEditMode:EnableFrameSetting(self.editModeFrame, L.Settings.TTSVoiceLabel)
				end

				LibEditMode:DisableFrameSetting(self.editModeFrame, L.Settings.SoundLabel)
				LibEditMode:DisableFrameSetting(self.editModeFrame, L.Settings.SoundChannelLabel)
			end
		end

		---@type LibEditModeCheckbox
		return {
			name = L.Settings.PlaySoundLabel,
			kind = Enum.EditModeSettingDisplayType.Checkbox,
			desc = L.Settings.PlaySoundTooltip,
			default = defaults.PlaySound,
			get = Get,
			set = Set,
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

		local function Generator(owner, rootDescription, data)
			for label, enumValue in pairs(Private.Enum.SoundChannel) do
				local function IsEnabled()
					return TargetedSpellsSaved.Settings.Self.SoundChannel == enumValue
				end

				local function SetProxy()
					Set(LibEditMode:GetActiveLayoutName(), enumValue)
				end

				local translated = L.Settings.SoundChannelLabels[enumValue]

				rootDescription:CreateCheckbox(translated, IsEnabled, SetProxy, {
					value = label,
					multiple = false,
				})
			end
		end

		---@type LibEditModeDropdown
		return {
			name = L.Settings.SoundChannelLabel,
			kind = Enum.EditModeSettingDisplayType.Dropdown,
			default = defaults.SoundChannel,
			desc = L.Settings.SoundChannelTooltip,
			generator = Generator,
			set = Set,
			disabled = TargetedSpellsSaved.Settings.Self.PlayTTS or not TargetedSpellsSaved.Settings.Self.PlaySound,
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
								value.soundKitID
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

		local function Generator(owner, rootDescription, data)
			-- pcall this to guard against internal changes on the cd viewer side
			pcall(AddCooldownViewerSounds, rootDescription)
			-- intentionally separated so if the above fails, we can always at least show Custom sounds
			AddCustomSounds(rootDescription)
		end

		---@param layoutName string
		---@param values table<string, boolean>
		local function Set(layoutName, values)
			if defaults.Sound ~= TargetedSpellsSaved.Settings.Self.Sound then
				TargetedSpellsSaved.Settings.Self.Sound = defaults.Sound
				Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, defaults.Sound)
			end
		end

		---@type LibEditModeDropdown
		return {
			name = L.Settings.SoundLabel,
			kind = Enum.EditModeSettingDisplayType.Dropdown,
			desc = L.Settings.SoundTooltip,
			default = defaults.Sound,
			generator = Generator,
			-- technically is a reset only
			set = Set,
			disabled = TargetedSpellsSaved.Settings.Self.PlayTTS or not TargetedSpellsSaved.Settings.Self.PlaySound,
		}
	end

	if key == Private.Settings.Keys.Party.IncludeSelfInParty then
		---@param layoutName string
		local function Get(layoutName)
			return TargetedSpellsSaved.Settings.Party.IncludeSelfInParty
		end

		---@param layoutName string
		---@param value boolean
		local function Set(layoutName, value)
			if value ~= TargetedSpellsSaved.Settings.Party.IncludeSelfInParty then
				TargetedSpellsSaved.Settings.Party.IncludeSelfInParty = value
				Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
			end
		end

		---@type LibEditModeCheckbox
		return {
			name = L.Settings.IncludeSelfInPartyLabel,
			kind = Enum.EditModeSettingDisplayType.Checkbox,
			desc = L.Settings.IncludeSelfInPartyTooltip,
			default = defaults.IncludeSelfInParty,
			get = Get,
			set = Set,
		}
	end

	if key == Private.Settings.Keys.Self.Enabled or key == Private.Settings.Keys.Party.Enabled then
		local tableRef = key == Private.Settings.Keys.Self.Enabled and TargetedSpellsSaved.Settings.Self
			or TargetedSpellsSaved.Settings.Party

		---@param layoutName string
		local function Get(layoutName)
			return tableRef.Enabled
		end

		---@param layoutName string
		---@param value boolean
		local function Set(layoutName, value)
			if value ~= tableRef.Enabled then
				tableRef.Enabled = value
				Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
			end
		end

		---@type LibEditModeCheckbox
		return {
			name = L.Settings.EnabledLabel,
			kind = Enum.EditModeSettingDisplayType.Checkbox,
			default = defaults.Enabled,
			desc = L.Settings.EnabledTooltip,
			get = Get,
			set = Set,
		}
	end

	if
		key == Private.Settings.Keys.Self.LoadConditionContentType
		or key == Private.Settings.Keys.Party.LoadConditionContentType
	then
		local isSelf = key == Private.Settings.Keys.Self.LoadConditionContentType
		local tableRef = isSelf and TargetedSpellsSaved.Settings.Self.LoadConditionContentType
			or TargetedSpellsSaved.Settings.Party.LoadConditionContentType

		local function Generator(owner, rootDescription, data)
			for label, id in pairs(Private.Enum.ContentType) do
				if id ~= Private.Enum.ContentType.Raid then
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

						local kindTableRef = isSelf and TargetedSpellsSaved.Settings.Self
							or TargetedSpellsSaved.Settings.Party

						if anyEnabled ~= kindTableRef.Enabled then
							kindTableRef.Enabled = anyEnabled
							local enabledKey = isSelf and Private.Settings.Keys.Self.Enabled
								or Private.Settings.Keys.Party.Enabled
							Private.EventRegistry:TriggerEvent(
								Private.Enum.Events.SETTING_CHANGED,
								enabledKey,
								anyEnabled
							)

							LibEditMode:RefreshFrameSettings(self.editModeFrame)
						end
					end

					local translated = L.Settings.LoadConditionContentTypeLabels[id]
					rootDescription:CreateCheckbox(translated, IsEnabled, Toggle, {
						value = label,
						multiple = true,
					})
				end
			end
		end

		---@param layoutName string
		---@param values table<string, boolean>
		local function Set(layoutName, values)
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
		end

		---@type LibEditModeDropdown
		return {
			name = L.Settings.LoadConditionContentTypeLabelAbbreviated,
			kind = Enum.EditModeSettingDisplayType.Dropdown,
			default = defaults.LoadConditionContentType,
			desc = L.Settings.LoadConditionContentTypeTooltip,
			generator = Generator,
			-- technically is a reset only
			set = Set,
		}
	end

	if key == Private.Settings.Keys.Self.LoadConditionSoundContentType then
		local function Generator(owner, rootDescription, data)
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
				end

				local translated = L.Settings.LoadConditionSoundContentTypeLabels[id]
				rootDescription:CreateCheckbox(translated, IsEnabled, Toggle, {
					value = label,
					multiple = true,
				})
			end
		end

		---@param layoutName string
		---@param values table<string, boolean>
		local function Set(layoutName, values)
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
		end

		---@type LibEditModeDropdown
		return {
			name = L.Settings.LoadConditionSoundContentTypeLabelAbbreviated,
			kind = Enum.EditModeSettingDisplayType.Dropdown,
			default = defaults.LoadConditionSoundContentType,
			desc = L.Settings.LoadConditionSoundContentTypeTooltip,
			generator = Generator,
			-- technically is a reset only
			set = Set,
		}
	end

	if key == Private.Settings.Keys.Self.LoadConditionRole or key == Private.Settings.Keys.Party.LoadConditionRole then
		local isSelf = key == Private.Settings.Keys.Self.LoadConditionRole
		local tableRef = isSelf and TargetedSpellsSaved.Settings.Self.LoadConditionRole
			or TargetedSpellsSaved.Settings.Party.LoadConditionRole

		local function Generator(owner, rootDescription, data)
			for label, id in pairs(Private.Enum.Role) do
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

					local kindTableRef = isSelf and TargetedSpellsSaved.Settings.Self
						or TargetedSpellsSaved.Settings.Party

					if anyEnabled ~= kindTableRef.Enabled then
						kindTableRef.Enabled = anyEnabled
						local enabledKey = isSelf and Private.Settings.Keys.Self.Enabled
							or Private.Settings.Keys.Party.Enabled
						Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, enabledKey, anyEnabled)

						LibEditMode:RefreshFrameSettings(self.editModeFrame)
					end
				end

				local translated = L.Settings.LoadConditionRoleLabels[id]

				rootDescription:CreateCheckbox(translated, IsEnabled, Toggle, {
					value = label,
					multiple = true,
				})
			end
		end

		---@param layoutName string
		---@param values table<string, boolean>
		local function Set(layoutName, values)
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
		end

		---@type LibEditModeDropdown
		return {
			name = L.Settings.LoadConditionRoleLabelAbbreviated,
			kind = Enum.EditModeSettingDisplayType.Dropdown,
			default = defaults.LoadConditionRole,
			desc = L.Settings.LoadConditionRoleTooltip,
			generator = Generator,
			-- technically is a reset only
			set = Set,
		}
	end

	if key == Private.Settings.Keys.Self.FontSize or key == Private.Settings.Keys.Party.FontSize then
		local tableRef = key == Private.Settings.Keys.Self.FontSize and TargetedSpellsSaved.Settings.Self
			or TargetedSpellsSaved.Settings.Party
		local sliderSettings = Private.Settings.GetSliderSettingsForOption(key)

		---@param layoutName string
		local function Get(layoutName)
			return tableRef.FontSize
		end

		---@param layoutName string
		---@param value number
		local function Set(layoutName, value)
			if value ~= tableRef.FontSize then
				tableRef.FontSize = value
				Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
			end
		end

		---@type LibEditModeSlider
		return {
			name = L.Settings.FontSizeLabel,
			kind = Enum.EditModeSettingDisplayType.Slider,
			default = defaults.FontSize,
			desc = L.Settings.FontSizeTooltip,
			get = Get,
			set = Set,
			minValue = sliderSettings.min,
			maxValue = sliderSettings.max,
			valueStep = sliderSettings.step,
			disabled = not tableRef.ShowDuration,
		}
	end

	if key == Private.Settings.Keys.Self.Width or key == Private.Settings.Keys.Party.Width then
		local tableRef = key == Private.Settings.Keys.Self.Width and TargetedSpellsSaved.Settings.Self
			or TargetedSpellsSaved.Settings.Party
		local sliderSettings = Private.Settings.GetSliderSettingsForOption(key)

		---@param layoutName string
		local function Get(layoutName)
			return tableRef.Width
		end

		---@param layoutName string
		---@param value number
		local function Set(layoutName, value)
			if value ~= tableRef.Width then
				tableRef.Width = value
				Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
			end
		end

		---@type LibEditModeSlider
		return {
			name = L.Settings.FrameWidthLabel,
			kind = Enum.EditModeSettingDisplayType.Slider,
			default = defaults.Width,
			desc = L.Settings.FrameWidthTooltip,
			get = Get,
			set = Set,
			minValue = sliderSettings.min,
			maxValue = sliderSettings.max,
			valueStep = sliderSettings.step,
		}
	end

	if key == Private.Settings.Keys.Self.Height or key == Private.Settings.Keys.Party.Height then
		local tableRef = key == Private.Settings.Keys.Self.Height and TargetedSpellsSaved.Settings.Self
			or TargetedSpellsSaved.Settings.Party
		local sliderSettings = Private.Settings.GetSliderSettingsForOption(key)

		---@param layoutName string
		local function Get(layoutName)
			return tableRef.Height
		end

		---@param layoutName string
		---@param value number
		local function Set(layoutName, value)
			if value ~= tableRef.Height then
				tableRef.Height = value
				Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
			end
		end

		---@type LibEditModeSlider
		return {
			name = L.Settings.FrameHeightLabel,
			kind = Enum.EditModeSettingDisplayType.Slider,
			default = defaults.Height,
			desc = L.Settings.FrameHeightTooltip,
			get = Get,
			set = Set,
			minValue = sliderSettings.min,
			maxValue = sliderSettings.max,
			valueStep = sliderSettings.step,
		}
	end

	if key == Private.Settings.Keys.Self.Gap or key == Private.Settings.Keys.Party.Gap then
		local tableRef = key == Private.Settings.Keys.Self.Gap and TargetedSpellsSaved.Settings.Self
			or TargetedSpellsSaved.Settings.Party
		local sliderSettings = Private.Settings.GetSliderSettingsForOption(key)

		---@param layoutName string
		local function Get(layoutName)
			return tableRef.Gap
		end

		---@param layoutName string
		---@param value number
		local function Set(layoutName, value)
			if value ~= tableRef.Gap then
				tableRef.Gap = value
				Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
			end
		end

		---@type LibEditModeSlider
		return {
			name = L.Settings.FrameGapLabel,
			kind = Enum.EditModeSettingDisplayType.Slider,
			default = defaults.Gap,
			desc = L.Settings.FrameGapTooltip,
			get = Get,
			set = Set,
			minValue = sliderSettings.min,
			maxValue = sliderSettings.max,
			valueStep = sliderSettings.step,
		}
	end

	if key == Private.Settings.Keys.Self.Direction or key == Private.Settings.Keys.Party.Direction then
		local tableRef = key == Private.Settings.Keys.Self.Direction and TargetedSpellsSaved.Settings.Self
			or TargetedSpellsSaved.Settings.Party

		---@param layoutName string
		---@param value number
		local function Set(layoutName, value)
			if tableRef.Direction ~= value then
				tableRef.Direction = value
				Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
			end
		end

		local function Generator(owner, rootDescription, data)
			for label, id in pairs(Private.Enum.Direction) do
				local function IsEnabled()
					return tableRef.Direction == id
				end

				local function SetProxy()
					Set(LibEditMode:GetActiveLayoutName(), id)
				end

				local translated = id == Private.Enum.Direction.Horizontal and L.Settings.FrameDirectionHorizontal
					or L.Settings.FrameDirectionVertical

				rootDescription:CreateCheckbox(translated, IsEnabled, SetProxy, {
					value = id,
					multiple = false,
				})
			end
		end

		---@type LibEditModeDropdown
		return {
			name = L.Settings.FrameDirectionLabel,
			kind = Enum.EditModeSettingDisplayType.Dropdown,
			default = defaults.Direction,
			desc = L.Settings.FrameDirectionTooltip,
			generator = Generator,
			set = Set,
		}
	end

	if key == Private.Settings.Keys.Party.OffsetX then
		local sliderSettings = Private.Settings.GetSliderSettingsForOption(key)

		---@param layoutName string
		local function Get(layoutName)
			return TargetedSpellsSaved.Settings.Party.OffsetX
		end

		---@param layoutName string
		---@param value number
		local function Set(layoutName, value)
			if value ~= TargetedSpellsSaved.Settings.Party.OffsetX then
				TargetedSpellsSaved.Settings.Party.OffsetX = value
				Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
			end
		end

		---@type LibEditModeSlider
		return {
			name = L.Settings.FrameOffsetXLabel,
			kind = Enum.EditModeSettingDisplayType.Slider,
			default = defaults.OffsetX,
			desc = L.Settings.FrameOffsetXTooltip,
			get = Get,
			set = Set,
			minValue = sliderSettings.min,
			maxValue = sliderSettings.max,
			valueStep = sliderSettings.step,
		}
	end

	if key == Private.Settings.Keys.Party.OffsetY then
		local sliderSettings = Private.Settings.GetSliderSettingsForOption(key)

		---@param layoutName string
		local function Get(layoutName)
			return TargetedSpellsSaved.Settings.Party.OffsetY
		end

		---@param layoutName string
		---@param value number
		local function Set(layoutName, value)
			if value ~= TargetedSpellsSaved.Settings.Party.OffsetY then
				TargetedSpellsSaved.Settings.Party.OffsetY = value
				Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
			end
		end

		---@type LibEditModeSlider
		return {
			name = L.Settings.FrameOffsetYLabel,
			kind = Enum.EditModeSettingDisplayType.Slider,
			default = defaults.OffsetY,
			desc = L.Settings.FrameOffsetYTooltip,
			get = Get,
			set = Set,
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

		local function Generator(owner, rootDescription, data)
			for label, enumValue in pairs(Private.Enum.Anchor) do
				local function IsEnabled()
					return TargetedSpellsSaved.Settings.Party.SourceAnchor == enumValue
				end

				local function SetProxy()
					Set(LibEditMode:GetActiveLayoutName(), enumValue)
				end

				rootDescription:CreateCheckbox(label, IsEnabled, SetProxy, {
					value = label,
					multiple = false,
				})
			end
		end

		---@type LibEditModeDropdown
		return {
			name = L.Settings.FrameSourceAnchorLabel,
			kind = Enum.EditModeSettingDisplayType.Dropdown,
			default = defaults.SourceAnchor,
			desc = L.Settings.FrameSourceAnchorTooltip,
			generator = Generator,
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

		local function Generator(owner, rootDescription, data)
			for label, enumValue in pairs(Private.Enum.Anchor) do
				local function IsEnabled()
					return TargetedSpellsSaved.Settings.Party.TargetAnchor == enumValue
				end

				local function SetProxy()
					Set(LibEditMode:GetActiveLayoutName(), enumValue)
				end

				rootDescription:CreateCheckbox(label, IsEnabled, SetProxy, {
					value = label,
					multiple = false,
				})
			end
		end

		---@type LibEditModeDropdown
		return {
			name = L.Settings.FrameTargetAnchorLabel,
			kind = Enum.EditModeSettingDisplayType.Dropdown,
			default = defaults.TargetAnchor,
			desc = L.Settings.FrameTargetAnchorTooltip,
			generator = Generator,
			set = Set,
		}
	end

	if key == Private.Settings.Keys.Self.SortOrder or key == Private.Settings.Keys.Party.SortOrder then
		local tableRef = key == Private.Settings.Keys.Self.SortOrder and TargetedSpellsSaved.Settings.Self
			or TargetedSpellsSaved.Settings.Party

		---@param layoutName string
		---@param value number
		local function Set(layoutName, value)
			if tableRef.SortOrder ~= value then
				tableRef.SortOrder = value
				Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
			end
		end

		local function Generator(owner, rootDescription, data)
			for label, id in pairs(Private.Enum.SortOrder) do
				local function IsEnabled()
					return tableRef.SortOrder == id
				end

				local function SetProxy()
					Set(LibEditMode:GetActiveLayoutName(), id)
				end

				local translated = id == Private.Enum.SortOrder.Ascending and L.Settings.FrameSortOrderAscending
					or L.Settings.FrameSortOrderDescending

				rootDescription:CreateCheckbox(translated, IsEnabled, SetProxy, {
					value = id,
					multiple = false,
				})
			end
		end

		---@type LibEditModeDropdown
		return {
			name = L.Settings.FrameSortOrderLabel,
			kind = Enum.EditModeSettingDisplayType.Dropdown,
			default = defaults.SortOrder,
			desc = L.Settings.FrameSortOrderTooltip,
			generator = Generator,
			set = Set,
		}
	end

	if key == Private.Settings.Keys.Self.Grow or key == Private.Settings.Keys.Party.Grow then
		local tableRef = key == Private.Settings.Keys.Self.Grow and TargetedSpellsSaved.Settings.Self
			or TargetedSpellsSaved.Settings.Party

		---@param layoutName string
		---@param value number
		local function Set(layoutName, value)
			if tableRef.Grow ~= value then
				tableRef.Grow = value
				Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
			end
		end

		local function Generator(owner, rootDescription, data)
			for label, id in pairs(Private.Enum.Grow) do
				local function IsEnabled()
					return tableRef.Grow == id
				end

				local function SetProxy()
					Set(LibEditMode:GetActiveLayoutName(), id)
				end

				local translated = L.Settings.FrameGrowLabels[id]

				rootDescription:CreateCheckbox(translated, IsEnabled, SetProxy, {
					value = id,
					multiple = false,
				})
			end
		end

		---@type LibEditModeDropdown
		return {
			name = L.Settings.FrameGrowLabel,
			kind = Enum.EditModeSettingDisplayType.Dropdown,
			default = defaults.Grow,
			desc = L.Settings.FrameGrowTooltip,
			generator = Generator,
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
		) and Private.Utils.RollDice()
	then
		frame:ShowGlow(true)
	else
		frame:HideGlow()
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
	self.maxFrames = 5

	self.editModeFrame:SetPoint("CENTER", UIParent)
	self:ResizeEditModeFrame()
end

function SelfEditModeMixin:ResizeEditModeFrame()
	local width, gap, height, direction =
		TargetedSpellsSaved.Settings.Self.Width,
		TargetedSpellsSaved.Settings.Self.Gap,
		TargetedSpellsSaved.Settings.Self.Height,
		TargetedSpellsSaved.Settings.Self.Direction

	if direction == Private.Enum.Direction.Horizontal then
		local totalWidth = (self.maxFrames * width) + (self.maxFrames - 1) * gap
		self.editModeFrame:SetSize(totalWidth, height)
	else
		local totalHeight = (self.maxFrames * height) + (self.maxFrames - 1) * gap
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
	LibEditMode:AddFrame(
		self.editModeFrame,
		GenerateClosure(self.OnEditModePositionChanged, self),
		Private.Settings.GetDefaultEditModeFramePosition(),
		Private.L.EditMode.TargetedSpellsSelfLabel
	)

	LibEditMode:RegisterCallback("layout", GenerateClosure(self.RestoreEditModePosition, self))

	local settingsOrder = Private.Settings.GetSettingsDisplayOrder(Private.Enum.FrameKind.Self)
	local settings = {}
	local defaults = Private.Settings.GetSelfDefaultSettings()

	for i, key in ipairs(settingsOrder) do
		table.insert(settings, self:CreateSetting(key, defaults))
	end

	LibEditMode:AddFrameSettings(self.editModeFrame, settings)
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

	for index = 1, self.maxFrames do
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
	then
		if
			key == Private.Settings.Keys.Self.Width
			or key == Private.Settings.Keys.Self.Height
			or key == Private.Settings.Keys.Self.Gap
			or key == Private.Settings.Keys.Self.Direction
		then
			self:ResizeEditModeFrame()
		end

		self:RepositionPreviewFrames()
	elseif key == Private.Settings.Keys.Self.GlowImportant then
		local glowEnabled = value

		for _, frame in pairs(self.frames) do
			if glowEnabled and frame:IsVisible() and Private.Utils.RollDice() then
				frame:ShowGlow(true)
			else
				frame:HideGlow()
			end
		end
	elseif key == Private.Settings.Keys.Self.GlowType then
		if not TargetedSpellsSaved.Settings.Self.GlowImportant then
			return
		end

		for _, frame in pairs(self.frames) do
			if frame:IsVisible() and Private.Utils.RollDice() then
				frame:ShowGlow(true)
			else
				frame:HideGlow()
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
		if Private.IsMidnight and TargetedSpellsSaved.Settings.Party.Enabled then
			local accountSettings = C_EditMode.GetAccountSettings()

			for i, setting in pairs(accountSettings) do
				if setting.setting == Enum.EditModeAccountSetting.ShowPartyFrames and setting.value == 0 then
					C_EditMode.SetAccountSetting(Enum.EditModeAccountSetting.ShowPartyFrames, 1)
					break
				end
			end
		end

		local useRaidStylePartyFrames = EditModeManagerFrame:UseRaidStylePartyFrames()

		if useRaidStylePartyFrames == self.useRaidStylePartyFrames then
			return
		end

		self.useRaidStylePartyFrames = useRaidStylePartyFrames
		self:RepositionEditModeFrame()
	end)

	-- dirtying checkboxes while edit mode is opened doesn't fire any events
	hooksecurefunc(EditModeManagerFrame, "OnAccountSettingChanged", function(editModeManagerSelf, accountSetting, value)
		if
			not TargetedSpellsSaved.Settings.Party.Enabled
			or accountSetting ~= Enum.EditModeAccountSetting.ShowPartyFrames
		then
			return
		end

		if value then
			self:StartDemo()
			self:RepositionEditModeFrame()
			self.editModeFrame:Show()
		else
			self:EndDemo()
			self.editModeFrame:Hide()
		end
	end)

	-- dirtying settings while edit mode is opened doesn't fire any events eitehr
	hooksecurefunc(EditModeSystemSettingsDialog, "OnSettingValueChanged", function(settingsSelf, setting, checked)
		if
			not TargetedSpellsSaved.Settings.Party.Enabled
			or setting ~= Enum.EditModeUnitFrameSetting.UseRaidStylePartyFrames
		then
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
	LibEditMode:AddFrame(
		self.editModeFrame,
		GenerateClosure(self.OnEditModePositionChanged, self),
		Private.Settings.GetDefaultEditModeFramePosition(),
		"Targeted Spells - Party"
	)
	self.editModeFrame:SetScript("OnDragStart", nil)
	self.editModeFrame:SetScript("OnDragStop", nil)

	local settingsOrder = Private.Settings.GetSettingsDisplayOrder(Private.Enum.FrameKind.Party)
	local settings = {}
	local defaults = Private.Settings.GetPartyDefaultSettings()

	for i, key in ipairs(settingsOrder) do
		table.insert(settings, self:CreateSetting(key, defaults))
	end

	LibEditMode:AddFrameSettings(self.editModeFrame, settings)
	self:RepositionEditModeFrame()
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
				if frame:IsVisible() and glowEnabled and Private.Utils.RollDice() then
					frame:ShowGlow(true)
				else
					frame:HideGlow()
				end
			end
		end
	elseif key == Private.Settings.Keys.Party.GlowType then
		if not Private.Settings.Keys.Party.GlowImportant then
			return
		end

		for _, frames in pairs(self.frames) do
			for _, frame in pairs(frames) do
				if frame:IsVisible() and Private.Utils.RollDice() then
					frame:ShowGlow(true)
				else
					frame:HideGlow()
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
			if self.frames[unit] == nil then
				self.frames[unit] = {}
			end

			if unit == self.maxUnitCount and not self.useRaidStylePartyFrames then
				break
			end

			for index = 1, self.amountOfPreviewFramesPerUnit do
				if self.frames[unit][index] == nil then
					self.frames[unit][index] = self:AcquireFrame()
				end

				local frame = self.frames[unit][index]

				table.insert(
					self.demoTimers.tickers,
					C_Timer.NewTicker(5 + index + unit, GenerateClosure(self.LoopFrame, self, frame, index + unit))
				)

				self:LoopFrame(frame, index + unit)
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
