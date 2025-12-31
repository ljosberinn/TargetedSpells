---@type string, TargetedSpells
local addonName, Private = ...

---@class TargetedSpellsEnums
Private.Enum = {}

---@enum CustomEvents
Private.Enum.Events = {
	SETTING_CHANGED = "SETTING_CHANGED",
	DELAYED_UNIT_SPELLCAST_START = "DELAYED_UNIT_SPELLCAST_START",
	DELAYED_UNIT_SPELLCAST_CHANNEL_START = "DELAYED_UNIT_SPELLCAST_CHANNEL_START",
	EDIT_MODE_POSITION_CHANGED = "EDIT_MODE_POSITION_CHANGED",
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
	Center = 1,
	Start = 2,
	End = 3,
}

---@enum SoundChannel
Private.Enum.SoundChannel = {
	Master = MASTER_VOLUME,
	Music = MUSIC_VOLUME,
	SFX = FX_VOLUME,
	Ambience = AMBIENCE_VOLUME,
	Dialog = DIALOG_VOLUME,
}

---@enum GlowType
Private.Enum.GlowType = {
	PixelGlow = 1,
	AutoCastGlow = 2,
	ButtonGlow = 3,
	ProcGlow = 4,
	Star4 = 5,
}
