---@type string, TargetedSpells
local addonName, Private = ...
local LibEditMode = LibStub("LibEditMode")

---@class TargetedSpellsEditModeMixin
local TargetedSpellsEditModeMixin = {}

function TargetedSpellsEditModeMixin:Init(displayName, frameKind)
	self.displayName = displayName
	self.frameKind = frameKind
	self.demoPlaying = false
	self.frames = {}
	self.demoTimers = {
		tickers = {},
		timers = {},
	}
	self.editModeFrame = CreateFrame("Frame", displayName, UIParent)
	self.editModeFrame:SetClampedToScreen(true)
	-- some addons such as BetterCooldownManager toggle the edit mode briefly on login/loading screen end
	-- which would toggle demos on our end. by flipping this bool, we can avoid that entirely, speeding up load time
	self.editModeFrame.firstFrameTimestamp = 0

	self.editModeFrame:RegisterEvent("FIRST_FRAME_RENDERED")
	self.editModeFrame:SetScript("OnEvent", function(self, event)
		self.firstFrameTimestamp = GetTime()
		self:SetScript("OnEvent", nil)
		self:UnregisterAllEvents()
	end)

	Private.Utils.RegisterEditModeFrame(frameKind, self.editModeFrame)
	Private.EventRegistry:RegisterCallback(Private.Enum.Events.SETTING_CHANGED, self.OnSettingsChanged, self)
	LibEditMode:RegisterCallback("enter", GenerateClosure(self.StartDemo, self))

	LibEditMode:RegisterCallback("exit", GenerateClosure(self.EndDemo, self))

	self:AppendSettings()
end

function TargetedSpellsEditModeMixin:IsPastLoadingScreen()
	return (GetTime() - self.editModeFrame.firstFrameTimestamp) > 1
end

function TargetedSpellsEditModeMixin:OnSettingsChanged(key, flagIdOrValue, newBool)
	if
		-- self
		key == Private.Settings.Keys.Self.Gap
		or key == Private.Settings.Keys.Self.Direction
		or key == Private.Settings.Keys.Self.Width
		or key == Private.Settings.Keys.Self.Height
		or key == Private.Settings.Keys.Self.SortOrder
		or key == Private.Settings.Keys.Self.Grow
		or key == Private.Settings.Keys.Self.GlowType
		-- party
		or key == Private.Settings.Keys.Party.Gap
		or key == Private.Settings.Keys.Party.Width
		or key == Private.Settings.Keys.Party.Height
		or key == Private.Settings.Keys.Party.SortOrder
		or key == Private.Settings.Keys.Party.Grow
		or key == Private.Settings.Keys.Party.GlowType
	then
		self:OnLayoutSettingChanged(key, flagIdOrValue)
	elseif key == Private.Settings.Keys.Self.Enabled or key == Private.Settings.Keys.Party.Enabled then
		if not LibEditMode:IsInEditMode() then
			return
		end

		if
			(key == Private.Settings.Keys.Self.Enabled and self.frameKind == Private.Enum.FrameKind.Self)
			or (key == Private.Settings.Keys.Party.Enabled and self.frameKind == Private.Enum.FrameKind.Party)
		then
			if flagIdOrValue then
				self:StartDemo()
			else
				self:EndDemo()
			end
		end
	elseif key == Private.Settings.Keys.Party.BackgroundBarColor then
		if not LibEditMode:IsInEditMode() then
			return
		end

		for _, frame in pairs(self.frames) do
			if frame.SetBackgroundBarColor then
				frame:SetBackgroundBarColor()
			end
		end
	elseif
		key == Private.Settings.Keys.Party.ProgressBarColor
		or key == Private.Settings.Keys.Party.UseInterruptabilityColors
		or key == Private.Settings.Keys.Party.UseTargetClassColor
		or key == Private.Settings.Keys.Party.UninterruptibleColor
		or key == Private.Settings.Keys.Party.InterruptibleColor
	then
		if not LibEditMode:IsInEditMode() then
			return
		end

		if self.frameKind == Private.Enum.FrameKind.Party then
			for _, frame in pairs(self.frames) do
				if frame.SetPreviewBarColor then
					frame:SetPreviewBarColor()
				end
			end
		end
	elseif key == Private.Settings.Keys.Self.FeatureFlags or key == Private.Settings.Keys.Party.FeatureFlags then
		local flagId = flagIdOrValue

		if
			flagId == Private.Enum.FeatureFlag.GlowImportant
			or flagId == Private.Enum.FeatureFlag.ShowTargetMarker
			or flagId == Private.Enum.FeatureFlag.InlineDuration
		then
			self:OnLayoutSettingChanged(key, flagId, newBool)
		elseif
			flagId == Private.Enum.FeatureFlag.OnlyImportant
			or flagId == Private.Enum.FeatureFlag.ShowTargetClassColor
		then
			if not LibEditMode:IsInEditMode() then
				return
			end

			local isSelf = key == Private.Settings.Keys.Self.FeatureFlags

			if
				(isSelf and self.frameKind == Private.Enum.FrameKind.Self)
				or (not isSelf and self.frameKind == Private.Enum.FrameKind.Party)
			then
				self:EndDemo()
				self:StartDemo()
			end
		end
	end
end

function TargetedSpellsEditModeMixin:CreateImportExportButtons()
	return {
		{
			click = function()
				self:OnImportButtonClick()
			end,
			text = Private.L.Settings.Import,
		},
		{
			click = function()
				self:OnExportButtonClick()
			end,
			text = Private.L.Settings.Export,
		},
		{
			click = function()
				self:OnDiscordButtonClick()
			end,
			text = "Discord",
		},
	}
end

function TargetedSpellsEditModeMixin:OnDiscordButtonClick()
	local link = C_EncodingUtil.DeserializeCBOR(
		C_EncodingUtil.DecodeBase64("oURsaW5rWB1odHRwczovL2Rpc2NvcmQuZ2cvQzVTVGpZUnNDRA==")
	).link

	Private.Utils.ShowStaticPopup(Private.Utils.CreateEditablePopup("Discord", link, ACCEPT))
end

function TargetedSpellsEditModeMixin:OnExportButtonClick()
	Private.Utils.ShowStaticPopup(
		Private.Utils.CreateEditablePopup(Private.L.Settings.Export, Private.Utils.Export(), ACCEPT)
	)
end

function TargetedSpellsEditModeMixin:OnImportButtonClick()
	Private.Utils.ShowStaticPopup({
		text = Private.L.Settings.Import,
		button1 = Private.L.Settings.Import,
		button2 = CLOSE,
		hasEditBox = true,
		hasWideEditBox = true,
		editBoxWidth = 350,
		hideOnEscape = true,
		OnAccept = function(popupSelf)
			local editBox = popupSelf:GetEditBox()
			self:OnImportConfirmation(editBox:GetText())
		end,
	})
end

function TargetedSpellsEditModeMixin:OnImportConfirmation(encodedString)
	local hasAnyChange = Private.Utils.Import(encodedString)

	if hasAnyChange then
		LibEditMode:RefreshFrameSettings(self.editModeFrame)
	end
end

do
	---@param value number
	---@return string
	local function FloatToHex(value)
		return string.format("%02X", math.floor(value * 255 + 0.5))
	end

	function TargetedSpellsEditModeMixin:CreateSetting(key, defaults)
		local L = Private.L

		if key == Private.Settings.Keys.Self.FontFlags or key == Private.Settings.Keys.Party.FontFlags then
			local tableRef = key == Private.Settings.Keys.Self.FontFlags and TargetedSpellsSaved.Settings.Self
				or TargetedSpellsSaved.Settings.Party

			local function Generator(owner, rootDescription, data)
				for label, id in pairs(Private.Enum.FontFlags) do
					local function IsEnabled()
						return tableRef.FontFlags[id] == true
					end

					local function Toggle()
						tableRef.FontFlags[id] = not tableRef.FontFlags[id]

						Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, tableRef.FontFlags)
					end

					local translated = L.Settings.FontFlagsLabels[id]

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
					if tableRef.FontFlags[id] ~= bool then
						tableRef.FontFlags[id] = bool
						hasChanges = true
					end
				end

				if hasChanges then
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, tableRef.FontFlags)
				end
			end

			---@type LibEditModeDropdown
			return {
				name = L.Settings.FontFlagsLabel,
				kind = Enum.EditModeSettingDisplayType.Dropdown,
				default = defaults.FontFlags,
				desc = L.Settings.FontFlagsTooltip,
				generator = Generator,
				-- technically is a reset only
				set = Set,
			}
		end

		if key == Private.Settings.Keys.Self.Font or key == Private.Settings.Keys.Party.Font then
			local tableRef = key == Private.Settings.Keys.Self.Font and TargetedSpellsSaved.Settings.Self
				or TargetedSpellsSaved.Settings.Party

			---@param layoutName string
			---@param value string
			local function Set(layoutName, value)
				if tableRef.Font ~= value then
					tableRef.Font = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end

			---@param path string
			---@param label string
			---@return string globalName
			local function CreateAndGetFontIfNeeded(path, label)
				local sanitizedName = string.gsub(label, " ", "")
				local globalName = addonName .. "_" .. sanitizedName

				if _G[globalName] == nil then
					local locale = GAME_LOCALE or GetLocale()
					local overrideAlphabet = "roman"
					if locale == "koKR" then
						overrideAlphabet = "korean"
					elseif locale == "zhCN" then
						overrideAlphabet = "simplifiedchinese"
					elseif locale == "zhTW" then
						overrideAlphabet = "traditionalchinese"
					elseif locale == "ruRU" then
						overrideAlphabet = "russian"
					end

					local members = {}
					local coreFont = GameFontNormal
					local alphabets = { "roman", "korean", "simplifiedchinese", "traditionalchinese", "russian" }
					for _, alphabet in ipairs(alphabets) do
						local forAlphabet = coreFont:GetFontObjectForAlphabet(alphabet)
						local file, size, _ = forAlphabet:GetFont()
						if alphabet == overrideAlphabet then
							table.insert(members, {
								alphabet = alphabet,
								file = path,
								height = size,
								flags = "",
							})
						else
							table.insert(members, {
								alphabet = alphabet,
								file = file,
								height = size,
								flags = "",
							})
						end
					end

					local font = CreateFontFamily(globalName, members)
					font:SetTextColor(1, 1, 1)
					_G[globalName] = font
				end

				return globalName
			end

			local function Generator(owner, rootDescription, data)
				rootDescription:SetScrollMode(20 * 10)

				local fontInfo = Private.Settings.GetFontOptions()

				for index, label in pairs(fontInfo.fonts) do
					local path = fontInfo.byLabel[label]

					local function IsEnabled()
						return tableRef.Font == path
					end

					local function SetProxy()
						Set(LibEditMode:GetActiveLayoutName(), path)
					end

					local radio = rootDescription:CreateRadio(label, IsEnabled, SetProxy)

					radio:AddInitializer(function(button, elementDescription, menu)
						local globalName = CreateAndGetFontIfNeeded(path, label)
						button.fontString:SetFontObject(globalName)
					end)
				end
			end

			---@type LibEditModeDropdown
			return {
				name = L.Settings.FontLabel,
				kind = Enum.EditModeSettingDisplayType.Dropdown,
				desc = L.Settings.FontTooltip,
				default = defaults.Font,
				multiple = false,
				generator = Generator,
				set = Set,
			}
		end

		if key == Private.Settings.Keys.Party.ForegroundBarTexture then
			---@param layoutName string
			---@param value string
			local function Set(layoutName, value)
				if TargetedSpellsSaved.Settings.Party.ForegroundBarTexture ~= value then
					TargetedSpellsSaved.Settings.Party.ForegroundBarTexture = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end

			local function Generator(owner, rootDescription, data)
				rootDescription:SetScrollMode(20 * 10)

				for _, label in ipairs(Private.Settings.GetStatusBarOptions()) do
					local function IsEnabled()
						return TargetedSpellsSaved.Settings.Party.ForegroundBarTexture == label
					end

					local function SetProxy()
						Set(LibEditMode:GetActiveLayoutName(), label)
					end

					rootDescription:CreateRadio(label, IsEnabled, SetProxy)
				end
			end

			---@type LibEditModeDropdown
			return {
				name = L.Settings.ForegroundBarTextureLabel,
				kind = Enum.EditModeSettingDisplayType.Dropdown,
				desc = L.Settings.ForegroundBarTextureTooltip,
				default = defaults.ForegroundBarTexture,
				multiple = false,
				generator = Generator,
				set = Set,
			}
		end

		if key == Private.Settings.Keys.Party.BackgroundBarTexture then
			---@param layoutName string
			---@param value string
			local function Set(layoutName, value)
				if TargetedSpellsSaved.Settings.Party.BackgroundBarTexture ~= value then
					TargetedSpellsSaved.Settings.Party.BackgroundBarTexture = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end

			local function Generator(owner, rootDescription, data)
				rootDescription:SetScrollMode(20 * 10)

				for _, label in ipairs(Private.Settings.GetBackgroundOptions()) do
					local function IsEnabled()
						return TargetedSpellsSaved.Settings.Party.BackgroundBarTexture == label
					end

					local function SetProxy()
						Set(LibEditMode:GetActiveLayoutName(), label)
					end

					rootDescription:CreateRadio(label, IsEnabled, SetProxy)
				end
			end

			---@type LibEditModeDropdown
			return {
				name = L.Settings.BackgroundBarTextureLabel,
				kind = Enum.EditModeSettingDisplayType.Dropdown,
				desc = L.Settings.BackgroundBarTextureTooltip,
				default = defaults.BackgroundBarTexture,
				multiple = false,
				generator = Generator,
				set = Set,
			}
		end

		if key == Private.Settings.Keys.Party.BackgroundBarColor then
			---@param layoutName string
			---@param value ColorMixin
			local function Set(layoutName, value)
				local r, g, b, a = value:GetRGBA()
				local hex = FloatToHex(a) .. FloatToHex(r) .. FloatToHex(g) .. FloatToHex(b)

				if TargetedSpellsSaved.Settings.Party.BackgroundBarColor ~= hex then
					TargetedSpellsSaved.Settings.Party.BackgroundBarColor = hex
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, hex)
				end
			end

			---@param layoutName string
			local function Get(layoutName)
				return CreateColorFromHexString(TargetedSpellsSaved.Settings.Party.BackgroundBarColor)
			end

			---@type LibEditModeColorPicker
			return {
				name = L.Settings.BackgroundBarColorLabel,
				kind = LibEditMode.SettingType.ColorPicker,
				desc = L.Settings.BackgroundBarColorTooltip,
				default = CreateColorFromHexString(defaults.BackgroundBarColor),
				hasOpacity = true,
				get = Get,
				set = Set,
			}
		end

		if key == Private.Settings.Keys.Party.ProgressBarColor then
			---@param layoutName string
			---@param value ColorMixin
			local function Set(layoutName, value)
				local r, g, b, a = value:GetRGBA()
				local hex = FloatToHex(a) .. FloatToHex(r) .. FloatToHex(g) .. FloatToHex(b)

				if TargetedSpellsSaved.Settings.Party.ProgressBarColor ~= hex then
					TargetedSpellsSaved.Settings.Party.ProgressBarColor = hex
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, hex)
				end
			end

			---@param layoutName string
			local function Get(layoutName)
				return CreateColorFromHexString(TargetedSpellsSaved.Settings.Party.ProgressBarColor)
			end

			---@type LibEditModeColorPicker
			return {
				name = L.Settings.ProgressBarColorLabel,
				kind = LibEditMode.SettingType.ColorPicker,
				desc = L.Settings.ProgressBarColorTooltip,
				default = CreateColorFromHexString(defaults.ProgressBarColor),
				hasOpacity = true,
				get = Get,
				set = Set,
			}
		end

		if key == Private.Settings.Keys.Party.UseInterruptabilityColors then
			---@param layoutName string
			---@param value boolean
			local function Set(layoutName, value)
				if TargetedSpellsSaved.Settings.Party.UseInterruptabilityColors ~= value then
					TargetedSpellsSaved.Settings.Party.UseInterruptabilityColors = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)

					if value then
						LibEditMode:EnableFrameSetting(self.editModeFrame, L.Settings.UninterruptibleColorLabel)
						LibEditMode:EnableFrameSetting(self.editModeFrame, L.Settings.InterruptibleColorLabel)

						if TargetedSpellsSaved.Settings.Party.UseTargetClassColor then
							TargetedSpellsSaved.Settings.Party.UseTargetClassColor = false
							Private.EventRegistry:TriggerEvent(
								Private.Enum.Events.SETTING_CHANGED,
								Private.Settings.Keys.Party.UseTargetClassColor,
								false
							)

							LibEditMode:RefreshFrameSettings(self.editModeFrame)
						end
					else
						LibEditMode:DisableFrameSetting(self.editModeFrame, L.Settings.UninterruptibleColorLabel)
						LibEditMode:DisableFrameSetting(self.editModeFrame, L.Settings.InterruptibleColorLabel)
					end
				end
			end

			---@param layoutName string
			local function Get(layoutName)
				return TargetedSpellsSaved.Settings.Party.UseInterruptabilityColors
			end

			---@type LibEditModeCheckbox
			return {
				name = L.Settings.UseInterruptabilityColorsLabel,
				kind = LibEditMode.SettingType.Checkbox,
				desc = L.Settings.UseInterruptabilityColorsTooltip,
				default = defaults.UseInterruptabilityColors,
				get = Get,
				set = Set,
			}
		end

		if key == Private.Settings.Keys.Party.UseTargetClassColor then
			---@param layoutName string
			---@param value boolean
			local function Set(layoutName, value)
				if TargetedSpellsSaved.Settings.Party.UseTargetClassColor ~= value then
					TargetedSpellsSaved.Settings.Party.UseTargetClassColor = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)

					if value and TargetedSpellsSaved.Settings.Party.UseInterruptabilityColors then
						TargetedSpellsSaved.Settings.Party.UseInterruptabilityColors = false
						Private.EventRegistry:TriggerEvent(
							Private.Enum.Events.SETTING_CHANGED,
							Private.Settings.Keys.Party.UseInterruptabilityColors,
							false
						)

						LibEditMode:DisableFrameSetting(self.editModeFrame, L.Settings.UninterruptibleColorLabel)
						LibEditMode:DisableFrameSetting(self.editModeFrame, L.Settings.InterruptibleColorLabel)

						LibEditMode:RefreshFrameSettings(self.editModeFrame)
					end
				end
			end

			---@param layoutName string
			local function Get(layoutName)
				return TargetedSpellsSaved.Settings.Party.UseTargetClassColor
			end

			---@type LibEditModeCheckbox
			return {
				name = L.Settings.UseTargetClassColorLabel,
				kind = LibEditMode.SettingType.Checkbox,
				desc = L.Settings.UseTargetClassColorTooltip,
				default = defaults.UseTargetClassColor,
				get = Get,
				set = Set,
			}
		end

		if key == Private.Settings.Keys.Party.UninterruptibleColor then
			---@param layoutName string
			---@param value ColorMixin
			local function Set(layoutName, value)
				local r, g, b, a = value:GetRGBA()
				local hex = FloatToHex(a) .. FloatToHex(r) .. FloatToHex(g) .. FloatToHex(b)

				if TargetedSpellsSaved.Settings.Party.UninterruptibleColor ~= hex then
					TargetedSpellsSaved.Settings.Party.UninterruptibleColor = hex
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, hex)
				end
			end

			---@param layoutName string
			local function Get(layoutName)
				return CreateColorFromHexString(TargetedSpellsSaved.Settings.Party.UninterruptibleColor)
			end

			---@type LibEditModeColorPicker
			return {
				name = L.Settings.UninterruptibleColorLabel,
				kind = LibEditMode.SettingType.ColorPicker,
				desc = L.Settings.UninterruptibleColorTooltip,
				default = CreateColorFromHexString(defaults.UninterruptibleColor),
				hasOpacity = true,
				get = Get,
				set = Set,
				disabled = not TargetedSpellsSaved.Settings.Party.UseInterruptabilityColors,
			}
		end

		if key == Private.Settings.Keys.Party.InterruptibleColor then
			---@param layoutName string
			---@param value ColorMixin
			local function Set(layoutName, value)
				local r, g, b, a = value:GetRGBA()
				local hex = FloatToHex(a) .. FloatToHex(r) .. FloatToHex(g) .. FloatToHex(b)

				if TargetedSpellsSaved.Settings.Party.InterruptibleColor ~= hex then
					TargetedSpellsSaved.Settings.Party.InterruptibleColor = hex
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, hex)
				end
			end

			---@param layoutName string
			local function Get(layoutName)
				return CreateColorFromHexString(TargetedSpellsSaved.Settings.Party.InterruptibleColor)
			end

			---@type LibEditModeColorPicker
			return {
				name = L.Settings.InterruptibleColorLabel,
				kind = LibEditMode.SettingType.ColorPicker,
				desc = L.Settings.InterruptibleColorTooltip,
				default = CreateColorFromHexString(defaults.InterruptibleColor),
				hasOpacity = true,
				get = Get,
				set = Set,
				disabled = not TargetedSpellsSaved.Settings.Party.UseInterruptabilityColors,
			}
		end

		if key == Private.Settings.Keys.Self.IconZoom then
			local sliderSettings = Private.Settings.GetSliderSettingsForOption(key)

			---@param layoutName string
			local function Get(layoutName)
				return TargetedSpellsSaved.Settings.Self.IconZoom
			end

			---@param layoutName string
			---@param value number
			local function Set(layoutName, value)
				if value ~= TargetedSpellsSaved.Settings.Self.IconZoom then
					TargetedSpellsSaved.Settings.Self.IconZoom = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end

			---@type LibEditModeSlider
			return {
				name = L.Settings.IconZoomLabel,
				kind = Enum.EditModeSettingDisplayType.Slider,
				default = defaults.IconZoom,
				desc = L.Settings.IconZoomTooltip,
				get = Get,
				set = Set,
				minValue = sliderSettings.min,
				maxValue = sliderSettings.max,
				valueStep = sliderSettings.step,
				formatter = FormatPercentage,
			}
		end

		if key == Private.Settings.Keys.Self.FeatureFlags or key == Private.Settings.Keys.Party.FeatureFlags then
			local kind = key == Private.Settings.Keys.Self.FeatureFlags and Private.Enum.FrameKind.Self
				or Private.Enum.FrameKind.Party
			local tableRef = kind == Private.Enum.FrameKind.Self and TargetedSpellsSaved.Settings.Self
				or TargetedSpellsSaved.Settings.Party

			local function Generator(owner, rootDescription, data)
				for _, id in ipairs(Private.Settings.GetFeatureFlagsForKind(kind)) do
					local title = L.Settings.FeatureFlagSettingTitles[id]

					if title then
						rootDescription:CreateTitle(title)
					end

					local function IsEnabled()
						return tableRef.FeatureFlags[id] == true
					end

					local function Toggle()
						tableRef.FeatureFlags[id] = not tableRef.FeatureFlags[id]
						Private.EventRegistry:TriggerEvent(
							Private.Enum.Events.SETTING_CHANGED,
							key,
							id,
							tableRef.FeatureFlags[id]
						)

						if tableRef.FeatureFlags[id] then
							if id == Private.Enum.FeatureFlag.HideUntargetedSpells then
								if tableRef.FeatureFlags[Private.Enum.FeatureFlag.HideTargetedSpells] then
									tableRef.FeatureFlags[Private.Enum.FeatureFlag.HideTargetedSpells] = false
									Private.EventRegistry:TriggerEvent(
										Private.Enum.Events.SETTING_CHANGED,
										key,
										Private.Enum.FeatureFlag.HideTargetedSpells,
										false
									)
								end
							elseif id == Private.Enum.FeatureFlag.HideTargetedSpells then
								if tableRef.FeatureFlags[Private.Enum.FeatureFlag.HideUntargetedSpells] then
									tableRef.FeatureFlags[Private.Enum.FeatureFlag.HideUntargetedSpells] = false
									Private.EventRegistry:TriggerEvent(
										Private.Enum.Events.SETTING_CHANGED,
										key,
										Private.Enum.FeatureFlag.HideUntargetedSpells,
										false
									)
								end

								if tableRef.FeatureFlags[Private.Enum.FeatureFlag.SelfOnly] then
									tableRef.FeatureFlags[Private.Enum.FeatureFlag.SelfOnly] = false
									Private.EventRegistry:TriggerEvent(
										Private.Enum.Events.SETTING_CHANGED,
										key,
										Private.Enum.FeatureFlag.SelfOnly,
										false
									)
								end
							elseif id == Private.Enum.FeatureFlag.SelfOnly then
								if tableRef.FeatureFlags[Private.Enum.FeatureFlag.HideTargetedSpells] then
									tableRef.FeatureFlags[Private.Enum.FeatureFlag.HideTargetedSpells] = false
									Private.EventRegistry:TriggerEvent(
										Private.Enum.Events.SETTING_CHANGED,
										key,
										Private.Enum.FeatureFlag.HideTargetedSpells,
										false
									)
								end
							end
						end
					end

					rootDescription:CreateCheckbox(L.Settings.FeatureFlagLabels[id], IsEnabled, Toggle, {
						value = id,
						multiple = true,
					})
				end
			end

			---@param layoutName string
			---@param values table<number, boolean>
			local function Set(layoutName, values)
				for id, bool in pairs(values) do
					if tableRef.FeatureFlags[id] ~= bool then
						tableRef.FeatureFlags[id] = bool
						Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, id, bool)
					end
				end
			end

			---@type LibEditModeDropdown
			return {
				name = L.Settings.FeatureFlagsLabel,
				kind = Enum.EditModeSettingDisplayType.Dropdown,
				default = defaults.FeatureFlags,
				desc = L.Settings.FeatureFlagsTooltip,
				generator = Generator,
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
				local kind = key == Private.Settings.Keys.Self.GlowType and Private.Enum.FrameKind.Self
					or Private.Enum.FrameKind.Party

				for _, id in ipairs(Private.Settings.GetGlowTypesForKind(kind)) do
					local function IsEnabled()
						return tableRef.GlowType == id
					end

					local function SetProxy()
						Set(LibEditMode:GetActiveLayoutName(), id)
					end

					rootDescription:CreateRadio(L.Settings.GlowTypeLabels[id], IsEnabled, SetProxy)
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
				disabled = not tableRef.FeatureFlags[Private.Enum.FeatureFlag.GlowImportant],
			}
		end

		if
			key == Private.Settings.Keys.Self.AnnounceUntargetedSpells
			or key == Private.Settings.Keys.Party.AnnounceUntargetedSpells
		then
			local function Generator(owner, rootDescription, data)
				for _, id in pairs(Private.Enum.NpcType) do
					local function IsEnabled()
						return TargetedSpellsSaved.Settings.Self.AnnounceUntargetedSpells[id] == true
					end

					local function Toggle()
						local bool = not TargetedSpellsSaved.Settings.Self.AnnounceUntargetedSpells[id]
						TargetedSpellsSaved.Settings.Self.AnnounceUntargetedSpells[id] = bool
						TargetedSpellsSaved.Settings.Party.AnnounceUntargetedSpells[id] = bool

						Private.EventRegistry:TriggerEvent(
							Private.Enum.Events.SETTING_CHANGED,
							Private.Settings.Keys.Self.AnnounceUntargetedSpells,
							TargetedSpellsSaved.Settings.Self.AnnounceUntargetedSpells
						)
						Private.EventRegistry:TriggerEvent(
							Private.Enum.Events.SETTING_CHANGED,
							Private.Settings.Keys.Party.AnnounceUntargetedSpells,
							TargetedSpellsSaved.Settings.Party.AnnounceUntargetedSpells
						)
					end

					rootDescription:CreateCheckbox(L.Settings.NpcTypeLabels[id], IsEnabled, Toggle, {
						value = id,
						multiple = true,
					})
				end
			end

			---@param layoutName string
			---@param values table<number, boolean>
			local function Set(layoutName, values)
				for id, bool in pairs(values) do
					if TargetedSpellsSaved.Settings.Self.AnnounceUntargetedSpells[id] ~= bool then
						TargetedSpellsSaved.Settings.Self.AnnounceUntargetedSpells[id] = bool
						TargetedSpellsSaved.Settings.Party.AnnounceUntargetedSpells[id] = bool

						Private.EventRegistry:TriggerEvent(
							Private.Enum.Events.SETTING_CHANGED,
							Private.Settings.Keys.Self.AnnounceUntargetedSpells,
							TargetedSpellsSaved.Settings.Self.AnnounceUntargetedSpells
						)
						Private.EventRegistry:TriggerEvent(
							Private.Enum.Events.SETTING_CHANGED,
							Private.Settings.Keys.Party.AnnounceUntargetedSpells,
							TargetedSpellsSaved.Settings.Party.AnnounceUntargetedSpells
						)
					end
				end
			end

			---@type LibEditModeDropdown
			return {
				name = L.Settings.AnnounceUntargetedSpellsLabel,
				kind = Enum.EditModeSettingDisplayType.Dropdown,
				default = defaults.AnnounceUntargetedSpells,
				desc = L.Settings.AnnounceUntargetedSpellsTooltip,
				generator = Generator,
				set = Set,
			}
		end

		if
			key == Private.Settings.Keys.Self.AnnounceTargetedSpells
			or key == Private.Settings.Keys.Party.AnnounceTargetedSpells
		then
			local function Generator(owner, rootDescription, data)
				for _, id in pairs(Private.Enum.NpcType) do
					local function IsEnabled()
						return TargetedSpellsSaved.Settings.Self.AnnounceTargetedSpells[id] == true
					end

					local function Toggle()
						local bool = not TargetedSpellsSaved.Settings.Self.AnnounceTargetedSpells[id]
						TargetedSpellsSaved.Settings.Self.AnnounceTargetedSpells[id] = bool
						TargetedSpellsSaved.Settings.Party.AnnounceTargetedSpells[id] = bool

						Private.EventRegistry:TriggerEvent(
							Private.Enum.Events.SETTING_CHANGED,
							Private.Settings.Keys.Self.AnnounceTargetedSpells,
							TargetedSpellsSaved.Settings.Self.AnnounceTargetedSpells
						)
						Private.EventRegistry:TriggerEvent(
							Private.Enum.Events.SETTING_CHANGED,
							Private.Settings.Keys.Party.AnnounceTargetedSpells,
							TargetedSpellsSaved.Settings.Party.AnnounceTargetedSpells
						)
					end

					rootDescription:CreateCheckbox(L.Settings.NpcTypeLabels[id], IsEnabled, Toggle, {
						value = id,
						multiple = true,
					})
				end
			end

			---@param layoutName string
			---@param values table<number, boolean>
			local function Set(layoutName, values)
				for id, bool in pairs(values) do
					if TargetedSpellsSaved.Settings.Self.AnnounceTargetedSpells[id] ~= bool then
						TargetedSpellsSaved.Settings.Self.AnnounceTargetedSpells[id] = bool
						TargetedSpellsSaved.Settings.Party.AnnounceTargetedSpells[id] = bool

						Private.EventRegistry:TriggerEvent(
							Private.Enum.Events.SETTING_CHANGED,
							Private.Settings.Keys.Self.AnnounceTargetedSpells,
							TargetedSpellsSaved.Settings.Self.AnnounceTargetedSpells
						)
						Private.EventRegistry:TriggerEvent(
							Private.Enum.Events.SETTING_CHANGED,
							Private.Settings.Keys.Party.AnnounceTargetedSpells,
							TargetedSpellsSaved.Settings.Party.AnnounceTargetedSpells
						)
					end
				end
			end

			---@type LibEditModeDropdown
			return {
				name = L.Settings.AnnounceTargetedSpellsLabel,
				kind = Enum.EditModeSettingDisplayType.Dropdown,
				default = defaults.AnnounceTargetedSpells,
				desc = L.Settings.AnnounceTargetedSpellsTooltip,
				generator = Generator,
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

			local version = C_AddOns.GetAddOnMetadata(addonName, "Version")

			---@type LibEditModeCheckbox
			return {
				name = string.format("%s - %s", L.Settings.EnabledLabel, version),
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
			local kindTableRef = isSelf and TargetedSpellsSaved.Settings.Self or TargetedSpellsSaved.Settings.Party

			local function Generator(owner, rootDescription, data)
				local kind = isSelf and Private.Enum.FrameKind.Self or Private.Enum.FrameKind.Party

				for label, id in pairs(Private.Settings.GetContentTypesForKind(kind)) do
					local function IsEnabled()
						return kindTableRef.LoadConditionContentType[id]
					end

					local function Toggle()
						kindTableRef.LoadConditionContentType[id] = not kindTableRef.LoadConditionContentType[id]

						Private.EventRegistry:TriggerEvent(
							Private.Enum.Events.SETTING_CHANGED,
							key,
							kindTableRef.LoadConditionContentType
						)

						local anyEnabled = false
						for _, loadCondition in pairs(kindTableRef.LoadConditionContentType) do
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

							LibEditMode:RefreshFrameSettings(self.editModeFrame)
						end
					end

					rootDescription:CreateCheckbox(L.Settings.LoadConditionContentTypeLabels[id], IsEnabled, Toggle, {
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
					if kindTableRef.LoadConditionContentType[id] ~= bool then
						kindTableRef.LoadConditionContentType[id] = bool
						hasChanges = true
					end
				end

				if hasChanges then
					Private.EventRegistry:TriggerEvent(
						Private.Enum.Events.SETTING_CHANGED,
						key,
						kindTableRef.LoadConditionContentType
					)
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

		if
			key == Private.Settings.Keys.Self.LoadConditionRole
			or key == Private.Settings.Keys.Party.LoadConditionRole
		then
			local isSelf = key == Private.Settings.Keys.Self.LoadConditionRole
			local kindTableRef = isSelf and TargetedSpellsSaved.Settings.Self or TargetedSpellsSaved.Settings.Party

			local function Generator(owner, rootDescription, data)
				for label, id in pairs(Private.Enum.Role) do
					local function IsEnabled()
						return kindTableRef.LoadConditionRole[id] == true
					end

					local function Toggle()
						kindTableRef.LoadConditionRole[id] = not kindTableRef.LoadConditionRole[id]

						Private.EventRegistry:TriggerEvent(
							Private.Enum.Events.SETTING_CHANGED,
							key,
							kindTableRef.LoadConditionRole
						)

						local anyEnabled = false
						for role, loadCondition in pairs(kindTableRef.LoadConditionRole) do
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
					if kindTableRef.LoadConditionRole[id] ~= bool then
						kindTableRef.LoadConditionRole[id] = bool
						hasChanges = true
					end
				end

				if hasChanges then
					Private.EventRegistry:TriggerEvent(
						Private.Enum.Events.SETTING_CHANGED,
						key,
						kindTableRef.LoadConditionRole
					)
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

			local disabled = false

			if key == Private.Settings.Keys.Self.FontSize then
				disabled = not tableRef.FeatureFlags[Private.Enum.FeatureFlag.ShowDuration]
			else
				disabled = not tableRef.FeatureFlags[Private.Enum.FeatureFlag.ShowDuration]
					and not tableRef.FeatureFlags[Private.Enum.FeatureFlag.ShowSpellName]
					and not tableRef.FeatureFlags[Private.Enum.FeatureFlag.ShowTargetName]
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
				disabled = disabled,
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

		if key == Private.Settings.Keys.Self.Direction then
			---@param layoutName string
			---@param value number
			local function Set(layoutName, value)
				if TargetedSpellsSaved.Settings.Self.Direction ~= value then
					TargetedSpellsSaved.Settings.Self.Direction = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end

			local function Generator(owner, rootDescription, data)
				for label, id in pairs(Private.Enum.Direction) do
					local function IsEnabled()
						return TargetedSpellsSaved.Settings.Self.Direction == id
					end

					local function SetProxy()
						Set(LibEditMode:GetActiveLayoutName(), id)
					end

					local translated = id == Private.Enum.Direction.Horizontal and L.Settings.FrameDirectionHorizontal
						or L.Settings.FrameDirectionVertical

					rootDescription:CreateRadio(translated, IsEnabled, SetProxy)
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

					rootDescription:CreateRadio(translated, IsEnabled, SetProxy)
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

					rootDescription:CreateRadio(L.Settings.FrameGrowLabels[id], IsEnabled, SetProxy)
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

		if key == Private.Settings.Keys.Self.BorderStyle then
			---@param layoutName string
			---@param value string
			local function Set(layoutName, value)
				if TargetedSpellsSaved.Settings.Self.BorderStyle ~= value then
					TargetedSpellsSaved.Settings.Self.BorderStyle = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end

			local function Generator(owner, rootDescription, data)
				for _, label in ipairs(Private.Settings.GetBorderOptions()) do
					local function IsEnabled()
						return TargetedSpellsSaved.Settings.Self.BorderStyle == label
					end

					local function SetProxy()
						Set(LibEditMode:GetActiveLayoutName(), label)
					end

					rootDescription:CreateRadio(label, IsEnabled, SetProxy)
				end
			end

			---@type LibEditModeDropdown
			return {
				name = L.Settings.BorderStyleLabel,
				kind = Enum.EditModeSettingDisplayType.Dropdown,
				default = defaults.BorderStyle,
				desc = L.Settings.BorderStyleTooltip,
				generator = Generator,
				set = Set,
			}
		end

		if
			key == Private.Settings.Keys.Self.TextToSpeechVoice
			or key == Private.Settings.Keys.Party.TextToSpeechVoice
		then
			---@param layoutName string
			---@param value integer
			local function Set(layoutName, value)
				if value ~= TargetedSpellsSaved.Settings.Self.TextToSpeechVoice then
					TargetedSpellsSaved.Settings.Self.TextToSpeechVoice = value
					TargetedSpellsSaved.Settings.Party.TextToSpeechVoice = value

					Private.EventRegistry:TriggerEvent(
						Private.Enum.Events.SETTING_CHANGED,
						Private.Settings.Keys.Self.TextToSpeechVoice,
						value
					)
					Private.EventRegistry:TriggerEvent(
						Private.Enum.Events.SETTING_CHANGED,
						Private.Settings.Keys.Party.TextToSpeechVoice,
						value
					)

					local deafeningRoar = C_Spell.GetSpellName(1256047)

					if deafeningRoar then
						C_VoiceChat.SpeakText(value, deafeningRoar, 2, C_TTSSettings.GetSpeechVolume(), true)
					end
				end
			end

			local function Generator(owner, rootDescription, data)
				for _, voice in ipairs(Private.Settings.GetTtsVoiceOptions()) do
					local function IsEnabled()
						return TargetedSpellsSaved.Settings.Self.TextToSpeechVoice == voice.voiceID
					end

					local function SetProxy()
						Set(LibEditMode:GetActiveLayoutName(), voice.voiceID)
					end

					rootDescription:CreateRadio(voice.name, IsEnabled, SetProxy)
				end
			end

			---@type LibEditModeDropdown
			return {
				name = L.Settings.TextToSpeechVoiceLabel,
				kind = Enum.EditModeSettingDisplayType.Dropdown,
				default = 0,
				desc = L.Settings.TextToSpeechVoiceTooltip,
				multiple = false,
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
end

function TargetedSpellsEditModeMixin:ResizeEditModeFrame()
	local tableRef = self.frameKind == Private.Enum.FrameKind.Self and TargetedSpellsSaved.Settings.Self
		or TargetedSpellsSaved.Settings.Party

	if tableRef.Direction == Private.Enum.Direction.Horizontal then
		local totalWidth = (self.maxFrames * tableRef.Width) + (self.maxFrames - 1) * tableRef.Gap
		PixelUtil.SetSize(self.editModeFrame, totalWidth, tableRef.Height)
	else
		local totalHeight = (self.maxFrames * tableRef.Height) + (self.maxFrames - 1) * tableRef.Gap
		PixelUtil.SetSize(self.editModeFrame, tableRef.Width, totalHeight)
	end
end

function TargetedSpellsEditModeMixin:RestoreEditModePosition()
	local tableRef = self.frameKind == Private.Enum.FrameKind.Self and TargetedSpellsSaved.Settings.Self
		or TargetedSpellsSaved.Settings.Party

	self.editModeFrame:ClearAllPoints()
	PixelUtil.SetPoint(
		self.editModeFrame,
		tableRef.Position.point,
		UIParent,
		tableRef.Position.point,
		tableRef.Position.x,
		tableRef.Position.y
	)
end

function TargetedSpellsEditModeMixin:OnEditModePositionChanged(_, _, point, x, y)
	local tableRef = self.frameKind == Private.Enum.FrameKind.Self and TargetedSpellsSaved.Settings.Self
		or TargetedSpellsSaved.Settings.Party

	tableRef.Position.point = point
	tableRef.Position.x = x
	tableRef.Position.y = y

	Private.EventRegistry:TriggerEvent(
		self.frameKind == Private.Enum.FrameKind.Self and Private.Enum.Events.EDIT_MODE_SELF_POSITION_CHANGED
			or Private.Enum.Events.EDIT_MODE_PARTY_POSITION_CHANGED,
		point,
		x,
		y
	)
end

function TargetedSpellsEditModeMixin:AppendSettings()
	local defaults = self.frameKind == Private.Enum.FrameKind.Self and Private.Settings.GetSelfDefaultSettings()
		or Private.Settings.GetPartyDefaultSettings()

	LibEditMode:AddFrame(
		self.editModeFrame,
		GenerateClosure(self.OnEditModePositionChanged, self),
		Private.Settings.GetDefaultEditModeFramePosition(self.frameKind),
		self.displayName
	)

	LibEditMode:RegisterCallback("layout", GenerateClosure(self.RestoreEditModePosition, self))

	local settingsOrder = Private.Settings.GetSettingsDisplayOrder(self.frameKind)
	local settings = {}

	for _, key in ipairs(settingsOrder) do
		table.insert(settings, self:CreateSetting(key, defaults))
	end

	LibEditMode:AddFrameSettings(self.editModeFrame, settings)
	LibEditMode:AddFrameSettingsButtons(self.editModeFrame, self:CreateImportExportButtons())
end

function TargetedSpellsEditModeMixin:OnLayoutSettingChanged(key, value)
	local Keys = self.frameKind == Private.Enum.FrameKind.Self and Private.Settings.Keys.Self
		or Private.Settings.Keys.Party

	if
		key == Keys.Gap
		or key == Keys.Direction
		or key == Keys.Width
		or key == Keys.Height
		or key == Keys.SortOrder
		or key == Keys.Grow
	then
		if key == Keys.Width or key == Keys.Height or key == Keys.Gap or key == Keys.Direction then
			self:ResizeEditModeFrame()
		end

		self:RepositionPreviewFrames()
	end
end

function TargetedSpellsEditModeMixin:RepositionPreviewFrames()
	if not self.demoPlaying then
		return
	end

	---@type (TargetedSpellsIconMixin|TargetedSpellsBarMixin)[]
	local activeFrames = {}

	for index = 1, self.maxFrames do
		if self.frames[index] == nil then
			table.insert(
				self.demoTimers.tickers,
				C_Timer.NewTicker(5 + index, GenerateClosure(self.LoopFrame, self, index))
			)

			self:LoopFrame(index)
		end

		local frame = self.frames[index]

		if frame ~= nil and frame:ShouldBeShown() then
			table.insert(activeFrames, frame)
		end
	end

	if #activeFrames == 0 then
		return
	end

	local tableRef = self.frameKind == Private.Enum.FrameKind.Self and TargetedSpellsSaved.Settings.Self
		or TargetedSpellsSaved.Settings.Party

	Private.Utils.SortFrames(activeFrames, tableRef.SortOrder)

	local layouting = Private.Utils.CollectLayoutingArguments(
		tableRef.Direction,
		tableRef.Grow,
		tableRef.Width,
		tableRef.Height,
		tableRef.Gap
	)

	local parentDimension = layouting.isHorizontal and self.editModeFrame:GetWidth() or self.editModeFrame:GetHeight()
	local offset = layouting.isGrowEnd and (parentDimension / 2 - tableRef.Gap) or (-parentDimension / 2)

	Private.Utils.AdjustLayout(
		activeFrames,
		layouting,
		self.editModeFrame,
		"CENTER",
		layouting.isHorizontal and offset or 0,
		(not layouting.isHorizontal) and offset or 0,
		true
	)
end

function TargetedSpellsEditModeMixin:LoopFrame(index)
	if self.frames[index] == nil then
		self.frames[index] = self.pool:Acquire()
	end

	local frame = self.frames[index]
	local castTime = 4 + index / 2
	local duration = C_DurationUtil.CreateDuration()
	duration:SetTimeFromStart(GetTime(), castTime)

	frame:PostCreate({
		unit = "player",
		spellId = nil,
		startTime = GetTime(),
		id = index,
		duration = duration,
		isChannel = false,
	})

	frame:Show()
	frame:SetAlpha(secretwrap(1))

	local tableRef = self.frameKind == Private.Enum.FrameKind.Self and TargetedSpellsSaved.Settings.Self
		or TargetedSpellsSaved.Settings.Party

	if tableRef.FeatureFlags[Private.Enum.FeatureFlag.GlowImportant] and Private.Utils.RollDice() then
		frame:ShowGlow(secretwrap(true))

		if tableRef.FeatureFlags[Private.Enum.FeatureFlag.OnlyImportant] then
			frame:SetAlpha(secretwrap(1))
		end
	else
		frame:HideGlow()

		if tableRef.FeatureFlags[Private.Enum.FeatureFlag.OnlyImportant] then
			frame:SetAlpha(secretwrap(0))
		end
	end

	self:RepositionPreviewFrames()

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
	local tableRef = self.frameKind == Private.Enum.FrameKind.Self and TargetedSpellsSaved.Settings.Self
		or TargetedSpellsSaved.Settings.Party

	if self.demoPlaying or not tableRef.Enabled or not self:IsPastLoadingScreen() then
		return
	end

	self.demoPlaying = true

	self:RepositionPreviewFrames()
end

function TargetedSpellsEditModeMixin:ReleaseAllFrames()
	for index = 1, self.maxFrames do
		local frame = self.frames[index]

		if frame ~= nil then
			self.pool:Release(frame)
			self.frames[index] = nil
		end
	end
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
	self.pool = Private.Utils.Pools.Self

	PixelUtil.SetPoint(self.editModeFrame, "CENTER", UIParent, "CENTER", 0, 0)
	self:ResizeEditModeFrame()
end

function SelfEditModeMixin:OnLayoutSettingChanged(key, value, newBool)
	TargetedSpellsEditModeMixin.OnLayoutSettingChanged(self, key, value)

	if key == Private.Settings.Keys.Self.FeatureFlags and value == Private.Enum.FeatureFlag.GlowImportant then
		for _, frame in pairs(self.frames) do
			if newBool and frame:IsVisible() and Private.Utils.RollDice() then
				frame:ShowGlow(true)
			else
				frame:HideGlow()
			end
		end
	elseif key == Private.Settings.Keys.Self.GlowType then
		if not TargetedSpellsSaved.Settings.Self.FeatureFlags[Private.Enum.FeatureFlag.GlowImportant] then
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
	self.maxFrames = 5
	self.pool = Private.Utils.Pools.Bar

	Private.EventRegistry:RegisterCallback(Private.Enum.Events.PARTY_SETTINGS_MIGRATED, function()
		self:RestoreEditModePosition()
		self:ResizeEditModeFrame()
	end, self)

	self:RestoreEditModePosition()
	self:ResizeEditModeFrame()
end

function PartyEditModeMixin:OnLayoutSettingChanged(key, value, newBool)
	TargetedSpellsEditModeMixin.OnLayoutSettingChanged(self, key, value)

	if key == Private.Settings.Keys.Party.FeatureFlags and value == Private.Enum.FeatureFlag.GlowImportant then
		for _, frame in pairs(self.frames) do
			if newBool and frame:IsVisible() and Private.Utils.RollDice() then
				frame:ShowGlow(true)
			else
				frame:HideGlow()
			end
		end
	elseif key == Private.Settings.Keys.Party.FeatureFlags and value == Private.Enum.FeatureFlag.ShowTargetMarker then
		if not LibEditMode:IsInEditMode() then
			return
		end

		for _, frame in pairs(self.frames) do
			frame:SetTargetMarker(newBool and (Private.Utils.RollDice() and math.random(1, 8) or nil) or nil)
		end
	elseif key == Private.Settings.Keys.Party.GlowType then
		if not TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.GlowImportant] then
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

function PartyEditModeMixin:LoopFrame(index)
	TargetedSpellsEditModeMixin.LoopFrame(self, index)

	local frame = self.frames[index]

	frame:SetPreviewBarColor()

	if Private.Utils.RollDice() then
		frame.ProgressBar:SetTimerDuration(frame.ProgressBar:GetTimerDuration(), Enum.StatusBarInterpolation.None, 1)
	end

	frame:SetTargetMarker(Private.Utils.RollDice() and math.random(1, 8) or nil)
end

table.insert(Private.LoginFnQueue, GenerateClosure(PartyEditModeMixin.Init, PartyEditModeMixin))
