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

	self.TargetMarker:SetSize(TargetedSpellsSaved.Settings.Party.Height, TargetedSpellsSaved.Settings.Party.Height)
	self.Icon:SetWidth(TargetedSpellsSaved.Settings.Party.Height)
	self.Icon:SetShown(showIcon)

	self.TargetMarker:ClearAllPoints()
	self.Icon:ClearAllPoints()
	self.ProgressBar:ClearAllPoints()
	self.SpellName:ClearAllPoints()

	-- The leftmost slot frame that ProgressBar and SpellName anchor their left edge to
	local slotFrame = nil

	if showTargetMarker and showIcon then
		self.TargetMarker:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
		self.TargetMarker:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 0, 0)
		self.Icon:SetPoint("TOPLEFT", self.TargetMarker, "TOPRIGHT", 0, 0)
		self.Icon:SetPoint("BOTTOMLEFT", self.TargetMarker, "BOTTOMRIGHT", 0, 0)
		slotFrame = self.Icon
	elseif showTargetMarker then
		self.TargetMarker:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
		self.TargetMarker:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 0, 0)
		slotFrame = self.TargetMarker
	elseif showIcon then
		self.Icon:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
		self.Icon:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 0, 0)
		slotFrame = self.Icon
	end

	if slotFrame then
		self.ProgressBar:SetPoint("TOPLEFT", slotFrame, "TOPRIGHT", 0, 0)
		self.ProgressBar:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0)
		self.SpellName:SetPoint("LEFT", slotFrame, "RIGHT", 4, 0)
	else
		self.ProgressBar:SetAllPoints(self)
		PixelUtil.SetPoint(self.SpellName, "LEFT", self, "LEFT", 4, 0)
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
		then
			if flagIdOrValue == Private.Enum.FeatureFlag.ShowTargetMarker and not newBool then
				self.TargetMarker:Hide()
			end

			self:OnSizeChanged()
		end
	end
end

function TargetedSpellsBarMixin:OnUpdate() end

function TargetedSpellsBarMixin:Reset()
	self:SetParent(UIParent)
	self.Bar:ClearAllPoints()
	self.Bar:SetParent(self)
	self:ClearAllPoints()
	self.startTime = nil
	self.TargetMarker:Hide()
	self:Hide()
end

function TargetedSpellsBarMixin:PostCreate(castingUnit) end

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

	if TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.ShowName] then
		local name = spellId == nil and addonName or C_Spell.GetspellName(spellId)

		self.SpellName:SetText(name)
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
