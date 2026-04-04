---@type string, TargetedSpells
local addonName, Private = ...
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
end

function TargetedSpellsBarMixin:OnSizeChanged()
	local showIcon = TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.ShowIcon]
	local showTargetMarker = TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.ShowTargetMarker]

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

	local slotFrame = nil

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

	local showSpellName = TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.ShowSpellName]
	local hasDivider = TargetedSpellsSaved.Settings.Party.NameDivider ~= Private.Enum.NameDivider.None

	if slotFrame then
		PixelUtil.SetPoint(self.ProgressBar, "TOPLEFT", slotFrame, "TOPRIGHT", 0, 0)
		PixelUtil.SetPoint(self.ProgressBar, "BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0)
		PixelUtil.SetPoint(self.ProgressBar.SpellName, "LEFT", slotFrame, "RIGHT", 4, 0)

		if not showSpellName then
			PixelUtil.SetPoint(self.ProgressBar.TargetName, "LEFT", slotFrame, "RIGHT", 4, 0)
		end
	else
		self.ProgressBar:SetAllPoints(self)
		PixelUtil.SetPoint(self.ProgressBar.SpellName, "LEFT", self, "LEFT", 4, 0)
		if not showSpellName then
			PixelUtil.SetPoint(self.ProgressBar.TargetName, "LEFT", self.ProgressBar, "LEFT", 4, 0)
		end
	end

	if showSpellName then
		if hasDivider then
			PixelUtil.SetPoint(self.ProgressBar.Divider, "LEFT", self.ProgressBar.SpellName, "RIGHT", 0, 0)
			PixelUtil.SetPoint(self.ProgressBar.TargetName, "LEFT", self.ProgressBar.Divider, "RIGHT", 0, 0)
		else
			PixelUtil.SetPoint(self.ProgressBar.TargetName, "LEFT", self.ProgressBar.SpellName, "RIGHT", 0, 0)
		end
	end

	self.ProgressBar.SpellName:SetWidth(TargetedSpellsSaved.Settings.Party.SpellNameWidth)
	self.ProgressBar.TargetName:SetWidth(TargetedSpellsSaved.Settings.Party.TargetNameWidth)

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

	if
		nameDivider == Private.Enum.NameDivider.Arrow
		or nameDivider == Private.Enum.NameDivider.Arrows
		or nameDivider == Private.Enum.NameDivider.Pipe
	then
		self.ProgressBar.Divider:SetText(" " .. nameDivider .. " ")
	elseif nameDivider == Private.Enum.NameDivider.Colon then
		self.ProgressBar.Divider:SetText(nameDivider .. " ")
	else
		self.ProgressBar.Divider:SetText(nameDivider)
	end

	self.ProgressBar.Divider:Show()
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

function TargetedSpellsBarMixin:SetBackgroundBarColor()
	local color = CreateColorFromHexString(TargetedSpellsSaved.Settings.Party.BackgroundBarColor)

	self.ProgressBar.Background:SetVertexColor(color.r, color.g, color.b, color.a)
end

function TargetedSpellsBarMixin:SetShowDuration(showDuration)
	self.ProgressBar.Duration:SetShown(showDuration)
end

function TargetedSpellsBarMixin:Reset()
	TargetedSpellsMixin.Reset(self)
	self.ProgressBar.InterruptSource:SetText("")
	self.ProgressBar.InterruptSource:Hide()
	self.ProgressBar.InterruptSource:SetTextColor(1, 1, 1)
	self.CustomElementsFrame.TargetMarker:Hide()
	self.ProgressBar.Divider:Hide()
	self.ProgressBar.TargetName:Hide()
end

do
	local whiteDefaultColor = CreateColor(1, 1, 1, 1)

	function TargetedSpellsBarMixin:PostCreate(castingUnit)
		if not TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.ShowTargetName] then
			self.ProgressBar.TargetName:Hide()
			return
		end

		local name = ""
		---@type colorRGB?
		local color = nil

		if castingUnit == "preview" then
			name = Private.L.Settings.TargetNamePreviewText

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
				end
			end

			if name == nil then
				name = ""
			end
		end

		if color == nil then
			color = whiteDefaultColor
		end

		self.ProgressBar.TargetName:SetText(name)
		self.ProgressBar.TargetName:SetTextColor(color.r, color.g, color.b, color.a)
		self.ProgressBar.TargetName:Show()
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

	self.ProgressBar.Duration:SetText(duration:FormatRemainingDuration(Private.Utils.Formatter))
end
