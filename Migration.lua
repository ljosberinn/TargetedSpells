---@type string, TargetedSpells
local addonName, Private = ...

-- Migration.lua ───────────────────────────────────────────────────────────────
-- v3 → v4 SavedVariables rewrite. v4 replaces the two fixed Settings.Self /
-- Settings.Party trees with an N-group model (see the v4 plan). This is a
-- one-way rewrite; downgrade to v3 is out of scope, so no v3 backup is kept.
--
-- Public surface:
--   Private.Migration.Apply(saved) -- migrate a saved table in place to v4
-- Everything else stays file-local. The bar-offset reconstruction and the
-- filter derivation are additionally exposed under Private.__test for the
-- (gated, spec-only) snapshot + transform tests; they ship no behaviour.
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

-- ── Bar-offset reconstruction (challenge #2's input; the riskiest piece) ──────
-- Replays TargetedSpellsBarMixin:OnSizeChanged against a user's saved
-- Width/Height/FontSize + flag combination to produce explicit CENTER→CENTER
-- offsets from the ProgressBar (the bar's core element), with no live frame.
--
-- Pure: reads only the geometry inputs, exactly like the old OnSizeChanged and
-- its width helpers (GetProgressBarWidth / GetDurationWidth). The non-text boxes
-- (ProgressBar, Icon, TargetMarker, DurationCooldown) are reconstructed
-- pixel-faithfully; text elements (SpellName/TargetName/InterruptSource) get a
-- best-effort center only — v4 text auto-sizes and cannot reproduce v3's
-- edge-anchored, width-split boxes (decided). Mirror flips every x offset.
--
---@param opts { width:number, height:number, fontSize:number, showIcon:boolean, showTargetMarker:boolean, showDuration:boolean, inlineDuration:boolean, mirrored:boolean, showSpellName:boolean, showTargetName:boolean }
---@return table<Element, table<string, number>>
local function reconstructBarGeometry(opts)
	local width = opts.width
	local height = opts.height
	local durationWidth = opts.fontSize * 2

	local markerInset = opts.showTargetMarker and height or 0
	local iconInset = opts.showIcon and height or 0
	local durationInset = (opts.showDuration and not opts.inlineDuration) and durationWidth or 0

	local progressBarWidth = width - markerInset - iconInset - durationInset

	-- fromLeft coordinates: 0 at the bar's left edge, `width` at its right edge.
	local progressBarLeft = markerInset + iconInset
	local progressBarRight = width - durationInset
	local progressBarCenter = (progressBarLeft + progressBarRight) / 2

	-- non-text box centers, laid out left→right: [marker][icon][progressbar][dur]
	local markerCenter = height / 2
	local iconCenter = markerInset + height / 2

	local durationCenter
	if opts.inlineDuration then
		-- inline duration sits inside the bar's right edge (x = -4), width unchanged
		durationCenter = (width - 4) - durationWidth / 2
	else
		durationCenter = width - durationWidth / 2
	end

	-- best-effort text-box centers (v3 width-split; not pixel-guaranteed in v4)
	local textWidth = (opts.showDuration and opts.inlineDuration) and (progressBarWidth - durationWidth) or progressBarWidth
	local spellCenter, targetCenter
	if opts.showSpellName and opts.showTargetName then
		spellCenter = progressBarLeft + 4 + textWidth / 4
		local targetRight = opts.inlineDuration and (progressBarRight - 4 - durationWidth) or (progressBarRight - 4)
		targetCenter = targetRight - textWidth / 4
	else
		spellCenter = progressBarLeft + 4 + textWidth / 2
		targetCenter = progressBarLeft + 4 + textWidth / 2
	end
	-- interrupt source was left-anchored and variable-length; center it on the bar
	local interruptCenter = progressBarCenter

	local sign = opts.mirrored and -1 or 1
	local function offsetX(center)
		return sign * (center - progressBarCenter)
	end

	return {
		[Element.ProgressBar] = { x = 0, y = 0, width = progressBarWidth, height = height },
		[Element.Icon] = { x = offsetX(iconCenter), y = 0, width = height, height = height },
		[Element.TargetMarker] = { x = offsetX(markerCenter), y = 0, width = height, height = height },
		[Element.DurationCooldown] = { x = offsetX(durationCenter), y = 0, width = durationWidth, height = height },
		[Element.SpellName] = { x = offsetX(spellCenter), y = 0 },
		[Element.TargetName] = { x = offsetX(targetCenter), y = 0 },
		[Element.InterruptSource] = { x = offsetX(interruptCenter), y = 0 },
	}
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
	local elements = Private.Design.GetDefault(Template.Bar)
	local flags = partySettings.FeatureFlags
	local fontFlags = copy(partySettings.FontFlags)
	local mirrored = flag(flags, V3_FLAG.MirrorLayout)

	local geometry = reconstructBarGeometry({
		width = partySettings.Width,
		height = partySettings.Height,
		fontSize = partySettings.FontSize,
		showIcon = flag(flags, V3_FLAG.ShowIcon),
		showTargetMarker = flag(flags, V3_FLAG.ShowTargetMarker),
		showDuration = flag(flags, V3_FLAG.ShowDuration),
		inlineDuration = flag(flags, V3_FLAG.InlineDuration),
		mirrored = mirrored,
		showSpellName = flag(flags, V3_FLAG.ShowSpellName),
		showTargetName = flag(flags, V3_FLAG.ShowTargetName),
	})

	-- fold the reconstructed geometry onto the default elements
	for element, values in pairs(geometry) do
		for key, value in pairs(values) do
			elements[element][key] = value
		end
	end

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
	spellName.justifyH = mirrored and "RIGHT" or "LEFT"

	local targetName = elements[Element.TargetName]
	targetName.active = flag(flags, V3_FLAG.ShowTargetName)
	targetName.useClassColor = flag(flags, V3_FLAG.ShowTargetClassColor)
	targetName.fontSize = partySettings.FontSize
	targetName.font = partySettings.Font
	targetName.fontFlags = copy(fontFlags)
	targetName.justifyH = mirrored and "LEFT" or "RIGHT"

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
		saved.NextGroupId = 3
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

-- Gated test-only internals (never ships behaviour): the pure reconstruction and
-- filter derivation the snapshot / transform specs pin directly.
Private.__test = Private.__test or {}
Private.__test.Migration = {
	CURRENT_SCHEMA_VERSION = CURRENT_SCHEMA_VERSION,
	reconstructBarGeometry = reconstructBarGeometry,
	derivePartyFilter = derivePartyFilter,
	V3_FLAG = V3_FLAG,
	V3_FONT_FLAG = V3_FONT_FLAG,
}
