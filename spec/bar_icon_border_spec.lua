---@diagnostic disable: undefined-global, undefined-field

local b = require("spec.bootstrap")
local Private = b.Private
local Element = Private.Enum.Element

_G.CreateFromMixins = function(...)
	local mixed = {}

	for index = 1, select("#", ...) do
		for name, value in pairs((select(index, ...))) do
			mixed[name] = value
		end
	end

	return mixed
end

loadfile("TargetedSpellsMixin.lua")("TargetedSpells", Private)
loadfile("TargetedSpellsBarMixin.lua")("TargetedSpells", Private)

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

local REGION = setmetatable({}, {
	__index = function()
		return function() end
	end,
})

-- ApplyBorderStyle stamps the signature it rendered onto the frame, which is what these assert on.
local function BorderFrame()
	local frame = {}

	for _, name in ipairs(BORDER_REGIONS) do
		frame[name] = REGION
	end

	return frame
end

local function MakeBar()
	local frame = { IconBorder = BorderFrame(), ProgressBar = BorderFrame() }

	for name, method in pairs(TargetedSpellsBarMixin) do
		frame[name] = method
	end

	frame.group = {
		Template = Private.Enum.Template.Bar,
		Elements = Private.Design.GetDefault(Private.Enum.Template.Bar),
	}

	return frame
end

describe("Bar ApplyIconBorderStyle", function()
	it("wraps the spell icon with the icon border's own settings", function()
		local frame = MakeBar()
		local elements = frame.group.Elements
		elements[Element.Icon].width = 30
		elements[Element.Icon].height = 24
		elements[Element.IconBorder].active = true
		elements[Element.IconBorder].borderTexture = "Solid"
		elements[Element.IconBorder].borderSize = 2
		elements[Element.IconBorder].borderColor = "FF00FF00"

		frame:ApplyIconBorderStyle()

		assert.equals("Solid", frame.IconBorder.appliedBorderStyle)
		assert.equals(30, frame.IconBorder.appliedBorderWidth)
		assert.equals(24, frame.IconBorder.appliedBorderHeight)
		assert.equals(0, frame.IconBorder.appliedBorderOffsetX)
		assert.equals(0, frame.IconBorder.appliedBorderOffsetY)
		assert.equals(2, frame.IconBorder.appliedBorderSize)
		assert.equals("FF00FF00", frame.IconBorder.appliedBorderColor)
	end)

	it("hides when the icon border is inactive", function()
		local frame = MakeBar()
		frame.group.Elements[Element.IconBorder].active = false

		frame:ApplyIconBorderStyle()

		assert.equals("None", frame.IconBorder.appliedBorderStyle)
	end)

	it("hides when the spell icon itself is inactive", function()
		local frame = MakeBar()
		frame.group.Elements[Element.IconBorder].active = true
		frame.group.Elements[Element.Icon].active = false

		frame:ApplyIconBorderStyle()

		assert.equals("None", frame.IconBorder.appliedBorderStyle)
	end)

	it("is independent of the bar border", function()
		local frame = MakeBar()
		frame.group.Elements[Element.Border].active = true
		frame.group.Elements[Element.IconBorder].active = false

		frame:ApplyBorderStyle(frame.group.Elements[Element.Border].borderTexture)
		frame:ApplyIconBorderStyle()

		assert.equals("Blizzard Tooltip Border", frame.ProgressBar.appliedBorderStyle)
		assert.equals("None", frame.IconBorder.appliedBorderStyle)
	end)
end)
