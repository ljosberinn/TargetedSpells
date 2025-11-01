---@type string, TargetedSpells
local addonName, Private = ...

local PreviewIconDataProvider = nil

---@return IconDataProviderMixin
local function GetPreviewIconDataProvider()
	if PreviewIconDataProvider == nil then
		PreviewIconDataProvider =
			CreateAndInitFromMixin(IconDataProviderMixin, IconDataProviderExtraType.Spellbook, true)
	end

	return PreviewIconDataProvider
end

---@type TargetedSpellsMixin
TargetedSpellsMixin = {}

function TargetedSpellsMixin:OnLoad()
	print("TargetedSpellsMixin:OnLoad()", self.kind, self.unit)

	if self.settingsCallbackId == nil then
		self.settingsCallbackId =
			Private.EventRegistry:RegisterCallback(Private.Events.SETTING_CHANGED, self.OnSettingChanged, self)
	end

	-- initially set via SelfPreviewTemplate through Settings, but not in any other case
	if self.kind ~= nil then
		self:OnKindChanged(self.kind)
	end

	self.Cooldown:SetCountdownFont("GameFontHighlightHugeOutline")
end

function TargetedSpellsMixin:OnKindChanged(kind)
	print("TargetedSpellsMixin:OnKindChanged()", kind)

	if kind == Private.Enum.FrameKind.Self then
		self:SetSize(TargetedSpellsSaved.Settings.Self.Width, TargetedSpellsSaved.Settings.Self.Height)
	elseif kind == Private.Enum.FrameKind.Party then
		self:SetSize(TargetedSpellsSaved.Settings.Party.Width, TargetedSpellsSaved.Settings.Party.Height)
	end
end

--- shamelessly ~~stolen~~ repurposed from WeakAuras2
---@param width number
---@param height number
function TargetedSpellsMixin:OnSizeChanged(width, height)
	print("TargetedSpellsMixin:OnSizeChanged()", self.kind, self.unit, width, height)

	local aspectRatio = width / height

	local coordinates = { 0, 0, 0, 1, 1, 0, 1, 1 }

	local xRatio = aspectRatio < 1 and aspectRatio or 1
	local yRatio = aspectRatio > 1 and 1 / aspectRatio or 1

	for i = 1, #coordinates, 1 do
		local coordinate = coordinates[i]

		if i % 2 == 1 then
			coordinates[i] = (coordinate - 0.5) * xRatio + 0.5
		else
			coordinates[i] = (coordinate - 0.5) * yRatio + 0.5
		end
	end

	self.Icon:SetTexCoord(unpack(coordinates))

	local topleftRelativePoint = select(2, self.Overlay:GetPointByName("TOPLEFT"))
	local bottomrightRelativePoint = select(2, self.Overlay:GetPointByName("BOTTOMRIGHT"))
	self.Overlay:ClearAllPoints()

	do
		local fifteenPercent = 0.15 * width
		self.Overlay:SetPoint("TOPLEFT", topleftRelativePoint, "TOPLEFT", -fifteenPercent, fifteenPercent)
	end

	do
		local fifteenPercent = 0.15 * height
		self.Overlay:SetPoint("BOTTOMRIGHT", bottomrightRelativePoint, "BOTTOMRIGHT", fifteenPercent, -fifteenPercent)
	end
end

function TargetedSpellsMixin:OnSettingChanged(key, value)
	print("TargetedSpellsMixin:OnSettingChanged()", key, value)

	if self.kind == Private.Enum.FrameKind.Self then
		if key == Private.Settings.Keys.Self.Width then
			self:SetSize(value, TargetedSpellsSaved.Settings.Self.Height)
		elseif key == Private.Settings.Keys.Self.Height then
			self:SetSize(TargetedSpellsSaved.Settings.Self.Width, value)
		end
	else
		if key == Private.Settings.Keys.Party.Width then
			self:SetSize(value, TargetedSpellsSaved.Settings.Party.Height)
		elseif key == Private.Settings.Keys.Party.Height then
			self:SetSize(TargetedSpellsSaved.Settings.Party.Width, value)
		end
	end
end

function TargetedSpellsMixin:RefreshSpellCooldownInfo()
	print("TargetedSpellsMixin:RefreshSpellCooldownInfo()", self.unit, self.kind)
	self.Cooldown:SetCooldown(self.startTime, self.castTime)
end

function TargetedSpellsMixin:SetStartTime()
	print("TargetedSpellsMixin:SetStartTime()", self.unit, self.kind)
	self.startTime = GetTime()
end

function TargetedSpellsMixin:GetStartTime()
	return self.startTime
end

function TargetedSpellsMixin:SetCastTime(castTime)
	print("TargetedSpellsMixin:SetCastTime()", self.unit, self.kind, castTime)
	self.castTime = castTime
end

function TargetedSpellsMixin:GetCastTime()
	print("TargetedSpellsMixin:GetCastTime()", self.unit, self.kind)
	return self.castTime
end

function TargetedSpellsMixin:SetSpellTexture(texture)
	texture = texture or GetPreviewIconDataProvider():GetRandomIcon()
	self.texture = texture
end

function TargetedSpellsMixin:RefreshSpellTexture()
	self.Icon:SetTexture(self.texture)
end

function TargetedSpellsMixin:UpdateShownState()
	local shouldBeShown = self:ShouldBeShown()
	self:SetShown(shouldBeShown)
end

function TargetedSpellsMixin:ShouldBeShown()
	return self.startTime ~= nil
end

function TargetedSpellsMixin:ClearStartTime()
	self.startTime = nil
end

function TargetedSpellsMixin:Reposition(point, relativeTo, relativePoint, offsetX, offsetY)
	self:ClearAllPoints()
	self:SetPoint(point, relativeTo, relativePoint, offsetX, offsetY)
end

function TargetedSpellsMixin:StartPreviewLoop(RepositionPreviewFrames)
	if self.unit == nil or string.find(self.unit, "preview") == nil or self.loopTicker ~= nil then
		return
	end

	local function Loop()
		self:SetSpellTexture()
		self:SetStartTime()
		RepositionPreviewFrames()
		local castTime = math.random(2, 4) + math.random()
		self:SetCastTime(castTime)
		self:RefreshSpellCooldownInfo()
		self:RefreshSpellTexture()
		self:Show()

		self.hideTimer = C_Timer.NewTimer(castTime, function()
			self:ClearStartTime()
			self.hideTimer = nil
			self:Hide()
			RepositionPreviewFrames()
		end)
	end

	local unit = string.gsub(self.unit, "preview", "")
	local index = tonumber(unit)
	local delay = (index - 1) * math.random()

	self.loopTicker = C_Timer.NewTicker(4.5 + delay, Loop)
	Loop()
end

function TargetedSpellsMixin:StopPreviewLoop()
	print("TargetedSpellsMixin:StopPreviewLoop()", self.unit, self.kind)
	if self.loopTicker ~= nil and not self.loopTicker:IsCancelled() then
		self.loopTicker:Cancel()
		self.loopTicker = nil
	end

	if self.hideTimer ~= nil and not self.hideTimer:IsCancelled() then
		self.hideTimer:Cancel()
		self.hideTimer = nil
	end

	self:Hide()
end

function TargetedSpellsMixin:SetUnit(unit)
	self.unit = unit
end

function TargetedSpellsMixin:SetKind(kind)
	if self.kind ~= kind then
		self.kind = kind
		self:OnKindChanged(kind)
	end
end

function TargetedSpellsMixin:GetUnit()
	return self.unit
end

function TargetedSpellsMixin:GetKind()
	return self.kind
end
