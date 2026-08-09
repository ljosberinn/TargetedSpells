---@type string, TargetedSpells
local _, Private = ...

---@class TargetedSpellsIconMixin : TargetedSpellsMixin
TargetedSpellsIconMixin = CreateFromMixins(TargetedSpellsMixin)

function TargetedSpellsIconMixin:GetCoreElement()
	return Private.Enum.Element.Icon
end

function TargetedSpellsIconMixin:OnLoad()
	TargetedSpellsMixin.OnLoad(self)
	self.Bar:SetStatusBarTexture("")
	self.countdownFormatter = Private.Utils.CreateCountdownFormatter()
	self.Cooldown:SetCountdownFormatter(self.countdownFormatter)
	self.Cooldown:SetCountdownFont("GameFontHighlightHugeOutline")
	self:HideGlow()
end

function TargetedSpellsIconMixin:ApplyLayout()
	local iconElement = self:GetElement(Private.Enum.Element.Icon)
	if iconElement == nil then
		return
	end

	PixelUtil.SetSize(self, iconElement.width, iconElement.height)
	self:SetFont()
	self:StyleInterruptSource()

	local overlay = self:GetElement(Private.Enum.Element.Overlay)
	self.Overlay:SetShown(overlay == nil or overlay.active ~= false)

	local border = self:GetElement(Private.Enum.Element.Border)
	self:ApplyBorderStyle(border ~= nil and border.active ~= false and border.borderTexture or "None")

	local cooldown = self:GetElement(Private.Enum.Element.Cooldown)
	if cooldown ~= nil then
		self:SetShowDuration(cooldown.showCountdown ~= false)
		self.Cooldown:SetDrawSwipe(cooldown.showSwipe)
		Private.Utils.ApplyFractionThreshold(self.countdownFormatter, cooldown.fractionThreshold)
	end
end

function TargetedSpellsIconMixin:ApplyBorderStyle(styleName)
	local border = self:GetElement(Private.Enum.Element.Border)
	local iconElement = self:GetElement(Private.Enum.Element.Icon)
	if iconElement == nil then
		return
	end

	Private.Utils.ApplyBorderStyle(
		self --[[@as TargetedSpellsBorderFrame]],
		styleName,
		{ width = iconElement.width, height = iconElement.height, offsetX = 0, offsetY = 0 },
		border and border.borderSize,
		border and border.borderColor
	)
end

function TargetedSpellsIconMixin:SetInterrupted(name, color)
	TargetedSpellsMixin.SetInterrupted(self, name, color)
	self.Cooldown:SetDrawSwipe(false)

	if name == nil then
		return
	end

	local interruptSource = self:GetElement(Private.Enum.Element.InterruptSource)

	if interruptSource ~= nil and interruptSource.active then
		self.InterruptSource:SetText(name)

		if color ~= nil then
			self.InterruptSource:SetTextColor(color.r, color.g, color.b)
		end

		self.InterruptSource:Show()
	else
		self.InterruptSource:Hide()
	end
end

function TargetedSpellsIconMixin:SetShowDuration(showDuration)
	self.Cooldown:SetHideCountdownNumbers(not showDuration)
end

--- shamelessly ~~stolen~~ repurposed from WeakAuras2
function TargetedSpellsIconMixin:OnSizeChanged()
	local iconElement = self:GetElement(Private.Enum.Element.Icon)
	if iconElement == nil then
		return
	end

	local coordinates = { 0, 0, 0, 1, 1, 0, 1, 1 }
	local aspectRatio = iconElement.width / iconElement.height

	local xRatio = aspectRatio < 1 and aspectRatio or 1
	local yRatio = aspectRatio > 1 and 1 / aspectRatio or 1

	for i = 1, #coordinates, 1 do
		local coordinate = coordinates[i]

		if i % 2 == 1 then
			coordinates[i] = (coordinate - 0.5) * (xRatio / iconElement.iconZoom) + 0.5
		else
			coordinates[i] = (coordinate - 0.5) * (yRatio / iconElement.iconZoom) + 0.5
		end
	end

	self.Icon:SetTexCoord(unpack(coordinates))

	local topleftRelativePoint = select(2, self.Overlay:GetPointByName("TOPLEFT"))
	local bottomrightRelativePoint = select(2, self.Overlay:GetPointByName("BOTTOMRIGHT"))
	self.Overlay:ClearAllPoints()

	do
		local fifteenPercent = 0.15 * iconElement.width
		PixelUtil.SetPoint(self.Overlay, "TOPLEFT", topleftRelativePoint, "TOPLEFT", -fifteenPercent, fifteenPercent)
	end

	do
		local fifteenPercent = 0.15 * iconElement.height
		PixelUtil.SetPoint(
			self.Overlay,
			"BOTTOMRIGHT",
			bottomrightRelativePoint,
			"BOTTOMRIGHT",
			fifteenPercent,
			-fifteenPercent
		)
	end
end

function TargetedSpellsIconMixin:PostCreate(info, OnCooldownDoneCallback)
	if info == nil then
		return
	end

	self:ApplyLayout()

	local group = self:GetGroup()

	self:SetUnit(info.unit)
	self.Cooldown:SetCooldownFromDurationObject(info.duration)

	self:SetSpellId(info.spellId)

	local durationAlpha = self:SetDuration(info.duration)
	self:ApplyCastAlpha(info, durationAlpha)

	self.Bar:SetValue(self:GetAlpha())

	if group ~= nil and group.GlowImportant then
		self:ShowGlow(self:IsSpellImportant())
	end

	self:SetStartTime(info.startTime)
	self:SetId(info.id)

	if OnCooldownDoneCallback ~= nil then
		self.OnCooldownDoneCallback = OnCooldownDoneCallback
		self.OnCooldownDoneClosure = GenerateClosure(OnCooldownDoneCallback, info)
		self.Cooldown:SetScript("OnCooldownDone", self.OnCooldownDoneClosure)
	end
end

function TargetedSpellsIconMixin:Reset()
	self.Cooldown:Clear()
	self.Cooldown:SetScript("OnCooldownDone", nil)

	self.InterruptSource:SetText()
	self.InterruptSource:Hide()

	local cooldown = self:GetElement(Private.Enum.Element.Cooldown)

	TargetedSpellsMixin.Reset(self)

	if cooldown ~= nil then
		self:SetShowDuration(cooldown.showCountdown ~= false)
		self.Cooldown:SetDrawSwipe(cooldown.showSwipe)
	end
end

function TargetedSpellsIconMixin:StyleInterruptSource()
	local element = self:GetElement(Private.Enum.Element.InterruptSource)
	if element == nil then
		return
	end

	local justifyH = element.justifyH or "CENTER"
	self.InterruptSource:ClearAllPoints()
	self.InterruptSource:SetJustifyH(justifyH)

	if element.maxWidth ~= nil and element.maxWidth > 0 then
		self.InterruptSource:SetWidth(element.maxWidth)
		self.InterruptSource:SetWordWrap(false)
	else
		self.InterruptSource:SetWidth(0)
	end

	PixelUtil.SetPoint(self.InterruptSource, justifyH, self, "CENTER", element.x or 0, element.y or 0)

	Private.Utils.SetFontIfChanged(
		self.InterruptSource,
		element.font,
		element.fontSize,
		element.fontFlags[Private.Enum.FontFlags.OUTLINE] and "OUTLINE" or ""
	)

	if element.fontFlags[Private.Enum.FontFlags.SHADOW] then
		self.InterruptSource:SetShadowOffset(1, -1)
		self.InterruptSource:SetShadowColor(0, 0, 0, 1)
	else
		self.InterruptSource:SetShadowOffset(0, 0)
	end

	if element.textColor ~= nil then
		local color = CreateColorFromHexString(element.textColor)
		self.InterruptSource:SetTextColor(color.r, color.g, color.b, color.a)
	end
end

function TargetedSpellsIconMixin:SetFont()
	local cooldown = self:GetElement(Private.Enum.Element.Cooldown)
	if cooldown == nil then
		return
	end

	local fontString = self.Cooldown:GetCountdownFontString()

	Private.Utils.SafelySetFont(
		fontString,
		cooldown.countdownFont,
		cooldown.countdownFontSize,
		cooldown.countdownFontFlags[Private.Enum.FontFlags.OUTLINE] and "OUTLINE" or ""
	)

	if cooldown.countdownFontFlags[Private.Enum.FontFlags.SHADOW] then
		fontString:SetShadowOffset(1, -1)
		fontString:SetShadowColor(0, 0, 0, 1)
	else
		fontString:SetShadowOffset(0, 0)
	end
end
