---@diagnostic disable: undefined-global

local cbor = require("cbor")
local base64 = require("spec.base64")

local addonName = "TargetedSpells"
local Private = {}

loadfile("Enum.lua")(addonName, Private)

LibStub = function(name)
	if name == "LibSharedMedia-3.0" then
		return {
			Register = function() end,
			List = function()
				return {}
			end,
			HashTable = function()
				return {}
			end,
			MediaType = {
				FONT = "font",
				STATUSBAR = "statusbar",
				BORDER = "border",
				BACKGROUND = "background",
			},
		}
	end
	return {}
end

Private.LoginFnQueue = {}

loadfile("Settings.lua")(addonName, Private)

Enum = { LuaCurveType = { Linear = 0 } }

C_CurveUtil = {
	CreateCurve = function()
		return { SetType = function() end, AddPoint = function() end }
	end,
}

C_StringUtil = {
	CreateNumericRuleFormatter = function()
		return { SetBreakpoints = function() end }
	end,
}

UIParent = {}

CreateFramePool = function()
	return {
		Acquire = function()
			return {}
		end,
		Release = function() end,
	}
end

C_EncodingUtil = {
	SerializeCBOR = function(t)
		return cbor.encode(t)
	end,
	DeserializeCBOR = function(s)
		return cbor.decode(s)
	end,
	EncodeBase64 = function(s)
		return base64.encode(s)
	end,
	DecodeBase64 = function(s)
		return base64.decode(s)
	end,
}

Private.EventRegistry = {
	triggeredEvents = {},
	TriggerEvent = function(self, event, ...)
		table.insert(self.triggeredEvents, { event = event, args = { ... } })
	end,
}

Private.L = setmetatable({}, {
	__index = function()
		return setmetatable({}, {
			__index = function(_, k)
				return k
			end,
		})
	end,
})

TargetedSpellsSaved = {}

loadfile("Utils.lua")(addonName, Private)

-- ── State kept in bootstrap's own _G (shared with Utils.lua loaded here) ──────
-- Busted uses setfenv() to sandbox spec files in Lua 5.1, so assignments to
-- globals from within a spec's before_each land in the spec's sandbox rather
-- than in bootstrap's _G. All TargetedSpellsSaved mutations must go through
-- these helpers so they always update the same table Utils.lua reads.

local function reset()
	TargetedSpellsSaved = {
		V3MigrationWarningSeen = false,
		Settings = {
			Self = Private.Settings.GetSelfDefaultSettings(),
			Party = Private.Settings.GetPartyDefaultSettings(),
		},
	}
	Private.EventRegistry.triggeredEvents = {}
end

-- Returns the live TargetedSpellsSaved table from bootstrap's scope.
-- Tests MUST use this instead of the global to avoid the setfenv split.
local function savedVars()
	return TargetedSpellsSaved
end

-- Re-encodes a (possibly modified) settings table into an import string.
local function encode(tbl)
	return C_EncodingUtil.EncodeBase64(C_EncodingUtil.SerializeCBOR(tbl))
end

-- Decodes the current Export() output. Works because both Export() and this
-- helper run in bootstrap's _G where TargetedSpellsSaved is properly set.
local function exportDecoded()
	return C_EncodingUtil.DeserializeCBOR(C_EncodingUtil.DecodeBase64(Private.Utils.Export()))
end

return {
	Private = Private,
	reset = reset,
	savedVars = savedVars,
	encode = encode,
	exportDecoded = exportDecoded,
}
