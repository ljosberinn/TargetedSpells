---@type string, TargetedSpells
local addonName, Private = ...
local LibSharedMedia = LibStub("LibSharedMedia-3.0")

local Element = Private.Enum.Element
local BarColorMode = Private.Enum.BarColorMode
local FontFlags = Private.Enum.FontFlags

---@class TargetedSpellsBarMixin : TargetedSpellsMixin
TargetedSpellsBarMixin = CreateFromMixins(TargetedSpellsMixin)

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

---@param region FontString
---@param maxWidth number?
local function ApplyTextWidth(region, maxWidth)
	if maxWidth ~= nil and maxWidth > 0 then
		region:SetWidth(maxWidth)
		region:SetWordWrap(false)
	else
		region:SetWidth(0)
	end
end

---@param frame TargetedSpellsBarMixin
---@param path string[]
---@return any
local function ResolveRegion(frame, path)
	local region = frame

	for index = 1, #path do
		region = region[path[index]]
	end

	return region
end

local BAR_BOX_REGIONS = {
	{ tag = Element.Icon,             path = { "Icon" },                                   applyShown = true },
	{ tag = Element.TargetMarker,     path = { "CustomElementsFrame", "TargetMarker" },    applyShown = false },
	{ tag = Element.InterruptShield,  path = { "CustomElementsFrame", "InterruptShield" }, applyShown = false },
	{ tag = Element.DurationCooldown, path = { "DurationCooldown" },                       applyShown = true },
}

local BAR_TEXT_REGIONS = {
	{ tag = Element.SpellName,       path = { "ProgressBar", "SpellName" } },
	{ tag = Element.TargetName,      path = { "ProgressBar", "TargetName" } },
	{ tag = Element.InterruptSource, path = { "ProgressBar", "InterruptSource" } },
}

local BAR_FONT_REGIONS = {
	BAR_TEXT_REGIONS[1],
	BAR_TEXT_REGIONS[2],
	BAR_TEXT_REGIONS[3],
	{ tag = Element.DurationCooldown, countdown = true },
}

function TargetedSpellsBarMixin:GetCoreElement()
	return Element.ProgressBar
end

function TargetedSpellsBarMixin:GetGlowFrame()
	return self.ProgressBar
end

function TargetedSpellsBarMixin:GetGlowTarget()
	local core = self:GetElement(Element.ProgressBar)

	if core == nil then
		return self.ProgressBar
	end

	local layout = Private.Utils.ComputeBarLayout(self:GetElements())
	return self.ProgressBar, layout.barWidth, core.height
end

function TargetedSpellsBarMixin:OnLoad()
	TargetedSpellsMixin.OnLoad(self)
	self.Bar:SetStatusBarTexture("")
	self.countdownFormatter = Private.Utils.CreateCountdownFormatter()
	self.DurationCooldown:SetCountdownFormatter(self.countdownFormatter)
end

function TargetedSpellsBarMixin:PositionElements()
	local elements = self:GetElements()
	if elements == nil then
		return
	end

	local layout = Private.Utils.ComputeBarLayout(elements)

	local core = layout[Element.ProgressBar]
	self.ProgressBar:ClearAllPoints()
	PixelUtil.SetPoint(self.ProgressBar, "CENTER", self, "CENTER", core.centerX, core.centerY)
	PixelUtil.SetSize(self.ProgressBar, core.width, core.height)

	local background = elements[Element.Background]
	self.ProgressBar.Background:SetShown(background == nil or background.active ~= false)

	for _, entry in ipairs(BAR_BOX_REGIONS) do
		local region = ResolveRegion(self, entry.path)
		region:ClearAllPoints()
		local geom = layout[entry.tag]

		if geom ~= nil then
			PixelUtil.SetPoint(region, "CENTER", self, "CENTER", geom.centerX, geom.centerY)
			PixelUtil.SetSize(region, geom.width, geom.height)

			if entry.applyShown then
				region:SetShown(elements[entry.tag].active ~= false)
			end
		elseif entry.applyShown then
			region:SetShown(false)
		end
	end

	for _, entry in ipairs(BAR_TEXT_REGIONS) do
		local region = ResolveRegion(self, entry.path)
		region:ClearAllPoints()
		local geom = layout[entry.tag]

		if geom ~= nil then
			region:SetJustifyH(geom.justifyH)

			if entry.tag == Element.SpellName then
				self:ApplySpellNameWidth()
			else
				ApplyTextWidth(region, geom.maxWidth)
			end

			PixelUtil.SetPoint(region, geom.justifyH, self, "CENTER", geom.edgeX, geom.centerY)

			local element = elements[entry.tag]
			if not element.useClassColor then
				Private.Utils.ApplyElementTextColor(region, element)
			end
		end
	end
end

function TargetedSpellsBarMixin:OnSizeChanged()
	self:PositionElements()
end

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

	local border = self:GetElement(Element.Border)
	self:ApplyBorderStyle(border ~= nil and border.active ~= false and border.borderTexture or "None")

	local duration = self:GetElement(Element.DurationCooldown)
	if duration ~= nil then
		self.DurationCooldown:SetHideCountdownNumbers(duration.active == false)
		Private.Utils.ApplyFractionThreshold(self.countdownFormatter, duration.fractionThreshold)
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

	if core == nil or core.barColorMode ~= BarColorMode.Interruptibility then
		return
	end

	local hex = isInterruptible and core.interruptibleColor or core.uninterruptibleColor
	local color = CreateColorFromHexString(hex)

	self.ProgressBar:SetStatusBarColor(color.r, color.g, color.b, color.a)
end

function TargetedSpellsBarMixin:AdjustInterruptShield(isInterruptible)
	local shield = self:GetElement(Element.InterruptShield)

	if shield == nil or not shield.active then
		return
	end

	self.CustomElementsFrame.InterruptShield:Show()
	self.CustomElementsFrame.InterruptShield:SetAlphaFromBoolean(secretwrap(not isInterruptible))
end

function TargetedSpellsBarMixin:SetBackgroundBarColor()
	local background = self:GetElement(Element.Background)
	if background == nil then
		return
	end

	local color = CreateColorFromHexString(background.backgroundColor)
	self.ProgressBar.Background:SetVertexColor(color.r, color.g, color.b, color.a)
end

function TargetedSpellsBarMixin:ApplyBorderStyle(styleName)
	local elements = self:GetElements()
	if elements == nil then
		return
	end

	local border = elements[Element.Border]
	local core = elements[Element.ProgressBar]
	local layout = Private.Utils.ComputeBarLayout(elements)

	Private.Utils.ApplyBorderStyle(
		self.ProgressBar --[[@as TargetedSpellsBorderFrame]],
		styleName,
		{ width = layout.barWidth, height = (core and core.height) or 0, offsetX = 0, offsetY = 0 },
		border and border.borderSize,
		border and border.borderColor
	)
end

function TargetedSpellsBarMixin:SetShowDuration(showDuration)
	self.DurationCooldown:SetHideCountdownNumbers(not showDuration)
end

function TargetedSpellsBarMixin:Reset()
	TargetedSpellsMixin.Reset(self)

	self.ProgressBar.InterruptSource:SetText("")
	self.ProgressBar.InterruptSource:Hide()

	self.CustomElementsFrame.InterruptShield:SetAlpha(secretwrap(1))
	self.CustomElementsFrame.InterruptShield:Hide()

	self.DurationCooldown:Clear()
	self.DurationCooldown:SetScript("OnCooldownDone", nil)
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

function TargetedSpellsBarMixin:ApplySpellNameWidth()
	local element = self:GetElement(Element.SpellName)
	local maxWidth = nil

	if element ~= nil and self.ProgressBar.TargetName:IsShown() then
		maxWidth = element.maxWidth
	end

	ApplyTextWidth(self.ProgressBar.SpellName, maxWidth)
end

---@param targetName string? may be a secret value
---@param classColor colorRGB? may be a secret value
function TargetedSpellsBarMixin:UpdateTargetName(targetName, classColor)
	local element = self:GetElement(Element.TargetName)

	if targetName == nil or element == nil or element.active == false then
		self.ProgressBar.TargetName:Hide()
	else
		Private.Utils.ApplyElementText(self.ProgressBar.TargetName, element, targetName, classColor)
		self.ProgressBar.TargetName:Show()
	end

	self:ApplySpellNameWidth()
end

function TargetedSpellsBarMixin:PostCreate(info, OnCooldownDoneCallback)
	self:SetUnit(info and info.unit or nil)
	self:ApplyLayout()
	self:SetTargetMarker()

	local group = self:GetGroup()
	local core = self:GetElement(Element.ProgressBar)

	if info == nil then
		self:UpdateTargetName(GetPlayerName(), GetPlayerClassColor())
		self:SetPreviewBarColor()

		return
	end

	self:SetStartTime(info.startTime)
	self:SetSpellId(info.spellId)
	self:SetId(info.id)
	local durationAlpha = self:SetDuration(info.duration)
	local targetName = UnitSpellTargetName(info.unit)

	self:ApplyCastAlpha(info, durationAlpha)
	self.Bar:SetValue(self:GetAlpha())

	if group ~= nil and group.GlowImportant then
		self:ShowGlow(self:IsSpellImportant())
	end

	self.ProgressBar:SetTimerDuration(info.duration, Enum.StatusBarInterpolation.None, info.isChannel and 1 or 0)

	local targetNameElement = self:GetElement(Element.TargetName)
	local useClassColorForName = targetNameElement ~= nil and targetNameElement.useClassColor
	local barColorMode = core ~= nil and core.barColorMode
	local useClassColorForBar = barColorMode == BarColorMode.TargetClassColor

	---@type colorRGB?
	local classColor = nil

	if useClassColorForName or useClassColorForBar then
		local targetClass = UnitSpellTargetClass(info.unit)

		if targetClass then
			classColor = C_ClassColor.GetClassColor(targetClass)
		end
	end

	self:UpdateTargetName(targetName, not useClassColorForBar and classColor or nil)

	local shield = self:GetElement(Element.InterruptShield)
	local shieldActive = shield ~= nil and shield.active

	if barColorMode == BarColorMode.Interruptibility or shieldActive then
		local uninterruptible = select(8, UnitCastingInfo(info.unit))

		if uninterruptible == nil then
			uninterruptible = select(7, UnitChannelInfo(info.unit))
		end

		if uninterruptible ~= nil then
			if barColorMode == BarColorMode.Interruptibility then
				self.ProgressBar:GetStatusBarTexture():SetVertexColorFromBoolean(
					uninterruptible,
					CreateColorFromHexString(core.uninterruptibleColor),
					CreateColorFromHexString(core.interruptibleColor)
				)
			end

			if shieldActive then
				self.CustomElementsFrame.InterruptShield:Show()
				self.CustomElementsFrame.InterruptShield:SetAlphaFromBoolean(uninterruptible)
			end
		end
	end

	if useClassColorForBar then
		if classColor then
			self.ProgressBar:SetStatusBarColor(classColor.r, classColor.g, classColor.b, 0.75)
		else
			local background = self:GetElement(Element.Background)
			local bg = CreateColorFromHexString(background and background.backgroundColor or "FF000000")

			self.ProgressBar:SetStatusBarColor(
				bg.r + (1 - bg.r) * 0.6,
				bg.g + (1 - bg.g) * 0.6,
				bg.b + (1 - bg.b) * 0.6,
				0.5
			)
		end
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
		Private.Utils.ApplyElementText(self.ProgressBar.InterruptSource, interruptSource, name, color)
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
	self:SetShowDuration(element ~= nil and element.active ~= false)
	self.DurationCooldown:SetCooldownFromDurationObject(duration)
	self.ProgressBar:SetTimerDuration(duration)

	return TargetedSpellsMixin.SetDuration(self, duration)
end

function TargetedSpellsBarMixin:SetFont()
	local elements = self:GetElements()
	if elements == nil then
		return
	end

	for _, target in ipairs(BAR_FONT_REGIONS) do
		local element = elements[target.tag]

		if element ~= nil then
			local font = target.countdown and element.countdownFont or element.font
			local fontSize = target.countdown and element.countdownFontSize or element.fontSize
			local fontFlags = target.countdown and element.countdownFontFlags or element.fontFlags

			local fontString = target.countdown and self.DurationCooldown:GetCountdownFontString()
				or ResolveRegion(self, target.path)

			local SetFont = target.countdown and Private.Utils.SafelySetFont or Private.Utils.SetFontIfChanged

			SetFont(fontString, font, fontSize, fontFlags[FontFlags.OUTLINE] and "OUTLINE" or "")

			local hasShadow = fontFlags[FontFlags.SHADOW]
			fontString:SetShadowOffset(hasShadow and 1 or 0, hasShadow and -1 or 0)

			if hasShadow then
				fontString:SetShadowColor(0, 0, 0, 1)
			end
		end
	end
end
