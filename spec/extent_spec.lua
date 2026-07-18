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

	describe("against the built-in defaults", function()
		it("icon default extent equals the 48×48 core (siblings are welded)", function()
			local r = Extent(Private.Design.GetDefault(Enum.Template.Icon))
			assert.equals(48, r.width)
			assert.equals(48, r.height)
			assert.equals(0, r.offsetX)
			assert.equals(0, r.offsetY)
		end)

		it("bar default extent spans the icon/duration boxes flanking the core", function()
			-- ProgressBar 300 wide (-150..150); Icon 30@-135 (-150..-120);
			-- DurationCooldown 30@135 (120..150); TargetMarker/InterruptShield inactive;
			-- text elements uncapped → excluded. Symmetric → offset 0.
			local r = Extent(Private.Design.GetDefault(Enum.Template.Bar))
			assert.equals(300, r.width)
			assert.equals(30, r.height)
			assert.equals(0, r.offsetX)
			assert.equals(0, r.offsetY)
		end)
	end)
end)
