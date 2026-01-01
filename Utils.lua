---@type string, TargetedSpells
local addonName, Private = ...

---@class TargetedSpellsUtils
Private.Utils = {}

function Private.Utils.CalculateCoordinate(index, dimension, gap, parentDimension, total, offset, grow)
	if grow == Private.Enum.Grow.Start then
		return (index - 1) * (dimension + gap) - parentDimension / 2 + offset
	elseif grow == Private.Enum.Grow.Center then
		return (index - 1) * (dimension + gap) - total / 2 + offset
	elseif grow == Private.Enum.Grow.End then
		return parentDimension / 2 - index * (dimension + gap) + offset
	end

	return 0
end

function Private.Utils.SortFrames(frames, sortOrder)
	local isAscending = sortOrder == Private.Enum.SortOrder.Ascending

	table.sort(frames, function(a, b)
		if isAscending then
			return a:GetStartTime() < b:GetStartTime()
		end

		return a:GetStartTime() > b:GetStartTime()
	end)
end

do
	local handle = nil
	local channels = tInvert(Private.Enum.SoundChannel)

	function Private.Utils.AttemptToPlaySound(sound, channel)
		if handle ~= nil then
			StopSound(handle)
			handle = nil
		end

		local channelToUse = channels[channel]
		local isFile = Private.Settings.SoundIsFile(sound)

		if not isFile and type(sound) == "number" then
			handle = select(3, pcall(PlaySound, sound, channelToUse, false))
		else
			handle = select(3, pcall(PlaySoundFile, sound, channelToUse))
		end
	end
end

function Private.Utils.RollDice()
	return math.random(1, 6) == 6
end

function Private.Utils.FindAppropriateTTSVoiceId()
	local locale = GAME_LOCALE or GetLocale()

	local ttsVoiceId = C_TTSSettings.GetVoiceOptionID(Enum.TtsVoiceType.Standard)
	local patternToLookFor = nil

	if locale == "deDE" then
		patternToLookFor = "German"
	elseif locale == "enUS" or locale == "enGB" then
		patternToLookFor = "English"
	end

	if patternToLookFor ~= nil then
		for _, voice in pairs(C_VoiceChat.GetTtsVoices()) do
			if string.find(voice.name, patternToLookFor) ~= nil then
				return voice.voiceID
			end
		end
	end

	return ttsVoiceId
end

function Private.Utils.PlayTTS(text, voiceId, rate)
	rate = rate or 2
	voiceId = voiceId or TargetedSpellsSaved.Settings.Self.TTSVoice

	if Private.IsMidnight then
		C_VoiceChat.SpeakText(voiceId, text, rate, C_TTSSettings.GetSpeechVolume())
	else
		C_VoiceChat.SpeakText(
			voiceId,
			text,
			Enum.VoiceTtsDestination.QueuedLocalPlayback,
			rate,
			C_TTSSettings.GetSpeechVolume()
		)
	end
end
