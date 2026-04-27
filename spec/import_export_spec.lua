---@diagnostic disable: undefined-global, undefined-field

local b = require("spec.bootstrap")
local Private = b.Private
local Enum = Private.Enum
local Keys = Private.Settings.Keys

describe("Export", function()
	before_each(function()
		b.reset()
	end)

	it("returns a non-empty string", function()
		local s = Private.Utils.Export()
		assert.is_string(s)
		assert.is_true(#s > 0)
	end)

	it("decoded output contains Self and Party keys", function()
		local decoded = b.exportDecoded()
		assert.is_table(decoded)
		assert.is_table(decoded.Self)
		assert.is_table(decoded.Party)
	end)
end)

describe("Round-trip (no change)", function()
	before_each(function()
		b.reset()
	end)

	it("importing an exported snapshot returns false when nothing changed", function()
		assert.is_false(Private.Utils.Import(Private.Utils.Export()))
	end)

	it("fires no events when nothing changed", function()
		Private.Utils.Import(Private.Utils.Export())
		assert.equals(0, #Private.EventRegistry.triggeredEvents)
	end)
end)

describe("Scalar import", function()
	before_each(function()
		b.reset()
	end)

	it("detects a changed Width and restores the exported value", function()
		local exported = Private.Utils.Export() -- Width = 48
		b.savedVars().Settings.Self.Width = 99
		assert.is_true(Private.Utils.Import(exported))
		assert.equals(48, b.savedVars().Settings.Self.Width)
	end)

	it("fires SETTING_CHANGED with the correct key for a changed scalar", function()
		local exported = Private.Utils.Export()
		b.savedVars().Settings.Self.Width = 99
		Private.Utils.Import(exported)

		local found = false
		for _, ev in ipairs(Private.EventRegistry.triggeredEvents) do
			if ev.event == Enum.Events.SETTING_CHANGED and ev.args[1] == Keys.Self.Width then
				found = true
			end
		end
		assert.is_true(found)
	end)

	it("ignores a field whose imported value has the wrong type", function()
		local decoded = b.exportDecoded()
		decoded.Self.Width = "not-a-number"
		assert.is_false(Private.Utils.Import(b.encode(decoded)))
		assert.equals(48, b.savedVars().Settings.Self.Width)
	end)

	it("ignores a key not present in defaults", function()
		local decoded = b.exportDecoded()
		decoded.Self.GhostKey = "ghost" ---@diagnostic disable-line: inject-field
		assert.is_false(Private.Utils.Import(b.encode(decoded)))
		assert.is_nil(b.savedVars().Settings.Self.GhostKey)
	end)

	it("imports a changed Party scalar independently of Self", function()
		local decoded = b.exportDecoded()
		decoded.Party.Width = 500
		assert.is_true(Private.Utils.Import(b.encode(decoded)))
		assert.equals(500, b.savedVars().Settings.Party.Width)
		assert.equals(48, b.savedVars().Settings.Self.Width)
	end)
end)

describe("Table (enum) import", function()
	before_each(function()
		b.reset()
	end)

	it("applies a changed ContentType flag", function()
		local decoded = b.exportDecoded()
		decoded.Self.LoadConditionContentType[Enum.ContentType.OpenWorld] = true
		assert.is_true(Private.Utils.Import(b.encode(decoded)))
		assert.is_true(b.savedVars().Settings.Self.LoadConditionContentType[Enum.ContentType.OpenWorld])
	end)

	it("preserves existing values for enum IDs absent from the import payload", function()
		local decoded = b.exportDecoded()
		decoded.Self.LoadConditionContentType[Enum.ContentType.OpenWorld] = true
		decoded.Self.LoadConditionContentType[Enum.ContentType.Dungeon] = nil
		Private.Utils.Import(b.encode(decoded))
		assert.is_true(b.savedVars().Settings.Self.LoadConditionContentType[Enum.ContentType.Dungeon])
	end)

	it("sets Enabled=false when all LoadConditionContentType flags are disabled", function()
		local decoded = b.exportDecoded()
		for _, id in pairs(Enum.ContentType) do
			decoded.Self.LoadConditionContentType[id] = false
		end
		Private.Utils.Import(b.encode(decoded))
		assert.is_false(b.savedVars().Settings.Self.Enabled)
	end)

	it("does not disable Enabled when at least one ContentType flag remains true", function()
		local decoded = b.exportDecoded()
		for _, id in pairs(Enum.ContentType) do
			decoded.Self.LoadConditionContentType[id] = false
		end
		decoded.Self.LoadConditionContentType[Enum.ContentType.Dungeon] = true
		Private.Utils.Import(b.encode(decoded))
		assert.is_true(b.savedVars().Settings.Self.Enabled)
	end)
end)

describe("Partial import (one kind only)", function()
	before_each(function()
		b.reset()
	end)

	it("Self-only payload leaves Party unchanged", function()
		local decoded = b.exportDecoded()
		decoded.Self.Width = 99
		decoded.Party = nil
		Private.Utils.Import(b.encode(decoded))
		assert.equals(300, b.savedVars().Settings.Party.Width)
	end)

	it("Party-only payload leaves Self unchanged", function()
		local decoded = b.exportDecoded()
		decoded.Party.Width = 400
		decoded.Self = nil
		Private.Utils.Import(b.encode(decoded))
		assert.equals(48, b.savedVars().Settings.Self.Width)
	end)
end)

describe("Invalid input", function()
	before_each(function()
		b.reset()
	end)

	it("returns false for a garbage string", function()
		assert.is_false(Private.Utils.Import("not valid base64 or cbor !!!"))
	end)

	it("returns false for an empty string", function()
		assert.is_false(Private.Utils.Import(""))
	end)
end)

describe("LoadConditionRole import", function()
	before_each(function()
		b.reset()
	end)

	it("sets Enabled=false when all LoadConditionRole flags are disabled", function()
		local decoded = b.exportDecoded()
		for _, id in pairs(Enum.Role) do
			decoded.Self.LoadConditionRole[id] = false
		end
		Private.Utils.Import(b.encode(decoded))
		assert.is_false(b.savedVars().Settings.Self.Enabled)
	end)

	it("does not disable Enabled when at least one Role flag remains true", function()
		local decoded = b.exportDecoded()
		for _, id in pairs(Enum.Role) do
			decoded.Self.LoadConditionRole[id] = false
		end
		decoded.Self.LoadConditionRole[Enum.Role.Healer] = true
		Private.Utils.Import(b.encode(decoded))
		assert.is_true(b.savedVars().Settings.Self.Enabled)
	end)

	it("fires SETTING_CHANGED with the correct key for a changed Role flag", function()
		local decoded = b.exportDecoded()
		decoded.Self.LoadConditionRole[Enum.Role.Damager] = false
		Private.Utils.Import(b.encode(decoded))

		local found = false
		for _, ev in ipairs(Private.EventRegistry.triggeredEvents) do
			if ev.event == Enum.Events.SETTING_CHANGED and ev.args[1] == Keys.Self.LoadConditionRole then
				found = true
			end
		end
		assert.is_true(found)
	end)
end)

describe("FeatureFlags import", function()
	before_each(function()
		b.reset()
	end)

	it("applies a changed FeatureFlag", function()
		local decoded = b.exportDecoded()
		decoded.Self.FeatureFlags[Enum.FeatureFlag.ShowDuration] = false
		assert.is_true(Private.Utils.Import(b.encode(decoded)))
		assert.is_false(b.savedVars().Settings.Self.FeatureFlags[Enum.FeatureFlag.ShowDuration])
	end)

	it("preserves flags absent from the import payload", function()
		local decoded = b.exportDecoded()
		decoded.Self.FeatureFlags[Enum.FeatureFlag.ShowDuration] = false
		decoded.Self.FeatureFlags[Enum.FeatureFlag.GlowImportant] = nil
		Private.Utils.Import(b.encode(decoded))
		assert.is_true(b.savedVars().Settings.Self.FeatureFlags[Enum.FeatureFlag.GlowImportant])
	end)

	it("fires SETTING_CHANGED with the correct key for a changed FeatureFlag", function()
		local decoded = b.exportDecoded()
		decoded.Self.FeatureFlags[Enum.FeatureFlag.ShowDuration] = false
		Private.Utils.Import(b.encode(decoded))

		local found = false
		for _, ev in ipairs(Private.EventRegistry.triggeredEvents) do
			if ev.event == Enum.Events.SETTING_CHANGED and ev.args[1] == Keys.Self.FeatureFlags then
				found = true
			end
		end
		assert.is_true(found)
	end)
end)

describe("AnnounceUntargetedSpells import", function()
	before_each(function()
		b.reset()
	end)

	it("applies a changed NpcType flag", function()
		local decoded = b.exportDecoded()
		decoded.Self.AnnounceUntargetedSpells[Enum.NpcType.Boss] = false
		assert.is_true(Private.Utils.Import(b.encode(decoded)))
		assert.is_false(b.savedVars().Settings.Self.AnnounceUntargetedSpells[Enum.NpcType.Boss])
	end)

	it("preserves flags absent from the import payload", function()
		local decoded = b.exportDecoded()
		decoded.Self.AnnounceUntargetedSpells[Enum.NpcType.Boss] = false
		decoded.Self.AnnounceUntargetedSpells[Enum.NpcType.Lieutenant] = nil
		Private.Utils.Import(b.encode(decoded))
		assert.is_true(b.savedVars().Settings.Self.AnnounceUntargetedSpells[Enum.NpcType.Lieutenant])
	end)
end)

describe("AnnounceTargetedSpells import", function()
	before_each(function()
		b.reset()
	end)

	it("applies a changed NpcType flag", function()
		local decoded = b.exportDecoded()
		decoded.Self.AnnounceTargetedSpells[Enum.NpcType.Boss] = true
		assert.is_true(Private.Utils.Import(b.encode(decoded)))
		assert.is_true(b.savedVars().Settings.Self.AnnounceTargetedSpells[Enum.NpcType.Boss])
	end)

	it("preserves flags absent from the import payload", function()
		local decoded = b.exportDecoded()
		decoded.Self.AnnounceTargetedSpells[Enum.NpcType.Boss] = true
		decoded.Self.AnnounceTargetedSpells[Enum.NpcType.Lieutenant] = nil
		Private.Utils.Import(b.encode(decoded))
		assert.is_false(b.savedVars().Settings.Self.AnnounceTargetedSpells[Enum.NpcType.Lieutenant])
	end)
end)

describe("ApplyMigration", function()
	before_each(function()
		b.reset()
	end)

	it("migrates Grow=1 (deprecated Center) to Grow.Start", function()
		local decoded = b.exportDecoded()
		decoded.Self.Grow = 1
		Private.Utils.Import(b.encode(decoded))
		assert.equals(Enum.Grow.Start, b.savedVars().Settings.Self.Grow)
	end)

	it("migrates GlowType=3 (deprecated ButtonGlow) to PixelGlow", function()
		local decoded = b.exportDecoded()
		decoded.Self.GlowType = 3
		Private.Utils.Import(b.encode(decoded))
		assert.equals(Enum.GlowType.PixelGlow, b.savedVars().Settings.Self.GlowType)
	end)

	it("migrates ShowBorder=true to default BorderStyle when called directly", function()
		local defaults = Private.Settings.GetSelfDefaultSettings()
		b.savedVars().Settings.Self.ShowBorder = true ---@diagnostic disable-line: inject-field
		Private.Utils.ApplyMigration("ShowBorder", Enum.FrameKind.Self, defaults)
		assert.is_nil(b.savedVars().Settings.Self.ShowBorder) ---@diagnostic disable-line: undefined-field
		assert.equals(defaults.BorderStyle, b.savedVars().Settings.Self.BorderStyle)
	end)

	it("migrates ShowBorder=false to BorderStyle 'None' when called directly", function()
		local defaults = Private.Settings.GetSelfDefaultSettings()
		b.savedVars().Settings.Self.ShowBorder = false ---@diagnostic disable-line: inject-field
		Private.Utils.ApplyMigration("ShowBorder", Enum.FrameKind.Self, defaults)
		assert.is_nil(b.savedVars().Settings.Self.ShowBorder) ---@diagnostic disable-line: undefined-field
		assert.equals("None", b.savedVars().Settings.Self.BorderStyle)
	end)
end)
