---@diagnostic disable: undefined-global, undefined-field

-- Target and interrupter names may arrive as secret values together with a secret class color.
-- A class color is a colorRGB and has no alpha, so forwarding its `a` puts a (secret) nil into
-- the fourth SetTextColor argument, which is what silently killed class coloring on live frames
-- while the designer preview -- which never passed alpha -- kept working. The argument count is
-- therefore part of the contract and pinned here.

local b = require("spec.bootstrap")
local Private = b.Private

local function StubFontString()
	local region = { colorArgumentCount = 0 }

	function region:SetText(text)
		self.text = text
	end

	function region:SetTextColor(...)
		self.colorArgumentCount = select("#", ...)
		self.red, self.green, self.blue, self.alpha = ...
	end

	return region
end

describe("Utils.ApplyElementText", function()
	-- a class color as C_ClassColor.GetClassColor hands it over: colorRGB, no alpha
	local classColor = { r = 0.77, g = 0.12, b = 0.23 }

	it("colors by class without passing an alpha component", function()
		local region = StubFontString()

		Private.Utils.ApplyElementText(region, { useClassColor = true, textColor = "FF00FF00" }, "Xephyris", classColor)

		assert.equals(3, region.colorArgumentCount)
		assert.equals(0.77, region.red)
		assert.equals("Xephyris", region.text)
	end)

	it("falls back to the configured text color when no class color is known", function()
		local region = StubFontString()

		Private.Utils.ApplyElementText(region, { useClassColor = true, textColor = "FF00FF00" }, "Xephyris", nil)

		assert.equals(4, region.colorArgumentCount)
		assert.equals(0, region.red)
		assert.equals(1, region.green)
	end)

	it("ignores a class color the element did not ask for", function()
		local region = StubFontString()

		Private.Utils.ApplyElementText(region, { useClassColor = false, textColor = "FF00FF00" }, "Xephyris", classColor)

		assert.equals(4, region.colorArgumentCount)
		assert.equals(1, region.green)
	end)

	it("leaves the color alone when the element has none configured", function()
		local region = StubFontString()

		Private.Utils.ApplyElementText(region, {}, "Xephyris", nil)

		assert.equals(0, region.colorArgumentCount)
		assert.equals("Xephyris", region.text)
	end)
end)
