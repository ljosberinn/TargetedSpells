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

-- AdjustLayout does two separable jobs per frame: bind the frame to its group's "spine"
-- (Bar size/orientation/fill + the frame↔Bar↔container parenting), and anchor it in the
-- chain. Only the second changes when a sibling comes or goes, so the first is stamped and
-- skipped — these tests pin down exactly when the stamp must give way (ISSUE-103 item 5).
describe("AdjustLayout", function()
	local function makeFrame()
		local statusBarTexture = { name = "statusBarTexture" }
		local frame = {
			binds = 0,
			anchors = 0,
			parents = {},
		}

		frame.Bar = {
			SetSize = function(_, width, height)
				frame.binds = frame.binds + 1
				frame.barWidth = width
				frame.barHeight = height
			end,
			SetOrientation = function(_, orientation)
				frame.binds = frame.binds + 1
				frame.orientation = orientation
			end,
			SetReverseFill = function(_, reverseFill)
				frame.binds = frame.binds + 1
				frame.reverseFill = reverseFill
			end,
			SetParent = function(_, parent)
				frame.binds = frame.binds + 1
				frame.parents.bar = parent
			end,
			GetStatusBarTexture = function()
				return statusBarTexture
			end,
			GetFrameLevel = function()
				return 5
			end,
			ClearAllPoints = function()
				frame.anchors = frame.anchors + 1
			end,
			SetPoint = function(_, point, relativeTo)
				frame.anchors = frame.anchors + 1
				frame.barPoint = point
				frame.barRelativeTo = relativeTo
			end,
			SetValue = function() end,
		}

		frame.SetParent = function(_, parent)
			frame.binds = frame.binds + 1
			frame.parents.frame = parent
		end
		frame.SetFrameLevel = function(_, level)
			frame.binds = frame.binds + 1
			frame.level = level
		end
		frame.ClearAllPoints = function()
			frame.anchors = frame.anchors + 1
		end
		frame.SetPoint = function()
			frame.anchors = frame.anchors + 1
		end
		frame.GetAlpha = function()
			return 1
		end
		frame.Show = function()
			frame.shown = true
		end

		return frame
	end

	local function vertical()
		return Private.Utils.CollectLayoutingArguments(Enum.Direction.Vertical, Enum.Grow.Start, 48, 30, 2)
	end

	local container = { name = "container" }

	it("binds the spine on the first pass", function()
		local frame = makeFrame()

		Private.Utils.AdjustLayout({ frame }, vertical(), container, "CENTER", 0, 0)

		assert.is_true(frame.binds > 0)
		-- vertical: Bar is (y, x) = (width, height + gap)
		assert.equals(48, frame.barWidth)
		assert.equals(32, frame.barHeight)
		assert.equals("VERTICAL", frame.orientation)
		assert.is_false(frame.reverseFill)
		assert.equals(container, frame.parents.bar)
		assert.equals(frame.Bar, frame.parents.frame)
		assert.equals(15, frame.level)
		assert.is_true(frame.shown)
	end)

	it("re-anchors but does not rebind when nothing about the spine changed", function()
		local frame = makeFrame()

		Private.Utils.AdjustLayout({ frame }, vertical(), container, "CENTER", 0, 0)
		local binds = frame.binds

		frame.anchors = 0
		Private.Utils.AdjustLayout({ frame }, vertical(), container, "CENTER", 0, 0)

		assert.equals(binds, frame.binds)
		assert.is_true(frame.anchors > 0)
	end)

	it("rebinds when the core size or gap changed the spine extent", function()
		local frame = makeFrame()

		Private.Utils.AdjustLayout({ frame }, vertical(), container, "CENTER", 0, 0)
		local binds = frame.binds

		local resized = Private.Utils.CollectLayoutingArguments(Enum.Direction.Vertical, Enum.Grow.Start, 48, 60, 2)
		Private.Utils.AdjustLayout({ frame }, resized, container, "CENTER", 0, 0)

		assert.is_true(frame.binds > binds)
		assert.equals(62, frame.barHeight)
	end)

	it("rebinds when the direction or grow direction changed", function()
		local frame = makeFrame()

		Private.Utils.AdjustLayout({ frame }, vertical(), container, "CENTER", 0, 0)
		local binds = frame.binds

		local flipped = Private.Utils.CollectLayoutingArguments(Enum.Direction.Vertical, Enum.Grow.End, 48, 30, 2)
		Private.Utils.AdjustLayout({ frame }, flipped, container, "CENTER", 0, 0)

		assert.is_true(frame.binds > binds)
		assert.is_true(frame.reverseFill)
	end)

	it("rebinds when the group container changed", function()
		local frame = makeFrame()

		Private.Utils.AdjustLayout({ frame }, vertical(), container, "CENTER", 0, 0)
		local binds = frame.binds

		local other = { name = "other" }
		Private.Utils.AdjustLayout({ frame }, vertical(), other, "CENTER", 0, 0)

		assert.is_true(frame.binds > binds)
		assert.equals(other, frame.parents.bar)
	end)

	it("rebinds when the Bar picked up a new frame level from elsewhere", function()
		local frame = makeFrame()

		Private.Utils.AdjustLayout({ frame }, vertical(), container, "CENTER", 0, 0)
		local binds = frame.binds

		frame.Bar.GetFrameLevel = function()
			return 40
		end
		Private.Utils.AdjustLayout({ frame }, vertical(), container, "CENTER", 0, 0)

		assert.is_true(frame.binds > binds)
		assert.equals(50, frame.level)
	end)

	it("rebinds after a release cleared the stamp (what Reset does)", function()
		local frame = makeFrame()

		Private.Utils.AdjustLayout({ frame }, vertical(), container, "CENTER", 0, 0)
		local binds = frame.binds

		frame.boundBarParent = nil
		Private.Utils.AdjustLayout({ frame }, vertical(), container, "CENTER", 0, 0)

		assert.is_true(frame.binds > binds)
	end)

	it("chains the second frame off the first frame's status bar texture", function()
		local first, second = makeFrame(), makeFrame()

		Private.Utils.AdjustLayout({ first, second }, vertical(), container, "CENTER", 0, 0)

		assert.equals(container, first.barRelativeTo)
		assert.equals("statusBarTexture", second.barRelativeTo.name)
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
