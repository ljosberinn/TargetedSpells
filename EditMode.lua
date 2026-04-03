---@type string, TargetedSpells
local addonName, Private = ...
local LibEditMode = LibStub("LibEditMode")

---@class TargetedSpellsEditModeMixin
local TargetedSpellsEditModeMixin = {}

function TargetedSpellsEditModeMixin:Init(displayName, frameKind)
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

	do
		local cb = GenerateClosure(self.StartDemo, self)

		LibEditMode:RegisterCallback("enter", QUI == nil and cb or function()
			C_Timer.After(0.25, cb)
		end)
	end

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
		or key == Private.Settings.Keys.Party.Direction
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
	elseif key == Private.Settings.Keys.Self.FeatureFlags or key == Private.Settings.Keys.Party.FeatureFlags then
		local flagId = flagIdOrValue

		if flagId == Private.Enum.FeatureFlag.GlowImportant then
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

function TargetedSpellsEditModeMixin:OnImportCancellation()
	-- Implement in your derived mixin.
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

	if key == Private.Settings.Keys.Party.SpellNameWidth then
		local sliderSettings = Private.Settings.GetSliderSettingsForOption(key)

		---@param layoutName string
		local function Get(layoutName)
			return TargetedSpellsSaved.Settings.Party.SpellNameWidth
		end

		---@param layoutName string
		---@param value number
		local function Set(layoutName, value)
			if value ~= TargetedSpellsSaved.Settings.Party.SpellNameWidth then
				TargetedSpellsSaved.Settings.Party.SpellNameWidth = value
				Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
			end
		end

		---@type LibEditModeSlider
		return {
			name = L.Settings.SpellNameWidthLabel,
			kind = Enum.EditModeSettingDisplayType.Slider,
			default = defaults.SpellNameWidth,
			desc = L.Settings.SpellNameWidthTooltip,
			get = Get,
			set = Set,
			minValue = sliderSettings.min,
			maxValue = sliderSettings.max,
			valueStep = sliderSettings.step,
			disabled = not TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.ShowSpellName],
		}
	end

	if key == Private.Settings.Keys.Party.TargetNameWidth then
		local sliderSettings = Private.Settings.GetSliderSettingsForOption(key)

		---@param layoutName string
		local function Get(layoutName)
			return TargetedSpellsSaved.Settings.Party.TargetNameWidth
		end

		---@param layoutName string
		---@param value number
		local function Set(layoutName, value)
			if value ~= TargetedSpellsSaved.Settings.Party.TargetNameWidth then
				TargetedSpellsSaved.Settings.Party.TargetNameWidth = value
				Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
			end
		end

		---@type LibEditModeSlider
		return {
			name = L.Settings.TargetNameWidthLabel,
			kind = Enum.EditModeSettingDisplayType.Slider,
			default = defaults.TargetNameWidth,
			desc = L.Settings.TargetNameWidthTooltip,
			get = Get,
			set = Set,
			minValue = sliderSettings.min,
			maxValue = sliderSettings.max,
			valueStep = sliderSettings.step,
			disabled = not TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.ShowTargetName],
		}
	end

	if key == Private.Settings.Keys.Party.NameDivider then
		---@param layoutName string
		---@param value NameDivider
		local function Set(layoutName, value)
			if TargetedSpellsSaved.Settings.Party.NameDivider ~= value then
				TargetedSpellsSaved.Settings.Party.NameDivider = value
				Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
			end
		end

		local function Generator(owner, rootDescription, data)
			for _, value in pairs(Private.Enum.NameDivider) do
				local label = value == Private.Enum.NameDivider.None and L.Settings.NameDividerNone or value

				local function IsEnabled()
					return TargetedSpellsSaved.Settings.Party.NameDivider == value
				end

				local function SetProxy()
					Set(LibEditMode:GetActiveLayoutName(), value)
				end

				rootDescription:CreateRadio(label, IsEnabled, SetProxy)
			end
		end

		---@type LibEditModeDropdown
		return {
			name = L.Settings.NameDividerLabel,
			kind = Enum.EditModeSettingDisplayType.Dropdown,
			desc = L.Settings.NameDividerTooltip,
			default = defaults.NameDivider,
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
		---@param value number
		---@return string
		local function FloatToHex(value)
			return string.format("%02X", math.floor(value * 255 + 0.5))
		end

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
			for label, id in pairs(Private.Enum.GlowType) do
				local function IsEnabled()
					return tableRef.GlowType == id
				end

				local function SetProxy()
					Set(LibEditMode:GetActiveLayoutName(), id)
				end

				local translated = L.Settings.GlowTypeLabels[id]

				rootDescription:CreateRadio(translated, IsEnabled, SetProxy)
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
		local kindTableRef = isSelf and TargetedSpellsSaved.Settings.Self or TargetedSpellsSaved.Settings.Party

		local function Generator(owner, rootDescription, data)
			for label, id in pairs(Private.Enum.ContentType) do
				if
					Private.Settings.IsContentTypeAvailableForKind(
						isSelf and Private.Enum.FrameKind.Self or Private.Enum.FrameKind.Party,
						id
					)
				then
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
						for role, loadCondition in pairs(kindTableRef.LoadConditionContentType) do
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

	if key == Private.Settings.Keys.Self.LoadConditionRole or key == Private.Settings.Keys.Party.LoadConditionRole then
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

	if key == Private.Settings.Keys.Party.Grow then
		---@param layoutName string
		---@param value number
		local function Set(layoutName, value)
			if TargetedSpellsSaved.Settings.Party.Grow ~= value then
				TargetedSpellsSaved.Settings.Party.Grow = value
				Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
			end
		end

		local function Generator(owner, rootDescription, data)
			for label, id in pairs(Private.Enum.Grow) do
				local function IsEnabled()
					return TargetedSpellsSaved.Settings.Party.Grow == id
				end

				local function SetProxy()
					Set(LibEditMode:GetActiveLayoutName(), id)
				end

				local translated = L.Settings.FrameGrowLabels[id]

				rootDescription:CreateRadio(translated, IsEnabled, SetProxy)
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

	if key == Private.Settings.Keys.Self.Grow then
		---@param layoutName string
		---@param value number
		local function Set(layoutName, value)
			if TargetedSpellsSaved.Settings.Self.Grow ~= value then
				TargetedSpellsSaved.Settings.Self.Grow = value
				Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
			end
		end

		local function Generator(owner, rootDescription, data)
			for label, id in pairs(Private.Enum.Grow) do
				local function IsEnabled()
					return TargetedSpellsSaved.Settings.Self.Grow == id
				end

				local function SetProxy()
					Set(LibEditMode:GetActiveLayoutName(), id)
				end

				local translated = L.Settings.FrameGrowLabels[id]

				rootDescription:CreateRadio(translated, IsEnabled, SetProxy)
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
	-- Implement in your derived mixin.
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
	local duration = C_DurationUtil.CreateDuration()
	duration:SetTimeFromStart(GetTime(), castTime)
	frame:SetDuration(duration)
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

	PixelUtil.SetPoint(self.editModeFrame, "CENTER", UIParent, "CENTER", 0, 0)
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
		PixelUtil.SetSize(self.editModeFrame, totalWidth, height)
	else
		local totalHeight = (self.maxFrames * height) + (self.maxFrames - 1) * gap
		PixelUtil.SetSize(self.editModeFrame, width, totalHeight)
	end
end

function SelfEditModeMixin:AcquireFrame()
	local frame = Private.Utils.Pools.Self:Acquire()

	frame:PostCreate("preview")

	return frame
end

function SelfEditModeMixin:ReleaseAllFrames()
	for index, frame in ipairs(self.frames) do
		Private.Utils.Pools.Self:Release(frame)
	end

	table.wipe(self.frames)
end

function SelfEditModeMixin:AppendSettings()
	LibEditMode:AddFrame(
		self.editModeFrame,
		GenerateClosure(self.OnEditModePositionChanged, self),
		Private.Settings.GetDefaultSelfEditModeFramePosition(),
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
	LibEditMode:AddFrameSettingsButtons(self.editModeFrame, self:CreateImportExportButtons())
end

function SelfEditModeMixin:RestoreEditModePosition()
	self.editModeFrame:ClearAllPoints()
	PixelUtil.SetPoint(
		self.editModeFrame,
		"CENTER",
		UIParent,
		TargetedSpellsSaved.Settings.Self.Position.point,
		TargetedSpellsSaved.Settings.Self.Position.x,
		TargetedSpellsSaved.Settings.Self.Position.y
	)
end

function SelfEditModeMixin:OnEditModePositionChanged(frame, layoutName, point, x, y)
	TargetedSpellsSaved.Settings.Self.Position.point = point
	TargetedSpellsSaved.Settings.Self.Position.x = x
	TargetedSpellsSaved.Settings.Self.Position.y = y

	Private.EventRegistry:TriggerEvent(Private.Enum.Events.EDIT_MODE_SELF_POSITION_CHANGED, point, x, y)
end

function SelfEditModeMixin:RepositionPreviewFrames()
	if not self.demoPlaying then
		return
	end

	---@type TargetedSpellsIconMixin[]
	local activeFrames = {}

	for index = 1, self.maxFrames do
		local frame = self.frames[index]

		if frame == nil then
			frame = self:AcquireFrame()
			self.frames[index] = frame

			table.insert(
				self.demoTimers.tickers,
				C_Timer.NewTicker(5 + index, GenerateClosure(self.LoopFrame, self, frame, index))
			)

			self:LoopFrame(frame, index)
		end

		if frame:ShouldBeShown() then
			table.insert(activeFrames, frame)
		end
	end

	if #activeFrames == 0 then
		return
	end

	Private.Utils.SortFrames(activeFrames, TargetedSpellsSaved.Settings.Self.SortOrder)

	local layouting = Private.Utils.CollectLayoutingArguments(
		TargetedSpellsSaved.Settings.Self.Direction,
		TargetedSpellsSaved.Settings.Self.Grow,
		TargetedSpellsSaved.Settings.Self.Width,
		TargetedSpellsSaved.Settings.Self.Height,
		TargetedSpellsSaved.Settings.Self.Gap
	)

	local parentDimension = layouting.isHorizontal and self.editModeFrame:GetWidth() or self.editModeFrame:GetHeight()
	local offset = layouting.isGrowEnd and (parentDimension / 2 - TargetedSpellsSaved.Settings.Self.Gap)
		or (-parentDimension / 2)

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

function SelfEditModeMixin:StartDemo()
	if self.demoPlaying or not TargetedSpellsSaved.Settings.Self.Enabled or not self:IsPastLoadingScreen() then
		return
	end

	self.demoPlaying = true

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

	self:RestoreEditModePosition()
	self:ResizeEditModeFrame()
end

function PartyEditModeMixin:ResizeEditModeFrame()
	if TargetedSpellsSaved.Settings.Party.Direction == Private.Enum.Direction.Horizontal then
		local totalWidth = (self.maxFrames * TargetedSpellsSaved.Settings.Party.Width)
			+ (self.maxFrames - 1) * TargetedSpellsSaved.Settings.Party.Gap
		PixelUtil.SetSize(self.editModeFrame, totalWidth, TargetedSpellsSaved.Settings.Party.Height)
	else
		local totalHeight = (self.maxFrames * TargetedSpellsSaved.Settings.Party.Height)
			+ (self.maxFrames - 1) * TargetedSpellsSaved.Settings.Party.Gap
		PixelUtil.SetSize(self.editModeFrame, TargetedSpellsSaved.Settings.Party.Width, totalHeight)
	end
end

function PartyEditModeMixin:RestoreEditModePosition()
	self.editModeFrame:ClearAllPoints()
	PixelUtil.SetPoint(
		self.editModeFrame,
		"CENTER",
		UIParent,
		TargetedSpellsSaved.Settings.Party.Position.point,
		TargetedSpellsSaved.Settings.Party.Position.x,
		TargetedSpellsSaved.Settings.Party.Position.y
	)
end

function PartyEditModeMixin:AppendSettings()
	LibEditMode:AddFrame(
		self.editModeFrame,
		GenerateClosure(self.OnEditModePositionChanged, self),
		Private.Settings.GetDefaultBarsEditModeFramePosition(),
		Private.L.EditMode.TargetedSpellsPartyLabel
	)

	LibEditMode:RegisterCallback("layout", GenerateClosure(self.RestoreEditModePosition, self))

	local settingsOrder = Private.Settings.GetSettingsDisplayOrder(Private.Enum.FrameKind.Party)
	local settings = {}
	local defaults = Private.Settings.GetPartyDefaultSettings()

	for i, key in ipairs(settingsOrder) do
		table.insert(settings, self:CreateSetting(key, defaults))
	end

	LibEditMode:AddFrameSettings(self.editModeFrame, settings)
	LibEditMode:AddFrameSettingsButtons(self.editModeFrame, self:CreateImportExportButtons())
end

function PartyEditModeMixin:OnEditModePositionChanged(frame, layoutName, point, x, y)
	TargetedSpellsSaved.Settings.Party.Position.point = point
	TargetedSpellsSaved.Settings.Party.Position.x = x
	TargetedSpellsSaved.Settings.Party.Position.y = y

	Private.EventRegistry:TriggerEvent(Private.Enum.Events.EDIT_MODE_PARTY_POSITION_CHANGED, point, x, y)
end

function PartyEditModeMixin:AcquireFrame()
	local frame = Private.Utils.Pools.Bar:Acquire()

	frame:PostCreate("preview")

	return frame
end

function PartyEditModeMixin:LoopFrame(frame, index)
	frame:SetSpellId()
	frame:SetStartTime()

	local castTime = 4 + index / 2
	local duration = C_DurationUtil.CreateDuration()
	duration:SetTimeFromStart(GetTime(), castTime)
	frame:SetDuration(duration)
	frame:Show()

	frame.CustomElementsFrame.TargetMarker:Hide()

	if
		TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.ShowTargetMarker]
		and Private.Utils.RollDice()
	then
		frame.CustomElementsFrame.TargetMarker:SetTexture(
			string.format("Interface\\TARGETINGFRAME\\UI-RaidTargetingIcon_%d.blp", math.random(1, 8))
		)
		frame.CustomElementsFrame.TargetMarker:Show()
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

function PartyEditModeMixin:OnLayoutSettingChanged(key, value)
	if
		key == Private.Settings.Keys.Party.Gap
		or key == Private.Settings.Keys.Party.Direction
		or key == Private.Settings.Keys.Party.Width
		or key == Private.Settings.Keys.Party.Height
		or key == Private.Settings.Keys.Party.SortOrder
		or key == Private.Settings.Keys.Party.Grow
	then
		if
			key == Private.Settings.Keys.Party.Width
			or key == Private.Settings.Keys.Party.Height
			or key == Private.Settings.Keys.Party.Gap
			or key == Private.Settings.Keys.Party.Direction
		then
			self:ResizeEditModeFrame()
		end

		self:RepositionPreviewFrames()
	end
end

function PartyEditModeMixin:RepositionPreviewFrames()
	if not self.demoPlaying then
		return
	end

	---@type TargetedSpellsBarMixin[]
	local activeFrames = {}

	for index = 1, self.maxFrames do
		local frame = self.frames[index]

		if frame == nil then
			frame = self:AcquireFrame()
			self.frames[index] = frame

			table.insert(
				self.demoTimers.tickers,
				C_Timer.NewTicker(5 + index, GenerateClosure(self.LoopFrame, self, frame, index))
			)

			self:LoopFrame(frame, index)
		end

		if frame:ShouldBeShown() then
			table.insert(activeFrames, frame)
		end
	end

	if #activeFrames == 0 then
		return
	end

	Private.Utils.SortFrames(activeFrames, TargetedSpellsSaved.Settings.Party.SortOrder)

	local layouting = Private.Utils.CollectLayoutingArguments(
		TargetedSpellsSaved.Settings.Party.Direction,
		TargetedSpellsSaved.Settings.Party.Grow,
		TargetedSpellsSaved.Settings.Party.Width,
		TargetedSpellsSaved.Settings.Party.Height,
		TargetedSpellsSaved.Settings.Party.Gap
	)

	local parentDimension = layouting.isHorizontal and self.editModeFrame:GetWidth() or self.editModeFrame:GetHeight()
	local offset = layouting.isGrowEnd and (parentDimension / 2 - TargetedSpellsSaved.Settings.Party.Gap)
		or (-parentDimension / 2)

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

function PartyEditModeMixin:StartDemo()
	if self.demoPlaying or not TargetedSpellsSaved.Settings.Party.Enabled or not self:IsPastLoadingScreen() then
		return
	end

	self.demoPlaying = true

	self:RepositionPreviewFrames()
end

function PartyEditModeMixin:ReleaseAllFrames()
	for index = 1, self.maxFrames do
		local frame = self.frames[index]

		if frame ~= nil then
			Private.Utils.Pools.Bar:Release(frame)
			self.frames[index] = nil
		end
	end
end

table.insert(Private.LoginFnQueue, GenerateClosure(PartyEditModeMixin.Init, PartyEditModeMixin))
