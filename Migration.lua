---@type string, TargetedSpells
local addonName, Private = ...

-- Migration.lua ───────────────────────────────────────────────────────────────
-- v3 → v4 SavedVariables rewrite. v4 replaces the two fixed Settings.Self /
-- Settings.Party trees with an N-group model (see the v4 plan). This is a
-- one-way rewrite; downgrade to v3 is out of scope, so no v3 backup is kept.
--
-- Public surface:
--   Private.Migration.Apply(saved) -- migrate a saved table in place to v4
-- Everything else stays file-local. The filter derivation is additionally exposed
-- under Private.__test for the (gated, spec-only) transform tests; it ships no
-- behaviour.
--
-- This module owns the whole pre-v4 phase: a v3 config is read exactly as it sits
-- on disk, field by field, with no caller-side backfill. Nothing outside here may
-- reshape TargetedSpellsSaved.Settings.
--
-- NOTE: bar element *layout* is intentionally NOT migrated. v3's free per-element
-- pixel layout has no faithful mapping onto v4's bar reflow model, so bars adopt the
-- v4 template defaults for geometry and only carry over v4-representable appearance
-- (colours/textures/fonts/toggles/filter). Group Position IS migrated, so a user's
-- placement survives; only bar appearance needs re-tuning. See BuildBarElements.
--
local Enum = Private.Enum
local Element = Enum.Element
local Template = Enum.Template
local TargetClass = Enum.TargetClass
local BarColorMode = Enum.BarColorMode

---@class TargetedSpellsMigration
Private.Migration = {}

local CURRENT_SCHEMA_VERSION = 4

-- Frozen v3 decode map, and the sole definition of these ids: v3 profile strings (shared
-- publicly) encode FeatureFlags as a table keyed by them, and v4 groups carry the surviving
-- ones as named boolean fields instead, so there is no live enum for this any more. Exposed
-- on Private.Migration because the v3 default builders in Settings.lua read it too.
-- Do not edit: these describe historical data. Ids 4, 5 and 9 were retired during v3
-- (ShowDurationFractions, ShowBorder, IncludeSelfInParty) and must not be reused.
local V3_FLAG = {
	GlowImportant = 1,
	OnlyImportant = 2,
	ShowDuration = 3,
	ShowSwipe = 6,
	IndicateInterrupts = 7,
	RenderInterruptSourceName = 8,
	ShowIcon = 10,
	ShowTargetMarker = 11,
	ShowSpellName = 12,
	ShowTargetName = 13,
	ShowTargetClassColor = 14,
	MirrorLayout = 15,
	HideUntargetedSpells = 16,
	HideTargetedSpells = 17,
	SelfOnly = 18,
	InlineDuration = 19,
}

local V3_NPC_TYPE = { Caster = 3, Melee = 4 }

local function copy(value)
	return Private.Utils.DeepCopy(value)
end

local function flag(featureFlags, id)
	return featureFlags and featureFlags[id] == true
end

-- A v3 config on disk is whatever the version that wrote it happened to store: keys
-- added late in v3's life are missing, and a hand-edited or very old value can hold
-- the wrong type. Every read of a v3 field goes through here, so the transform never
-- assumes a complete source.
---@param source table
---@param defaults table
---@param key string
local function read(source, defaults, key)
	local value = source[key]

	if value == nil or type(value) ~= type(defaults[key]) then
		return defaults[key]
	end

	return value
end

-- Two v3 enum members were retired mid-v3 and their ids reused for nothing. Both
-- remaps key on the saved *value*, so a config that never held the legacy id passes
-- through untouched.
---@param value number
---@return Grow
local function MigrateGrow(value)
	if value == 1 then -- the removed Grow.Center
		return Enum.Grow.Start
	end

	return value
end

---@param value number
---@return GlowType
local function MigrateGlowType(value)
	if value == 3 then -- the removed GlowType.ButtonGlow
		return Enum.GlowType.PixelGlow
	end

	return value
end

-- v3 reshaped the party display far too heavily for its v2 settings to be carried
-- over field by field, so the party side restarts from the v3 defaults and keeps only
-- the handful of keys whose meaning survived. Runs for a config that never saw v3
-- (V3MigrationWarningSeen unset), and is what the migration popup tells the user about.

-- ── Element layout builders ──────────────────────────────────────────────────

---@param selfSettings SavedVariablesSettingsSelf
---@param defaults SavedVariablesSettingsSelf
local function BuildSelfGroup(selfSettings, defaults)
	local flags = read(selfSettings, defaults, "FeatureFlags")

	local function BuildIconElements()
		local elements = Private.Design.GetDefault(Template.Icon)
		local flags = read(selfSettings, defaults, "FeatureFlags")
		local fontFlags = copy(read(selfSettings, defaults, "FontFlags"))
		local fontSize = read(selfSettings, defaults, "FontSize")
		local font = read(selfSettings, defaults, "Font")

		local icon = elements[Element.Icon]
		icon.width = read(selfSettings, defaults, "Width")
		icon.height = read(selfSettings, defaults, "Height")
		icon.iconZoom = read(selfSettings, defaults, "IconZoom")

		local cooldown = elements[Element.Cooldown]
		cooldown.showSwipe = flag(flags, V3_FLAG.ShowSwipe)
		cooldown.showCountdown = flag(flags, V3_FLAG.ShowDuration)
		cooldown.countdownFontSize = fontSize
		cooldown.countdownFont = font
		cooldown.countdownFontFlags = copy(fontFlags)

		local interruptSource = elements[Element.InterruptSource]
		interruptSource.active = flag(flags, V3_FLAG.RenderInterruptSourceName)
		interruptSource.fontSize = fontSize
		interruptSource.font = font
		interruptSource.fontFlags = copy(fontFlags)

		-- v3 stored border style as a single LSM name; "None" meant no border
		local border = elements[Element.Border]
		local borderStyle = read(selfSettings, defaults, "BorderStyle")
		if borderStyle == "None" then
			border.active = false
		else
			border.active = true
			border.borderTexture = borderStyle
		end

		return elements
	end

	return {
		Name = "Self",
		Enabled = read(selfSettings, defaults, "Enabled"),
		Filter = { [TargetClass.Player] = true },
		Template = Template.Icon,
		Elements = BuildIconElements(),
		Position = copy(read(selfSettings, defaults, "Position")),
		Gap = read(selfSettings, defaults, "Gap"),
		Grow = MigrateGrow(read(selfSettings, defaults, "Grow")),
		Direction = read(selfSettings, defaults, "Direction"),
		SortOrder = read(selfSettings, defaults, "SortOrder"),
		LoadConditionContentType = copy(read(selfSettings, defaults, "LoadConditionContentType")),
		LoadConditionRole = copy(read(selfSettings, defaults, "LoadConditionRole")),
		GlowType = MigrateGlowType(read(selfSettings, defaults, "GlowType")),
		GlowImportant = flag(flags, V3_FLAG.GlowImportant),
		OnlyImportant = flag(flags, V3_FLAG.OnlyImportant),
		IndicateInterrupts = flag(flags, V3_FLAG.IndicateInterrupts),
	}
end

---@param partySettings SavedVariablesSettingsParty
---@param defaults SavedVariablesSettingsParty
local function BuildPartyGroup(partySettings, defaults)
	local flags = read(partySettings, defaults, "FeatureFlags")

	local function BuildBarElements()
		-- LAYOUT IS NOT MIGRATED for bars. v3 stored a free per-element pixel layout
		-- (Width/Height + edge-anchored, width-split boxes); v4's bar is a reflow model
		-- (Private.Utils.ComputeBarLayout) where element x/y are small insets and
		-- ProgressBar.width is the *total* frame width with the gutter subtracted
		-- internally. There is no faithful mapping between the two: any reconstructed
		-- absolute offset is re-interpreted as an inset and the elements fly apart. So we
		-- keep the v4 template's default geometry verbatim and only carry over the settings
		-- that ARE representable in v4 (colours, textures, fonts, active toggles, filter).
		-- Positioning is preserved at the group level via Position; users re-tune bar
		-- appearance with the new designer. See BuildPartyGroup / DerivePartyFilter.
		local elements = Private.Design.GetDefault(Template.Bar)
		local flags = read(partySettings, defaults, "FeatureFlags")
		local fontFlags = copy(read(partySettings, defaults, "FontFlags"))
		local fontSize = read(partySettings, defaults, "FontSize")
		local font = read(partySettings, defaults, "Font")

		local progressBar = elements[Element.ProgressBar]
		progressBar.barTexture = read(partySettings, defaults, "ForegroundBarTexture")
		progressBar.progressBarColor = read(partySettings, defaults, "ProgressBarColor")
		progressBar.interruptibleColor = read(partySettings, defaults, "InterruptibleColor")
		progressBar.uninterruptibleColor = read(partySettings, defaults, "UninterruptibleColor")
		if read(partySettings, defaults, "UseInterruptabilityColors") then
			progressBar.barColorMode = BarColorMode.Interruptibility
		elseif read(partySettings, defaults, "UseTargetClassColor") then
			progressBar.barColorMode = BarColorMode.TargetClassColor
		else
			progressBar.barColorMode = BarColorMode.Static
		end

		local background = elements[Element.Background]
		background.backgroundTexture = read(partySettings, defaults, "BackgroundBarTexture")
		background.backgroundColor = read(partySettings, defaults, "BackgroundBarColor")

		elements[Element.Icon].active = flag(flags, V3_FLAG.ShowIcon)
		elements[Element.TargetMarker].active = flag(flags, V3_FLAG.ShowTargetMarker)

		local duration = elements[Element.DurationCooldown]
		-- v4: the bar duration's `active` toggle controls both the region and its number
		duration.active = flag(flags, V3_FLAG.ShowDuration)
		duration.countdownFontSize = fontSize
		duration.countdownFont = font
		duration.countdownFontFlags = copy(fontFlags)

		local spellName = elements[Element.SpellName]
		spellName.active = flag(flags, V3_FLAG.ShowSpellName)
		spellName.fontSize = fontSize
		spellName.font = font
		spellName.fontFlags = copy(fontFlags)

		local targetName = elements[Element.TargetName]
		targetName.active = flag(flags, V3_FLAG.ShowTargetName)
		targetName.useClassColor = flag(flags, V3_FLAG.ShowTargetClassColor)
		targetName.fontSize = fontSize
		targetName.font = font
		targetName.fontFlags = copy(fontFlags)

		local interruptSource = elements[Element.InterruptSource]
		interruptSource.active = flag(flags, V3_FLAG.RenderInterruptSourceName)
		interruptSource.fontSize = fontSize
		interruptSource.font = font
		interruptSource.fontFlags = copy(fontFlags)

		return elements
	end

	---@return table<TargetClass, boolean>
	local function DerivePartyFilter()
		local filter = {
			[TargetClass.Player] = true,
			[TargetClass.PartyMember] = true,
			[TargetClass.Nobody] = true,
		}

		if flag(flags, V3_FLAG.SelfOnly) then
			filter[TargetClass.PartyMember] = nil
		end
		if flag(flags, V3_FLAG.HideUntargetedSpells) then
			filter[TargetClass.Nobody] = nil
		end
		if flag(flags, V3_FLAG.HideTargetedSpells) then
			filter[TargetClass.Player] = nil
			filter[TargetClass.PartyMember] = nil
		end

		return filter
	end

	return {
		Name = "Party",
		Enabled = read(partySettings, defaults, "Enabled"),
		Filter = DerivePartyFilter(),
		Template = Template.Bar,
		Elements = BuildBarElements(),
		Position = copy(read(partySettings, defaults, "Position")),
		Gap = read(partySettings, defaults, "Gap"),
		Grow = MigrateGrow(read(partySettings, defaults, "Grow")),
		Direction = Enum.Direction.Vertical,
		SortOrder = read(partySettings, defaults, "SortOrder"),
		LoadConditionContentType = copy(read(partySettings, defaults, "LoadConditionContentType")),
		LoadConditionRole = copy(read(partySettings, defaults, "LoadConditionRole")),
		GlowType = MigrateGlowType(read(partySettings, defaults, "GlowType")),
		GlowImportant = flags[1] == nil and true or flags[1],
		OnlyImportant = flags[2] == nil and false or flags[2],
		IndicateInterrupts = flags[7] == nil and true or flags[7],
	}
end

-- Collapses the deprecated Caster/Melee buckets of one v3 TTS table into
-- Enum.NpcType.Other. The merge is an OR: a user who had either bucket enabled keeps
-- hearing those casts rather than silently losing them.
---@param source table<number, boolean>|nil
---@return table<number, boolean>|nil
local function FoldNpcTypes(source)
	local folded = copy(source)

	if folded == nil then
		return nil
	end

	if folded[V3_NPC_TYPE.Caster] or folded[V3_NPC_TYPE.Melee] then
		folded[Enum.NpcType.Other] = true
	elseif folded[Enum.NpcType.Other] == nil then
		folded[Enum.NpcType.Other] = false
	end

	folded[V3_NPC_TYPE.Caster] = nil
	folded[V3_NPC_TYPE.Melee] = nil

	return folded
end

-- ── Ordered migration steps ──────────────────────────────────────────────────
-- migrationSteps[N] upgrades a schema at version N to N+1, mutating `saved` in
-- place and bumping saved.SchemaVersion. A missing SchemaVersion is treated as
-- v3 (the last unversioned shape). A step returns true when what it did needs
-- telling the user about; the caller owns that UI.

local migrationSteps = {
	-- v3 → v4: two fixed Settings trees become an N-group model.
	[3] = function(saved)
		local settings = saved.Settings or {}
		local selfDefaults = {
			Enabled = true,
			Width = 48,
			Height = 48,
			Gap = 2,
			Direction = Private.Enum.Direction.Horizontal,
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
			SortOrder = Private.Enum.SortOrder.Ascending,
			Grow = Private.Enum.Grow.Start,
			FontSize = 20,
			Position = Private.Settings.GetDefaultEditModeFramePosition(Private.Enum.FrameKind.Self),
			IconZoom = 1,
			GlowType = Private.Enum.GlowType.PixelGlow,
			Font = "Fonts\\FRIZQT__.TTF",
			FontFlags = {
				[Private.Enum.FontFlags.OUTLINE] = true,
				[Private.Enum.FontFlags.SHADOW] = false,
			},
			FeatureFlags = {
				[V3_FLAG.GlowImportant] = true,
				[V3_FLAG.OnlyImportant] = false,
				[V3_FLAG.ShowDuration] = true,
				[V3_FLAG.ShowSwipe] = true,
				[V3_FLAG.IndicateInterrupts] = false,
				[V3_FLAG.RenderInterruptSourceName] = false,
			},
			BorderStyle = "Blizzard Tooltip Border",
			AnnounceUntargetedSpells = {
				[Private.Enum.NpcType.Boss] = true,
				[Private.Enum.NpcType.Lieutenant] = true,
				[Private.Enum.NpcType.Other] = true,
				[Private.Enum.NpcType.Minion] = false,
			},
			AnnounceTargetedSpells = {
				[Private.Enum.NpcType.Boss] = false,
				[Private.Enum.NpcType.Lieutenant] = false,
				[Private.Enum.NpcType.Other] = false,
				[Private.Enum.NpcType.Minion] = false,
			},
			TextToSpeechVoice = -1,
		}
		local partyDefaults = {
			Enabled = true,
			Width = 300,
			Height = 30,
			FontSize = 14,
			Gap = 2,
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
			SortOrder = Private.Enum.SortOrder.Ascending,
			Grow = Private.Enum.Grow.Start,
			GlowType = Private.Enum.GlowType.PixelGlow,
			Font = "Fonts\\FRIZQT__.TTF",
			FontFlags = {
				[Private.Enum.FontFlags.OUTLINE] = true,
				[Private.Enum.FontFlags.SHADOW] = false,
			},
			FeatureFlags = {
				[V3_FLAG.GlowImportant] = true,
				[V3_FLAG.OnlyImportant] = false,
				[V3_FLAG.IndicateInterrupts] = true,
				[V3_FLAG.RenderInterruptSourceName] = true,
				[V3_FLAG.ShowDuration] = true,
				[V3_FLAG.ShowIcon] = true,
				[V3_FLAG.ShowTargetMarker] = false,
				[V3_FLAG.ShowSpellName] = true,
				[V3_FLAG.ShowTargetName] = true,
				[V3_FLAG.ShowTargetClassColor] = true,
				[V3_FLAG.MirrorLayout] = false,
				[V3_FLAG.HideUntargetedSpells] = false,
				[V3_FLAG.HideTargetedSpells] = false,
				[V3_FLAG.SelfOnly] = false,
				[V3_FLAG.InlineDuration] = true,
			},
			ForegroundBarTexture = "Blizzard Raid Bar",
			BackgroundBarTexture = "Solid",
			BackgroundBarColor = "FF1A1A1A",
			ProgressBarColor = "FFFFFF00",
			UseInterruptabilityColors = true,
			UseTargetClassColor = false,
			UninterruptibleColor = "FFFF4444",
			InterruptibleColor = "FF44FF44",
			AnnounceUntargetedSpells = {
				[Private.Enum.NpcType.Boss] = true,
				[Private.Enum.NpcType.Lieutenant] = true,
				[Private.Enum.NpcType.Other] = true,
				[Private.Enum.NpcType.Minion] = false,
			},
			AnnounceTargetedSpells = {
				[Private.Enum.NpcType.Boss] = false,
				[Private.Enum.NpcType.Lieutenant] = false,
				[Private.Enum.NpcType.Other] = false,
				[Private.Enum.NpcType.Minion] = false,
			},
			TextToSpeechVoice = -1,
			Position = Private.Settings.GetDefaultEditModeFramePosition(Private.Enum.FrameKind.Party),
		}
		local selfSettings = settings.Self or selfDefaults
		local partySettings = settings.Party or partyDefaults

		---@return SavedVariablesSettingsParty
		local function MigratePartySettingsToV3()
			local compatibleKeys = {
				"Enabled",
				"LoadConditionContentType",
				"LoadConditionRole",
				"Font",
				"GlowType",
				"FontFlags",
			}

			for _, key in ipairs(compatibleKeys) do
				local value = partySettings[key]

				if value ~= nil and type(value) == type(partyDefaults[key]) then
					partyDefaults[key] = value
				end
			end

			return partyDefaults
		end

		partySettings = MigratePartySettingsToV3()

		local function ReadAnnounceUntargetedSpells()
			local value = selfSettings.AnnounceUntargetedSpells

			if type(value) == "boolean" then
				return {
					[Enum.NpcType.Boss] = value,
					[Enum.NpcType.Lieutenant] = value,
					[Enum.NpcType.Other] = value,
					[Enum.NpcType.Minion] = false,
				}
			end

			return selfSettings.AnnounceUntargetedSpells
		end

		saved.Groups = {
			[1] = BuildSelfGroup(selfSettings, selfDefaults),
			[2] = BuildPartyGroup(partySettings, partyDefaults),
		}
		saved.TextToSpeech = {
			AnnounceUntargetedSpells = FoldNpcTypes(ReadAnnounceUntargetedSpells()),
			AnnounceTargetedSpells = FoldNpcTypes(read(selfSettings, selfDefaults, "AnnounceTargetedSpells")),
			TextToSpeechVoice = read(selfSettings, selfDefaults, "TextToSpeechVoice"),
		}
		saved.Settings = nil
		saved.SchemaVersion = 4

		return false
	end,
}

function Private.Migration.Apply(saved)
	local version = saved.SchemaVersion or 3

	while version < CURRENT_SCHEMA_VERSION do
		local step = migrationSteps[version]
		assert(step, "Migration.Apply: no step from schema version " .. tostring(version))

		step(saved)

		local advanced = saved.SchemaVersion
		version = advanced
	end
end

-- Gated test-only internals (never ships behaviour): the pure reconstruction and
-- filter derivation the snapshot / transform specs pin directly.
Private.__test = Private.__test or {}
Private.__test.Migration = {
	CURRENT_SCHEMA_VERSION = CURRENT_SCHEMA_VERSION,
	FoldNpcTypes = FoldNpcTypes,
	V3_FLAG = V3_FLAG,
	V3_NPC_TYPE = V3_NPC_TYPE,
}
