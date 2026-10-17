---@diagnostic disable: undefined-global, undefined-field

local b = require("spec.bootstrap")
local Enum = b.Private.Enum

local LOCALES = { "deDE", "esES", "esMX", "frFR", "itIT", "koKR", "ptBR", "ruRU", "zhCN", "zhTW" }

-- Blizzard GlobalStrings resolve to their own name, so a label sourced from one still
-- counts as a key instead of vanishing as nil.
local environment = setmetatable({}, {
	__index = function(_, key)
		local value = _G[key]
		if value == nil and type(key) == "string" and key:match("^[A-Z][A-Z0-9_]+$") then
			return key
		end

		return value
	end,
})

---@param tbl table
---@param prefix string?
---@param out table<string, any>?
---@return table<string, any>
local function Flatten(tbl, prefix, out)
	out = out or {}
	for key, value in pairs(tbl) do
		local path = prefix and (prefix .. "." .. tostring(key)) or tostring(key)
		if type(value) == "table" then
			Flatten(value, path, out)
		else
			out[path] = value
		end
	end

	return out
end

-- Every locale file resets the namespaces enUS fills, so a key it omits is nil in-game.
---@param locale string?
---@return table<string, any>
local function Load(locale)
	local Private = { L = {}, Enum = Enum }

	for _, name in ipairs({ "enUS", locale }) do
		local chunk = assert(loadfile("Localization/" .. name .. ".lua"))
		setfenv(chunk, environment)
		chunk("TargetedSpells", Private)
	end

	return Flatten(Private.L)
end

---@param text any
---@return integer
local function CountSpecifiers(text)
	if type(text) ~= "string" then
		return 0
	end

	local _, count = text:gsub("%%[sd]", "")

	return count
end

describe("Localization", function()
	local english = Load(nil)

	for _, locale in ipairs(LOCALES) do
		describe(locale, function()
			local translated = Load(locale)

			it("defines exactly the enUS keys", function()
				for key in pairs(english) do
					assert.is_not_nil(translated[key], key)
				end

				for key in pairs(translated) do
					assert.is_not_nil(english[key], key)
				end
			end)

			it("keeps the format specifiers of enUS", function()
				for key, value in pairs(english) do
					assert.equals(CountSpecifiers(value), CountSpecifiers(translated[key]), key)
				end
			end)
		end)
	end
end)
