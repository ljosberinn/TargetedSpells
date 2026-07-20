---@diagnostic disable: undefined-global, undefined-field

local b = require("spec.bootstrap")
local Private = b.Private
local Enum = Private.Enum
local Element = Enum.Element

local Layout = function(elements)
	return Private.Utils.ComputeBarLayout(elements)
end

-- Fresh default bar elements, so the test tracks the shipped geometry.
local function barDefaults()
	return Private.Design.GetDefault(Enum.Template.Bar)
end

describe("ComputeBarLayout", function()
	describe("gutter reflow (300 total, TargetMarker/Icon 30 each)", function()
		it("neither gutter element active → bar is the full width, centred", function()
			local elements = barDefaults()
			elements[Element.Icon].active = false
			elements[Element.TargetMarker].active = false

			local layout = Layout(elements)
			assert.equals(0, layout.gutterWidth)
			assert.equals(300, layout.barWidth)
			assert.equals(0, layout[Element.ProgressBar].centerX)
			assert.is_nil(layout[Element.Icon]) -- inactive → no slot
			assert.is_nil(layout[Element.TargetMarker])
		end)

		it("default (icon only) → bar 270, shifted right by half the gutter", function()
			local layout = Layout(barDefaults())
			assert.equals(30, layout.gutterWidth)
			assert.equals(270, layout.barWidth)
			assert.equals(15, layout[Element.ProgressBar].centerX) -- gutter/2
			-- icon takes the leftmost slot: frame left -150, width 30 → centre -135
			assert.equals(-135, layout[Element.Icon].centerX)
			assert.is_nil(layout[Element.TargetMarker])
		end)

		it("both active → bar 240, packed [TargetMarker][Icon] from the left", function()
			local elements = barDefaults()
			elements[Element.TargetMarker].active = true

			local layout = Layout(elements)
			assert.equals(60, layout.gutterWidth)
			assert.equals(240, layout.barWidth)
			assert.equals(30, layout[Element.ProgressBar].centerX)
			-- marker leftmost (-150..-120 → -135), icon next (-120..-90 → -105)
			assert.equals(-135, layout[Element.TargetMarker].centerX)
			assert.equals(-105, layout[Element.Icon].centerX)
		end)
	end)

	describe("edge-anchored elements track the reflowing bar", function()
		it("LEFT text follows the bar's (moving) left edge; RIGHT stays at the fixed right", function()
			-- default: barLeft = -120, barRight = +150
			local iconOnly = Layout(barDefaults())
			assert.equals(-115, iconOnly[Element.SpellName].edgeX) -- barLeft + 5
			assert.equals(110, iconOnly[Element.TargetName].edgeX) -- barRight - 40

			-- both gutters: barLeft = -90, barRight unchanged
			local elements = barDefaults()
			elements[Element.TargetMarker].active = true
			local both = Layout(elements)
			assert.equals(-85, both[Element.SpellName].edgeX) -- barLeft moved right with the gutter
			assert.equals(110, both[Element.TargetName].edgeX) -- right edge is fixed
		end)

		it("Duration hugs the fixed right edge regardless of the gutter", function()
			-- right box: centre = barRight + x - width/2 = 150 + 0 - 15
			assert.equals(135, Layout(barDefaults())[Element.DurationCooldown].centerX)

			local elements = barDefaults()
			elements[Element.TargetMarker].active = true
			assert.equals(135, Layout(elements)[Element.DurationCooldown].centerX)
		end)
	end)

	it("SpellName and TargetName never overlap, even in the narrowest (both-gutter) bar", function()
		local elements = barDefaults()
		elements[Element.TargetMarker].active = true
		local layout = Layout(elements)

		local spell = layout[Element.SpellName]
		local target = layout[Element.TargetName]
		-- SpellName grows right from its (LEFT) edge; TargetName grows left from its (RIGHT) edge
		local spellRight = spell.edgeX + spell.maxWidth
		local targetLeft = target.edgeX - target.maxWidth
		assert.is_true(spellRight <= targetLeft, "spell " .. spellRight .. " must stay left of target " .. targetLeft)
	end)
end)
