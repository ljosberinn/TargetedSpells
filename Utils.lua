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
		-- fall back to a known-good font; the invalid one is not persisted anywhere
		fontString:SetFont("Fonts\\FRIZQT__.TTF", fontSize, fontFlags)
	end
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

	---@param frame TargetedSpellsBorderFrame owns the Border* regions and is the anchor origin
	---@param styleName string LSM border media name, or "Solid" / "None"
	---@param box { width: number, height: number, offsetX: number, offsetY: number } rectangle to wrap; its centre is offset from frame CENTER (known dims — never GetWidth(), so secret-safe)
	---@param borderSize number? edge/strip thickness; falls back to the border's natural size
	---@param borderColorHex string? AARRGGBB tint, or nil for untinted
	function Private.Utils.ApplyBorderStyle(frame, styleName, box, borderSize, borderColorHex)
		local borderColor = borderColorHex and CreateColorFromHexString(borderColorHex)
		-- the border wraps `box`, centred at frame CENTER + (offsetX, offsetY). For the
		-- icon this is the icon frame itself (offset 0); for the bar it's the union extent
		-- of the active boxed elements, so the border encloses the icon / target marker /
		-- duration too, not just the ProgressBar.
		local width, height = box.width, box.height
		local offsetX, offsetY = box.offsetX or 0, box.offsetY or 0
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

			for _, strip in ipairs({ frame.BorderSolidTop, frame.BorderSolidBottom, frame.BorderSolidLeft, frame.BorderSolidRight }) do
				if borderColor ~= nil then
					strip:SetVertexColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)
				end
				strip:Show()
			end
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

			local sliceTexCoords = {
				[frame.BorderTopLeft] = {
					0.5078125,
					BACKDROP_COORD_START,
					0.5078125,
					BACKDROP_COORD_END,
					0.6171875,
					BACKDROP_COORD_START,
					0.6171875,
					BACKDROP_COORD_END,
				},
				[frame.BorderTopRight] = {
					0.6328125,
					BACKDROP_COORD_START,
					0.6328125,
					BACKDROP_COORD_END,
					0.7421875,
					BACKDROP_COORD_START,
					0.7421875,
					BACKDROP_COORD_END,
				},
				[frame.BorderBottomLeft] = {
					0.7578125,
					BACKDROP_COORD_START,
					0.7578125,
					BACKDROP_COORD_END,
					0.8671875,
					BACKDROP_COORD_START,
					0.8671875,
					BACKDROP_COORD_END,
				},
				[frame.BorderBottomRight] = {
					0.8828125,
					BACKDROP_COORD_START,
					0.8828125,
					BACKDROP_COORD_END,
					0.9921875,
					BACKDROP_COORD_START,
					0.9921875,
					BACKDROP_COORD_END,
				},
				[frame.BorderTop] = {
					0.2578125,
					edgeRepeatX,
					0.3671875,
					edgeRepeatX,
					0.2578125,
					BACKDROP_COORD_START,
					0.3671875,
					BACKDROP_COORD_START,
				},
				[frame.BorderBottom] = {
					0.3828125,
					edgeRepeatX,
					0.4921875,
					edgeRepeatX,
					0.3828125,
					BACKDROP_COORD_START,
					0.4921875,
					BACKDROP_COORD_START,
				},
				[frame.BorderLeft] = {
					0.0078125,
					BACKDROP_COORD_START,
					0.0078125,
					edgeRepeatY,
					0.1171875,
					BACKDROP_COORD_START,
					0.1171875,
					edgeRepeatY,
				},
				[frame.BorderRight] = {
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
				if borderColor ~= nil then
					tex:SetVertexColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)
				else
					tex:SetVertexColor(1, 1, 1, 1)
				end
				tex:Show()
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

	-- Reconfigures a countdown formatter's fraction cutoff in place. Each frame owns
	-- its own formatter (thresholds are a per-element setting), so this is called on
	-- layout apply rather than once globally.
	---@param formatter NumericFormatter
	---@param fractionThreshold number?
	function Private.Utils.ApplyFractionThreshold(formatter, fractionThreshold)
		formatter:SetBreakpoints(BuildCountdownBreakpoints(fractionThreshold))
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
}

do
	local function sortAsc(a, b)
		return a:GetStartTime() < b:GetStartTime()
	end

	local function sortDesc(a, b)
		return a:GetStartTime() > b:GetStartTime()
	end

	function Private.Utils.SortFrames(frames, sortOrder)
		local isAscending = sortOrder == Private.Enum.SortOrder.Ascending

		table.sort(frames, isAscending and sortAsc or sortDesc)
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

-- Phase 7: the visual extent of a group's active elements, in CENTER→CENTER offset
-- space relative to the core element (which is the 0,0 origin). Returns the union
-- bounding box of every active *non-text* box — that includes the core, whose
-- `active` field is absent (omitActive) and so counts as active — plus any text
-- element carrying an explicit `maxWidth` cap. Auto-sized (uncapped) text is
-- deliberately excluded: its runtime width is unbounded, so a long name would
-- otherwise blow the extent out arbitrarily (Phase 7 step 2). Welded/decorative
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

---@param elements table<Element, table<string, any>>
---@return table<any, any> layout keyed by Element plus `gutterWidth`/`barWidth`
function Private.Utils.ComputeBarLayout(elements)
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

	return layout
end

-- Visual extent of a group's layout, for the edit-mode placeholder outline. A bar's
-- gutter + bar fill the full frame, so its extent is simply the core box; an icon group
-- has no ProgressBar and falls back to the free-positioned union.
---@param elements table<Element, table<string, any>>
---@return { width: number, height: number, offsetX: number, offsetY: number }
function Private.Utils.ComputeGroupExtent(elements)
	local core = elements[Private.Enum.Element.ProgressBar]

	if core ~= nil then
		return { width = core.width or 0, height = core.height or 0, offsetX = 0, offsetY = 0 }
	end

	return Private.Utils.ComputeElementExtent(elements)
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

function Private.Utils.MigratePartySettingsToV3(existing)
	local defaults = Private.Settings.GetPartyDefaultSettings()

	local compatibleKeys = {
		"Enabled",
		"LoadConditionContentType",
		"LoadConditionRole",
		"Font",
		"GlowType",
		"FontFlags",
	}

	for _, key in ipairs(compatibleKeys) do
		local value = existing[key]

		if value ~= nil and type(value) == type(defaults[key]) then
			defaults[key] = value
		end
	end

	return defaults
end

function Private.Utils.ApplyMigration(key, kind, defaults)
	local tableRef = kind == Private.Enum.FrameKind.Self and TargetedSpellsSaved.Settings.Self
		or TargetedSpellsSaved.Settings.Party

	if key == "Grow" and tableRef[key] == 1 then
		tableRef[key] = Private.Enum.Grow.Start
	end

	if key == "GlowType" and tableRef[key] == 3 then
		tableRef[key] = Private.Enum.GlowType.PixelGlow
	end

	if key == "ShowBorder" then
		local shown = tableRef[key]
		tableRef[key] = nil
		tableRef.BorderStyle = shown and defaults.BorderStyle or "None"
	end
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
		if layouting.isHorizontal then
			frame.Bar:SetSize(layouting.x, layouting.y)
		else
			frame.Bar:SetSize(layouting.y, layouting.x)
		end

		local texture = frame.Bar:GetStatusBarTexture()
		frame:ClearAllPoints()
		frame:SetPoint(layouting.originPoint, texture, layouting.originPoint)

		frame.Bar:SetOrientation(layouting.orientation)
		frame.Bar:SetReverseFill(layouting.isGrowEnd)
		frame.Bar:SetParent(barParent)
		frame:SetParent(frame.Bar)
		frame:SetFrameLevel(frame.Bar:GetFrameLevel() + 10)
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

	-- v4 profile import: accepts a v4 payload (has Groups) or a v3 payload
	-- (Self/Party), normalising the latter through the migration first, then
	-- adopts it wholesale — profile import means replacing your config. Returns
	-- whether anything actually changed.
	---@param result table
	---@return boolean
	local function ImportV4Profile(result)
		local payload = result

		if result.Groups == nil then
			if result.Self == nil and result.Party == nil then
				return false
			end

			-- a v3 profile string imported into a v4 config: migrate it first
			local temp = { Settings = { Self = result.Self, Party = result.Party } }
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

				TargetedSpellsSaved.Groups[id].Id = id
			end

			-- ids were added/removed in place above; drop the cached sort order
			Private.Groups.InvalidateOrder(TargetedSpellsSaved.Groups)

			TargetedSpellsSaved.TextToSpeech = Private.Utils.DeepCopy(payload.TextToSpeech)

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

		-- once migrated to the v4 group model, import runs the v4 path (which
		-- also accepts v3 strings by migrating them). Until then, the v3 path below.
		if TargetedSpellsSaved.Groups ~= nil then
			return ImportV4Profile(result)
		end

		local hasAnyChange = false

		---@param tableRef SavedVariablesSettingsParty|SavedVariablesSettingsSelf
		---@param kindString string
		---@param sourceData table
		---@param defaults table
		---@param eventKeys table
		local function ImportKindSettings(tableRef, kindString, sourceData, defaults, eventKeys)
			local anyPrimaryLoadConditionIsDisabled = false

			local enumByKey = {
				LoadConditionContentType = Private.Enum.ContentType,
				LoadConditionRole = Private.Enum.Role,
				FontFlags = Private.Enum.FontFlags,
				FeatureFlags = Private.Enum.FeatureFlag,
				AnnounceUntargetedSpells = Private.Enum.NpcType,
				AnnounceTargetedSpells = Private.Enum.NpcType,
			}

			local isLoadConditionKey = {
				LoadConditionContentType = true,
				LoadConditionRole = true,
			}

			for key, defaultValue in pairs(defaults) do
				local newValue = sourceData[key]
				local expectedType = type(defaultValue)

				if newValue ~= nil and type(newValue) == expectedType then
					local eventKey = eventKeys[key]
					local hasChanges = false

					if expectedType == "table" then
						local enumToCompareAgainst = enumByKey[key]

						if enumToCompareAgainst then
							local newTable = {}
							local allDisabled = true

							for _, id in pairs(enumToCompareAgainst) do
								if newValue[id] == nil then
									newTable[id] = tableRef[key][id]
								else
									newTable[id] = newValue[id]

									if newValue[id] ~= tableRef[key][id] then
										hasChanges = true
									end

									if newValue[id] then
										allDisabled = false
									end
								end
							end

							if allDisabled and isLoadConditionKey[key] then
								anyPrimaryLoadConditionIsDisabled = true
							end

							if hasChanges then
								tableRef[key] = newTable
								Private.Utils.ApplyMigration(key, kindString, defaults)
								Private.EventRegistry:TriggerEvent(
									Private.Enum.Events.SETTING_CHANGED,
									eventKey,
									newTable
								)
							end
						end
					elseif newValue ~= tableRef[key] then
						tableRef[key] = newValue
						Private.Utils.ApplyMigration(key, kindString, defaults)
						hasChanges = true

						if eventKey then
							Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, eventKey, newValue)
						end
					end

					if hasChanges then
						hasAnyChange = true
					end
				end
			end

			if anyPrimaryLoadConditionIsDisabled then
				tableRef.Enabled = false
				Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, eventKeys.Enabled, false)
			end
		end

		TargetedSpellsSaved.V3MigrationWarningSeen = true

		for kind, kindString in pairs(Private.Enum.FrameKind) do
			local sourceData = result[kind]

			if sourceData ~= nil then
				local tableRef = TargetedSpellsSaved.Settings[kind]
				local isSelf = kind == "Self"
				local defaults = isSelf and Private.Settings.GetSelfDefaultSettings()
					or Private.Settings.GetPartyDefaultSettings()
				local eventKeys = isSelf and Private.Settings.Keys.Self or Private.Settings.Keys.Party

				ImportKindSettings(tableRef, kindString, sourceData, defaults, eventKeys)

				if sourceData.Position ~= nil then
					local point, x, y = sourceData.Position.point, sourceData.Position.x, sourceData.Position.y
					-- v3 import path (only reachable pre-migration); frames are keyed by group id
					local frame = editModeFrameByGroupId[isSelf and 1 or 2]

					if
						frame ~= nil
						and (point ~= tableRef.Position.point or x ~= tableRef.Position.x or y ~= tableRef.Position.y)
					then
						frame:ClearAllPoints()
						PixelUtil.SetPoint(frame, "CENTER", UIParent, point, x, y)

						tableRef.Position.point = point
						tableRef.Position.x = x
						tableRef.Position.y = y

						local event = isSelf and Private.Enum.Events.SETTING_CHANGED
							or Private.Enum.Events.SETTING_CHANGED
						Private.EventRegistry:TriggerEvent(event, point, x, y)
					end
				end
			end
		end

		return hasAnyChange
	end

	function Private.Utils.Export()
		local payload
		if TargetedSpellsSaved.Groups ~= nil then
			-- v4: serialise the group model + hoisted TTS, not the old Settings tree
			payload = {
				SchemaVersion = TargetedSpellsSaved.SchemaVersion,
				Groups = TargetedSpellsSaved.Groups,
				TextToSpeech = TargetedSpellsSaved.TextToSpeech,
			}
		else
			payload = TargetedSpellsSaved.Settings
		end

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
	local function noop() end

	_G.TargetedSpellsAPI = {
		Import = Private.Utils.Import,
		Export = Private.Utils.Export,
		DecodeProfileString = DecodeProfileString,
		SetProfile = noop,
		GetProfileKeys = function()
			return { "Global" }
		end,
		GetCurrentProfileKey = function()
			return "Global"
		end,
		OpenConfig = noop,
		CloseConfig = noop,
	}
end
