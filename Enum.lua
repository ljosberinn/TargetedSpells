---@type string, TargetedSpells
local addonName, Private = ...

Private.Enum = {}

Private.Enum.GrowDirection = {
	Horizontal = "horizontal",
	Vertical = "vertical",
}

Private.Enum.ContentType = {
	OpenWorld = 1,
	Delve = 2,
	Dungeon = 3,
	Raid = 4,
	Arena = 5,
	Battleground = 6,
}

Private.Enum.Role = {
	Healer = 1,
	Tank = 2,
	Damager = 3,
}

Private.Enum.FrameKind = {
	Self = "self",
	Party = "party",
}

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
