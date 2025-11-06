---@type string, TargetedSpells
local addonName, Private = ...

---@class TargetedSpellsEnums
Private.Enum = {}

---@enum CustomEvents
Private.Enum.Events = {
	SETTING_CHANGED = "SETTING_CHANGED",
	DELAYED_UNIT_SPELLCAST_START = "DELAYED_UNIT_SPELLCAST_START",
	DELAYED_UNIT_SPELLCAST_CHANNEL_START = "DELAYED_UNIT_SPELLCAST_CHANNEL_START",
}

---@enum Direction
Private.Enum.Direction = {
	Horizontal = "horizontal",
	Vertical = "vertical",
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
	Ascending = "ascending",
	Descending = "descending",
}

---@enum Grow
Private.Enum.Grow = {
	Center = "center",
	Start = "start",
	End = "end",
}
