---@type string, TargetedSpells
local _, Private = ...

local PreviewIconDataProvider = nil

---@return IconDataProviderMixin
local function GetRandomIcon()
	if PreviewIconDataProvider == nil then
		PreviewIconDataProvider =
			CreateAndInitFromMixin(IconDataProviderMixin, IconDataProviderExtraType.Spellbook, true)
	end

	return PreviewIconDataProvider:GetRandomIcon()
end

---@param parent Frame
---@param width number
---@param height number
local function CreateStar4Glow(parent, width, height)
	local innerFactor = 1.9
	local outerFactor = 2.2

	local Star4 = CreateFrame("Frame", nil, parent)
	Star4:SetPoint("CENTER")
	Star4:SetFrameStrata(parent:GetFrameStrata())
	Star4:SetFrameLevel(parent:GetFrameLevel() + 1)
	PixelUtil.SetSize(Star4, width * innerFactor, height * innerFactor)

	local Inner = Star4:CreateTexture(nil, "OVERLAY")
	Inner:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
	Inner:SetBlendMode("ADD")
	Inner:SetAlpha(0.9)
	Inner:SetVertexColor(1, 0.85, 0.25)
	Inner:SetPoint("CENTER")
	PixelUtil.SetSize(Inner, width * innerFactor, height * innerFactor)
	Star4.Inner = Inner

	local Outer = Star4:CreateTexture(nil, "OVERLAY")
	Outer:SetTexture("Interface\\Cooldown\\star4")
	Outer:SetBlendMode("ADD")
	Outer:SetAlpha(0.6)
	Outer:SetVertexColor(1, 0.75, 0.2)
	Outer:SetPoint("CENTER")
	PixelUtil.SetSize(Outer, width * outerFactor, height * outerFactor)
	Star4.Outer = Outer

	local Animation = Star4:CreateAnimationGroup()
	local Pulse = Animation:CreateAnimation("Alpha")
	Pulse:SetFromAlpha(0.35)
	Pulse:SetToAlpha(0.75)
	Pulse:SetDuration(0.75)
	Pulse:SetSmoothing("IN_OUT")
	Animation:SetLooping("BOUNCE")
	Star4.Animation = Animation

	return Star4
end

---@class TargetedSpellsMixin : Frame
TargetedSpellsMixin = {}

function TargetedSpellsMixin:OnLoad()
	Private.EventRegistry:RegisterCallback(Private.Enum.Events.SETTING_CHANGED, self.OnSettingChanged, self)
	self.wasInterrupted = false
	self.doNotHideBefore = nil
	self.elapsed = 0
end

function TargetedSpellsMixin:OnSettingChanged()
	-- Implement in your derived mixin.
end

function TargetedSpellsMixin:SetId(id)
	self.id = id
end

function TargetedSpellsMixin:GetId()
	return self.id
end

function TargetedSpellsMixin:GetKind()
	return self.kind
end

function TargetedSpellsMixin:CanBeHidden(id)
	if self.wasInterrupted then
		return GetTime() >= self.doNotHideBefore
	end

	if id == nil then
		return true
	end

	return id == self:GetId()
end

function TargetedSpellsMixin:SetStartTime(startTime)
	self.startTime = startTime or GetTime()
end

function TargetedSpellsMixin:GetStartTime()
	return self.startTime
end

function TargetedSpellsMixin:ClearStartTime()
	self.startTime = nil
end

function TargetedSpellsMixin:ShouldBeShown()
	return self.startTime ~= nil
end

function TargetedSpellsMixin:IsSpellImportant(boolOverride)
	if boolOverride ~= nil then
		return secretwrap(boolOverride)
	end

	if self.spellId == nil then
		return secretwrap(false)
	end

	return C_Spell.IsSpellImportant(self.spellId)
end

function TargetedSpellsMixin:GetGlowTarget()
	local tableRef = self.kind == Private.Enum.FrameKind.Self and TargetedSpellsSaved.Settings.Self
		or TargetedSpellsSaved.Settings.Party

	return self, tableRef.Width, tableRef.Height
end

function TargetedSpellsMixin:HideGlow()
	local glowFrame = self:GetGlowTarget()

	if glowFrame._Star4 ~= nil then
		glowFrame._Star4:Hide()
		glowFrame._Star4.Inner:Hide()
		glowFrame._Star4.Outer:Hide()
		glowFrame._Star4.Animation:Stop()
	end

	Private.Glows.PixelGlow_Stop(glowFrame)
	Private.Glows.AutoCastGlow_Stop(glowFrame)
	Private.Glows.ProcGlow_Stop(glowFrame)
end

function TargetedSpellsMixin:ShowGlow(isImportant)
	local tableRef = self.kind == Private.Enum.FrameKind.Self and TargetedSpellsSaved.Settings.Self
		or TargetedSpellsSaved.Settings.Party
	local glowFrame, glowWidth, glowHeight = self:GetGlowTarget()

	if tableRef.GlowType == Private.Enum.GlowType.Star4 then
		if glowFrame._Star4 == nil then
			glowFrame._Star4 = CreateStar4Glow(glowFrame, glowWidth, glowHeight)
		end

		glowFrame._Star4:Show()
		glowFrame._Star4.Inner:Show()
		glowFrame._Star4.Outer:Show()
		glowFrame._Star4.Animation:Play()

		glowFrame._Star4:SetAlphaFromBoolean(isImportant)
	elseif tableRef.GlowType == Private.Enum.GlowType.PixelGlow then
		Private.Glows.PixelGlow_Start(glowFrame, glowWidth, glowHeight)

		glowFrame._PixelGlow:SetAlphaFromBoolean(isImportant)
	elseif tableRef.GlowType == Private.Enum.GlowType.AutoCastGlow then
		Private.Glows.AutoCastGlow_Start(glowFrame, glowWidth, glowHeight)

		glowFrame._AutoCastGlow:SetAlphaFromBoolean(isImportant)
	elseif tableRef.GlowType == Private.Enum.GlowType.ProcGlow then
		Private.Glows.ProcGlow_Start(glowFrame, glowWidth, glowHeight)

		glowFrame._ProcGlow:SetAlphaFromBoolean(isImportant)
	end
end

function TargetedSpellsMixin:GetSpellId()
	return self.spellId
end

function TargetedSpellsMixin:SetSpellId(spellId)
	self.spellId = spellId
	local texture = spellId and C_Spell.GetSpellTexture(spellId) or GetRandomIcon()
	self.Icon:SetTexture(texture)
end

function TargetedSpellsMixin:SetInterrupted(name, color)
	self.wasInterrupted = true
	self.doNotHideBefore = GetTime() + 0.95
	self.InterruptIcon:Show()
	self.Icon:SetDesaturated(true)
	self:SetShowDuration(false)
	self:HideGlow()
end

function TargetedSpellsMixin:Reset()
	self:SetParent(UIParent)
	self.Bar:ClearAllPoints()
	self.Bar:SetParent(self)
	self:ClearAllPoints()
	self:ClearStartTime()
	self.wasInterrupted = false
	self.doNotHideBefore = nil
	self.InterruptIcon:Hide()
	self.Icon:SetDesaturated(false)
	self:SetId()
	self:HideGlow()
	self:Hide()
end

function TargetedSpellsMixin:SetFont()
	-- Implement in your derived mixin.
end

function TargetedSpellsMixin:SetShowDuration(showDuration)
	-- Implement in your derived mixin.
end

function TargetedSpellsMixin:SetDuration(duration)
	local alpha = duration:EvaluateRemainingDuration(Private.Utils.IsLongCastCurve)
	self:SetAlpha(alpha)
	self.Bar:SetValue(alpha)

	return alpha
end
