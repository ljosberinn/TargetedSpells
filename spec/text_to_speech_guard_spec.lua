---@diagnostic disable: undefined-global, undefined-field, missing-fields

-- Murder Row suppresses channel announcements until the first boss is pulled. The state lives
-- on the Driver as `encounterState`, so these specs drive the real event handlers and then ask
-- TextToSpeech whether it would speak, the same way HandleDelayedStart wires the two.

local b = require("spec.bootstrap")
local Private = b.Private

local capturedDriver
_G.GenerateClosure = function(_, boundSelf)
	capturedDriver = boundSelf
	return function() end
end
_G.UIParent = _G.UIParent or {}

local spoken = 0
local activeChallengeMapId = nil

_G.GetTime = function()
	return 0
end
_G.InCombatLockdown = function()
	return true
end
_G.UnitAffectingCombat = function()
	return true
end
_G.UnitSpellTargetName = function()
	return nil
end
_G.UnitClassification = function()
	return "elite"
end
_G.UnitIsMinion = function()
	return false
end
_G.UnitIsLieutenant = function()
	return false
end
_G.UnitIsBossMob = function()
	return false
end
_G.UnitLevel = function()
	return 90
end
_G.C_Spell = {
	GetSpellName = function()
		return "Spell"
	end,
}
_G.C_TTSSettings = {
	GetVoiceOptionID = function()
		return 0
	end,
	GetSpeechVolume = function()
		return 100
	end,
}
_G.C_VoiceChat = {
	SpeakText = function()
		spoken = spoken + 1
	end,
}
_G.Enum.TtsVoiceType = { Standard = 0 }
_G.C_ChallengeMode = {
	GetActiveChallengeMapID = function()
		return activeChallengeMapId
	end,
}
_G.GetInstanceInfo = function()
	return nil, "party", 8
end
_G.DifficultyUtil = { ID = { DungeonChallenge = 8 } }
_G.PlayerUtil = {
	GetCurrentSpecID = function()
		return 0
	end,
}
_G.GetSpecializationRoleByID = function()
	return "DAMAGER"
end

loadfile("TextToSpeech.lua")("TargetedSpells", Private)
loadfile("Driver.lua")("TargetedSpells", Private)

local murderRow = 587

---@param event string
local function Fire(event, ...)
	capturedDriver:OnFrameEvent(nil, event, ...)
end

---@param isChannel boolean
---@return boolean
local function WouldAnnounce(isChannel)
	local before = spoken

	Private.TextToSpeechUtil.ClearAnnouncementCacheForUnit("nameplate1")
	Private.TextToSpeechUtil.MaybeAnnounceSpell(
		{ unit = "nameplate1", spellId = 1, isChannel = isChannel },
		Private.Enum.ContentType.Dungeon,
		capturedDriver.encounterState
	)

	return spoken > before
end

describe("Murder Row channel announcements", function()
	before_each(function()
		b.resetToV4()
		capturedDriver.unitGroups = {}
		capturedDriver.encounterState = {
			activeEncounterId = nil,
			challengeModeMapId = nil,
			seenEncounterIds = {},
		}
		activeChallengeMapId = nil
	end)

	it("suppresses channels but not casts after the key starts", function()
		activeChallengeMapId = murderRow
		Fire("CHALLENGE_MODE_START", murderRow)

		assert.is_false(WouldAnnounce(true))
		assert.is_true(WouldAnnounce(false))
	end)

	it("announces channels again once the first boss is pulled, including after a wipe", function()
		activeChallengeMapId = murderRow
		Fire("CHALLENGE_MODE_START", murderRow)
		Fire("ENCOUNTER_START", 1)

		assert.is_true(WouldAnnounce(true))

		Fire("ENCOUNTER_END", 1)

		assert.is_true(WouldAnnounce(true))
	end)

	it("does not affect other dungeons", function()
		activeChallengeMapId = 1
		Fire("CHALLENGE_MODE_START", 1)

		assert.is_true(WouldAnnounce(true))
	end)

	it("clears on CHALLENGE_MODE_RESET and re-arms on the next key", function()
		activeChallengeMapId = murderRow
		Fire("CHALLENGE_MODE_START", murderRow)
		Fire("CHALLENGE_MODE_RESET", murderRow)

		assert.is_true(WouldAnnounce(true))

		Fire("CHALLENGE_MODE_START", murderRow)

		assert.is_false(WouldAnnounce(true))
	end)

	it("keeps suppressing across a loading screen inside the run", function()
		activeChallengeMapId = murderRow
		Fire("CHALLENGE_MODE_START", murderRow)
		Fire("LOADING_SCREEN_DISABLED")

		assert.is_false(WouldAnnounce(true))
	end)

	it("clears once a loading screen leaves the run", function()
		activeChallengeMapId = murderRow
		Fire("CHALLENGE_MODE_START", murderRow)
		activeChallengeMapId = nil
		Fire("LOADING_SCREEN_DISABLED")

		assert.is_nil(capturedDriver.encounterState.challengeModeMapId)
		assert.is_nil(next(capturedDriver.encounterState.seenEncounterIds))
		assert.is_true(WouldAnnounce(true))
	end)

	it("forgets encounters seen in the previous run when the next key starts", function()
		activeChallengeMapId = murderRow
		Fire("CHALLENGE_MODE_START", murderRow)
		Fire("ENCOUNTER_START", 1)
		Fire("ENCOUNTER_END", 1)
		Fire("CHALLENGE_MODE_START", murderRow)

		assert.is_false(WouldAnnounce(true))
	end)

	it("only records encounters during a run", function()
		Fire("ENCOUNTER_START", 1)
		Fire("ENCOUNTER_END", 1)

		assert.is_nil(next(capturedDriver.encounterState.seenEncounterIds))
	end)

	it("fails open when CHALLENGE_MODE_START was never observed, as after a reload", function()
		activeChallengeMapId = murderRow
		Fire("LOADING_SCREEN_DISABLED")

		assert.is_true(WouldAnnounce(true))
	end)
end)
