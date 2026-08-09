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

-- Minimal frame satisfying Acquire (SetGroup/PostCreate), SortFrames (GetStartTime) and
-- the controller's per-unit lookups (GetUnit/CanBeHidden). PostCreate takes the unit off
-- the info table exactly as the real mixins do.
local nextStartTime = 0
local function makeFakeFrame()
	nextStartTime = nextStartTime + 1
	local frame = { startTime = nextStartTime, hideable = true }
	function frame:SetGroup(group)
		self.group = group
	end
	function frame:GetGroup()
		return self.group
	end
	function frame:GetStartTime()
		return self.startTime
	end
	function frame:GetUnit()
		return self.unit
	end
	function frame:CanBeHidden()
		return self.hideable
	end
	function frame:PostCreate(info)
		self.created = true
		self.unit = info and info.unit or nil
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

describe("GroupController ReleaseForUnit", function()
	it("releases only the named unit's frames and leaves siblings alone", function()
		local a = makeController(1)
		local first = a:Acquire({ unit = "nameplate1" }, noop)
		local second = a:Acquire({ unit = "nameplate2" }, noop)

		local released, remaining = a:ReleaseForUnit("nameplate1")

		assert.is_true(released)
		assert.is_false(remaining)
		assert.equals(1, #a.frames)
		assert.equals(second, a.frames[1]) -- other unit untouched
		assert.is_true(a.pool.released[first])
		assert.is_nil(a.pool.released[second])
	end)

	it("leaves other controllers' lists alone", function()
		local a = makeController(1)
		local c = makeController(2)
		a:Acquire({ unit = "nameplate1" }, noop)
		local c1 = c:Acquire({ unit = "nameplate1" }, noop)

		a:ReleaseForUnit("nameplate1")

		assert.equals(0, #a.frames)
		assert.equals(1, #c.frames)
		assert.equals(c1, c.frames[1])
	end)

	it("reports a lingering frame as remaining and keeps holding it", function()
		local a = makeController(1)
		local lingering = a:Acquire({ unit = "nameplate1" }, noop)
		lingering.hideable = false -- interrupted: still inside its hide delay

		local released, remaining = a:ReleaseForUnit("nameplate1")

		assert.is_false(released)
		assert.is_true(remaining)
		assert.equals(1, #a.frames)
		assert.is_nil(a.pool.released[lingering])
	end)

	it("reports both when one frame goes and another lingers", function()
		local a = makeController(1)
		local goes = a:Acquire({ unit = "nameplate1" }, noop)
		local stays = a:Acquire({ unit = "nameplate1" }, noop)
		stays.hideable = false

		local released, remaining = a:ReleaseForUnit("nameplate1")

		assert.is_true(released)
		assert.is_true(remaining)
		assert.equals(1, #a.frames)
		assert.equals(stays, a.frames[1])
		assert.is_true(a.pool.released[goes])
	end)

	it("reports nothing for a unit it never held", function()
		local a = makeController(1)
		a:Acquire({ unit = "nameplate1" }, noop)

		local released, remaining = a:ReleaseForUnit("nameplate9")

		assert.is_false(released)
		assert.is_false(remaining)
		assert.equals(1, #a.frames)
	end)
end)

describe("GroupController ReleaseAll", function()
	it("drops every frame regardless of the hide delay", function()
		local a = makeController(1)
		local first = a:Acquire({ unit = "nameplate1" }, noop)
		local lingering = a:Acquire({ unit = "nameplate2" }, noop)
		lingering.hideable = false

		a:ReleaseAll()

		assert.equals(0, #a.frames)
		assert.is_true(a.pool.released[first])
		assert.is_true(a.pool.released[lingering])
	end)

	it("leaves other controllers' lists alone", function()
		local a = makeController(1)
		local c = makeController(2)
		a:Acquire({ unit = "nameplate1" }, noop)
		local c1 = c:Acquire({ unit = "nameplate1" }, noop)

		a:ReleaseAll()

		assert.equals(0, #a.frames)
		assert.equals(1, #c.frames)
		assert.equals(c1, c.frames[1])
	end)
end)

describe("GroupController MarkInterruptedForUnit", function()
	local function makeMarkable(controller)
		for _, frame in ipairs(controller.frames) do
			function frame:SetInterrupted(name, color)
				self.interruptedBy = name
				self.interruptColor = color
			end
		end
	end

	it("marks only the named unit's frames when the group opts in", function()
		local a = makeController(1)
		a.group.IndicateInterrupts = true
		local target = a:Acquire({ unit = "nameplate1" }, noop)
		local other = a:Acquire({ unit = "nameplate2" }, noop)
		makeMarkable(a)

		assert.is_true(a:MarkInterruptedForUnit("nameplate1", "Healer", nil))
		assert.equals("Healer", target.interruptedBy)
		assert.is_nil(other.interruptedBy)
	end)

	it("does nothing and reports false when the group opts out", function()
		local a = makeController(1)
		a.group.IndicateInterrupts = false
		local target = a:Acquire({ unit = "nameplate1" }, noop)
		makeMarkable(a)

		assert.is_false(a:MarkInterruptedForUnit("nameplate1", "Healer", nil))
		assert.is_nil(target.interruptedBy)
	end)

	it("reports false when it holds nothing for the unit", function()
		local a = makeController(1)
		a.group.IndicateInterrupts = true

		assert.is_false(a:MarkInterruptedForUnit("nameplate1", "Healer", nil))
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

		-- icon+duration shares the Icon core element but must NOT share the Icon pool
		local iconDurationController = Controller.New(makeGroup(3, Enum.Template.IconDuration))
		assert.equals(Enum.Element.Icon, iconDurationController.coreElement)
		assert.equals(Private.Utils.Pools.IconDuration, iconDurationController.pool)
		assert.is_false(iconDurationController.pool == Private.Utils.Pools.Icon)
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

	it("re-derives the pool when flipping to icon+duration, despite the core element not changing", function()
		local group = makeGroup(1, Enum.Template.Icon)
		local controller = Controller.New(group)

		group.Template = Enum.Template.IconDuration
		controller:Reconfigure(group)

		-- the core element is Icon either way, so the pool is the only observable difference —
		-- and a stale pool here would return frames of the wrong template
		assert.equals(Enum.Element.Icon, controller.coreElement)
		assert.equals(Private.Utils.Pools.IconDuration, controller.pool)
	end)
end)
