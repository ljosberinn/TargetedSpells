---@diagnostic disable: undefined-global, undefined-field

-- Exercises the Phase-3 transitional proxy (Settings.CreateGroupView): the flat
-- v3 Settings shape that edit mode reads/writes, backed by the v4 group model.
-- This is the riskiest go-live piece (a bad mapping writes wrong group data), and
-- it is pure Lua, so it is tested directly here.

local b = require("spec.bootstrap")
local Private = b.Private
local Enum = Private.Enum
local Element = Enum.Element
local FeatureFlag = Enum.FeatureFlag
local TargetClass = Enum.TargetClass
local BarColorMode = Enum.BarColorMode

local iconView, barView, iconGroup, barGroup

before_each(function()
	b.reset()
	Private.Migration.Apply(b.savedVars())
	iconGroup = b.savedVars().Groups[1]
	barGroup = b.savedVars().Groups[2]
	iconView = Private.Settings.CreateGroupView(iconGroup)
	barView = Private.Settings.CreateGroupView(barGroup)
end)

describe("CreateGroupView — scalars", function()
	it("reads/writes core Width/Height through the core element", function()
		assert.equals(48, iconView.Width)
		iconView.Width = 60
		assert.equals(60, iconGroup.Elements[Element.Icon].width)

		-- the migrated bar core is the reconstructed progressBarWidth (270), not 300
		assert.equals(270, barView.Width)
	end)

	it("reads/writes group-level scalars", function()
		assert.equals(iconGroup.GlowType, iconView.GlowType)
		iconView.Gap = 7
		assert.equals(7, iconGroup.Gap)
	end)

	it("maps IconZoom and BorderStyle for icon groups", function()
		assert.equals(1, iconView.IconZoom)
		iconView.IconZoom = 1.5
		assert.equals(1.5, iconGroup.Elements[Element.Icon].iconZoom)

		iconView.BorderStyle = "None"
		assert.is_false(iconGroup.Elements[Element.Border].active)
		iconView.BorderStyle = "Blizzard Tooltip"
		assert.is_true(iconGroup.Elements[Element.Border].active)
		assert.equals("Blizzard Tooltip", iconGroup.Elements[Element.Border].borderTexture)
	end)

	it("maps bar textures/colors to their elements", function()
		assert.equals("Blizzard Raid Bar", barView.ForegroundBarTexture)
		barView.ProgressBarColor = "FF123456"
		assert.equals("FF123456", barGroup.Elements[Element.ProgressBar].progressBarColor)
		barView.BackgroundBarColor = "FF654321"
		assert.equals("FF654321", barGroup.Elements[Element.Background].backgroundColor)
	end)
end)

describe("CreateGroupView — bar color mode (lossy two-bool ↔ one-mode)", function()
	it("reflects Interruptibility mode as the two booleans", function()
		assert.is_true(barView.UseInterruptabilityColors)
		assert.is_false(barView.UseTargetClassColor)
	end)

	it("switching UseTargetClassColor on moves the mode", function()
		barView.UseTargetClassColor = true
		assert.equals(BarColorMode.TargetClassColor, barGroup.Elements[Element.ProgressBar].barColorMode)
		assert.is_false(barView.UseInterruptabilityColors)
	end)

	it("turning the active bool off falls back to Static", function()
		barView.UseInterruptabilityColors = false
		assert.equals(BarColorMode.Static, barGroup.Elements[Element.ProgressBar].barColorMode)
	end)
end)

describe("CreateGroupView — Font fan-out", function()
	it("Font/FontSize write to every text element", function()
		barView.Font = "Fonts\\SKURRI.TTF"
		barView.FontSize = 22
		assert.equals("Fonts\\SKURRI.TTF", barGroup.Elements[Element.SpellName].font)
		assert.equals("Fonts\\SKURRI.TTF", barGroup.Elements[Element.TargetName].font)
		assert.equals("Fonts\\SKURRI.TTF", barGroup.Elements[Element.InterruptSource].font)
		-- the cooldown countdown font is the prefixed field
		assert.equals("Fonts\\SKURRI.TTF", barGroup.Elements[Element.DurationCooldown].countdownFont)
		assert.equals(22, barGroup.Elements[Element.SpellName].fontSize)
	end)

	it("FontFlags fan out across text elements", function()
		assert.is_true(barView.FontFlags[Enum.FontFlags.OUTLINE])
		barView.FontFlags[Enum.FontFlags.SHADOW] = true
		assert.is_true(barGroup.Elements[Element.SpellName].fontFlags[Enum.FontFlags.SHADOW])
		assert.is_true(barGroup.Elements[Element.TargetName].fontFlags[Enum.FontFlags.SHADOW])
	end)
end)

describe("CreateGroupView — FeatureFlags → group / element / filter", function()
	it("behaviour flags map to group fields", function()
		assert.equals(iconGroup.GlowImportant, iconView.FeatureFlags[FeatureFlag.GlowImportant])
		iconView.FeatureFlags[FeatureFlag.GlowImportant] = false
		assert.is_false(iconGroup.GlowImportant)
	end)

	it("Show* flags map to element.active", function()
		assert.is_true(barView.FeatureFlags[FeatureFlag.ShowIcon])
		barView.FeatureFlags[FeatureFlag.ShowIcon] = false
		assert.is_false(barGroup.Elements[Element.Icon].active)

		barView.FeatureFlags[FeatureFlag.ShowTargetMarker] = true
		assert.is_true(barGroup.Elements[Element.TargetMarker].active)
	end)

	it("icon ShowDuration/ShowSwipe map to the Cooldown element", function()
		iconView.FeatureFlags[FeatureFlag.ShowSwipe] = false
		assert.is_false(iconGroup.Elements[Element.Cooldown].showSwipe)
	end)

	it("ShowTargetClassColor maps to TargetName.useClassColor", function()
		barView.FeatureFlags[FeatureFlag.ShowTargetClassColor] = false
		assert.is_false(barGroup.Elements[Element.TargetName].useClassColor)
	end)

	it("filter flags are the inverse of the party filter", function()
		-- default party filter = {Player, PartyMember, Nobody}
		assert.is_false(barView.FeatureFlags[FeatureFlag.HideUntargetedSpells])
		assert.is_false(barView.FeatureFlags[FeatureFlag.SelfOnly])

		barView.FeatureFlags[FeatureFlag.HideUntargetedSpells] = true
		assert.is_nil(barGroup.Filter[TargetClass.Nobody])
		assert.is_true(barView.FeatureFlags[FeatureFlag.HideUntargetedSpells])

		barView.FeatureFlags[FeatureFlag.SelfOnly] = true
		assert.is_nil(barGroup.Filter[TargetClass.PartyMember])
		assert.is_true(barView.FeatureFlags[FeatureFlag.SelfOnly])

		barView.FeatureFlags[FeatureFlag.HideTargetedSpells] = true
		assert.is_nil(barGroup.Filter[TargetClass.Player])
	end)

	it("dropped flags (MirrorLayout/InlineDuration) read false and ignore writes", function()
		assert.is_false(barView.FeatureFlags[FeatureFlag.MirrorLayout])
		assert.has_no_error(function()
			barView.FeatureFlags[FeatureFlag.InlineDuration] = true
		end)
	end)
end)

describe("CreateGroupView — sub-tables by reference", function()
	it("Position / LoadConditions are the group's own tables", function()
		assert.equals(iconGroup.Position, iconView.Position)
		assert.equals(iconGroup.LoadConditionRole, iconView.LoadConditionRole)
		iconView.Position.x = 123
		assert.equals(123, iconGroup.Position.x)
	end)

	it("Announce tables map to the global TTS table", function()
		assert.equals(b.savedVars().TextToSpeech.AnnounceUntargetedSpells, iconView.AnnounceUntargetedSpells)
		iconView.TextToSpeechVoice = 5
		assert.equals(5, b.savedVars().TextToSpeech.TextToSpeechVoice)
	end)
end)

describe("a v4 import updates groups in place (views/refs survive)", function()
	it("keeps the group table identity and the view reflects imported values", function()
		-- export the current (migrated) v4 config, tweak it, import it back
		local decoded = b.exportDecoded()
		decoded.Groups[1].Gap = 42
		assert.is_true(Private.Utils.Import(b.encode(decoded)))

		-- same table object, updated in place
		assert.equals(iconGroup, b.savedVars().Groups[1])
		assert.equals(42, iconGroup.Gap)
		-- the pre-existing view (captured the group ref) still works
		assert.equals(42, iconView.Gap)
	end)
end)
