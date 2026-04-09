---@type string, TargetedSpells
local addonName, Private = ...
local LibEditMode = LibStub("LibEditMode")
local LibSharedMedia = LibStub("LibSharedMedia-3.0")

---@class TargetedSpellsBarMixin : TargetedSpellsMixin
TargetedSpellsBarMixin = CreateFromMixins(TargetedSpellsMixin)

function TargetedSpellsBarMixin:GetGlowTarget()
	local settings = TargetedSpellsSaved.Settings.Party
	local flags = settings.FeatureFlags

	local width = settings.Width
		- (flags[Private.Enum.FeatureFlag.ShowIcon] and settings.Height or 0)
		- (flags[Private.Enum.FeatureFlag.ShowTargetMarker] and settings.Height or 0)
		- (flags[Private.Enum.FeatureFlag.ShowDuration] and settings.FontSize * 2 or 0)

	return self.ProgressBar, width, settings.Height
end

function TargetedSpellsBarMixin:OnLoad()
	TargetedSpellsMixin.OnLoad(self)
	self.Bar:SetStatusBarTexture("")
	PixelUtil.SetSize(self, TargetedSpellsSaved.Settings.Party.Width, TargetedSpellsSaved.Settings.Party.Height)
	self:SetFont()
	self:SetShowDuration(TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.ShowDuration])
	self:SetForegroundBarTexture()
	self:SetBackgroundBarTexture()
	self:SetBackgroundBarColor()
	self:SetProgressBarColor()
end

function TargetedSpellsBarMixin:OnSizeChanged()
	local showIcon = TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.ShowIcon]
	local showTargetMarker = TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.ShowTargetMarker]
	local mirrored = TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.MirrorLayout]
	local showDuration = TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.ShowDuration]

	self.CustomElementsFrame.TargetMarker:SetSize(
		TargetedSpellsSaved.Settings.Party.Height,
		TargetedSpellsSaved.Settings.Party.Height
	)
	self.Icon:SetWidth(TargetedSpellsSaved.Settings.Party.Height)
	self.Icon:SetShown(showIcon)

	self.CustomElementsFrame.TargetMarker:ClearAllPoints()
	self.Icon:ClearAllPoints()
	self.ProgressBar:ClearAllPoints()
	self.Duration:ClearAllPoints()
	self.ProgressBar.SpellName:ClearAllPoints()
	self.ProgressBar.TargetName:ClearAllPoints()

	local slotFrame = nil

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
	end

	local durationWidth = TargetedSpellsSaved.Settings.Party.FontSize * 2

	if mirrored then
		self.Duration:SetJustifyH("LEFT")

		if showDuration then
			PixelUtil.SetPoint(self.Duration, "TOPLEFT", self, "TOPLEFT", 0, 0)
			PixelUtil.SetPoint(self.Duration, "BOTTOMLEFT", self, "BOTTOMLEFT", 0, 0)
			self.Duration:SetWidth(durationWidth)
			PixelUtil.SetPoint(self.ProgressBar, "TOPLEFT", self.Duration, "TOPRIGHT", 0, 0)
		else
			PixelUtil.SetPoint(self.ProgressBar, "TOPLEFT", self, "TOPLEFT", 0, 0)
		end

		if slotFrame then
			PixelUtil.SetPoint(self.ProgressBar, "BOTTOMRIGHT", slotFrame, "BOTTOMLEFT", 0, 0)
		else
			PixelUtil.SetPoint(self.ProgressBar, "BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0)
		end
	else
		self.Duration:SetJustifyH("RIGHT")

		if slotFrame then
			PixelUtil.SetPoint(self.ProgressBar, "TOPLEFT", slotFrame, "TOPRIGHT", 0, 0)
		else
			PixelUtil.SetPoint(self.ProgressBar, "TOPLEFT", self, "TOPLEFT", 0, 0)
		end

		if showDuration then
			PixelUtil.SetPoint(self.Duration, "TOPRIGHT", self, "TOPRIGHT", 0, 0)
			PixelUtil.SetPoint(self.Duration, "BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0)
			self.Duration:SetWidth(durationWidth)
			PixelUtil.SetPoint(self.ProgressBar, "BOTTOMRIGHT", self.Duration, "BOTTOMLEFT", 0, 0)
		else
			PixelUtil.SetPoint(self.ProgressBar, "BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0)
		end
	end

	local showSpellName = TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.ShowSpellName]
	local showTargetName = TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.ShowTargetName]

	local progressBarWidth = TargetedSpellsSaved.Settings.Party.Width
		- (showIcon and TargetedSpellsSaved.Settings.Party.Height or 0)
		- (showTargetMarker and TargetedSpellsSaved.Settings.Party.Height or 0)
		- (showDuration and durationWidth or 0)

	self.ProgressBar.SpellName:SetWidth(progressBarWidth * 0.5)
	self.ProgressBar.TargetName:SetWidth(progressBarWidth * 0.5)

	if mirrored then
		if showSpellName then
			PixelUtil.SetPoint(self.ProgressBar.SpellName, "RIGHT", self.ProgressBar, "RIGHT", -4, 0)
		end

		if showTargetName then
			PixelUtil.SetPoint(self.ProgressBar.TargetName, "LEFT", self.ProgressBar, "LEFT", 4, 0)
		end
	else
		if showSpellName then
			PixelUtil.SetPoint(self.ProgressBar.SpellName, "LEFT", self.ProgressBar, "LEFT", 4, 0)
		end

		if showTargetName then
			PixelUtil.SetPoint(self.ProgressBar.TargetName, "RIGHT", self.ProgressBar, "RIGHT", -4, 0)
		end
	end

	if
		TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.GlowImportant] and self:ShouldBeShown()
	then
		self:HideGlow()
		self:ShowGlow(self:IsSpellImportant(LibEditMode:IsInEditMode() and Private.Utils.RollDice()))
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
				self.ProgressBar.SpellName:SetShown(newBool)
				self:OnSizeChanged()
			elseif flagIdOrValue == Private.Enum.FeatureFlag.ShowDuration then
				self:SetShowDuration(newBool)
				self:OnSizeChanged()
			elseif flagIdOrValue == Private.Enum.FeatureFlag.MirrorLayout then
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
		local color = C_ClassColor.GetClassColor(select(2, UnitClass("player")))

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
	self.Duration:SetShown(showDuration)
end

function TargetedSpellsBarMixin:Reset()
	TargetedSpellsMixin.Reset(self)
	self:SetAlpha(1)
	self.unit = nil
	self.ProgressBar:SetReverseFill(false)
	self:SetProgressBarColor()
	self.ProgressBar.InterruptSource:SetText("")
	self.ProgressBar.InterruptSource:Hide()
	self.ProgressBar.InterruptSource:SetTextColor(1, 1, 1)
	self.CustomElementsFrame.TargetMarker:Hide()
	self.ProgressBar.TargetName:Hide()
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

	function TargetedSpellsBarMixin:PostCreate(castingUnit)
		self.unit = castingUnit
		self:SetTargetMarker()

		---@type string?
		local name = nil
		---@type colorRGB?
		local color = nil
		local isClassColor = false

		if castingUnit == "preview" then
			name = UnitName("player")

			if TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.ShowTargetClassColor] then
				color = C_ClassColor.GetClassColor(select(2, UnitClass("player")))
			end
		else
			name = UnitSpellTargetName(castingUnit)

			if
				name == nil
				and TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.HideUntargetedSpells]
			then
				self:SetAlpha(0)
				return
			elseif TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.ShowTargetClassColor] then
				local targetClass = UnitSpellTargetClass(castingUnit)

				if targetClass ~= nil then
					color = C_ClassColor.GetClassColor(targetClass)
					isClassColor = color ~= nil
				end
			end

			if TargetedSpellsSaved.Settings.Party.UseInterruptabilityColors then
				local uninterruptible = select(8, UnitCastingInfo(castingUnit))

				if uninterruptible == nil then
					uninterruptible = select(7, UnitChannelInfo(castingUnit))
				end

				if uninterruptible ~= nil then
					self.ProgressBar:GetStatusBarTexture():SetVertexColorFromBoolean(
						uninterruptible,
						CreateColorFromHexString(TargetedSpellsSaved.Settings.Party.UninterruptibleColor),
						CreateColorFromHexString(TargetedSpellsSaved.Settings.Party.InterruptibleColor)
					)
				end
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

		self.ProgressBar:SetReverseFill(UnitChannelDuration(castingUnit) ~= nil)
		self.ProgressBar.TargetName:SetText(name)
		self.ProgressBar.TargetName:SetShown(
			TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.ShowTargetName] and name ~= nil
		)

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

		if castingUnit == "preview" then
			self:SetPreviewBarColor()
		end
	end
end

function TargetedSpellsBarMixin:SetOnCooldownDone() end

function TargetedSpellsBarMixin:SetInterrupted(name, color)
	TargetedSpellsMixin.SetInterrupted(self, name, color)
	local now = GetTime()

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
	self.Duration:SetText("")
	self:SetShowDuration(TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.ShowDuration])
	self.ProgressBar:SetTimerDuration(duration)
end

function TargetedSpellsBarMixin:SetFont()
	local hasShadow = TargetedSpellsSaved.Settings.Party.FontFlags[Private.Enum.FontFlags.SHADOW]

	for _, fontString in ipairs({
		self.ProgressBar.SpellName,
		self.ProgressBar.TargetName,
		self.Duration,
		self.ProgressBar.InterruptSource,
	}) do
		fontString:SetFont(
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

function TargetedSpellsBarMixin:OnUpdate(elapsed)
	self.elapsed = self.elapsed + elapsed

	if self.elapsed < 0.1 then
		return
	end

	self.elapsed = self.elapsed - 0.1

	local duration = self.ProgressBar:GetTimerDuration()

	if duration == nil then
		return
	end

	if duration.FormatRemainingDuration == nil and Private.Utils.Formatter == nil then
		self.Duration:SetFormattedText("%.1f", duration:GetRemainingDuration())
	else
		self.Duration:SetText(duration:FormatRemainingDuration(Private.Utils.Formatter))
	end
end
