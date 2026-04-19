---@type string, TargetedSpells
local _, Private = ...

---@class TargetedSpellsEnums
Private.Enum = {}

---@enum CustomEvents
Private.Enum.Events = {
	SETTING_CHANGED = "SETTING_CHANGED",
	DELAYED_UNIT_SPELLCAST_START = "DELAYED_UNIT_SPELLCAST_START",
	EDIT_MODE_SELF_POSITION_CHANGED = "EDIT_MODE_SELF_POSITION_CHANGED",
	EDIT_MODE_PARTY_POSITION_CHANGED = "EDIT_MODE_PARTY_POSITION_CHANGED",
	DELAYED_FRAME_CLEANUP = "DELAYED_FRAME_CLEANUP",
	PARTY_SETTINGS_MIGRATED = "PARTY_SETTINGS_MIGRATED",
}

---@enum Direction
Private.Enum.Direction = {
	Horizontal = 1,
	Vertical = 2,
}

---@enum ContentType
Private.Enum.ContentType = {
	OpenWorld = 1,
	Delve = 2,
	Dungeon = 3,
	Raid = 4,
	Arena = 5,
	Battleground = 6,
}

---@enum Role
Private.Enum.Role = {
	Healer = 1,
	Tank = 2,
	Damager = 3,
}

---@enum FrameKind
Private.Enum.FrameKind = {
	Self = "self",
	Party = "party",
}

---@enum Anchor
Private.Enum.Anchor = {
	Center = "CENTER",
	Top = "TOP",
	Bottom = "BOTTOM",
	Left = "LEFT",
	Right = "RIGHT",
	TopLeft = "TOPLEFT",
	TopRight = "TOPRIGHT",
	BottomLeft = "BOTTOMLEFT",
	BottomRight = "BOTTOMRIGHT",
}

---@enum SortOrder
Private.Enum.SortOrder = {
	Ascending = 1,
	Descending = 2,
}

---@enum Grow
Private.Enum.Grow = {
	-- Center = 1, -- deprecated
	Start = 2,
	End = 3,
}

---@enum GlowType
Private.Enum.GlowType = {
	PixelGlow = 1,
	AutoCastGlow = 2,
	-- ButtonGlow = 3, -- deprecated
	ProcGlow = 4,
	Star4 = 5,
}

---@enum FontFlags
Private.Enum.FontFlags = {
	OUTLINE = 1,
	SHADOW = 2,
}

---@enum NpcType
Private.Enum.NpcType = {
	Boss = 1,
	Lieutenant = 2,
	Caster = 3,
	Melee = 4,
	Minion = 5,
}

---@enum FeatureFlag
Private.Enum.FeatureFlag = {
	GlowImportant = 1,
	OnlyImportant = 2,
	ShowDuration = 3,
	-- ShowDurationFractions = 4, -- deprecated
	-- ShowBorder = 5, -- deprecated
	ShowSwipe = 6,
	IndicateInterrupts = 7,
	RenderInterruptSourceName = 8,
	-- IncludeSelfInParty = 9, -- deprecated
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
