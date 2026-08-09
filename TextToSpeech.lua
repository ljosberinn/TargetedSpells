---@type string, TargetedSpells
local _, Private = ...

---@class TargetedSpellsTextToSpeechUtil
Private.TextToSpeechUtil = {}

---@type table<string, number>
local announcementCache = {}

---@type table<number, fun(unit: string): boolean>
local encounterTtsExecutionGuards = {
	[3333] = function(unit) -- Lothraxion, Nexus-Point Xenas
		if UnitLevel(unit) == -1 then
			local id = string.gsub(unit, "nameplate", "")
			-- ignores casts by a boss unit if the nameplateN id is greater than 1
			return tonumber(id) > 1
		end

		return false
	end,
	[2001] = function(unit) -- Ick and Krick, Pit of Saron
		return UnitLevel(unit) == 91 and UnitIsLieutenant(unit)
	end,
	[2067] = function(unit) -- Viceroy Nezhar, Seat of the Triumvirate
		return UnitLevel(unit) == 90
	end
}

---@param unit string
---@param activeEncounterId number
---@return boolean
local function EncounterPreventsTTSExecution(unit, activeEncounterId)
	local fn = encounterTtsExecutionGuards[activeEncounterId]

	if fn then
		return fn(unit)
	end

	return false
end

---@param unit string
---@return boolean
local function UnitMatchesTTSCriteria(unit)
	local settings = UnitSpellTargetName(unit) == nil and TargetedSpellsSaved.TextToSpeech.AnnounceUntargetedSpells or
		TargetedSpellsSaved.TextToSpeech.AnnounceTargetedSpells
	local classification = UnitClassification(unit)

	if UnitIsMinion(unit) or classification == "normal" or classification == "trivial" or classification == "minus" then
		return settings[Private.Enum.NpcType.Minion]
	end

	if UnitIsLieutenant(unit) or UnitLevel(unit) - 1 == UnitLevel("player") then
		return settings[Private.Enum.NpcType.Lieutenant]
	end

	if UnitIsBossMob(unit) or UnitLevel(unit) - 2 == UnitLevel("player") then
		return settings[Private.Enum.NpcType.Boss]
	end

	return settings[Private.Enum.NpcType.Other]
end

function Private.TextToSpeechUtil.MaybeAnnounceSpell(info, contentType, activeEncounterId)
	if
	-- Suppress open-world announcements outside combat.
		(contentType == Private.Enum.ContentType.OpenWorld and (not InCombatLockdown() or not UnitAffectingCombat(
			info.unit
		)))
		or EncounterPreventsTTSExecution(info.unit, activeEncounterId)
	then
		return
	end

	local now = GetTime()

	if
		announcementCache[info.unit] ~= nil and now - announcementCache[info.unit] < 3
		or not UnitMatchesTTSCriteria(info.unit)
	then
		return
	end

	local spellName = C_Spell.GetSpellName(info.spellId)

	if spellName == nil then
		return
	end

	announcementCache[info.unit] = now

	local configuredVoice = TargetedSpellsSaved.TextToSpeech.TextToSpeechVoice
	local voiceId = configuredVoice ~= nil and configuredVoice > -1 and configuredVoice
		or C_TTSSettings.GetVoiceOptionID(Enum.TtsVoiceType.Standard)

	C_VoiceChat.SpeakText(voiceId, spellName, 2, C_TTSSettings.GetSpeechVolume(), true)
end

function Private.TextToSpeechUtil.ClearAnnouncementCacheForUnit(unit)
	announcementCache[unit] = nil
end
