---@diagnostic disable: undefined-global, undefined-field, missing-fields

-- Controller-level specs: a TargetedSpellsGroupController owns its container, pool,
-- active-frames list, and layout. These assert the ownership boundary the Driver's
-- router relies on — acquire routes each cast's frame into its own controller,
-- release removes only that frame, and relayout touches only that controller's frames
-- under its own container.

local b = require("spec.bootstrap")
local Private = b.Private
local Enum = Private.Enum

_G.UIParent = _G.UIParent or {}

loadfile("GroupController.lua")("TargetedSpells", Private)

local Controller = Private.GroupController

local function makeGroup(id, template)
	return {
		Id = id,
		Template = template or Enum.Template.Icon,
		SortOrder = Enum.SortOrder.Ascending,
		Direction = Enum.Direction.Vertical,
		Grow = Enum.Grow.End,
		Gap = 2,
		Position = { point = Enum.Anchor.Center, x = 0, y = 0 },
		Elements = {
			[Enum.Element.Icon] = { width = 48, height = 48 },
			[Enum.Element.ProgressBar] = { width = 200, height = 20 },
		},
	}
end

-- Minimal frame satisfying Acquire (SetGroup/PostCreate) and SortFrames (GetStartTime).
local nextStartTime = 0
local function makeFakeFrame()
	nextStartTime = nextStartTime + 1
	local frame = { startTime = nextStartTime }
	function frame:SetGroup(group)
		self.group = group
	end
	function frame:GetGroup()
		return self.group
	end
	function frame:GetStartTime()
		return self.startTime
	end
	function frame:PostCreate()
		self.created = true
	end
	return frame
end

-- Fake pool handing out fresh frames and recording releases by identity.
local function makePool()
	return {
		released = {},
		Acquire = function()
			return makeFakeFrame()
		end,
		Release = function(self, frame)
			self.released[frame] = true
		end,
	}
end

-- A controller whose pool is swapped for a spyable one, so acquire returns frames we
-- can track without needing the real (bootstrap-stubbed) shared pools.
local function makeController(id, template)
	local controller = Controller.New(makeGroup(id, template))
	controller.pool = makePool()
	-- preset container so Relayout / GetContainer never reaches CreateFrame
	controller.container = { id = id }
	return controller
end

local function noop() end

describe("GroupController acquire ownership", function()
	it("routes each cast's frame into its own controller, tagged with its group", function()
		local a = makeController(1)
		local c = makeController(2)

		local a1 = a:Acquire({}, noop)
		local a2 = a:Acquire({}, noop)
		local c1 = c:Acquire({}, noop)

		assert.equals(2, #a.frames)
		assert.equals(1, #c.frames)

		-- each controller holds only its own frames
		assert.equals(a1, a.frames[1])
		assert.equals(a2, a.frames[2])
		assert.equals(c1, c.frames[1])

		-- and every frame carries its owning group
		assert.equals(a.group, a1:GetGroup())
		assert.equals(c.group, c1:GetGroup())
	end)

	it("styles the acquired frame via PostCreate", function()
		local a = makeController(1)
		local frame = a:Acquire({}, noop)
		assert.is_true(frame.created)
	end)
end)

describe("GroupController release", function()
	it("removes only the released frame and returns it to the pool", function()
		local a = makeController(1)
		local first = a:Acquire({}, noop)
		local second = a:Acquire({}, noop)

		a:Release(first)

		assert.equals(1, #a.frames)
		assert.equals(second, a.frames[1]) -- sibling untouched
		assert.is_true(a.pool.released[first])
		assert.is_nil(a.pool.released[second])
	end)

	it("leaves other controllers' lists alone", function()
		local a = makeController(1)
		local c = makeController(2)
		local a1 = a:Acquire({}, noop)
		local c1 = c:Acquire({}, noop)

		a:Release(a1)

		assert.equals(0, #a.frames)
		assert.equals(1, #c.frames)
		assert.equals(c1, c.frames[1])
	end)
end)

describe("GroupController relayout", function()
	-- Spy on AdjustLayout so we observe which frames/container a relayout anchors,
	-- restoring inline (the shim's after_each is a no-op).
	local function withAdjustSpy(fn)
		local calls = {}
		local original = Private.Utils.AdjustLayout
		Private.Utils.AdjustLayout = function(frames, _, container)
			table.insert(calls, { count = #frames, container = container })
		end
		local ok, err = pcall(fn, calls)
		Private.Utils.AdjustLayout = original
		if not ok then
			error(err)
		end
		return calls
	end

	it("anchors its own frames under its own container", function()
		local a = makeController(1)
		a:Acquire({}, noop)
		a:Acquire({}, noop)

		local calls = withAdjustSpy(function()
			a:Relayout()
		end)

		assert.equals(1, #calls)
		assert.equals(2, calls[1].count)
		assert.equals(1, calls[1].container.id) -- its own container, not a sibling's
	end)

	it("no-ops when the controller holds no frames", function()
		local a = makeController(1)

		local calls = withAdjustSpy(function()
			a:Relayout()
		end)

		assert.equals(0, #calls)
	end)

	it("relayouts controllers independently", function()
		local a = makeController(1)
		local c = makeController(2)
		a:Acquire({}, noop)
		c:Acquire({}, noop)
		c:Acquire({}, noop)

		local calls = withAdjustSpy(function()
			a:Relayout()
			c:Relayout()
		end)

		assert.equals(2, #calls)
		assert.equals(1, calls[1].container.id)
		assert.equals(1, calls[1].count)
		assert.equals(2, calls[2].container.id)
		assert.equals(2, calls[2].count)
	end)
end)

describe("GroupController reconfigure", function()
	it("derives pool and core element from the group template at New", function()
		local iconController = Controller.New(makeGroup(1, Enum.Template.Icon))
		assert.equals(Enum.Element.Icon, iconController.coreElement)
		assert.equals(Private.Utils.Pools.Icon, iconController.pool)

		local barController = Controller.New(makeGroup(2, Enum.Template.Bar))
		assert.equals(Enum.Element.ProgressBar, barController.coreElement)
		assert.equals(Private.Utils.Pools.Bar, barController.pool)
	end)

	it("re-derives pool and core element on an Icon<->Bar flip", function()
		local group = makeGroup(1, Enum.Template.Icon)
		local controller = Controller.New(group)
		assert.equals(Enum.Element.Icon, controller.coreElement)

		group.Template = Enum.Template.Bar
		controller:Reconfigure(group)

		assert.equals(Enum.Element.ProgressBar, controller.coreElement)
		assert.equals(Private.Utils.Pools.Bar, controller.pool)
		assert.equals(group, controller.group)
	end)
end)
