---@diagnostic disable: undefined-global, undefined-field, missing-fields

-- Nameplate event shards: the unit events are registered per nameplate token slice, on
-- frames created on demand as nameplates appear. These specs pin the two properties the
-- design rests on — nothing is built before the first nameplate, and no maximum token index
-- is assumed anywhere — plus the reconciliation that has to reach every shard, including one
-- created after a capability changed.
--
-- EnsureShardForUnit is only ever reached from NAME_PLATE_UNIT_ADDED, so every case below
-- passes a nameplate token; it does not accept anything else and is not tested for it.
--
-- Driver.lua is loaded headlessly the same way the other driver specs do it (capturing the
-- singleton through its file-scope GenerateClosure call, so Init never runs).

local b = require("spec.bootstrap")
local Private = b.Private

local capturedDriver
_G.GenerateClosure = function(_, boundSelf)
	capturedDriver = boundSelf
	return function() end
end
_G.UIParent = _G.UIParent or {}

-- Records what was registered, so a shard's slice and event set are both observable.
-- `registered` maps event -> the unit list it was registered with (or true for a plain
-- RegisterEvent), which is exactly what the assertions below need.
local function MakeFrame()
	local frame = { registered = {}, scripts = {} }

	function frame:RegisterEvent(event)
		self.registered[event] = true
	end

	-- The tokens are a strided variadic, NOT a list: handing RegisterUnitEvent the table
	-- registers the event with no unit filter at all, which is the ISSUE-102 regression that
	-- let `player`/`target`/`targettarget` casts into the Driver and delivered every cast once
	-- per shard. Collecting the varargs here (and rejecting a non-string) is what makes a
	-- regression to the table form fail loudly instead of silently un-filtering.
	function frame:RegisterUnitEvent(event, ...)
		local count = select("#", ...)

		if count == 0 then
			error("RegisterUnitEvent called with no unit tokens: that is a plain RegisterEvent")
		end

		local units = {}

		for index = 1, count do
			local unit = select(index, ...)

			if type(unit) ~= "string" then
				error("RegisterUnitEvent expects unit tokens as varargs, got " .. type(unit))
			end

			units[index] = unit
		end

		self.registered[event] = units
	end

	function frame:UnregisterEvent(event)
		self.registered[event] = nil
	end

	function frame:UnregisterAllEvents()
		self.registered = {}
	end

	function frame:IsEventRegistered(event)
		return self.registered[event] ~= nil
	end

	function frame:SetScript(name, handler)
		self.scripts[name] = handler
	end

	function frame:SetSize() end

	return frame
end

_G.CreateFrame = function()
	return MakeFrame()
end

loadfile("Driver.lua")("TargetedSpells", Private)

local driver = capturedDriver

-- Capabilities are set directly rather than derived from a Groups table: GetCapabilities
-- returns the cached value when it is non-nil, and the reduction itself is already covered
-- by groups_spec. `enabled` is what gates registration; the interruptibility pair keys off
-- usesInterruptibility/usesShield.
local function SetCapabilities(overrides)
	local capabilities = {
		enabled = true,
		usesInterruptibility = false,
		usesShield = false,
		showsTargetMarker = false,
		indicatesInterrupts = false,
	}

	for key, value in pairs(overrides or {}) do
		capabilities[key] = value
	end

	driver.capabilities = capabilities
end

local function ResetDriver()
	driver.shards = {}
	driver.frame = MakeFrame()
	driver.OnFrameEventClosure = function() end
	SetCapabilities()
end

-- The number of shards currently allocated (the table is keyed by shard index, not dense).
local function ShardCount()
	local count = 0

	for _ in pairs(driver.shards) do
		count = count + 1
	end

	return count
end

describe("shard allocation", function()
	before_each(ResetDriver)

	it("allocates nothing until a nameplate appears", function()
		assert.equals(0, ShardCount())
	end)

	it("maps the first four tokens onto one shard", function()
		for index = 1, 4 do
			driver:EnsureShardForUnit("nameplate" .. index)
		end

		assert.equals(1, ShardCount())
		assert.is_not_nil(driver.shards[1])
	end)

	it("registers the whole slice on creation, not just the arriving token", function()
		driver:EnsureShardForUnit("nameplate3")

		assert.same({ "nameplate1", "nameplate2", "nameplate3", "nameplate4" }, driver.shards[1].units)
	end)

	it("reuses the existing shard for another token in the same slice", function()
		driver:EnsureShardForUnit("nameplate1")
		local first = driver.shards[1]

		driver:EnsureShardForUnit("nameplate2")

		assert.is_true(first == driver.shards[1])
		assert.equals(1, ShardCount())
	end)

	it("starts a new shard at the slice boundary", function()
		driver:EnsureShardForUnit("nameplate5")

		assert.is_nil(driver.shards[1])
		assert.is_not_nil(driver.shards[2])
		assert.same({ "nameplate5", "nameplate6", "nameplate7", "nameplate8" }, driver.shards[2].units)
	end)

	it("puts the highest observed token on the tenth shard", function()
		driver:EnsureShardForUnit("nameplate40")

		assert.is_not_nil(driver.shards[10])
		assert.same({ "nameplate37", "nameplate38", "nameplate39", "nameplate40" }, driver.shards[10].units)
	end)

	-- The point of allocating lazily: there is no ceiling to exceed, so a token past the
	-- range we expect is tracked rather than silently dropped.
	it("allocates past the expected range instead of dropping the token", function()
		driver:EnsureShardForUnit("nameplate41")

		assert.is_not_nil(driver.shards[11])
		assert.same({ "nameplate41", "nameplate42", "nameplate43", "nameplate44" }, driver.shards[11].units)
	end)
end)

describe("shard configuration", function()
	before_each(ResetDriver)

	it("registers the cast events for its own slice", function()
		driver:EnsureShardForUnit("nameplate1")
		local shard = driver.shards[1]

		assert.same(shard.units, shard.registered.UNIT_SPELLCAST_START)
		assert.same(shard.units, shard.registered.UNIT_SPELLCAST_STOP)
		assert.same(shard.units, shard.registered.UNIT_TARGET)
	end)

	it("shares the driver's single event handler", function()
		driver:EnsureShardForUnit("nameplate1")

		assert.is_true(driver.shards[1].scripts.OnEvent == driver.OnFrameEventClosure)
	end)

	it("leaves the interruptibility pair off when no group reads it", function()
		driver:EnsureShardForUnit("nameplate1")
		local shard = driver.shards[1]

		assert.is_nil(shard.registered.UNIT_SPELLCAST_INTERRUPTIBLE)
		assert.is_nil(shard.registered.UNIT_SPELLCAST_NOT_INTERRUPTIBLE)
	end)

	-- A shard born after the capability was already on must not be the one shard missing it.
	it("gives a shard created mid-session the interruptibility pair already in effect", function()
		SetCapabilities({ usesInterruptibility = true })

		driver:EnsureShardForUnit("nameplate1")
		local shard = driver.shards[1]

		assert.same(shard.units, shard.registered.UNIT_SPELLCAST_INTERRUPTIBLE)
		assert.same(shard.units, shard.registered.UNIT_SPELLCAST_NOT_INTERRUPTIBLE)
	end)

	it("registers the interruptibility pair for the shield too", function()
		SetCapabilities({ usesShield = true })

		driver:EnsureShardForUnit("nameplate1")

		assert.same(driver.shards[1].units, driver.shards[1].registered.UNIT_SPELLCAST_INTERRUPTIBLE)
	end)

	-- ISSUE-102 regression guard. Passing the token list as a table registers the event
	-- unfiltered, which is not observable in-game as an error — only as casts arriving for
	-- units that have no nameplate, and as one delivery per shard. The stub above rejects a
	-- table outright; this pins the tokens that must actually reach the client.
	it("registers its whole slice as separate unit tokens", function()
		driver:EnsureShardForUnit("nameplate6")
		local shard = driver.shards[2]

		assert.same({ "nameplate5", "nameplate6", "nameplate7", "nameplate8" }, shard.units)

		for _, event in ipairs({ "UNIT_TARGET", "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP" }) do
			assert.same(
				{ "nameplate5", "nameplate6", "nameplate7", "nameplate8" },
				shard.registered[event],
				event .. " must be filtered to the shard's four tokens"
			)
		end
	end)

	it("registers nothing on a shard created while no display is active", function()
		SetCapabilities({ enabled = false })

		driver:EnsureShardForUnit("nameplate1")
		local shard = driver.shards[1]

		assert.same({}, shard.registered)
		assert.is_nil(shard.scripts.OnEvent)
	end)
end)

describe("SetupFrame shard reconciliation", function()
	before_each(function()
		ResetDriver()

		-- two shards, so "every shard" is actually observable
		driver:EnsureShardForUnit("nameplate1")
		driver:EnsureShardForUnit("nameplate5")
	end)

	it("turns the interruptibility pair on across every shard", function()
		SetCapabilities({ usesInterruptibility = true })
		driver:SetupFrame(false)

		for _, index in ipairs({ 1, 2 }) do
			local shard = driver.shards[index]
			assert.same(shard.units, shard.registered.UNIT_SPELLCAST_INTERRUPTIBLE)
		end
	end)

	it("turns the interruptibility pair back off across every shard", function()
		SetCapabilities({ usesInterruptibility = true })
		driver:SetupFrame(false)

		SetCapabilities({ usesInterruptibility = false })
		driver:SetupFrame(false)

		for _, index in ipairs({ 1, 2 }) do
			local shard = driver.shards[index]
			assert.is_nil(shard.registered.UNIT_SPELLCAST_INTERRUPTIBLE)
			assert.is_nil(shard.registered.UNIT_SPELLCAST_NOT_INTERRUPTIBLE)
		end
	end)

	it("clears every shard when the last display is disabled", function()
		driver:SetupFrame(false)
		assert.is_not_nil(driver.shards[1].registered.UNIT_SPELLCAST_START)

		SetCapabilities({ enabled = false })
		driver:SetupFrame(false)

		for _, index in ipairs({ 1, 2 }) do
			local shard = driver.shards[index]
			assert.same({}, shard.registered)
			assert.is_nil(shard.scripts.OnEvent)
		end
	end)

	-- A raw CVAR_UPDATE registration delivers every CVar the client or any addon writes;
	-- measured at 1275 of 1701 total driver events in one session, all but two discarded after
	-- a string compare. These pin that the driver goes through the by-name registry instead.
	describe("CVar callbacks", function()
		it("registers by CVar name rather than listening to CVAR_UPDATE", function()
			driver:SetupFrame(false)

			assert.is_nil(driver.frame.registered.CVAR_UPDATE)
			assert.is_not_nil(CVarCallbackRegistry.callbacks.nameplateShowEnemies[driver])
			assert.is_not_nil(CVarCallbackRegistry.callbacks.nameplateShowOffscreen[driver])
		end)

		-- SetupFrame is called on every group edit, so a non-idempotent registration would
		-- accumulate one callback per edit for the whole session
		it("does not accumulate callbacks across repeated reconciliation", function()
			driver:SetupFrame(false)
			driver:SetupFrame(false)
			driver:SetupFrame(false)

			local count = 0

			for _ in pairs(CVarCallbackRegistry.callbacks.nameplateShowEnemies) do
				count = count + 1
			end

			assert.equals(1, count)
		end)

		it("drops the callbacks when every group is disabled", function()
			driver:SetupFrame(false)
			SetCapabilities({ enabled = false })
			driver:SetupFrame(false)

			assert.is_nil(CVarCallbackRegistry.callbacks.nameplateShowEnemies[driver])
			assert.is_nil(CVarCallbackRegistry.callbacks.nameplateShowOffscreen[driver])
		end)

		it("releases every frame when enemy nameplates are turned off", function()
			driver:SetupFrame(false)

			local released = false
			driver.ReleaseAllOwnFrames = function()
				released = true
			end

			CVarCallbackRegistry:TriggerEvent("nameplateShowEnemies", "0")

			assert.is_true(released)
		end)

		it("ignores an enemy-nameplate write that is not a disable", function()
			driver:SetupFrame(false)

			local released = false
			driver.ReleaseAllOwnFrames = function()
				released = true
			end

			CVarCallbackRegistry:TriggerEvent("nameplateShowEnemies", "1")

			assert.is_false(released)
		end)
	end)

	it("keeps the cast events off the driver frame", function()
		driver:SetupFrame(false)

		assert.is_nil(driver.frame.registered.UNIT_SPELLCAST_START)
		assert.is_nil(driver.frame.registered.UNIT_TARGET)
		-- the non-unit events and the single-token one stay on it
		assert.is_true(driver.frame.registered.NAME_PLATE_UNIT_ADDED)
		assert.same({ "player" }, driver.frame.registered.PLAYER_SPECIALIZATION_CHANGED)
	end)

	it("re-enables the driver frame and its shards after a disable", function()
		SetCapabilities({ enabled = false })
		driver:SetupFrame(false)

		SetCapabilities({ enabled = true })
		driver:SetupFrame(false)

		assert.is_true(driver.frame.registered.NAME_PLATE_UNIT_ADDED)

		for _, index in ipairs({ 1, 2 }) do
			local shard = driver.shards[index]
			assert.same(shard.units, shard.registered.UNIT_SPELLCAST_START)
			assert.is_true(shard.scripts.OnEvent == driver.OnFrameEventClosure)
		end
	end)
end)
