---@type string, TargetedSpells
local addonName, Private = ...
local LibSharedMedia = LibStub("LibSharedMedia-3.0")

---@class TargetedSpellsSettings
Private.Settings = {}

Private.Settings.Keys = {
	Self = {
		Enabled = "ENABLED_SELF",
		LoadConditionContentType = "LOAD_CONDITION_CONTENT_TYPE_SELF",
		LoadConditionRole = "LOAD_CONDITION_ROLE_SELF",
		Width = "FRAME_WIDTH_SELF",
		Height = "FRAME_HEIGHT_SELF",
		FontSize = "FONT_SIZE_SELF",
		Gap = "FRAME_GAP_SELF",
		Direction = "GROW_DIRECTION_SELF",
		SortOrder = "FRAME_SORT_ORDER_SELF",
		GlowType = "GLOW_TYPE_SELF",
		Grow = "FRAME_GROW_SELF",
		MaxItems = "MAX_ITEMS_SELF",
		Filter = "FILTER_SELF",
		Template = "TEMPLATE_SELF",
		Name = "NAME_SELF",
		IconZoom = "ICON_ZOOM_SELF",
		Import = "IMPORT_SELF",
		Export = "EXPORT_SELF",
		Font = "FONT_SELF",
		FontFlags = "FONT_FLAGS_SELF",
		FeatureFlags = "FEATURE_FLAGS_SELF",
		BorderStyle = "BORDER_STYLE_SELF",
		AnnounceUntargetedSpells = "ANNOUNCE_UNTARGETED_SPELLS_SELF",
		AnnounceTargetedSpells = "ANNOUNCE_TARGETED_SPELLS_SELF",
		TextToSpeechVoice = "TTS_VOICE_SELF",
	},
	Party = {
		Enabled = "ENABLED_PARTY",
		LoadConditionContentType = "LOAD_CONDITION_CONTENT_TYPE_PARTY",
		LoadConditionRole = "LOAD_CONDITION_ROLE_PARTY",
		Width = "FRAME_WIDTH_PARTY",
		Height = "FRAME_HEIGHT_PARTY",
		FontSize = "FONT_SIZE_PARTY",
		Gap = "FRAME_GAP_PARTY",
		Direction = "GROW_DIRECTION_PARTY",
		SortOrder = "FRAME_SORT_ORDER_PARTY",
		GlowType = "GLOW_TYPE_PARTY",
		Grow = "FRAME_GROW_PARTY",
		MaxItems = "MAX_ITEMS_PARTY",
		Filter = "FILTER_PARTY",
		Template = "TEMPLATE_PARTY",
		Name = "NAME_PARTY",
		ForegroundBarTexture = "FOREGROUND_BAR_TEXTURE_PARTY",
		BackgroundBarTexture = "BACKGROUND_BAR_TEXTURE_PARTY",
		BackgroundBarColor = "BACKGROUND_BAR_COLOR_PARTY",
		ProgressBarColor = "PROGRESS_BAR_COLOR_PARTY",
		UseInterruptabilityColors = "USE_INTERRUPTABILITY_COLORS_PARTY",
		UseTargetClassColor = "USE_TARGET_CLASS_COLOR_PARTY",
		UninterruptibleColor = "UNINTERRUPTIBLE_COLOR_PARTY",
		InterruptibleColor = "INTERRUPTIBLE_COLOR_PARTY",
		Import = "IMPORT_PARTY",
		Export = "EXPORT_PARTY",
		Font = "FONT_PARTY",
		FontFlags = "FONT_FLAGS_PARTY",
		FeatureFlags = "FEATURE_FLAGS_PARTY",
		AnnounceUntargetedSpells = "ANNOUNCE_UNTARGETED_SPELLS_PARTY",
		AnnounceTargetedSpells = "ANNOUNCE_TARGETED_SPELLS_PARTY",
		TextToSpeechVoice = "TTS_VOICE_PARTY",
	},
}

function Private.Settings.GetSettingsDisplayOrder(kind)
	if kind == Private.Enum.FrameKind.Self then
		return {
			Private.Settings.Keys.Self.Enabled,
			Private.Settings.Keys.Self.LoadConditionContentType,
			Private.Settings.Keys.Self.LoadConditionRole,
			Private.Settings.Keys.Self.Width,
			Private.Settings.Keys.Self.Height,
			Private.Settings.Keys.Self.Gap,
			Private.Settings.Keys.Self.Direction,
			Private.Settings.Keys.Self.SortOrder,
			Private.Settings.Keys.Self.Grow,
			Private.Settings.Keys.Self.GlowType,
			Private.Settings.Keys.Self.FeatureFlags,
			Private.Settings.Keys.Self.BorderStyle,
			Private.Settings.Keys.Self.Font,
			Private.Settings.Keys.Self.FontSize,
			Private.Settings.Keys.Self.FontFlags,
			Private.Settings.Keys.Self.IconZoom,
			Private.Settings.Keys.Self.AnnounceUntargetedSpells,
			Private.Settings.Keys.Self.AnnounceTargetedSpells,
			Private.Settings.Keys.Self.TextToSpeechVoice,
		}
	end

	return {
		Private.Settings.Keys.Party.Enabled,
		Private.Settings.Keys.Party.LoadConditionContentType,
		Private.Settings.Keys.Party.LoadConditionRole,
		Private.Settings.Keys.Party.Width,
		Private.Settings.Keys.Party.Height,
		Private.Settings.Keys.Party.Gap,
		Private.Settings.Keys.Party.SortOrder,
		Private.Settings.Keys.Party.Grow,
		Private.Settings.Keys.Party.GlowType,
		Private.Settings.Keys.Party.FeatureFlags,
		Private.Settings.Keys.Party.Font,
		Private.Settings.Keys.Party.FontSize,
		Private.Settings.Keys.Party.FontFlags,
		Private.Settings.Keys.Party.ForegroundBarTexture,
		Private.Settings.Keys.Party.BackgroundBarTexture,
		Private.Settings.Keys.Party.BackgroundBarColor,
		Private.Settings.Keys.Party.ProgressBarColor,
		Private.Settings.Keys.Party.UseInterruptabilityColors,
		Private.Settings.Keys.Party.UninterruptibleColor,
		Private.Settings.Keys.Party.InterruptibleColor,
		Private.Settings.Keys.Party.UseTargetClassColor,
		Private.Settings.Keys.Party.AnnounceUntargetedSpells,
		Private.Settings.Keys.Party.AnnounceTargetedSpells,
		Private.Settings.Keys.Party.TextToSpeechVoice,
	}
end

function Private.Settings.GetFeatureFlagsForKind(kind)
	if kind == Private.Enum.FrameKind.Self then
		return {
			Private.Enum.FeatureFlag.GlowImportant,
			Private.Enum.FeatureFlag.OnlyImportant,
			Private.Enum.FeatureFlag.ShowDuration,
			Private.Enum.FeatureFlag.ShowSwipe,
			Private.Enum.FeatureFlag.IndicateInterrupts,
			Private.Enum.FeatureFlag.RenderInterruptSourceName,
		}
	end

	return {
		Private.Enum.FeatureFlag.GlowImportant,
		Private.Enum.FeatureFlag.OnlyImportant,
		Private.Enum.FeatureFlag.ShowDuration,
		Private.Enum.FeatureFlag.ShowIcon,
		Private.Enum.FeatureFlag.ShowTargetMarker,
		Private.Enum.FeatureFlag.ShowSpellName,
		Private.Enum.FeatureFlag.ShowTargetName,
		Private.Enum.FeatureFlag.ShowTargetClassColor,
		Private.Enum.FeatureFlag.HideUntargetedSpells,
		Private.Enum.FeatureFlag.HideTargetedSpells,
		Private.Enum.FeatureFlag.SelfOnly,
		Private.Enum.FeatureFlag.MirrorLayout,
		Private.Enum.FeatureFlag.InlineDuration,
		Private.Enum.FeatureFlag.IndicateInterrupts,
		Private.Enum.FeatureFlag.RenderInterruptSourceName,
	}
end

function Private.Settings.GetDefaultEditModeFramePosition(kind)
	if kind == Private.Enum.FrameKind.Self then
		return { point = "CENTER", x = 0, y = 100 }
	end

	return { point = "CENTER", x = 0, y = 325 }
end

function Private.Settings.GetSliderSettingsForOption(key)
	if key == Private.Settings.Keys.Self.IconZoom or key == Private.Settings.Keys.Party.IconZoom then
		return {
			min = 1,
			max = 2,
			step = 0.01,
		}
	end

	if key == Private.Settings.Keys.Self.FontSize or key == Private.Settings.Keys.Party.FontSize then
		return {
			min = 8,
			max = 32,
			step = 1,
		}
	end

	if key == Private.Settings.Keys.Self.Width or key == Private.Settings.Keys.Self.Height then
		return {
			min = 36,
			max = 100,
			step = 1,
		}
	end

	if key == Private.Settings.Keys.Party.Width then
		return {
			min = 60,
			max = 800,
			step = 1,
		}
	end

	if key == Private.Settings.Keys.Party.Height then
		return {
			min = 10,
			max = 120,
			step = 1,
		}
	end

	if key == Private.Settings.Keys.Self.Gap then
		return {
			min = -100,
			max = 100,
			step = 1,
		}
	end

	if key == Private.Settings.Keys.Party.Gap then
		return {
			min = -10,
			max = 60,
			step = 1,
		}
	end

	error(
		string.format(
			"Slider Settings for key '%s' are either not implemented or you're calling this with the wrong key.",
			key
		)
	)
end

---@return SavedVariablesSettingsSelf
function Private.Settings.GetSelfDefaultSettings()
	return {
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
			[Private.Enum.FeatureFlag.GlowImportant] = true,
			[Private.Enum.FeatureFlag.OnlyImportant] = false,
			[Private.Enum.FeatureFlag.ShowDuration] = true,
			[Private.Enum.FeatureFlag.ShowSwipe] = true,
			[Private.Enum.FeatureFlag.IndicateInterrupts] = false,
			[Private.Enum.FeatureFlag.RenderInterruptSourceName] = false,
		},
		BorderStyle = "Blizzard Tooltip Border",
		AnnounceUntargetedSpells = {
			[Private.Enum.NpcType.Boss] = true,
			[Private.Enum.NpcType.Lieutenant] = true,
			[Private.Enum.NpcType.Caster] = true,
			[Private.Enum.NpcType.Melee] = true,
			[Private.Enum.NpcType.Minion] = false,
		},
		AnnounceTargetedSpells = {
			[Private.Enum.NpcType.Boss] = false,
			[Private.Enum.NpcType.Lieutenant] = false,
			[Private.Enum.NpcType.Caster] = false,
			[Private.Enum.NpcType.Melee] = false,
			[Private.Enum.NpcType.Minion] = false,
		},
		TextToSpeechVoice = -1,
	}
end

---@return SavedVariablesSettingsParty
function Private.Settings.GetPartyDefaultSettings()
	return {
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
			[Private.Enum.FeatureFlag.GlowImportant] = true,
			[Private.Enum.FeatureFlag.OnlyImportant] = false,
			[Private.Enum.FeatureFlag.IndicateInterrupts] = true,
			[Private.Enum.FeatureFlag.RenderInterruptSourceName] = true,
			[Private.Enum.FeatureFlag.ShowDuration] = true,
			[Private.Enum.FeatureFlag.ShowIcon] = true,
			[Private.Enum.FeatureFlag.ShowTargetMarker] = false,
			[Private.Enum.FeatureFlag.ShowSpellName] = true,
			[Private.Enum.FeatureFlag.ShowTargetName] = true,
			[Private.Enum.FeatureFlag.ShowTargetClassColor] = true,
			[Private.Enum.FeatureFlag.MirrorLayout] = false,
			[Private.Enum.FeatureFlag.HideUntargetedSpells] = false,
			[Private.Enum.FeatureFlag.HideTargetedSpells] = false,
			[Private.Enum.FeatureFlag.SelfOnly] = false,
			[Private.Enum.FeatureFlag.InlineDuration] = true,
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
			[Private.Enum.NpcType.Caster] = true,
			[Private.Enum.NpcType.Melee] = true,
			[Private.Enum.NpcType.Minion] = false,
		},
		AnnounceTargetedSpells = {
			[Private.Enum.NpcType.Boss] = false,
			[Private.Enum.NpcType.Lieutenant] = false,
			[Private.Enum.NpcType.Caster] = false,
			[Private.Enum.NpcType.Melee] = false,
			[Private.Enum.NpcType.Minion] = false,
		},
		TextToSpeechVoice = -1,
		Position = Private.Settings.GetDefaultEditModeFramePosition(Private.Enum.FrameKind.Party),
	}
end

-- ── v3 Settings view over a v4 group (Phase-3 transitional proxy) ────────────
-- Edit mode and the settings UI still read/write the flat v3 shape at
-- TargetedSpellsSaved.Settings.Self/.Party. After migration those tables are
-- replaced by these metatable proxies backed by the group model, so the ~165
-- edit-mode/settings read/write sites keep working unedited while the group model
-- stays authoritative. The whole edit-mode UI is restructured in Phase 4, which
-- deletes this proxy. Some v3 concepts fan out (Font/FontSize/FontFlags → every
-- text element) or are lossy inversions (bar colour mode, party filter flags);
-- those are noted inline and are best-effort transitional mappings.
---@param group TargetedSpellsGroup
function Private.Settings.CreateGroupView(group)
	local Enum = Private.Enum
	local Element = Enum.Element
	local FeatureFlag = Enum.FeatureFlag
	local BarColorMode = Enum.BarColorMode
	local TargetClass = Enum.TargetClass

	local isIcon = group.Template == Enum.Template.Icon
	local coreTag = isIcon and Element.Icon or Element.ProgressBar

	local function core()
		return group.Elements[coreTag]
	end

	local function getElement(tag)
		return group.Elements[tag]
	end

	-- text elements carrying a font, per template (for Font/FontSize/FontFlags fan-out)
	local fontTargets = isIcon
			and {
				{ tag = Element.Cooldown, countdown = true },
				{ tag = Element.InterruptSource },
			}
		or {
			{ tag = Element.SpellName },
			{ tag = Element.TargetName },
			{ tag = Element.InterruptSource },
			{ tag = Element.DurationCooldown, countdown = true },
		}

	-- "font" | "fontSize" | "fontFlags" → the element field, prefixed for cooldowns
	local function fontField(target, base)
		if target.countdown then
			return "countdown" .. base:gsub("^%l", string.upper)
		end
		return base
	end

	local getters = {}
	local setters = {}

	for _, groupKey in ipairs({ "Enabled", "Gap", "Grow", "Direction", "SortOrder", "GlowType" }) do
		getters[groupKey] = function()
			return group[groupKey]
		end
		setters[groupKey] = function(value)
			group[groupKey] = value
		end
	end

	-- old container Width/Height now live on the core element
	getters.Width = function()
		return core().width
	end
	setters.Width = function(value)
		core().width = value
	end
	getters.Height = function()
		return core().height
	end
	setters.Height = function(value)
		core().height = value
	end

	getters.Font = function()
		local first = getElement(fontTargets[1].tag)
		return first and first[fontField(fontTargets[1], "font")]
	end
	setters.Font = function(value)
		for _, target in ipairs(fontTargets) do
			local elementTable = getElement(target.tag)
			if elementTable then
				elementTable[fontField(target, "font")] = value
			end
		end
	end
	getters.FontSize = function()
		local first = getElement(fontTargets[1].tag)
		return first and first[fontField(fontTargets[1], "fontSize")]
	end
	setters.FontSize = function(value)
		for _, target in ipairs(fontTargets) do
			local elementTable = getElement(target.tag)
			if elementTable then
				elementTable[fontField(target, "fontSize")] = value
			end
		end
	end

	if isIcon then
		getters.IconZoom = function()
			return getElement(Element.Icon).iconZoom
		end
		setters.IconZoom = function(value)
			getElement(Element.Icon).iconZoom = value
		end
		getters.BorderStyle = function()
			local border = getElement(Element.Border)
			if border == nil then
				return "None"
			end
			return border.active == false and "None" or border.borderTexture
		end
		setters.BorderStyle = function(value)
			local border = getElement(Element.Border)
			if border == nil then
				return
			end
			if value == "None" then
				border.active = false
			else
				border.active = true
				border.borderTexture = value
			end
		end
	else
		getters.ForegroundBarTexture = function()
			return core().barTexture
		end
		setters.ForegroundBarTexture = function(value)
			core().barTexture = value
		end
		getters.ProgressBarColor = function()
			return core().progressBarColor
		end
		setters.ProgressBarColor = function(value)
			core().progressBarColor = value
		end
		getters.UninterruptibleColor = function()
			return core().uninterruptibleColor
		end
		setters.UninterruptibleColor = function(value)
			core().uninterruptibleColor = value
		end
		getters.InterruptibleColor = function()
			return core().interruptibleColor
		end
		setters.InterruptibleColor = function(value)
			core().interruptibleColor = value
		end
		getters.BackgroundBarTexture = function()
			return getElement(Element.Background).backgroundTexture
		end
		setters.BackgroundBarTexture = function(value)
			getElement(Element.Background).backgroundTexture = value
		end
		getters.BackgroundBarColor = function()
			return getElement(Element.Background).backgroundColor
		end
		setters.BackgroundBarColor = function(value)
			getElement(Element.Background).backgroundColor = value
		end

		-- lossy: two independent v3 bools ↔ one v4 mode (Phase 6 makes it a dropdown)
		getters.UseInterruptabilityColors = function()
			return core().barColorMode == BarColorMode.Interruptibility
		end
		setters.UseInterruptabilityColors = function(value)
			if value then
				core().barColorMode = BarColorMode.Interruptibility
			elseif core().barColorMode == BarColorMode.Interruptibility then
				core().barColorMode = BarColorMode.Static
			end
		end
		getters.UseTargetClassColor = function()
			return core().barColorMode == BarColorMode.TargetClassColor
		end
		setters.UseTargetClassColor = function(value)
			if value then
				core().barColorMode = BarColorMode.TargetClassColor
			elseif core().barColorMode == BarColorMode.TargetClassColor then
				core().barColorMode = BarColorMode.Static
			end
		end
	end

	-- sub-tables with an identical v4 shape are handed back by reference
	local directTables = {
		Position = function()
			return group.Position
		end,
		LoadConditionContentType = function()
			return group.LoadConditionContentType
		end,
		LoadConditionRole = function()
			return group.LoadConditionRole
		end,
		AnnounceUntargetedSpells = function()
			return TargetedSpellsSaved.TextToSpeech.AnnounceUntargetedSpells
		end,
		AnnounceTargetedSpells = function()
			return TargetedSpellsSaved.TextToSpeech.AnnounceTargetedSpells
		end,
	}
	getters.TextToSpeechVoice = function()
		return TargetedSpellsSaved.TextToSpeech.TextToSpeechVoice
	end
	setters.TextToSpeechVoice = function(value)
		TargetedSpellsSaved.TextToSpeech.TextToSpeechVoice = value
	end

	-- FontFlags: read a representative element, write fans out to all
	local fontFlagsProxy = setmetatable({}, {
		__index = function(_, flagId)
			local first = getElement(fontTargets[1].tag)
			local flags = first and first[fontField(fontTargets[1], "fontFlags")]
			return flags and flags[flagId]
		end,
		__newindex = function(_, flagId, value)
			for _, target in ipairs(fontTargets) do
				local elementTable = getElement(target.tag)
				local flags = elementTable and elementTable[fontField(target, "fontFlags")]
				if flags then
					flags[flagId] = value
				end
			end
		end,
	})

	-- FeatureFlags: each v3 flag maps to a group field, an element field, or the
	-- filter set. Behaviour flags → group; Show*/active → element.active; the
	-- Hide/SelfOnly flags are the inverse of derivePartyFilter; Mirror/Inline gone.
	local function featureFlagGet(flagId)
		if flagId == FeatureFlag.GlowImportant then
			return group.GlowImportant
		elseif flagId == FeatureFlag.OnlyImportant then
			return group.OnlyImportant
		elseif flagId == FeatureFlag.IndicateInterrupts then
			return group.IndicateInterrupts
		elseif flagId == FeatureFlag.RenderInterruptSourceName then
			local elementTable = getElement(Element.InterruptSource)
			return elementTable ~= nil and elementTable.active
		end

		if isIcon then
			if flagId == FeatureFlag.ShowDuration then
				local elementTable = getElement(Element.Cooldown)
				return elementTable ~= nil and elementTable.showCountdown
			elseif flagId == FeatureFlag.ShowSwipe then
				local elementTable = getElement(Element.Cooldown)
				return elementTable ~= nil and elementTable.showSwipe
			end

			return false
		end

		if flagId == FeatureFlag.ShowDuration then
			local elementTable = getElement(Element.DurationCooldown)
			return elementTable ~= nil and elementTable.active
		elseif flagId == FeatureFlag.ShowIcon then
			local elementTable = getElement(Element.Icon)
			return elementTable ~= nil and elementTable.active
		elseif flagId == FeatureFlag.ShowTargetMarker then
			local elementTable = getElement(Element.TargetMarker)
			return elementTable ~= nil and elementTable.active
		elseif flagId == FeatureFlag.ShowSpellName then
			local elementTable = getElement(Element.SpellName)
			return elementTable ~= nil and elementTable.active
		elseif flagId == FeatureFlag.ShowTargetName then
			local elementTable = getElement(Element.TargetName)
			return elementTable ~= nil and elementTable.active
		elseif flagId == FeatureFlag.ShowTargetClassColor then
			local elementTable = getElement(Element.TargetName)
			return elementTable ~= nil and elementTable.useClassColor
		elseif flagId == FeatureFlag.HideUntargetedSpells then
			return not group.Filter[TargetClass.Nobody]
		elseif flagId == FeatureFlag.HideTargetedSpells then
			return not group.Filter[TargetClass.Player] and not group.Filter[TargetClass.PartyMember]
		elseif flagId == FeatureFlag.SelfOnly then
			return not group.Filter[TargetClass.PartyMember] and group.Filter[TargetClass.Player] == true
		end

		return false
	end

	local function setElementActive(tag, value)
		local elementTable = getElement(tag)
		if elementTable then
			elementTable.active = value
		end
	end

	local function setFilterClass(targetClass, present)
		if present then
			group.Filter[targetClass] = true
		else
			group.Filter[targetClass] = nil
		end
	end

	local function featureFlagSet(flagId, value)
		if flagId == FeatureFlag.GlowImportant then
			group.GlowImportant = value
		elseif flagId == FeatureFlag.OnlyImportant then
			group.OnlyImportant = value
		elseif flagId == FeatureFlag.IndicateInterrupts then
			group.IndicateInterrupts = value
		elseif flagId == FeatureFlag.RenderInterruptSourceName then
			setElementActive(Element.InterruptSource, value)
		elseif isIcon and flagId == FeatureFlag.ShowDuration then
			local elementTable = getElement(Element.Cooldown)
			if elementTable then
				elementTable.showCountdown = value
			end
		elseif isIcon and flagId == FeatureFlag.ShowSwipe then
			local elementTable = getElement(Element.Cooldown)
			if elementTable then
				elementTable.showSwipe = value
			end
		elseif flagId == FeatureFlag.ShowDuration then
			local elementTable = getElement(Element.DurationCooldown)
			if elementTable then
				elementTable.active = value
				elementTable.showCountdown = value
			end
		elseif flagId == FeatureFlag.ShowIcon then
			setElementActive(Element.Icon, value)
		elseif flagId == FeatureFlag.ShowTargetMarker then
			setElementActive(Element.TargetMarker, value)
		elseif flagId == FeatureFlag.ShowSpellName then
			setElementActive(Element.SpellName, value)
		elseif flagId == FeatureFlag.ShowTargetName then
			setElementActive(Element.TargetName, value)
		elseif flagId == FeatureFlag.ShowTargetClassColor then
			local elementTable = getElement(Element.TargetName)
			if elementTable then
				elementTable.useClassColor = value
			end
		elseif flagId == FeatureFlag.HideUntargetedSpells then
			setFilterClass(TargetClass.Nobody, not value)
		elseif flagId == FeatureFlag.HideTargetedSpells then
			setFilterClass(TargetClass.Player, not value)
			setFilterClass(TargetClass.PartyMember, not value)
		elseif flagId == FeatureFlag.SelfOnly then
			setFilterClass(TargetClass.PartyMember, not value)
		end
		-- MirrorLayout / InlineDuration and anything unmapped: intentionally ignored
	end

	local featureFlagsProxy = setmetatable({}, {
		__index = function(_, flagId)
			return featureFlagGet(flagId)
		end,
		__newindex = function(_, flagId, value)
			featureFlagSet(flagId, value)
		end,
	})

	return setmetatable({}, {
		__index = function(_, key)
			if key == "FeatureFlags" then
				return featureFlagsProxy
			elseif key == "FontFlags" then
				return fontFlagsProxy
			elseif directTables[key] ~= nil then
				return directTables[key]()
			end

			local getter = getters[key]
			return getter and getter()
		end,
		__newindex = function(_, key, value)
			if key == "FeatureFlags" or key == "FontFlags" then
				return -- these are edited element-wise through their sub-proxies
			elseif directTables[key] ~= nil then
				-- whole sub-table assignment: copy into the backing table in place
				local target = directTables[key]()
				if type(value) == "table" and type(target) == "table" then
					table.wipe(target)
					for subKey, subValue in pairs(value) do
						target[subKey] = subValue
					end
				end
				return
			end

			local setter = setters[key]
			if setter then
				setter(value)
			end
		end,
	})
end

function Private.Settings.GetFontOptions()
	local fonts = CopyTable(LibSharedMedia:List(LibSharedMedia.MediaType.FONT))
	table.sort(fonts)
	local byLabel = LibSharedMedia:HashTable(LibSharedMedia.MediaType.FONT)

	return {
		fonts = fonts,
		byLabel = byLabel,
	}
end

function Private.Settings.GetStatusBarOptions()
	local bars = CopyTable(LibSharedMedia:List(LibSharedMedia.MediaType.STATUSBAR))
	table.sort(bars)

	return bars
end

function Private.Settings.GetBackgroundOptions()
	local backgrounds = CopyTable(LibSharedMedia:List(LibSharedMedia.MediaType.BACKGROUND))
	table.sort(backgrounds)

	return backgrounds
end

function Private.Settings.GetBorderOptions()
	local borders = {
		"Solid",
	}

	for _, border in pairs(CopyTable(LibSharedMedia:List(LibSharedMedia.MediaType.BORDER))) do
		table.insert(borders, border)
	end

	table.sort(borders)

	return borders
end

function Private.Settings.GetTtsVoiceOptions()
	local seen = {}
	local voices = {}

	for _, list in ipairs({ C_VoiceChat.GetTtsVoices(), C_VoiceChat.GetRemoteTtsVoices() }) do
		if list then
			for _, voice in ipairs(list) do
				if not seen[voice.voiceID] then
					seen[voice.voiceID] = true
					table.insert(voices, voice)
				end
			end
		end
	end

	table.sort(voices, function(a, b)
		return a.name < b.name
	end)

	return voices
end

function Private.Settings.GetContentTypesForKind(kind)
	if kind == Private.Enum.FrameKind.Self then
		return Private.Enum.ContentType
	end

	return {
		OpenWorld = Private.Enum.ContentType.OpenWorld,
		Delve = Private.Enum.ContentType.Delve,
		Dungeon = Private.Enum.ContentType.Dungeon,
		Arena = Private.Enum.ContentType.Arena,
		Battleground = Private.Enum.ContentType.Battleground,
	}
end

function Private.Settings.GetGlowTypesForKind(kind)
	if kind == Private.Enum.FrameKind.Self then
		return {
			Private.Enum.GlowType.PixelGlow,
			Private.Enum.GlowType.Star4,
			Private.Enum.GlowType.AutoCastGlow,
			Private.Enum.GlowType.ProcGlow,
		}
	end

	return {
		Private.Enum.GlowType.PixelGlow,
		Private.Enum.GlowType.Star4,
	}
end

table.insert(Private.LoginFnQueue, function()
	LibSharedMedia:Register(
		LibSharedMedia.MediaType.BORDER,
		"Blizzard Tooltip Border",
		"Interface\\Tooltips\\UI-Tooltip-Border"
	)

	local L = Private.L
	local settingsName = C_AddOns.GetAddOnMetadata(addonName, "Title")
	local category, layout = Settings.RegisterVerticalLayoutCategory(settingsName)

	---@param enum table<string, number>
	---@param IsEnabled fun(id: number): boolean
	---@return number
	local function GetMask(enum, IsEnabled)
		local mask = 0

		for label, id in pairs(enum) do
			if IsEnabled(id) then
				mask = bit.bor(mask, bit.lshift(1, id - 1))
			end
		end

		return mask
	end

	---@param value number
	---@return boolean
	local function DecodeBitToBool(mask, value)
		return bit.band(mask, bit.lshift(1, value - 1)) ~= 0
	end

	---@class SettingConfig
	---@field initializer table
	---@field hideSteppers boolean
	---@field IsSectionEnabled nil|fun(): boolean

	---@param key string
	---@param defaults SavedVariablesSettingsSelf|SavedVariablesSettingsParty
	---@return SettingConfig
	local function CreateSetting(key, defaults)
		if key == Private.Settings.Keys.Self.FontFlags or key == Private.Settings.Keys.Party.FontFlags then
			local kindTableRef = key == Private.Settings.Keys.Self.FontFlags and TargetedSpellsSaved.Settings.Self
				or TargetedSpellsSaved.Settings.Party

			local defaultValue = GetMask(Private.Enum.FontFlags, function(id)
				return defaults.FontFlags[id]
			end)

			local function GetValue()
				return GetMask(Private.Enum.FontFlags, function(id)
					return kindTableRef.FontFlags[id]
				end)
			end

			local function SetValue(mask)
				local hasChanges = false

				for label, id in pairs(Private.Enum.FontFlags) do
					local enabled = DecodeBitToBool(mask, id)

					if enabled ~= kindTableRef.FontFlags[id] then
						kindTableRef.FontFlags[id] = enabled
						hasChanges = true
					end
				end

				if hasChanges then
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, kindTableRef.FontFlags)
				end
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				L.Settings.FontFlagsLabel,
				defaultValue,
				GetValue,
				SetValue
			)

			local function GetOptions()
				local container = Settings.CreateControlTextContainer()

				for label, id in pairs(Private.Enum.FontFlags) do
					local translated = L.Settings.FontFlagsLabels[id]

					container:AddCheckbox(id, translated, L.Settings.FontFlagsTooltip)
				end

				return container:GetData()
			end

			local initializer = Settings.CreateDropdown(category, setting, GetOptions, L.Settings.FontFlagsTooltip)

			return {
				initializer = initializer,
				hideSteppers = true,
				IsSectionEnabled = nil,
			}
		end

		if key == Private.Settings.Keys.Self.Font or key == Private.Settings.Keys.Party.Font then
			local tableRef = key == Private.Settings.Keys.Self.Font and TargetedSpellsSaved.Settings.Self
				or TargetedSpellsSaved.Settings.Party

			local function GetValue()
				return tableRef.Font
			end

			local function SetValue(value)
				if value ~= tableRef.Font then
					tableRef.Font = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end

			local function GetOptions()
				local container = Settings.CreateControlTextContainer()
				local fontInfo = Private.Settings.GetFontOptions()

				for label, path in pairs(fontInfo.byLabel) do
					container:Add(path, label)
				end

				return container:GetData()
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.String,
				L.Settings.FontLabel,
				defaults.Font,
				GetValue,
				SetValue
			)
			local initializer = Settings.CreateDropdown(category, setting, GetOptions, L.Settings.FontTooltip)

			return {
				initializer = initializer,
				hideSteppers = false,
				IsSectionEnabled = nil,
			}
		end

		if key == Private.Settings.Keys.Self.BorderStyle or key == Private.Settings.Keys.Party.BorderStyle then
			local tableRef = key == Private.Settings.Keys.Self.BorderStyle and TargetedSpellsSaved.Settings.Self
				or TargetedSpellsSaved.Settings.Party

			local function GetValue()
				return tableRef.BorderStyle
			end

			local function SetValue(value)
				if value ~= tableRef.BorderStyle then
					tableRef.BorderStyle = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end

			local function GetOptions()
				local container = Settings.CreateControlTextContainer()

				for _, label in ipairs(Private.Settings.GetBorderOptions()) do
					container:Add(label, label)
				end

				return container:GetData()
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.String,
				L.Settings.BorderStyleLabel,
				defaults.BorderStyle,
				GetValue,
				SetValue
			)
			local initializer = Settings.CreateDropdown(category, setting, GetOptions, L.Settings.BorderStyleTooltip)

			return {
				initializer = initializer,
				hideSteppers = false,
				IsSectionEnabled = nil,
			}
		end

		if key == Private.Settings.Keys.Self.FeatureFlags or key == Private.Settings.Keys.Party.FeatureFlags then
			local kind = key == Private.Settings.Keys.Self.FeatureFlags and Private.Enum.FrameKind.Self
				or Private.Enum.FrameKind.Party
			local kindTableRef = kind == Private.Enum.FrameKind.Self and TargetedSpellsSaved.Settings.Self
				or TargetedSpellsSaved.Settings.Party
			local applicableFlags = Private.Settings.GetFeatureFlagsForKind(kind)

			local defaultValue = GetMask(applicableFlags, function(id)
				return defaults.FeatureFlags[id]
			end)

			local function GetValue()
				return GetMask(applicableFlags, function(id)
					return kindTableRef.FeatureFlags[id]
				end)
			end

			local function SetValue(mask)
				for _, id in ipairs(applicableFlags) do
					local enabled = DecodeBitToBool(mask, id)
					if enabled ~= kindTableRef.FeatureFlags[id] then
						kindTableRef.FeatureFlags[id] = enabled
						Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, id, enabled)
					end
				end
			end

			local function GetOptions()
				local container = Settings.CreateControlTextContainer()

				for _, id in ipairs(applicableFlags) do
					container:AddCheckbox(id, L.Settings.FeatureFlagLabels[id], L.Settings.FeatureFlagsTooltip)
				end

				return container:GetData()
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				L.Settings.FeatureFlagsLabel,
				defaultValue,
				GetValue,
				SetValue
			)

			local initializer = Settings.CreateDropdown(category, setting, GetOptions, L.Settings.FeatureFlagsTooltip)

			return {
				initializer = initializer,
				hideSteppers = true,
				IsSectionEnabled = nil,
			}
		end

		if key == Private.Settings.Keys.Self.Enabled or key == Private.Settings.Keys.Party.Enabled then
			local tableRef = key == Private.Settings.Keys.Self.Enabled and TargetedSpellsSaved.Settings.Self
				or TargetedSpellsSaved.Settings.Party

			local function GetValue()
				return tableRef.Enabled
			end

			local function SetValue(value)
				if value ~= tableRef.Enabled then
					tableRef.Enabled = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, tableRef.Enabled)
				end
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Boolean,
				L.Settings.EnabledLabel,
				Settings.Default.True,
				GetValue,
				SetValue
			)

			local initializer = Settings.CreateCheckbox(category, setting, L.Settings.EnabledTooltip)

			return {
				initializer = initializer,
				hideSteppers = false,
				IsSectionEnabled = nil,
			}
		end

		if key == Private.Settings.Keys.Party.ForegroundBarTexture then
			local function GetValue()
				return TargetedSpellsSaved.Settings.Party.ForegroundBarTexture
			end

			local function SetValue(value)
				if value ~= TargetedSpellsSaved.Settings.Party.ForegroundBarTexture then
					TargetedSpellsSaved.Settings.Party.ForegroundBarTexture = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end

			local function GetOptions()
				local container = Settings.CreateControlTextContainer()

				for _, label in ipairs(Private.Settings.GetStatusBarOptions()) do
					container:Add(label, label)
				end

				return container:GetData()
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.String,
				L.Settings.ForegroundBarTextureLabel,
				defaults.ForegroundBarTexture,
				GetValue,
				SetValue
			)
			local initializer =
				Settings.CreateDropdown(category, setting, GetOptions, L.Settings.ForegroundBarTextureTooltip)

			return {
				initializer = initializer,
				hideSteppers = false,
				IsSectionEnabled = nil,
			}
		end

		if key == Private.Settings.Keys.Party.BackgroundBarTexture then
			local function GetValue()
				return TargetedSpellsSaved.Settings.Party.BackgroundBarTexture
			end

			local function SetValue(value)
				if value ~= TargetedSpellsSaved.Settings.Party.BackgroundBarTexture then
					TargetedSpellsSaved.Settings.Party.BackgroundBarTexture = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end

			local function GetOptions()
				local container = Settings.CreateControlTextContainer()

				for _, label in ipairs(Private.Settings.GetBackgroundOptions()) do
					container:Add(label, label)
				end

				return container:GetData()
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.String,
				L.Settings.BackgroundBarTextureLabel,
				defaults.BackgroundBarTexture,
				GetValue,
				SetValue
			)
			local initializer =
				Settings.CreateDropdown(category, setting, GetOptions, L.Settings.BackgroundBarTextureTooltip)

			return {
				initializer = initializer,
				hideSteppers = false,
				IsSectionEnabled = nil,
			}
		end

		if key == Private.Settings.Keys.Party.BackgroundBarColor then
			local function GetValue()
				return TargetedSpellsSaved.Settings.Party.BackgroundBarColor
			end

			local function SetValue(value)
				if value ~= TargetedSpellsSaved.Settings.Party.BackgroundBarColor then
					TargetedSpellsSaved.Settings.Party.BackgroundBarColor = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.String,
				L.Settings.BackgroundBarColorLabel,
				defaults.BackgroundBarColor,
				GetValue,
				SetValue
			)
			local initializer = Settings.CreateColorSwatch(category, setting, L.Settings.BackgroundBarColorTooltip)

			return {
				initializer = initializer,
				hideSteppers = false,
				IsSectionEnabled = nil,
			}
		end

		if key == Private.Settings.Keys.Party.ProgressBarColor then
			local function GetValue()
				return TargetedSpellsSaved.Settings.Party.ProgressBarColor
			end

			local function SetValue(value)
				if value ~= TargetedSpellsSaved.Settings.Party.ProgressBarColor then
					TargetedSpellsSaved.Settings.Party.ProgressBarColor = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.String,
				L.Settings.ProgressBarColorLabel,
				defaults.ProgressBarColor,
				GetValue,
				SetValue
			)
			local initializer = Settings.CreateColorSwatch(category, setting, L.Settings.ProgressBarColorTooltip)

			return {
				initializer = initializer,
				hideSteppers = false,
				IsSectionEnabled = nil,
			}
		end

		if key == Private.Settings.Keys.Party.UseInterruptabilityColors then
			local function GetValue()
				return TargetedSpellsSaved.Settings.Party.UseInterruptabilityColors
			end

			local function SetValue(value)
				if value ~= TargetedSpellsSaved.Settings.Party.UseInterruptabilityColors then
					TargetedSpellsSaved.Settings.Party.UseInterruptabilityColors = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)

					if value and TargetedSpellsSaved.Settings.Party.UseTargetClassColor then
						TargetedSpellsSaved.Settings.Party.UseTargetClassColor = false
						Private.EventRegistry:TriggerEvent(
							Private.Enum.Events.SETTING_CHANGED,
							Private.Settings.Keys.Party.UseTargetClassColor,
							false
						)
					end
				end
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Boolean,
				L.Settings.UseInterruptabilityColorsLabel,
				defaults.UseInterruptabilityColors,
				GetValue,
				SetValue
			)
			local initializer = Settings.CreateCheckbox(category, setting, L.Settings.UseInterruptabilityColorsTooltip)

			return {
				initializer = initializer,
				hideSteppers = false,
				IsSectionEnabled = nil,
			}
		end

		if key == Private.Settings.Keys.Party.UseTargetClassColor then
			local function GetValue()
				return TargetedSpellsSaved.Settings.Party.UseTargetClassColor
			end

			local function SetValue(value)
				if value ~= TargetedSpellsSaved.Settings.Party.UseTargetClassColor then
					TargetedSpellsSaved.Settings.Party.UseTargetClassColor = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)

					if value and TargetedSpellsSaved.Settings.Party.UseInterruptabilityColors then
						TargetedSpellsSaved.Settings.Party.UseInterruptabilityColors = false
						Private.EventRegistry:TriggerEvent(
							Private.Enum.Events.SETTING_CHANGED,
							Private.Settings.Keys.Party.UseInterruptabilityColors,
							false
						)
					end
				end
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Boolean,
				L.Settings.UseTargetClassColorLabel,
				defaults.UseTargetClassColor,
				GetValue,
				SetValue
			)
			local initializer = Settings.CreateCheckbox(category, setting, L.Settings.UseTargetClassColorTooltip)

			return {
				initializer = initializer,
				hideSteppers = false,
				IsSectionEnabled = nil,
			}
		end

		if key == Private.Settings.Keys.Party.UninterruptibleColor then
			local function GetValue()
				return TargetedSpellsSaved.Settings.Party.UninterruptibleColor
			end

			local function SetValue(value)
				if value ~= TargetedSpellsSaved.Settings.Party.UninterruptibleColor then
					TargetedSpellsSaved.Settings.Party.UninterruptibleColor = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.String,
				L.Settings.UninterruptibleColorLabel,
				defaults.UninterruptibleColor,
				GetValue,
				SetValue
			)
			local initializer = Settings.CreateColorSwatch(category, setting, L.Settings.UninterruptibleColorTooltip)

			return {
				initializer = initializer,
				hideSteppers = false,
				IsSectionEnabled = function()
					return TargetedSpellsSaved.Settings.Party.Enabled
						and TargetedSpellsSaved.Settings.Party.UseInterruptabilityColors
				end,
			}
		end

		if key == Private.Settings.Keys.Party.InterruptibleColor then
			local function GetValue()
				return TargetedSpellsSaved.Settings.Party.InterruptibleColor
			end

			local function SetValue(value)
				if value ~= TargetedSpellsSaved.Settings.Party.InterruptibleColor then
					TargetedSpellsSaved.Settings.Party.InterruptibleColor = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.String,
				L.Settings.InterruptibleColorLabel,
				defaults.InterruptibleColor,
				GetValue,
				SetValue
			)
			local initializer = Settings.CreateColorSwatch(category, setting, L.Settings.InterruptibleColorTooltip)

			return {
				initializer = initializer,
				hideSteppers = false,
				IsSectionEnabled = function()
					return TargetedSpellsSaved.Settings.Party.Enabled
						and TargetedSpellsSaved.Settings.Party.UseInterruptabilityColors
				end,
			}
		end

		if key == Private.Settings.Keys.Self.IconZoom then
			local sliderSettings = Private.Settings.GetSliderSettingsForOption(key)

			local function GetValue()
				return TargetedSpellsSaved.Settings.Self.IconZoom
			end

			local function SetValue(value)
				if value ~= TargetedSpellsSaved.Settings.Self.IconZoom then
					TargetedSpellsSaved.Settings.Self.IconZoom = value

					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				L.Settings.IconZoomLabel,
				defaults.IconZoom,
				GetValue,
				SetValue
			)
			local options = Settings.CreateSliderOptions(sliderSettings.min, sliderSettings.max, sliderSettings.step)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, FormatPercentage)

			local initializer = Settings.CreateSlider(category, setting, options, L.Settings.IconZoomTooltip)

			return {
				initializer = initializer,
				hideSteppers = false,
				IsSectionEnabled = nil,
			}
		end

		if key == Private.Settings.Keys.Self.GlowType or key == Private.Settings.Keys.Party.GlowType then
			local tableRef = key == Private.Settings.Keys.Self.GlowType and TargetedSpellsSaved.Settings.Self
				or TargetedSpellsSaved.Settings.Party

			local function GetValue()
				return tableRef.GlowType
			end

			local function SetValue(value)
				if value ~= tableRef.GlowType then
					tableRef.GlowType = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end

			local function GetOptions()
				local container = Settings.CreateControlTextContainer()

				local kind = key == Private.Settings.Keys.Self.GlowType and Private.Enum.FrameKind.Self
					or Private.Enum.FrameKind.Party

				for _, id in ipairs(Private.Settings.GetGlowTypesForKind(kind)) do
					container:Add(id, L.Settings.GlowTypeLabels[id])
				end

				return container:GetData()
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				L.Settings.GlowTypeLabel,
				defaults.GlowType,
				GetValue,
				SetValue
			)
			local initializer = Settings.CreateDropdown(category, setting, GetOptions, L.Settings.GlowTypeTooltip)

			return {
				initializer = initializer,
				hideSteppers = false,
				IsSectionEnabled = nil,
			}
		end

		if key == Private.Settings.Keys.Self.Grow then
			local function GetValue()
				return TargetedSpellsSaved.Settings.Self.Grow
			end

			local function SetValue(value)
				if value ~= TargetedSpellsSaved.Settings.Self.Grow then
					TargetedSpellsSaved.Settings.Self.Grow = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end

			local function GetOptions()
				local container = Settings.CreateControlTextContainer()

				for label, id in pairs(Private.Enum.Grow) do
					local translated = L.Settings.FrameGrowLabels[id]
					container:Add(id, translated)
				end

				return container:GetData()
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				L.Settings.FrameGrowLabel,
				defaults.Grow,
				GetValue,
				SetValue
			)
			local initializer = Settings.CreateDropdown(category, setting, GetOptions, L.Settings.FrameGrowTooltip)

			return {
				initializer = initializer,
				hideSteppers = false,
				IsSectionEnabled = nil,
			}
		end

		if key == Private.Settings.Keys.Party.Grow then
			local function GetValue()
				return TargetedSpellsSaved.Settings.Party.Grow
			end

			local function SetValue(value)
				if value ~= TargetedSpellsSaved.Settings.Party.Grow then
					TargetedSpellsSaved.Settings.Party.Grow = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end

			local function GetOptions()
				local container = Settings.CreateControlTextContainer()

				for label, id in pairs(Private.Enum.Grow) do
					local translated = L.Settings.FrameGrowLabels[id]
					container:Add(id, translated)
				end

				return container:GetData()
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				L.Settings.FrameGrowLabel,
				defaults.Grow,
				GetValue,
				SetValue
			)
			local initializer = Settings.CreateDropdown(category, setting, GetOptions, L.Settings.FrameGrowTooltip)

			return {
				initializer = initializer,
				hideSteppers = false,
				IsSectionEnabled = nil,
			}
		end

		if key == Private.Settings.Keys.Self.SortOrder or key == Private.Settings.Keys.Party.SortOrder then
			local tableRef = key == Private.Settings.Keys.Self.SortOrder and TargetedSpellsSaved.Settings.Self
				or TargetedSpellsSaved.Settings.Party

			local function GetValue()
				return tableRef.SortOrder
			end

			local function SetValue(value)
				if value ~= tableRef.SortOrder then
					tableRef.SortOrder = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end

			local function GetOptions()
				local container = Settings.CreateControlTextContainer()

				for label, id in pairs(Private.Enum.SortOrder) do
					local translated = id == Private.Enum.SortOrder.Ascending and L.Settings.FrameSortOrderAscending
						or L.Settings.FrameSortOrderDescending
					container:Add(id, translated)
				end

				return container:GetData()
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				L.Settings.FrameSortOrderLabel,
				defaults.SortOrder,
				GetValue,
				SetValue
			)
			local initializer = Settings.CreateDropdown(category, setting, GetOptions, L.Settings.FrameSortOrderTooltip)

			return {
				initializer = initializer,
				hideSteppers = false,
				IsSectionEnabled = nil,
			}
		end

		if key == Private.Settings.Keys.Self.Direction then
			local function GetValue()
				return TargetedSpellsSaved.Settings.Self.Direction
			end

			local function SetValue(value)
				if value ~= TargetedSpellsSaved.Settings.Self.Direction then
					TargetedSpellsSaved.Settings.Self.Direction = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end

			local function GetOptions()
				local container = Settings.CreateControlTextContainer()

				for label, id in pairs(Private.Enum.Direction) do
					local translated = id == Private.Enum.Direction.Horizontal and L.Settings.FrameDirectionHorizontal
						or L.Settings.FrameDirectionVertical
					container:Add(id, translated)
				end

				return container:GetData()
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				L.Settings.FrameDirectionLabel,
				defaults.Direction,
				GetValue,
				SetValue
			)
			local initializer = Settings.CreateDropdown(category, setting, GetOptions, L.Settings.FrameDirectionTooltip)

			return {
				initializer = initializer,
				hideSteppers = false,
				IsSectionEnabled = nil,
			}
		end

		if key == Private.Settings.Keys.Self.Gap or key == Private.Settings.Keys.Party.Gap then
			local sliderSettings = Private.Settings.GetSliderSettingsForOption(key)
			local tableRef = key == Private.Settings.Keys.Self.Gap and TargetedSpellsSaved.Settings.Self
				or TargetedSpellsSaved.Settings.Party

			local function GetValue()
				return tableRef.Gap
			end

			local function SetValue(value)
				if value ~= tableRef.Gap then
					tableRef.Gap = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				L.Settings.FrameGapLabel,
				defaults.Gap,
				GetValue,
				SetValue
			)
			local options = Settings.CreateSliderOptions(sliderSettings.min, sliderSettings.max, sliderSettings.step)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)

			local initializer = Settings.CreateSlider(category, setting, options, L.Settings.FrameGapTooltip)

			return {
				initializer = initializer,
				hideSteppers = false,
				IsSectionEnabled = nil,
			}
		end

		if key == Private.Settings.Keys.Self.FontSize or key == Private.Settings.Keys.Party.FontSize then
			local sliderSettings = Private.Settings.GetSliderSettingsForOption(key)
			local tableRef = key == Private.Settings.Keys.Self.FontSize and TargetedSpellsSaved.Settings.Self
				or TargetedSpellsSaved.Settings.Party

			local function GetValue()
				return tableRef.FontSize
			end

			local function SetValue(value)
				if value ~= tableRef.FontSize then
					tableRef.FontSize = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				L.Settings.FontSizeLabel,
				defaults.FontSize,
				GetValue,
				SetValue
			)
			local options = Settings.CreateSliderOptions(sliderSettings.min, sliderSettings.max, sliderSettings.step)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)

			local initializer = Settings.CreateSlider(category, setting, options, L.Settings.FontSizeTooltip)

			return {
				initializer = initializer,
				hideSteppers = false,
				IsSectionEnabled = nil,
			}
		end

		if key == Private.Settings.Keys.Self.Height or key == Private.Settings.Keys.Party.Height then
			local sliderSettings = Private.Settings.GetSliderSettingsForOption(key)
			local tableRef = key == Private.Settings.Keys.Self.Height and TargetedSpellsSaved.Settings.Self
				or TargetedSpellsSaved.Settings.Party

			local function GetValue()
				return tableRef.Height
			end

			local function SetValue(value)
				if tableRef.Height ~= value then
					tableRef.Height = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				L.Settings.FrameHeightLabel,
				defaults.Height,
				GetValue,
				SetValue
			)
			local options = Settings.CreateSliderOptions(sliderSettings.min, sliderSettings.max, sliderSettings.step)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)

			local initializer = Settings.CreateSlider(category, setting, options, L.Settings.FrameHeightTooltip)

			return {
				initializer = initializer,
				hideSteppers = false,
				IsSectionEnabled = nil,
			}
		end

		if key == Private.Settings.Keys.Self.Width or key == Private.Settings.Keys.Party.Width then
			local sliderSettings = Private.Settings.GetSliderSettingsForOption(key)
			local tableRef = key == Private.Settings.Keys.Self.Width and TargetedSpellsSaved.Settings.Self
				or TargetedSpellsSaved.Settings.Party

			local function GetValue()
				return tableRef.Width
			end

			local function SetValue(value)
				if value ~= tableRef.Width then
					tableRef.Width = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				L.Settings.FrameWidthLabel,
				defaults.Width,
				GetValue,
				SetValue
			)
			local options = Settings.CreateSliderOptions(sliderSettings.min, sliderSettings.max, sliderSettings.step)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)

			local initializer = Settings.CreateSlider(category, setting, options, L.Settings.FrameWidthTooltip)

			return {
				initializer = initializer,
				hideSteppers = false,
				IsSectionEnabled = nil,
			}
		end

		if
			key == Private.Settings.Keys.Self.LoadConditionRole
			or key == Private.Settings.Keys.Party.LoadConditionRole
		then
			local isSelf = key == Private.Settings.Keys.Self.LoadConditionRole
			local kindTableRef = isSelf and TargetedSpellsSaved.Settings.Self or TargetedSpellsSaved.Settings.Party

			local defaultValue = GetMask(Private.Enum.Role, function(id)
				return defaults.LoadConditionRole[id]
			end)

			local function GetValue()
				return GetMask(Private.Enum.Role, function(id)
					return kindTableRef.LoadConditionRole[id]
				end)
			end

			local function SetValue(mask)
				local hasChanges = false
				local anyEnabled = false

				for label, id in pairs(Private.Enum.Role) do
					local enabled = DecodeBitToBool(mask, id)

					if enabled ~= kindTableRef.LoadConditionRole[id] then
						kindTableRef.LoadConditionRole[id] = enabled
						hasChanges = true
					end

					if enabled then
						anyEnabled = true
					end
				end

				if not hasChanges then
					return
				end

				Private.EventRegistry:TriggerEvent(
					Private.Enum.Events.SETTING_CHANGED,
					key,
					kindTableRef.LoadConditionRole
				)

				if anyEnabled ~= kindTableRef.Enabled then
					kindTableRef.Enabled = anyEnabled
					Private.EventRegistry:TriggerEvent(
						Private.Enum.Events.SETTING_CHANGED,
						isSelf and Private.Settings.Keys.Self.Enabled or Private.Settings.Keys.Party.Enabled,
						anyEnabled
					)
				end
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				L.Settings.LoadConditionRoleLabel,
				defaultValue,
				GetValue,
				SetValue
			)

			local function GetOptions()
				local container = Settings.CreateControlTextContainer()

				for label, id in pairs(Private.Enum.Role) do
					local translated = L.Settings.LoadConditionRoleLabels[id]

					container:AddCheckbox(id, translated, L.Settings.LoadConditionRoleTooltip)
				end

				return container:GetData()
			end

			local initializer =
				Settings.CreateDropdown(category, setting, GetOptions, L.Settings.LoadConditionRoleTooltip)

			return {
				initializer = initializer,
				hideSteppers = true,
				IsSectionEnabled = nil,
			}
		end

		if
			key == Private.Settings.Keys.Self.LoadConditionContentType
			or key == Private.Settings.Keys.Party.LoadConditionContentType
		then
			local isSelf = key == Private.Settings.Keys.Self.LoadConditionContentType
			local kindTableRef = isSelf and TargetedSpellsSaved.Settings.Self or TargetedSpellsSaved.Settings.Party

			local defaultValue = GetMask(Private.Enum.ContentType, function(id)
				return defaults.LoadConditionContentType[id]
			end)

			local function GetValue()
				return GetMask(Private.Enum.ContentType, function(id)
					return kindTableRef.LoadConditionContentType[id]
				end)
			end

			local function SetValue(mask)
				local hasChanges = false
				local anyEnabled = false

				for label, id in pairs(Private.Enum.ContentType) do
					local enabled = DecodeBitToBool(mask, id)

					if enabled ~= kindTableRef.LoadConditionContentType[id] then
						kindTableRef.LoadConditionContentType[id] = enabled
						hasChanges = true
					end

					if enabled then
						anyEnabled = true
					end
				end

				if not hasChanges then
					return
				end

				Private.EventRegistry:TriggerEvent(
					Private.Enum.Events.SETTING_CHANGED,
					key,
					kindTableRef.LoadConditionContentType
				)

				if anyEnabled ~= kindTableRef.Enabled then
					kindTableRef.Enabled = anyEnabled
					Private.EventRegistry:TriggerEvent(
						Private.Enum.Events.SETTING_CHANGED,
						isSelf and Private.Settings.Keys.Self.Enabled or Private.Settings.Keys.Party.Enabled,
						anyEnabled
					)
				end
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				L.Settings.LoadConditionContentTypeLabel,
				defaultValue,
				GetValue,
				SetValue
			)

			local function GetOptions()
				local container = Settings.CreateControlTextContainer()

				for label, id in pairs(Private.Enum.ContentType) do
					local function IsEnabled()
						return kindTableRef.LoadConditionContentType[id]
					end

					local function Toggle()
						kindTableRef.LoadConditionContentType[id] = not kindTableRef.LoadConditionContentType[id]
					end

					local translated = L.Settings.LoadConditionContentTypeLabels[id]

					container:AddCheckbox(id, translated, L.Settings.LoadConditionContentTypeTooltip, IsEnabled, Toggle)
				end

				return container:GetData()
			end

			local initializer =
				Settings.CreateDropdown(category, setting, GetOptions, L.Settings.LoadConditionContentTypeTooltip)

			return {
				initializer = initializer,
				hideSteppers = true,
				IsSectionEnabled = nil,
			}
		end

		if
			key == Private.Settings.Keys.Self.AnnounceUntargetedSpells
			or key == Private.Settings.Keys.Party.AnnounceUntargetedSpells
		then
			local defaultValue = GetMask(Private.Enum.NpcType, function(id)
				return defaults.AnnounceUntargetedSpells[id]
			end)

			local function GetValue()
				return GetMask(Private.Enum.NpcType, function(id)
					return TargetedSpellsSaved.Settings.Self.AnnounceUntargetedSpells[id]
				end)
			end

			local function SetValue(mask)
				local hasChanges = false

				for _, id in pairs(Private.Enum.NpcType) do
					local enabled = DecodeBitToBool(mask, id)

					if enabled ~= TargetedSpellsSaved.Settings.Self.AnnounceUntargetedSpells[id] then
						TargetedSpellsSaved.Settings.Self.AnnounceUntargetedSpells[id] = enabled
						TargetedSpellsSaved.Settings.Party.AnnounceUntargetedSpells[id] = enabled
						hasChanges = true
					end
				end

				if not hasChanges then
					return
				end

				Private.EventRegistry:TriggerEvent(
					Private.Enum.Events.SETTING_CHANGED,
					Private.Settings.Keys.Self.AnnounceUntargetedSpells,
					TargetedSpellsSaved.Settings.Self.AnnounceUntargetedSpells
				)
				Private.EventRegistry:TriggerEvent(
					Private.Enum.Events.SETTING_CHANGED,
					Private.Settings.Keys.Party.AnnounceUntargetedSpells,
					TargetedSpellsSaved.Settings.Party.AnnounceUntargetedSpells
				)
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				L.Settings.AnnounceUntargetedSpellsLabel,
				defaultValue,
				GetValue,
				SetValue
			)

			local function GetOptions()
				local container = Settings.CreateControlTextContainer()

				for _, id in pairs(Private.Enum.NpcType) do
					local function IsEnabled()
						return TargetedSpellsSaved.Settings.Self.AnnounceUntargetedSpells[id]
					end

					local function Toggle()
						local bool = not TargetedSpellsSaved.Settings.Self.AnnounceUntargetedSpells[id]
						TargetedSpellsSaved.Settings.Self.AnnounceUntargetedSpells[id] = bool
						TargetedSpellsSaved.Settings.Party.AnnounceUntargetedSpells[id] = bool
					end

					container:AddCheckbox(
						id,
						L.Settings.NpcTypeLabels[id],
						L.Settings.AnnounceUntargetedSpellsTooltip,
						IsEnabled,
						Toggle
					)
				end

				return container:GetData()
			end

			local initializer =
				Settings.CreateDropdown(category, setting, GetOptions, L.Settings.AnnounceUntargetedSpellsTooltip)

			return {
				initializer = initializer,
				hideSteppers = true,
				IsSectionEnabled = nil,
			}
		end

		if
			key == Private.Settings.Keys.Self.AnnounceTargetedSpells
			or key == Private.Settings.Keys.Party.AnnounceTargetedSpells
		then
			local defaultValue = GetMask(Private.Enum.NpcType, function(id)
				return defaults.AnnounceTargetedSpells[id]
			end)

			local function GetValue()
				return GetMask(Private.Enum.NpcType, function(id)
					return TargetedSpellsSaved.Settings.Self.AnnounceTargetedSpells[id]
				end)
			end

			local function SetValue(mask)
				local hasChanges = false

				for _, id in pairs(Private.Enum.NpcType) do
					local enabled = DecodeBitToBool(mask, id)

					if enabled ~= TargetedSpellsSaved.Settings.Self.AnnounceTargetedSpells[id] then
						TargetedSpellsSaved.Settings.Self.AnnounceTargetedSpells[id] = enabled
						TargetedSpellsSaved.Settings.Party.AnnounceTargetedSpells[id] = enabled
						hasChanges = true
					end
				end

				if not hasChanges then
					return
				end

				Private.EventRegistry:TriggerEvent(
					Private.Enum.Events.SETTING_CHANGED,
					Private.Settings.Keys.Self.AnnounceTargetedSpells,
					TargetedSpellsSaved.Settings.Self.AnnounceTargetedSpells
				)
				Private.EventRegistry:TriggerEvent(
					Private.Enum.Events.SETTING_CHANGED,
					Private.Settings.Keys.Party.AnnounceTargetedSpells,
					TargetedSpellsSaved.Settings.Party.AnnounceTargetedSpells
				)
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				L.Settings.AnnounceTargetedSpellsLabel,
				defaultValue,
				GetValue,
				SetValue
			)

			local function GetOptions()
				local container = Settings.CreateControlTextContainer()

				for _, id in pairs(Private.Enum.NpcType) do
					local function IsEnabled()
						return TargetedSpellsSaved.Settings.Self.AnnounceTargetedSpells[id]
					end

					local function Toggle()
						local bool = not TargetedSpellsSaved.Settings.Self.AnnounceTargetedSpells[id]
						TargetedSpellsSaved.Settings.Self.AnnounceTargetedSpells[id] = bool
						TargetedSpellsSaved.Settings.Party.AnnounceTargetedSpells[id] = bool
					end

					container:AddCheckbox(
						id,
						L.Settings.NpcTypeLabels[id],
						L.Settings.AnnounceTargetedSpellsTooltip,
						IsEnabled,
						Toggle
					)
				end

				return container:GetData()
			end

			local initializer =
				Settings.CreateDropdown(category, setting, GetOptions, L.Settings.AnnounceTargetedSpellsTooltip)

			return {
				initializer = initializer,
				hideSteppers = true,
				IsSectionEnabled = nil,
			}
		end

		if
			key == Private.Settings.Keys.Self.TextToSpeechVoice
			or key == Private.Settings.Keys.Party.TextToSpeechVoice
		then
			local function GetValue()
				return TargetedSpellsSaved.Settings.Self.TextToSpeechVoice or 0
			end

			local function SetValue(value)
				if value ~= TargetedSpellsSaved.Settings.Self.TextToSpeechVoice then
					TargetedSpellsSaved.Settings.Self.TextToSpeechVoice = value
					TargetedSpellsSaved.Settings.Party.TextToSpeechVoice = value

					Private.EventRegistry:TriggerEvent(
						Private.Enum.Events.SETTING_CHANGED,
						Private.Settings.Keys.Self.TextToSpeechVoice,
						value
					)
					Private.EventRegistry:TriggerEvent(
						Private.Enum.Events.SETTING_CHANGED,
						Private.Settings.Keys.Party.TextToSpeechVoice,
						value
					)

					local deafeningRoar = C_Spell.GetSpellName(1256047)

					if deafeningRoar then
						C_VoiceChat.SpeakText(value, deafeningRoar, 2, C_TTSSettings.GetSpeechVolume(), true)
					end
				end
			end

			local function GetOptions()
				local container = Settings.CreateControlTextContainer()

				for _, voice in ipairs(Private.Settings.GetTtsVoiceOptions()) do
					container:Add(voice.voiceID, voice.name)
				end

				return container:GetData()
			end

			local setting = Settings.RegisterProxySetting(
				category,
				key,
				Settings.VarType.Number,
				L.Settings.TextToSpeechVoiceLabel,
				0,
				GetValue,
				SetValue
			)
			local initializer =
				Settings.CreateDropdown(category, setting, GetOptions, L.Settings.TextToSpeechVoiceTooltip)

			return {
				initializer = initializer,
				hideSteppers = false,
				IsSectionEnabled = nil,
			}
		end

		error(string.format("CreateSetting not implemented for key '%s'", key))
	end

	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L.Settings.EditModeReminder))

	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L.EditMode.TargetedSpellsSelfLabel))

	do
		local generalCategoryEnabledInitializer

		local function IsSectionEnabled()
			return TargetedSpellsSaved.Settings.Self.Enabled
		end

		local settingsOrder = Private.Settings.GetSettingsDisplayOrder(Private.Enum.FrameKind.Self)
		local defaults = Private.Settings.GetSelfDefaultSettings()

		for i, key in ipairs(settingsOrder) do
			local config = CreateSetting(key, defaults)

			if key == Private.Settings.Keys.Self.Enabled then
				generalCategoryEnabledInitializer = config.initializer
			else
				if config.hideSteppers then
					config.initializer.hideSteppers = true
				end

				config.initializer:SetParentInitializer(
					generalCategoryEnabledInitializer,
					config.IsSectionEnabled or IsSectionEnabled
				)
			end
		end
	end

	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L.EditMode.TargetedSpellsPartyLabel))

	do
		local generalCategoryEnabledInitializer

		local function IsSectionEnabled()
			return TargetedSpellsSaved.Settings.Party.Enabled
		end

		local settingsOrder = Private.Settings.GetSettingsDisplayOrder(Private.Enum.FrameKind.Party)
		local defaults = Private.Settings.GetPartyDefaultSettings()

		for i, key in ipairs(settingsOrder) do
			local config = CreateSetting(key, defaults)

			if key == Private.Settings.Keys.Party.Enabled then
				generalCategoryEnabledInitializer = config.initializer
			else
				if config.hideSteppers then
					config.initializer.hideSteppers = true
				end

				config.initializer:SetParentInitializer(
					generalCategoryEnabledInitializer,
					config.IsSectionEnabled or IsSectionEnabled
				)
			end
		end
	end

	Settings.RegisterAddOnCategory(category)

	local function OpenSettings()
		Settings.OpenToCategory(category:GetID())
	end

	AddonCompartmentFrame:RegisterAddon({
		text = settingsName,
		icon = C_AddOns.GetAddOnMetadata(addonName, "IconTexture"),
		registerForAnyClick = true,
		notCheckable = true,
		func = OpenSettings,
		funcOnEnter = function(button)
			MenuUtil.ShowTooltip(button, function(tooltip)
				tooltip:SetText(settingsName, 1, 1, 1)
				tooltip:AddLine(L.Settings.ClickToOpenSettingsLabel)
				tooltip:AddLine(" ")

				local enabledColor = "FF00FF00"
				local disabledColor = "00FF0000"

				tooltip:AddLine(L.Settings.AddonCompartmentTooltipLine1:format(WrapTextInColorCode(
					string.lower(
					---@diagnostic disable-next-line: param-type-mismatch
						TargetedSpellsSaved.Settings.Self.Enabled and L.Settings.EnabledLabel
						or L.Settings.DisabledLabel
					),
					TargetedSpellsSaved.Settings.Self.Enabled and enabledColor or disabledColor
				)))
				tooltip:AddLine(L.Settings.AddonCompartmentTooltipLine2:format(WrapTextInColorCode(
					string.lower(
					---@diagnostic disable-next-line: param-type-mismatch
						TargetedSpellsSaved.Settings.Party.Enabled and L.Settings.EnabledLabel
						or L.Settings.DisabledLabel
					),
					TargetedSpellsSaved.Settings.Party.Enabled and enabledColor or disabledColor
				)))
			end)
		end,
		funcOnLeave = function(button)
			MenuUtil.HideTooltip(button)
		end,
	})

	local uppercased = string.upper(settingsName)
	local lowercased = string.lower(settingsName)

	SlashCmdList[uppercased] = function(message)
		local command, rest = message:match("^(%S+)%s*(.*)$")

		if command == "options" or command == "settings" then
			OpenSettings()
		end
	end

	_G[string.format("SLASH_%s1", uppercased)] = string.format("/%s", lowercased)
end)
