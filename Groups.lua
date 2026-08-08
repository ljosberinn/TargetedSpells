---@type string, TargetedSpells
local _, Private = ...

---@class TargetedSpellsGroups
Private.Groups = {}

---@type table<table, integer[]>
local sortedIdCache = setmetatable({}, { __mode = "k" })

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

---@param groups table
function Private.Groups.InvalidateOrder(groups)
	sortedIdCache[groups] = nil
end

---@param groups table<integer, TargetedSpellsGroup>
---@return TargetedSpellsGroupCapabilities
function Private.Groups.ComputeCapabilities(groups)
	local capabilities = {
		enabled = false,
		usesInterruptibility = false,
		usesShield = false,
		showsTargetMarker = false,
		indicatesInterrupts = false,
	}

	for _, group in pairs(groups) do
		if group.Enabled then
			capabilities.enabled = true

			if group.Template == Private.Enum.Template.Bar then
				local elements = group.Elements
				if elements[Private.Enum.Element.ProgressBar] and elements[Private.Enum.Element.ProgressBar].barColorMode == Private.Enum.BarColorMode.Interruptibility then
					capabilities.usesInterruptibility = true
				end

				if elements[Private.Enum.Element.InterruptShield] and elements[Private.Enum.Element.InterruptShield].active then
					capabilities.usesShield = true
				end

				if elements[Private.Enum.Element.TargetMarker] and elements[Private.Enum.Element.TargetMarker].active then
					capabilities.showsTargetMarker = true
				end
			end
		end

		if group.IndicateInterrupts then
			capabilities.indicatesInterrupts = true
		end
	end

	return capabilities
end

function Private.Groups.GetMatching(info, groups, out)
	groups = groups or (TargetedSpellsSaved and TargetedSpellsSaved.Groups)

	local matching = table.wipe(out)
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

local function SavedOrGlobal(saved)
	return saved or TargetedSpellsSaved
end

function Private.Groups.Count(saved)
	local count = 0

	for _ in pairs(SavedOrGlobal(saved).Groups) do
		count = count + 1
	end

	return count
end

-- Templates whose frames are wider than they are tall stack vertically; anything else
-- defaults to a horizontal row. Absent → Horizontal.
local DEFAULT_DIRECTION = {
	[Private.Enum.Template.Bar] = Private.Enum.Direction.Vertical,
	[Private.Enum.Template.IconDuration] = Private.Enum.Direction.Vertical,
}

-- Which cast targets a new group shows. Absent → all three, the historical default. The
-- icon+duration display is built around a single prominent countdown, so it seeds to the
-- player's own incoming casts rather than every cast in the pull.
---@return table<TargetClass, boolean>
local function DefaultFilter(template)
	if template == Private.Enum.Template.IconDuration then
		return { [Private.Enum.TargetClass.Player] = true }
	end

	if template == Private.Enum.Template.Bar then
		return { [Private.Enum.TargetClass.Nobody] = true }
	end

	return { [Private.Enum.TargetClass.Player] = true }
end

-- Container-level defaults for a group — every field except Elements (the element
-- layout comes from the template schema, see Design). Single source of truth shared by
-- BuildDefaultGroup (a brand-new group) and Conform (healing a saved group missing a
-- field), so a new container field is added in one place and healed automatically.
-- Returns a fresh table with fresh sub-tables on every call, so callers may keep the
-- result without deep-copying. Kept here — not in the v3 Settings defaults — because a
-- new v4 group has no v3 ancestor.
---@param id integer
---@param template TargetedSpellsTemplate
---@param name string
local function ContainerDefaults(id, template, name)
	return {
		Id = id,
		Name = name,
		Enabled = true,
		Filter = DefaultFilter(template),
		Template = template,
		Position = { point = "CENTER", x = 0, y = 0 },
		Gap = 2,
		Grow = Private.Enum.Grow.Start,
		Direction = DEFAULT_DIRECTION[template] or Private.Enum.Direction.Horizontal,
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

-- A brand-new group: container defaults + the template's default element layout.
---@param id integer
---@param template TargetedSpellsTemplate
---@param name string
local function BuildDefaultGroup(id, template, name)
	local group = ContainerDefaults(id, template, name)
	group.Elements = Private.Design.GetDefault(template)

	return group
end

-- Fills any missing container field on `group` from a same-shape default; never
-- overwrites a present value, so a meaningful `false` (Enabled/GlowImportant/…) or a
-- non-default enum survives — the test is `== nil`, not truthiness. Elements are healed
-- separately (Design.BackfillElements). ContainerDefaults is freshly built for this one
-- group, so its sub-tables can be assigned directly without aliasing another group.
---@param group TargetedSpellsGroup
local function ApplyContainerDefaults(group)
	local defaults = ContainerDefaults(group.Id, group.Template, group.Name or ("Group " .. tostring(group.Id)))

	for key, value in pairs(defaults) do
		if group[key] == nil then
			group[key] = value
		end
	end
end

-- Guarantees every saved group is complete and self-consistent, whatever version
-- created it: re-stamps the derived Id from its key, fills any missing container field,
-- and backfills element fields. Idempotent, and the single load-time owner of group
-- shape — heals presence only (nil → default), never validating or overwriting a value
-- that is already there.
---@param groups table<integer, TargetedSpellsGroup>
function Private.Groups.Conform(groups)
	for id, group in pairs(groups) do
		group.Id = id
		ApplyContainerDefaults(group)
		Private.Design.BackfillElements(group)
	end
end

-- Runtime (non-persisted) id allocator. Ids must be unique among currently-live
-- groups AND must not collide with an edit-mode frame that a within-session delete
-- left lingering: LibEditMode has no RemoveFrame, so a deleted group's named frame
-- (TargetedSpellsGroupEditMode<id>) survives until the next reload — see
-- Private.EditMode.DeleteGroup. A per-session high-water mark satisfies both without
-- persisting anything: it only ever climbs within a session, so an id freed this
-- session is never handed back while its frame is still around. Across reloads the
-- lingering frames are gone and the mark reseeds from the highest saved id, so
-- reusing a since-freed top id is safe. Keyed weakly by the config table so the live
-- config and each spec's fixture stay isolated (and are collected with it).
local highWaterByConfig = setmetatable({}, { __mode = "k" })

---@param saved table
---@return integer
local function AllocateId(saved)
	local water = highWaterByConfig[saved] or 0

	for id in pairs(saved.Groups) do
		if id > water then
			water = id
		end
	end

	local id = water + 1
	highWaterByConfig[saved] = id

	return id
end

-- A friendly default name: the lowest "Group N" not already taken. Names are not
-- identity (ids are), but naming off the raw allocated id produces an ugly label like
-- "Group 10" once groups have been created and deleted in a session, since ids only
-- climb. Picking the smallest free N keeps the label sequential and fills gaps left by
-- deletions.
---@param saved table
---@return string
local function NextGroupName(saved)
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
-- freshly allocated id (see AllocateId — a runtime high-water mark, never reused within
-- a session) and a sequential "Group N" display name (independent of the id — see
-- NextGroupName).
---@param template TargetedSpellsTemplate
---@param saved table?
---@return integer id, TargetedSpellsGroup group
function Private.Groups.Create(template, saved)
	saved = SavedOrGlobal(saved)

	local id = AllocateId(saved)

	local group = BuildDefaultGroup(id, template, NextGroupName(saved))
	saved.Groups[id] = group
	Private.Groups.InvalidateOrder(saved.Groups)

	return id, group
end

-- The starter groups seeded on a brand-new install (no SavedVariables yet). Built from
-- the live v4 element defaults (Design.GetDefault, via BuildDefaultGroup) so a fresh
-- bar/icon matches exactly what "Reset Element" produces — unlike the v3→v4 migration,
-- which reconstructs geometry from legacy settings. Ids 1/2 mirror the migration layout
-- (Self icon, then bar), each pre-filtered to its role.
---@return table<integer, TargetedSpellsGroup>
function Private.Groups.CreateStarterGroups()
	local selfGroup = BuildDefaultGroup(1, Private.Enum.Template.Icon, "Self - Icon")
	selfGroup.Filter = { [Private.Enum.TargetClass.Player] = true }

	local barGroup = BuildDefaultGroup(2, Private.Enum.Template.Bar, "Untargeted AoE - Bar")
	barGroup.Filter = { [Private.Enum.TargetClass.Nobody] = true }

	return { [1] = selfGroup, [2] = barGroup }
end

---@param id integer
---@param saved table?
---@return boolean
function Private.Groups.Delete(id, saved)
	saved = SavedOrGlobal(saved)

	if saved.Groups[id] == nil or Private.Groups.Count(saved) <= 1 then
		return false
	end

	saved.Groups[id] = nil
	Private.Groups.InvalidateOrder(saved.Groups)
	return true
end

---@param group TargetedSpellsGroup
---@param template TargetedSpellsTemplate
function Private.Groups.SetTemplate(group, template)
	if group.Template == template then
		return
	end

	group.Template = template
	group.Elements = Private.Design.GetDefault(template)
end
