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

	local matching = table.wipe(out or {})
	local targetClasses = info and info.targetClasses
	if not groups or not targetClasses then
		return matching
	end

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

local DEFAULT_DIRECTION = {
	[Private.Enum.Template.Bar] = Private.Enum.Direction.Vertical,
	[Private.Enum.Template.IconDuration] = Private.Enum.Direction.Vertical,
}

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

---@param id integer
---@param template TargetedSpellsTemplate
---@param name string
local function BuildDefaultGroup(id, template, name)
	local group = ContainerDefaults(id, template, name)
	group.Elements = Private.Design.GetDefault(template)

	return group
end

---@param group TargetedSpellsGroup
local function ApplyContainerDefaults(group)
	local defaults = ContainerDefaults(group.Id, group.Template, group.Name or ("Group " .. tostring(group.Id)))

	for key, value in pairs(defaults) do
		if group[key] == nil then
			group[key] = value
		end
	end
end

---@param groups table<integer, TargetedSpellsGroup>
function Private.Groups.Conform(groups)
	for id, group in pairs(groups) do
		group.Id = id
		ApplyContainerDefaults(group)
		Private.Design.BackfillElements(group)
	end
end

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
