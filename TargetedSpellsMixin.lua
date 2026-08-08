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

-- Star4 is the one glow whose size is baked in at construction rather than re-derived per
-- start, so a frame re-acquired into a group with a different core size needs this applied
-- again. Width/height come from the group's saved element sizes, never from GetSize().
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

-- Which field each glow type parks its object on. The glow stamp below and its teardown key
-- off this rather than probing all four fields on every release.
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

-- The unit whose cast this frame renders. Set on acquire (PostCreate), cleared on
-- Reset. The owning GroupController keys its per-unit lookups off this, so it has to
-- be set for every live frame — demo frames pass their own placeholder unit.
function TargetedSpellsMixin:SetUnit(unit)
	self.unit = unit
end

function TargetedSpellsMixin:GetUnit()
	return self.unit
end

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

-- The frame the glow attaches to, without its dimensions. Split out because stopping a
-- glow needs only the frame, and deriving the bar's glow width means computing a full bar
-- layout — work HideGlow used to do and throw away on every release.
function TargetedSpellsMixin:GetGlowFrame()
	return self --[[@as GlowTargetFrame]]
end

function TargetedSpellsMixin:GetGlowTarget()
	local width, height = self:GetCoreSize()
	return self:GetGlowFrame(), width, height
end

-- ── Glow lifecycle ───────────────────────────────────────────────────────────
-- The glow a frame carries is stamped with the type and the dimensions it was built for. A
-- pooled frame is normally re-acquired into the group it came from, so that glow is already
-- the one it needs — and building a PixelGlow means drawing 8 textures, 2 masks and a
-- background from three pools and wiring them together. Releasing them on every cast end only
-- to re-acquire them on the next was the largest single cost in the frame lifecycle.
--
-- So HideGlow parks; ShowGlow re-shows a matching glow, re-sizes a mismatched one, and only
-- returns objects to their pools when the group's GlowType itself changed.

-- Parks the glow: hidden, animation stopped, objects retained. A hidden frame receives no
-- OnUpdate and PixelGlow's PUpdate additionally guards on IsShown(), so a parked glow costs
-- nothing while the frame sits in the pool.
--
-- The stamp is deliberately left in place — it is how the next ShowGlow recognises what the
-- frame already has. Nothing else reads these regions, so nothing else can invalidate it.
-- Parks the glow on one specific frame. Split out from HideGlow because a template may carry
-- more than one glow target (the icon+duration template glows each icon cell), and the
-- appliedGlow* stamp that makes a re-acquire cheap lives on the glowing frame itself — so
-- "which frame" cannot be a single value for every template.
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

	-- ProcGlow stops its own two animations from its OnHide script
	glow:Hide()
end

function TargetedSpellsMixin:HideGlow()
	self:HideGlowOn(self:GetGlowFrame())
end

-- Builds/re-shows the glow on one specific frame at a known size. The counterpart to
-- HideGlowOn; see its note for why the frame is a parameter. `glowType` is passed in rather
-- than re-read from the group so a multi-target caller resolves it once.
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

	-- Width/height are the group's saved element sizes (never GetSize()), so they are plain
	-- numbers and comparing them is secret-safe.
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

		-- ProcGlow replays its start animation from its OnShow script
		glow:Show()
	else
		-- A different type must go back to its pool or its objects stay stranded on this frame
		-- for the session. A size change must not: every *_Start below re-sizes in place.
		if previousType ~= nil and previousType ~= glowType then
			if previousType == Private.Enum.GlowType.Star4 then
				-- Star4 is not pooled (one per glow frame, created on demand), so it is only hidden
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

-- Writes the icon art without touching the stored spell id. Split out from SetSpellId so a
-- template rendering the icon more than once (icon+duration) can mirror it in one override,
-- and so callers that restore a texture go through the template rather than poking self.Icon.
---@param texture number|string?
function TargetedSpellsMixin:SetIconTexture(texture)
	self.Icon:SetTexture(texture)
end

function TargetedSpellsMixin:SetSpellId(spellId)
	self.spellId = spellId
	local texture = spellId and C_Spell.GetSpellTexture(spellId) or GetRandomIcon()
	self:SetIconTexture(texture)
end

-- `name` and `color` are part of the shared contract but only the derived mixins render
-- them; the base owns the state and visuals common to both templates.
function TargetedSpellsMixin:SetInterrupted(name, color)
	self.wasInterrupted = true
	self.doNotHideBefore = GetTime() + 0.95
	self.InterruptIcon:Show()
	self.Icon:SetDesaturated(true)
	self:SetShowDuration(false)
	self:HideGlow()
end

-- ── Pool contract ────────────────────────────────────────────────────────────
-- What a released frame must guarantee, and deliberately nothing beyond it:
--   (1) invisible and detached — hidden, unparented, unanchored, nothing animating
--   (2) no per-cast visual state that the next acquire does not itself overwrite
--   (3) no live script still bound to the cast that just ended
--
-- All three acquire paths — GroupController:Acquire, Designer:PlayDemoCast and
-- EditMode:LoopFrame — pass a non-nil `info`, so every acquire runs ApplyLayout and the full
-- PostCreate. Anything those re-apply unconditionally (size, textures, colours, fonts,
-- border, alpha, unit, id, startTime, target marker, target name) is therefore NOT repeated
-- here: repeating it renders nowhere, since a released frame is hidden and never shown again
-- before ApplyLayout runs.
--
-- Every line below names the clause it serves. If you cannot name one, it does not belong —
-- and if you can, do not delete it.
function TargetedSpellsMixin:Reset()
	-- (1) detach from the group's layout spine. The spine-binding stamp goes with it: the
	-- next acquire must rebind rather than trust a parenting this just undid.
	self:SetParent(UIParent)
	self.Bar:ClearAllPoints()
	self.Bar:SetParent(self)
	self.boundBarParent = nil
	self:ClearAllPoints()

	-- (2) interrupt state. Only SetInterrupted ever sets these, and nothing on the acquire
	-- path clears them, so Reset is the only place they can be unset.
	self.wasInterrupted = false
	self.doNotHideBefore = nil
	self.InterruptIcon:Hide()
	self.Icon:SetDesaturated(false)

	-- (1) stops the glow animating. Also (2): ShowGlow runs only when the group has
	-- GlowImportant, so a frame re-acquired into a group without it would keep this one.
	self:HideGlow()

	-- (2) the designer previews from an injected scratch table and never clears it on
	-- release; a frame that kept it would render a live cast from unsaved designer edits.
	-- The group ref is left intact so derived Reset()s can still read it.
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
