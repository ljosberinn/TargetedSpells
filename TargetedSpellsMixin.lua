---@type string, TargetedSpells
local addonName, Private = ...

local PreviewIconDataProvider = nil

---@return IconDataProviderMixin
local function GetRandomIcon()
	if PreviewIconDataProvider == nil then
		PreviewIconDataProvider =
			CreateAndInitFromMixin(IconDataProviderMixin, IconDataProviderExtraType.Spellbook, true)
	end

	if Private.IsMidnight then
		return PreviewIconDataProvider:GetRandomIcon()
	end

	-- backport of GetRandomIcon() from 12.0
	local numIcons = PreviewIconDataProvider:GetNumIcons()
	local avoidQuestionMarkIndex = 2
	return PreviewIconDataProvider:GetIconByIndex(math.random(avoidQuestionMarkIndex, numIcons))
end

---@class TargetedSpellsMixin
TargetedSpellsMixin = {}

function TargetedSpellsMixin:OnLoad()
	-- print("TargetedSpellsMixin:OnLoad()", self.kind, self.unit)

	Private.EventRegistry:RegisterCallback(Private.Enum.Events.SETTING_CHANGED, self.OnSettingChanged, self)

	-- initially set via SelfPreviewTemplate through Settings, but not in any other case
	if self.kind ~= nil then
		self:OnKindChanged(self.kind)
	end

	self.Cooldown:SetCountdownFont("GameFontHighlightHugeOutline")
	self.Cooldown:SetMinimumCountdownDuration(0)
end

function TargetedSpellsMixin:OnKindChanged(kind)
	-- print("TargetedSpellsMixin:OnKindChanged()", kind)

	if kind == Private.Enum.FrameKind.Self then
		self:SetSize(TargetedSpellsSaved.Settings.Self.Width, TargetedSpellsSaved.Settings.Self.Height)
		self:SetFontSize(TargetedSpellsSaved.Settings.Self.FontSize)
	elseif kind == Private.Enum.FrameKind.Party then
		self:SetSize(TargetedSpellsSaved.Settings.Party.Width, TargetedSpellsSaved.Settings.Party.Height)
		self:SetFontSize(TargetedSpellsSaved.Settings.Party.FontSize)
	end
end

--- shamelessly ~~stolen~~ repurposed from WeakAuras2
---@param width number
---@param height number
function TargetedSpellsMixin:OnSizeChanged(width, height)
	-- print("TargetedSpellsMixin:OnSizeChanged()", self.kind, self.unit, width, height)

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
	if self.kind == Private.Enum.FrameKind.Self then
		if key == Private.Settings.Keys.Self.Width then
			print("TargetedSpellsMixin:OnSettingChanged->SetSize()", key, value)
			self:SetSize(value, TargetedSpellsSaved.Settings.Self.Height)
		elseif key == Private.Settings.Keys.Self.Height then
			print("TargetedSpellsMixin:OnSettingChanged->SetSize()", key, value)
			self:SetSize(TargetedSpellsSaved.Settings.Self.Width, value)
		elseif key == Private.Settings.Keys.Self.ShowDuration then
			print("TargetedSpellsMixin:OnSettingChanged->SetShowDuration()", key, value)
			self:SetShowDuration(value)
		elseif key == Private.Settings.Keys.Self.FontSize then
			print("TargetedSpellsMixin:OnSettingChanged->SetFontSize()", key, value)
			self:SetFontSize(value)
		elseif key == Private.Settings.Keys.Self.Opacity then
			self:SetAlpha(value)
		end
	else
		if key == Private.Settings.Keys.Party.Width then
			print("TargetedSpellsMixin:OnSettingChanged->SetSize()", key, value)
			self:SetSize(value, TargetedSpellsSaved.Settings.Party.Height)
		elseif key == Private.Settings.Keys.Party.Height then
			print("TargetedSpellsMixin:OnSettingChanged->SetSize()", key, value)
			self:SetSize(TargetedSpellsSaved.Settings.Party.Width, value)
		elseif key == Private.Settings.Keys.Party.ShowDuration then
			print("TargetedSpellsMixin:OnSettingChanged->SetShowDuration()", key, value)
			self:SetShowDuration(value)
		elseif key == Private.Settings.Keys.Party.FontSize then
			print("TargetedSpellsMixin:OnSettingChanged->SetFontSize()", key, value)
			self:SetFontSize(value)
		elseif key == Private.Settings.Keys.Party.Opacity then
			self:SetAlpha(value)
		end
	end
end

function TargetedSpellsMixin:RefreshSpellCooldownInfo()
	-- print("TargetedSpellsMixin:RefreshSpellCooldownInfo()", self.unit, self.kind)
	self.Cooldown:SetCooldown(self.startTime, self.castTime)
end

function TargetedSpellsMixin:SetStartTime(startTime)
	-- print("TargetedSpellsMixin:SetStartTime()", self.unit, self.kind)
	self.startTime = startTime or GetTime()
end

function TargetedSpellsMixin:GetStartTime()
	return self.startTime
end

function TargetedSpellsMixin:SetCastTime(castTime)
	-- print("TargetedSpellsMixin:SetCastTime()", self.unit, self.kind, castTime)
	self.castTime = castTime
end

function TargetedSpellsMixin:SetSpellId(spellId)
	local texture = spellId and C_Spell.GetSpellTexture(spellId) or GetRandomIcon()
	self.Icon:SetTexture(texture)
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

function TargetedSpellsMixin:SetUnit(unit)
	self.unit = unit
end

function TargetedSpellsMixin:SetKind(kind)
	if self.kind ~= kind then
		self.kind = kind
		self:OnKindChanged(kind)
	end
end

function TargetedSpellsMixin:GetKind()
	return self.kind
end

function TargetedSpellsMixin:GetUnit()
	return self.unit
end

function TargetedSpellsMixin:PostCreate(unit, kind)
	self:SetUnit(unit)
	self:SetKind(kind)
end

function TargetedSpellsMixin:Reset()
	self:ClearStartTime()
	self.Cooldown:Clear()
	self:ClearAllPoints()
	self:Hide()

	if self.soundHandle then
		StopSound(self.soundHandle)
		self.soundHandle = nil
	end
end

function TargetedSpellsMixin:AttemptToPlaySound()
	if self.kind ~= Private.Enum.FrameKind.Self then
		return
	end

	if not TargetedSpellsSaved.Settings.Self.PlaySound then
		return
	end

	local sound = TargetedSpellsSaved.Settings.Self.Sound

	if sound == nil then
		return
	end

	-- todo: load condition check for sound
	local ok, result, handle = nil, nil, nil

	if type(sound) == "number" then
		ok, result, handle = pcall(PlaySound, sound, TargetedSpellsSaved.Settings.Self.SoundChannel)
	else
		ok, result, handle = pcall(PlaySoundFile, sound, TargetedSpellsSaved.Settings.Self.SoundChannel)
	end

	if ok then
		self.soundHandle = handle
	end
end

function TargetedSpellsMixin:SetShowDuration(showDuration)
	self.Cooldown:SetHideCountdownNumbers(not showDuration)
end

function TargetedSpellsMixin:SetFontSize(fontSize)
	local fontString = Private.IsMidnight and self.Cooldown:GetCountdownFontString() or self.Cooldown:GetRegions()
	local font, size, flags = fontString:GetFont()

	if size == fontSize then
		return
	end

	fontString:SetFont(font, fontSize, flags)
end
