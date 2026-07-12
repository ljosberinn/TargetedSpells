---@type string, TargetedSpells
local addonName, Private = ...

-- Groups.lua ──────────────────────────────────────────────────────────────────
-- Group-filter matching. Groups are independent: a cast is offered to every
-- group whose multi-select Filter matches, and may render in several at once.
-- No priority, no arbitration, no enforced-disjoint filters — overlap is intended.
--
-- Public surface:
--   Private.Groups.GetMatching(info, groups) -> array of matching groups
-- Helpers stay file-local.

local Enum = Private.Enum

---@class TargetedSpellsGroups
Private.Groups = {}

-- Returns every enabled group whose Filter overlaps the cast's target classes,
-- in ascending group-id order. One cast can feed several groups; each match is a
-- separate frame downstream. No arbitration when filters overlap.
--
-- `info.targetClasses` is a set `{ [Enum.TargetClass.X] = true }` of the classes
-- the cast satisfies (the caller classifies the cast). `groups` defaults to the
-- live SavedVariables map; specs pass one explicitly.
---@param info { targetClasses: table<TargetClass, boolean> }
---@param groups table<any, table>?
---@return table[]
function Private.Groups.GetMatching(info, groups)
	groups = groups or (TargetedSpellsSaved and TargetedSpellsSaved.Groups)

	local matching = {}
	local targetClasses = info and info.targetClasses
	if not groups or not targetClasses then
		return matching
	end

	-- deterministic order so overlapping matches are stable across calls
	local ids = {}
	for id in pairs(groups) do
		ids[#ids + 1] = id
	end
	table.sort(ids)

	for _, id in ipairs(ids) do
		local group = groups[id]
		if group and group.Enabled ~= false and group.Filter then
			for targetClass, enabled in pairs(group.Filter) do
				if enabled and targetClasses[targetClass] then
					matching[#matching + 1] = group
					break
				end
			end
		end
	end

	return matching
end
