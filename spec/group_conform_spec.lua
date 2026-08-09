---@diagnostic disable: undefined-global, undefined-field

-- Contract for Private.Groups.Conform — the single load-time owner of group shape.
-- It re-stamps the derived Id, fills missing container fields, and backfills element
-- fields, healing presence only (nil → default) without ever overwriting a value that
-- is already there.

local b = require("spec.bootstrap")
local Private = b.Private
local Enum = Private.Enum
local Template = Enum.Template
local TargetClass = Enum.TargetClass

-- Smallest identifiable partial group: a template (so Direction/Elements resolve) with
-- everything else absent, keyed at 1. Conform must complete it.
local function partial(overrides)
	local group = { Template = Template.Icon }

	if overrides then
		for key, value in pairs(overrides) do
			group[key] = value
		end
	end

	return { [1] = group }
end

describe("Groups.Conform", function()
	it("is a no-op on an already-complete group", function()
		local _, group = Private.Groups.Create(Template.Bar, { Groups = {}, NextGroupId = 1 })
		local before = Private.Utils.DeepCopy(group)

		Private.Groups.Conform({ [group.Id] = group })

		assert.same(before, group)
	end)

	it("fills a missing Grow with the default", function()
		local groups = partial()
		Private.Groups.Conform(groups)
		assert.equals(Enum.Grow.Start, groups[1].Grow)
	end)

	-- A missing Filter is seeded per template rather than "everything": each template has a
	-- job, and a new group that shows every cast in the pull is noise the user has to narrow
	-- by hand. Conform still only fills a Filter that is absent — a saved one is never
	-- rewritten, so these defaults reach existing groups only if they never had a Filter.
	it("seeds a missing Filter to the player for the icon templates", function()
		local icon = partial()
		Private.Groups.Conform(icon)
		assert.same({ [TargetClass.Player] = true }, icon[1].Filter)

		local iconDuration = { [1] = { Template = Template.IconDuration } }
		Private.Groups.Conform(iconDuration)
		assert.same({ [TargetClass.Player] = true }, iconDuration[1].Filter)
	end)

	it("seeds a missing Filter to untargeted casts for the bar template", function()
		local groups = { [1] = { Template = Template.Bar } }
		Private.Groups.Conform(groups)

		assert.same({ [TargetClass.Nobody] = true }, groups[1].Filter)
	end)

	it("fills both missing LoadCondition tables", function()
		local groups = partial()
		Private.Groups.Conform(groups)

		assert.same({
			[Enum.ContentType.OpenWorld] = false,
			[Enum.ContentType.Delve] = true,
			[Enum.ContentType.Dungeon] = true,
			[Enum.ContentType.Raid] = false,
			[Enum.ContentType.Arena] = true,
			[Enum.ContentType.Battleground] = false,
		}, groups[1].LoadConditionContentType)

		assert.same({
			[Enum.Role.Healer] = true,
			[Enum.Role.Tank] = true,
			[Enum.Role.Damager] = true,
		}, groups[1].LoadConditionRole)
	end)

	it("does not overwrite a present non-default enum", function()
		local groups = partial({ Grow = Enum.Grow.End })
		Private.Groups.Conform(groups)
		assert.equals(Enum.Grow.End, groups[1].Grow)
	end)

	it("does not flip a meaningful Enabled = false (false is not missing)", function()
		local groups = partial({ Enabled = false })
		Private.Groups.Conform(groups)
		assert.is_false(groups[1].Enabled)
	end)

	it("re-stamps Id from the map key even when it disagrees", function()
		local groups = partial({ Id = 99 })
		Private.Groups.Conform(groups)
		assert.equals(1, groups[1].Id)
	end)

	it("defaults Direction per template: Bar/IconDuration → Vertical, Icon → Horizontal", function()
		local bar = { [1] = { Template = Template.Bar } }
		Private.Groups.Conform(bar)
		assert.equals(Enum.Direction.Vertical, bar[1].Direction)

		local icon = { [1] = { Template = Template.Icon } }
		Private.Groups.Conform(icon)
		assert.equals(Enum.Direction.Horizontal, icon[1].Direction)

		local iconDuration = { [1] = { Template = Template.IconDuration } }
		Private.Groups.Conform(iconDuration)
		assert.equals(Enum.Direction.Vertical, iconDuration[1].Direction)
	end)

	it("backfills a full icon+duration element set", function()
		local groups = { [1] = { Template = Template.IconDuration } }
		Private.Groups.Conform(groups)

		local elements = groups[1].Elements
		assert.is_not_nil(elements[Enum.Element.Icon].width)
		assert.is_not_nil(elements[Enum.Element.Icon].iconZoom)
		assert.is_not_nil(elements[Enum.Element.Duration].gap)
		assert.is_not_nil(elements[Enum.Element.Duration].fractionThreshold)
		assert.is_not_nil(elements[Enum.Element.Border].borderTexture)

		-- the icons stay plain by default: the duration text is what shows the remaining cast
		assert.is_false(elements[Enum.Element.Cooldown].showSwipe)
		assert.is_false(elements[Enum.Element.Cooldown].showCountdown)

		-- this template has no interrupter-name element
		assert.is_nil(elements[Enum.Element.InterruptSource])
	end)

	it("still backfills Elements", function()
		local groups = partial()
		Private.Groups.Conform(groups)
		assert.is_table(groups[1].Elements[Enum.Element.Icon])
		assert.is_not_nil(groups[1].Elements[Enum.Element.Icon].width)
	end)

	it("is idempotent", function()
		local groups = partial()
		Private.Groups.Conform(groups)
		local once = Private.Utils.DeepCopy(groups[1])
		Private.Groups.Conform(groups)
		assert.same(once, groups[1])
	end)
end)
