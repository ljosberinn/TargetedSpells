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
local function buildDefaultGroup(id, template)
	return {
		Id = id,
		Name = "Group " .. id,
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
		MaxItems = 10,
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

-- Creates a group of `template`, seeded from the built-in element defaults, with a
-- freshly allocated id (persisted in NextGroupId so ids are never reused).
---@param template TargetedSpellsTemplate
---@param saved table?
---@return integer id, TargetedSpellsGroup group
function Private.Groups.Create(template, saved)
	saved = savedOrGlobal(saved)

	local id = saved.NextGroupId or 1
	saved.NextGroupId = id + 1

	local group = buildDefaultGroup(id, template)
	saved.Groups[id] = group

	return id, group
end

-- Deletes a group by id. Refuses to remove the last remaining group (there must
-- always be at least one). Returns whether it deleted anything.
---@param id integer
---@param saved table?
---@return boolean
function Private.Groups.Delete(id, saved)
	saved = savedOrGlobal(saved)

	if saved.Groups[id] == nil or Private.Groups.Count(saved) <= 1 then
		return false
	end

	saved.Groups[id] = nil
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
