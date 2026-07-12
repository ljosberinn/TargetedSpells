---@type string, TargetedSpells
local addonName, Private = ...
local LibEditMode = LibStub("LibEditMode")
local LibSharedMedia = LibStub("LibSharedMedia-3.0")

local Element = Private.Enum.Element
local BarColorMode = Private.Enum.BarColorMode
local FontFlags = Private.Enum.FontFlags

---@class TargetedSpellsBarMixin : TargetedSpellsMixin
TargetedSpellsBarMixin = CreateFromMixins(TargetedSpellsMixin)

local whiteDefaultColor = CreateColor(1, 1, 1, 1)

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

function TargetedSpellsBarMixin:GetCoreElement()
	return Element.ProgressBar
end

function TargetedSpellsBarMixin:GetGlowTarget()
	local core = self:GetElement(Element.ProgressBar)

	if core == nil then
		return self.ProgressBar
	end

	return self.ProgressBar, core.width, core.height
end

function TargetedSpellsBarMixin:OnLoad()
	TargetedSpellsMixin.OnLoad(self)
	-- group-agnostic setup only; group-dependent styling lives in ApplyLayout,
	-- which runs on acquire once the Driver has assigned a group
	self.Bar:SetStatusBarTexture("")
	self.DurationCooldown:SetCountdownFormatter(Private.Utils.Formatter)
end

-- ── Free-positioning renderer (v4 offset consumption) ────────────────────────
-- The ProgressBar is the core: it fills the frame, and every other element is
-- placed at its stored CENTER→CENTER offset from it (see Migration's
-- reconstruction). This replaces the old flag-driven OnSizeChanged anchoring.
function TargetedSpellsBarMixin:PositionElements()
	local elements = self:GetElements()
	if elements == nil then
		return
	end

	self.ProgressBar:ClearAllPoints()
	self.ProgressBar:SetAllPoints(self)

	local background = elements[Element.Background]
	self.ProgressBar.Background:SetShown(background == nil or background.active ~= false)

	-- boxed elements: centered on the core, explicit size. TargetMarker manages
	-- its own visibility (raid-icon presence) via SetTargetMarker.
	local boxes = {
		{ region = self.Icon, element = elements[Element.Icon], applyShown = true },
		{ region = self.CustomElementsFrame.TargetMarker, element = elements[Element.TargetMarker], applyShown = false },
		{ region = self.DurationCooldown, element = elements[Element.DurationCooldown], applyShown = true },
	}

	for _, entry in ipairs(boxes) do
		local element = entry.element
		entry.region:ClearAllPoints()

		if element ~= nil then
			PixelUtil.SetPoint(entry.region, "CENTER", self.ProgressBar, "CENTER", element.x or 0, element.y or 0)
			PixelUtil.SetSize(entry.region, element.width, element.height)

			if entry.applyShown then
				entry.region:SetShown(element.active ~= false)
			end
		end
	end

	-- text elements: centered offset, auto-sizing unless maxWidth caps it (native
	-- ellipsis truncation). Visibility is driven at runtime (SetSpellId /
	-- UpdateTargetName / SetInterrupted); here we only place and colour them.
	local texts = {
		{ region = self.ProgressBar.SpellName, element = elements[Element.SpellName] },
		{ region = self.ProgressBar.TargetName, element = elements[Element.TargetName] },
		{ region = self.ProgressBar.InterruptSource, element = elements[Element.InterruptSource] },
	}

	for _, entry in ipairs(texts) do
		local element = entry.element
		entry.region:ClearAllPoints()

		if element ~= nil then
			PixelUtil.SetPoint(entry.region, "CENTER", self.ProgressBar, "CENTER", element.x or 0, element.y or 0)
			entry.region:SetJustifyH(element.justifyH or "LEFT")

			if element.maxWidth ~= nil and element.maxWidth > 0 then
				entry.region:SetWidth(element.maxWidth)
				entry.region:SetWordWrap(false)
			else
				entry.region:SetWidth(0)
			end

			if element.textColor ~= nil then
				local color = CreateColorFromHexString(element.textColor)
				entry.region:SetTextColor(color.r, color.g, color.b, color.a)
			end
		end
	end
end

-- SetSize(self, ...) fires this; the free layout is offset-based, so a resize is
-- just a reflow of the same offsets.
function TargetedSpellsBarMixin:OnSizeChanged()
	self:PositionElements()
end

-- Sizes and styles the frame from its group's Bar layout. Runs on acquire.
function TargetedSpellsBarMixin:ApplyLayout()
	local core = self:GetElement(Element.ProgressBar)
	if core == nil then
		return
	end

	PixelUtil.SetSize(self, core.width, core.height)
	self:PositionElements()

	self:SetForegroundBarTexture()
	self:SetBackgroundBarTexture()
	self:SetBackgroundBarColor()
	self:SetProgressBarColor()
	self:SetFont()

	local duration = self:GetElement(Element.DurationCooldown)
	if duration ~= nil then
		self.DurationCooldown:SetHideCountdownNumbers(not duration.showCountdown)
	end
end

function TargetedSpellsBarMixin:OnSettingChanged(key, flagIdOrValue, newBool)
	if self:GetElements() == nil then
		return
	end

	local Keys = Private.Settings.Keys.Party

	if key == Keys.Width or key == Keys.Height then
		self:ApplyLayout()
	elseif key == Keys.FeatureFlags then
		-- Show* toggles all reduce to element.active / layout in v4; reapply
		self:ApplyLayout()
		self:SetSpellId(self:GetSpellId())
		self:SetTargetMarker()
	elseif key == Keys.Font or key == Keys.FontSize or key == Keys.FontFlags then
		self:SetFont()
	elseif key == Keys.ForegroundBarTexture then
		self:SetForegroundBarTexture()
	elseif key == Keys.BackgroundBarTexture then
		self:SetBackgroundBarTexture()
	elseif key == Keys.GlowType then
		self:HideGlow()

		local group = self:GetGroup()
		if group ~= nil and group.GlowImportant then
			self:ShowGlow(self:IsSpellImportant(LibEditMode:IsInEditMode() and Private.Utils.RollDice()))
		end
	end
end

function TargetedSpellsBarMixin:SetForegroundBarTexture()
	local core = self:GetElement(Element.ProgressBar)
	if core == nil then
		return
	end

	self.ProgressBar:SetStatusBarTexture(LibSharedMedia:Fetch(LibSharedMedia.MediaType.STATUSBAR, core.barTexture))
end

function TargetedSpellsBarMixin:SetBackgroundBarTexture()
	local background = self:GetElement(Element.Background)
	if background == nil then
		return
	end

	self.ProgressBar.Background:SetTexture(
		LibSharedMedia:Fetch(LibSharedMedia.MediaType.BACKGROUND, background.backgroundTexture)
	)
end

function TargetedSpellsBarMixin:SetProgressBarColor()
	local core = self:GetElement(Element.ProgressBar)
	if core == nil then
		return
	end

	local color = CreateColorFromHexString(core.progressBarColor)
	self.ProgressBar:SetStatusBarColor(color.r, color.g, color.b, color.a)
end

function TargetedSpellsBarMixin:SetPreviewBarColor()
	local core = self:GetElement(Element.ProgressBar)
	if core == nil then
		return
	end

	if core.barColorMode == BarColorMode.Interruptibility then
		local hex = Private.Utils.RollDice() and core.interruptibleColor or core.uninterruptibleColor
		local color = CreateColorFromHexString(hex)

		self.ProgressBar:SetStatusBarColor(color.r, color.g, color.b, color.a)
	elseif core.barColorMode == BarColorMode.TargetClassColor then
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
	local core = self:GetElement(Element.ProgressBar)
	if core == nil then
		return
	end

	local hex = isInterruptible and core.interruptibleColor or core.uninterruptibleColor
	local color = CreateColorFromHexString(hex)

	self.ProgressBar:SetStatusBarColor(color.r, color.g, color.b, color.a)
end

function TargetedSpellsBarMixin:SetBackgroundBarColor()
	local background = self:GetElement(Element.Background)
	if background == nil then
		return
	end

	local color = CreateColorFromHexString(background.backgroundColor)
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
	local marker = self:GetElement(Element.TargetMarker)

	if marker == nil or marker.active == false then
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

-- v4 text auto-sizes; visibility is just active + whether a target exists (the
-- old width-splitting is gone — see the free-positioning note in the plan).
function TargetedSpellsBarMixin:UpdateTargetName(targetName)
	local element = self:GetElement(Element.TargetName)

	if targetName == nil or element == nil or element.active == false then
		self.ProgressBar.TargetName:Hide()
	else
		self.ProgressBar.TargetName:SetText(targetName)
		self.ProgressBar.TargetName:Show()
	end
end

function TargetedSpellsBarMixin:PostCreate(info, OnCooldownDoneCallback)
	-- the Driver assigns the group before PostCreate; size/style from it now
	self.unit = info and info.unit or nil
	self:ApplyLayout()
	self:SetTargetMarker()

	local group = self:GetGroup()
	local core = self:GetElement(Element.ProgressBar)

	if info == nil then
		self:UpdateTargetName(GetPlayerName())
		self:SetPreviewBarColor()

		return
	end

	self:SetStartTime(info.startTime)
	self:SetSpellId(info.spellId)
	self:SetId(info.id)
	local durationAlpha = self:SetDuration(info.duration)
	local targetName = UnitSpellTargetName(info.unit)

	-- The non-secret part of the filter (Nobody vs targeted) was decided by the
	-- Driver before acquisition; the Player/PartyMember distinction + OnlyImportant
	-- are secret and resolved here via the frame alpha.
	self:ApplyCastAlpha(info, durationAlpha)
	self.Bar:SetValue(self:GetAlpha())

	if group ~= nil and group.GlowImportant then
		self:ShowGlow(self:IsSpellImportant())
	end

	self.ProgressBar:SetTimerDuration(info.duration, Enum.StatusBarInterpolation.None, info.isChannel and 1 or 0)
	self:UpdateTargetName(targetName)

	local targetNameElement = self:GetElement(Element.TargetName)
	local useClassColorForName = targetNameElement ~= nil and targetNameElement.useClassColor
	local barColorMode = core ~= nil and core.barColorMode

	---@type colorRGB?
	local color = nil
	local isClassColor = false

	if useClassColorForName then
		local targetClass = UnitSpellTargetClass(info.unit)

		if targetClass ~= nil then
			color = C_ClassColor.GetClassColor(targetClass)
			isClassColor = color ~= nil
		end
	end

	if barColorMode == BarColorMode.Interruptibility then
		local uninterruptible = select(8, UnitCastingInfo(info.unit))

		if uninterruptible == nil then
			uninterruptible = select(7, UnitChannelInfo(info.unit))
		end

		if uninterruptible ~= nil then
			self.ProgressBar:GetStatusBarTexture():SetVertexColorFromBoolean(
				uninterruptible,
				CreateColorFromHexString(core.uninterruptibleColor),
				CreateColorFromHexString(core.interruptibleColor)
			)
		end
	end

	if color == nil then
		if barColorMode == BarColorMode.TargetClassColor then
			local background = self:GetElement(Element.Background)
			local bg = CreateColorFromHexString(background and background.backgroundColor or "FF000000")
			color = CreateColor(bg.r + (1 - bg.r) * 0.6, bg.g + (1 - bg.g) * 0.6, bg.b + (1 - bg.b) * 0.6, 0.5)
		else
			color = whiteDefaultColor
		end
	end

	if barColorMode == BarColorMode.TargetClassColor then
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

	local interruptSource = self:GetElement(Element.InterruptSource)

	if interruptSource ~= nil and interruptSource.active then
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
	local element = self:GetElement(Element.SpellName)

	if element ~= nil and element.active ~= false then
		self.ProgressBar.SpellName:SetText(spellId == nil and addonName or C_Spell.GetSpellName(spellId))
		self.ProgressBar.SpellName:Show()
	else
		self.ProgressBar.SpellName:Hide()
	end

	TargetedSpellsMixin.SetSpellId(self, spellId)
end

function TargetedSpellsBarMixin:SetDuration(duration)
	local element = self:GetElement(Element.DurationCooldown)
	self:SetShowDuration(element ~= nil and element.showCountdown)
	self.DurationCooldown:SetCooldownFromDurationObject(duration)
	self.ProgressBar:SetTimerDuration(duration)

	return TargetedSpellsMixin.SetDuration(self, duration)
end

-- Each text element carries its own font in v4; the cooldown countdown carries a
-- separate countdown font. One loop applies them all.
function TargetedSpellsBarMixin:SetFont()
	local elements = self:GetElements()
	if elements == nil then
		return
	end

	local targets = {
		{ fontString = self.ProgressBar.SpellName, element = elements[Element.SpellName] },
		{ fontString = self.ProgressBar.TargetName, element = elements[Element.TargetName] },
		{ fontString = self.ProgressBar.InterruptSource, element = elements[Element.InterruptSource] },
		{
			fontString = self.DurationCooldown:GetCountdownFontString(),
			element = elements[Element.DurationCooldown],
			countdown = true,
		},
	}

	for _, target in ipairs(targets) do
		local element = target.element

		if element ~= nil then
			local font = target.countdown and element.countdownFont or element.font
			local fontSize = target.countdown and element.countdownFontSize or element.fontSize
			local fontFlags = target.countdown and element.countdownFontFlags or element.fontFlags

			Private.Utils.SafelySetFont(
				Private.Enum.FrameKind.Party,
				target.fontString,
				font,
				fontSize,
				fontFlags[FontFlags.OUTLINE] and "OUTLINE" or ""
			)

			local hasShadow = fontFlags[FontFlags.SHADOW]
			target.fontString:SetShadowOffset(hasShadow and 1 or 0, hasShadow and -1 or 0)

			if hasShadow then
				target.fontString:SetShadowColor(0, 0, 0, 1)
			end
		end
	end
end
