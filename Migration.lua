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
-- NOTE: bar element *layout* is intentionally NOT migrated. v3's free per-element
-- pixel layout has no faithful mapping onto v4's bar reflow model, so bars adopt the
-- v4 template defaults for geometry and only carry over v4-representable appearance
-- (colours/textures/fonts/toggles/filter). Group Position IS migrated, so a user's
-- placement survives; only bar appearance needs re-tuning. See buildBarElements.
--
-- PHASE-2 GATE (challenge #1): this module is NOT wired into ADDON_LOADED yet.
-- The Driver still reads Settings.Self/Party until Phase 3, and there is no
-- escape hatch, so running Apply on a live config would irreversibly convert it
-- with nothing to render it. Apply is exercised purely by busted this phase;
-- Phase 3 step 8a wires it into real ADDON_LOADED once a v4 reader exists.

local Enum = Private.Enum
local Element = Enum.Element
local Template = Enum.Template
local TargetClass = Enum.TargetClass
local BarColorMode = Enum.BarColorMode

---@class TargetedSpellsMigration
Private.Migration = {}

local CURRENT_SCHEMA_VERSION = 4

-- Frozen v3 decode maps. v3 profile strings (shared publicly) encode FeatureFlags
-- and FontFlags as tables keyed by these ids. The live Enum.FeatureFlag may be
-- dropped in v4, so the id→meaning lives here, inside the migration path only —
-- not as a live enum. Do not edit: these describe historical data.
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

-- v3 FontFlags bit positions (must stay decodable; per-element value in v4).
local V3_FONT_FLAG = { OUTLINE = 1, SHADOW = 2 }

local function copy(value)
	return Private.Utils.DeepCopy(value)
end

local function flag(featureFlags, id)
	return featureFlags and featureFlags[id] == true
end

-- ── v3 party filter → v4 multi-select TargetClass set ─────────────────────────
-- Reproduces the exact v3 visibility semantics (TargetedSpellsBarMixin:PostCreate
-- lines ~454-484), which were composable, not one-of:
--   base           = {Player, PartyMember, Nobody}
--   SelfOnly       removes PartyMember (player-targeted + untargeted stay — the
--                  explicit v3 "allow untargeted spells to still get shown")
--   HideUntargeted removes Nobody
--   HideTargeted   removes Player + PartyMember (only untargeted stays)
-- SelfOnly and HideTargeted are mutually exclusive in v3; the result is never
-- empty.
---@param featureFlags table<number, boolean>
---@return table<TargetClass, boolean>
local function derivePartyFilter(featureFlags)
	local filter = {
		[TargetClass.Player] = true,
		[TargetClass.PartyMember] = true,
		[TargetClass.Nobody] = true,
	}

	if flag(featureFlags, V3_FLAG.SelfOnly) then
		filter[TargetClass.PartyMember] = nil
	end
	if flag(featureFlags, V3_FLAG.HideUntargetedSpells) then
		filter[TargetClass.Nobody] = nil
	end
	if flag(featureFlags, V3_FLAG.HideTargetedSpells) then
		filter[TargetClass.Player] = nil
		filter[TargetClass.PartyMember] = nil
	end

	return filter
end

-- ── Element layout builders ──────────────────────────────────────────────────

---@param selfSettings SavedVariablesSettingsSelf
local function buildIconElements(selfSettings)
	local elements = Private.Design.GetDefault(Template.Icon)
	local flags = selfSettings.FeatureFlags
	local fontFlags = copy(selfSettings.FontFlags)

	local icon = elements[Element.Icon]
	icon.width = selfSettings.Width
	icon.height = selfSettings.Height
	icon.iconZoom = selfSettings.IconZoom

	local cooldown = elements[Element.Cooldown]
	cooldown.showSwipe = flag(flags, V3_FLAG.ShowSwipe)
	cooldown.showCountdown = flag(flags, V3_FLAG.ShowDuration)
	cooldown.countdownFontSize = selfSettings.FontSize
	cooldown.countdownFont = selfSettings.Font
	cooldown.countdownFontFlags = copy(fontFlags)

	local interruptSource = elements[Element.InterruptSource]
	interruptSource.active = flag(flags, V3_FLAG.RenderInterruptSourceName)
	interruptSource.fontSize = selfSettings.FontSize
	interruptSource.font = selfSettings.Font
	interruptSource.fontFlags = copy(fontFlags)

	-- v3 stored border style as a single LSM name; "None" meant no border
	local border = elements[Element.Border]
	if selfSettings.BorderStyle == "None" then
		border.active = false
	else
		border.active = true
		border.borderTexture = selfSettings.BorderStyle
	end

	return elements
end

---@param partySettings SavedVariablesSettingsParty
local function buildBarElements(partySettings)
	-- LAYOUT IS NOT MIGRATED for bars. v3 stored a free per-element pixel layout
	-- (Width/Height + edge-anchored, width-split boxes); v4's bar is a reflow model
	-- (Private.Utils.ComputeBarLayout) where element x/y are small insets and
	-- ProgressBar.width is the *total* frame width with the gutter subtracted
	-- internally. There is no faithful mapping between the two: any reconstructed
	-- absolute offset is re-interpreted as an inset and the elements fly apart. So we
	-- keep the v4 template's default geometry verbatim and only carry over the settings
	-- that ARE representable in v4 (colours, textures, fonts, active toggles, filter).
	-- Positioning is preserved at the group level via Position; users re-tune bar
	-- appearance with the new designer. See buildPartyGroup / derivePartyFilter.
	local elements = Private.Design.GetDefault(Template.Bar)
	local flags = partySettings.FeatureFlags
	local fontFlags = copy(partySettings.FontFlags)

	local progressBar = elements[Element.ProgressBar]
	progressBar.barTexture = partySettings.ForegroundBarTexture
	progressBar.progressBarColor = partySettings.ProgressBarColor
	progressBar.interruptibleColor = partySettings.InterruptibleColor
	progressBar.uninterruptibleColor = partySettings.UninterruptibleColor
	if partySettings.UseInterruptabilityColors then
		progressBar.barColorMode = BarColorMode.Interruptibility
	elseif partySettings.UseTargetClassColor then
		progressBar.barColorMode = BarColorMode.TargetClassColor
	else
		progressBar.barColorMode = BarColorMode.Static
	end

	local background = elements[Element.Background]
	background.backgroundTexture = partySettings.BackgroundBarTexture
	background.backgroundColor = partySettings.BackgroundBarColor

	elements[Element.Icon].active = flag(flags, V3_FLAG.ShowIcon)
	elements[Element.TargetMarker].active = flag(flags, V3_FLAG.ShowTargetMarker)

	local duration = elements[Element.DurationCooldown]
	-- v4: the bar duration's `active` toggle controls both the region and its number
	duration.active = flag(flags, V3_FLAG.ShowDuration)
	duration.countdownFontSize = partySettings.FontSize
	duration.countdownFont = partySettings.Font
	duration.countdownFontFlags = copy(fontFlags)

	local spellName = elements[Element.SpellName]
	spellName.active = flag(flags, V3_FLAG.ShowSpellName)
	spellName.fontSize = partySettings.FontSize
	spellName.font = partySettings.Font
	spellName.fontFlags = copy(fontFlags)

	local targetName = elements[Element.TargetName]
	targetName.active = flag(flags, V3_FLAG.ShowTargetName)
	targetName.useClassColor = flag(flags, V3_FLAG.ShowTargetClassColor)
	targetName.fontSize = partySettings.FontSize
	targetName.font = partySettings.Font
	targetName.fontFlags = copy(fontFlags)

	local interruptSource = elements[Element.InterruptSource]
	interruptSource.active = flag(flags, V3_FLAG.RenderInterruptSourceName)
	interruptSource.fontSize = partySettings.FontSize
	interruptSource.font = partySettings.Font
	interruptSource.fontFlags = copy(fontFlags)

	return elements
end

-- ── Group + TTS assembly ─────────────────────────────────────────────────────

local function localizedName(key, fallback)
	local group = Private.L and Private.L.Migration
	local name = group and group[key]
	if type(name) == "string" and name ~= "" then
		return name
	end
	return fallback
end

---@param selfSettings SavedVariablesSettingsSelf
local function buildSelfGroup(selfSettings)
	local flags = selfSettings.FeatureFlags
	return {
		Name = localizedName("SelfGroupName", "Self"),
		Enabled = selfSettings.Enabled,
		Filter = { [TargetClass.Player] = true },
		Template = Template.Icon,
		Elements = buildIconElements(selfSettings),
		Position = copy(selfSettings.Position),
		Gap = selfSettings.Gap,
		Grow = selfSettings.Grow,
		Direction = selfSettings.Direction,
		SortOrder = selfSettings.SortOrder,
		LoadConditionContentType = copy(selfSettings.LoadConditionContentType),
		LoadConditionRole = copy(selfSettings.LoadConditionRole),
		GlowType = selfSettings.GlowType,
		GlowImportant = flag(flags, V3_FLAG.GlowImportant),
		OnlyImportant = flag(flags, V3_FLAG.OnlyImportant),
		IndicateInterrupts = flag(flags, V3_FLAG.IndicateInterrupts),
	}
end

---@param partySettings SavedVariablesSettingsParty
local function buildPartyGroup(partySettings)
	local flags = partySettings.FeatureFlags
	return {
		Name = localizedName("PartyGroupName", "Party"),
		Enabled = partySettings.Enabled,
		Filter = derivePartyFilter(flags),
		Template = Template.Bar,
		Elements = buildBarElements(partySettings),
		Position = copy(partySettings.Position),
		Gap = partySettings.Gap,
		Grow = partySettings.Grow,
		-- v3 forced the party display to vertical; keep that as a plain setting
		Direction = Enum.Direction.Vertical,
		SortOrder = partySettings.SortOrder,
		LoadConditionContentType = copy(partySettings.LoadConditionContentType),
		LoadConditionRole = copy(partySettings.LoadConditionRole),
		GlowType = partySettings.GlowType,
		GlowImportant = flag(flags, V3_FLAG.GlowImportant),
		OnlyImportant = flag(flags, V3_FLAG.OnlyImportant),
		IndicateInterrupts = flag(flags, V3_FLAG.IndicateInterrupts),
	}
end

-- TTS was mirrored across Self/Party by hand; hoist the Self copy to a single
-- global table and discard the Party duplicate.
---@param selfSettings SavedVariablesSettingsSelf
local function buildTextToSpeech(selfSettings)
	return {
		AnnounceUntargetedSpells = copy(selfSettings.AnnounceUntargetedSpells),
		AnnounceTargetedSpells = copy(selfSettings.AnnounceTargetedSpells),
		TextToSpeechVoice = selfSettings.TextToSpeechVoice,
	}
end

-- ── Ordered migration steps ──────────────────────────────────────────────────
-- migrationSteps[N] upgrades a schema at version N to N+1, mutating `saved` in
-- place and bumping saved.SchemaVersion. A missing SchemaVersion is treated as
-- v3 (the last unversioned shape).

local migrationSteps = {
	-- v3 → v4: two fixed Settings trees become an N-group model.
	[3] = function(saved)
		local settings = saved.Settings or {}
		local selfSettings = settings.Self or Private.Settings.GetSelfDefaultSettings()
		local partySettings = settings.Party or Private.Settings.GetPartyDefaultSettings()

		saved.Groups = {
			[1] = buildSelfGroup(selfSettings),
			[2] = buildPartyGroup(partySettings),
		}
		saved.TextToSpeech = buildTextToSpeech(selfSettings)
		saved.Settings = nil
		saved.SchemaVersion = 4
	end,
}

-- Migrates `saved` in place to the current schema version by applying the
-- ordered steps. Idempotent: a saved table already at (or past) the current
-- version is left untouched. Sole entry point.
---@param saved table
---@return table saved
function Private.Migration.Apply(saved)
	local version = saved.SchemaVersion or 3

	while version < CURRENT_SCHEMA_VERSION do
		local step = migrationSteps[version]
		assert(step, "Migration.Apply: no step from schema version " .. tostring(version))
		step(saved)
		local advanced = saved.SchemaVersion
		assert(
			advanced and advanced > version,
			"Migration.Apply: step did not advance schema version " .. tostring(version)
		)
		version = advanced
	end

	return saved
end

---@param saved table
---@return table saved
function Private.Migration.SeedFreshInstall(saved)
	saved.Groups = Private.Groups.CreateStarterGroups()
	saved.TextToSpeech = buildTextToSpeech(Private.Settings.GetSelfDefaultSettings())
	saved.SchemaVersion = CURRENT_SCHEMA_VERSION

	return saved
end

-- Gated test-only internals (never ships behaviour): the pure reconstruction and
-- filter derivation the snapshot / transform specs pin directly.
Private.__test = Private.__test or {}
Private.__test.Migration = {
	CURRENT_SCHEMA_VERSION = CURRENT_SCHEMA_VERSION,
	derivePartyFilter = derivePartyFilter,
	V3_FLAG = V3_FLAG,
	V3_FONT_FLAG = V3_FONT_FLAG,
}
