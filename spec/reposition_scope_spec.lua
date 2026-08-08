---@diagnostic disable: undefined-global, undefined-field, missing-fields

-- Sprint 3: RepositionFrames must relayout only the group(s) whose membership
-- changed. These specs load Driver.lua headlessly (capturing the driver singleton
-- via its file-scope GenerateClosure call) and spy on AdjustLayout to assert which
-- group containers get re-anchored.

local b = require("spec.bootstrap")
local Private = b.Private

-- Driver.lua's only file-scope side effect is
--   table.insert(Private.LoginFnQueue, GenerateClosure(Driver.Init, Driver))
-- so a GenerateClosure that records its bound self hands us the driver table
-- without running Init (which needs the live WoW frame API).
-- These are injected via _G, not bare assignment: under real busted, spec files run in
-- a setfenv sandbox but loadfile-loaded chunks (Driver.lua) get the real _G, so the
-- globals it reads must live there — bare `GenerateClosure = …` would land in the sandbox.
local capturedDriver
_G.GenerateClosure = function(_, boundSelf)
	capturedDriver = boundSelf
	return function() end
end
_G.UIParent = _G.UIParent or {}

loadfile("Driver.lua")("TargetedSpells", Private)

local driver = capturedDriver

-- Minimal state RepositionFrames/ReleaseFrameForUnit read, seeded fresh per test.
-- self.unitGroups is the Driver's routing index (unit -> set of group ids displaying
-- it — ids only, never frames); self.controllers holds the frames the Driver routes to.
local function resetDriver()
	driver.unitGroups = {}
	driver.dirtyGroups = {}
	driver.controllers = {}
end

-- A stand-in controller that records how many times the router relayouts it. The
-- controller owns its own frame list now, so the router's whole job is "call Relayout
-- on the right controllers"; these counts are all the scoping spec needs to observe.
local function makeController(id, seen)
	return {
		Relayout = function()
			seen[id] = (seen[id] or 0) + 1
		end,
	}
end

-- A controller stubbed to report a fixed release outcome. The real one decides per
-- frame; the Driver only ever sees this (released, remaining) pair, which is the whole
-- contract these specs exercise.
local function makeReleasingController(released, remaining)
	return {
		ReleaseForUnit = function()
			return released, remaining
		end,
	}
end

describe("RepositionFrames scoping", function()
	local seen

	before_each(function()
		resetDriver()
		seen = {}
		driver.controllers = { [1] = makeController(1, seen), [2] = makeController(2, seen) }
	end)

	it("no argument relayouts every controller", function()
		driver:RepositionFrames()

		assert.equals(1, seen[1])
		assert.equals(1, seen[2])
	end)

	it("a dirty set of one group leaves the other untouched", function()
		driver:RepositionFrames({ [1] = true })

		assert.equals(1, seen[1])
		assert.is_nil(seen[2]) -- group B never re-anchored
	end)

	it("relayouts a dirty controller exactly once, not once per frame", function()
		-- frame spread across units is no longer the router's concern: the controller
		-- owns its frame list, so scoping to a group is a single Relayout call.
		driver:RepositionFrames({ [1] = true })

		assert.equals(1, seen[1])
	end)
end)

describe("ReleaseFrameForUnit dirty-group collection", function()
	before_each(resetDriver)

	it("records the group id of every group that released something", function()
		driver.controllers = {
			[1] = makeReleasingController(true, false),
			[2] = makeReleasingController(true, false),
		}
		driver.unitGroups = { nameplate1 = { [1] = true, [2] = true } }

		local dirty = {}
		driver:ReleaseFrameForUnit("nameplate1", true, nil, dirty)

		assert.is_true(dirty[1])
		assert.is_true(dirty[2])
	end)

	it("does not record a group whose frame cannot be hidden yet", function()
		driver.controllers = {
			[1] = makeReleasingController(true, false),
			[2] = makeReleasingController(false, true), -- interrupt-delayed, still held
		}
		driver.unitGroups = { nameplate1 = { [1] = true, [2] = true } }

		local dirty = {}
		driver:ReleaseFrameForUnit("nameplate1", true, nil, dirty)

		assert.is_true(dirty[1])
		assert.is_nil(dirty[2]) -- lingering frame's group stays clean
	end)

	it("returns false for a unit it is not displaying", function()
		driver.controllers = { [1] = makeReleasingController(true, false) }

		assert.is_false(driver:ReleaseFrameForUnit("nameplate9", true, nil, {}))
	end)
end)

-- The routing index must stay an exact description of who holds what: a controller that
-- reports itself empty is dropped from the unit's set, one still holding a lingering
-- frame keeps its id so the delayed cleanup revisits it.
describe("ReleaseFrameForUnit routing maintenance", function()
	before_each(resetDriver)

	it("drops the unit entirely once every group is empty", function()
		driver.controllers = {
			[1] = makeReleasingController(true, false),
			[2] = makeReleasingController(true, false),
		}
		driver.unitGroups = { nameplate1 = { [1] = true, [2] = true } }

		assert.is_true(driver:ReleaseFrameForUnit("nameplate1", true, nil, {}))
		assert.is_nil(driver.unitGroups.nameplate1)
	end)

	it("keeps the unit and only the still-holding group when one lingers", function()
		driver.controllers = {
			[1] = makeReleasingController(true, false),
			[2] = makeReleasingController(false, true),
		}
		driver.unitGroups = { nameplate1 = { [1] = true, [2] = true } }

		driver:ReleaseFrameForUnit("nameplate1", true, nil, {})

		assert.is_not_nil(driver.unitGroups.nameplate1)
		assert.is_nil(driver.unitGroups.nameplate1[1]) -- emptied, pruned
		assert.is_true(driver.unitGroups.nameplate1[2]) -- still lingering
	end)

	it("keeps an emptied unit entry when removeUnit is false", function()
		-- ProcessInfo's release-then-reacquire path: the entry is about to be written to
		driver.controllers = { [1] = makeReleasingController(true, false) }
		driver.unitGroups = { nameplate1 = { [1] = true } }

		driver:ReleaseFrameForUnit("nameplate1", false, nil, {})

		assert.is_not_nil(driver.unitGroups.nameplate1)
		assert.same({}, driver.unitGroups.nameplate1)
	end)
end)

-- Sprint 7: the CVAR nameplate-off path must release only the Driver's own frames,
-- never Pools:ReleaseAll (which would free EditMode/Designer demo frames sharing the
-- pools). Routing through the controllers makes that structural — a controller only
-- ever holds frames it acquired for a live cast.
describe("ReleaseAllOwnFrames", function()
	before_each(resetDriver)

	it("releases through every controller and clears the routing index", function()
		local releasedAll = {}
		local function makeReleaseAllController(id)
			return {
				ReleaseAll = function()
					releasedAll[id] = true
				end,
			}
		end

		driver.controllers = { [1] = makeReleaseAllController(1), [2] = makeReleaseAllController(2) }
		driver.unitGroups = { nameplate1 = { [1] = true }, nameplate2 = { [2] = true } }

		driver:ReleaseAllOwnFrames()

		assert.is_true(releasedAll[1])
		assert.is_true(releasedAll[2])
		assert.same({}, driver.unitGroups)
	end)
end)
