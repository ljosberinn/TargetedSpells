---@type string, TargetedSpells
local _, Private = ...

---@class TargetedSpellsIconDurationMixin : TargetedSpellsMixin
TargetedSpellsIconDurationMixin = CreateFromMixins(TargetedSpellsMixin)

---@param frame TargetedSpellsIconDurationMixin
---@param fn fun(cell: table)
local function ForEachCell(frame, fn)
	fn(frame.IconCell)
	fn(frame.IconCellMirror)
end

function TargetedSpellsIconDurationMixin:GetCoreElement()
	return Private.Enum.Element.Icon
end

function TargetedSpellsIconDurationMixin:OnLoad()
	TargetedSpellsMixin.OnLoad(self)

	self.Icon = self.IconCell.Icon
	self.InterruptIcon = self.IconCell.InterruptIcon

	self.Bar:SetStatusBarTexture("")

	self.durationFormatter = Private.Utils.CreateCountdownFormatter()

	self.durationBinding = C_DurationUtil.CreateDurationTextBinding()
	self.durationBinding:SetFontString(self.Duration)
	self.durationBinding:SetFormatter(self.durationFormatter)
	self.durationBinding:SetZeroDurationText("")

	ForEachCell(self, function(cell)
		cell.countdownFormatter = Private.Utils.CreateCountdownFormatter()
		cell.Cooldown:SetCountdownFormatter(cell.countdownFormatter)
		cell.Cooldown:SetCountdownFont("GameFontHighlightHugeOutline")
	end)

	self:HideGlow()
end

function TargetedSpellsIconDurationMixin:PositionElements()
	local elements = self:GetElements()
	if elements == nil then
		return
	end

	local layout = Private.Utils.ComputeIconDurationLayout(elements)

	local function Place(region, geometry)
		region:ClearAllPoints()
		PixelUtil.SetSize(region, geometry.width, geometry.height)
		PixelUtil.SetPoint(region, "CENTER", self, "CENTER", geometry.centerX, geometry.centerY)
	end

	Place(self.IconCell, layout.iconLeft)
	Place(self.IconCellMirror, layout.iconRight)

	self.Duration:ClearAllPoints()
	PixelUtil.SetPoint(self.Duration, "CENTER", self, "CENTER", layout.duration.centerX, layout.duration.centerY)
end

function TargetedSpellsIconDurationMixin:ApplyLayout()
	local elements = self:GetElements()
	local iconElement = self:GetElement(Private.Enum.Element.Icon)
	if elements == nil or iconElement == nil then
		return
	end

	local layout = Private.Utils.ComputeIconDurationLayout(elements)
	PixelUtil.SetSize(self, layout.totalWidth, iconElement.height)

	self:PositionElements()
	self:SetFont()

	local overlay = self:GetElement(Private.Enum.Element.Overlay)
	local shown = overlay == nil or overlay.active ~= false

	local border = self:GetElement(Private.Enum.Element.Border)
	self:ApplyBorderStyle(border ~= nil and border.active ~= false and border.borderTexture or "None")

	local cooldown = self:GetElement(Private.Enum.Element.Cooldown)

	ForEachCell(self, function(cell)
		cell.Overlay:SetShown(shown)

		if cooldown ~= nil then
			cell.Cooldown:SetHideCountdownNumbers(cooldown.showCountdown == false)
			cell.Cooldown:SetDrawSwipe(cooldown.showSwipe)
			Private.Utils.ApplyFractionThreshold(cell.countdownFormatter, cooldown.fractionThreshold)
		end
	end)

	local duration = self:GetElement(Private.Enum.Element.Duration)
	if duration ~= nil then
		Private.Utils.ApplyFractionThreshold(self.durationFormatter, duration.fractionThreshold)
	end
end

function TargetedSpellsIconDurationMixin:ApplyBorderStyle(styleName)
	local border = self:GetElement(Private.Enum.Element.Border)
	local iconElement = self:GetElement(Private.Enum.Element.Icon)
	if iconElement == nil then
		return
	end

	local box = { width = iconElement.width, height = iconElement.height, offsetX = 0, offsetY = 0 }

	ForEachCell(self, function(cell)
		Private.Utils.ApplyBorderStyle(
			cell --[[@as TargetedSpellsBorderFrame]],
			styleName,
			box,
			border and border.borderSize,
			border and border.borderColor
		)
	end)
end


function TargetedSpellsIconDurationMixin:HideGlow()
	ForEachCell(self, function(cell)
		self:HideGlowOn(cell)
	end)
end

---@param isImportant boolean secret — only ever fed to SetAlphaFromBoolean, never branched on
function TargetedSpellsIconDurationMixin:ShowGlow(isImportant)
	local group = self:GetGroup()
	local iconElement = self:GetElement(Private.Enum.Element.Icon)
	if group == nil or iconElement == nil then
		return
	end

	ForEachCell(self, function(cell)
		self:ShowGlowOn(cell, iconElement.width, iconElement.height, group.GlowType, isImportant)
	end)
end

function TargetedSpellsIconDurationMixin:SetIconTexture(texture)
	self.IconCell.Icon:SetTexture(texture)
	self.IconCellMirror.Icon:SetTexture(texture)
end

function TargetedSpellsIconDurationMixin:SetInterrupted(name, color)
	TargetedSpellsMixin.SetInterrupted(self, name, color)

	self.IconCellMirror.InterruptIcon:Show()
	self.IconCellMirror.Icon:SetDesaturated(true)

	ForEachCell(self, function(cell)
		cell.Cooldown:SetDrawSwipe(false)
	end)
end

function TargetedSpellsIconDurationMixin:SetShowDuration(showDuration)
	ForEachCell(self, function(cell)
		cell.Cooldown:SetHideCountdownNumbers(not showDuration)
	end)

	self.durationBinding:SetEnabled(showDuration)
end

--- shamelessly ~~stolen~~ repurposed from WeakAuras2, applied to both cells
function TargetedSpellsIconDurationMixin:OnSizeChanged()
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

	local horizontalInset = 0.15 * iconElement.width
	local verticalInset = 0.15 * iconElement.height

	ForEachCell(self, function(cell)
		cell.Icon:SetTexCoord(unpack(coordinates))

		local topleftRelativePoint = select(2, cell.Overlay:GetPointByName("TOPLEFT"))
		local bottomrightRelativePoint = select(2, cell.Overlay:GetPointByName("BOTTOMRIGHT"))
		cell.Overlay:ClearAllPoints()

		PixelUtil.SetPoint(cell.Overlay, "TOPLEFT", topleftRelativePoint, "TOPLEFT", -horizontalInset, verticalInset)
		PixelUtil.SetPoint(
			cell.Overlay,
			"BOTTOMRIGHT",
			bottomrightRelativePoint,
			"BOTTOMRIGHT",
			verticalInset,
			-verticalInset
		)
	end)

	self:PositionElements()
end

function TargetedSpellsIconDurationMixin:PostCreate(info, OnCooldownDoneCallback)
	if info == nil then
		return
	end

	self:ApplyLayout()

	local group = self:GetGroup()

	self:SetUnit(info.unit)

	ForEachCell(self, function(cell)
		cell.Cooldown:SetCooldownFromDurationObject(info.duration)
	end)

	self.durationBinding:SetDuration(info.duration)
	self.durationBinding:SetEnabled(true)

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
		self.IconCell.Cooldown:SetScript("OnCooldownDone", self.OnCooldownDoneClosure)
	end
end

function TargetedSpellsIconDurationMixin:SetFont()
	local duration = self:GetElement(Private.Enum.Element.Duration)

	if duration ~= nil then
		Private.Utils.SetFontIfChanged(
			self.Duration,
			duration.countdownFont,
			duration.countdownFontSize,
			duration.countdownFontFlags[Private.Enum.FontFlags.OUTLINE] and "OUTLINE" or ""
		)

		if duration.countdownFontFlags[Private.Enum.FontFlags.SHADOW] then
			self.Duration:SetShadowOffset(1, -1)
			self.Duration:SetShadowColor(0, 0, 0, 1)
		else
			self.Duration:SetShadowOffset(0, 0)
		end
	end

	local cooldown = self:GetElement(Private.Enum.Element.Cooldown)
	if cooldown == nil then
		return
	end

	ForEachCell(self, function(cell)
		local fontString = cell.Cooldown:GetCountdownFontString()

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
	end)
end

function TargetedSpellsIconDurationMixin:Reset()
	self.durationBinding:SetEnabled(false)
	self.Duration:SetText("")

	local cooldown = self:GetElement(Private.Enum.Element.Cooldown)

	ForEachCell(self, function(cell)
		cell.Cooldown:Clear()
		cell.Cooldown:SetScript("OnCooldownDone", nil)
	end)

	self.IconCellMirror.InterruptIcon:Hide()
	self.IconCellMirror.Icon:SetDesaturated(false)

	TargetedSpellsMixin.Reset(self)

	if cooldown ~= nil then
		ForEachCell(self, function(cell)
			cell.Cooldown:SetHideCountdownNumbers(cooldown.showCountdown == false)
			cell.Cooldown:SetDrawSwipe(cooldown.showSwipe)
		end)
	end
end
