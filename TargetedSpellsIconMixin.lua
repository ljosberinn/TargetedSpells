---@type string, TargetedSpells
local _, Private = ...
local LibEditMode = LibStub("LibEditMode")
local LibSharedMedia = LibStub("LibSharedMedia-3.0")

local PreviewIconDataProvider = nil

---@return IconDataProviderMixin
local function GetRandomIcon()
	if PreviewIconDataProvider == nil then
		PreviewIconDataProvider =
			CreateAndInitFromMixin(IconDataProviderMixin, IconDataProviderExtraType.Spellbook, true)
	end

	return PreviewIconDataProvider:GetRandomIcon()
end

local BACKDROP_COORD_START = 0.0625
local BACKDROP_COORD_END = 1 - BACKDROP_COORD_START

---@class TargetedSpellsIconMixin
TargetedSpellsIconMixin = {}

function TargetedSpellsIconMixin:OnLoad()
	Private.EventRegistry:RegisterCallback(Private.Enum.Events.SETTING_CHANGED, self.OnSettingChanged, self)

	self.Bar:SetStatusBarTexture("")
	self.Cooldown:SetCountdownFont("GameFontHighlightHugeOutline")
	self.wasInterrupted = false
	self.doNotHideBefore = nil
	self.elapsed = 0
	Private.Utils.MaybeApplyElvUISkin(self)
end

do
	local BORDER_EDGE_SIZES = {
		["Blizzard Tooltip"] = 16,
		["Blizzard Dialog"] = 8,
		["Blizzard Dialog Gold"] = 8,
		["Blizzard Achievement Wood"] = 6,
		["Blizzard Party"] = 8,
	}

	local BORDER_INSETS = {
		["Blizzard Tooltip"] = 3,
	}

	function TargetedSpellsIconMixin:ApplyBorderStyle(styleName)
		if styleName == "Solid" then
			self.BorderTopLeft:Hide()
			self.BorderTopRight:Hide()
			self.BorderBottomLeft:Hide()
			self.BorderBottomRight:Hide()
			self.BorderTop:Hide()
			self.BorderBottom:Hide()
			self.BorderLeft:Hide()
			self.BorderRight:Hide()

			self.BorderSolidTop:Show()
			self.BorderSolidBottom:Show()
			self.BorderSolidLeft:Show()
			self.BorderSolidRight:Show()
		elseif styleName == "None" then
			self.BorderSolidTop:Hide()
			self.BorderSolidBottom:Hide()
			self.BorderSolidLeft:Hide()
			self.BorderSolidRight:Hide()

			self.BorderTopLeft:Hide()
			self.BorderTopRight:Hide()
			self.BorderBottomLeft:Hide()
			self.BorderBottomRight:Hide()
			self.BorderTop:Hide()
			self.BorderBottom:Hide()
			self.BorderLeft:Hide()
			self.BorderRight:Hide()
		else
			self.BorderSolidTop:Hide()
			self.BorderSolidBottom:Hide()
			self.BorderSolidLeft:Hide()
			self.BorderSolidRight:Hide()

			local tableRef = self.kind == Private.Enum.FrameKind.Self and TargetedSpellsSaved.Settings.Self
				or TargetedSpellsSaved.Settings.Party

			local edgeSize = BORDER_EDGE_SIZES[styleName] or 8
			local outwardOffset = BORDER_INSETS[styleName] or 0
			local borderWidth = tableRef.Width + 2 * outwardOffset
			local borderHeight = tableRef.Height + 2 * outwardOffset

			-- replicates BackdropTemplateMixin:SetupTextureCoordinates using known
			-- dimensions instead of GetWidth()/GetHeight() to avoid secret errors
			local edgeRepeatX = math.max(0, borderWidth / edgeSize - 2 - BACKDROP_COORD_START)
			local edgeRepeatY = math.max(0, borderHeight / edgeSize - 2 - BACKDROP_COORD_START)

			self.BorderTopLeft:ClearAllPoints()
			self.BorderTopLeft:SetPoint("TOPLEFT", self, "TOPLEFT", -outwardOffset, outwardOffset)
			self.BorderTopLeft:SetSize(edgeSize, edgeSize)

			self.BorderTopRight:ClearAllPoints()
			self.BorderTopRight:SetPoint("TOPRIGHT", self, "TOPRIGHT", outwardOffset, outwardOffset)
			self.BorderTopRight:SetSize(edgeSize, edgeSize)

			self.BorderBottomLeft:ClearAllPoints()
			self.BorderBottomLeft:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", -outwardOffset, -outwardOffset)
			self.BorderBottomLeft:SetSize(edgeSize, edgeSize)

			self.BorderBottomRight:ClearAllPoints()
			self.BorderBottomRight:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", outwardOffset, -outwardOffset)
			self.BorderBottomRight:SetSize(edgeSize, edgeSize)

			self.BorderTop:SetHeight(edgeSize)
			self.BorderBottom:SetHeight(edgeSize)
			self.BorderLeft:SetWidth(edgeSize)
			self.BorderRight:SetWidth(edgeSize)

			local path = LibSharedMedia:Fetch(LibSharedMedia.MediaType.BORDER, styleName) or ""

			local sliceTexCoords = {
				[self.BorderTopLeft] = {
					0.5078125,
					BACKDROP_COORD_START,
					0.5078125,
					BACKDROP_COORD_END,
					0.6171875,
					BACKDROP_COORD_START,
					0.6171875,
					BACKDROP_COORD_END,
				},
				[self.BorderTopRight] = {

					0.6328125,
					BACKDROP_COORD_START,
					0.6328125,
					BACKDROP_COORD_END,
					0.7421875,
					BACKDROP_COORD_START,
					0.7421875,
					BACKDROP_COORD_END,
				},
				[self.BorderBottomLeft] = {

					0.7578125,
					BACKDROP_COORD_START,
					0.7578125,
					BACKDROP_COORD_END,
					0.8671875,
					BACKDROP_COORD_START,
					0.8671875,
					BACKDROP_COORD_END,
				},
				[self.BorderBottomRight] = {

					0.8828125,
					BACKDROP_COORD_START,
					0.8828125,
					BACKDROP_COORD_END,
					0.9921875,
					BACKDROP_COORD_START,
					0.9921875,
					BACKDROP_COORD_END,
				},
				[self.BorderTop] = {

					0.2578125,
					edgeRepeatX,
					0.3671875,
					edgeRepeatX,
					0.2578125,
					BACKDROP_COORD_START,
					0.3671875,
					BACKDROP_COORD_START,
				},
				[self.BorderBottom] = {

					0.3828125,
					edgeRepeatX,
					0.4921875,
					edgeRepeatX,
					0.3828125,
					BACKDROP_COORD_START,
					0.4921875,
					BACKDROP_COORD_START,
				},
				[self.BorderLeft] = {

					0.0078125,
					BACKDROP_COORD_START,
					0.0078125,
					edgeRepeatY,
					0.1171875,
					BACKDROP_COORD_START,
					0.1171875,
					edgeRepeatY,
				},
				[self.BorderRight] = {

					0.1328125,
					BACKDROP_COORD_START,
					0.1328125,
					edgeRepeatY,
					0.2421875,
					BACKDROP_COORD_START,
					0.2421875,
					edgeRepeatY,
				},
			}

			for tex, entry in pairs(sliceTexCoords) do
				tex:SetTexture(path, "REPEAT", "REPEAT")
				tex:SetTexCoord(entry[1], entry[2], entry[3], entry[4], entry[5], entry[6], entry[7], entry[8])
				tex:Show()
			end
		end
	end
end

function TargetedSpellsIconMixin:SetId(id)
	self.id = id
end

function TargetedSpellsIconMixin:GetId()
	return self.id
end

function TargetedSpellsIconMixin:SetInterrupted(name, color)
	self.wasInterrupted = true
	self.doNotHideBefore = GetTime() + 0.95
	self.InterruptIcon:Show()
	self.Icon:SetDesaturated(true)
	self.Cooldown:SetDrawSwipe(false)
	self:SetShowDuration(false)
	self:HideGlow()

	if name == nil then
		return
	end

	local renderInterruptSourceName = false

	if self.kind == Private.Enum.FrameKind.Self then
		renderInterruptSourceName =
			TargetedSpellsSaved.Settings.Self.FeatureFlags[Private.Enum.FeatureFlag.RenderInterruptSourceName]
	else
		renderInterruptSourceName =
			TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.RenderInterruptSourceName]
	end

	if renderInterruptSourceName then
		self.InterruptSource:SetText(name)

		if color ~= nil then
			self.InterruptSource:SetTextColor(color.r, color.g, color.b)
		end
	end

	self.InterruptSource:Show()
end

function TargetedSpellsIconMixin:CanBeHidden(id)
	if self.wasInterrupted then
		return GetTime() >= self.doNotHideBefore
	end

	if id == nil then
		return true
	end

	return id == self:GetId()
end

do
	local formatter = C_StringUtil.CreateNumericRuleFormatter()
	formatter:SetBreakpoints({
		{
			threshold = 0,
			rounding = Enum.NumericRuleFormatRounding.Nearest,
			format = "%.1f",
			step = 0.1,
		},
		{
			threshold = 3,
			rounding = Enum.NumericRuleFormatRounding.Nearest,
			format = "%d",
		},
		{
			threshold = 60,
			rounding = Enum.NumericRuleFormatRounding.Nearest,
			format = "%d:%02d",
			components = {
				{
					div = 60,
				},
				{
					mod = 60,
				},
			},
		},
		{
			threshold = 300,
			rounding = Enum.NumericRuleFormatRounding.Up,
			format = "%dm",
			components = {
				{
					div = 60,
				},
			},
		},
	})

	function TargetedSpellsIconMixin:OnUpdate(elapsed)
		self.elapsed = self.elapsed + elapsed

		if self.elapsed < 0.1 then
			return
		end

		self.elapsed = self.elapsed - 0.1

		if self.duration == nil then
			return
		end

		self.Cooldown.DurationText:SetText(self.duration:FormatRemainingDuration(formatter))
	end
end

function TargetedSpellsIconMixin:SetShowDuration(showDuration)
	self.Cooldown.DurationText:SetShown(showDuration)
	self:SetScript("OnUpdate", showDuration and self.OnUpdate or nil)
end

--- shamelessly ~~stolen~~ repurposed from WeakAuras2
function TargetedSpellsIconMixin:OnSizeChanged()
	local width = TargetedSpellsSaved.Settings.Self.Width
	local height = TargetedSpellsSaved.Settings.Self.Height
	local zoom = TargetedSpellsSaved.Settings.Self.IconZoom

	local coordinates = { 0, 0, 0, 1, 1, 0, 1, 1 }
	local aspectRatio = width / height

	local xRatio = aspectRatio < 1 and aspectRatio or 1
	local yRatio = aspectRatio > 1 and 1 / aspectRatio or 1

	for i = 1, #coordinates, 1 do
		local coordinate = coordinates[i]

		if i % 2 == 1 then
			coordinates[i] = (coordinate - 0.5) * (xRatio / zoom) + 0.5
		else
			coordinates[i] = (coordinate - 0.5) * (yRatio / zoom) + 0.5
		end
	end

	self.Icon:SetTexCoord(unpack(coordinates))

	local topleftRelativePoint = select(2, self.Overlay:GetPointByName("TOPLEFT"))
	local bottomrightRelativePoint = select(2, self.Overlay:GetPointByName("BOTTOMRIGHT"))
	self.Overlay:ClearAllPoints()

	do
		local fifteenPercent = 0.15 * width
		PixelUtil.SetPoint(self.Overlay, "TOPLEFT", topleftRelativePoint, "TOPLEFT", -fifteenPercent, fifteenPercent)
	end

	do
		local fifteenPercent = 0.15 * height
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

function TargetedSpellsIconMixin:OnSettingChanged(key, flagIdOrValue, newBool)
	if self.kind == Private.Enum.FrameKind.Self then
		if key == Private.Settings.Keys.Self.Width then
			PixelUtil.SetSize(self, flagIdOrValue, TargetedSpellsSaved.Settings.Self.Height)
		elseif key == Private.Settings.Keys.Self.Height then
			PixelUtil.SetSize(self, TargetedSpellsSaved.Settings.Self.Width, flagIdOrValue)
		elseif
			key == Private.Settings.Keys.Self.FontSize
			or key == Private.Settings.Keys.Self.Font
			or key == Private.Settings.Keys.Self.FontFlags
		then
			self:SetFont()
		elseif key == Private.Settings.Keys.Self.IconZoom then
			self:OnSizeChanged()
		elseif key == Private.Settings.Keys.Self.GlowType then
			self:HideGlow()

			if TargetedSpellsSaved.Settings.Self.FeatureFlags[Private.Enum.FeatureFlag.GlowImportant] then
				self:ShowGlow(self:IsSpellImportant(LibEditMode:IsInEditMode() and Private.Utils.RollDice()))
			end
		elseif key == Private.Settings.Keys.Self.BorderStyle then
			self:ApplyBorderStyle(flagIdOrValue)
		elseif key == Private.Settings.Keys.Self.FeatureFlags then
			if flagIdOrValue == Private.Enum.FeatureFlag.ShowDuration then
				self:SetShowDuration(
					TargetedSpellsSaved.Settings.Self.FeatureFlags[Private.Enum.FeatureFlag.ShowDuration]
				)
			elseif flagIdOrValue == Private.Enum.FeatureFlag.ShowSwipe then
				self.Cooldown:SetDrawSwipe(newBool)
			elseif flagIdOrValue == Private.Enum.FeatureFlag.GlowImportant then
				self:ShowGlow(self:IsSpellImportant(LibEditMode:IsInEditMode() and Private.Utils.RollDice()))
			elseif flagIdOrValue == Private.Enum.FeatureFlag.OnlyImportant then
				self:SetAlphaFromBoolean(not newBool or self:IsSpellImportant())
			end
		end
	else
		if key == Private.Settings.Keys.Party.Width then
			PixelUtil.SetSize(self, flagIdOrValue, TargetedSpellsSaved.Settings.Party.Height)
		elseif key == Private.Settings.Keys.Party.Height then
			PixelUtil.SetSize(self, TargetedSpellsSaved.Settings.Party.Width, flagIdOrValue)
		elseif
			key == Private.Settings.Keys.Party.FontSize
			or key == Private.Settings.Keys.Party.Font
			or key == Private.Settings.Keys.Party.FontFlags
		then
			self:SetFont()
		elseif key == Private.Settings.Keys.Party.Opacity then
			self:SetAlpha(flagIdOrValue)
		elseif key == Private.Settings.Keys.Party.IconZoom then
			self:OnSizeChanged()
		elseif key == Private.Settings.Keys.Party.GlowType then
			self:HideGlow()

			if TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.GlowImportant] then
				self:ShowGlow(self:IsSpellImportant(LibEditMode:IsInEditMode() and Private.Utils.RollDice()))
			end
		elseif key == Private.Settings.Keys.Party.BorderStyle then
			self:ApplyBorderStyle(flagIdOrValue)
		elseif key == Private.Settings.Keys.Party.FeatureFlags then
			if flagIdOrValue == Private.Enum.FeatureFlag.ShowDuration then
				self:SetShowDuration(
					TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.ShowDuration]
				)
			elseif flagIdOrValue == Private.Enum.FeatureFlag.ShowSwipe then
				self.Cooldown:SetDrawSwipe(newBool)
			elseif flagIdOrValue == Private.Enum.FeatureFlag.GlowImportant then
				self:ShowGlow(self:IsSpellImportant(LibEditMode:IsInEditMode() and Private.Utils.RollDice()))
			elseif flagIdOrValue == Private.Enum.FeatureFlag.OnlyImportant then
				self:SetAlphaFromBoolean(not newBool or self:IsSpellImportant())
			end
		end
	end
end

do
	function TargetedSpellsIconMixin:SetDuration(duration)
		self.duration = duration
		self.Cooldown:SetCooldownFromDurationObject(duration)
	end
end

function TargetedSpellsIconMixin:GetDuration()
	return self.duration
end

function TargetedSpellsIconMixin:SetStartTime(startTime)
	self.startTime = startTime or GetTime()
end

function TargetedSpellsIconMixin:GetStartTime()
	return self.startTime
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

function TargetedSpellsIconMixin:ShowGlow(isImportant)
	local glowType = TargetedSpellsSaved.Settings.Self.GlowType

	if glowType == Private.Enum.GlowType.Star4 then
		if self._Star4 == nil then
			self._Star4 =
				CreateStar4Glow(self, TargetedSpellsSaved.Settings.Self.Width, TargetedSpellsSaved.Settings.Self.Height)
		end

		self._Star4:Show()
		self._Star4.Inner:Show()
		self._Star4.Outer:Show()
		self._Star4.Animation:Play()

		self._Star4:SetAlphaFromBoolean(isImportant)
	elseif glowType == Private.Enum.GlowType.PixelGlow then
		Private.Glows.PixelGlow_Start(
			self,
			TargetedSpellsSaved.Settings.Self.Width,
			TargetedSpellsSaved.Settings.Self.Height
		)

		self._PixelGlow:SetAlphaFromBoolean(isImportant)
	elseif glowType == Private.Enum.GlowType.AutoCastGlow then
		Private.Glows.AutoCastGlow_Start(
			self,
			TargetedSpellsSaved.Settings.Self.Width,
			TargetedSpellsSaved.Settings.Self.Height
		)

		self._AutoCastGlow:SetAlphaFromBoolean(isImportant)
	elseif glowType == Private.Enum.GlowType.ProcGlow then
		Private.Glows.ProcGlow_Start(
			self,
			TargetedSpellsSaved.Settings.Self.Width,
			TargetedSpellsSaved.Settings.Self.Height
		)

		self._ProcGlow:SetAlphaFromBoolean(isImportant)
	end
end

function TargetedSpellsIconMixin:HideGlow()
	if self._Star4 ~= nil then
		self._Star4:Hide()
		self._Star4.Inner:Hide()
		self._Star4.Outer:Hide()
		self._Star4.Animation:Stop()
	end

	Private.Glows.PixelGlow_Stop(self)
	Private.Glows.AutoCastGlow_Stop(self)
	Private.Glows.ProcGlow_Stop(self)
end

function TargetedSpellsIconMixin:IsSpellImportant(boolOverride)
	if boolOverride ~= nil then
		return boolOverride
	end

	if self.spellId == nil then
		return false
	end

	return C_Spell.IsSpellImportant(self.spellId)
end

function TargetedSpellsIconMixin:SetSpellId(spellId)
	self.spellId = spellId
	local texture = spellId and C_Spell.GetSpellTexture(spellId) or GetRandomIcon()
	self.Icon:SetTexture(texture)

	if spellId == nil then
		return
	end

	if not TargetedSpellsSaved.Settings.Self.FeatureFlags[Private.Enum.FeatureFlag.GlowImportant] then
		return
	end

	local isImportant = self:IsSpellImportant()

	self:ShowGlow(isImportant)

	if TargetedSpellsSaved.Settings.Self.FeatureFlags[Private.Enum.FeatureFlag.OnlyImportant] then
		self:SetAlphaFromBoolean(isImportant, 1, 0)
	end
end

function TargetedSpellsIconMixin:ShouldBeShown()
	return self.startTime ~= nil
end

function TargetedSpellsIconMixin:ClearStartTime()
	self.startTime = nil
end

function TargetedSpellsIconMixin:SetUnit(unit)
	self.unit = unit
end

function TargetedSpellsIconMixin:GetKind()
	return self.kind
end

function TargetedSpellsIconMixin:GetUnit()
	return self.unit
end

function TargetedSpellsIconMixin:PostCreate(unit, castingUnit)
	self:SetUnit(unit)

	if castingUnit ~= nil then
		local targetsThatUnit = PlayerIsSpellTarget(castingUnit, unit)
		self:SetAlphaFromBoolean(targetsThatUnit)
		self.Bar:SetValue(C_CurveUtil.EvaluateColorValueFromBoolean(targetsThatUnit, 1, 0))
	end
end

function TargetedSpellsIconMixin:Reset()
	self:SetParent(UIParent)
	self.Bar:ClearAllPoints()
	self.Bar:SetParent(self)
	self:ClearStartTime()
	self.spellId = nil
	self.Cooldown:Clear()
	self.duration = nil
	self:ClearAllPoints()
	self.wasInterrupted = false
	self.doNotHideBefore = nil
	self.InterruptIcon:Hide()
	self.Icon:SetDesaturated(false)
	self:SetId()
	self.InterruptSource:SetText()
	self.InterruptSource:Hide()
	self.InterruptSource:SetTextColor(1, 1, 1)
	self.Cooldown:SetScript("OnCooldownDone", nil)

	if TargetedSpellsSaved.Settings.Self.FeatureFlags[Private.Enum.FeatureFlag.GlowImportant] then
		local glowType = TargetedSpellsSaved.Settings.Self.GlowType

		if glowType == Private.Enum.GlowType.PixelGlow then
			if self._PixelGlow ~= nil then
				self._PixelGlow:SetAlpha(1)
			end
		elseif glowType == Private.Enum.GlowType.AutoCastGlow then
			if self._AutoCastGlow ~= nil then
				self._AutoCastGlow:SetAlpha(1)
			end
		elseif glowType == Private.Enum.GlowType.ProcGlow then
			if self._ProcGlow ~= nil then
				self._ProcGlow:SetAlpha(1)
			end
		end
	end

	self:HideGlow()

	self:SetShowDuration(TargetedSpellsSaved.Settings.Self.FeatureFlags[Private.Enum.FeatureFlag.ShowDuration])
	self.Cooldown:SetDrawSwipe(TargetedSpellsSaved.Settings.Self.FeatureFlags[Private.Enum.FeatureFlag.ShowSwipe])

	-- important to come last - the cooldown swipe ignores display status of its parent
	self:Hide()
end

function TargetedSpellsIconMixin:SetFont()
	local fontString = self.Cooldown:GetCountdownFontString()

	fontString:SetFont(
		TargetedSpellsSaved.Settings.Self.Font,
		TargetedSpellsSaved.Settings.Self.FontSize,
		TargetedSpellsSaved.Settings.Self.FontFlags[Private.Enum.FontFlags.OUTLINE] and "OUTLINE" or ""
	)

	if TargetedSpellsSaved.Settings.Self.FontFlags[Private.Enum.FontFlags.SHADOW] then
		fontString:SetShadowOffset(1, -1)
		fontString:SetShadowColor(0, 0, 0, 1)
	else
		fontString:SetShadowOffset(0, 0)
	end
end

function TargetedSpellsIconMixin:SetOnCooldownDone(callback)
	self.Cooldown:SetScript("OnCooldownDone", callback)
end
