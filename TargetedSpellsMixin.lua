---@type string, TargetedSpells
local addonName, Private = ...
local LibCustomGlow = LibStub("LibCustomGlow-1.0")
local LibEditMode = LibStub("LibEditMode")

TARGETED_SPELLS_BACKDROP = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true,
	tileEdge = true,
	tileSize = 8,
	edgeSize = 8,
	insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

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
	Private.EventRegistry:RegisterCallback(Private.Enum.Events.SETTING_CHANGED, self.OnSettingChanged, self)

	self.Cooldown:SetCountdownFont("GameFontHighlightHugeOutline")
	self.wasInterrupted = false
	self.doNotHideBefore = nil
end

function TargetedSpellsMixin:SetInterrupted()
	self.wasInterrupted = true
	self.doNotHideBefore = GetTime() + 0.95
	self.InterruptIcon:Show()
	self.Icon:SetDesaturated(true)
	self.Cooldown:SetDrawSwipe(false)
	self:SetShowDuration(false, false)
end

function TargetedSpellsMixin:CanBeHidden()
	if self.wasInterrupted then
		return GetTime() >= self.doNotHideBefore
	end

	return true
end

---@param self TargetedSpellsMixin
---@param elapsed number
local function OnUpdate(self, elapsed)
	if self.duration == nil then
		return
	end

	local remainingDuration = type(self.duration) == "number" and self.startTime + self.duration - GetTime()
		or self.duration:GetRemainingDuration()

	self.DurationText:SetFormattedText("%.1f", remainingDuration)
end

function TargetedSpellsMixin:OnUpdate(elapsed)
	-- noop until it gets overridden by the above
end

function TargetedSpellsMixin:OnKindChanged(kind)
	local tableRef = kind == Private.Enum.FrameKind.Self and TargetedSpellsSaved.Settings.Self
		or TargetedSpellsSaved.Settings.Party

	self:SetSize(tableRef.Width, tableRef.Height)
	self:SetFontSize(tableRef.FontSize)
	self:HideGlow()
	self:SetShowBorder(tableRef.ShowBorder)
	self:SetAlpha(tableRef.Opacity)
	self:SetShowDuration(tableRef.ShowDuration, tableRef.ShowDurationFractions)
end

function TargetedSpellsMixin:SetShowDuration(showDuration, showFractions)
	self.Cooldown:SetHideCountdownNumbers(not showDuration or showFractions)
	self.DurationText:SetShown(showDuration and showFractions)
	self:SetScript("OnUpdate", showDuration and showFractions and OnUpdate or nil)
end

function TargetedSpellsMixin:SetShowBorder(bool)
	if bool then
		self.Border:Show()
	else
		self.Border:Hide()
	end
end

--- shamelessly ~~stolen~~ repurposed from WeakAuras2
---@param width number
---@param height number
function TargetedSpellsMixin:OnSizeChanged(width, height)
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
			self:SetWidth(value)
		elseif key == Private.Settings.Keys.Self.Height then
			self:SetHeight(value)
		elseif key == Private.Settings.Keys.Self.ShowDuration then
			---@diagnostic disable-next-line: param-type-mismatch
			self:SetShowDuration(value, TargetedSpellsSaved.Settings.Self.ShowDurationFractions)
		elseif key == Private.Settings.Keys.Self.FontSize then
			self:SetFontSize(value)
		elseif key == Private.Settings.Keys.Self.Opacity then
			self:SetAlpha(value)
		elseif key == Private.Settings.Keys.Self.ShowBorder then
			---@diagnostic disable-next-line: param-type-mismatch
			self:SetShowBorder(value)
		elseif key == Private.Settings.Keys.Self.GlowType then
			self:HideGlow()

			if TargetedSpellsSaved.Settings.Self.GlowImportant then
				self:ShowGlow(self:IsSpellImportant(LibEditMode:IsInEditMode() and Private.Utils.RollDice()))
			end
		elseif key == Private.Settings.Keys.Self.ShowDurationFractions then
			self:SetScript("OnUpdate", value and OnUpdate or nil)
			---@diagnostic disable-next-line: param-type-mismatch
			self.Cooldown:SetHideCountdownNumbers(value)
			---@diagnostic disable-next-line: param-type-mismatch
			self.DurationText:SetShown(value)
		end
	else
		if key == Private.Settings.Keys.Party.Width then
			self:SetWidth(value)
		elseif key == Private.Settings.Keys.Party.Height then
			self:SetHeight(value)
		elseif key == Private.Settings.Keys.Party.ShowDuration then
			---@diagnostic disable-next-line: param-type-mismatch
			self:SetShowDuration(value, TargetedSpellsSaved.Settings.Party.ShowDurationFractions)
		elseif key == Private.Settings.Keys.Party.FontSize then
			self:SetFontSize(value)
		elseif key == Private.Settings.Keys.Party.Opacity then
			self:SetAlpha(value)
		elseif key == Private.Settings.Keys.Party.ShowBorder then
			---@diagnostic disable-next-line: param-type-mismatch
			self:SetShowBorder(value)
		elseif key == Private.Settings.Keys.Party.GlowType then
			self:HideGlow()

			if TargetedSpellsSaved.Settings.Party.GlowImportant then
				self:ShowGlow(self:IsSpellImportant(LibEditMode:IsInEditMode() and Private.Utils.RollDice()))
			end
		elseif key == Private.Settings.Keys.Party.ShowDurationFractions then
			self:SetScript("OnUpdate", value and OnUpdate or nil)
			---@diagnostic disable-next-line: param-type-mismatch
			self.Cooldown:SetHideCountdownNumbers(value)
			---@diagnostic disable-next-line: param-type-mismatch
			self.DurationText:SetShown(value)
		end
	end
end

function TargetedSpellsMixin:SetDuration(duration)
	self.duration = duration

	if type(duration) == "number" then
		self.Cooldown:SetCooldown(self.startTime, duration)
	else
		self.Cooldown:SetCooldownFromDurationObject(duration)
	end
end

function TargetedSpellsMixin:SetStartTime(startTime)
	self.startTime = startTime or GetTime()
end

function TargetedSpellsMixin:GetStartTime()
	return self.startTime
end

---@param parent Frame
local function CreateStar4Glow(parent)
	local width, height = parent:GetSize()
	local innerFactor = 1.9
	local outerFactor = 2.2

	local Star4 = CreateFrame("Frame", nil, parent)
	Star4:SetPoint("CENTER")
	Star4:SetFrameStrata(parent:GetFrameStrata())
	Star4:SetFrameLevel(parent:GetFrameLevel() + 1)
	Star4:SetSize(width * innerFactor, height * innerFactor)

	local Inner = Star4:CreateTexture(nil, "OVERLAY")
	Inner:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
	Inner:SetBlendMode("ADD")
	Inner:SetAlpha(0.9)
	Inner:SetVertexColor(1, 0.85, 0.25)
	Inner:SetPoint("CENTER")
	Inner:SetSize(width * innerFactor, height * innerFactor)
	Star4.Inner = Inner

	local Outer = Star4:CreateTexture(nil, "OVERLAY")
	Outer:SetTexture("Interface\\Cooldown\\star4")
	Outer:SetBlendMode("ADD")
	Outer:SetAlpha(0.6)
	Outer:SetVertexColor(1, 0.75, 0.2)
	Outer:SetPoint("CENTER")
	Outer:SetSize(width * outerFactor, height * outerFactor)
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

function TargetedSpellsMixin:ShowGlow(isImportant)
	local glowType = self.kind == Private.Enum.FrameKind.Self and TargetedSpellsSaved.Settings.Self.GlowType
		or TargetedSpellsSaved.Settings.Party.GlowType

	if glowType == Private.Enum.GlowType.Star4 then
		if self._Star4 == nil then
			self._Star4 = CreateStar4Glow(self)
		end

		self._Star4:Show()
		self._Star4.Inner:Show()
		self._Star4.Outer:Show()
		self._Star4.Animation:Play()

		if Private.IsMidnight then
			self._Star4:SetAlphaFromBoolean(isImportant)
		end
	elseif glowType == Private.Enum.GlowType.PixelGlow then
		LibCustomGlow.PixelGlow_Start(self)

		if Private.IsMidnight then
			self._PixelGlow:SetAlphaFromBoolean(isImportant)
		end
	elseif glowType == Private.Enum.GlowType.AutoCastGlow then
		LibCustomGlow.AutoCastGlow_Start(self)

		if Private.IsMidnight then
			self._AutoCastGlow:SetAlphaFromBoolean(isImportant)
		end
	elseif glowType == Private.Enum.GlowType.ButtonGlow then
		LibCustomGlow.ButtonGlow_Start(self)

		if Private.IsMidnight then
			self._ButtonGlow:SetAlphaFromBoolean(isImportant)
		end
	elseif glowType == Private.Enum.GlowType.ProcGlow then
		LibCustomGlow.ProcGlow_Start(self)

		if Private.IsMidnight then
			self._ProcGlow:SetAlphaFromBoolean(isImportant)
		end
	end
end

function TargetedSpellsMixin:HideGlow()
	if self._Star4 ~= nil then
		self._Star4:Hide()
		self._Star4.Inner:Hide()
		self._Star4.Outer:Hide()
		self._Star4.Animation:Stop()
	end

	LibCustomGlow.PixelGlow_Stop(self)
	LibCustomGlow.AutoCastGlow_Stop(self)
	LibCustomGlow.ButtonGlow_Stop(self)
	LibCustomGlow.ProcGlow_Stop(self)
end

do
	---@type table<number, boolean>
	local platerProfileImportantCastsCache = Private.IsMidnight and nil or {}
	local cacheInitialized = false

	function TargetedSpellsMixin:IsSpellImportant(override)
		if override ~= nil then
			return override
		end

		if self.spellId == nil then
			return false
		end

		if Private.IsMidnight then
			return C_Spell.IsSpellImportant(self.spellId)
		end

		if Plater and Plater.db and Plater.db.profile and Plater.db.profile.script_data then
			if not cacheInitialized then
				cacheInitialized = true

				local importantCastsScripts = {
					["Cast - Very Important [Plater]"] = true,
					["Important Casts - Jundies"] = true,
					["Quazii MUST INTERRUPT"] = true,
				}

				for i, script in ipairs(Plater.db.profile.script_data) do
					if script and importantCastsScripts[script.Name] == true then
						for _, id in pairs(script.SpellIds) do
							platerProfileImportantCastsCache[id] = true
						end
					end
				end
			end

			return platerProfileImportantCastsCache[self.spellId] == true
		end

		return false
	end
end

function TargetedSpellsMixin:SetSpellId(spellId)
	self.spellId = spellId
	local texture = spellId and C_Spell.GetSpellTexture(spellId) or GetRandomIcon()
	self.Icon:SetTexture(texture)

	if
		spellId ~= nil
		and (
			(self.kind == Private.Enum.FrameKind.Self and TargetedSpellsSaved.Settings.Self.GlowImportant)
			or (self.kind == Private.Enum.FrameKind.Party and TargetedSpellsSaved.Settings.Party.GlowImportant)
		)
	then
		if Private.IsMidnight or self:IsSpellImportant() then
			self:ShowGlow(self:IsSpellImportant())
		else
			self:HideGlow()
		end
	end
end

function TargetedSpellsMixin:IsSpellId(spellId)
	if Private.IsMidnight then
		return false
	end

	return self.spellId == spellId
end

function TargetedSpellsMixin:ShouldBeShown()
	return self.startTime ~= nil
end

function TargetedSpellsMixin:ClearStartTime()
	self.startTime = nil
end

function TargetedSpellsMixin:ClearSpellId()
	self.spellId = nil
end

function TargetedSpellsMixin:Reposition(point, relativeTo, relativePoint, offsetX, offsetY)
	self:ClearAllPoints()
	self:SetPoint(point, relativeTo, relativePoint, offsetX, offsetY)
	self:Show()
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

function TargetedSpellsMixin:PostCreate(unit, kind, castingUnit)
	self:SetUnit(unit)
	self:SetKind(kind)

	if castingUnit ~= nil and Private.IsMidnight then
		-- using UnitIsSpellTarget(castingUnit, unit) works and is technically more accurate
		-- but it omits spells that - while the enemy is targeting something - doesn't affect the target, e.g. aoe enrages or party-wide damage
		self:SetAlphaFromBoolean(UnitIsUnit(string.format("%starget", castingUnit), unit))
	end
end

function TargetedSpellsMixin:Reset()
	self:ClearStartTime()
	self:ClearSpellId()
	self.Cooldown:Clear()
	self.duration = nil
	self:ClearAllPoints()
	self:Hide()
	self:HideGlow()
	self.wasInterrupted = false
	self.doNotHideBefore = nil
	self.InterruptIcon:Hide()
	self.Icon:SetDesaturated(false)
	self.Cooldown:SetDrawSwipe(true)

	local tableRef = self.kind == Private.Enum.FrameKind.Self and TargetedSpellsSaved.Settings.Self
		or TargetedSpellsSaved.Settings.Party

	self:SetShowDuration(tableRef.ShowDuration, tableRef.ShowDurationFractions)
end

function TargetedSpellsMixin:SetFontSize(fontSize)
	local tableRef = self.kind == Private.Enum.FrameKind.Self and TargetedSpellsSaved.Settings.Self
		or TargetedSpellsSaved.Settings.Party

	local fontString = nil

	if tableRef.ShowDurationFractions then
		fontString = self.DurationText
	else
		fontString = Private.IsMidnight and self.Cooldown:GetCountdownFontString() or self.Cooldown:GetRegions()
	end

	local font, size, flags = fontString:GetFont()

	if size == fontSize then
		return
	end

	fontString:SetFont(font, fontSize, flags)
end

function TargetedSpellsMixin:AttemptToPlaySound(contentType, unit)
	if
		not Private.IsMidnight
		and self.kind == Private.Enum.FrameKind.Self
		and TargetedSpellsSaved.Settings.Self.PlaySound
		and TargetedSpellsSaved.Settings.Self.LoadConditionSoundContentType[contentType]
		and UnitIsUnit(string.format("%starget", unit), "player")
	then
		Private.Utils.AttemptToPlaySound(
			TargetedSpellsSaved.Settings.Self.Sound,
			TargetedSpellsSaved.Settings.Self.SoundChannel
		)
	end
end

function TargetedSpellsMixin:AttemptToPlayTTS(contentType, unit)
	if
		Private.IsMidnight
		or self.kind ~= Private.Enum.FrameKind.Self
		or self.spellId == nil
		or not TargetedSpellsSaved.Settings.Self.PlayTTS
		or not TargetedSpellsSaved.Settings.Self.LoadConditionSoundContentType[contentType]
		or not UnitIsUnit(string.format("%starget", unit), "player")
	then
		return
	end

	local spellName = C_Spell.GetSpellName(self.spellId)

	if spellName == nil then
		return
	end

	Private.Utils.PlayTTS(spellName)
end
