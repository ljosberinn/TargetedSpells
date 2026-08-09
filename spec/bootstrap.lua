---@diagnostic disable: undefined-global

local cbor = require("cbor")
local base64 = require("spec.base64")

local addonName = "TargetedSpells"
local Private = {}

-- WoW global not present in plain Lua 5.1
function table.wipe(target)
	for key in pairs(target) do
		target[key] = nil
	end
	return target
end

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
			-- ApplyBorderStyle fetches the border art path; the name round-trips so a spec
			-- can assert which media a style resolved to
			Fetch = function(_, mediaType, key)
				return string.format("%s/%s", tostring(mediaType), tostring(key))
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

-- ColorMixin stand-ins: only the four channels are read by the addon.
function CreateColor(r, g, b, a)
	return { r = r, g = g, b = b, a = a }
end

-- AARRGGBB, matching the hex strings the element schema stores.
function CreateColorFromHexString(hex)
	local a, r, g, b = hex:match("^(%x%x)(%x%x)(%x%x)(%x%x)$")

	return CreateColor(tonumber(r, 16) / 255, tonumber(g, 16) / 255, tonumber(b, 16) / 255, tonumber(a, 16) / 255)
end

Private.LoginFnQueue = {}

loadfile("Settings.lua")(addonName, Private)

Enum = { LuaCurveType = { Linear = 0 } }

-- Driver.lua reads the unit-token cap at file scope to size its nameplate event shards.
Constants = { UnitEventConstants = { MAX_UNIT_TOKENS_IN_EVENT = 4 } }

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

-- Blizzard's CVar callback registry (Blizzard_SharedXMLBase/CvarUtil.lua). Faithful on the two
-- properties the Driver depends on: callbacks are keyed by CVar name so only that CVar's
-- writes reach them, and registration is idempotent per owner ("an owner can have a single
-- callback per event" — CallbackRegistry.lua), which is what lets the Driver register from
-- SetupFrame's repeatedly-called reconciliation. TriggerEvent passes the owner first, matching
-- securecallfunction(func, owner, ...) in the real TriggerEvent.
CVarCallbackRegistry = {
	callbacks = {},
}

function CVarCallbackRegistry:RegisterCallback(event, func, owner)
	if self.callbacks[event] == nil then
		self.callbacks[event] = {}
	end

	self.callbacks[event][owner] = func
end

function CVarCallbackRegistry:UnregisterCallback(event, owner)
	if self.callbacks[event] ~= nil then
		self.callbacks[event][owner] = nil
	end
end

function CVarCallbackRegistry:TriggerEvent(event, ...)
	if self.callbacks[event] == nil then
		return
	end

	for owner, func in pairs(self.callbacks[event]) do
		func(owner, ...)
	end
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

SlashCmdList = {}
loadfile("Utils.lua")(addonName, Private)
loadfile("Design.lua")(addonName, Private)
loadfile("Groups.lua")(addonName, Private)
loadfile("Migration.lua")(addonName, Private)


-- ── State kept in bootstrap's own _G (shared with Utils.lua loaded here) ──────
-- Busted uses setfenv() to sandbox spec files in Lua 5.1, so assignments to
-- globals from within a spec's before_each land in the spec's sandbox rather
-- than in bootstrap's _G. All TargetedSpellsSaved mutations must go through
-- these helpers so they always update the same table Utils.lua reads.

-- Returns the live TargetedSpellsSaved table from bootstrap's scope.
-- Tests MUST use this instead of the global to avoid the setfenv split.
local function savedVars()
	return TargetedSpellsSaved
end

local function resetToV4()
	table.wipe(TargetedSpellsSaved)
	TargetedSpellsSaved.SchemaVersion = 4
	TargetedSpellsSaved.Groups = Private.Groups.CreateStarterGroups()
	TargetedSpellsSaved.TextToSpeech = {
		AnnounceUntargetedSpells = {
			[Private.Enum.NpcType.Boss] = true,
			[Private.Enum.NpcType.Lieutenant] = true,
			[Private.Enum.NpcType.Other] = true,
			[Private.Enum.NpcType.Minion] = false,
		},
		AnnounceTargetedSpells = {
			[Private.Enum.NpcType.Boss] = false,
			[Private.Enum.NpcType.Lieutenant] = false,
			[Private.Enum.NpcType.Other] = false,
			[Private.Enum.NpcType.Minion] = false,
		},
		TextToSpeechVoice = -1,
	}
	table.wipe(Private.EventRegistry.triggeredEvents)
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
	resetToV4 = resetToV4,
	savedVars = savedVars,
	encode = encode,
	exportDecoded = exportDecoded,
}
