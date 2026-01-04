--[[
	file is not loaded by default and removed for public builds

	usage:

	local result = Private.Profile("label", function()
		return 1
	end)

	results will be sorted by avg time desc in chat every 10s and accumulate constantly
]]
--

---@type string, TargetedSpells
local addonName, Private = ...

local datasetsByLabel = {}

function Private.Profile(label, cb)
	local result, rest = C_AddOnProfiler.MeasureCall(cb)

	if datasetsByLabel[label] == nil then
		datasetsByLabel[label] = {}
	end

	table.insert(datasetsByLabel[label], result.elapsedMilliseconds)

	return rest
end

C_Timer.NewTicker(10, function()
	print("---")

	local data = {}
	for label, datasets in pairs(datasetsByLabel) do
		local totalCalls = #datasets
		local sumTime = 0
		local maxTime = 0
		local minTime = 0
		local avgTime = 0

		for _, dataset in ipairs(datasets) do
			sumTime = sumTime + dataset
			maxTime = math.max(maxTime, dataset)
			minTime = math.min(minTime, dataset)
		end

		avgTime = sumTime / totalCalls

		table.insert(data, {
			label = label,
			totalCalls = totalCalls,
			avgTime = avgTime,
			minTime = minTime,
			maxTime = maxTime,
		})
	end

	table.sort(data, function(a, b)
		return a.avgTime > b.avgTime
	end)

	for i, datum in ipairs(data) do
		print(
			string.format(
				"%s: calls %d, avg %.3f, min %.3f, max %.3f",
				datum.label,
				datum.totalCalls,
				datum.avgTime,
				datum.minTime,
				datum.maxTime
			)
		)
	end
end)
