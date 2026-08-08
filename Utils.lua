---@type string, TargetedSpells
local addonName, Private = ...

local LibSharedMedia = LibStub("LibSharedMedia-3.0")

---@class TargetedSpellsUtils
Private.Utils = {}

function Private.Utils.SafelySetFont(fontString, font, fontSize, fontFlags)
	local ok = pcall(function()
		fontString:SetFont(font, fontSize, fontFlags)
	end)

	if not ok then
		fontString:SetFont("Fonts\\FRIZQT__.TTF", fontSize, fontFlags)
	end
end

-- SafelySetFont, skipped when the same triple is already stamped on the region. A pooled
-- frame is usually re-acquired into the group it came from, so the font being applied is
-- normally the one already there — and this is the addon's highest-frequency call.
--
-- Deliberately NOT used for a cooldown's countdown FontString: Cooldown:Clear() silently
-- re-inherits the font from SetCountdownFont, which the stamp cannot observe, so those
-- keep going through SafelySetFont unconditionally.
---@param fontString TargetedSpellsStampedFontString
---@param font string
---@param fontSize number
---@param fontFlags string
function Private.Utils.SetFontIfChanged(fontString, font, fontSize, fontFlags)
	if
		fontString.appliedFont == font
		and fontString.appliedFontSize == fontSize
		and fontString.appliedFontFlags == fontFlags
	then
		return
	end

	Private.Utils.SafelySetFont(fontString, font, fontSize, fontFlags)

	fontString.appliedFont = font
	fontString.appliedFontSize = fontSize
	fontString.appliedFontFlags = fontFlags
end

-- ── Slice / solid border renderer (shared by the icon + bar mixins) ──────────
-- Both templates carry the same standard border regions (BorderSolid* strips +
-- Border* 8-slice pieces); this renders `styleName` into them. Kept here rather
-- than duplicated per mixin — the slice texcoord math is delicate and belongs in
-- one place (the plan's shared-math discipline). Sizes come from the caller's
-- known width/height, never GetWidth()/GetHeight(), to avoid secret-value taint.
do
	local BACKDROP_COORD_START = 0.0625
	local BACKDROP_COORD_END = 1 - BACKDROP_COORD_START

	-- natural edge sizes / insets per LSM border, used only as a fallback when the
	-- element carries no explicit borderSize (post-BackfillElements it always does)
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

	-- The set of border regions ApplyBorderStyle drives; both templates expose them.
	---@class TargetedSpellsBorderFrame : Frame
	---@field BorderSolidTop Texture
	---@field BorderSolidBottom Texture
	---@field BorderSolidLeft Texture
	---@field BorderSolidRight Texture
	---@field BorderTopLeft Texture
	---@field BorderTopRight Texture
	---@field BorderBottomLeft Texture
	---@field BorderBottomRight Texture
	---@field BorderTop Texture
	---@field BorderBottom Texture
	---@field BorderLeft Texture
	---@field BorderRight Texture
	--- the last-rendered border signature, stamped by ApplyBorderStyle so an unchanged
	--- re-apply costs one comparison instead of twelve regions' worth of C calls
	---@field appliedBorderStyle string?
	---@field appliedBorderWidth number?
	---@field appliedBorderHeight number?
	---@field appliedBorderOffsetX number?
	---@field appliedBorderOffsetY number?
	---@field appliedBorderSize number?
	---@field appliedBorderColor string?

	-- 8-slice texcoords keyed by region name, hoisted and mutated in place rather than
	-- rebuilt per call: only the four edge strips' repeat slots follow the box size (they
	-- are written just before the loop below), the other 48 numbers are constants. The
	-- loop consumes them synchronously, so sharing one table across every caller is safe.
	local SLICE_TEXCOORDS = {
		BorderTopLeft = {
			0.5078125,
			BACKDROP_COORD_START,
			0.5078125,
			BACKDROP_COORD_END,
			0.6171875,
			BACKDROP_COORD_START,
			0.6171875,
			BACKDROP_COORD_END,
		},
		BorderTopRight = {
			0.6328125,
			BACKDROP_COORD_START,
			0.6328125,
			BACKDROP_COORD_END,
			0.7421875,
			BACKDROP_COORD_START,
			0.7421875,
			BACKDROP_COORD_END,
		},
		BorderBottomLeft = {
			0.7578125,
			BACKDROP_COORD_START,
			0.7578125,
			BACKDROP_COORD_END,
			0.8671875,
			BACKDROP_COORD_START,
			0.8671875,
			BACKDROP_COORD_END,
		},
		BorderBottomRight = {
			0.8828125,
			BACKDROP_COORD_START,
			0.8828125,
			BACKDROP_COORD_END,
			0.9921875,
			BACKDROP_COORD_START,
			0.9921875,
			BACKDROP_COORD_END,
		},
		BorderTop = {
			0.2578125,
			0,
			0.3671875,
			0,
			0.2578125,
			BACKDROP_COORD_START,
			0.3671875,
			BACKDROP_COORD_START,
		},
		BorderBottom = {
			0.3828125,
			0,
			0.4921875,
			0,
			0.3828125,
			BACKDROP_COORD_START,
			0.4921875,
			BACKDROP_COORD_START,
		},
		BorderLeft = {
			0.0078125,
			BACKDROP_COORD_START,
			0.0078125,
			0,
			0.1171875,
			BACKDROP_COORD_START,
			0.1171875,
			0,
		},
		BorderRight = {
			0.1328125,
			BACKDROP_COORD_START,
			0.1328125,
			0,
			0.2421875,
			BACKDROP_COORD_START,
			0.2421875,
			0,
		},
	}

	---@param frame TargetedSpellsBorderFrame owns the Border* regions and is the anchor origin
	---@param styleName string LSM border media name, or "Solid" / "None"
	---@param box { width: number, height: number, offsetX: number, offsetY: number } rectangle to wrap; its centre is offset from frame CENTER (known dims — never GetWidth(), so secret-safe)
	---@param borderSize number? edge/strip thickness; falls back to the border's natural size
	---@param borderColorHex string? AARRGGBB tint, or nil for untinted
	function Private.Utils.ApplyBorderStyle(frame, styleName, box, borderSize, borderColorHex)
		-- the border wraps `box`, centred at frame CENTER + (offsetX, offsetY). For the
		-- icon this is the icon frame itself (offset 0); for the bar it's the union extent
		-- of the active boxed elements, so the border encloses the icon / target marker /
		-- duration too, not just the ProgressBar.
		local width, height = box.width, box.height
		local offsetX, offsetY = box.offsetX or 0, box.offsetY or 0

		-- What the border renders is a pure function of style, box and tint, and a pooled
		-- frame is normally re-acquired into the group it came from — so the whole 12-region
		-- reapply (and, for "None", 12 redundant Hide()s) is skipped when nothing changed.
		-- Anything that touches these regions behind our back must clear the stamp;
		-- currently nothing does.
		if
			frame.appliedBorderStyle == styleName
			and frame.appliedBorderWidth == width
			and frame.appliedBorderHeight == height
			and frame.appliedBorderOffsetX == offsetX
			and frame.appliedBorderOffsetY == offsetY
			and frame.appliedBorderSize == borderSize
			and frame.appliedBorderColor == borderColorHex
		then
			return
		end

		frame.appliedBorderStyle = styleName
		frame.appliedBorderWidth = width
		frame.appliedBorderHeight = height
		frame.appliedBorderOffsetX = offsetX
		frame.appliedBorderOffsetY = offsetY
		frame.appliedBorderSize = borderSize
		frame.appliedBorderColor = borderColorHex

		local borderColor = borderColorHex and CreateColorFromHexString(borderColorHex)
		local halfW, halfH = width / 2, height / 2

		if styleName == "Solid" then
			frame.BorderTopLeft:Hide()
			frame.BorderTopRight:Hide()
			frame.BorderBottomLeft:Hide()
			frame.BorderBottomRight:Hide()
			frame.BorderTop:Hide()
			frame.BorderBottom:Hide()
			frame.BorderLeft:Hide()
			frame.BorderRight:Hide()

			-- solid strips: thickness from borderSize, tint from borderColor, spanning the
			-- box edges (re-anchored to frame CENTER so they follow an offset extent)
			local size = borderSize or 1

			frame.BorderSolidTop:ClearAllPoints()
			frame.BorderSolidTop:SetPoint("TOPLEFT", frame, "CENTER", offsetX - halfW, offsetY + halfH)
			frame.BorderSolidTop:SetPoint("TOPRIGHT", frame, "CENTER", offsetX + halfW, offsetY + halfH)
			frame.BorderSolidTop:SetHeight(size)

			frame.BorderSolidBottom:ClearAllPoints()
			frame.BorderSolidBottom:SetPoint("BOTTOMLEFT", frame, "CENTER", offsetX - halfW, offsetY - halfH)
			frame.BorderSolidBottom:SetPoint("BOTTOMRIGHT", frame, "CENTER", offsetX + halfW, offsetY - halfH)
			frame.BorderSolidBottom:SetHeight(size)

			frame.BorderSolidLeft:ClearAllPoints()
			frame.BorderSolidLeft:SetPoint("TOPLEFT", frame, "CENTER", offsetX - halfW, offsetY + halfH)
			frame.BorderSolidLeft:SetPoint("BOTTOMLEFT", frame, "CENTER", offsetX - halfW, offsetY - halfH)
			frame.BorderSolidLeft:SetWidth(size)

			frame.BorderSolidRight:ClearAllPoints()
			frame.BorderSolidRight:SetPoint("TOPRIGHT", frame, "CENTER", offsetX + halfW, offsetY + halfH)
			frame.BorderSolidRight:SetPoint("BOTTOMRIGHT", frame, "CENTER", offsetX + halfW, offsetY - halfH)
			frame.BorderSolidRight:SetWidth(size)

			if borderColor ~= nil then
				frame.BorderSolidTop:SetVertexColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)
				frame.BorderSolidBottom:SetVertexColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)
				frame.BorderSolidLeft:SetVertexColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)
				frame.BorderSolidRight:SetVertexColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)
			end

			frame.BorderSolidTop:Show()
			frame.BorderSolidBottom:Show()
			frame.BorderSolidLeft:Show()
			frame.BorderSolidRight:Show()
		elseif styleName == "None" then
			frame.BorderSolidTop:Hide()
			frame.BorderSolidBottom:Hide()
			frame.BorderSolidLeft:Hide()
			frame.BorderSolidRight:Hide()

			frame.BorderTopLeft:Hide()
			frame.BorderTopRight:Hide()
			frame.BorderBottomLeft:Hide()
			frame.BorderBottomRight:Hide()
			frame.BorderTop:Hide()
			frame.BorderBottom:Hide()
			frame.BorderLeft:Hide()
			frame.BorderRight:Hide()
		else
			frame.BorderSolidTop:Hide()
			frame.BorderSolidBottom:Hide()
			frame.BorderSolidLeft:Hide()
			frame.BorderSolidRight:Hide()

			-- borderSize drives the slice edge thickness (per-texture natural sizes
			-- are the fallback when no group/border element is set)
			local edgeSize = borderSize or BORDER_EDGE_SIZES[styleName] or 8
			local outwardOffset = BORDER_INSETS[styleName] or 0
			local borderWidth = width + 2 * outwardOffset
			local borderHeight = height + 2 * outwardOffset

			-- replicates BackdropTemplateMixin:SetupTextureCoordinates using known
			-- dimensions instead of GetWidth()/GetHeight() to avoid secret errors
			local edgeRepeatX = math.max(0, borderWidth / edgeSize - 2 - BACKDROP_COORD_START)
			local edgeRepeatY = math.max(0, borderHeight / edgeSize - 2 - BACKDROP_COORD_START)

			-- corners anchored relative to frame CENTER so the slice follows the box's
			-- centre offset (outwardOffset pushes them outward for inset styles)
			frame.BorderTopLeft:ClearAllPoints()
			frame.BorderTopLeft:SetPoint("TOPLEFT", frame, "CENTER", offsetX - halfW - outwardOffset,
				offsetY + halfH + outwardOffset)
			frame.BorderTopLeft:SetSize(edgeSize, edgeSize)

			frame.BorderTopRight:ClearAllPoints()
			frame.BorderTopRight:SetPoint("TOPRIGHT", frame, "CENTER", offsetX + halfW + outwardOffset,
				offsetY + halfH + outwardOffset)
			frame.BorderTopRight:SetSize(edgeSize, edgeSize)

			frame.BorderBottomLeft:ClearAllPoints()
			frame.BorderBottomLeft:SetPoint("BOTTOMLEFT", frame, "CENTER", offsetX - halfW - outwardOffset,
				offsetY - halfH - outwardOffset)
			frame.BorderBottomLeft:SetSize(edgeSize, edgeSize)

			frame.BorderBottomRight:ClearAllPoints()
			frame.BorderBottomRight:SetPoint("BOTTOMRIGHT", frame, "CENTER", offsetX + halfW + outwardOffset,
				offsetY - halfH - outwardOffset)
			frame.BorderBottomRight:SetSize(edgeSize, edgeSize)

			frame.BorderTop:SetHeight(edgeSize)
			frame.BorderBottom:SetHeight(edgeSize)
			frame.BorderLeft:SetWidth(edgeSize)
			frame.BorderRight:SetWidth(edgeSize)

			-- the only size-dependent numbers in the whole slice map
			SLICE_TEXCOORDS.BorderTop[2] = edgeRepeatX
			SLICE_TEXCOORDS.BorderTop[4] = edgeRepeatX
			SLICE_TEXCOORDS.BorderBottom[2] = edgeRepeatX
			SLICE_TEXCOORDS.BorderBottom[4] = edgeRepeatX
			SLICE_TEXCOORDS.BorderLeft[4] = edgeRepeatY
			SLICE_TEXCOORDS.BorderLeft[8] = edgeRepeatY
			SLICE_TEXCOORDS.BorderRight[4] = edgeRepeatY
			SLICE_TEXCOORDS.BorderRight[8] = edgeRepeatY

			local path = LibSharedMedia:Fetch(LibSharedMedia.MediaType.BORDER, styleName) or ""

			for region, coordinates in pairs(SLICE_TEXCOORDS) do
				local texture = frame[region]

				texture:SetTexture(path, "REPEAT", "REPEAT")
				texture:SetTexCoord(
					coordinates[1],
					coordinates[2],
					coordinates[3],
					coordinates[4],
					coordinates[5],
					coordinates[6],
					coordinates[7],
					coordinates[8]
				)

				if borderColor ~= nil then
					texture:SetVertexColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)
				else
					texture:SetVertexColor(1, 1, 1, 1)
				end

				texture:Show()
			end
		end
	end
end

-- Recursive deep copy of a (possibly nested) table. Backs the designer's scratch
-- copy and the "copy layout from group" action; also used by Design.GetDefault so
-- callers can mutate the returned Elements without touching the code constant.
function Private.Utils.DeepCopy(source)
	if type(source) ~= "table" then
		return source
	end

	local copy = {}
	for key, value in pairs(source) do
		copy[key] = Private.Utils.DeepCopy(value)
	end
	return copy
end

-- Structural equality of two values (tables compared recursively). Used by the
-- v4 profile import to decide whether an imported config actually differs.
function Private.Utils.DeepEqual(left, right)
	if left == right then
		return true
	end
	if type(left) ~= "table" or type(right) ~= "table" then
		return false
	end
	for key, value in pairs(left) do
		if not Private.Utils.DeepEqual(value, right[key]) then
			return false
		end
	end
	for key in pairs(right) do
		if left[key] == nil then
			return false
		end
	end
	return true
end

do
	local IsLongCastCurve = C_CurveUtil.CreateCurve()
	IsLongCastCurve:SetType(Enum.LuaCurveType.Linear)
	IsLongCastCurve:AddPoint(0, 1)
	IsLongCastCurve:AddPoint(60, 1)
	IsLongCastCurve:AddPoint(60.001, 0)

	Private.Utils.IsLongCastCurve = IsLongCastCurve
end

do
	---@param fractionThreshold number?
	---@return table[]
	local function BuildCountdownBreakpoints(fractionThreshold)
		local breakpoints = {}

		if fractionThreshold ~= nil and fractionThreshold > 0 then
			-- clamp below the minutes rule so thresholds stay strictly ascending
			local cutoff = math.min(fractionThreshold, 59)
			breakpoints[#breakpoints + 1] = { threshold = 0, format = "%.1f" }
			breakpoints[#breakpoints + 1] = { threshold = cutoff, format = "%d" }
		else
			breakpoints[#breakpoints + 1] = { threshold = 0, format = "%d" }
		end

		breakpoints[#breakpoints + 1] = { threshold = 60, format = "%d:%02d", components = { { div = 60 }, { mod = 60 } } }
		breakpoints[#breakpoints + 1] = { threshold = 600, format = "%dm", components = { { div = 60 } } } -- 10 minutes
		breakpoints[#breakpoints + 1] = { threshold = 3600, format = "%dh", components = { { div = 3600 } } } -- 1 hour
		breakpoints[#breakpoints + 1] = { threshold = 86400, format = "%dd", components = { { div = 86400 } } } -- 1 day

		return breakpoints
	end

	---@type table<number, table[]>
	local breakpointsByThreshold = {}

	---@type table<NumericFormatter, number>
	local appliedByFormatter = setmetatable({}, { __mode = "k" })

	function Private.Utils.ApplyFractionThreshold(formatter, fractionThreshold)
		if appliedByFormatter[formatter] == fractionThreshold then
			return
		end

		if breakpointsByThreshold[fractionThreshold] == nil then
			breakpointsByThreshold[fractionThreshold] = BuildCountdownBreakpoints(fractionThreshold)
		end

		formatter:SetBreakpoints(breakpointsByThreshold[fractionThreshold])
		appliedByFormatter[formatter] = fractionThreshold
	end

	---@return NumericFormatter
	function Private.Utils.CreateCountdownFormatter()
		local formatter = C_StringUtil.CreateNumericRuleFormatter()

		Private.Utils.ApplyFractionThreshold(formatter, 3)

		return formatter
	end
end

Private.Utils.Pools = {
	Icon = CreateFramePool(
		"Frame",
		UIParent,
		"TargetedSpellsFrameTemplate",
		---@param pool FramePool<TargetedSpellsIconMixin>
		---@param frame TargetedSpellsIconMixin
		function(pool, frame)
			frame:Reset()
		end
	),
	Bar = CreateFramePool(
		"Frame",
		UIParent,
		"TargetedSpellsBarFrameTemplate",
		---@param pool FramePool<TargetedSpellsBarMixin>
		---@param frame TargetedSpellsBarMixin
		function(pool, frame)
			frame:Reset()
		end
	),
	IconDuration = CreateFramePool(
		"Frame",
		UIParent,
		"TargetedSpellsIconDurationFrameTemplate",
		---@param pool FramePool<TargetedSpellsIconDurationMixin>
		---@param frame TargetedSpellsIconDurationMixin
		function(pool, frame)
			frame:Reset()
		end
	),
}

do
	---@param a TargetedSpellsMixin
	---@param b TargetedSpellsMixin
	---@return boolean
	local function SortAscending(a, b)
		return a:GetStartTime() < b:GetStartTime()
	end

	---@param a TargetedSpellsMixin
	---@param b TargetedSpellsMixin
	---@return boolean
	local function SortDescending(a, b)
		return a:GetStartTime() > b:GetStartTime()
	end

	function Private.Utils.SortFrames(frames, sortOrder)
		local isAscending = sortOrder == Private.Enum.SortOrder.Ascending

		table.sort(frames, isAscending and SortAscending or SortDescending)
	end
end

function Private.Utils.RollDice()
	return math.random(1, 6) == 6
end

-- `out`, if given, is filled and returned instead of allocating a fresh table —
-- every field is overwritten unconditionally, so reusing a scratch table is safe.
-- AdjustLayout consumes the result synchronously and never retains it, which lets
-- the reposition hot path pass one reused table per pass (Driver.RepositionFrames).
function Private.Utils.CollectLayoutingArguments(direction, grow, width, height, gap, out)
	local isHorizontal = direction == Private.Enum.Direction.Horizontal
	local isGrowEnd = grow == Private.Enum.Grow.End

	out = out or {}
	out.isHorizontal = isHorizontal
	out.isGrowEnd = isGrowEnd
	out.orientation = isHorizontal and "HORIZONTAL" or "VERTICAL"
	out.x = (isHorizontal and width or height) + gap
	out.y = isHorizontal and height or width
	out.originPoint = isHorizontal and (isGrowEnd and "RIGHT" or "LEFT") or (isGrowEnd and "TOP" or "BOTTOM")
	out.relativePoint = isHorizontal and (isGrowEnd and "LEFT" or "RIGHT") or (isGrowEnd and "BOTTOM" or "TOP")
	return out
end

-- space relative to the core element (which is the 0,0 origin). Returns the union
-- bounding box of every active *non-text* box — that includes the core, whose
-- `active` field is absent (omitActive) and so counts as active — plus any text
-- element carrying an explicit `maxWidth` cap. Auto-sized (uncapped) text is
-- deliberately excluded: its runtime width is unbounded, so a long name would
-- elements (Overlay, Cooldown, Border, Background) have no width/height and so
-- contribute nothing — they draw within the core.
--
-- Returns { width, height, offsetX, offsetY } where (offsetX, offsetY) is the
-- centre of the extent relative to the core centre — usually non-zero, since
-- elements skew to one side. The edit-mode placeholder uses this so its outline
-- covers the pixels the display actually draws, not just the narrower core box.
--
-- Pure: reads only stored offsets/sizes, no live frame, so it is busted-coverable
-- like the bar-offset reconstruction.
function Private.Utils.ComputeElementExtent(elements)
	local hasBox = false
	local minX, minY, maxX, maxY

	---@param centerX number
	---@param centerY number
	---@param boxWidth number
	---@param boxHeight number
	local function Include(centerX, centerY, boxWidth, boxHeight)
		local halfWidth = boxWidth / 2
		local halfHeight = boxHeight / 2
		local left, right = centerX - halfWidth, centerX + halfWidth
		local bottom, top = centerY - halfHeight, centerY + halfHeight

		if not hasBox then
			minX, maxX, minY, maxY = left, right, bottom, top
			hasBox = true
		else
			minX = math.min(minX, left)
			maxX = math.max(maxX, right)
			minY = math.min(minY, bottom)
			maxY = math.max(maxY, top)
		end
	end

	for _, values in pairs(elements) do
		-- the core has no `active` field (omitActive) → nil counts as active
		if values.active ~= false then
			local centerX = values.x or 0
			local centerY = values.y or 0

			if values.width and values.height then
				-- non-text box (includes the core element)
				Include(centerX, centerY, values.width, values.height)
			elseif values.maxWidth and values.maxWidth > 0 then
				-- capped text: width is bounded by maxWidth, height ≈ its font size. The
				-- renderer edge-anchors by justifyH (x pins the LEFT/RIGHT/CENTER edge), so
				-- shift to the box centre before unioning. Nil justifyH → CENTER (no shift).
				local justifyH = values.justifyH or "CENTER"
				local boxCenterX = centerX
				if justifyH == "LEFT" then
					boxCenterX = centerX + values.maxWidth / 2
				elseif justifyH == "RIGHT" then
					boxCenterX = centerX - values.maxWidth / 2
				end
				Include(boxCenterX, centerY, values.maxWidth, values.fontSize or 0)
			end
		end
	end

	if not hasBox then
		return { width = 0, height = 0, offsetX = 0, offsetY = 0 }
	end

	return {
		width = maxX - minX,
		height = maxY - minY,
		offsetX = (minX + maxX) / 2,
		offsetY = (minY + maxY) / 2,
	}
end

-- Bar reflow layout. TargetMarker + Icon form a left "gutter": the *active* ones pack
-- against the frame's left edge (TargetMarker first, then Icon), and the ProgressBar fills
-- the remaining width to the right. So the bar's right edge is fixed at the frame's right
-- edge; its left edge and width reflow as the gutter grows/shrinks. Everything else hangs
-- off the bar — text pinned by its justifyH edge, Duration/InterruptShield off the (fixed)
-- right edge. `x`/`y` on those elements are insets from their anchor, not absolute offsets.
--
-- Pure: geometry only, in frame-CENTRE coordinates, shared by the renderer and the
-- designer markers so both agree. Returns a table keyed by Element, plus string keys
-- `gutterWidth` and `barWidth`:
--   box elements → { centerX, centerY, width, height }
--   text elements → { text = true, justifyH, edgeX, centerY, maxWidth, fontSize }
--                    (edgeX = frame-centre X of the justifyH-pinned edge; width auto-sizes)
local BAR_GUTTER_ORDER = {
	Private.Enum.Element.TargetMarker,
	Private.Enum.Element.Icon
}
local BAR_RIGHT_BOXES = {
	Private.Enum.Element.DurationCooldown,
	Private.Enum.Element.InterruptShield
}
local BAR_TEXTS = {
	Private.Enum.Element.SpellName,
	Private.Enum.Element.TargetName,
	Private.Enum.Element
		.InterruptSource
}

-- Memo for the reflow layouts (ComputeBarLayout / ComputeIconDurationLayout), keyed by the
-- Elements table it was computed from and weak so a discarded group/scratch table takes its
-- layout with it (same shape as Groups' sortedIdCache). A frame acquire computes the same
-- layout three to four times over — renderer, border, glow width — from a table that is not
-- mutated in between.
--
-- One cache serves both functions: an Elements table belongs to exactly one template, and a
-- template swap replaces it wholesale (Groups.SetTemplate) rather than mutating it, so the two
-- can never collide on a key.
--
-- The layout is only ever read, never mutated, so handing every caller the same table is
-- safe. Elements tables ARE mutated in place in two places (the Designer's live scratch
-- and Design.BackfillElements), and both call InvalidateLayout.
---@type table<table, table<any, any>>
local layoutCache = setmetatable({}, { __mode = "k" })

-- Drops the memoised layout for an Elements table. Must be called by anything that
-- mutates one in place; replacing the table wholesale needs no call (the new table simply
-- has no entry).
---@param elements table<Element, table<string, any>>?
function Private.Utils.InvalidateLayout(elements)
	if elements ~= nil then
		layoutCache[elements] = nil
	end
end

---@param elements table<Element, table<string, any>>
---@return table<any, any> layout keyed by Element plus `gutterWidth`/`barWidth`
function Private.Utils.ComputeBarLayout(elements)
	local cached = layoutCache[elements]

	if cached ~= nil then
		return cached
	end

	local core = elements[Private.Enum.Element.ProgressBar]
	local total = (core and core.width) or 0
	local height = (core and core.height) or 0
	local halfTotal = total / 2

	local gutterWidth = 0
	for _, tag in ipairs(BAR_GUTTER_ORDER) do
		local element = elements[tag]
		if element ~= nil and element.active ~= false then
			gutterWidth = gutterWidth + (element.width or 0)
		end
	end

	local barLeft = -halfTotal + gutterWidth
	local barRight = halfTotal
	local barCenter = (barLeft + barRight) / 2

	local layout = {
		gutterWidth = gutterWidth,
		barWidth = total - gutterWidth
	}

	layout[Private.Enum.Element.ProgressBar] = {
		centerX = barCenter,
		centerY = 0,
		width = total - gutterWidth,
		height = height
	}

	-- gutter elements packed from the frame's left edge; only active ones occupy a slot
	local cursorLeft = -halfTotal
	for _, tag in ipairs(BAR_GUTTER_ORDER) do
		local element = elements[tag]
		if element ~= nil and element.active ~= false then
			local width = element.width or 0
			layout[tag] = {
				centerX = cursorLeft + width / 2 + (element.x or 0),
				centerY = element.y or 0,
				width = width,
				height = element.height or 0,
			}
			cursorLeft = cursorLeft + width
		end
	end

	-- right-hugging boxes: their right edge sits at the (fixed) bar right + x inset
	for _, tag in ipairs(BAR_RIGHT_BOXES) do
		local element = elements[tag]
		if element ~= nil then
			local width = element.width or 0
			layout[tag] = {
				centerX = barRight + (element.x or 0) - width / 2,
				centerY = element.y or 0,
				width = width,
				height = element.height or 0,
			}
		end
	end

	-- text: pinned by justifyH to the matching bar edge, x an inset from that edge
	for _, tag in ipairs(BAR_TEXTS) do
		local element = elements[tag]
		if element ~= nil then
			local justifyH = element.justifyH or "CENTER"
			local edgeX
			if justifyH == "LEFT" then
				edgeX = barLeft + (element.x or 0)
			elseif justifyH == "RIGHT" then
				edgeX = barRight + (element.x or 0)
			else
				edgeX = barCenter + (element.x or 0)
			end

			layout[tag] = {
				text = true,
				justifyH = justifyH,
				edgeX = edgeX,
				centerY = element.y or 0,
				maxWidth = element.maxWidth,
				fontSize = element.fontSize,
			}
		end
	end

	layoutCache[elements] = layout

	return layout
end

local DURATION_WIDTH_RATIO = 2.6

---@param elements table<Element, table<string, any>>
---@return table<any, any> layout keyed by the string/Element keys listed above
function Private.Utils.ComputeIconDurationLayout(elements)
	local cached = layoutCache[elements]

	if cached ~= nil then
		return cached
	end

	local icon = elements[Private.Enum.Element.Icon]
	local duration = elements[Private.Enum.Element.Duration]

	local iconWidth = (icon and icon.width) or 0
	local iconHeight = (icon and icon.height) or 0
	local gap = (duration and duration.gap) or 0
	local fontSize = (duration and duration.countdownFontSize) or 0
	local durationWidth = fontSize * DURATION_WIDTH_RATIO
	local totalWidth = iconWidth * 2 + gap * 2 + durationWidth

	-- each cell's centre sits half an icon in from its own edge of the assembly
	local cellOffset = totalWidth / 2 - iconWidth / 2

	local layout = {
		totalWidth = totalWidth,
		durationWidth = durationWidth,
		iconLeft = { centerX = -cellOffset, centerY = 0, width = iconWidth, height = iconHeight },
		iconRight = { centerX = cellOffset, centerY = 0, width = iconWidth, height = iconHeight },
		duration = {
			centerX = 0,
			centerY = (duration and duration.y) or 0,
			width = durationWidth,
			height = fontSize,
		},
	}

	-- designer-facing aliases: one marker per configurable element
	layout[Private.Enum.Element.Icon] = {
		centerX = 0,
		centerY = 0,
		width = totalWidth,
		height = iconHeight,
	}
	layout[Private.Enum.Element.Duration] = layout.duration

	layoutCache[elements] = layout

	return layout
end

-- Visual extent of a group's layout, for the edit-mode placeholder outline. A bar's
-- gutter + bar fill the full frame, so its extent is simply the core box; an icon+duration
-- assembly likewise fills its frame; a plain icon group falls back to the free-positioned union.
---@param elements table<Element, table<string, any>>
---@return { width: number, height: number, offsetX: number, offsetY: number }
function Private.Utils.ComputeGroupExtent(elements)
	local core = elements[Private.Enum.Element.ProgressBar]

	if core ~= nil then
		return { width = core.width or 0, height = core.height or 0, offsetX = 0, offsetY = 0 }
	end

	-- the Duration element exists only on the icon+duration template, whose two cells and text
	-- span more than the single Icon box ComputeElementExtent would find
	if elements[Private.Enum.Element.Duration] ~= nil then
		local layout = Private.Utils.ComputeIconDurationLayout(elements)
		local icon = elements[Private.Enum.Element.Icon]

		return {
			width = layout.totalWidth,
			height = (icon and icon.height) or 0,
			offsetX = 0,
			offsetY = 0,
		}
	end

	return Private.Utils.ComputeElementExtent(elements)
end

-- The box a group's frames occupy for stacking purposes, which is NOT always the core
-- element's box: the icon+duration core is one icon, but the frame is the whole assembly.
-- GroupController:Relayout feeds this into CollectLayoutingArguments.
--
-- Getting this wrong is invisible in Vertical mode — AdjustLayout anchors each frame to the
-- spine texture point-to-point, so a too-narrow spine still centres the frame — and only shows
-- as wrong spacing in Horizontal. Hence a named helper rather than an inline core read.
---@param template TargetedSpellsTemplate
---@param elements table<Element, table<string, any>>
---@return number width, number height
function Private.Utils.ComputeGroupFootprint(template, elements)
	if template == Private.Enum.Template.IconDuration then
		local icon = elements[Private.Enum.Element.Icon]
		local layout = Private.Utils.ComputeIconDurationLayout(elements)

		return layout.totalWidth, (icon and icon.height) or 0
	end

	-- every other template's frame IS its core element's box
	local coreTag = template == Private.Enum.Template.Bar and Private.Enum.Element.ProgressBar
		or Private.Enum.Element.Icon
	local core = elements[coreTag]

	return (core and core.width) or 0, (core and core.height) or 0
end

function Private.Utils.ShowMigrationPopup()
	EventRegistry:RegisterFrameEventAndCallback("FIRST_FRAME_RENDERED", function(ownerId)
		EventRegistry:UnregisterFrameEventAndCallback("FIRST_FRAME_RENDERED", ownerId)

		C_Timer.After(3, function()
			Private.Utils.ShowStaticPopup({
				whileDead = true,
				button1 = OKAY,
				text = Private.L.Functionality.V3MigrationWarning,
			})
		end)
	end)
end

function Private.Utils.AdjustLayout(
	frames,
	layouting,
	barParent,
	firstAnchorPoint,
	firstOffsetX,
	firstOffsetY
)
	---@type Texture?
	local prevStatusBarTexture = nil

	for _, frame in ipairs(frames) do
		-- Spine binding: the Bar's size/orientation/fill direction and the frame↔Bar
		-- parenting are a pure function of the group's Direction/Grow/core size and of the
		-- container, so they change on acquire or on a Reconfigure — never because a sibling
		-- frame came or went. A relayout that changes only the anchor chain skips them. The
		-- stamp lives on the frame and is cleared by Reset, so a pooled frame always rebinds.
		if
			frame.boundBarParent ~= barParent
			or frame.boundX ~= layouting.x
			or frame.boundY ~= layouting.y
			or frame.boundIsHorizontal ~= layouting.isHorizontal
			or frame.boundIsGrowEnd ~= layouting.isGrowEnd
			-- the frame's own level is derived from the Bar's, so a level the Bar picked up
			-- from elsewhere has to re-derive it; keeps the skip self-healing
			or frame.boundBarLevel ~= frame.Bar:GetFrameLevel()
		then
			if layouting.isHorizontal then
				frame.Bar:SetSize(layouting.x, layouting.y)
			else
				frame.Bar:SetSize(layouting.y, layouting.x)
			end

			frame.Bar:SetOrientation(layouting.orientation)
			frame.Bar:SetReverseFill(layouting.isGrowEnd)
			frame.Bar:SetParent(barParent)
			frame:SetParent(frame.Bar)
			frame:SetFrameLevel(frame.Bar:GetFrameLevel() + 10)

			frame.boundBarParent = barParent
			frame.boundX = layouting.x
			frame.boundY = layouting.y
			frame.boundIsHorizontal = layouting.isHorizontal
			frame.boundIsGrowEnd = layouting.isGrowEnd
			frame.boundBarLevel = frame.Bar:GetFrameLevel()
		end

		local texture = frame.Bar:GetStatusBarTexture()
		frame:ClearAllPoints()
		frame:SetPoint(layouting.originPoint, texture, layouting.originPoint)

		frame.Bar:ClearAllPoints()
		frame.Bar:SetValue(frame:GetAlpha())

		if prevStatusBarTexture == nil then
			frame.Bar:SetPoint(layouting.originPoint, barParent, firstAnchorPoint, firstOffsetX, firstOffsetY)
		else
			frame.Bar:SetPoint(layouting.originPoint, prevStatusBarTexture, layouting.relativePoint, 0, 0)
		end

		frame:Show()

		prevStatusBarTexture = texture
	end
end

function Private.Utils.CreateEditablePopup(title, text, button1)
	return {
		text = title,
		button1 = button1,
		hasEditBox = true,
		hasWideEditBox = true,
		editBoxWidth = 350,
		hideOnEscape = true,
		OnShow = function(popupSelf)
			local editBox = popupSelf:GetEditBox()
			editBox:SetText(text)
			editBox:HighlightText()

			local ctrlDown = false

			editBox:SetScript("OnKeyDown", function(_, key)
				if key == "LCTRL" or key == "RCTRL" or key == "LMETA" or key == "RMETA" then
					ctrlDown = true
				end
			end)
			editBox:SetScript("OnKeyUp", function(_, key)
				C_Timer.After(0.2, function()
					ctrlDown = false
				end)

				if ctrlDown and (key == "C" or key == "X") then
					StaticPopup_Hide(addonName)
				end
			end)
		end,
		EditBoxOnEscapePressed = function(popupSelf)
			popupSelf:GetParent():Hide()
		end,
		EditBoxOnTextChanged = function(popupSelf)
			-- ctrl + x sets the text to "" but this triggers hiding and shouldn't trigger resetting the text
			local currentText = popupSelf:GetText()

			if currentText == "" or currentText == text then
				return
			end

			popupSelf:SetText(text)
		end,
	}
end

function Private.Utils.ShowStaticPopup(args)
	args.id = addonName
	args.whileDead = true

	StaticPopupDialogs[addonName] = args

	StaticPopup_Hide(addonName)
	StaticPopup_Show(addonName)
end

---@param string string
---@return table
local function DecodeProfileString(string)
	return C_EncodingUtil.DeserializeCBOR(C_EncodingUtil.DecodeBase64(string))
end

do
	---@type table<integer, Frame>
	local editModeFrameByGroupId = {}

	function Private.Utils.RegisterEditModeFrame(groupId, frame)
		editModeFrameByGroupId[groupId] = frame
	end

	function Private.Utils.GetEditModeFrame(groupId)
		return editModeFrameByGroupId[groupId]
	end

	-- Profile import: accepts a v4 payload (has Groups) or a v3 payload (Self/Party),
	-- normalising the latter through the migration first, then adopts it wholesale —
	-- profile import means replacing your config. Returns whether anything actually
	-- changed.
	---@param result table
	---@return boolean
	local function ImportV4Profile(result)
		local payload = result

		if result.Groups == nil then
			if result.Self == nil and result.Party == nil then
				return false
			end

			-- A v3 profile string imported into a v4 config: migrate it first. The
			-- warning flag is pre-stamped because an exported profile is already
			-- v3-shaped — only a live pre-v3 config needs the party reset.
			local temp = {
				V3MigrationWarningSeen = true,
				Settings = { Self = result.Self, Party = result.Party },
			}
			Private.Migration.Apply(temp)
			payload = temp
		end

		local changed = not Private.Utils.DeepEqual(
			{ Groups = TargetedSpellsSaved.Groups, TextToSpeech = TargetedSpellsSaved.TextToSpeech },
			{ Groups = payload.Groups, TextToSpeech = payload.TextToSpeech }
		)

		if changed then
			-- Update groups IN PLACE so the transitional Settings views and the
			-- edit-mode `self.group` refs (which captured these tables) survive the
			-- import. Replacing the tables wholesale would strand those references.
			local incoming = Private.Utils.DeepCopy(payload.Groups)

			for id in pairs(TargetedSpellsSaved.Groups) do
				if incoming[id] == nil then
					TargetedSpellsSaved.Groups[id] = nil
				end
			end

			for id, group in pairs(incoming) do
				local existing = TargetedSpellsSaved.Groups[id]

				if existing == nil then
					TargetedSpellsSaved.Groups[id] = group
				else
					table.wipe(existing)
					for key, value in pairs(group) do
						existing[key] = value
					end
				end
			end

			-- An imported payload may be as incomplete as whatever version exported it.
			-- Conform re-stamps every Id from its key and heals missing container/element
			-- fields, so a sparse imported group is completed rather than left partial.
			Private.Groups.Conform(TargetedSpellsSaved.Groups)

			-- ids were added/removed in place above; drop the cached sort order
			Private.Groups.InvalidateOrder(TargetedSpellsSaved.Groups)

			-- Same in-place rule as the groups above, and it has to reach one level
			-- deeper: the edit-mode announcement dropdowns capture the
			-- AnnounceUntargetedSpells / AnnounceTargetedSpells tables themselves
			-- (EditMode.lua, MultiDropdown), so replacing either one leaves the panel
			-- reading and writing an orphan until the next reload.
			-- walked as a plain map here, not as the typed record it is elsewhere
			---@type table<string, any>
			local incomingTextToSpeech = Private.Utils.DeepCopy(payload.TextToSpeech)
			---@type table<string, any>
			local textToSpeech = TargetedSpellsSaved.TextToSpeech

			for key in pairs(textToSpeech) do
				if incomingTextToSpeech[key] == nil then
					textToSpeech[key] = nil
				end
			end

			for key, value in pairs(incomingTextToSpeech) do
				local existing = textToSpeech[key]

				if type(existing) == "table" and type(value) == "table" then
					table.wipe(existing)
					for id, enabled in pairs(value) do
						existing[id] = enabled
					end
				else
					textToSpeech[key] = value
				end
			end

			Private.EventRegistry:TriggerEvent(Private.Enum.Events.PROFILE_IMPORTED)
		end

		return changed
	end

	function Private.Utils.Import(string)
		local ok, result = pcall(DecodeProfileString, string)

		if not ok then
			if result ~= nil then
				print(result)
			end

			return false
		end

		-- just a type check
		if result == nil then
			return false
		end

		return ImportV4Profile(result)
	end

	-- serialises the group model + hoisted TTS; Init guarantees both exist
	function Private.Utils.Export()
		local payload = {
			SchemaVersion = TargetedSpellsSaved.SchemaVersion,
			Groups = TargetedSpellsSaved.Groups,
			TextToSpeech = TargetedSpellsSaved.TextToSpeech,
		}

		return C_EncodingUtil.EncodeBase64(C_EncodingUtil.SerializeCBOR(payload))
	end
end

do
	---@class SlashCommandEntry
	---@field name string
	---@field description string
	---@field handler fun(rest: string)

	---@type SlashCommandEntry[]
	local commands = {}
	---@type table<string, SlashCommandEntry>
	local byName = {}

	function Private.Utils.RegisterSlashCommand(name, description, handler)
		name = string.lower(name)
		local entry = byName[name]

		if entry then
			entry.description = description
			entry.handler = handler
			return
		end

		entry = { name = name, description = description, handler = handler }
		byName[name] = entry
		commands[#commands + 1] = entry
	end

	local key = string.upper(addonName)
	local slashToken = "targetedspells"

	_G[string.format("SLASH_%s1", key)] = "/" .. slashToken

	SlashCmdList[key] = function(message)
		local command, args = (message or ""):match("^%s*(%S*)%s*(.-)%s*$")

		if not command then
			return
		end

		command = string.lower(command)
		args = args or ""

		local entry = byName[command]

		if entry == nil then
			print(Private.L.SlashCommands.Header)

			for index = 1, #commands do
				local cmd = commands[index]

				print(string.format("  /%s %s - %s", slashToken, cmd.name, cmd.description))
			end

			return
		end

		entry.handler(args)
	end
end

do
	---@return nil
	local function Noop() end

	_G.TargetedSpellsAPI = {
		Import = Private.Utils.Import,
		Export = Private.Utils.Export,
		DecodeProfileString = DecodeProfileString,
		SetProfile = Noop,
		GetProfileKeys = function()
			return { "Global" }
		end,
		GetCurrentProfileKey = function()
			return "Global"
		end,
		OpenConfig = Noop,
		CloseConfig = Noop,
	}
end
