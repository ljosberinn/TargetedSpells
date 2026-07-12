---@diagnostic disable: undefined-global, undefined-field

local b = require("spec.bootstrap")
local Private = b.Private
local Enum = Private.Enum
local TargetClass = Enum.TargetClass

-- Builds a groups map keyed by ascending id. Each entry is the minimal shape
-- GetMatching reads: Enabled + Filter.
local function makeGroups()
	return {
		[1] = { Name = "player", Enabled = true, Filter = { [TargetClass.Player] = true } },
		[2] = { Name = "party", Enabled = true, Filter = { [TargetClass.PartyMember] = true } },
		[3] = { Name = "nobody", Enabled = true, Filter = { [TargetClass.Nobody] = true } },
		[4] = { Name = "player+party", Enabled = true, Filter = { [TargetClass.Player] = true, [TargetClass.PartyMember] = true } },
		[5] = { Name = "disabled", Enabled = false, Filter = { [TargetClass.Player] = true } },
	}
end

local function names(matches)
	local result = {}
	for _, group in ipairs(matches) do
		result[#result + 1] = group.Name
	end
	return result
end

describe("Groups.GetMatching", function()
	it("matches a single target class", function()
		local matches = Private.Groups.GetMatching({ targetClasses = { [TargetClass.Nobody] = true } }, makeGroups())
		assert.same({ "nobody" }, names(matches))
	end)

	it("PartyMember single matches the party group and the multi group", function()
		local matches = Private.Groups.GetMatching({ targetClasses = { [TargetClass.PartyMember] = true } }, makeGroups())
		assert.same({ "party", "player+party" }, names(matches))
	end)

	it("overlap: one Player cast feeds several groups", function()
		local matches = Private.Groups.GetMatching({ targetClasses = { [TargetClass.Player] = true } }, makeGroups())
		-- both the Player group and the Player+Party multi group match; disabled is skipped
		assert.same({ "player", "player+party" }, names(matches))
	end)

	it("a cast satisfying two classes matches every group touching either", function()
		local matches = Private.Groups.GetMatching(
			{ targetClasses = { [TargetClass.Player] = true, [TargetClass.PartyMember] = true } },
			makeGroups()
		)
		assert.same({ "player", "party", "player+party" }, names(matches))
	end)

	it("a multi-filter group is returned at most once", function()
		local matches = Private.Groups.GetMatching(
			{ targetClasses = { [TargetClass.Player] = true, [TargetClass.PartyMember] = true } },
			{ [4] = { Name = "player+party", Enabled = true, Filter = { [TargetClass.Player] = true, [TargetClass.PartyMember] = true } } }
		)
		assert.same({ "player+party" }, names(matches))
	end)

	it("disabled groups never match", function()
		local matches = Private.Groups.GetMatching(
			{ targetClasses = { [TargetClass.Player] = true } },
			{ [5] = { Name = "disabled", Enabled = false, Filter = { [TargetClass.Player] = true } } }
		)
		assert.same({}, names(matches))
	end)

	it("returns matches in ascending group-id order", function()
		local groups = {
			[10] = { Name = "ten", Enabled = true, Filter = { [TargetClass.Player] = true } },
			[2] = { Name = "two", Enabled = true, Filter = { [TargetClass.Player] = true } },
			[7] = { Name = "seven", Enabled = true, Filter = { [TargetClass.Player] = true } },
		}
		local matches = Private.Groups.GetMatching({ targetClasses = { [TargetClass.Player] = true } }, groups)
		assert.same({ "two", "seven", "ten" }, names(matches))
	end)

	it("no target classes matches nothing", function()
		assert.same({}, Private.Groups.GetMatching({ targetClasses = {} }, makeGroups()))
		assert.same({}, Private.Groups.GetMatching({}, makeGroups()))
	end)
end)

describe("Groups.Create / Delete / SetTemplate / Count", function()
	local Template = Enum.Template
	local Element = Enum.Element

	local function newSaved()
		return { NextGroupId = 1, Groups = {} }
	end

	it("Create seeds a group from the template defaults with a fresh id", function()
		local saved = newSaved()
		local id, group = Private.Groups.Create(Template.Bar, saved)

		assert.equals(1, id)
		assert.equals(2, saved.NextGroupId)
		assert.equals(group, saved.Groups[1])
		assert.equals(Template.Bar, group.Template)
		assert.equals(1, group.Id)
		assert.is_string(group.Name)
		assert.is_table(group.Elements[Element.ProgressBar])
		-- fresh group sees every target class until narrowed
		assert.is_true(group.Filter[Enum.TargetClass.Player])
		assert.is_true(group.Filter[Enum.TargetClass.Nobody])
	end)

	it("never reuses ids across delete/create", function()
		local saved = newSaved()
		local firstId = Private.Groups.Create(Template.Icon, saved)
		Private.Groups.Create(Template.Icon, saved)
		assert.is_true(Private.Groups.Delete(firstId, saved))
		local reusedId = Private.Groups.Create(Template.Icon, saved)
		assert.equals(3, reusedId)
	end)

	it("Delete refuses to remove the last remaining group", function()
		local saved = newSaved()
		Private.Groups.Create(Template.Icon, saved)
		assert.is_false(Private.Groups.Delete(1, saved))
		assert.is_not_nil(saved.Groups[1])

		Private.Groups.Create(Template.Bar, saved)
		assert.is_true(Private.Groups.Delete(1, saved))
		assert.is_nil(saved.Groups[1])
	end)

	it("SetTemplate swaps template and reseeds Elements", function()
		local saved = newSaved()
		local _, group = Private.Groups.Create(Template.Icon, saved)
		assert.is_table(group.Elements[Element.Border]) -- icon-only element

		Private.Groups.SetTemplate(group, Template.Bar)
		assert.equals(Template.Bar, group.Template)
		assert.is_table(group.Elements[Element.ProgressBar])
		assert.is_nil(group.Elements[Element.Border]) -- gone: bar has no Border
	end)

	it("Count reflects the number of groups", function()
		local saved = newSaved()
		assert.equals(0, Private.Groups.Count(saved))
		Private.Groups.Create(Template.Icon, saved)
		Private.Groups.Create(Template.Bar, saved)
		assert.equals(2, Private.Groups.Count(saved))
	end)
end)
