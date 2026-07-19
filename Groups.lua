---@type string, TargetedSpells
local addonName, Private = ...

-- Groups.lua ──────────────────────────────────────────────────────────────────
-- Group-filter matching + group lifecycle (create / delete / template swap).
-- Groups are independent: a cast is offered to every group whose multi-select
-- Filter matches, and may render in several at once. No priority, no arbitration,
-- no enforced-disjoint filters — overlap is intended.
--
-- Public surface:
--   Private.Groups.GetMatching(info, groups) -> array of matching groups
--   Private.Groups.Create(template, saved)   -> id, group   (fresh id, seeded)
--   Private.Groups.Delete(id, saved)         -> boolean      (refuses the last)
--   Private.Groups.SetTemplate(group, template)              (reseeds Elements)
--   Private.Groups.Count(saved)              -> number
-- Helpers stay file-local.

---@class TargetedSpellsGroups
Private.Groups = {}

-- Ascending group-id order is needed on every cast (GetMatching) and by the
-- Designer's tab strip, but the id set changes only on create / delete / import.
-- Cache the sorted array per groups-map so the steady-state cast path does no
-- sort or table allocation; rebuild only when the set changes. The cache is
-- weak-keyed on the groups map, so a dropped map (e.g. a spec's throwaway table,
-- or the pre-migration table replaced wholesale) GCs its entry away on its own.
---@type table<table, integer[]>
local sortedIdCache = setmetatable({}, { __mode = "k" })

-- Ascending list of the ids present in `groups`. The returned array is shared and
-- cached — callers must treat it as read-only and must not hold it across a
-- create/delete/import (which invalidate it).
---@param groups table
---@return integer[]
function Private.Groups.SortedIds(groups)
	local cached = sortedIdCache[groups]

	if cached then
		return cached
	end

	local ids = {}
	for id in pairs(groups) do
		ids[#ids + 1] = id
	end

	table.sort(ids)

	sortedIdCache[groups] = ids

	return ids
end

-- Drops the cached order for a groups map. Must be called after any mutation that
-- adds or removes an id (create / delete / in-place import); pure field edits
-- (rename, layout changes) keep the id set and need no invalidation.
---@param groups table
function Private.Groups.InvalidateOrder(groups)
	sortedIdCache[groups] = nil
end

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

	-- deterministic order so overlapping matches are stable across calls (cached;
	-- rebuilt only when the group set changes — see SortedIds)
	for _, id in ipairs(Private.Groups.SortedIds(groups)) do
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

local function savedOrGlobal(saved)
	return saved or TargetedSpellsSaved
end

-- Number of groups. Used to guard against deleting the last one.
---@param saved table?
---@return number
function Private.Groups.Count(saved)
	local count = 0
	for _ in pairs(savedOrGlobal(saved).Groups) do
		count = count + 1
	end
	return count
end

-- Container-level defaults for a brand-new group (element layout comes from the
-- template's built-in defaults). Kept here — not in the v3 Settings defaults —
-- because a new v4 group has no v3 ancestor.
---@param id integer
---@param template TargetedSpellsTemplate
---@param name string
local function buildDefaultGroup(id, template, name)
	return {
		Id = id,
		Name = name,
		Enabled = true,
		-- a fresh group sees every cast until the user narrows the filter
		Filter = {
			[Private.Enum.TargetClass.Player] = true,
			[Private.Enum.TargetClass.PartyMember] = true,
			[Private.Enum.TargetClass.Nobody] = true,
		},
		Template = template,
		Elements = Private.Design.GetDefault(template),
		Position = { point = "CENTER", x = 0, y = 0 },
		Gap = 2,
		Grow = Private.Enum.Grow.Start,
		Direction = Private.Enum.Direction.Horizontal,
		SortOrder = Private.Enum.SortOrder.Ascending,
		LoadConditionContentType = {
			[Private.Enum.ContentType.OpenWorld] = false,
			[Private.Enum.ContentType.Delve] = true,
			[Private.Enum.ContentType.Dungeon] = true,
			[Private.Enum.ContentType.Raid] = false,
			[Private.Enum.ContentType.Arena] = true,
			[Private.Enum.ContentType.Battleground] = false,
		},
		LoadConditionRole = {
			[Private.Enum.Role.Healer] = true,
			[Private.Enum.Role.Tank] = true,
			[Private.Enum.Role.Damager] = true,
		},
		GlowType = Private.Enum.GlowType.PixelGlow,
		GlowImportant = true,
		OnlyImportant = false,
		IndicateInterrupts = false,
	}
end

-- A friendly default name: the lowest "Group N" not already taken. Names are not
-- identity (ids are), but naming off the raw NextGroupId produces an ugly label like
-- "Group 10" once groups have been created and deleted in a session, since ids are
-- never reused. Picking the smallest free N keeps the label sequential and fills gaps
-- left by deletions.
---@param saved table
---@return string
local function nextGroupName(saved)
	local taken = {}
	for _, group in pairs(saved.Groups) do
		if group.Name then
			taken[group.Name] = true
		end
	end

	local n = 1
	while taken["Group " .. n] do
		n = n + 1
	end

	return "Group " .. n
end

-- Creates a group of `template`, seeded from the built-in element defaults, with a
-- freshly allocated id (persisted in NextGroupId so ids are never reused) and a
-- sequential "Group N" display name (independent of the id — see nextGroupName).
---@param template TargetedSpellsTemplate
---@param saved table?
---@return integer id, TargetedSpellsGroup group
function Private.Groups.Create(template, saved)
	saved = savedOrGlobal(saved)

	local id = saved.NextGroupId or 1
	saved.NextGroupId = id + 1

	local group = buildDefaultGroup(id, template, nextGroupName(saved))
	saved.Groups[id] = group
	Private.Groups.InvalidateOrder(saved.Groups)

	return id, group
end

-- Deletes a group by id. Refuses to remove the last remaining group (there must
-- always be at least one) — any other group, including the two migrated Self/Party
-- slots, is freely deletable. The transitional v3 surfaces that read Groups[1]/[2]
-- tolerate a missing slot rather than pinning them. Returns whether it deleted anything.
---@param id integer
---@param saved table?
---@return boolean
function Private.Groups.Delete(id, saved)
	saved = savedOrGlobal(saved)

	if saved.Groups[id] == nil or Private.Groups.Count(saved) <= 1 then
		return false
	end

	saved.Groups[id] = nil
	Private.Groups.InvalidateOrder(saved.Groups)
	return true
end

-- Swaps a group's template and reseeds its Elements from the new template's
-- built-in defaults (the old template's element values can't map onto a different
-- element set). No-op if the template is unchanged.
---@param group TargetedSpellsGroup
---@param template TargetedSpellsTemplate
function Private.Groups.SetTemplate(group, template)
	if group.Template == template then
		return
	end

	group.Template = template
	group.Elements = Private.Design.GetDefault(template)
end
