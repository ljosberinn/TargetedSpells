---@type string, TargetedSpells
local addonName, Private = ...

local Enum = Private.Enum

---@class TargetedSpellsDesign
Private.Design = {}

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

---@return table<FontFlags, boolean>
local function DefaultFontFlags()
	return {
		[Enum.FontFlags.OUTLINE] = true,
		[Enum.FontFlags.SHADOW] = false,
	}
end

local justifyHOptions = {
	{ value = "LEFT",   name = "JUSTIFY_LEFT" },
	{ value = "CENTER", name = "JUSTIFY_CENTER" },
	{ value = "RIGHT",  name = "JUSTIFY_RIGHT" },
}

local barColorModeOptions = {
	{ value = Enum.BarColorMode.Static,           name = "BAR_COLOR_STATIC" },
	{ value = Enum.BarColorMode.Interruptibility, name = "BAR_COLOR_INTERRUPTIBILITY" },
	{ value = Enum.BarColorMode.TargetClassColor, name = "BAR_COLOR_TARGET_CLASS" },
}

---@param opts table {active, width, height, x, y, omitActive, omitOffset}
---@return table[]
local function NonTextBase(opts)
	local records = {}

	if not opts.omitActive then
		records[#records + 1] = { setting = "active", name = "ELEMENT_ACTIVE", type = SettingType.Boolean, default = opts
		.active }
	end

	records[#records + 1] = { setting = "width", name = "ELEMENT_WIDTH", type = SettingType.Number, min = 1, max = 512, step = 1, default =
	opts.width }
	records[#records + 1] = { setting = "height", name = "ELEMENT_HEIGHT", type = SettingType.Number, min = 1, max = 512, step = 1, default =
	opts.height }

	if not opts.omitOffset then
		records[#records + 1] = { setting = "x", name = "ELEMENT_X", type = SettingType.Number, min = -512, max = 512, step = 1, default =
		opts.x or 0 }
		records[#records + 1] = { setting = "y", name = "ELEMENT_Y", type = SettingType.Number, min = -512, max = 512, step = 1, default =
		opts.y or 0 }
	end

	return records
end

---@param opts table {active, x, y, fontSize, justifyH, textColor, useClassColor}
---@return table[]
local function TextBase(opts)
	local records = {
		{ setting = "active",    name = "ELEMENT_ACTIVE",     type = SettingType.Boolean,   default = opts.active },
		{ setting = "x",         name = "ELEMENT_X",          type = SettingType.Number,    min = -512,                            max = 512,                        step = 1, default = opts.x or 0 },
		{ setting = "y",         name = "ELEMENT_Y",          type = SettingType.Number,    min = -512,                            max = 512,                        step = 1, default = opts.y or 0 },
		{ setting = "fontSize",  name = "ELEMENT_FONT_SIZE",  type = SettingType.Number,    min = 6,                               max = 64,                         step = 1, default = opts.fontSize },
		{ setting = "font",      name = "ELEMENT_FONT",       type = SettingType.Font,      default = opts.font or FRIZQT },
		{ setting = "fontFlags", name = "ELEMENT_FONT_FLAGS", type = SettingType.FontFlags, default = DefaultFontFlags() },
		{ setting = "textColor", name = "ELEMENT_TEXT_COLOR", type = SettingType.Color,     default = opts.textColor or "FFFFFFFF" },
		{ setting = "justifyH",  name = "ELEMENT_JUSTIFY_H",  type = SettingType.Enum,      options = justifyHOptions,             default = opts.justifyH or "LEFT" },
		{ setting = "maxWidth",  name = "ELEMENT_MAX_WIDTH",  type = SettingType.Number,    min = 0,                               max = 500,                        step = 1, default = opts.maxWidth or 0 },
	}

	-- "use class colour" companion toggle, only for elements that can honour it
	if opts.useClassColor ~= nil then
		table.insert(records,
			{ setting = "useClassColor", name = "ELEMENT_USE_CLASS_COLOR", type = SettingType.Boolean, default = opts
			.useClassColor })
	end

	return records
end

---@param fontSize number
---@return table[]
local function CountdownTextRecords(fontSize)
	return {
		{ setting = "countdownFontSize",  name = "ELEMENT_FONT_SIZE",          type = SettingType.Number,    min = 6,                     max = 64, step = 1, default = fontSize },
		{ setting = "countdownFont",      name = "ELEMENT_FONT",               type = SettingType.Font,      default = FRIZQT },
		{ setting = "countdownFontFlags", name = "ELEMENT_FONT_FLAGS",         type = SettingType.FontFlags, default = DefaultFontFlags() },
		{ setting = "fractionThreshold",  name = "ELEMENT_FRACTION_THRESHOLD", type = SettingType.Number,    min = 0,                     max = 30, step = 1, default = 3 },
	}
end

---@param target table[]
---@param source table[]
---@return nil
local function Append(target, source)
	for _, record in ipairs(source) do
		table.insert(target, record)
	end
end


---@return table<Element, table[]>
local function BuildIconSchema()
	local schema = {}

	-- core: XML-anchored, always active (no enable toggle), the 0,0 origin (no x/y)
	do
		local records = NonTextBase({ omitActive = true, omitOffset = true, width = 48, height = 48 })
		table.insert(records,
			{ setting = "iconZoom", name = "ELEMENT_ICON_ZOOM", type = SettingType.Number, min = 1, max = 2, step = 0.05, default = 1 })
		schema[Enum.Element.Icon] = records
	end

	-- decorative cooldown-manager bezel: expose `active` only, no position/size
	schema[Enum.Element.Overlay] = {
		{ setting = "active", name = "ELEMENT_ACTIVE", type = SettingType.Boolean, default = true },
	}

	-- swipe + countdown number; welded to the icon (setAllPoints), so no x/y/size.
	-- Both the radial swipe and the countdown number toggle independently.
	do
		local records = {
			{ setting = "showSwipe",     name = "ELEMENT_SHOW_SWIPE",     type = SettingType.Boolean, default = true },
			{ setting = "showCountdown", name = "ELEMENT_SHOW_COUNTDOWN", type = SettingType.Boolean, default = true },
		}
		Append(records, CountdownTextRecords(20))
		schema[Enum.Element.Cooldown] = records
	end

	schema[Enum.Element.InterruptSource] = TextBase({
		active = false,
		x = 0,
		y = 0,
		fontSize = 12,
		justifyH = "CENTER",
		useClassColor = true,
	})

	-- border enabled + texture (LSM) + color + size; anchored to the frame edges
	schema[Enum.Element.Border] = {
		{ setting = "active",        name = "ELEMENT_ACTIVE",         type = SettingType.Boolean, default = true },
		{ setting = "borderTexture", name = "ELEMENT_BORDER_TEXTURE", type = SettingType.Texture, mediaType = "border", default = "Blizzard Tooltip Border" },
		{ setting = "borderColor",   name = "ELEMENT_BORDER_COLOR",   type = SettingType.Color,   default = "FFFFFFFF" },
		{ setting = "borderSize",    name = "ELEMENT_BORDER_SIZE",    type = SettingType.Number,  min = 1,              max = 32,                           step = 1, default = 8 },
	}

	return schema
end

-- ── Bar template schema ──────────────────────────────────────────────────────

---@return table<Element, table[]>
local function BuildBarSchema()
	local schema = {}

	-- core: the total footprint (marker + icon gutter + bar). Always active (no toggle),
	-- no x/y. The renderer (ComputeBarLayout) packs the active gutter elements against the
	-- left and lets the ProgressBar fill the rest, so this width is the whole 300 assembly
	-- and the visible bar is 300 − gutter (270 with the default icon, 240 with the marker too).
	do
		local records = NonTextBase({ omitActive = true, omitOffset = true, width = 300, height = 30 })
		Append(records, {
			{ setting = "barTexture",           name = "ELEMENT_BAR_TEXTURE",           type = SettingType.Texture, mediaType = "statusbar",       default = "Blizzard Raid Bar" },
			{ setting = "barColorMode",         name = "ELEMENT_BAR_COLOR_MODE",        type = SettingType.Enum,    options = barColorModeOptions, default = Enum.BarColorMode.Interruptibility },
			{ setting = "progressBarColor",     name = "ELEMENT_BAR_COLOR",             type = SettingType.Color,   default = "FFFFFF00" },
			{ setting = "interruptibleColor",   name = "ELEMENT_INTERRUPTIBLE_COLOR",   type = SettingType.Color,   default = "FF44FF44" },
			{ setting = "uninterruptibleColor", name = "ELEMENT_UNINTERRUPTIBLE_COLOR", type = SettingType.Color,   default = "FFFF4444" },
		})
		schema[Enum.Element.ProgressBar] = records
	end

	-- fill behind the bar; welded to the progress bar, so texture + color only
	schema[Enum.Element.Background] = {
		{ setting = "active",            name = "ELEMENT_ACTIVE",             type = SettingType.Boolean, default = true },
		{ setting = "backgroundTexture", name = "ELEMENT_BACKGROUND_TEXTURE", type = SettingType.Texture, mediaType = "background", default = "Solid" },
		{ setting = "backgroundColor",   name = "ELEMENT_BACKGROUND_COLOR",   type = SettingType.Color,   default = "FF1A1A1A" },
	}

	-- gutter elements: packed against the frame's left edge in the order [TargetMarker][Icon]
	-- (the renderer, not x, decides the slot; x/y here are just a fine nudge). 30 wide each,
	-- so an active one carves 30 off the bar's left. TargetMarker seeds off (opt-in).
	schema[Enum.Element.Icon] = NonTextBase({ active = true, width = 30, height = 30, x = 0, y = 0 })

	schema[Enum.Element.TargetMarker] = NonTextBase({ active = false, width = 30, height = 30, x = 0, y = 0 })

	-- countdown-only cooldown (bar swipe is disabled): position/size + countdown. Right-hugging
	-- box: x is an inset from the bar's (fixed) right edge, 0 = flush. The `active` toggle
	-- shows/hides the whole region and its number together — no separate "show countdown".
	do
		local records = NonTextBase({ active = true, width = 30, height = 30, x = 0, y = 0 })
		Append(records, CountdownTextRecords(14))
		schema[Enum.Element.DurationCooldown] = records
	end

	-- Text hangs off the reflowing bar: x is an inset from the justifyH-pinned edge (LEFT →
	-- from the bar's left edge, which moves with the gutter; RIGHT → from the fixed right
	-- edge). maxWidths are sized so SpellName and TargetName never meet even in the narrowest
	-- (both-gutter, 240-wide) bar: SpellName's right reaches at most +25, TargetName's left is
	-- a fixed +35. TargetName also stops left of the Duration (~+120).

	-- LEFT: left edge 5px inside the bar's left edge; grows right toward the target name.
	schema[Enum.Element.SpellName] = TextBase({
		active = true,
		x = 5,
		y = 0,
		fontSize = 14,
		justifyH = "LEFT",
		maxWidth = 110,
	})

	-- RIGHT: right edge 40px inside the bar's right edge (clearing the Duration); grows left.
	schema[Enum.Element.TargetName] = TextBase({
		active = true,
		x = -40,
		y = 0,
		fontSize = 14,
		justifyH = "RIGHT",
		useClassColor = true,
		maxWidth = 75,
	})

	-- On interrupt the duration is cleared and SpellName is hidden, freeing the whole bar,
	-- so the interrupter name right-aligns near the bar's end (5px inside) and grows left.
	-- maxWidth clamps it so a long name can't run onto the gutter.
	schema[Enum.Element.InterruptSource] = TextBase({
		active = false,
		x = -5,
		y = 0,
		fontSize = 14,
		justifyH = "RIGHT",
		useClassColor = true,
		maxWidth = 200,
	})

	-- native shield shown only while the cast is NOT interruptible (the renderer drives
	-- its visibility from the secret interruptibility boolean). Right-hugging box: x is an
	-- inset from the bar's right edge, seated just left of the Duration. `active` is the
	-- plain on/off toggle; seeds off so it's opt-in and doesn't change existing displays.
	schema[Enum.Element.InterruptShield] = NonTextBase({ active = false, width = 24, height = 24, x = -35, y = 0 })

	-- border wrapping the bar: enabled + texture (LSM) + color + size, same fragment
	-- as the icon's Border. Seeds off (opt-in) — bars never had a border before, so
	-- BackfillElements must not add one to existing displays.
	schema[Enum.Element.Border] = {
		{ setting = "active",        name = "ELEMENT_ACTIVE",         type = SettingType.Boolean, default = false },
		{ setting = "borderTexture", name = "ELEMENT_BORDER_TEXTURE", type = SettingType.Texture, mediaType = "border", default = "Blizzard Tooltip Border" },
		{ setting = "borderColor",   name = "ELEMENT_BORDER_COLOR",   type = SettingType.Color,   default = "FFFFFFFF" },
		{ setting = "borderSize",    name = "ELEMENT_BORDER_SIZE",    type = SettingType.Number,  min = 1,              max = 32,                           step = 1, default = 8 },
	}

	return schema
end

-- ── Icon+Duration template schema ────────────────────────────────────────────
-- [Icon][Duration][Icon]. There is exactly ONE Icon element and it drives both cells —
-- that is what makes the designer expose a single icon whose edits mirror. Everything the
-- Icon template offers except InterruptSource carries over; the cooldown's swipe and
-- countdown seed OFF here, since the duration text is the point of the template and the
-- icons repeating it would be noise.

---@return table<Element, table[]>
local function BuildIconDurationSchema()
	local schema = {}

	-- core: sizes BOTH cells (never one). Always active, and the 0,0 origin, so no
	-- toggle and no x/y — same treatment as the other templates' cores. Smaller than the
	-- icon template's 48: two of them plus the countdown sit side by side, and the zoom
	-- crops the art's dead border so the smaller icon still reads at a glance.
	do
		local records = NonTextBase({ omitActive = true, omitOffset = true, width = 32, height = 32 })
		table.insert(records, { setting = "iconZoom", name = "ELEMENT_ICON_ZOOM", type = SettingType.Number, min = 1, max = 2, step = 0.05, default = 1.35 })
		schema[Enum.Element.Icon] = records
	end

	schema[Enum.Element.Overlay] = {
		{ setting = "active", name = "ELEMENT_ACTIVE", type = SettingType.Boolean, default = true },
	}

	-- both seed false: the duration text already shows the remaining cast, so the icons
	-- default to plain. The font records still apply if a user turns the countdown back on.
	do
		local records = {
			{ setting = "showSwipe",     name = "ELEMENT_SHOW_SWIPE",     type = SettingType.Boolean, default = false },
			{ setting = "showCountdown", name = "ELEMENT_SHOW_COUNTDOWN", type = SettingType.Boolean, default = false },
		}
		Append(records, CountdownTextRecords(20))
		schema[Enum.Element.Cooldown] = records
	end

	-- the centre text. No width/height: the slot is derived from the font size
	-- (Utils.ComputeIconDurationLayout) rather than configured, and `gap` is the clearance
	-- between the text slot and each icon. No `active` — a template whose text can be
	-- switched off is just the Icon template.
	do
		local records = {
			{ setting = "gap", name = "ELEMENT_GAP", type = SettingType.Number, min = 0,    max = 128, step = 1, default = 4 },
			{ setting = "y",   name = "ELEMENT_Y",   type = SettingType.Number, min = -512, max = 512, step = 1, default = 0 },
		}
		Append(records, CountdownTextRecords(20))
		schema[Enum.Element.Duration] = records
	end

	schema[Enum.Element.Border] = {
		{ setting = "active",        name = "ELEMENT_ACTIVE",         type = SettingType.Boolean, default = true },
		{ setting = "borderTexture", name = "ELEMENT_BORDER_TEXTURE", type = SettingType.Texture, mediaType = "border", default = "Blizzard Tooltip Border" },
		{ setting = "borderColor",   name = "ELEMENT_BORDER_COLOR",   type = SettingType.Color,   default = "FFFFFFFF" },
		{ setting = "borderSize",    name = "ELEMENT_BORDER_SIZE",    type = SettingType.Number,  min = 1,              max = 32,                           step = 1, default = 8 },
	}

	return schema
end

-- ── Assembled schemas + derived defaults ─────────────────────────────────────

local schemasByTemplate = {
	[Enum.Template.Icon] = BuildIconSchema(),
	[Enum.Template.Bar] = BuildBarSchema(),
	[Enum.Template.IconDuration] = BuildIconDurationSchema(),
}

---@param schema table<Element, table[]>
---@return table<Element, table<string, any>>
local function BuildDefaults(schema)
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
	[Enum.Template.Icon] = BuildDefaults(schemasByTemplate[Enum.Template.Icon]),
	[Enum.Template.Bar] = BuildDefaults(schemasByTemplate[Enum.Template.Bar]),
	[Enum.Template.IconDuration] = BuildDefaults(schemasByTemplate[Enum.Template.IconDuration]),
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

-- Fills any schema fields missing from a group's `Elements` with the template
-- default, never overwriting an existing value. Runs on load so groups created
-- before a field was added — dev iteration, or a future v4.x schema addition —
-- pick it up (the v3→v4 migration runs only once, so it can't). Idempotent.
---@param group TargetedSpellsGroup
function Private.Design.BackfillElements(group)
	local schema = schemasByTemplate[group.Template]
	if schema == nil then
		return
	end

	group.Elements = group.Elements or {}

	-- mutates the table in place, so any memoised bar layout for it is now stale
	Private.Utils.InvalidateLayout(group.Elements)

	for element, records in pairs(schema) do
		local values = group.Elements[element]
		if values == nil then
			values = {}
			group.Elements[element] = values
		end

		for _, record in ipairs(records) do
			if values[record.setting] == nil then
				values[record.setting] = Private.Utils.DeepCopy(record.default)
			end
		end
	end
end
