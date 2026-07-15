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

	it("seeds the core element as the origin (no x/y) with its size", function()
		-- the core is the CENTER→CENTER origin every other element offsets from; it
		-- fills the frame and carries no x/y widget/value of its own
		local iconElements = Private.Design.GetDefault(Enum.Template.Icon)
		assert.is_nil(iconElements[Enum.Element.Icon].x)
		assert.is_nil(iconElements[Enum.Element.Icon].y)
		assert.equals(48, iconElements[Enum.Element.Icon].width)

		local barElements = Private.Design.GetDefault(Enum.Template.Bar)
		assert.is_nil(barElements[Enum.Element.ProgressBar].x)
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

	it("every texture record declares a mediaType the designer can resolve", function()
		local valid = { statusbar = true, background = true, border = true }
		for _, template in pairs({ Enum.Template.Icon, Enum.Template.Bar }) do
			for _, records in pairs(Private.Design.GetSchema(template)) do
				for _, record in ipairs(records) do
					if record.type == "texture" then
						assert.is_true(
							valid[record.mediaType] == true,
							("texture setting %s has invalid mediaType %s"):format(
								tostring(record.setting),
								tostring(record.mediaType)
							)
						)
					end
				end
			end
		end
	end)
end)

describe("Design.BackfillElements", function()
	it("fills missing schema fields without overwriting existing values", function()
		local group = {
			Template = Enum.Template.Bar,
			Elements = {
				[Enum.Element.ProgressBar] = { width = 111 }, -- partial; keep width
			},
		}

		Private.Design.BackfillElements(group)

		-- existing value preserved
		assert.equals(111, group.Elements[Enum.Element.ProgressBar].width)
		-- missing field on a partial element backfilled from the default
		assert.equals(30, group.Elements[Enum.Element.ProgressBar].height)
		-- an entirely absent element seeded whole
		assert.is_table(group.Elements[Enum.Element.TargetName])
		assert.is_not_nil(group.Elements[Enum.Element.TargetName].fontSize)
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
