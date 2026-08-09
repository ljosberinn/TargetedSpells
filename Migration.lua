---@type string, TargetedSpells
local addonName, Private = ...

local Enum = Private.Enum
local Element = Enum.Element
local Template = Enum.Template
local TargetClass = Enum.TargetClass
local BarColorMode = Enum.BarColorMode

---@class TargetedSpellsMigration
Private.Migration = {}

local CURRENT_SCHEMA_VERSION = 4

-- Historical v3 flag ids; do not reuse retired values.
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

---@param value any
---@return any
local function Copy(value)
	return Private.Utils.DeepCopy(value)
end

local copy = Copy

---@param featureFlags table<number, boolean>?
---@param id number
---@return boolean
local function Flag(featureFlags, id)
	return featureFlags and featureFlags[id] == true
end

local flag = Flag

-- Missing or mistyped v3 values fall back to defaults.
---@param source table
---@param defaults table
---@param key string
---@return any
local function Read(source, defaults, key)
	local value = source[key]

	if value == nil or type(value) ~= type(defaults[key]) then
		return defaults[key]
	end

	return value
end

local read = Read

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

---@param featureFlags table<number, boolean>
---@return table<TargetClass, boolean>
local function DerivePartyFilter(featureFlags)
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


---@param selfSettings SavedVariablesSettingsSelf
---@param defaults SavedVariablesSettingsSelf
local function BuildSelfGroup(selfSettings, defaults)
	local flags = read(selfSettings, defaults, "FeatureFlags")

	---@return table<Element, table<string, any>>
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

	---@return table<Element, table<string, any>>
	local function BuildBarElements()
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

	return {
		Name = "Party",
		Enabled = read(partySettings, defaults, "Enabled"),
		Filter = DerivePartyFilter(flags),
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


local migrationSteps = {
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

		---@return table<number, boolean>|boolean|nil
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
		saved.V3MigrationWarningSeen = nil
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

