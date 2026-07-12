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
