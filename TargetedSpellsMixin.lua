---@type string, TargetedSpells
local addonName, Private = ...
local LibCustomGlow = LibStub("LibCustomGlow-1.0")
local LibEditMode = LibStub("LibEditMode")

---@class TargetedSpellsMixin
TargetedSpellsMixin = {}

function TargetedSpellsMixin:OnLoad()
	Private.EventRegistry:RegisterCallback(Private.Enum.Events.SETTING_CHANGED, self.OnSettingChanged, self)

	self.Cooldown:SetCountdownFont("GameFontHighlightHugeOutline")
	self.Cooldown:SetMinimumCountdownDuration(0)
end

function TargetedSpellsMixin:OnKindChanged(kind)
	local tableRef = kind == Private.Enum.FrameKind.Self and TargetedSpellsSaved.Settings.Self
		or TargetedSpellsSaved.Settings.Party

	self:SetSize(tableRef.Width, tableRef.Height)
	self:SetFontSize(tableRef.FontSize)

	if tableRef.ShowBorder then
		self:ApplyBorder()
	else
		self:ClearBorder()
	end

	self:SetShowDuration(tableRef.ShowDuration)
	self:SetAlpha(tableRef.Opacity)
end

function TargetedSpellsMixin:ApplyBorder()
	-- literally the defaults from https://warcraft.wiki.gg/wiki/BackdropTemplate
	self:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileEdge = true,
		tileSize = 8,
		edgeSize = 8,
		insets = { left = 1, right = 1, top = 1, bottom = 1 },
	})
end

function TargetedSpellsMixin:ClearBorder()
	self:ClearBackdrop()
end

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
	if key == Private.Settings.Keys.Self.Width then
		if self.kind == Private.Enum.FrameKind.Self then
			self:SetWidth(value)
		end
	elseif key == Private.Settings.Keys.Self.Height then
		if self.kind == Private.Enum.FrameKind.Self then
			self:SetHeight(value)
		end
	elseif key == Private.Settings.Keys.Party.Width then
		if self.kind == Private.Enum.FrameKind.Party then
			self:SetWidth(value)
		end
	elseif key == Private.Settings.Keys.Party.Height then
		if self.kind == Private.Enum.FrameKind.Party then
			self:SetHeight(value)
		end
	elseif key == Private.Settings.Keys.Self.ShowDuration or key == Private.Settings.Keys.Party.ShowDuration then
		---@diagnostic disable-next-line: param-type-mismatch
		self:SetShowDuration(value)
	elseif key == Private.Settings.Keys.Self.FontSize or key == Private.Settings.Keys.Party.FontSize then
		self:SetFontSize(value)
	elseif key == Private.Settings.Keys.Self.Opacity or key == Private.Settings.Keys.Party.Opacity then
		self:SetAlpha(value)
	elseif key == Private.Settings.Keys.Self.ShowBorder or key == Private.Settings.Keys.Party.ShowBorder then
		if value then
			self:ApplyBorder()
		else
			self:ClearBorder()
		end
	elseif key == Private.Settings.Keys.Self.GlowType or key == Private.Settings.Keys.Party.GlowType then
		self:HideGlow()

		local tableRef = self.kind == Private.Enum.FrameKind.Self and TargetedSpellsSaved.Settings.Self
			or TargetedSpellsSaved.Settings.Party

		if tableRef.GlowImportant then
			self:ShowGlow(self:IsSpellImportant(LibEditMode:IsInEditMode() and Private.Utils.RollDice()))
		end
	end
end

function TargetedSpellsMixin:RefreshSpellCooldownInfo()
	self.Cooldown:SetCooldown(self.startTime, self.castTime)
end

function TargetedSpellsMixin:SetStartTime(startTime)
	self.startTime = startTime or GetTime()
end

function TargetedSpellsMixin:GetStartTime()
	return self.startTime
end

function TargetedSpellsMixin:SetCastTime(castTime)
	self.castTime = castTime
end

function TargetedSpellsMixin:ShowGlow(isImportant)
	local glowType = self.kind == Private.Enum.FrameKind.Self and TargetedSpellsSaved.Settings.Self.GlowType
		or TargetedSpellsSaved.Settings.Party.GlowType

	if glowType == Private.Enum.GlowType.Star4 then
		if self.Star4 == nil then
			local width, height = self:GetSize()
			local innerFactor = 1.9
			local outerFactor = 2.2

			self.Star4 = CreateFrame("Frame", nil, self)
			self.Star4:SetPoint("CENTER")
			self.Star4:SetFrameStrata(self:GetFrameStrata())
			self.Star4:SetFrameLevel(self:GetFrameLevel() + 1)
			self.Star4:SetSize(width * innerFactor, height * innerFactor)

			self.Star4Inner = self.Star4:CreateTexture(nil, "OVERLAY")
			self.Star4Inner:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
			self.Star4Inner:SetBlendMode("ADD")
			self.Star4Inner:SetAlpha(0.9)
			self.Star4Inner:SetVertexColor(1, 0.85, 0.25)
			self.Star4Inner:SetPoint("CENTER")
			self.Star4Inner:SetSize(width * innerFactor, height * innerFactor)

			self.Star4Outer = self.Star4:CreateTexture(nil, "OVERLAY")
			self.Star4Outer:SetTexture("Interface\\Cooldown\\star4")
			self.Star4Outer:SetBlendMode("ADD")
			self.Star4Outer:SetAlpha(0.6)
			self.Star4Outer:SetVertexColor(1, 0.75, 0.2)
			self.Star4Outer:SetPoint("CENTER")
			self.Star4Outer:SetSize(width * outerFactor, height * outerFactor)

			self.Star4AnimationGroup = self.Star4:CreateAnimationGroup()
			self.Star4Pulse = self.Star4AnimationGroup:CreateAnimation("Alpha")
			self.Star4Pulse:SetFromAlpha(0.35)
			self.Star4Pulse:SetToAlpha(0.75)
			self.Star4Pulse:SetDuration(0.75)
			self.Star4Pulse:SetSmoothing("IN_OUT")
			self.Star4AnimationGroup:SetLooping("BOUNCE")
		end

		self.Star4:Show()
		self.Star4Inner:Show()
		self.Star4Outer:Show()
		self.Star4AnimationGroup:Play()

		if Private.IsMidnight then
			self.Star4:SetAlphaFromBoolean(isImportant)
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
	if self.Star4 ~= nil then
		self.Star4:Hide()
		self.Star4Inner:Hide()
		self.Star4Outer:Hide()
		self.Star4AnimationGroup:Stop()
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

	function TargetedSpellsMixin:IsSpellImportant(boolOverride)
		if boolOverride ~= nil then
			return boolOverride
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

				for _, script in pairs(Plater.db.profile.script_data) do
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
	self:ClearAllPoints()
	self:Hide()
	self:HideGlow()
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
