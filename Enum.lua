---@type string, TargetedSpells
local addonName, Private = ...

Private.Enum = {}

Private.Enum.GrowDirection = {
	Horizontal = 1,
	Vertical = 2,
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
