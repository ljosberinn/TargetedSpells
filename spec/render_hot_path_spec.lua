---@diagnostic disable: undefined-global, undefined-field

-- Covers the render hot path's allocation/call-count reductions (ISSUE-103 / ISSUE-107):
-- the memoised bar layout, the breakpoint memo + threshold early-out, the font change
-- detection, and the border signature skip. All four are caches, so every test here is
-- really about invalidation: the value must be right, and it must change when its inputs do.

local b = require("spec.bootstrap")
local Private = b.Private
local Enum = Private.Enum
local Element = Enum.Element

local function barDefaults()
	return Private.Design.GetDefault(Enum.Template.Bar)
end

describe("ComputeBarLayout memoisation", function()
	it("returns the same table for repeated calls on an unmutated Elements table", function()
		local elements = barDefaults()

		assert.equals(Private.Utils.ComputeBarLayout(elements), Private.Utils.ComputeBarLayout(elements))
	end)

	it("keys on the table, so a separate copy computes its own layout", function()
		local first = barDefaults()
		local second = barDefaults()

		local firstLayout = Private.Utils.ComputeBarLayout(first)
		local secondLayout = Private.Utils.ComputeBarLayout(second)

		assert.is_false(firstLayout == secondLayout)
		assert.same(firstLayout, secondLayout)
	end)

	it("recomputes after an explicit invalidation, and the new value reflects the mutation", function()
		local elements = barDefaults()

		local before = Private.Utils.ComputeBarLayout(elements)
		assert.equals(270, before.barWidth)

		elements[Element.TargetMarker].active = true
		Private.Utils.InvalidateLayout(elements)

		local after = Private.Utils.ComputeBarLayout(elements)
		assert.is_false(before == after)
		assert.equals(240, after.barWidth)
	end)

	it("BackfillElements invalidates the group it healed", function()
		local group = { Template = Enum.Template.Bar, Elements = barDefaults() }

		local before = Private.Utils.ComputeBarLayout(group.Elements)
		group.Elements[Element.ProgressBar].width = 400
		Private.Design.BackfillElements(group)

		local after = Private.Utils.ComputeBarLayout(group.Elements)
		assert.is_false(before == after)
		assert.equals(370, after.barWidth) -- 400 less the 30px icon gutter
	end)

	it("tolerates a nil Elements table on invalidation", function()
		assert.has_no_error(function()
			Private.Utils.InvalidateLayout(nil)
		end)
	end)
end)

describe("ApplyFractionThreshold", function()
	local function formatterStub()
		return {
			applications = 0,
			SetBreakpoints = function(formatter, breakpoints)
				formatter.applications = formatter.applications + 1
				formatter.breakpoints = breakpoints
			end,
		}
	end

	it("skips the apply when the threshold has not changed for that formatter", function()
		local formatter = formatterStub()

		Private.Utils.ApplyFractionThreshold(formatter, 3)
		assert.equals(1, formatter.applications)

		Private.Utils.ApplyFractionThreshold(formatter, 3)
		Private.Utils.ApplyFractionThreshold(formatter, 3)
		assert.equals(1, formatter.applications)
	end)

	it("re-applies when the threshold changes, then again when it changes back", function()
		local formatter = formatterStub()

		Private.Utils.ApplyFractionThreshold(formatter, 3)
		local three = formatter.breakpoints

		Private.Utils.ApplyFractionThreshold(formatter, 5)
		assert.equals(2, formatter.applications)
		assert.is_false(three == formatter.breakpoints)

		Private.Utils.ApplyFractionThreshold(formatter, 3)
		assert.equals(3, formatter.applications)
		-- memoised by threshold: the same list comes back rather than a fresh one
		assert.equals(three, formatter.breakpoints)
	end)

	it("shares one memoised list between formatters on the same threshold", function()
		local first, second = formatterStub(), formatterStub()

		Private.Utils.ApplyFractionThreshold(first, 7)
		Private.Utils.ApplyFractionThreshold(second, 7)

		assert.equals(first.breakpoints, second.breakpoints)
	end)

	it("treats nil as its own threshold and builds the no-fraction list for it", function()
		local formatter = formatterStub()

		Private.Utils.ApplyFractionThreshold(formatter, nil)
		assert.equals(1, formatter.applications)
		-- no fraction cutoff → one leading integer rule instead of the %.1f + %d pair
		assert.equals("%d", formatter.breakpoints[1].format)
		assert.equals(0, formatter.breakpoints[1].threshold)

		Private.Utils.ApplyFractionThreshold(formatter, nil)
		assert.equals(1, formatter.applications)

		Private.Utils.ApplyFractionThreshold(formatter, 3)
		assert.equals(2, formatter.applications)
		assert.equals("%.1f", formatter.breakpoints[1].format)
	end)

	it("clamps a threshold above the minutes rule so breakpoints stay ascending", function()
		local formatter = formatterStub()

		Private.Utils.ApplyFractionThreshold(formatter, 120)

		assert.equals(59, formatter.breakpoints[2].threshold)
		assert.is_true(formatter.breakpoints[2].threshold < formatter.breakpoints[3].threshold)
	end)
end)

describe("SetFontIfChanged", function()
	local function fontStringStub()
		return {
			applications = 0,
			SetFont = function(fontString, font, fontSize, fontFlags)
				fontString.applications = fontString.applications + 1
				fontString.font = font
				fontString.fontSize = fontSize
				fontString.fontFlags = fontFlags
			end,
		}
	end

	it("applies once and skips an identical triple", function()
		local fontString = fontStringStub()

		Private.Utils.SetFontIfChanged(fontString, "Fonts\\ARIALN.TTF", 12, "OUTLINE")
		Private.Utils.SetFontIfChanged(fontString, "Fonts\\ARIALN.TTF", 12, "OUTLINE")

		assert.equals(1, fontString.applications)
		assert.equals("Fonts\\ARIALN.TTF", fontString.font)
	end)

	it("re-applies when any one of font, size or flags changes", function()
		local fontString = fontStringStub()

		Private.Utils.SetFontIfChanged(fontString, "Fonts\\ARIALN.TTF", 12, "OUTLINE")
		Private.Utils.SetFontIfChanged(fontString, "Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
		assert.equals(2, fontString.applications)

		Private.Utils.SetFontIfChanged(fontString, "Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
		assert.equals(3, fontString.applications)

		Private.Utils.SetFontIfChanged(fontString, "Fonts\\FRIZQT__.TTF", 14, "")
		assert.equals(4, fontString.applications)
		assert.equals("", fontString.fontFlags)
	end)

	it("still applies the fallback font when the requested one errors", function()
		local fontString = fontStringStub()

		fontString.SetFont = function(target, font, fontSize, fontFlags)
			if font == "bogus" then
				error("invalid font")
			end

			target.applications = target.applications + 1
			target.font = font
			target.fontSize = fontSize
			target.fontFlags = fontFlags
		end

		Private.Utils.SetFontIfChanged(fontString, "bogus", 12, "")

		assert.equals(1, fontString.applications)
		assert.equals("Fonts\\FRIZQT__.TTF", fontString.font)
	end)
end)

describe("ApplyBorderStyle", function()
	local BORDER_REGIONS = {
		"BorderSolidTop",
		"BorderSolidBottom",
		"BorderSolidLeft",
		"BorderSolidRight",
		"BorderTopLeft",
		"BorderTopRight",
		"BorderBottomLeft",
		"BorderBottomRight",
		"BorderTop",
		"BorderBottom",
		"BorderLeft",
		"BorderRight",
	}

	-- A frame carrying the twelve border regions, each recording what was done to it. The
	-- shared `calls` counter is what the signature-skip tests assert on: a skipped re-apply
	-- must touch no region at all.
	local function borderFrame()
		local frame = { calls = 0, texCoords = {}, textures = {}, colors = {}, shown = {} }

		---@param name string
		local function region(name)
			local function noted()
				return function()
					frame.calls = frame.calls + 1
				end
			end

			return {
				ClearAllPoints = noted(),
				SetPoint = noted(),
				SetSize = noted(),
				SetWidth = noted(),
				SetHeight = noted(),
				SetTexture = function(_, path)
					frame.calls = frame.calls + 1
					frame.textures[name] = path
				end,
				SetTexCoord = function(_, ...)
					frame.calls = frame.calls + 1
					frame.texCoords[name] = { ... }
				end,
				SetVertexColor = function(_, r, g, b, a)
					frame.calls = frame.calls + 1
					frame.colors[name] = { r, g, b, a }
				end,
				Show = function()
					frame.calls = frame.calls + 1
					frame.shown[name] = true
				end,
				Hide = function()
					frame.calls = frame.calls + 1
					frame.shown[name] = false
				end,
			}
		end

		for _, name in ipairs(BORDER_REGIONS) do
			frame[name] = region(name)
		end

		return frame
	end

	local function box(width, height)
		return { width = width, height = height, offsetX = 0, offsetY = 0 }
	end

	describe("8-slice texcoords", function()
		it("writes the constant corner coordinates", function()
			local frame = borderFrame()

			Private.Utils.ApplyBorderStyle(frame, "Test Border", box(100, 20), 8, nil)

			assert.same({ 0.5078125, 0.0625, 0.5078125, 0.9375, 0.6171875, 0.0625, 0.6171875, 0.9375 },
				frame.texCoords.BorderTopLeft)
			assert.same({ 0.6328125, 0.0625, 0.6328125, 0.9375, 0.7421875, 0.0625, 0.7421875, 0.9375 },
				frame.texCoords.BorderTopRight)
			assert.same({ 0.7578125, 0.0625, 0.7578125, 0.9375, 0.8671875, 0.0625, 0.8671875, 0.9375 },
				frame.texCoords.BorderBottomLeft)
			assert.same({ 0.8828125, 0.0625, 0.8828125, 0.9375, 0.9921875, 0.0625, 0.9921875, 0.9375 },
				frame.texCoords.BorderBottomRight)
		end)

		it("writes the size-dependent repeat factor into the four edge strips", function()
			local frame = borderFrame()

			-- edgeRepeat = box / edgeSize - 2 - 0.0625, per BackdropTemplateMixin
			local repeatX = 100 / 8 - 2 - 0.0625
			local repeatY = 20 / 8 - 2 - 0.0625

			Private.Utils.ApplyBorderStyle(frame, "Test Border", box(100, 20), 8, nil)

			assert.same({ 0.2578125, repeatX, 0.3671875, repeatX, 0.2578125, 0.0625, 0.3671875, 0.0625 },
				frame.texCoords.BorderTop)
			assert.same({ 0.3828125, repeatX, 0.4921875, repeatX, 0.3828125, 0.0625, 0.4921875, 0.0625 },
				frame.texCoords.BorderBottom)
			assert.same({ 0.0078125, 0.0625, 0.0078125, repeatY, 0.1171875, 0.0625, 0.1171875, repeatY },
				frame.texCoords.BorderLeft)
			assert.same({ 0.1328125, 0.0625, 0.1328125, repeatY, 0.2421875, 0.0625, 0.2421875, repeatY },
				frame.texCoords.BorderRight)
		end)

		it("does not leak one frame's repeat factor into the next frame's", function()
			local wide = borderFrame()
			local narrow = borderFrame()

			Private.Utils.ApplyBorderStyle(wide, "Test Border", box(300, 20), 8, nil)
			Private.Utils.ApplyBorderStyle(narrow, "Test Border", box(100, 20), 8, nil)

			assert.equals(300 / 8 - 2 - 0.0625, wide.texCoords.BorderTop[2])
			assert.equals(100 / 8 - 2 - 0.0625, narrow.texCoords.BorderTop[2])
		end)

		it("tints every slice, or resets it to white when untinted", function()
			local tinted = borderFrame()
			Private.Utils.ApplyBorderStyle(tinted, "Test Border", box(100, 20), 8, "FF0000FF")
			assert.same({ 0, 0, 1, 1 }, tinted.colors.BorderTopLeft)

			local plain = borderFrame()
			Private.Utils.ApplyBorderStyle(plain, "Test Border", box(100, 20), 8, nil)
			assert.same({ 1, 1, 1, 1 }, plain.colors.BorderTopLeft)
		end)
	end)

	describe("Solid", function()
		it("shows the four strips and hides the slice pieces", function()
			local frame = borderFrame()

			Private.Utils.ApplyBorderStyle(frame, "Solid", box(100, 20), 2, "FF00FF00")

			assert.is_true(frame.shown.BorderSolidTop)
			assert.is_true(frame.shown.BorderSolidBottom)
			assert.is_true(frame.shown.BorderSolidLeft)
			assert.is_true(frame.shown.BorderSolidRight)
			assert.is_false(frame.shown.BorderTopLeft)
			assert.same({ 0, 1, 0, 1 }, frame.colors.BorderSolidRight)
		end)

		it("leaves the strips untinted when no colour is given", function()
			local frame = borderFrame()

			Private.Utils.ApplyBorderStyle(frame, "Solid", box(100, 20), 2, nil)

			assert.is_nil(frame.colors.BorderSolidTop)
			assert.is_true(frame.shown.BorderSolidTop)
		end)
	end)

	describe("signature skip", function()
		it("does no work at all when every input is unchanged", function()
			local frame = borderFrame()

			Private.Utils.ApplyBorderStyle(frame, "Test Border", box(100, 20), 8, "FF112233")
			assert.is_true(frame.calls > 0)

			frame.calls = 0
			Private.Utils.ApplyBorderStyle(frame, "Test Border", box(100, 20), 8, "FF112233")
			assert.equals(0, frame.calls)
		end)

		it("skips the twelve Hide()s of an already-hidden border", function()
			local frame = borderFrame()

			Private.Utils.ApplyBorderStyle(frame, "None", box(100, 20), 8, nil)
			assert.equals(12, frame.calls)

			frame.calls = 0
			Private.Utils.ApplyBorderStyle(frame, "None", box(100, 20), 8, nil)
			assert.equals(0, frame.calls)
		end)

		-- each component of the signature, changed on its own, must force a re-apply
		local variations = {
			{ name = "styleName", style = "Solid" },
			{ name = "width", width = 101 },
			{ name = "height", height = 21 },
			{ name = "offsetX", offsetX = 1 },
			{ name = "offsetY", offsetY = 1 },
			{ name = "borderSize", borderSize = 9 },
			{ name = "borderColor", color = "FF445566" },
		}

		for _, variation in ipairs(variations) do
			it("re-applies when " .. variation.name .. " changes", function()
				local frame = borderFrame()

				Private.Utils.ApplyBorderStyle(frame, "Test Border", box(100, 20), 8, "FF112233")

				frame.calls = 0
				Private.Utils.ApplyBorderStyle(
					frame,
					variation.style or "Test Border",
					{
						width = variation.width or 100,
						height = variation.height or 20,
						offsetX = variation.offsetX or 0,
						offsetY = variation.offsetY or 0,
					},
					variation.borderSize or 8,
					variation.color or "FF112233"
				)

				assert.is_true(frame.calls > 0)
			end)
		end

		it("re-applies for a second frame with the same signature (the stamp is per frame)", function()
			local first = borderFrame()
			local second = borderFrame()

			Private.Utils.ApplyBorderStyle(first, "Test Border", box(100, 20), 8, nil)
			Private.Utils.ApplyBorderStyle(second, "Test Border", box(100, 20), 8, nil)

			assert.is_true(second.calls > 0)
			assert.same(first.texCoords.BorderTop, second.texCoords.BorderTop)
		end)
	end)
end)
