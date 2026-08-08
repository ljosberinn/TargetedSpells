---@type string, TargetedSpells
local _, Private = ...

---@class TargetedSpellsEnums
Private.Enum = {}

---@enum CustomEvents
Private.Enum.Events = {
	PROFILE_IMPORTED = "PROFILE_IMPORTED",
	GROUP_CHANGED = "GROUP_CHANGED",
	GROUP_POSITION_CHANGED = "GROUP_POSITION_CHANGED",
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
	-- Caster = 3, -- deprecated as of 12.1
	-- Melee = 4, -- deprecated as of 12.1
	Minion = 5,
	Other = 6,
}

---@enum TargetedSpellsTemplate
Private.Enum.Template = {
	Icon = "Icon",
	Bar = "Bar",
	IconDuration = "IconDuration",
}

---@enum Element
Private.Enum.Element = {
	-- shared / icon template
	Icon = "Icon",
	Overlay = "Overlay",
	Cooldown = "Cooldown",
	Border = "Border",
	InterruptSource = "InterruptSource",
	-- bar template
	ProgressBar = "ProgressBar",
	Background = "Background",
	TargetMarker = "TargetMarker",
	DurationCooldown = "DurationCooldown",
	SpellName = "SpellName",
	TargetName = "TargetName",
	InterruptShield = "InterruptShield",
	-- icon+duration template
	Duration = "Duration",
}

---@enum TargetClass
Private.Enum.TargetClass = {
	Player = 1,
	PartyMember = 2,
	Nobody = 3,
}

---@enum BarColorMode
Private.Enum.BarColorMode = {
	Static = 1,
	Interruptibility = 2,
	TargetClassColor = 3,
}
