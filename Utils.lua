---@type string, TargetedSpells
local addonName, Private = ...

Private.Utils = {}

function Private.Utils.FlipCoin()
	return math.random(1, 10) >= 5
end

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

	function Private.Utils.AttemptToPlaySound(sound, channel)
		if handle ~= nil then
			StopSound(handle)
			handle = nil
		end

		local isFile = Private.Settings.SoundIsFile(sound)

		if not isFile and type(sound) == "number" then
			handle = select(3, pcall(PlaySound, sound, channel, false))
		else
			handle = select(3, pcall(PlaySoundFile, sound, channel))
		end
	end
end
