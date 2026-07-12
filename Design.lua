---@type string, TargetedSpells
local addonName, Private = ...

-- Design.lua ──────────────────────────────────────────────────────────────────
-- The v4 element model: per-template schema (which widgets an element exposes)
-- and per-template default `Elements` tables (code constants, never stored).
--
-- A "Design" is not a shared, separately-managed entity — a group owns its
-- `Template` + `Elements` 1:1. This module holds only template *schemas +
-- defaults*: the seed for a new group and the source for every "reset to
-- defaults" / template-swap. There are no user Design records to look up.
--
-- Public surface (kept deliberately small):
--   Private.Design.GetDefault(template) -> fresh Elements table for a template
--   Private.Design.GetSchema(template)  -> ordered element -> record schema
--   Private.Design.CopyElements(tbl)    -> deep copy (scratch copy / copy-from)
-- Everything below stays file-local.

local Enum = Private.Enum

---@class TargetedSpellsDesign
Private.Design = {}

-- Widget/setting types a schema record can request. Mirrors Blizzard's
-- systemSettingDisplayInfo `type` field; the designer switches on these strings
-- to pick a widget (slider / dropdown / checkbox / color swatch) in Phase 5.
local SettingType = {
	Boolean = "boolean",
	Number = "number",
	Color = "color",
	Enum = "enum",
	Font = "font",
	FontFlags = "fontFlags",
	Texture = "texture", -- LibSharedMedia dropdown (statusbar / border / background)
}

local FRIZQT = "Fonts\\FRIZQT__.TTF"

-- default font-flag set, matching today's global default (OUTLINE on, SHADOW off)
local function defaultFontFlags()
	return {
		[Enum.FontFlags.OUTLINE] = true,
		[Enum.FontFlags.SHADOW] = false,
	}
end

local justifyHOptions = {
	{ value = "LEFT", name = "JUSTIFY_LEFT" },
	{ value = "CENTER", name = "JUSTIFY_CENTER" },
	{ value = "RIGHT", name = "JUSTIFY_RIGHT" },
}

local barColorModeOptions = {
	{ value = Enum.BarColorMode.Static, name = "BAR_COLOR_STATIC" },
	{ value = Enum.BarColorMode.Interruptibility, name = "BAR_COLOR_INTERRUPTIBILITY" },
	{ value = Enum.BarColorMode.TargetClassColor, name = "BAR_COLOR_TARGET_CLASS" },
}

-- ── Shared schema fragments ──────────────────────────────────────────────────
-- Each fragment builder returns a *fresh* ordered array of records so composed
-- element schemas never share mutable record tables. A record lists only fields
-- the element can actually honour; there are no shown-but-ignored keys.

---@param opts table {active, width, height, x, y, drawLayer}
local function nonTextBase(opts)
	return {
		{ setting = "active", name = "ELEMENT_ACTIVE", type = SettingType.Boolean, default = opts.active },
		{ setting = "width", name = "ELEMENT_WIDTH", type = SettingType.Number, min = 1, max = 512, step = 1, default = opts.width },
		{ setting = "height", name = "ELEMENT_HEIGHT", type = SettingType.Number, min = 1, max = 512, step = 1, default = opts.height },
		{ setting = "x", name = "ELEMENT_X", type = SettingType.Number, min = -512, max = 512, step = 1, default = opts.x or 0 },
		{ setting = "y", name = "ELEMENT_Y", type = SettingType.Number, min = -512, max = 512, step = 1, default = opts.y or 0 },
		{ setting = "drawLayer", name = "ELEMENT_DRAW_LAYER", type = SettingType.Number, min = 0, max = 20, step = 1, default = opts.drawLayer },
	}
end

-- Auto-sizing text: no width/height. `maxWidth` (0 = unconstrained) caps
-- horizontal growth and truncates with a native ellipsis when exceeded.
---@param opts table {active, x, y, drawLayer, fontSize, justifyH, textColor, useClassColor}
local function textBase(opts)
	local records = {
		{ setting = "active", name = "ELEMENT_ACTIVE", type = SettingType.Boolean, default = opts.active },
		{ setting = "x", name = "ELEMENT_X", type = SettingType.Number, min = -512, max = 512, step = 1, default = opts.x or 0 },
		{ setting = "y", name = "ELEMENT_Y", type = SettingType.Number, min = -512, max = 512, step = 1, default = opts.y or 0 },
		{ setting = "drawLayer", name = "ELEMENT_DRAW_LAYER", type = SettingType.Number, min = 0, max = 20, step = 1, default = opts.drawLayer },
		{ setting = "fontSize", name = "ELEMENT_FONT_SIZE", type = SettingType.Number, min = 6, max = 64, step = 1, default = opts.fontSize },
		{ setting = "font", name = "ELEMENT_FONT", type = SettingType.Font, default = opts.font or FRIZQT },
		{ setting = "fontFlags", name = "ELEMENT_FONT_FLAGS", type = SettingType.FontFlags, default = defaultFontFlags() },
		{ setting = "textColor", name = "ELEMENT_TEXT_COLOR", type = SettingType.Color, default = opts.textColor or "FFFFFFFF" },
		{ setting = "justifyH", name = "ELEMENT_JUSTIFY_H", type = SettingType.Enum, options = justifyHOptions, default = opts.justifyH or "LEFT" },
		{ setting = "maxWidth", name = "ELEMENT_MAX_WIDTH", type = SettingType.Number, min = 0, max = 1024, step = 1, default = opts.maxWidth or 0 },
	}

	-- "use class colour" companion toggle, only for elements that can honour it
	if opts.useClassColor ~= nil then
		table.insert(records, { setting = "useClassColor", name = "ELEMENT_USE_CLASS_COLOR", type = SettingType.Boolean, default = opts.useClassColor })
	end

	return records
end

-- Countdown-number font records shared by both cooldown composites (icon
-- Cooldown and bar DurationCooldown). The number is drawn centered on the
-- cooldown frame, so it gets font styling but no x/y/justifyH.
---@param fontSize number
local function countdownTextRecords(fontSize)
	return {
		{ setting = "countdownFontSize", name = "ELEMENT_FONT_SIZE", type = SettingType.Number, min = 6, max = 64, step = 1, default = fontSize },
		{ setting = "countdownFont", name = "ELEMENT_FONT", type = SettingType.Font, default = FRIZQT },
		{ setting = "countdownFontFlags", name = "ELEMENT_FONT_FLAGS", type = SettingType.FontFlags, default = defaultFontFlags() },
	}
end

-- appends every record of `source` onto `target`, in order
local function append(target, source)
	for _, record in ipairs(source) do
		table.insert(target, record)
	end
end

-- ── Icon template schema ─────────────────────────────────────────────────────

local function buildIconSchema()
	local schema = {}

	-- core: XML-anchored, always active, sits at x=y=0 by definition
	do
		local records = nonTextBase({ active = true, width = 48, height = 48, x = 0, y = 0, drawLayer = 1 })
		table.insert(records, { setting = "iconZoom", name = "ELEMENT_ICON_ZOOM", type = SettingType.Number, min = 1, max = 2, step = 0.05, default = 1 })
		schema[Enum.Element.Icon] = records
	end

	-- decorative cooldown-manager bezel: expose `active` only, no position/size
	schema[Enum.Element.Overlay] = {
		{ setting = "active", name = "ELEMENT_ACTIVE", type = SettingType.Boolean, default = true },
	}

	-- swipe + countdown; welded to the icon (setAllPoints), so no x/y/size
	do
		local records = {
			{ setting = "showSwipe", name = "ELEMENT_SHOW_SWIPE", type = SettingType.Boolean, default = true },
			{ setting = "showCountdown", name = "ELEMENT_SHOW_COUNTDOWN", type = SettingType.Boolean, default = true },
			{ setting = "drawLayer", name = "ELEMENT_DRAW_LAYER", type = SettingType.Number, min = 0, max = 20, step = 1, default = 4 },
		}
		append(records, countdownTextRecords(20))
		schema[Enum.Element.Cooldown] = records
	end

	schema[Enum.Element.InterruptSource] = textBase({
		active = false,
		x = 0,
		y = 0,
		drawLayer = 5,
		fontSize = 12,
		justifyH = "CENTER",
		useClassColor = true,
	})

	-- border enabled + texture (LSM) + color + size; anchored to the frame edges
	schema[Enum.Element.Border] = {
		{ setting = "active", name = "ELEMENT_ACTIVE", type = SettingType.Boolean, default = true },
		{ setting = "borderTexture", name = "ELEMENT_BORDER_TEXTURE", type = SettingType.Texture, default = "Blizzard Tooltip Border" },
		{ setting = "borderColor", name = "ELEMENT_BORDER_COLOR", type = SettingType.Color, default = "FFFFFFFF" },
		{ setting = "borderSize", name = "ELEMENT_BORDER_SIZE", type = SettingType.Number, min = 1, max = 32, step = 1, default = 1 },
		{ setting = "drawLayer", name = "ELEMENT_DRAW_LAYER", type = SettingType.Number, min = 0, max = 20, step = 1, default = 3 },
	}

	return schema
end

-- ── Bar template schema ──────────────────────────────────────────────────────

local function buildBarSchema()
	local schema = {}

	-- core: the old container Width/Height live here now
	do
		local records = nonTextBase({ active = true, width = 300, height = 30, x = 0, y = 0, drawLayer = 1 })
		append(records, {
			{ setting = "barTexture", name = "ELEMENT_BAR_TEXTURE", type = SettingType.Texture, default = "Blizzard Raid Bar" },
			{ setting = "barColorMode", name = "ELEMENT_BAR_COLOR_MODE", type = SettingType.Enum, options = barColorModeOptions, default = Enum.BarColorMode.Interruptibility },
			{ setting = "progressBarColor", name = "ELEMENT_BAR_COLOR", type = SettingType.Color, default = "FFFFFF00" },
			{ setting = "interruptibleColor", name = "ELEMENT_INTERRUPTIBLE_COLOR", type = SettingType.Color, default = "FF44FF44" },
			{ setting = "uninterruptibleColor", name = "ELEMENT_UNINTERRUPTIBLE_COLOR", type = SettingType.Color, default = "FFFF4444" },
		})
		schema[Enum.Element.ProgressBar] = records
	end

	-- fill behind the bar; welded to the progress bar, so texture + color only
	schema[Enum.Element.Background] = {
		{ setting = "active", name = "ELEMENT_ACTIVE", type = SettingType.Boolean, default = true },
		{ setting = "backgroundTexture", name = "ELEMENT_BACKGROUND_TEXTURE", type = SettingType.Texture, default = "Solid" },
		{ setting = "backgroundColor", name = "ELEMENT_BACKGROUND_COLOR", type = SettingType.Color, default = "FF1A1A1A" },
		{ setting = "drawLayer", name = "ELEMENT_DRAW_LAYER", type = SettingType.Number, min = 0, max = 20, step = 1, default = 0 },
	}

	schema[Enum.Element.Icon] = nonTextBase({ active = true, width = 30, height = 30, x = -135, y = 0, drawLayer = 2 })

	schema[Enum.Element.TargetMarker] = nonTextBase({ active = false, width = 20, height = 20, x = 0, y = 0, drawLayer = 4 })

	-- countdown-only cooldown (bar swipe is disabled): position/size + countdown
	do
		local records = nonTextBase({ active = true, width = 30, height = 30, x = 135, y = 0, drawLayer = 3 })
		table.insert(records, { setting = "showCountdown", name = "ELEMENT_SHOW_COUNTDOWN", type = SettingType.Boolean, default = true })
		append(records, countdownTextRecords(14))
		schema[Enum.Element.DurationCooldown] = records
	end

	schema[Enum.Element.SpellName] = textBase({
		active = true,
		x = -60,
		y = 0,
		drawLayer = 3,
		fontSize = 14,
		justifyH = "LEFT",
	})

	schema[Enum.Element.TargetName] = textBase({
		active = true,
		x = 60,
		y = 0,
		drawLayer = 3,
		fontSize = 14,
		justifyH = "RIGHT",
		useClassColor = true,
	})

	schema[Enum.Element.InterruptSource] = textBase({
		active = true,
		x = 0,
		y = 0,
		drawLayer = 4,
		fontSize = 14,
		justifyH = "LEFT",
		useClassColor = true,
	})

	-- new; `active` is gated on bar color mode TargetClassColor by the renderer,
	-- so it seeds off (default color mode is Interruptibility)
	schema[Enum.Element.InterruptShield] = nonTextBase({ active = false, width = 16, height = 16, x = 0, y = 0, drawLayer = 4 })

	return schema
end

-- ── Assembled schemas + derived defaults ─────────────────────────────────────

local schemasByTemplate = {
	[Enum.Template.Icon] = buildIconSchema(),
	[Enum.Template.Bar] = buildBarSchema(),
}

-- The per-template default `Elements` table is derived once from the schema by
-- reading each record's `default`. Single source of truth: a field cannot exist
-- in the defaults without a schema record describing its widget.
local function buildDefaults(schema)
	local elements = {}
	for element, records in pairs(schema) do
		local values = {}
		for _, record in ipairs(records) do
			values[record.setting] = Private.Utils.DeepCopy(record.default)
		end
		elements[element] = values
	end
	return elements
end

local defaultsByTemplate = {
	[Enum.Template.Icon] = buildDefaults(schemasByTemplate[Enum.Template.Icon]),
	[Enum.Template.Bar] = buildDefaults(schemasByTemplate[Enum.Template.Bar]),
}

-- ── Public entry points ──────────────────────────────────────────────────────

-- Returns a *fresh* default `Elements` table for a template — the seed for a new
-- group and the source for "reset to defaults" / template-swap. Never returns the
-- shared constant, so callers may mutate freely.
---@param template TargetedSpellsTemplate
---@return table<Element, table<string, any>>
function Private.Design.GetDefault(template)
	local defaults = defaultsByTemplate[template]
	assert(defaults, "Design.GetDefault: unknown template " .. tostring(template))
	return Private.Utils.DeepCopy(defaults)
end

-- Returns the ordered element -> record schema for a template. Read-only; the
-- designer walks this to build its widget panel. Do not mutate.
---@param template TargetedSpellsTemplate
---@return table<Element, table[]>
function Private.Design.GetSchema(template)
	local schema = schemasByTemplate[template]
	assert(schema, "Design.GetSchema: unknown template " .. tostring(template))
	return schema
end

-- Deep-copies an `Elements` table. Backs the designer's scratch copy and the
-- "copy layout from group" action; a pure copy with no persistent link.
---@param elements table
---@return table
function Private.Design.CopyElements(elements)
	return Private.Utils.DeepCopy(elements)
end
