---@type string, TargetedSpells
local addonName, Private = ...

-- Single slash-command dispatcher for the addon. Modules register their own
-- subcommands (Settings → `options`/`settings`, Designer → `design`); the one
-- /<addon> entry routes to them and, on an empty or unknown argument, prints the
-- available commands. There is exactly one SlashCmdList entry (wired at load).
-- Only Register / Dispatch are public; parsing, the registry and the login wiring
-- stay file-local (surfaced under Private.__test for the specs).

---@class SlashCommandEntry
---@field name string
---@field description string
---@field handler fun(rest: string)

-- ordered so the help listing follows registration order
---@type SlashCommandEntry[]
local commands = {}
---@type table<string, SlashCommandEntry>
local byName = {}

-- the user-facing slash token (e.g. "targetedspells"), resolved from the addon
-- Title at login so the command name tracks the metadata, not a literal string.
local slashToken

---@param message string?
---@return string command, string rest
local function parse(message)
	local command, rest = (message or ""):match("^%s*(%S*)%s*(.-)%s*$")
	return string.lower(command or ""), rest or ""
end

-- Resolves a raw message to its command entry, or nil when the argument is empty
-- or unrecognised (→ show help).
---@param message string?
---@return SlashCommandEntry? entry, string rest
local function resolve(message)
	local command, rest = parse(message)

	if command == "" then
		return nil, rest
	end

	return byName[command], rest
end

-- Lines printed for an empty or unknown command.
---@return string[]
local function helpLines()
	local token = slashToken or string.lower(addonName)
	local lines = { Private.L.SlashCommands.Header }

	for index = 1, #commands do
		local entry = commands[index]
		lines[#lines + 1] = string.format("  /%s %s - %s", token, entry.name, entry.description)
	end

	return lines
end

Private.SlashCommands = {}

-- Registers (or overrides) a subcommand. Re-registering an existing name replaces
-- its handler/description while keeping its slot in the help listing.
---@param name string
---@param description string
---@param handler fun(rest: string)
function Private.SlashCommands.Register(name, description, handler)
	name = string.lower(name)
	local entry = byName[name]

	if entry then
		entry.description = description
		entry.handler = handler
		return
	end

	entry = { name = name, description = description, handler = handler }
	byName[name] = entry
	commands[#commands + 1] = entry
end

-- Routes a raw slash message. An empty or unknown command prints the help listing.
---@param message string?
function Private.SlashCommands.Dispatch(message)
	local entry, rest = resolve(message)

	if entry then
		entry.handler(rest)
		return
	end

	for _, line in ipairs(helpLines()) do
		print(line)
	end
end

-- Installs the single SlashCmdList entry. The token is the addon *name* (no
-- spaces) rather than the Title ("Targeted Spells") — a slash trigger containing
-- a space is unmatchable, since the chat parser splits on the first whitespace.
-- A short "/ts" alias is registered alongside it. Runs at file load: SlashCmdList
-- and the SLASH_ globals are available immediately, and subcommands need only be
-- registered by the time the user actually types the command.
local function Setup()
	slashToken = string.lower(addonName)
	local key = string.upper(addonName)

	_G[string.format("SLASH_%s1", key)] = "/" .. slashToken
	_G[string.format("SLASH_%s2", key)] = "/ts"
	SlashCmdList[key] = function(message)
		Private.SlashCommands.Dispatch(message)
	end
end

Setup()

-- Gated test-only internals (never ships behaviour): the pure parse/resolve helpers
-- and the registry the dispatcher specs assert against.
Private.__test = Private.__test or {}
Private.__test.SlashCommands = {
	parse = parse,
	resolve = resolve,
	helpLines = helpLines,
	commands = commands,
	reset = function()
		table.wipe(commands)
		table.wipe(byName)
		slashToken = nil
	end,
}
