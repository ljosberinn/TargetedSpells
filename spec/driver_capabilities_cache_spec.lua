---@diagnostic disable: undefined-global, undefined-field

-- Driver-side of the capability cache (the #2 half): GetCapabilities memoises the
-- pure Groups.ComputeCapabilities result and only recomputes after InvalidateCapabilities.
-- Loads Driver.lua headlessly via the GenerateClosure capture (see reposition_scope_spec)
-- and drives the cache through the real reduction against a controlled Groups table, so a
-- mutation is observable only across an invalidation.

local b = require("spec.bootstrap")
local Private = b.Private

local capturedDriver
_G.GenerateClosure = function(_, boundSelf)
	capturedDriver = boundSelf
	return function() end
end
_G.UIParent = _G.UIParent or {}

loadfile("Driver.lua")("TargetedSpells", Private)

local driver = capturedDriver

describe("Driver capability cache", function()
	before_each(function()
		_G.TargetedSpellsSaved = { Groups = {} }
		driver.capabilities = nil
	end)

	it("computes on first read and memoises the same table", function()
		local first = driver:GetCapabilities()
		local second = driver:GetCapabilities()

		assert.is_false(first.enabled)
		assert.is_true(first == second)
	end)

	it("does not observe a group mutation until invalidated", function()
		local before = driver:GetCapabilities()
		assert.is_false(before.enabled)

		-- mutate the group set behind the cache's back
		TargetedSpellsSaved.Groups[1] = { Enabled = true }

		local stale = driver:GetCapabilities()
		assert.is_true(stale == before)
		assert.is_false(stale.enabled)
	end)

	it("recomputes after InvalidateCapabilities", function()
		local before = driver:GetCapabilities()

		TargetedSpellsSaved.Groups[1] = { Enabled = true }
		driver:InvalidateCapabilities()

		local fresh = driver:GetCapabilities()
		assert.is_false(fresh == before)
		assert.is_true(fresh.enabled)
	end)
end)
