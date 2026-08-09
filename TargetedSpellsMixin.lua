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

local STAR4_INNER_FACTOR = 1.9
local STAR4_OUTER_FACTOR = 2.2

---@param Star4 Star4Glow
---@param width number
---@param height number
local function SizeStar4Glow(Star4, width, height)
	PixelUtil.SetSize(Star4, width * STAR4_INNER_FACTOR, height * STAR4_INNER_FACTOR)
	PixelUtil.SetSize(Star4.Inner, width * STAR4_INNER_FACTOR, height * STAR4_INNER_FACTOR)
	PixelUtil.SetSize(Star4.Outer, width * STAR4_OUTER_FACTOR, height * STAR4_OUTER_FACTOR)
end

---@param parent Frame
---@param width number
---@param height number
---@return Star4Glow
local function CreateStar4Glow(parent, width, height)
	local Star4 = CreateFrame("Frame", nil, parent)
	Star4:SetPoint("CENTER")
	Star4:SetFrameStrata(parent:GetFrameStrata())
	Star4:SetFrameLevel(parent:GetFrameLevel() + 1)

	local Inner = Star4:CreateTexture(nil, "OVERLAY")
	Inner:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
	Inner:SetBlendMode("ADD")
	Inner:SetAlpha(0.9)
	Inner:SetVertexColor(1, 0.85, 0.25)
	Inner:SetPoint("CENTER")
	Star4.Inner = Inner

	local Outer = Star4:CreateTexture(nil, "OVERLAY")
	Outer:SetTexture("Interface\\Cooldown\\star4")
	Outer:SetBlendMode("ADD")
	Outer:SetAlpha(0.6)
	Outer:SetVertexColor(1, 0.75, 0.2)
	Outer:SetPoint("CENTER")
	Star4.Outer = Outer

	local Animation = Star4:CreateAnimationGroup()
	local Pulse = Animation:CreateAnimation("Alpha")
	Pulse:SetFromAlpha(0.35)
	Pulse:SetToAlpha(0.75)
	Pulse:SetDuration(0.75)
	Pulse:SetSmoothing("IN_OUT")
	Animation:SetLooping("BOUNCE")
	Star4.Animation = Animation

	SizeStar4Glow(Star4 --[[@as Star4Glow]], width, height)

	return Star4 --[[@as Star4Glow]]
end

local GLOW_FIELD = {
	[Private.Enum.GlowType.Star4] = "_Star4",
	[Private.Enum.GlowType.PixelGlow] = "_PixelGlow",
	[Private.Enum.GlowType.AutoCastGlow] = "_AutoCastGlow",
	[Private.Enum.GlowType.ProcGlow] = "_ProcGlow",
}

---@class TargetedSpellsMixin : Frame
TargetedSpellsMixin = {}

function TargetedSpellsMixin:OnLoad()
	self.wasInterrupted = false
	self.doNotHideBefore = nil
	self.elapsed = 0
end

function TargetedSpellsMixin:SetId(id)
	self.id = id
end

function TargetedSpellsMixin:GetId()
	return self.id
end

function TargetedSpellsMixin:SetUnit(unit)
	self.unit = unit
end

function TargetedSpellsMixin:GetUnit()
	return self.unit
end


function TargetedSpellsMixin:SetGroup(group)
	self.group = group
end

function TargetedSpellsMixin:GetGroup()
	return self.group
end

function TargetedSpellsMixin:SetLayoutOverride(elements)
	self.layoutOverride = elements
end

function TargetedSpellsMixin:ClearLayoutOverride()
	self.layoutOverride = nil
end

---@return table<Element, table<string, any>>?
function TargetedSpellsMixin:GetElements()
	if self.layoutOverride ~= nil then
		return self.layoutOverride
	end

	return self.group and self.group.Elements
end

---@param element Element
---@return table<string, any>?
function TargetedSpellsMixin:GetElement(element)
	local elements = self:GetElements()
	return elements and elements[element]
end

---@return Element?
function TargetedSpellsMixin:GetCoreElement()
	return nil
end

---@return number?, number?
function TargetedSpellsMixin:GetCoreSize()
	local core = self:GetElement(self:GetCoreElement())
	if core == nil then
		return nil, nil
	end
	return core.width, core.height
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

function TargetedSpellsMixin:GetGlowFrame()
	return self --[[@as GlowTargetFrame]]
end

function TargetedSpellsMixin:GetGlowTarget()
	local width, height = self:GetCoreSize()
	return self:GetGlowFrame(), width, height
end

-- Glows are parked and reused when type and dimensions match.

---@param glowFrame GlowTargetFrame
function TargetedSpellsMixin:HideGlowOn(glowFrame)
	local glowType = glowFrame.appliedGlowType

	if glowType == nil then
		return
	end

	local glow = glowFrame[GLOW_FIELD[glowType]]

	if glow == nil then
		return
	end

	if glowType == Private.Enum.GlowType.Star4 then
		glow.Animation:Stop()
		glow.Inner:Hide()
		glow.Outer:Hide()
	end

	glow:Hide()
end

function TargetedSpellsMixin:HideGlow()
	self:HideGlowOn(self:GetGlowFrame())
end

---@param glowFrame GlowTargetFrame
---@param glowWidth number
---@param glowHeight number
---@param glowType GlowType
---@param isImportant boolean secret — only ever fed to SetAlphaFromBoolean, never branched on
function TargetedSpellsMixin:ShowGlowOn(glowFrame, glowWidth, glowHeight, glowType, isImportant)
	local field = GLOW_FIELD[glowType]

	if field == nil then
		return
	end

	local previousType = glowFrame.appliedGlowType

	local matches = previousType == glowType
		and glowFrame.appliedGlowWidth == glowWidth
		and glowFrame.appliedGlowHeight == glowHeight
		and glowFrame[field] ~= nil

	if matches then
		local glow = glowFrame[field]

		if glowType == Private.Enum.GlowType.Star4 then
			glow.Inner:Show()
			glow.Outer:Show()
			glow.Animation:Play()
		end

		glow:Show()
	else
		if previousType ~= nil and previousType ~= glowType then
			if previousType == Private.Enum.GlowType.Star4 then
				glowFrame._Star4.Animation:Stop()
				glowFrame._Star4.Inner:Hide()
				glowFrame._Star4.Outer:Hide()
				glowFrame._Star4:Hide()
			elseif previousType == Private.Enum.GlowType.PixelGlow then
				Private.Glows.PixelGlow_Stop(glowFrame)
			elseif previousType == Private.Enum.GlowType.AutoCastGlow then
				Private.Glows.AutoCastGlow_Stop(glowFrame)
			elseif previousType == Private.Enum.GlowType.ProcGlow then
				Private.Glows.ProcGlow_Stop(glowFrame)
			end
		end

		if glowType == Private.Enum.GlowType.Star4 then
			if glowFrame._Star4 == nil then
				glowFrame._Star4 = CreateStar4Glow(glowFrame, glowWidth, glowHeight)
			else
				SizeStar4Glow(glowFrame._Star4, glowWidth, glowHeight)
			end

			glowFrame._Star4:Show()
			glowFrame._Star4.Inner:Show()
			glowFrame._Star4.Outer:Show()
			glowFrame._Star4.Animation:Play()
		elseif glowType == Private.Enum.GlowType.PixelGlow then
			Private.Glows.PixelGlow_Start(glowFrame, glowWidth, glowHeight)
		elseif glowType == Private.Enum.GlowType.AutoCastGlow then
			Private.Glows.AutoCastGlow_Start(glowFrame, glowWidth, glowHeight)
		elseif glowType == Private.Enum.GlowType.ProcGlow then
			Private.Glows.ProcGlow_Start(glowFrame, glowWidth, glowHeight)
		end

		glowFrame.appliedGlowType = glowType
		glowFrame.appliedGlowWidth = glowWidth
		glowFrame.appliedGlowHeight = glowHeight
	end

	glowFrame[field]:SetAlphaFromBoolean(isImportant)
end

---@param isImportant boolean secret — only ever fed to SetAlphaFromBoolean, never branched on
function TargetedSpellsMixin:ShowGlow(isImportant)
	local group = self:GetGroup()
	if group == nil then
		return
	end

	local glowFrame, glowWidth, glowHeight = self:GetGlowTarget()

	self:ShowGlowOn(glowFrame, glowWidth, glowHeight, group.GlowType, isImportant)
end

function TargetedSpellsMixin:GetSpellId()
	return self.spellId
end

---@param texture number|string?
function TargetedSpellsMixin:SetIconTexture(texture)
	self.Icon:SetTexture(texture)
end

function TargetedSpellsMixin:SetSpellId(spellId)
	self.spellId = spellId
	local texture = spellId and C_Spell.GetSpellTexture(spellId) or GetRandomIcon()
	self:SetIconTexture(texture)
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
	self.boundBarParent = nil
	self:ClearAllPoints()

	self.wasInterrupted = false
	self.doNotHideBefore = nil
	self.InterruptIcon:Hide()
	self.Icon:SetDesaturated(false)

	self:HideGlow()

	self.layoutOverride = nil

	self:Hide()
end

function TargetedSpellsMixin:SetFont()
end

function TargetedSpellsMixin:SetShowDuration(showDuration)
end

function TargetedSpellsMixin:SetDuration(duration)
	local alpha = duration:EvaluateRemainingDuration(Private.Utils.IsLongCastCurve)
	self:SetAlpha(alpha)
	self.Bar:SetValue(alpha)

	return alpha
end

-- Apply filter alpha without branching on secret booleans.
---@param info SpellCastInfo
---@param durationAlpha number
function TargetedSpellsMixin:ApplyCastAlpha(info, durationAlpha)
	local group = self:GetGroup()
	local onlyImportant = group ~= nil and group.OnlyImportant

	-- alpha to show when the cast passes the filter; a secret value when OnlyImportant
	local shownAlpha = durationAlpha
	if onlyImportant then
		shownAlpha = C_CurveUtil.EvaluateColorValueFromBoolean(self:IsSpellImportant(), 0, durationAlpha)
	end

	local targetName = UnitSpellTargetName(info.unit)
	local wantsPlayer = group ~= nil and group.Filter[Private.Enum.TargetClass.Player]
	local wantsPartyMember = group ~= nil and group.Filter[Private.Enum.TargetClass.PartyMember]

	if targetName ~= nil and wantsPlayer and not wantsPartyMember then
		self:SetAlphaFromBoolean(PlayerIsSpellTarget(info.unit, "player"), shownAlpha, 0)
	elseif targetName ~= nil and wantsPartyMember and not wantsPlayer then
		self:SetAlphaFromBoolean(PlayerIsSpellTarget(info.unit, "player"), 0, shownAlpha)
	elseif onlyImportant then
		self:SetAlphaFromBoolean(self:IsSpellImportant(), durationAlpha, 0)
	else
		self:SetAlpha(shownAlpha)
	end
end
