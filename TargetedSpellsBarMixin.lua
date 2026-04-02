---@type string, TargetedSpells
local addonName, Private = ...

---@class TargetedSpellsBarMixin
TargetedSpellsBarMixin = {}

function TargetedSpellsBarMixin:OnLoad()
	self.Bar:SetStatusBarTexture("")
	self.ProgressBar:SetStatusBarTexture("Interface\\RaidFrame\\Raid-Bar-Hp-Fill")
	Private.EventRegistry:RegisterCallback(Private.Enum.Events.SETTING_CHANGED, self.OnSettingChanged, self)
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
	self.ProgressBar.TargetName:ClearAllPoints()

	-- The leftmost slot frame that ProgressBar and SpellName anchor their left edge to
	local slotFrame = nil

	if showTargetMarker and showIcon then
		self.CustomElementsFrame.TargetMarker:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
		self.CustomElementsFrame.TargetMarker:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 0, 0)
		self.Icon:SetPoint("TOPLEFT", self.CustomElementsFrame.TargetMarker, "TOPRIGHT", 0, 0)
		self.Icon:SetPoint("BOTTOMLEFT", self.CustomElementsFrame.TargetMarker, "BOTTOMRIGHT", 0, 0)
		slotFrame = self.Icon
	elseif showTargetMarker then
		self.CustomElementsFrame.TargetMarker:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
		self.CustomElementsFrame.TargetMarker:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 0, 0)
		slotFrame = self.CustomElementsFrame.TargetMarker
	elseif showIcon then
		self.Icon:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
		self.Icon:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 0, 0)
		slotFrame = self.Icon
	end

	local showSpellName = TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.ShowSpellName]

	if slotFrame then
		self.ProgressBar:SetPoint("TOPLEFT", slotFrame, "TOPRIGHT", 0, 0)
		self.ProgressBar:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0)
		self.ProgressBar.SpellName:SetPoint("LEFT", slotFrame, "RIGHT", 4, 0)
		if not showSpellName then
			self.ProgressBar.TargetName:SetPoint("LEFT", slotFrame, "RIGHT", 4, 0)
		end
	else
		self.ProgressBar:SetAllPoints(self)
		PixelUtil.SetPoint(self.ProgressBar.SpellName, "LEFT", self, "LEFT", 4, 0)
		if not showSpellName then
			PixelUtil.SetPoint(self.ProgressBar.TargetName, "LEFT", self.ProgressBar, "LEFT", 4, 0)
		end
	end

	if showSpellName then
		self.ProgressBar.TargetName:SetPoint("LEFT", self.ProgressBar.SpellName, "RIGHT", 0, 0)
	end

	self.ProgressBar.SpellName:SetWidth(TargetedSpellsSaved.Settings.Party.SpellNameWidth)
	self.ProgressBar.TargetName:SetWidth(TargetedSpellsSaved.Settings.Party.TargetNameWidth)
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
		then
			if flagIdOrValue == Private.Enum.FeatureFlag.ShowTargetMarker and not newBool then
				self.CustomElementsFrame.TargetMarker:Hide()
			end
			if flagIdOrValue == Private.Enum.FeatureFlag.ShowTargetName and not newBool then
				self.ProgressBar.TargetName:Hide()
			end

			self:OnSizeChanged()
		end
	elseif key == Private.Settings.Keys.Party.SpellNameWidth then
		self.ProgressBar.SpellName:SetWidth(flagIdOrValue)
	elseif key == Private.Settings.Keys.Party.TargetNameWidth then
		self.ProgressBar.TargetName:SetWidth(flagIdOrValue)
	end
end

function TargetedSpellsBarMixin:OnUpdate() end

function TargetedSpellsBarMixin:Reset()
	self:SetParent(UIParent)
	self.Bar:ClearAllPoints()
	self.Bar:SetParent(self)
	self:ClearAllPoints()
	self.startTime = nil
	self.CustomElementsFrame.TargetMarker:Hide()
	self.ProgressBar.TargetName:Hide()
	self:Hide()
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
			local targetUnit = UnitSpellTargetName(castingUnit)

			if targetUnit ~= nil then
				name = UnitName(targetUnit)

				if TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.ShowTargetClassColor] then
					local targetClass = UnitSpellTargetClass(targetUnit)

					if targetClass ~= nil then
						color = C_ClassColor.GetClassColor(targetClass)
					end
				end
			end

			if name == nil then
				name = ""
			end
		end

		if color == nil then
			color = whiteDefaultColor
		end

		self.ProgressBar.TargetName:SetFormattedText(
			"%s%s",
			TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.ShowSpellName] and " >> " or "",
			name
		)
		self.ProgressBar.TargetName:SetTextColor(color.r, color.g, color.b, color.a)
		self.ProgressBar.TargetName:Show()
	end
end

function TargetedSpellsBarMixin:GetKind()
	return self.kind
end

function TargetedSpellsBarMixin:SetStartTime(startTime)
	self.startTime = startTime or GetTime()
end

function TargetedSpellsBarMixin:ClearStartTime()
	self.startTime = nil
end

function TargetedSpellsBarMixin:GetStartTime()
	return self.startTime
end

function TargetedSpellsBarMixin:ShouldBeShown()
	return self.startTime ~= nil
end

local PreviewIconDataProvider = nil

---@return IconDataProviderMixin
local function GetRandomIcon()
	if PreviewIconDataProvider == nil then
		PreviewIconDataProvider =
			CreateAndInitFromMixin(IconDataProviderMixin, IconDataProviderExtraType.Spellbook, true)
	end

	return PreviewIconDataProvider:GetRandomIcon()
end

function TargetedSpellsBarMixin:SetSpellId(spellId)
	self.spellId = spellId
	local texture = spellId and C_Spell.GetSpellTexture(spellId) or GetRandomIcon()
	self.Icon:SetTexture(texture)

	if TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.ShowSpellName] then
		local name = spellId == nil and addonName or C_Spell.GetSpellName(spellId)
		self.ProgressBar.SpellName:SetText(name)
		self.ProgressBar.SpellName:Show()
	else
		self.ProgressBar.SpellName:Hide()
	end

	if spellId == nil then
		return
	end

	if not TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.GlowImportant] then
		return
	end

	local isImportant = self:IsSpellImportant()

	self:ShowGlow(isImportant)

	if TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.OnlyImportant] then
		self:SetAlphaFromBoolean(isImportant, 1, 0)
	end
end

function TargetedSpellsBarMixin:ShowGlow(isImportant)
	local glowType = TargetedSpellsSaved.Settings.Party.GlowType

	if glowType == Private.Enum.GlowType.Star4 then
		if self._Star4 == nil then
			self._Star4 = CreateStar4Glow(
				self,
				TargetedSpellsSaved.Settings.Party.Width,
				TargetedSpellsSaved.Settings.Party.Height
			)
		end

		self._Star4:Show()
		self._Star4.Inner:Show()
		self._Star4.Outer:Show()
		self._Star4.Animation:Play()

		self._Star4:SetAlphaFromBoolean(isImportant)
	elseif glowType == Private.Enum.GlowType.PixelGlow then
		Private.Glows.PixelGlow_Start(
			self,
			TargetedSpellsSaved.Settings.Party.Width,
			TargetedSpellsSaved.Settings.Party.Height
		)

		self._PixelGlow:SetAlphaFromBoolean(isImportant)
	elseif glowType == Private.Enum.GlowType.AutoCastGlow then
		Private.Glows.AutoCastGlow_Start(
			self,
			TargetedSpellsSaved.Settings.Party.Width,
			TargetedSpellsSaved.Settings.Party.Height
		)

		self._AutoCastGlow:SetAlphaFromBoolean(isImportant)
	elseif glowType == Private.Enum.GlowType.ProcGlow then
		Private.Glows.ProcGlow_Start(
			self,
			TargetedSpellsSaved.Settings.Party.Width,
			TargetedSpellsSaved.Settings.Party.Height
		)

		self._ProcGlow:SetAlphaFromBoolean(isImportant)
	end
end

function TargetedSpellsBarMixin:HideGlow()
	if self._Star4 ~= nil then
		self._Star4:Hide()
		self._Star4.Inner:Hide()
		self._Star4.Outer:Hide()
		self._Star4.Animation:Stop()
	end

	Private.Glows.PixelGlow_Stop(self)
	Private.Glows.AutoCastGlow_Stop(self)
	Private.Glows.ProcGlow_Stop(self)
end

function TargetedSpellsBarMixin:IsSpellImportant(boolOverride)
	if boolOverride ~= nil then
		return boolOverride
	end

	if self.spellId == nil then
		return false
	end

	return C_Spell.IsSpellImportant(self.spellId)
end

function TargetedSpellsBarMixin:SetDuration(duration)
	self.duration = duration
	self.ProgressBar:SetTimerDuration(duration)
end
