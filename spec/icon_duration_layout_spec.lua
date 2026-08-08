---@diagnostic disable: undefined-global, undefined-field

-- Contract for Private.Utils.ComputeIconDurationLayout and the group footprint that follows
-- from it. The renderer, the border and the designer markers all read this one function, so
-- these cases are what keeps the preview and the live display agreeing.

local b = require("spec.bootstrap")
local Private = b.Private
local Enum = Private.Enum
local Element = Enum.Element
local Template = Enum.Template

local Layout = function(elements)
	return Private.Utils.ComputeIconDurationLayout(elements)
end

-- Fresh default elements, so the tests track the shipped geometry rather than a local guess.
local function defaults()
	return Private.Design.GetDefault(Template.IconDuration)
end

-- the reserve the layout gives the text, derived from the font size (see the note on
-- ComputeIconDurationLayout for why it is estimated rather than measured)
local function durationWidthFor(fontSize)
	return fontSize * 2.6
end

-- Read back from the schema so the geometry cases below track the shipped defaults instead
-- of restating them; the one case that pins the actual numbers is explicit about it.
local ICON_SIZE = defaults()[Element.Icon].width
local GAP = defaults()[Element.Duration].gap
local FONT_SIZE = defaults()[Element.Duration].countdownFontSize

describe("ComputeIconDurationLayout", function()
	describe("shipped defaults", function()
		it("seeds 32px icons at 1.35 zoom, gap 4, font 20", function()
			-- pinned deliberately: these are a deliberate visual choice, not an accident of
			-- copying the icon template, and a silent change to them is a product change
			local elements = defaults()

			assert.equals(32, elements[Element.Icon].width)
			assert.equals(32, elements[Element.Icon].height)
			assert.equals(1.35, elements[Element.Icon].iconZoom)
			assert.equals(4, elements[Element.Duration].gap)
			assert.equals(20, elements[Element.Duration].countdownFontSize)
		end)

		it("totals both icons, both gaps and the text reserve", function()
			local layout = Layout(defaults())

			assert.equals(durationWidthFor(FONT_SIZE), layout.durationWidth)
			assert.equals(ICON_SIZE * 2 + GAP * 2 + durationWidthFor(FONT_SIZE), layout.totalWidth)
		end)

		it("gives both cells the icon element's size", function()
			local layout = Layout(defaults())

			assert.equals(ICON_SIZE, layout.iconLeft.width)
			assert.equals(ICON_SIZE, layout.iconLeft.height)
			assert.equals(ICON_SIZE, layout.iconRight.width)
			assert.equals(ICON_SIZE, layout.iconRight.height)
		end)

		it("centres the duration text on the frame", function()
			assert.equals(0, Layout(defaults()).duration.centerX)
		end)
	end)

	describe("symmetry", function()
		it("the two cells mirror about x = 0", function()
			local layout = Layout(defaults())

			assert.equals(-layout.iconRight.centerX, layout.iconLeft.centerX)
			assert.is_true(layout.iconLeft.centerX < 0)
		end)

		it("each cell hugs its own outer edge", function()
			local layout = Layout(defaults())

			-- the left cell's left edge is the frame's left edge
			assert.equals(-layout.totalWidth / 2, layout.iconLeft.centerX - layout.iconLeft.width / 2)
			assert.equals(layout.totalWidth / 2, layout.iconRight.centerX + layout.iconRight.width / 2)
		end)

		it("holds after the icon is resized", function()
			local elements = defaults()
			elements[Element.Icon].width = 90

			local layout = Layout(elements)
			assert.equals(-layout.iconRight.centerX, layout.iconLeft.centerX)
			assert.equals(90 * 2 + GAP * 2 + durationWidthFor(FONT_SIZE), layout.totalWidth)
		end)
	end)

	describe("gap and font size widen the assembly", function()
		it("gap pushes both cells outward, twice over", function()
			local elements = defaults()
			local before = Layout(elements)
			local beforeLeft = before.iconLeft.centerX

			elements[Element.Duration].gap = GAP + 20
			Private.Utils.InvalidateLayout(elements)

			local after = Layout(elements)
			-- +20 gap on each side of the text = +40 total, so each cell moves out by 20
			assert.equals(before.totalWidth + 40, after.totalWidth)
			assert.equals(beforeLeft - 20, after.iconLeft.centerX)
		end)

		it("a larger font widens the text reserve, and so the frame", function()
			local elements = defaults()
			local before = Layout(elements)

			elements[Element.Duration].countdownFontSize = 30
			Private.Utils.InvalidateLayout(elements)

			local after = Layout(elements)
			assert.equals(durationWidthFor(30), after.durationWidth)
			assert.equals(before.totalWidth + (durationWidthFor(30) - durationWidthFor(FONT_SIZE)), after.totalWidth)
		end)

		it("the duration's y offset moves only the text", function()
			local elements = defaults()
			elements[Element.Duration].y = -8

			local layout = Layout(elements)
			assert.equals(-8, layout.duration.centerY)
			assert.equals(0, layout.iconLeft.centerY)
			assert.equals(0, layout.iconRight.centerY)
		end)
	end)

	describe("designer marker aliases", function()
		it("the single Icon marker spans both cells", function()
			local layout = Layout(defaults())
			local marker = layout[Element.Icon]

			assert.equals(0, marker.centerX)
			assert.equals(layout.totalWidth, marker.width)
			assert.equals(ICON_SIZE, marker.height)
		end)

		it("the Duration marker is the text slot itself", function()
			local layout = Layout(defaults())
			assert.is_true(layout[Element.Duration] == layout.duration)
		end)

		it("footprint-less elements get no marker geometry", function()
			local layout = Layout(defaults())

			assert.is_nil(layout[Element.Overlay])
			assert.is_nil(layout[Element.Cooldown])
			assert.is_nil(layout[Element.Border])
		end)
	end)

	describe("memoisation", function()
		it("returns the identical table for an unmutated Elements table", function()
			local elements = defaults()
			assert.is_true(Layout(elements) == Layout(elements))
		end)

		it("distinct Elements tables do not share a layout", function()
			local first, second = Layout(defaults()), Layout(defaults())

			assert.is_false(first == second)
			assert.same(first, second)
		end)

		it("recomputes after an explicit invalidation", function()
			local elements = defaults()
			local before = Layout(elements)

			elements[Element.Icon].width = 64
			Private.Utils.InvalidateLayout(elements)

			local after = Layout(elements)
			assert.is_false(before == after)
			assert.equals(64, after.iconLeft.width)
		end)

		it("shares one cache with the bar layout without colliding", function()
			-- an Elements table belongs to exactly one template, which is what makes a single
			-- cache safe for both layout functions
			local iconDuration = defaults()
			local bar = Private.Design.GetDefault(Template.Bar)

			assert.equals(ICON_SIZE * 2 + GAP * 2 + durationWidthFor(FONT_SIZE), Layout(iconDuration).totalWidth)
			assert.equals(270, Private.Utils.ComputeBarLayout(bar).barWidth)
			-- re-reading either must still return its own layout
			assert.equals(270, Private.Utils.ComputeBarLayout(bar).barWidth)
			assert.is_nil(Layout(iconDuration).barWidth)
		end)
	end)

	describe("missing elements degrade to zero rather than erroring", function()
		it("an empty table yields a zero-width assembly", function()
			local layout = Layout({})

			assert.equals(0, layout.totalWidth)
			assert.equals(0, layout.durationWidth)
			assert.equals(0, layout.iconLeft.width)
		end)
	end)
end)

describe("ComputeGroupFootprint", function()
	local Footprint = function(template, elements)
		return Private.Utils.ComputeGroupFootprint(template, elements)
	end

	it("icon+duration reports the whole assembly, not the Icon core", function()
		local elements = defaults()
		local width, height = Footprint(Template.IconDuration, elements)

		assert.equals(Layout(elements).totalWidth, width)
		assert.equals(ICON_SIZE, height)
		-- the distinction that matters: the core alone would understate the width
		assert.is_true(width > elements[Element.Icon].width)
	end)

	it("is unchanged for the icon template (the core box)", function()
		local elements = Private.Design.GetDefault(Template.Icon)
		local width, height = Footprint(Template.Icon, elements)

		assert.equals(elements[Element.Icon].width, width)
		assert.equals(elements[Element.Icon].height, height)
	end)

	it("is unchanged for the bar template (the ProgressBar box, gutter included)", function()
		local elements = Private.Design.GetDefault(Template.Bar)
		local width, height = Footprint(Template.Bar, elements)

		-- the full 300, NOT the reflowed 270 bar width — the frame is the whole assembly
		assert.equals(300, width)
		assert.equals(30, height)
	end)

	it("tracks a resized icon+duration group", function()
		local elements = defaults()
		elements[Element.Icon].width = 20
		elements[Element.Duration].gap = 0
		Private.Utils.InvalidateLayout(elements)

		local width = Footprint(Template.IconDuration, elements)
		assert.equals(20 * 2 + durationWidthFor(FONT_SIZE), width)
	end)
end)

describe("ComputeGroupExtent for icon+duration", function()
	it("is the whole assembly, not the single Icon box ComputeElementExtent would find", function()
		local elements = defaults()
		local extent = Private.Utils.ComputeGroupExtent(elements)

		assert.equals(Layout(elements).totalWidth, extent.width)
		assert.equals(ICON_SIZE, extent.height)
		assert.equals(0, extent.offsetX)
		assert.equals(0, extent.offsetY)

		-- the fallback path would have reported just one icon
		assert.equals(48, Private.Utils.ComputeElementExtent({ [Element.Icon] = { width = 48, height = 48 } }).width)
	end)
end)
