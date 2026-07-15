---@diagnostic disable: undefined-global, undefined-field

local b = require("spec.bootstrap")
local Private = b.Private
local Enum = Private.Enum
local Element = Enum.Element
local Template = Enum.Template
local TargetClass = Enum.TargetClass
local BarColorMode = Enum.BarColorMode

local snapshot = require("spec.fixtures.bar_geometry_snapshot")
local reconstruct = Private.__test.Migration.reconstructBarGeometry
local derivePartyFilter = Private.__test.Migration.derivePartyFilter
local V3_FLAG = Private.__test.Migration.V3_FLAG

-- same flag order + default size the fixture was generated with
local flagOrder = {
	"showIcon",
	"showTargetMarker",
	"showDuration",
	"inlineDuration",
	"mirrored",
	"showSpellName",
	"showTargetName",
}

local function comboOpts(combo)
	local opts = { width = 300, height = 30, fontSize = 14 }
	local key = {}
	for index, name in ipairs(flagOrder) do
		local bit = math.floor(combo / (2 ^ (7 - index))) % 2
		opts[name] = (bit == 1)
		key[index] = tostring(bit)
	end
	return opts, table.concat(key)
end

describe("bar-offset reconstruction", function()
	it("matches the committed snapshot across every flag combination", function()
		for combo = 0, 127 do
			local opts, key = comboOpts(combo)
			local geometry = reconstruct(opts)
			assert.is_true(
				Private.Utils.DeepEqual(geometry, snapshot[key]),
				"geometry drift at flag combo " .. key
			)
		end
	end)

	it("insets the non-text boxes exactly like v3 (icon + inline duration)", function()
		-- default party layout: icon on, target marker off, duration inline
		local geometry = reconstruct({
			width = 300,
			height = 30,
			fontSize = 14,
			showIcon = true,
			showTargetMarker = false,
			showDuration = true,
			inlineDuration = true,
			mirrored = false,
			showSpellName = true,
			showTargetName = true,
		})
		-- progress bar loses the icon's 30px; inline duration does not inset it
		assert.equals(270, geometry[Element.ProgressBar].width)
		assert.equals(0, geometry[Element.ProgressBar].x)
		-- icon centered in the leftmost 30px: center -150 relative to the bar center
		assert.equals(-150, geometry[Element.Icon].x)
		assert.equals(30, geometry[Element.Icon].width)
	end)

	it("mirror flips every non-text box x offset", function()
		local base = {
			width = 300,
			height = 30,
			fontSize = 14,
			showIcon = true,
			showTargetMarker = true,
			showDuration = true,
			inlineDuration = false,
			showSpellName = false,
			showTargetName = false,
		}
		base.mirrored = false
		local normal = reconstruct(base)
		base.mirrored = true
		local mirrored = reconstruct(base)

		for _, element in ipairs({ Element.Icon, Element.TargetMarker, Element.DurationCooldown }) do
			assert.equals(-normal[element].x, mirrored[element].x)
			assert.equals(normal[element].width, mirrored[element].width)
		end
	end)
end)

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
		assert.equals(3, saved.NextGroupId)
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

	it("Party settings become a Bar group with reconstructed geometry", function()
		local group = migratedDefaults().Groups[2]
		assert.equals(Template.Bar, group.Template)
		assert.equals(Enum.Direction.Vertical, group.Direction)
		-- default party has icon + inline duration -> core bar is 270 wide
		assert.equals(270, group.Elements[Element.ProgressBar].width)
		assert.equals(BarColorMode.Interruptibility, group.Elements[Element.ProgressBar].barColorMode)
		assert.is_true(group.Elements[Element.Icon].active)
		assert.is_false(group.Elements[Element.TargetMarker].active)
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
