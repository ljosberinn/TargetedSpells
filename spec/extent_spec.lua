---@diagnostic disable: undefined-global, undefined-field

local b = require("spec.bootstrap")
local Private = b.Private
local Enum = Private.Enum

describe("ComputeElementExtent", function()
	local Extent = function(elements)
		return Private.Utils.ComputeElementExtent(elements)
	end

	it("empty table yields a zero extent", function()
		local r = Extent({})
		assert.equals(0, r.width)
		assert.equals(0, r.height)
		assert.equals(0, r.offsetX)
		assert.equals(0, r.offsetY)
	end)

	it("a lone core box (no `active` field, at origin) is the whole extent", function()
		local r = Extent({ [Enum.Element.Icon] = { width = 100, height = 20 } })
		assert.equals(100, r.width)
		assert.equals(20, r.height)
		assert.equals(0, r.offsetX)
		assert.equals(0, r.offsetY)
	end)

	it("unions the core with an offset box and centres the extent on the union", function()
		-- core: -50..50 x, -10..10 y ; box: 80..120 x, -20..20 y
		local r = Extent({
			[Enum.Element.ProgressBar] = { width = 100, height = 20 },
			[Enum.Element.Icon] = { active = true, width = 40, height = 40, x = 100, y = 0 },
		})
		assert.equals(170, r.width) -- -50..120
		assert.equals(40, r.height) -- -20..20
		assert.equals(35, r.offsetX) -- (-50 + 120) / 2
		assert.equals(0, r.offsetY)
	end)

	it("excludes inactive elements", function()
		local r = Extent({
			[Enum.Element.ProgressBar] = { width = 100, height = 20 },
			[Enum.Element.Icon] = { active = false, width = 40, height = 40, x = 500, y = 0 },
		})
		assert.equals(100, r.width)
		assert.equals(20, r.height)
		assert.equals(0, r.offsetX)
	end)

	it("includes capped text (maxWidth > 0), sizing it by maxWidth × fontSize", function()
		-- text: -100..100 x, -7..7 y ; core is taller so it drives height
		local r = Extent({
			[Enum.Element.ProgressBar] = { width = 100, height = 20 },
			[Enum.Element.TargetName] = { active = true, x = 0, y = 0, maxWidth = 200, fontSize = 14 },
		})
		assert.equals(200, r.width)
		assert.equals(20, r.height)
		assert.equals(0, r.offsetX)
	end)

	it("edge-anchors capped text by justifyH: LEFT pins x at the box's left edge", function()
		-- LEFT: box is x..x+maxWidth = 0..200 (centre 100). core -50..50 → union -50..200.
		local r = Extent({
			[Enum.Element.ProgressBar] = { width = 100, height = 20 },
			[Enum.Element.SpellName] = { active = true, x = 0, y = 0, maxWidth = 200, fontSize = 14, justifyH = "LEFT" },
		})
		assert.equals(250, r.width) -- -50..200
		assert.equals(75, r.offsetX) -- (-50 + 200) / 2
	end)

	it("edge-anchors capped text by justifyH: RIGHT pins x at the box's right edge", function()
		-- RIGHT: box is x-maxWidth..x = -200..0 (centre -100). core -50..50 → union -200..50.
		local r = Extent({
			[Enum.Element.ProgressBar] = { width = 100, height = 20 },
			[Enum.Element.TargetName] = { active = true, x = 0, y = 0, maxWidth = 200, fontSize = 14, justifyH = "RIGHT" },
		})
		assert.equals(250, r.width) -- -200..50
		assert.equals(-75, r.offsetX) -- (-200 + 50) / 2
	end)

	it("excludes uncapped text (maxWidth == 0) — its runtime width is unbounded", function()
		local r = Extent({
			[Enum.Element.ProgressBar] = { width = 100, height = 20 },
			[Enum.Element.TargetName] = { active = true, x = 500, y = 0, maxWidth = 0, fontSize = 14 },
		})
		assert.equals(100, r.width)
		assert.equals(20, r.height)
		assert.equals(0, r.offsetX)
	end)

	it("ignores welded/decorative elements that carry no width/height", function()
		local r = Extent({
			[Enum.Element.Icon] = { width = 48, height = 48 },
			[Enum.Element.Overlay] = { active = true }, -- no footprint
			[Enum.Element.Border] = { active = true, borderSize = 8 }, -- no width/height
		})
		assert.equals(48, r.width)
		assert.equals(48, r.height)
	end)

	it("skews the offset when elements sit on one side only", function()
		-- core -15..15 ; right-hand box 90..110 → union -15..110
		local r = Extent({
			[Enum.Element.ProgressBar] = { width = 30, height = 30 },
			[Enum.Element.DurationCooldown] = { active = true, width = 20, height = 20, x = 100, y = 0 },
		})
		assert.equals(125, r.width) -- -15..110
		assert.equals(30, r.height)
		assert.equals(47.5, r.offsetX) -- (-15 + 110) / 2
	end)

	describe("group extent against the built-in defaults (ComputeGroupExtent)", function()
		local GroupExtent = function(elements)
			return Private.Utils.ComputeGroupExtent(elements)
		end

		it("icon default extent equals the 48×48 core (siblings are welded)", function()
			local r = GroupExtent(Private.Design.GetDefault(Enum.Template.Icon))
			assert.equals(48, r.width)
			assert.equals(48, r.height)
			assert.equals(0, r.offsetX)
			assert.equals(0, r.offsetY)
		end)

		it("bar default extent is the whole core box (gutter + bar fill the frame)", function()
			-- the bar reflows: the gutter packs left and the ProgressBar fills the rest, so
			-- the assembly is exactly the 300×30 core, centred (offset 0) regardless of gutter.
			local r = GroupExtent(Private.Design.GetDefault(Enum.Template.Bar))
			assert.equals(300, r.width)
			assert.equals(30, r.height)
			assert.equals(0, r.offsetX)
			assert.equals(0, r.offsetY)
		end)
	end)
end)
