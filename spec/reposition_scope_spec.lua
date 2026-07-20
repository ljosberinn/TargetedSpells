---@diagnostic disable: undefined-global, undefined-field, missing-fields

-- Sprint 3: RepositionFrames must relayout only the group(s) whose membership
-- changed. These specs load Driver.lua headlessly (capturing the driver singleton
-- via its file-scope GenerateClosure call) and spy on AdjustLayout to assert which
-- group containers get re-anchored.

local b = require("spec.bootstrap")
local Private = b.Private
local Enum = Private.Enum

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
-- self.frames is the Driver's release-by-unit index (read by ReleaseFrameForUnit /
-- ReleaseAllOwnFrames); self.controllers is the per-group ownership RepositionFrames
-- now routes to.
local function resetDriver()
	driver.frames = {}
	driver.dirtyGroups = {}
	driver.controllers = {}
end

local function makeGroup(id)
	return {
		Id = id,
		Template = Enum.Template.Icon,
		SortOrder = Enum.SortOrder.Ascending,
		Direction = Enum.Direction.Vertical,
		Grow = Enum.Grow.End,
		Gap = 2,
		Elements = { [Enum.Element.Icon] = { width = 48, height = 48 } },
	}
end

local function makeFrame(group, startTime, canBeHidden)
	return {
		GetGroup = function()
			return group
		end,
		GetStartTime = function()
			return startTime
		end,
		CanBeHidden = function()
			return canBeHidden ~= false
		end,
	}
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
	before_each(function()
		resetDriver()
		-- releasing is out of scope here; record nothing and let the frame drop
		driver.ReleaseFrame = function() end
	end)

	it("records the group id of every released frame", function()
		local groupA, groupB = makeGroup(1), makeGroup(2)
		driver.frames = {
			nameplate1 = { makeFrame(groupA, 10), makeFrame(groupB, 20) },
		}

		local dirty = {}
		driver:ReleaseFrameForUnit("nameplate1", true, nil, dirty)

		assert.is_true(dirty[1])
		assert.is_true(dirty[2])
	end)

	it("does not record groups of frames that cannot be hidden yet", function()
		local groupA, groupB = makeGroup(1), makeGroup(2)
		driver.frames = {
			nameplate1 = { makeFrame(groupA, 10, true), makeFrame(groupB, 20, false) },
		}

		local dirty = {}
		driver:ReleaseFrameForUnit("nameplate1", true, nil, dirty)

		assert.is_true(dirty[1])
		assert.is_nil(dirty[2]) -- lingering (interrupt-delayed) frame's group stays clean
	end)
end)

-- Sprint 7: the CVAR nameplate-off path must release only the Driver's own frames,
-- never Pools:ReleaseAll (which would free EditMode/Designer demo frames sharing the pools).
describe("ReleaseAllOwnFrames", function()
	before_each(resetDriver)

	it("releases every frame in self.frames and leaves foreign frames alone", function()
		local groupA = makeGroup(1)
		local own1, own2 = makeFrame(groupA, 10), makeFrame(groupA, 20)
		local demoFrame = makeFrame(groupA, 30) -- shares the pool but not owned by the Driver

		driver.frames = { nameplate1 = { own1 }, nameplate2 = { own2 } }

		local released = {}
		driver.ReleaseFrame = function(_, frame)
			released[frame] = true
		end

		driver:ReleaseAllOwnFrames()

		assert.is_true(released[own1])
		assert.is_true(released[own2])
		assert.is_nil(released[demoFrame]) -- never touched: not in self.frames
		assert.same({}, driver.frames)
	end)
end)

-- Sprint 8: a group that enables the InterruptShield must gate the interruptibility
-- flip events regardless of bar colour mode. AnyGroupUsesShield reads the TargetedSpellsSaved
-- global (the Driver chunk's env), so the tests set it there and restore afterwards.
describe("AnyGroupUsesShield", function()
	local savedVars

	before_each(function()
		savedVars = _G.TargetedSpellsSaved
	end)

	after_each(function()
		_G.TargetedSpellsSaved = savedVars
	end)

	local function barGroupWithShield(shieldActive)
		return {
			Enabled = true,
			Template = Enum.Template.Bar,
			Elements = { [Enum.Element.InterruptShield] = { active = shieldActive } },
		}
	end

	local function withGroups(groups)
		_G.TargetedSpellsSaved = { Groups = groups }
	end

	it("is true for an enabled bar group with an active shield", function()
		withGroups({ barGroupWithShield(true) })
		assert.is_true(driver:AnyGroupUsesShield())
	end)

	it("is false when the shield element is present but inactive", function()
		withGroups({ barGroupWithShield(false) })
		assert.is_false(driver:AnyGroupUsesShield())
	end)

	it("is false when the group carrying the shield is disabled", function()
		local group = barGroupWithShield(true)
		group.Enabled = false
		withGroups({ group })
		assert.is_false(driver:AnyGroupUsesShield())
	end)

	it("is false for a non-bar (icon) group even with an active shield element", function()
		local group = barGroupWithShield(true)
		group.Template = Enum.Template.Icon
		withGroups({ group })
		assert.is_false(driver:AnyGroupUsesShield())
	end)
end)
