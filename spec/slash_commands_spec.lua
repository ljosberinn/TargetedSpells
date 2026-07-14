---@diagnostic disable: undefined-global, undefined-field

local b = require("spec.bootstrap")
local Private = b.Private
local SlashCommands = Private.SlashCommands
local internals = Private.__test.SlashCommands

local parse = internals.parse
local resolve = internals.resolve

describe("SlashCommands", function()
	before_each(function()
		internals.reset()
	end)

	describe("parse", function()
		it("splits command and rest, lowercasing the command", function()
			local command, rest = parse("Design foo bar")
			assert.equals("design", command)
			assert.equals("foo bar", rest)
		end)

		it("tolerates leading/trailing whitespace", function()
			local command, rest = parse("   options   ")
			assert.equals("options", command)
			assert.equals("", rest)
		end)

		it("treats nil / empty as an empty command", function()
			local nilCommand = parse(nil)
			local emptyCommand = parse("")
			assert.equals("", nilCommand)
			assert.equals("", emptyCommand)
		end)
	end)

	describe("Register", function()
		it("adds a command resolvable by name (case-insensitive)", function()
			SlashCommands.Register("Design", "open designer", function() end)
			local entry = resolve("design")
			assert.is_not_nil(entry)
			assert.equals("design", entry.name)
		end)

		it("overrides handler/description in place without duplicating the slot", function()
			local first = function() end
			local second = function() end
			SlashCommands.Register("design", "old", first)
			SlashCommands.Register("design", "new", second)

			assert.equals(1, #internals.commands)
			local entry = resolve("design")
			assert.equals("new", entry.description)
			assert.equals(second, entry.handler)
		end)

		it("preserves registration order for the help listing", function()
			SlashCommands.Register("options", "a", function() end)
			SlashCommands.Register("design", "b", function() end)
			assert.equals("options", internals.commands[1].name)
			assert.equals("design", internals.commands[2].name)
		end)
	end)

	describe("Dispatch", function()
		it("routes to the matching handler, passing the rest", function()
			local seen
			SlashCommands.Register("design", "d", function(rest)
				seen = rest
			end)
			SlashCommands.Dispatch("design keep this")
			assert.equals("keep this", seen)
		end)

		it("does not invoke a handler for an empty command", function()
			local called = false
			SlashCommands.Register("design", "d", function()
				called = true
			end)
			SlashCommands.Dispatch("")
			assert.is_false(called)
		end)

		it("does not invoke a handler for an unknown command", function()
			local called = false
			SlashCommands.Register("design", "d", function()
				called = true
			end)
			SlashCommands.Dispatch("bogus")
			assert.is_false(called)
		end)
	end)

	describe("helpLines", function()
		it("lists a header plus one line per registered command", function()
			SlashCommands.Register("options", "Open the settings panel", function() end)
			SlashCommands.Register("design", "Open the layout designer", function() end)
			local lines = internals.helpLines()
			assert.equals(3, #lines)
			assert.is_true(lines[2]:find("options", 1, true) ~= nil)
			assert.is_true(lines[2]:find("Open the settings panel", 1, true) ~= nil)
			assert.is_true(lines[3]:find("design", 1, true) ~= nil)
		end)
	end)
end)
