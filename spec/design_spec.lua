---@diagnostic disable: undefined-global, undefined-field

local b = require("spec.bootstrap")
local Private = b.Private
local Enum = Private.Enum

describe("Design.GetDefault", function()
	it("returns Elements for both templates", function()
		assert.is_table(Private.Design.GetDefault(Enum.Template.Icon))
		assert.is_table(Private.Design.GetDefault(Enum.Template.Bar))
	end)

	it("errors on an unknown template", function()
		assert.has_error(function()
			Private.Design.GetDefault("nope")
		end)
	end)

	it("returns a fresh copy each call (callers may mutate)", function()
		local first = Private.Design.GetDefault(Enum.Template.Bar)
		first[Enum.Element.ProgressBar].width = 999
		local second = Private.Design.GetDefault(Enum.Template.Bar)
		assert.equals(300, second[Enum.Element.ProgressBar].width)
	end)

	it("seeds the core element at x=y=0 with its size", function()
		local iconElements = Private.Design.GetDefault(Enum.Template.Icon)
		assert.equals(0, iconElements[Enum.Element.Icon].x)
		assert.equals(0, iconElements[Enum.Element.Icon].y)
		assert.equals(48, iconElements[Enum.Element.Icon].width)

		local barElements = Private.Design.GetDefault(Enum.Template.Bar)
		assert.equals(0, barElements[Enum.Element.ProgressBar].x)
		assert.equals(300, barElements[Enum.Element.ProgressBar].width)
		assert.equals(30, barElements[Enum.Element.ProgressBar].height)
	end)

	it("every schema record has a corresponding default value", function()
		for _, template in pairs({ Enum.Template.Icon, Enum.Template.Bar }) do
			local schema = Private.Design.GetSchema(template)
			local defaults = Private.Design.GetDefault(template)
			for element, records in pairs(schema) do
				for _, record in ipairs(records) do
					assert.is_not_nil(
						defaults[element][record.setting],
						("template %s element %s missing default for %s"):format(
							tostring(template),
							tostring(element),
							tostring(record.setting)
						)
					)
				end
			end
		end
	end)
end)

describe("Design.CopyElements", function()
	it("deep-copies with no shared nested references", function()
		local original = Private.Design.GetDefault(Enum.Template.Icon)
		local copy = Private.Design.CopyElements(original)
		copy[Enum.Element.Icon].width = 12
		assert.equals(48, original[Enum.Element.Icon].width)
	end)
end)
