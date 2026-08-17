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

---@param region FontString
---@param element table<string, any>
---@param text string may be a secret value
---@param classColor colorRGB? may be a secret value
function Private.Utils.ApplyElementText(region, element, text, classColor)
	if element.useClassColor and classColor then
		region:SetTextColor(classColor.r, classColor.g, classColor.b)
		region:SetText(text)

		return
	end

	Private.Utils.ApplyElementTextColor(region, element)
	region:SetText(text)
end

---@param region FontString
---@param element table<string, any>
function Private.Utils.ApplyElementTextColor(region, element)
	if element.textColor == nil then
		return
	end

	local color = CreateColorFromHexString(element.textColor)
	region:SetTextColor(color.r, color.g, color.b, color.a)
end

do
	local BACKDROP_COORD_START = 0.0625
	local BACKDROP_COORD_END = 1 - BACKDROP_COORD_START

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
		local width, height = box.width, box.height
		local offsetX, offsetY = box.offsetX or 0, box.offsetY or 0

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

			local edgeSize = borderSize or BORDER_EDGE_SIZES[styleName] or 8
			local outwardOffset = BORDER_INSETS[styleName] or 0
			local borderWidth = width + 2 * outwardOffset
			local borderHeight = height + 2 * outwardOffset

			local edgeRepeatX = math.max(0, borderWidth / edgeSize - 2 - BACKDROP_COORD_START)
			local edgeRepeatY = math.max(0, borderHeight / edgeSize - 2 - BACKDROP_COORD_START)

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

	---@type table<any, table[]>
	local breakpointsByThreshold = {}

	---@type table<NumericFormatter, any>
	local appliedByFormatter = setmetatable({}, { __mode = "k" })
	local NIL_THRESHOLD = {}

	function Private.Utils.ApplyFractionThreshold(formatter, fractionThreshold)
		local thresholdKey = fractionThreshold == nil and NIL_THRESHOLD or fractionThreshold

		if appliedByFormatter[formatter] == thresholdKey then
			return
		end

		if breakpointsByThreshold[thresholdKey] == nil then
			breakpointsByThreshold[thresholdKey] = BuildCountdownBreakpoints(fractionThreshold)
		end

		formatter:SetBreakpoints(breakpointsByThreshold[thresholdKey])
		appliedByFormatter[formatter] = thresholdKey
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
		if values.active ~= false then
			local centerX = values.x or 0
			local centerY = values.y or 0

			if values.width and values.height then
				Include(centerX, centerY, values.width, values.height)
			elseif values.maxWidth and values.maxWidth > 0 then
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

---@type table<table, table<any, any>>
local layoutCache = setmetatable({}, { __mode = "k" })

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

---@param elements table<Element, table<string, any>>
---@return { width: number, height: number, offsetX: number, offsetY: number }
function Private.Utils.ComputeGroupExtent(elements)
	local core = elements[Private.Enum.Element.ProgressBar]

	if core ~= nil then
		return { width = core.width or 0, height = core.height or 0, offsetX = 0, offsetY = 0 }
	end

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

---@param template TargetedSpellsTemplate
---@param elements table<Element, table<string, any>>
---@return number width, number height
function Private.Utils.ComputeGroupFootprint(template, elements)
	if template == Private.Enum.Template.IconDuration then
		local icon = elements[Private.Enum.Element.Icon]
		local layout = Private.Utils.ComputeIconDurationLayout(elements)

		return layout.totalWidth, (icon and icon.height) or 0
	end

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
		if
			frame.boundBarParent ~= barParent
			or frame.boundX ~= layouting.x
			or frame.boundY ~= layouting.y
			or frame.boundIsHorizontal ~= layouting.isHorizontal
			or frame.boundIsGrowEnd ~= layouting.isGrowEnd
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

	---@param result table
	---@return boolean
	local function ImportV4Profile(result)
		local payload = result

		if result.Groups == nil then
			if result.Self == nil and result.Party == nil then
				return false
			end

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

			Private.Groups.Conform(TargetedSpellsSaved.Groups)

			Private.Groups.InvalidateOrder(TargetedSpellsSaved.Groups)

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

		if result == nil then
			return false
		end

		return ImportV4Profile(result)
	end

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
