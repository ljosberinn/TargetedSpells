---@type string, TargetedSpells
local _, Private = ...
local LibEditMode = LibStub("LibEditMode")
local LibSharedMedia = LibStub("LibSharedMedia-3.0")

local BACKDROP_COORD_START = 0.0625
local BACKDROP_COORD_END = 1 - BACKDROP_COORD_START

---@class TargetedSpellsIconMixin : TargetedSpellsMixin
TargetedSpellsIconMixin = CreateFromMixins(TargetedSpellsMixin)

function TargetedSpellsIconMixin:OnLoad()
	TargetedSpellsMixin.OnLoad(self)
	PixelUtil.SetSize(self, TargetedSpellsSaved.Settings.Self.Width, TargetedSpellsSaved.Settings.Self.Height)
	self.Bar:SetStatusBarTexture("")
	self.Cooldown:SetCountdownFormatter(Private.Utils.Formatter)
	self.Cooldown:SetCountdownFont("GameFontHighlightHugeOutline")
	self:SetFont()
	self:HideGlow()
	self:ApplyBorderStyle(TargetedSpellsSaved.Settings.Self.BorderStyle)
	self:SetShowDuration(TargetedSpellsSaved.Settings.Self.FeatureFlags[Private.Enum.FeatureFlag.ShowDuration])
	self.Cooldown:SetDrawSwipe(TargetedSpellsSaved.Settings.Self.FeatureFlags[Private.Enum.FeatureFlag.ShowSwipe])
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

			local edgeSize = BORDER_EDGE_SIZES[styleName] or 8
			local outwardOffset = BORDER_INSETS[styleName] or 0
			local borderWidth = TargetedSpellsSaved.Settings.Self.Width + 2 * outwardOffset
			local borderHeight = TargetedSpellsSaved.Settings.Self.Height + 2 * outwardOffset

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

			local path = LibSharedMedia:Fetch(LibSharedMedia.MediaType.BORDER, styleName) or ""

			for tex, entry in pairs(sliceTexCoords) do
				tex:SetTexture(path, "REPEAT", "REPEAT")
				tex:SetTexCoord(entry[1], entry[2], entry[3], entry[4], entry[5], entry[6], entry[7], entry[8])
				tex:Show()
			end
		end
	end
end

function TargetedSpellsIconMixin:SetInterrupted(name, color)
	TargetedSpellsMixin.SetInterrupted(self, name, color)
	self.Cooldown:SetDrawSwipe(false)

	if name == nil then
		return
	end

	if TargetedSpellsSaved.Settings.Self.FeatureFlags[Private.Enum.FeatureFlag.RenderInterruptSourceName] then
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
	local coordinates = { 0, 0, 0, 1, 1, 0, 1, 1 }
	local aspectRatio = TargetedSpellsSaved.Settings.Self.Width / TargetedSpellsSaved.Settings.Self.Height

	local xRatio = aspectRatio < 1 and aspectRatio or 1
	local yRatio = aspectRatio > 1 and 1 / aspectRatio or 1

	for i = 1, #coordinates, 1 do
		local coordinate = coordinates[i]

		if i % 2 == 1 then
			coordinates[i] = (coordinate - 0.5) * (xRatio / TargetedSpellsSaved.Settings.Self.IconZoom) + 0.5
		else
			coordinates[i] = (coordinate - 0.5) * (yRatio / TargetedSpellsSaved.Settings.Self.IconZoom) + 0.5
		end
	end

	self.Icon:SetTexCoord(unpack(coordinates))

	local topleftRelativePoint = select(2, self.Overlay:GetPointByName("TOPLEFT"))
	local bottomrightRelativePoint = select(2, self.Overlay:GetPointByName("BOTTOMRIGHT"))
	self.Overlay:ClearAllPoints()

	do
		local fifteenPercent = 0.15 * TargetedSpellsSaved.Settings.Self.Width
		PixelUtil.SetPoint(self.Overlay, "TOPLEFT", topleftRelativePoint, "TOPLEFT", -fifteenPercent, fifteenPercent)
	end

	do
		local fifteenPercent = 0.15 * TargetedSpellsSaved.Settings.Self.Height
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
			self:SetShowDuration(TargetedSpellsSaved.Settings.Self.FeatureFlags[Private.Enum.FeatureFlag.ShowDuration])
		elseif flagIdOrValue == Private.Enum.FeatureFlag.ShowSwipe then
			self.Cooldown:SetDrawSwipe(newBool)
		elseif flagIdOrValue == Private.Enum.FeatureFlag.GlowImportant then
			self:ShowGlow(self:IsSpellImportant(LibEditMode:IsInEditMode() and Private.Utils.RollDice()))
		elseif flagIdOrValue == Private.Enum.FeatureFlag.OnlyImportant then
			self:SetAlphaFromBoolean(not newBool or self:IsSpellImportant())
		end
	end
end

function TargetedSpellsIconMixin:PostCreate(info, OnCooldownDoneCallback)
	if info == nil then
		return
	end

	self.info = info
	self.Cooldown:SetCooldownFromDurationObject(info.duration)

	self:SetSpellId(info.spellId)

	local durationAlpha = self:SetDuration(info.duration)
	local targetsPlayer = PlayerIsSpellTarget(info.unit, "player")

	if TargetedSpellsSaved.Settings.Self.FeatureFlags[Private.Enum.FeatureFlag.OnlyImportant] then
		self:SetAlphaFromBoolean(
			targetsPlayer,
			C_CurveUtil.EvaluateColorValueFromBoolean(self:IsSpellImportant(), 0, durationAlpha),
			0
		)
	else
		self:SetAlphaFromBoolean(targetsPlayer, durationAlpha, 0)
	end

	self.Bar:SetValue(self:GetAlpha())

	if TargetedSpellsSaved.Settings.Self.FeatureFlags[Private.Enum.FeatureFlag.GlowImportant] then
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
	self.spellId = nil
	self.duration = nil
	self.Cooldown:Clear()
	self.info = nil
	self.Cooldown:SetScript("OnCooldownDone", nil)
	self.InterruptSource:SetText()
	self.InterruptSource:Hide()
	self.InterruptSource:SetTextColor(1, 1, 1)

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

	TargetedSpellsMixin.Reset(self)

	-- important to come last - the cooldown swipe ignores display status of its parent
	self:SetShowDuration(TargetedSpellsSaved.Settings.Self.FeatureFlags[Private.Enum.FeatureFlag.ShowDuration])
	self.Cooldown:SetDrawSwipe(TargetedSpellsSaved.Settings.Self.FeatureFlags[Private.Enum.FeatureFlag.ShowSwipe])
	-- Cooldown:Clear() re-inherits from SetCountdownFont, overwriting any previously applied font
	self:SetFont()
end

function TargetedSpellsIconMixin:SetFont()
	local fontString = self.Cooldown:GetCountdownFontString()

	Private.Utils.SafelySetFont(
		Private.Enum.FrameKind.Self,
		fontString,
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
