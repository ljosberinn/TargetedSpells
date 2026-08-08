---@diagnostic disable: undefined-global, undefined-field

local b = require("spec.bootstrap")
local Private = b.Private
local Enum = Private.Enum
local Element = Enum.Element

describe("Export", function()
	before_each(function()
		b.resetToV4()
	end)

	it("returns a non-empty string", function()
		local exported = Private.Utils.Export()
		assert.is_string(exported)
		assert.is_true(#exported > 0)
	end)

	it("serialises the group model, not the retired Settings tree", function()
		local decoded = b.exportDecoded()
		assert.is_table(decoded)
		assert.equals(4, decoded.SchemaVersion)
		assert.is_table(decoded.Groups)
		assert.is_table(decoded.TextToSpeech)
		assert.is_nil(decoded.Self)
		assert.is_nil(decoded.Party)
	end)
end)

describe("Round-trip (no change)", function()
	before_each(function()
		b.resetToV4()
	end)

	it("importing an exported snapshot returns false when nothing changed", function()
		assert.is_false(Private.Utils.Import(Private.Utils.Export()))
	end)

	it("fires no events when nothing changed", function()
		Private.Utils.Import(Private.Utils.Export())
		assert.equals(0, #Private.EventRegistry.triggeredEvents)
	end)
end)

describe("Group import", function()
	before_each(function()
		b.resetToV4()
	end)

	it("restores a changed container field", function()
		local exported = Private.Utils.Export()
		b.savedVars().Groups[1].Gap = 999
		assert.is_true(Private.Utils.Import(exported))
		assert.equals(2, b.savedVars().Groups[1].Gap)
	end)

	it("restores a changed element field", function()
		local exported = Private.Utils.Export()
		b.savedVars().Groups[1].Elements[Element.Icon].width = 999
		assert.is_true(Private.Utils.Import(exported))
		assert.equals(48, b.savedVars().Groups[1].Elements[Element.Icon].width)
	end)

	it("fires PROFILE_IMPORTED when something changed", function()
		local exported = Private.Utils.Export()
		b.savedVars().Groups[1].Gap = 999
		Private.Utils.Import(exported)

		local found = false
		for _, ev in ipairs(Private.EventRegistry.triggeredEvents) do
			if ev.event == Enum.Events.PROFILE_IMPORTED then
				found = true
			end
		end
		assert.is_true(found)
	end)

	-- edit-mode instances capture the group table itself, so an import that swapped
	-- the tables out would strand every one of those references
	it("updates group tables in place rather than replacing them", function()
		local exported = Private.Utils.Export()
		local groupRef = b.savedVars().Groups[1]
		b.savedVars().Groups[1].Gap = 999
		Private.Utils.Import(exported)
		assert.is_true(groupRef == b.savedVars().Groups[1])
	end)

	it("adds a group present only in the payload and stamps its id", function()
		local decoded = b.exportDecoded()
		decoded.Groups[3] = Private.Utils.DeepCopy(decoded.Groups[1])
		assert.is_true(Private.Utils.Import(b.encode(decoded)))
		assert.is_not_nil(b.savedVars().Groups[3])
		assert.equals(3, b.savedVars().Groups[3].Id)
	end)

	it("removes a group absent from the payload", function()
		local exported = Private.Utils.Export()
		b.savedVars().Groups[3] = Private.Utils.DeepCopy(b.savedVars().Groups[1])
		assert.is_true(Private.Utils.Import(exported))
		assert.is_nil(b.savedVars().Groups[3])
	end)

	it("re-stamps Id from the key when the payload disagrees", function()
		local decoded = b.exportDecoded()
		decoded.Groups[1].Id = 99
		assert.is_true(Private.Utils.Import(b.encode(decoded)))
		assert.equals(1, b.savedVars().Groups[1].Id)
	end)
end)

describe("TextToSpeech import", function()
	before_each(function()
		b.resetToV4()
	end)

	it("restores a changed announcement flag", function()
		local exported = Private.Utils.Export()
		b.savedVars().TextToSpeech.AnnounceUntargetedSpells[Enum.NpcType.Boss] = false
		assert.is_true(Private.Utils.Import(exported))
		assert.is_true(b.savedVars().TextToSpeech.AnnounceUntargetedSpells[Enum.NpcType.Boss])
	end)

	it("restores a changed voice", function()
		local decoded = b.exportDecoded()
		decoded.TextToSpeech.TextToSpeechVoice = 5
		assert.is_true(Private.Utils.Import(b.encode(decoded)))
		assert.equals(5, b.savedVars().TextToSpeech.TextToSpeechVoice)
	end)

	-- the edit-mode announcement dropdowns capture these tables at login, so an
	-- import that swapped either of them out would leave the panel on an orphan
	it("updates the announcement tables in place rather than replacing them", function()
		local exported = Private.Utils.Export()
		local textToSpeechRef = b.savedVars().TextToSpeech
		local untargetedRef = b.savedVars().TextToSpeech.AnnounceUntargetedSpells

		b.savedVars().TextToSpeech.AnnounceUntargetedSpells[Enum.NpcType.Boss] = false
		assert.is_true(Private.Utils.Import(exported))

		assert.is_true(textToSpeechRef == b.savedVars().TextToSpeech)
		assert.is_true(untargetedRef == b.savedVars().TextToSpeech.AnnounceUntargetedSpells)
		assert.is_true(untargetedRef[Enum.NpcType.Boss])
	end)
end)

describe("Invalid input", function()
	before_each(function()
		b.resetToV4()
	end)

	it("returns false for a garbage string", function()
		assert.is_false(Private.Utils.Import("not valid base64 or cbor !!!"))
	end)

	it("returns false for an empty string", function()
		assert.is_false(Private.Utils.Import(""))
	end)

	it("returns false for a payload that is neither a v4 nor a v3 profile", function()
		assert.is_false(Private.Utils.Import(b.encode({ NotAProfile = true })))
	end)
end)
