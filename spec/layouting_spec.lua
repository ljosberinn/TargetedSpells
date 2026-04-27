---@diagnostic disable: undefined-global, undefined-field

local b = require("spec.bootstrap")
local Private = b.Private
local Enum = Private.Enum

describe("CollectLayoutingArguments", function()
	it("horizontal + grow start: orientation, axes, and anchor points", function()
		local r = Private.Utils.CollectLayoutingArguments(Enum.Direction.Horizontal, Enum.Grow.Start, 48, 48, 2)
		assert.equals("HORIZONTAL", r.orientation)
		assert.equals(50, r.x) -- width + gap
		assert.equals(48, r.y) -- height
		assert.equals("LEFT", r.originPoint)
		assert.equals("RIGHT", r.relativePoint)
		assert.is_true(r.isHorizontal)
		assert.is_false(r.isGrowEnd)
	end)

	it("horizontal + grow end: anchor points are flipped", function()
		local r = Private.Utils.CollectLayoutingArguments(Enum.Direction.Horizontal, Enum.Grow.End, 48, 48, 2)
		assert.equals("RIGHT", r.originPoint)
		assert.equals("LEFT", r.relativePoint)
		assert.is_true(r.isGrowEnd)
	end)

	it("vertical + grow start: orientation, axes, and anchor points", function()
		local r = Private.Utils.CollectLayoutingArguments(Enum.Direction.Vertical, Enum.Grow.Start, 48, 30, 4)
		assert.equals("VERTICAL", r.orientation)
		assert.equals(34, r.x) -- height + gap
		assert.equals(48, r.y) -- width
		assert.equals("BOTTOM", r.originPoint)
		assert.equals("TOP", r.relativePoint)
		assert.is_false(r.isHorizontal)
		assert.is_false(r.isGrowEnd)
	end)

	it("vertical + grow end: anchor points are flipped", function()
		local r = Private.Utils.CollectLayoutingArguments(Enum.Direction.Vertical, Enum.Grow.End, 48, 30, 4)
		assert.equals("TOP", r.originPoint)
		assert.equals("BOTTOM", r.relativePoint)
		assert.is_true(r.isGrowEnd)
	end)

	it("gap contributes to x for both directions", function()
		local horiz = Private.Utils.CollectLayoutingArguments(Enum.Direction.Horizontal, Enum.Grow.Start, 100, 50, 10)
		assert.equals(110, horiz.x)

		local vert = Private.Utils.CollectLayoutingArguments(Enum.Direction.Vertical, Enum.Grow.Start, 100, 50, 10)
		assert.equals(60, vert.x)
	end)
end)

describe("SortFrames", function()
	local function makeFrame(startTime)
		return {
			GetStartTime = function()
				return startTime
			end,
		}
	end

	it("ascending: earlier start times come first", function()
		local frames = { makeFrame(3), makeFrame(1), makeFrame(2) }
		Private.Utils.SortFrames(frames, Enum.SortOrder.Ascending)
		assert.equals(1, frames[1]:GetStartTime())
		assert.equals(2, frames[2]:GetStartTime())
		assert.equals(3, frames[3]:GetStartTime())
	end)

	it("descending: later start times come first", function()
		local frames = { makeFrame(3), makeFrame(1), makeFrame(2) }
		Private.Utils.SortFrames(frames, Enum.SortOrder.Descending)
		assert.equals(3, frames[1]:GetStartTime())
		assert.equals(2, frames[2]:GetStartTime())
		assert.equals(1, frames[3]:GetStartTime())
	end)

	it("single frame is unchanged", function()
		local frames = { makeFrame(5) }
		Private.Utils.SortFrames(frames, Enum.SortOrder.Ascending)
		assert.equals(5, frames[1]:GetStartTime())
	end)

	it("empty list does not error", function()
		assert.has_no_error(function()
			Private.Utils.SortFrames({}, Enum.SortOrder.Ascending)
		end)
	end)
end)
