---@type string, TargetedSpells
local addonName, Private = ...
local LibEditMode = LibStub("LibEditMode")
local LibSharedMedia = LibStub("LibSharedMedia-3.0")

---@class TargetedSpellsBarMixin : TargetedSpellsMixin
TargetedSpellsBarMixin = CreateFromMixins(TargetedSpellsMixin)

function TargetedSpellsBarMixin:GetGlowTarget()
	local settings = TargetedSpellsSaved.Settings.Party
	local flags = settings.FeatureFlags
	local inlineDuration = flags[Private.Enum.FeatureFlag.InlineDuration]

	local width = settings.Width
		- (flags[Private.Enum.FeatureFlag.ShowIcon] and settings.Height or 0)
		- (flags[Private.Enum.FeatureFlag.ShowTargetMarker] and settings.Height or 0)
		- (flags[Private.Enum.FeatureFlag.ShowDuration] and not inlineDuration and settings.FontSize * 2 or 0)

	return self.ProgressBar, width, settings.Height
end

function TargetedSpellsBarMixin:OnLoad()
	TargetedSpellsMixin.OnLoad(self)
	self.Bar:SetStatusBarTexture("")
	self.DurationCooldown:SetCountdownFormatter(Private.Utils.Formatter)
	self.DurationCooldown:SetHideCountdownNumbers(
		not TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.ShowDuration]
	)
	PixelUtil.SetSize(self, TargetedSpellsSaved.Settings.Party.Width, TargetedSpellsSaved.Settings.Party.Height)
	self:SetFont()
	self:SetForegroundBarTexture()
	self:SetBackgroundBarTexture()
	self:SetBackgroundBarColor()
	self:SetProgressBarColor()
end

---@type colorRGB?
local playerClassColor = nil

local function GetPlayerClassColor()
	if playerClassColor == nil then
		playerClassColor = C_ClassColor.GetClassColor(select(2, UnitClass("player")))
	end

	return playerClassColor
end

---@type string?
local playerName = nil

---@return string
local function GetPlayerName()
	if playerName == nil then
		playerName = UnitName("player")
	end

	return playerName
end

local function GetDurationWidth()
	return TargetedSpellsSaved.Settings.Party.FontSize * 2
end

local function GetProgressBarWidth()
	local tableRef = TargetedSpellsSaved.Settings.Party

	return tableRef.Width
		- (tableRef.FeatureFlags[Private.Enum.FeatureFlag.ShowIcon] and tableRef.Height or 0)
		- (tableRef.FeatureFlags[Private.Enum.FeatureFlag.ShowTargetMarker] and tableRef.Height or 0)
		- (
			tableRef.FeatureFlags[Private.Enum.FeatureFlag.ShowDuration]
				and not tableRef.FeatureFlags[Private.Enum.FeatureFlag.InlineDuration]
				and GetDurationWidth()
			or 0
		)
end

function TargetedSpellsBarMixin:OnSizeChanged()
	local tableRef = TargetedSpellsSaved.Settings.Party

	local showIcon = tableRef.FeatureFlags[Private.Enum.FeatureFlag.ShowIcon]
	local showTargetMarker = tableRef.FeatureFlags[Private.Enum.FeatureFlag.ShowTargetMarker]
	local mirrored = tableRef.FeatureFlags[Private.Enum.FeatureFlag.MirrorLayout]
	local showDuration = tableRef.FeatureFlags[Private.Enum.FeatureFlag.ShowDuration]
	local inlineDuration = tableRef.FeatureFlags[Private.Enum.FeatureFlag.InlineDuration]
	local showSpellName = tableRef.FeatureFlags[Private.Enum.FeatureFlag.ShowSpellName]
	local showTargetName = tableRef.FeatureFlags[Private.Enum.FeatureFlag.ShowTargetName]

	self.CustomElementsFrame.TargetMarker:SetSize(tableRef.Height, tableRef.Height)
	self.Icon:SetWidth(tableRef.Height)
	self.Icon:SetShown(showIcon)

	self.CustomElementsFrame.TargetMarker:ClearAllPoints()
	self.Icon:ClearAllPoints()
	self.ProgressBar:ClearAllPoints()
	self.DurationCooldown:ClearAllPoints()
	self.ProgressBar.SpellName:ClearAllPoints()
	self.ProgressBar.TargetName:ClearAllPoints()

	local durationWidth = GetDurationWidth()
	---@type Texture?
	local slotFrame = nil

	local progressBarWidth = GetProgressBarWidth()
	local textWidth = (showDuration and inlineDuration) and (progressBarWidth - durationWidth) or progressBarWidth

	if showSpellName and showTargetName then
		self.ProgressBar.SpellName:SetWidth(textWidth * 0.5)
		self.ProgressBar.TargetName:SetWidth(textWidth * 0.5)
	elseif showSpellName then
		self.ProgressBar.SpellName:SetWidth(textWidth)
	elseif showTargetName then
		self.ProgressBar.TargetName:SetWidth(textWidth)
	end

	if
		TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.GlowImportant] and self:ShouldBeShown()
	then
		self:HideGlow()
		self:ShowGlow(self:IsSpellImportant(LibEditMode:IsInEditMode() and Private.Utils.RollDice()))
	end

	if mirrored then
		if showTargetMarker and showIcon then
			PixelUtil.SetPoint(self.CustomElementsFrame.TargetMarker, "TOPRIGHT", self, "TOPRIGHT", 0, 0)
			PixelUtil.SetPoint(self.CustomElementsFrame.TargetMarker, "BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0)
			PixelUtil.SetPoint(self.Icon, "TOPRIGHT", self.CustomElementsFrame.TargetMarker, "TOPLEFT", 0, 0)
			PixelUtil.SetPoint(self.Icon, "BOTTOMRIGHT", self.CustomElementsFrame.TargetMarker, "BOTTOMLEFT", 0, 0)

			slotFrame = self.Icon
		elseif showTargetMarker then
			PixelUtil.SetPoint(self.CustomElementsFrame.TargetMarker, "TOPRIGHT", self, "TOPRIGHT", 0, 0)
			PixelUtil.SetPoint(self.CustomElementsFrame.TargetMarker, "BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0)

			slotFrame = self.CustomElementsFrame.TargetMarker
		elseif showIcon then
			PixelUtil.SetPoint(self.Icon, "TOPRIGHT", self, "TOPRIGHT", 0, 0)
			PixelUtil.SetPoint(self.Icon, "BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0)

			slotFrame = self.Icon
		end

		if showDuration then
			self.DurationCooldown:SetWidth(durationWidth)

			if inlineDuration then
				PixelUtil.SetPoint(self.ProgressBar, "TOPLEFT", self, "TOPLEFT", 0, 0)
				PixelUtil.SetPoint(self.DurationCooldown, "TOPLEFT", self.ProgressBar, "TOPLEFT", 4, 0)
				PixelUtil.SetPoint(self.DurationCooldown, "BOTTOMLEFT", self.ProgressBar, "BOTTOMLEFT", 4, 0)
			else
				PixelUtil.SetPoint(self.DurationCooldown, "TOPLEFT", self, "TOPLEFT", 0, 0)
				PixelUtil.SetPoint(self.DurationCooldown, "BOTTOMLEFT", self, "BOTTOMLEFT", 0, 0)
				PixelUtil.SetPoint(self.ProgressBar, "TOPLEFT", self.DurationCooldown, "TOPRIGHT", 0, 0)
			end
		else
			PixelUtil.SetPoint(self.ProgressBar, "TOPLEFT", self, "TOPLEFT", 0, 0)
		end

		if showSpellName then
			PixelUtil.SetPoint(self.ProgressBar.SpellName, "RIGHT", self.ProgressBar, "RIGHT", -4, 0)
			self.ProgressBar.SpellName:SetJustifyH("RIGHT")
		end

		if showTargetName then
			if not showSpellName then
				PixelUtil.SetPoint(self.ProgressBar.TargetName, "RIGHT", self.ProgressBar, "RIGHT", -4, 0)
				self.ProgressBar.TargetName:SetJustifyH("RIGHT")
			else
				if showDuration and inlineDuration then
					PixelUtil.SetPoint(self.ProgressBar.TargetName, "LEFT", self.DurationCooldown, "RIGHT", 0, 0)
				else
					PixelUtil.SetPoint(self.ProgressBar.TargetName, "LEFT", self.ProgressBar, "LEFT", 4, 0)
				end
				self.ProgressBar.TargetName:SetJustifyH("LEFT")
			end
		end

		if slotFrame then
			PixelUtil.SetPoint(self.ProgressBar, "BOTTOMRIGHT", slotFrame, "BOTTOMLEFT", 0, 0)
		else
			PixelUtil.SetPoint(self.ProgressBar, "BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0)
		end
	else
		if showTargetMarker and showIcon then
			PixelUtil.SetPoint(self.CustomElementsFrame.TargetMarker, "TOPLEFT", self, "TOPLEFT", 0, 0)
			PixelUtil.SetPoint(self.CustomElementsFrame.TargetMarker, "BOTTOMLEFT", self, "BOTTOMLEFT", 0, 0)
			PixelUtil.SetPoint(self.Icon, "TOPLEFT", self.CustomElementsFrame.TargetMarker, "TOPRIGHT", 0, 0)
			PixelUtil.SetPoint(self.Icon, "BOTTOMLEFT", self.CustomElementsFrame.TargetMarker, "BOTTOMRIGHT", 0, 0)

			slotFrame = self.Icon
		elseif showTargetMarker then
			PixelUtil.SetPoint(self.CustomElementsFrame.TargetMarker, "TOPLEFT", self, "TOPLEFT", 0, 0)
			PixelUtil.SetPoint(self.CustomElementsFrame.TargetMarker, "BOTTOMLEFT", self, "BOTTOMLEFT", 0, 0)

			slotFrame = self.CustomElementsFrame.TargetMarker
		elseif showIcon then
			PixelUtil.SetPoint(self.Icon, "TOPLEFT", self, "TOPLEFT", 0, 0)
			PixelUtil.SetPoint(self.Icon, "BOTTOMLEFT", self, "BOTTOMLEFT", 0, 0)

			slotFrame = self.Icon
		end

		if slotFrame then
			PixelUtil.SetPoint(self.ProgressBar, "TOPLEFT", slotFrame, "TOPRIGHT", 0, 0)
		else
			PixelUtil.SetPoint(self.ProgressBar, "TOPLEFT", self, "TOPLEFT", 0, 0)
		end

		if showDuration then
			self.DurationCooldown:SetWidth(durationWidth)

			if inlineDuration then
				PixelUtil.SetPoint(self.ProgressBar, "BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0)
				PixelUtil.SetPoint(self.DurationCooldown, "TOPRIGHT", self.ProgressBar, "TOPRIGHT", -4, 0)
				PixelUtil.SetPoint(self.DurationCooldown, "BOTTOMRIGHT", self.ProgressBar, "BOTTOMRIGHT", -4, 0)
			else
				PixelUtil.SetPoint(self.DurationCooldown, "TOPRIGHT", self, "TOPRIGHT", 0, 0)
				PixelUtil.SetPoint(self.DurationCooldown, "BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0)
				PixelUtil.SetPoint(self.ProgressBar, "BOTTOMRIGHT", self.DurationCooldown, "BOTTOMLEFT", 0, 0)
			end
		else
			PixelUtil.SetPoint(self.ProgressBar, "BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0)
		end

		if showSpellName then
			PixelUtil.SetPoint(self.ProgressBar.SpellName, "LEFT", self.ProgressBar, "LEFT", 4, 0)
			self.ProgressBar.SpellName:SetJustifyH("LEFT")
		end

		if showTargetName then
			if not showSpellName then
				PixelUtil.SetPoint(self.ProgressBar.TargetName, "LEFT", self.ProgressBar, "LEFT", 4, 0)
				self.ProgressBar.TargetName:SetJustifyH("LEFT")
			else
				if showDuration and inlineDuration then
					PixelUtil.SetPoint(self.ProgressBar.TargetName, "RIGHT", self.DurationCooldown, "LEFT", 0, 0)
				else
					PixelUtil.SetPoint(self.ProgressBar.TargetName, "RIGHT", self.ProgressBar, "RIGHT", -4, 0)
				end
				self.ProgressBar.TargetName:SetJustifyH("RIGHT")
			end
		end
	end
end

function TargetedSpellsBarMixin:OnSettingChanged(key, flagIdOrValue, newBool)
	if key == Private.Settings.Keys.Party.Width then
		PixelUtil.SetSize(self, flagIdOrValue, TargetedSpellsSaved.Settings.Party.Height)
	elseif key == Private.Settings.Keys.Party.Height then
		PixelUtil.SetSize(self, TargetedSpellsSaved.Settings.Party.Width, flagIdOrValue)
	elseif key == Private.Settings.Keys.Party.FeatureFlags then
		if
			flagIdOrValue == Private.Enum.FeatureFlag.ShowIcon
			or flagIdOrValue == Private.Enum.FeatureFlag.ShowTargetMarker
			or flagIdOrValue == Private.Enum.FeatureFlag.ShowSpellName
			or flagIdOrValue == Private.Enum.FeatureFlag.ShowTargetName
			or flagIdOrValue == Private.Enum.FeatureFlag.ShowDuration
			or flagIdOrValue == Private.Enum.FeatureFlag.MirrorLayout
			or flagIdOrValue == Private.Enum.FeatureFlag.InlineDuration
		then
			if flagIdOrValue == Private.Enum.FeatureFlag.ShowTargetMarker then
				self:SetTargetMarker()
				self:OnSizeChanged()
			elseif flagIdOrValue == Private.Enum.FeatureFlag.ShowIcon then
				self.Icon:SetShown(newBool)
				self:OnSizeChanged()
			elseif flagIdOrValue == Private.Enum.FeatureFlag.ShowTargetName then
				self.ProgressBar.TargetName:SetShown(newBool)
				self:OnSizeChanged()
			elseif flagIdOrValue == Private.Enum.FeatureFlag.ShowSpellName then
				self:SetSpellId(self:GetSpellId())
				self:OnSizeChanged()
			elseif flagIdOrValue == Private.Enum.FeatureFlag.ShowDuration then
				self:SetShowDuration(newBool)
				self:OnSizeChanged()
			elseif flagIdOrValue == Private.Enum.FeatureFlag.MirrorLayout then
				self:OnSizeChanged()
				self.ProgressBar.SpellName:SetText("")
				self.ProgressBar.TargetName:SetText("")
				self:SetSpellId(self:GetSpellId())
				self.ProgressBar.TargetName:SetText(GetPlayerName())
			elseif flagIdOrValue == Private.Enum.FeatureFlag.InlineDuration then
				self:OnSizeChanged()
			end
		end
	elseif
		key == Private.Settings.Keys.Party.FontSize
		or key == Private.Settings.Keys.Party.Font
		or key == Private.Settings.Keys.Party.FontFlags
	then
		self:SetFont()
		self:OnSizeChanged()
	elseif key == Private.Settings.Keys.Party.ForegroundBarTexture then
		self:SetForegroundBarTexture()
	elseif key == Private.Settings.Keys.Party.BackgroundBarTexture then
		self:SetBackgroundBarTexture()
	elseif key == Private.Settings.Keys.Party.GlowType then
		self:HideGlow()

		if TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.GlowImportant] then
			self:ShowGlow(self:IsSpellImportant(LibEditMode:IsInEditMode() and Private.Utils.RollDice()))
		end
	end
end

function TargetedSpellsBarMixin:SetForegroundBarTexture()
	self.ProgressBar:SetStatusBarTexture(
		LibSharedMedia:Fetch(
			LibSharedMedia.MediaType.STATUSBAR,
			TargetedSpellsSaved.Settings.Party.ForegroundBarTexture
		)
	)
end

function TargetedSpellsBarMixin:SetBackgroundBarTexture()
	self.ProgressBar.Background:SetTexture(
		LibSharedMedia:Fetch(
			LibSharedMedia.MediaType.BACKGROUND,
			TargetedSpellsSaved.Settings.Party.BackgroundBarTexture
		)
	)
end

function TargetedSpellsBarMixin:SetProgressBarColor()
	local color = CreateColorFromHexString(TargetedSpellsSaved.Settings.Party.ProgressBarColor)

	self.ProgressBar:SetStatusBarColor(color.r, color.g, color.b, color.a)
end

function TargetedSpellsBarMixin:SetPreviewBarColor()
	if TargetedSpellsSaved.Settings.Party.UseInterruptabilityColors then
		local hex = Private.Utils.RollDice() and TargetedSpellsSaved.Settings.Party.InterruptibleColor
			or TargetedSpellsSaved.Settings.Party.UninterruptibleColor

		local color = CreateColorFromHexString(hex)

		self.ProgressBar:SetStatusBarColor(color.r, color.g, color.b, color.a)
	elseif TargetedSpellsSaved.Settings.Party.UseTargetClassColor then
		local color = GetPlayerClassColor()

		if color then
			self.ProgressBar:SetStatusBarColor(color.r, color.g, color.b, 0.75)
		else
			self:SetProgressBarColor()
		end
	else
		self:SetProgressBarColor()
	end
end

function TargetedSpellsBarMixin:AdjustInterruptibleColor(isInterruptible)
	local hex = isInterruptible and TargetedSpellsSaved.Settings.Party.InterruptibleColor
		or TargetedSpellsSaved.Settings.Party.UninterruptibleColor
	local color = CreateColorFromHexString(hex)

	self.ProgressBar:SetStatusBarColor(color.r, color.g, color.b, color.a)
end

function TargetedSpellsBarMixin:SetBackgroundBarColor()
	local color = CreateColorFromHexString(TargetedSpellsSaved.Settings.Party.BackgroundBarColor)

	self.ProgressBar.Background:SetVertexColor(color.r, color.g, color.b, color.a)
end

function TargetedSpellsBarMixin:SetShowDuration(showDuration)
	self.DurationCooldown:SetHideCountdownNumbers(not showDuration)
end

function TargetedSpellsBarMixin:Reset()
	TargetedSpellsMixin.Reset(self)
	self:SetAlpha(1)
	self.Bar:SetValue(1)
	self.unit = nil
	self:SetProgressBarColor()
	self.ProgressBar.InterruptSource:SetText("")
	self.ProgressBar.InterruptSource:Hide()
	self.ProgressBar.InterruptSource:SetTextColor(1, 1, 1)
	self.CustomElementsFrame.TargetMarker:Hide()
	self.ProgressBar.TargetName:Hide()
	self.DurationCooldown:Clear()
	self.DurationCooldown:SetScript("OnCooldownDone", nil)
	-- DurationCooldown:Clear() re-inherits from SetCountdownFont, overwriting any previously applied font
	self:SetFont()
end

function TargetedSpellsBarMixin:SetTargetMarker(raidTargetIndex)
	if not TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.ShowTargetMarker] then
		self.CustomElementsFrame.TargetMarker:Hide()
		return
	end

	local index = raidTargetIndex or (self.unit and GetRaidTargetIndex(self.unit))

	if index ~= nil then
		SetRaidTargetIconTexture(self.CustomElementsFrame.TargetMarker, index)

		self.CustomElementsFrame.TargetMarker:Show()
	else
		self.CustomElementsFrame.TargetMarker:Hide()
	end
end

do
	local whiteDefaultColor = CreateColor(1, 1, 1, 1)

	---@param ProgressBar TargetedSpellsBarProgressBar
	---@param targetName string?
	local function UpdateTargetName(ProgressBar, targetName)
		local showSpellName = TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.ShowSpellName]
		local barWidth = GetProgressBarWidth()
		local textWidth = (
			TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.ShowDuration]
			and TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.InlineDuration]
		)
				and (barWidth - GetDurationWidth())
			or barWidth

		if
			targetName == nil
			or not TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.ShowTargetName]
		then
			ProgressBar.TargetName:Hide()
			ProgressBar.SpellName:SetWidth(textWidth)
		else
			ProgressBar.TargetName:SetText(targetName)
			ProgressBar.TargetName:Show()

			if showSpellName then
				ProgressBar.SpellName:SetWidth(textWidth * 0.5)
				ProgressBar.TargetName:SetWidth(textWidth * 0.5)
			else
				ProgressBar.TargetName:SetWidth(textWidth)
			end
		end
	end

	function TargetedSpellsBarMixin:PostCreate(info, OnCooldownDoneCallback)
		self.unit = info and info.unit or nil
		self:SetTargetMarker()

		if info == nil then
			UpdateTargetName(self.ProgressBar, GetPlayerName())
			self:SetPreviewBarColor()

			return
		end

		self:SetStartTime(info.startTime)
		self:SetSpellId(info.spellId)
		self:SetId(info.id)
		local durationAlpha = self:SetDuration(info.duration)
		local targetName = UnitSpellTargetName(info.unit)

		if
			TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.HideUntargetedSpells]
			and targetName == nil
		then
			self:SetAlpha(0)

			return
		end

		local fallbackAlpha = durationAlpha

		if TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.OnlyImportant] then
			fallbackAlpha = C_CurveUtil.EvaluateColorValueFromBoolean(self:IsSpellImportant(), 0, durationAlpha)
		end

		if TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.SelfOnly] then
			-- allow untargeted spells to still get shown when showing player-targeting spells only
			if targetName ~= nil then
				local bool = PlayerIsSpellTarget(info.unit, "player")

				self:SetAlphaFromBoolean(bool, fallbackAlpha, 0)
				self.Bar:SetValue(self:GetAlpha())
			end
		elseif
			targetName ~= nil
			and TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.HideTargetedSpells]
		then
			self:SetAlpha(0)

			return
		end

		if TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.GlowImportant] then
			self:ShowGlow(self:IsSpellImportant())
		end

		self.ProgressBar:SetTimerDuration(info.duration, Enum.StatusBarInterpolation.None, info.isChannel and 1 or 0)
		UpdateTargetName(self.ProgressBar, targetName)

		---@type colorRGB?
		local color = nil
		local isClassColor = false

		if TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.ShowTargetClassColor] then
			if TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.SelfOnly] then
				color = GetPlayerClassColor()
			else
				local targetClass = UnitSpellTargetClass(info.unit)

				if targetClass ~= nil then
					color = C_ClassColor.GetClassColor(targetClass)
					isClassColor = color ~= nil
				end
			end
		end

		if TargetedSpellsSaved.Settings.Party.UseInterruptabilityColors then
			local uninterruptible = select(8, UnitCastingInfo(info.unit))

			if uninterruptible == nil then
				uninterruptible = select(7, UnitChannelInfo(info.unit))
			end

			if uninterruptible ~= nil then
				self.ProgressBar:GetStatusBarTexture():SetVertexColorFromBoolean(
					uninterruptible,
					CreateColorFromHexString(TargetedSpellsSaved.Settings.Party.UninterruptibleColor),
					CreateColorFromHexString(TargetedSpellsSaved.Settings.Party.InterruptibleColor)
				)
			end
		end

		if color == nil then
			if TargetedSpellsSaved.Settings.Party.UseTargetClassColor then
				local bg = CreateColorFromHexString(TargetedSpellsSaved.Settings.Party.BackgroundBarColor)
				color = CreateColor(bg.r + (1 - bg.r) * 0.6, bg.g + (1 - bg.g) * 0.6, bg.b + (1 - bg.b) * 0.6, 0.5)
			else
				color = whiteDefaultColor
			end
		end

		if TargetedSpellsSaved.Settings.Party.UseTargetClassColor then
			self.ProgressBar.TargetName:SetTextColor(
				whiteDefaultColor.r,
				whiteDefaultColor.g,
				whiteDefaultColor.b,
				whiteDefaultColor.a
			)
			self.ProgressBar:SetStatusBarColor(color.r, color.g, color.b, isClassColor and 0.75 or color.a)
		else
			self.ProgressBar.TargetName:SetTextColor(color.r, color.g, color.b, color.a)
		end

		if OnCooldownDoneCallback ~= nil then
			self.DurationCooldown:SetScript("OnCooldownDone", GenerateClosure(OnCooldownDoneCallback, info))
		end
	end
end

function TargetedSpellsBarMixin:SetInterrupted(name, color)
	TargetedSpellsMixin.SetInterrupted(self, name, color)
	local now = GetTime()

	self.DurationCooldown:Clear()
	self.ProgressBar:GetTimerDuration():SetTimeSpan(now - 1, now)
	self.ProgressBar.SpellName:Hide()
	self.ProgressBar.TargetName:Hide()

	if name == nil then
		return
	end

	if TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.RenderInterruptSourceName] then
		self.ProgressBar.InterruptSource:SetText(name)

		if color ~= nil then
			self.ProgressBar.InterruptSource:SetTextColor(color.r, color.g, color.b)
		end

		self.ProgressBar.InterruptSource:Show()
	else
		self.ProgressBar.InterruptSource:Hide()
	end
end

function TargetedSpellsBarMixin:SetSpellId(spellId)
	if TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.ShowSpellName] then
		self.ProgressBar.SpellName:SetText(spellId == nil and addonName or C_Spell.GetSpellName(spellId))
		self.ProgressBar.SpellName:Show()
	else
		self.ProgressBar.SpellName:Hide()
	end

	TargetedSpellsMixin.SetSpellId(self, spellId)
end

function TargetedSpellsBarMixin:SetDuration(duration)
	self:SetShowDuration(TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.ShowDuration])
	self.DurationCooldown:SetCooldownFromDurationObject(duration)
	self.ProgressBar:SetTimerDuration(duration)

	return TargetedSpellsMixin.SetDuration(self, duration)
end

function TargetedSpellsBarMixin:SetFont()
	local hasShadow = TargetedSpellsSaved.Settings.Party.FontFlags[Private.Enum.FontFlags.SHADOW]

	for _, fontString in ipairs({
		self.ProgressBar.SpellName,
		self.ProgressBar.TargetName,
		self.ProgressBar.InterruptSource,
		self.DurationCooldown:GetCountdownFontString(),
	}) do
		Private.Utils.SafelySetFont(
			Private.Enum.FrameKind.Party,
			fontString,
			TargetedSpellsSaved.Settings.Party.Font,
			TargetedSpellsSaved.Settings.Party.FontSize,
			TargetedSpellsSaved.Settings.Party.FontFlags[Private.Enum.FontFlags.OUTLINE] and "OUTLINE" or ""
		)

		fontString:SetShadowOffset(hasShadow and 1 or 0, hasShadow and -1 or 0)

		if hasShadow then
			fontString:SetShadowColor(0, 0, 0, 1)
		end
	end
end
