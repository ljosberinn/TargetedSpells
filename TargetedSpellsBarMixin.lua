---@type string, TargetedSpells
local addonName, Private = ...
local LibEditMode = LibStub("LibEditMode")
local LibSharedMedia = LibStub("LibSharedMedia-3.0")

---@class TargetedSpellsBarMixin : TargetedSpellsMixin
TargetedSpellsBarMixin = CreateFromMixins(TargetedSpellsMixin)

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

	self.CustomElementsFrame.TargetMarker:SetSize(
		TargetedSpellsSaved.Settings.Party.Height,
		TargetedSpellsSaved.Settings.Party.Height
	)
	self.Icon:SetWidth(TargetedSpellsSaved.Settings.Party.Height)
	self.Icon:SetShown(showIcon)

	self.CustomElementsFrame.TargetMarker:ClearAllPoints()
	self.Icon:ClearAllPoints()
	self.ProgressBar:ClearAllPoints()
	self.ProgressBar.SpellName:ClearAllPoints()
	self.ProgressBar.Divider:ClearAllPoints()
	self.ProgressBar.TargetName:ClearAllPoints()
	self.ProgressBar.Duration:ClearAllPoints()

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

	if slotFrame then
		if mirrored then
			PixelUtil.SetPoint(self.ProgressBar, "TOPLEFT", self, "TOPLEFT", 0, 0)
			PixelUtil.SetPoint(self.ProgressBar, "BOTTOMRIGHT", slotFrame, "BOTTOMLEFT", 0, 0)
		else
			PixelUtil.SetPoint(self.ProgressBar, "TOPLEFT", slotFrame, "TOPRIGHT", 0, 0)
			PixelUtil.SetPoint(self.ProgressBar, "BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0)
		end
	else
		self.ProgressBar:SetAllPoints(self)
	end

	local showSpellName = TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.ShowSpellName]
	local showTargetName = TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.ShowTargetName]
	local showDuration = TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.ShowDuration]
	local hasDivider = TargetedSpellsSaved.Settings.Party.NameDivider ~= Private.Enum.NameDivider.None

	self.ProgressBar.SpellName:SetWidth(TargetedSpellsSaved.Settings.Party.SpellNameWidth)
	self.ProgressBar.TargetName:SetWidth(TargetedSpellsSaved.Settings.Party.TargetNameWidth)

	if mirrored then
		self.ProgressBar.Duration:SetJustifyH("LEFT")
		PixelUtil.SetPoint(self.ProgressBar.Duration, "LEFT", self.ProgressBar, "LEFT", 4, 0)

		local chainAnchor = showDuration and self.ProgressBar.Duration or self.ProgressBar
		local chainPoint = showDuration and "RIGHT" or "LEFT"

		if showTargetName and showSpellName then
			PixelUtil.SetPoint(self.ProgressBar.TargetName, "LEFT", chainAnchor, chainPoint, 4, 0)
			if hasDivider then
				PixelUtil.SetPoint(self.ProgressBar.Divider, "LEFT", self.ProgressBar.TargetName, "RIGHT", 0, 0)
				PixelUtil.SetPoint(self.ProgressBar.SpellName, "LEFT", self.ProgressBar.Divider, "RIGHT", 0, 0)
			else
				PixelUtil.SetPoint(self.ProgressBar.SpellName, "LEFT", self.ProgressBar.TargetName, "RIGHT", 0, 0)
			end
			PixelUtil.SetPoint(self.ProgressBar.SpellName, "RIGHT", self.ProgressBar, "RIGHT", -4, 0)
		elseif showSpellName then
			PixelUtil.SetPoint(self.ProgressBar.SpellName, "LEFT", chainAnchor, chainPoint, 4, 0)
			PixelUtil.SetPoint(self.ProgressBar.SpellName, "RIGHT", self.ProgressBar, "RIGHT", -4, 0)
		elseif showTargetName then
			PixelUtil.SetPoint(self.ProgressBar.TargetName, "LEFT", chainAnchor, chainPoint, 4, 0)
			PixelUtil.SetPoint(self.ProgressBar.TargetName, "RIGHT", self.ProgressBar, "RIGHT", -4, 0)
		end
	else
		self.ProgressBar.Duration:SetJustifyH("RIGHT")
		PixelUtil.SetPoint(self.ProgressBar.Duration, "RIGHT", self.ProgressBar, "RIGHT", -4, 0)

		local textAnchor = slotFrame or self.ProgressBar
		local textPoint = slotFrame and "RIGHT" or "LEFT"

		if showSpellName then
			PixelUtil.SetPoint(self.ProgressBar.SpellName, "LEFT", textAnchor, textPoint, 4, 0)
			if showTargetName then
				if hasDivider then
					PixelUtil.SetPoint(self.ProgressBar.Divider, "LEFT", self.ProgressBar.SpellName, "RIGHT", 0, 0)
					PixelUtil.SetPoint(self.ProgressBar.TargetName, "LEFT", self.ProgressBar.Divider, "RIGHT", 0, 0)
				else
					PixelUtil.SetPoint(self.ProgressBar.TargetName, "LEFT", self.ProgressBar.SpellName, "RIGHT", 0, 0)
				end
			end
		elseif showTargetName then
			PixelUtil.SetPoint(self.ProgressBar.TargetName, "LEFT", textAnchor, textPoint, 4, 0)
		end

		local rightText = showTargetName and self.ProgressBar.TargetName or showSpellName and self.ProgressBar.SpellName
		if rightText then
			if showDuration then
				PixelUtil.SetPoint(rightText, "RIGHT", self.ProgressBar.Duration, "LEFT", -4, 0)
			else
				PixelUtil.SetPoint(rightText, "RIGHT", self.ProgressBar, "RIGHT", -4, 0)
			end
		end
	end

	self:SetDivider()
end

function TargetedSpellsBarMixin:OnSettingChanged(key, flagIdOrValue, newBool)
	if key == Private.Settings.Keys.Party.Width then
		PixelUtil.SetSize(self, flagIdOrValue, TargetedSpellsSaved.Settings.Party.Height)
	elseif key == Private.Settings.Keys.Party.Height then
		PixelUtil.SetSize(self, TargetedSpellsSaved.Settings.Party.Width, flagIdOrValue)
	elseif key == Private.Settings.Keys.Party.ShowDuration then
		self:SetShowDuration(flagIdOrValue)
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
				self.CustomElementsFrame.TargetMarker:SetShown(newBool)
				self:OnSizeChanged()
			elseif flagIdOrValue == Private.Enum.FeatureFlag.ShowIcon then
				self.Icon:SetShown(newBool)
				self:OnSizeChanged()
			elseif flagIdOrValue == Private.Enum.FeatureFlag.ShowTargetName then
				self.ProgressBar.TargetName:SetShown(newBool)
				self:SetDivider()
				self:OnSizeChanged()
			elseif flagIdOrValue == Private.Enum.FeatureFlag.ShowSpellName then
				self.ProgressBar.SpellName:SetShown(newBool)
				self:SetDivider()
				self:OnSizeChanged()
			elseif flagIdOrValue == Private.Enum.FeatureFlag.ShowDuration then
				self:SetShowDuration(newBool)
				self:OnSizeChanged()
			elseif flagIdOrValue == Private.Enum.FeatureFlag.MirrorLayout then
				self:SetDivider()
				self:OnSizeChanged()
			end
		end
	elseif
		key == Private.Settings.Keys.Party.FontSize
		or key == Private.Settings.Keys.Party.Font
		or key == Private.Settings.Keys.Party.FontFlags
	then
		self:SetFont()
	elseif key == Private.Settings.Keys.Party.NameDivider then
		self:SetDivider()
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
	elseif key == Private.Settings.Keys.Party.SpellNameWidth then
		self.ProgressBar.SpellName:SetWidth(flagIdOrValue)
	elseif key == Private.Settings.Keys.Party.TargetNameWidth then
		self.ProgressBar.TargetName:SetWidth(flagIdOrValue)
	end
end

function TargetedSpellsBarMixin:SetDivider()
	if
		not TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.ShowSpellName]
		or not TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.ShowTargetName]
	then
		self.ProgressBar.Divider:Hide()
		return
	end

	local nameDivider = TargetedSpellsSaved.Settings.Party.NameDivider

	if nameDivider == Private.Enum.NameDivider.None then
		self.ProgressBar.Divider:Hide()
		return
	end

	if TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.MirrorLayout] then
		if nameDivider == Private.Enum.NameDivider.Arrow then
			nameDivider = Private.Enum.NameDivider.LeftArrow
		elseif nameDivider == Private.Enum.NameDivider.LeftArrow then
			nameDivider = Private.Enum.NameDivider.Arrow
		elseif nameDivider == Private.Enum.NameDivider.Arrows then
			nameDivider = Private.Enum.NameDivider.LeftArrows
		elseif nameDivider == Private.Enum.NameDivider.LeftArrows then
			nameDivider = Private.Enum.NameDivider.Arrows
		end
	end

	if
		nameDivider == Private.Enum.NameDivider.Arrow
		or nameDivider == Private.Enum.NameDivider.LeftArrow
		or nameDivider == Private.Enum.NameDivider.Arrows
		or nameDivider == Private.Enum.NameDivider.LeftArrows
		or nameDivider == Private.Enum.NameDivider.Pipe
	then
		self.ProgressBar.Divider:SetText(" " .. nameDivider .. " ")
	elseif nameDivider == Private.Enum.NameDivider.Colon then
		self.ProgressBar.Divider:SetText(nameDivider .. " ")
	else
		self.ProgressBar.Divider:SetText(nameDivider)
	end

	local targetName = self.ProgressBar.TargetName:GetText()

	if targetName == nil then
		self.ProgressBar.Divider:Hide()
	else
		self.ProgressBar.Divider:Show()
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
	self.ProgressBar.Duration:SetShown(showDuration)
end

function TargetedSpellsBarMixin:Reset()
	TargetedSpellsMixin.Reset(self)
	self.unit = nil
	self.ProgressBar:SetReverseFill(false)
	self:SetProgressBarColor()
	self.ProgressBar.InterruptSource:SetText("")
	self.ProgressBar.InterruptSource:Hide()
	self.ProgressBar.InterruptSource:SetTextColor(1, 1, 1)
	self.CustomElementsFrame.TargetMarker:Hide()
	self.ProgressBar.Divider:Hide()
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

		if not TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.ShowTargetName] then
			self.ProgressBar.TargetName:Hide()
			return
		end

		local name = ""
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
				name ~= nil
				and TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.ShowTargetClassColor]
			then
				local targetClass = UnitSpellTargetClass(castingUnit)

				if targetClass ~= nil then
					color = C_ClassColor.GetClassColor(targetClass)
					isClassColor = color ~= nil
				end
			end

			if name == nil then
				name = ""

				self.ProgressBar.Divider:Hide()
			else
				self.ProgressBar.Divider:Show()
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

		local isChannel = false

		do
			local castingDuration = UnitCastingDuration(castingUnit)

			if castingDuration == nil then
				local channelDuration = UnitChannelDuration(castingUnit)

				if channelDuration ~= nil then
					isChannel = true
				end
			end
		end

		self.ProgressBar:SetReverseFill(isChannel)

		self.ProgressBar.TargetName:SetText(name)

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

		self.ProgressBar.TargetName:Show()

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
	self.ProgressBar.Divider:Hide()
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

	self:SetDivider()

	TargetedSpellsMixin.SetSpellId(self, spellId)
end

function TargetedSpellsBarMixin:SetDuration(duration)
	self.ProgressBar.Duration:SetText("")
	self:SetShowDuration(TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.ShowDuration])
	self.ProgressBar:SetTimerDuration(duration)
end

function TargetedSpellsBarMixin:SetFont()
	local hasShadow = TargetedSpellsSaved.Settings.Party.FontFlags[Private.Enum.FontFlags.SHADOW]

	for _, fontString in ipairs({
		self.ProgressBar.SpellName,
		self.ProgressBar.Divider,
		self.ProgressBar.TargetName,
		self.ProgressBar.Duration,
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
		self.ProgressBar.Duration:SetFormattedText("%.1f", duration:GetRemainingDuration())
	else
		self.ProgressBar.Duration:SetText(duration:FormatRemainingDuration(Private.Utils.Formatter))
	end
end
