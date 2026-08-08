---@diagnostic disable: undefined-global, undefined-field

local b = require("spec.bootstrap")
local Private = b.Private
local Enum = Private.Enum
local Element = Enum.Element
local Template = Enum.Template
local TargetClass = Enum.TargetClass
local BarColorMode = Enum.BarColorMode

local derivePartyFilter = Private.__test.Migration.derivePartyFilter
local foldNpcTypes = Private.__test.Migration.foldNpcTypes
local V3_FLAG = Private.__test.Migration.V3_FLAG
local V3_NPC_TYPE = Private.__test.Migration.V3_NPC_TYPE

describe("derivePartyFilter", function()
	it("no flags: all three target classes", function()
		assert.same(
			{ [TargetClass.Player] = true, [TargetClass.PartyMember] = true, [TargetClass.Nobody] = true },
			derivePartyFilter({})
		)
	end)

	it("SelfOnly removes PartyMember but keeps Nobody (v3 quirk)", function()
		assert.same(
			{ [TargetClass.Player] = true, [TargetClass.Nobody] = true },
			derivePartyFilter({ [V3_FLAG.SelfOnly] = true })
		)
	end)

	it("HideUntargetedSpells removes Nobody", function()
		assert.same(
			{ [TargetClass.Player] = true, [TargetClass.PartyMember] = true },
			derivePartyFilter({ [V3_FLAG.HideUntargetedSpells] = true })
		)
	end)

	it("HideTargetedSpells leaves only Nobody", function()
		assert.same({ [TargetClass.Nobody] = true }, derivePartyFilter({ [V3_FLAG.HideTargetedSpells] = true }))
	end)

	it("SelfOnly + HideUntargeted composes to Player only", function()
		assert.same(
			{ [TargetClass.Player] = true },
			derivePartyFilter({ [V3_FLAG.SelfOnly] = true, [V3_FLAG.HideUntargetedSpells] = true })
		)
	end)
end)

describe("foldNpcTypes", function()
	it("Caster or Melee enabled collapses to Other", function()
		assert.same(
			{ [Enum.NpcType.Boss] = true, [Enum.NpcType.Other] = true },
			foldNpcTypes({ [Enum.NpcType.Boss] = true, [V3_NPC_TYPE.Caster] = true, [V3_NPC_TYPE.Melee] = false })
		)
	end)

	it("both disabled collapses to a disabled Other", function()
		assert.same(
			{ [Enum.NpcType.Other] = false },
			foldNpcTypes({ [V3_NPC_TYPE.Caster] = false, [V3_NPC_TYPE.Melee] = false })
		)
	end)

	it("drops the deprecated ids entirely", function()
		local folded = foldNpcTypes({ [V3_NPC_TYPE.Caster] = true, [V3_NPC_TYPE.Melee] = true })
		assert.is_nil(folded[V3_NPC_TYPE.Caster])
		assert.is_nil(folded[V3_NPC_TYPE.Melee])
	end)

	it("leaves an already-folded table untouched", function()
		assert.same({ [Enum.NpcType.Other] = true }, foldNpcTypes({ [Enum.NpcType.Other] = true }))
		assert.same({ [Enum.NpcType.Other] = false }, foldNpcTypes({ [Enum.NpcType.Other] = false }))
	end)

	it("does not invent a table where there was none", function()
		assert.is_nil(foldNpcTypes(nil))
	end)
end)


describe("sparse and legacy v3 configs", function()
	---@param selfSettings table?
	---@param partySettings table?
	local function migrated(selfSettings, partySettings)
		local saved = {
			-- set, so the party side is read as-is instead of being reset to the v3 defaults
			V3MigrationWarningSeen = true,
			Settings = { Self = selfSettings, Party = partySettings },
		}
		Private.Migration.Apply(saved)

		return saved
	end



	it("survives a missing Settings tree entirely", function()
		local saved = { V3MigrationWarningSeen = true }
		Private.Migration.Apply(saved)

		assert.equals(4, saved.SchemaVersion)
		assert.is_table(saved.Groups[1])
		assert.is_table(saved.Groups[2])
		assert.is_table(saved.TextToSpeech)
	end)



	it("maps the retired Grow = 1 (Center) onto Grow.Start for both groups", function()
		local saved = migrated({ Grow = 1 }, { Grow = 1 })
		assert.equals(Enum.Grow.Start, saved.Groups[1].Grow)
		assert.equals(Enum.Grow.Start, saved.Groups[2].Grow)
	end)

	it("maps the retired GlowType = 3 (ButtonGlow) onto PixelGlow for both groups", function()
		local saved = migrated({ GlowType = 3 }, { GlowType = 3 })
		assert.equals(Enum.GlowType.PixelGlow, saved.Groups[1].GlowType)
		assert.equals(Enum.GlowType.PixelGlow, saved.Groups[2].GlowType)
	end)

	it("leaves a live Grow / GlowType value alone", function()
		local saved = migrated({ Grow = Enum.Grow.End, GlowType = Enum.GlowType.Star4 }, {})
		assert.equals(Enum.Grow.End, saved.Groups[1].Grow)
		assert.equals(Enum.GlowType.Star4, saved.Groups[1].GlowType)
	end)

	it("expands a pre-table boolean AnnounceUntargetedSpells", function()
		local tts = migrated({ AnnounceUntargetedSpells = true }, {}).TextToSpeech
		assert.is_true(tts.AnnounceUntargetedSpells[Enum.NpcType.Boss])
		assert.is_true(tts.AnnounceUntargetedSpells[Enum.NpcType.Lieutenant])
		assert.is_true(tts.AnnounceUntargetedSpells[Enum.NpcType.Other])
		assert.is_false(tts.AnnounceUntargetedSpells[Enum.NpcType.Minion])
	end)

	it("expands a disabled boolean AnnounceUntargetedSpells", function()
		local tts = migrated({ AnnounceUntargetedSpells = false }, {}).TextToSpeech
		assert.is_false(tts.AnnounceUntargetedSpells[Enum.NpcType.Boss])
		assert.is_false(tts.AnnounceUntargetedSpells[Enum.NpcType.Minion])
	end)
end)

describe("pre-v3 party settings", function()
	it("drops the legacy warning flag from the saved table", function()
		local saved = { V3MigrationWarningSeen = true }
		Private.Migration.Apply(saved)
		assert.is_nil(saved.V3MigrationWarningSeen)
	end)
end)

describe("Import accepts v3 and v4 profile strings", function()
	before_each(function()
		b.resetToV4()
	end)

	it("round-trips a v4 export against a v4 config (no change)", function()
		assert.is_false(Private.Utils.Import(Private.Utils.Export()))
	end)

	it("a v4 string restores a changed v4 group", function()
		local exported = Private.Utils.Export()
		b.savedVars().Groups[1].Gap = 999
		assert.is_true(Private.Utils.Import(exported))
		assert.equals(2, b.savedVars().Groups[1].Gap)
	end)
end)
