---@type string, TargetedSpells
local addonName, Private = ...

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

---@param element TargetedSpellsMixin
---@param width number
---@param height number
local function ResizeSpellActivationAlert(element, width, height, startPlay)
	local alertFrame = element.SpellActivationAlert

	if alertFrame == nil then
		return
	end

	-- default scaling as per `ActionButtonSpellAlerts` > `GetAlertFrame`
	alertFrame:SetSize(width * 1.4, height * 1.4)

	-- this may need adjusting further down the line
	local factor = 1

	alertFrame.ProcStartFlipbook:ClearAllPoints()
	alertFrame.ProcStartFlipbook:SetPoint("TOPLEFT", element, -width * factor, height * factor)
	alertFrame.ProcStartFlipbook:SetPoint("BOTTOMRIGHT", element, height * factor, -width * factor)

	if startPlay then
		alertFrame.ProcLoop:Play()
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

	ResizeSpellActivationAlert(self, width, height, false)
end

local actionButtonSpellAlertManagerPatched = false

---@param bool boolean
local function MaybePatchActionButtonSpellAlertManager(bool)
	if actionButtonSpellAlertManagerPatched or bool == false then
		return
	end

	actionButtonSpellAlertManagerPatched = true

	hooksecurefunc(ActionButtonSpellAlertManager, "ShowAlert", function(self, element)
		if element.kind == nil then
			return
		end

		if element.kind == Private.Enum.FrameKind.Self and not TargetedSpellsSaved.Settings.Self.GlowImportant then
			return
		end

		if element.kind == Private.Enum.FrameKind.Party and not TargetedSpellsSaved.Settings.Party.GlowImportant then
			return
		end

		local width, height = element:GetSize()
		ResizeSpellActivationAlert(element, width, height, true)
	end)
end

table.insert(Private.LoginFnQueue, function()
	MaybePatchActionButtonSpellAlertManager(
		TargetedSpellsSaved.Settings.Self.GlowImportant or TargetedSpellsSaved.Settings.Party.GlowImportant
	)
end)

local function GetBackdropTemplate()
	-- literally the defaults from https://warcraft.wiki.gg/wiki/BackdropTemplate
	return {
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileEdge = true,
		tileSize = 8,
		edgeSize = 8,
		insets = { left = 1, right = 1, top = 1, bottom = 1 },
	}
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
		elseif key == Private.Settings.Keys.Self.ShowBorder then
			if value then
				self:SetBackdrop(GetBackdropTemplate())
			else
				self:ClearBackdrop()
			end
		elseif key == Private.Settings.Keys.Self.GlowImportant then
			MaybePatchActionButtonSpellAlertManager(value)
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
		elseif key == Private.Settings.Keys.Party.ShowBorder then
			if value then
				self:SetBackdrop(GetBackdropTemplate())
			else
				self:ClearBackdrop()
			end
		elseif key == Private.Settings.Keys.Party.GlowImportant then
			MaybePatchActionButtonSpellAlertManager(value)
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

function TargetedSpellsMixin:ShowGlow()
	ActionButtonSpellAlertManager:ShowAlert(self)
end

function TargetedSpellsMixin:HideGlow()
	-- internally nilchecks so safe to call unconditionally
	ActionButtonSpellAlertManager:HideAlert(self)
end

do
	---@type table<number, boolean>
	local platerProfileImportantCastsCache = Private.IsMidnight and nil or {}
	local cacheInitialized = false

	function TargetedSpellsMixin:SetSpellId(spellId)
		local texture = spellId and C_Spell.GetSpellTexture(spellId) or GetRandomIcon()
		self.Icon:SetTexture(texture)

		if
			-- todo: verify this is fine with secret values
			spellId == nil
			or (self.kind == Private.Enum.FrameKind.Self and not TargetedSpellsSaved.Settings.Self.GlowImportant)
			or (self.kind == Private.Enum.FrameKind.Party and not TargetedSpellsSaved.Settings.Party.GlowImportant)
		then
			return
		end

		if Private.IsMidnight then
			self:ShowGlow()
			self.SpellActivationAlert:SetAlphaFromBoolean(C_Spell.IsSpellImportant(spellId))
		elseif Plater and Plater.db and Plater.db.profile and Plater.db.profile.script_data then
			if cacheInitialized then
				if platerProfileImportantCastsCache[spellId] == true then
					self:ShowGlow()
				end
			else
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
		end
	end
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

function TargetedSpellsMixin:PostCreate(unit, kind, castingUnit)
	self:SetUnit(unit)
	self:SetKind(kind)

	if castingUnit ~= nil then
		if Private.IsMidnight then
			self:SetAlphaFromBoolean(UnitIsSpellTarget(castingUnit, unit))
		end
	end
end

function TargetedSpellsMixin:Reset()
	self:ClearStartTime()
	self.Cooldown:Clear()
	self:ClearAllPoints()
	self:Hide()

	self:HideGlow()
end

function TargetedSpellsMixin:AttemptToPlaySound(contentType)
	if
		self.kind == Private.Enum.FrameKind.Self
		and TargetedSpellsSaved.Settings.Self.PlaySound
		and TargetedSpellsSaved.Settings.Self.LoadConditionSoundContentType[contentType]
		and TargetedSpellsSaved.Settings.Self.Sound ~= nil
	then
		Private.Utils.AttemptToPlaySound(
			TargetedSpellsSaved.Settings.Self.Sound,
			TargetedSpellsSaved.Settings.Self.SoundChannel
		)
	else
		print(
			"not playing sound because:",
			self.kind == Private.Enum.FrameKind.Self and "isnt self" or nil,
			TargetedSpellsSaved.Settings.Self.PlaySound and "disabled" or nil,
			TargetedSpellsSaved.Settings.Self.LoadConditionSoundContentType[contentType] and "content type doesnt apply"
				or nil
		)
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
