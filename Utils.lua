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

local PreviewIconDataProvider = nil

---@return IconDataProviderMixin
function Private.Utils.GetRandomIcon()
	if PreviewIconDataProvider == nil then
		PreviewIconDataProvider =
			CreateAndInitFromMixin(IconDataProviderMixin, IconDataProviderExtraType.Spellbook, true)
	end

	if Private.IsMidnight then
		return PreviewIconDataProvider:GetRandomIcon()
	end

	-- backport of GetRandomIcon() from 12.0
	local numIcons = PreviewIconDataProvider:GetNumIcons()
	local avoidQuestionMarkIndex = 2
	return PreviewIconDataProvider:GetIconByIndex(math.random(avoidQuestionMarkIndex, numIcons))
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

function Private.Utils.AttemptToPlaySound(sound, channel)
	local ok, result, handle = nil, nil, nil

	if type(sound) == "number" then
		ok, result, handle = pcall(PlaySound, sound, channel)
	else
		ok, result, handle = pcall(PlaySoundFile, sound, channel)
	end

	return ok, result, handle
end
