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

-- `kind` (the XML KeyValue, "self"/"party") survives in v4 only as "which pool
-- do I return to". Settings resolution goes through GetGroup / the element layout
-- below, not through kind.
function TargetedSpellsMixin:GetKind()
	return self.kind
end

-- ── Group + layout resolution (Phase 3 seam) ─────────────────────────────────
-- A frame belongs to a group (assigned by the Driver on acquire). It renders its
-- element layout from that group — unless a scratch layout is injected, which is
-- how the designer previews unsaved edits on a frame that belongs to no group
-- (v4 plan §Designer / challenge #3a). Everything downstream resolves settings
-- through these accessors rather than reaching for Settings.Self/Party.

function TargetedSpellsMixin:SetGroup(group)
	self.group = group
end

function TargetedSpellsMixin:GetGroup()
	return self.group
end

-- Designer preview: render from an injected scratch Elements table instead of the
-- group's saved layout. Set while previewing, cleared on release / apply.
function TargetedSpellsMixin:SetLayoutOverride(elements)
	self.layoutOverride = elements
end

function TargetedSpellsMixin:ClearLayoutOverride()
	self.layoutOverride = nil
end

-- The element layout this frame renders from: the injected override if present,
-- otherwise the frame's group's Elements. Nil only for an unassigned frame.
---@return table<Element, table<string, any>>?
function TargetedSpellsMixin:GetElements()
	if self.layoutOverride ~= nil then
		return self.layoutOverride
	end

	return self.group and self.group.Elements
end

-- One element's resolved settings table, or nil if unavailable.
---@param element Element
---@return table<string, any>?
function TargetedSpellsMixin:GetElement(element)
	local elements = self:GetElements()
	return elements and elements[element]
end

-- The template's core element tag (Icon frames → Icon, Bar frames → ProgressBar).
-- Overridden per derived mixin; its width/height are what the old container
-- Width/Height controlled.
---@return Element?
function TargetedSpellsMixin:GetCoreElement()
	return nil
end

-- Core element's width/height from the resolved layout (glow sizing, footprint).
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

function TargetedSpellsMixin:GetGlowTarget()
	local width, height = self:GetCoreSize()
	return self, width, height
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
	local group = self:GetGroup()
	if group == nil then
		return
	end

	local glowType = group.GlowType
	local glowFrame, glowWidth, glowHeight = self:GetGlowTarget()

	if glowType == Private.Enum.GlowType.Star4 then
		if glowFrame._Star4 == nil then
			glowFrame._Star4 = CreateStar4Glow(glowFrame, glowWidth, glowHeight)
		end

		glowFrame._Star4:Show()
		glowFrame._Star4.Inner:Show()
		glowFrame._Star4.Outer:Show()
		glowFrame._Star4.Animation:Play()

		glowFrame._Star4:SetAlphaFromBoolean(isImportant)
	elseif glowType == Private.Enum.GlowType.PixelGlow then
		Private.Glows.PixelGlow_Start(glowFrame, glowWidth, glowHeight)

		glowFrame._PixelGlow:SetAlphaFromBoolean(isImportant)
	elseif glowType == Private.Enum.GlowType.AutoCastGlow then
		Private.Glows.AutoCastGlow_Start(glowFrame, glowWidth, glowHeight)

		glowFrame._AutoCastGlow:SetAlphaFromBoolean(isImportant)
	elseif glowType == Private.Enum.GlowType.ProcGlow then
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
	-- drop the designer preview override; the group ref is left intact so derived
	-- Reset()s can still read it, and it is overwritten on the next acquire
	self.layoutOverride = nil
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

-- Applies the frame's alpha for a cast, secret-safe. Combines the duration alpha,
-- the OnlyImportant behaviour, and the Player/PartyMember filter distinction. The
-- latter two hinge on *secret* booleans (IsSpellImportant / PlayerIsSpellTarget)
-- that cannot be used in a Lua `if`, so they are only ever fed to `*FromBoolean`.
-- Player-vs-PartyMember can't be decided in the Driver before acquisition for the
-- same reason, so the group offers a targeted cast to both classes and the frame
-- resolves visibility here.
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
		-- player-only group: visible only when the player is the target
		self:SetAlphaFromBoolean(PlayerIsSpellTarget(info.unit, "player"), shownAlpha, 0)
	elseif targetName ~= nil and wantsPartyMember and not wantsPlayer then
		-- party-member-only group: visible only when the player is NOT the target
		self:SetAlphaFromBoolean(PlayerIsSpellTarget(info.unit, "player"), 0, shownAlpha)
	elseif onlyImportant then
		-- no target distinction, but shownAlpha is secret → must route through *FromBoolean
		self:SetAlphaFromBoolean(self:IsSpellImportant(), durationAlpha, 0)
	else
		self:SetAlpha(shownAlpha)
	end
end
