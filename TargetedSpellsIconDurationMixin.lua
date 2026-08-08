---@type string, TargetedSpells
local _, Private = ...

---@class TargetedSpellsIconDurationMixin : TargetedSpellsMixin
TargetedSpellsIconDurationMixin = CreateFromMixins(TargetedSpellsMixin)

-- Runs `fn` for each icon cell. Every visual setting on this template is mirrored, and there
-- is exactly one Icon element driving both — so anything reaching for a cell goes through here
-- rather than naming IconCell/IconCellMirror twice and inviting the two to drift apart.
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

	-- The base mixin drives `self.Icon` and `self.InterruptIcon` directly (SetSpellId,
	-- SetInterrupted, Reset), and the Designer duck-types `frame.Icon`. Alias the left cell's
	-- regions so all of that keeps working untouched; the overrides below propagate to the
	-- mirror. XML assigns parentKeys before OnLoad runs, so the cells exist by now.
	self.Icon = self.IconCell.Icon
	self.InterruptIcon = self.IconCell.InterruptIcon

	self.Bar:SetStatusBarTexture("")

	-- per-frame formatters so each group's fraction threshold is independent
	self.durationFormatter = Private.Utils.CreateCountdownFormatter()

	-- The duration text updates itself from the cast's duration object — no OnUpdate. See
	-- C_DurationUtil.CreateDurationTextBinding; SetFormatter takes the same NumericFormatter
	-- the cooldown countdowns use, so the fraction threshold behaves identically here.
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

-- Places both cells and the duration text from the shared reflow layout. Called from
-- ApplyLayout and OnSizeChanged, so geometry has exactly one source.
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

	-- the FontString auto-sizes, so it gets a position but never a size: the layout's
	-- duration box is the *reserved* slot, not a cap on the text
	self.Duration:ClearAllPoints()
	PixelUtil.SetPoint(self.Duration, "CENTER", self, "CENTER", layout.duration.centerX, layout.duration.centerY)
end

-- Sizes and styles the frame from its assigned group's layout. Runs on acquire (PostCreate),
-- once the group is set — SetSize here drives OnSizeChanged.
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
			-- swipe and countdown number toggle independently; both seed off on this template
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

-- One border per cell, each wrapping its own icon — the borders are what make the two read as
-- two icons rather than one wide box. Both come from the single Border element.
function TargetedSpellsIconDurationMixin:ApplyBorderStyle(styleName)
	local border = self:GetElement(Private.Enum.Element.Border)
	local iconElement = self:GetElement(Private.Enum.Element.Icon)
	if iconElement == nil then
		return
	end

	-- each cell is its own anchor origin, so the box is unoffset within it
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

-- ── Glow: one per icon, never around the text ────────────────────────────────
-- The base lifecycle drives a single frame, because the appliedGlow* stamp that makes a
-- re-acquire cheap lives on the glowing frame. Here there are two, so these bypass
-- GetGlowFrame/GetGlowTarget and drive the per-frame workers once per cell. Sizing comes from
-- the Icon element, so each glow hugs its icon and the duration text is never enclosed.

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

-- Both cells show the same spell. Overriding the texture writer rather than SetSpellId keeps
-- the two in step for every caller, including the Designer's "restore the previous texture"
-- refresh — which writes art directly and would otherwise leave the cells showing
-- different icons after an unrelated widget edit.
function TargetedSpellsIconDurationMixin:SetIconTexture(texture)
	self.IconCell.Icon:SetTexture(texture)
	self.IconCellMirror.Icon:SetTexture(texture)
end

function TargetedSpellsIconDurationMixin:SetInterrupted(name, color)
	-- the base handles the left cell (via the aliases), the shared state, SetShowDuration
	-- and HideGlow — which this mixin's override already clears on both cells
	TargetedSpellsMixin.SetInterrupted(self, name, color)

	self.IconCellMirror.InterruptIcon:Show()
	self.IconCellMirror.Icon:SetDesaturated(true)

	ForEachCell(self, function(cell)
		cell.Cooldown:SetDrawSwipe(false)
	end)
end

-- Stops the countdown numbers on both cells and, more importantly, the duration text itself:
-- the binding is what would otherwise keep ticking after an interrupt.
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

	-- the cells are placed from the layout, and the frame's size just changed
	self:PositionElements()
end

function TargetedSpellsIconDurationMixin:PostCreate(info, OnCooldownDoneCallback)
	if info == nil then
		return
	end

	-- the Driver assigns the group before PostCreate; size/style from it now
	self:ApplyLayout()

	local group = self:GetGroup()

	self:SetUnit(info.unit)

	ForEachCell(self, function(cell)
		cell.Cooldown:SetCooldownFromDurationObject(info.duration)
	end)

	-- hands the text its own updater; nothing per-frame runs on our side
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
		-- a FontString we own outright: the binding writes text and colour but never the font,
		-- so the cheap stamped path is valid here (unlike a cooldown's countdown FontString,
		-- which Cooldown:Clear() silently re-inherits behind the stamp's back)
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

-- See the pool contract on TargetedSpellsMixin:Reset for what belongs here. The spell id, the
-- font, the formatter thresholds and the border are all re-applied unconditionally on acquire
-- and so are deliberately absent.
function TargetedSpellsIconDurationMixin:Reset()
	-- (3) the duration text's updater is bound to the cast that just ended. Nothing on the
	-- acquire path disables it, so this is the only place it can be stopped — a pooled frame
	-- that kept it would keep counting into a hidden FontString.
	self.durationBinding:SetEnabled(false)
	self.Duration:SetText("")

	local cooldown = self:GetElement(Private.Enum.Element.Cooldown)

	ForEachCell(self, function(cell)
		-- (1) stops the countdown, and (3) drops the closure bound to the finished cast:
		-- PostCreate rebinds it only when handed a callback, and neither preview path passes one.
		cell.Cooldown:Clear()
		cell.Cooldown:SetScript("OnCooldownDone", nil)
	end)

	-- (2) the mirror's interrupt state. The base Reset covers the left cell via the aliases.
	self.IconCellMirror.InterruptIcon:Hide()
	self.IconCellMirror.Icon:SetDesaturated(false)

	TargetedSpellsMixin.Reset(self)

	if cooldown ~= nil then
		-- (1) has to come last: the cooldown swipe ignores the display status of its parent,
		-- so this runs after the base Reset hides the frame. ApplyLayout re-applies both on
		-- the next acquire — these exist for the window the frame spends in the pool.
		ForEachCell(self, function(cell)
			cell.Cooldown:SetHideCountdownNumbers(cooldown.showCountdown == false)
			cell.Cooldown:SetDrawSwipe(cooldown.showSwipe)
		end)
	end
end
