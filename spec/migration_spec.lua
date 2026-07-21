---@diagnostic disable: undefined-global, undefined-field

local b = require("spec.bootstrap")
local Private = b.Private
local Enum = Private.Enum
local Element = Enum.Element
local Template = Enum.Template
local TargetClass = Enum.TargetClass
local BarColorMode = Enum.BarColorMode

local derivePartyFilter = Private.__test.Migration.derivePartyFilter
local V3_FLAG = Private.__test.Migration.V3_FLAG

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

describe("v3 -> v4 transform", function()
	local function migratedDefaults()
		local saved = {
			Settings = {
				Self = Private.Settings.GetSelfDefaultSettings(),
				Party = Private.Settings.GetPartyDefaultSettings(),
			},
		}
		Private.Migration.Apply(saved)
		return saved
	end

	it("produces the v4 container and drops Settings", function()
		local saved = migratedDefaults()
		assert.equals(4, saved.SchemaVersion)
		-- ids are allocated at runtime (Groups.Create), never persisted
		assert.is_nil(saved.NextGroupId)
		assert.is_nil(saved.Settings)
		assert.is_table(saved.Groups)
		assert.is_table(saved.TextToSpeech)
	end)

	it("Self settings become an Icon group filtered on the player", function()
		local group = migratedDefaults().Groups[1]
		assert.equals(Template.Icon, group.Template)
		assert.same({ [TargetClass.Player] = true }, group.Filter)
		assert.is_string(group.Name)
		assert.equals(48, group.Elements[Element.Icon].width)
		assert.equals(1, group.Elements[Element.Icon].iconZoom)
		-- the core element is the 0,0 origin; it carries no x/y offset
		assert.is_nil(group.Elements[Element.Icon].x)
	end)

	it("Party settings become a Bar group keeping the v4 template layout", function()
		local group = migratedDefaults().Groups[2]
		local barDefaults = Private.Design.GetDefault(Template.Bar)
		assert.equals(Template.Bar, group.Template)
		assert.equals(Enum.Direction.Vertical, group.Direction)
		-- bar geometry is NOT migrated: it stays at the v4 template default (see
		-- buildBarElements), so the old free per-element layout can't spread it apart.
		assert.equals(barDefaults[Element.ProgressBar].width, group.Elements[Element.ProgressBar].width)
		assert.equals(barDefaults[Element.SpellName].x, group.Elements[Element.SpellName].x)
		assert.equals(barDefaults[Element.TargetName].x, group.Elements[Element.TargetName].x)
		-- appearance + active toggles still carry over
		assert.equals(BarColorMode.Interruptibility, group.Elements[Element.ProgressBar].barColorMode)
		assert.is_true(group.Elements[Element.Icon].active)
		assert.is_false(group.Elements[Element.TargetMarker].active)
	end)

	it("preserves the party group's edit-mode Position through migration", function()
		local saved = {
			Settings = {
				Self = Private.Settings.GetSelfDefaultSettings(),
				Party = Private.Settings.GetPartyDefaultSettings(),
			},
		}
		saved.Settings.Party.Position = { point = "CENTER", x = 123, y = -456 }
		Private.Migration.Apply(saved)
		assert.same({ point = "CENTER", x = 123, y = -456 }, saved.Groups[2].Position)
	end)

	it("maps the party color settings onto the ProgressBar element", function()
		local progressBar = migratedDefaults().Groups[2].Elements[Element.ProgressBar]
		assert.equals("FFFFFF00", progressBar.progressBarColor)
		assert.equals("FF44FF44", progressBar.interruptibleColor)
		assert.equals("FFFF4444", progressBar.uninterruptibleColor)
		assert.equals("Blizzard Raid Bar", progressBar.barTexture)
	end)

	it("hoists TTS from the Self copy to a single global table", function()
		local tts = migratedDefaults().TextToSpeech
		assert.is_true(tts.AnnounceUntargetedSpells[Enum.NpcType.Boss])
		assert.is_false(tts.AnnounceTargetedSpells[Enum.NpcType.Boss])
		assert.equals(-1, tts.TextToSpeechVoice)
	end)

	it("is idempotent: re-applying a v4 saved changes nothing", function()
		local saved = migratedDefaults()
		local before = Private.Utils.DeepCopy(saved)
		Private.Migration.Apply(saved)
		assert.is_true(Private.Utils.DeepEqual(before, saved))
	end)

	it("a migrated Self/Party slot is freely deletable (only the last group is protected)", function()
		local saved = migratedDefaults()

		-- Deleting the Self slot (id 1) is allowed while the Party slot remains.
		assert.is_true(Private.Groups.Delete(1, saved))
		assert.is_nil(saved.Groups[1])
		assert.is_not_nil(saved.Groups[2])

		-- The one surviving group is now the last, so it cannot be deleted.
		assert.is_false(Private.Groups.Delete(2, saved))
	end)
end)

describe("Import accepts v3 and v4 profile strings", function()
	before_each(function()
		b.reset()
	end)

	it("still round-trips a v3 string against a v3 config (no change)", function()
		assert.is_false(Private.Utils.Import(Private.Utils.Export()))
	end)

	it("round-trips a v4 export against a migrated v4 config (no change)", function()
		Private.Migration.Apply(b.savedVars())
		assert.is_false(Private.Utils.Import(Private.Utils.Export()))
	end)

	it("a v4 string restores a changed v4 group", function()
		Private.Migration.Apply(b.savedVars())
		local exported = Private.Utils.Export()
		b.savedVars().Groups[1].Gap = 999
		assert.is_true(Private.Utils.Import(exported))
		assert.equals(2, b.savedVars().Groups[1].Gap)
	end)

	it("a v3 string imported into a v4 config is migrated and applied", function()
		-- capture a v3 profile, then upgrade the live config to v4
		local v3String = Private.Utils.Export()
		Private.Migration.Apply(b.savedVars())

		-- same config -> importing the v3 string changes nothing
		assert.is_false(Private.Utils.Import(v3String))

		-- mutate, then the v3 string restores the migrated value
		b.savedVars().Groups[2].Gap = 777
		assert.is_true(Private.Utils.Import(v3String))
		assert.equals(2, b.savedVars().Groups[2].Gap)
	end)
end)

describe("fresh-install seed", function()
	local function seeded()
		local saved = {}
		Private.Migration.SeedFreshInstall(saved)
		return saved
	end

	it("stamps the current schema, two groups, and TextToSpeech", function()
		local saved = seeded()
		assert.equals(4, saved.SchemaVersion)
		-- ids are allocated at runtime (Groups.Create), never persisted
		assert.is_nil(saved.NextGroupId)
		assert.is_table(saved.TextToSpeech)
		assert.equals(Template.Icon, saved.Groups[1].Template)
		assert.equals(Template.Bar, saved.Groups[2].Template)
	end)

	it("names and filters the starter groups as designed", function()
		local saved = seeded()
		assert.equals("Self - Icon", saved.Groups[1].Name)
		assert.same({ [TargetClass.Player] = true }, saved.Groups[1].Filter)
		assert.equals("Untargeted AoE - Bar", saved.Groups[2].Name)
		assert.same({ [TargetClass.Nobody] = true }, saved.Groups[2].Filter)
	end)

	it("seeds bar elements from the v4 schema defaults, not the v3 reconstruction", function()
		-- the reported bug: a freshly seeded bar must equal what "Reset Element" gives
		-- (Design.GetDefault), so the SpellName offset matches the schema, not x≈70.
		local barElements = seeded().Groups[2].Elements
		local defaults = Private.Design.GetDefault(Template.Bar)
		assert.equals(defaults[Element.SpellName].x, barElements[Element.SpellName].x)
		assert.equals(defaults[Element.TargetName].x, barElements[Element.TargetName].x)
		assert.equals(defaults[Element.SpellName].maxWidth, barElements[Element.SpellName].maxWidth)
	end)

	it("bars default to vertical grow direction", function()
		assert.equals(Enum.Direction.Vertical, seeded().Groups[2].Direction)
	end)

	it("leaves Migration.Apply a no-op (already at the current version)", function()
		local saved = seeded()
		local spellNameX = saved.Groups[2].Elements[Element.SpellName].x
		Private.Migration.Apply(saved)
		assert.equals(4, saved.SchemaVersion) -- unchanged: no migration step ran
		assert.equals(spellNameX, saved.Groups[2].Elements[Element.SpellName].x)
	end)
end)
