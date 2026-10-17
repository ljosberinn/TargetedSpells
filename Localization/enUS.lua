---@type string, TargetedSpells
local addonName, Private = ...

local addonNameWithIcon = ""

do
	local icon = C_AddOns.GetAddOnMetadata(addonName, "IconTexture")
	-- width, height, offsetX, offsetY
	addonNameWithIcon = string.format("|T%s:%d:%d:%d:%d|t %s", icon, 20, 20, 0, -4, addonName)
end

local L = Private.L

L.EditMode = {}
L.Functionality = {}
L.Settings = {}
L.SlashCommands = {}
L.Designer = {}
L.Groups = {}

L.Designer.Title = "Targeted Spells - Layout Designer"
L.Designer.ElementPickerLabel = "Element"
L.Designer.SelectHint = "Click an element in the preview, or pick one from the Element dropdown."
L.Designer.ResetElement = "Reset Element"

-- Copy-layout-from-group: fixed action-dropdown prompt + the empty-list message.
L.Designer.CopyFrom = "Copy layout from…"
L.Designer.CopyFromEmpty = "No other groups of this type"

-- Scratch-copy lifecycle: the footer Apply/Revert controls, the reminder that edits
-- are only live once saved, and the unsaved-changes prompt (close / tab-switch).
L.Designer.Apply = SAVE_CHANGES
L.Designer.Revert = HUD_EDIT_MODE_REVERT_CHANGES
L.Designer.Discard = "Discard"
L.Designer.UnsavedHint = "Changes apply on Save."
L.Designer.UnsavedPrompt = "You have unsaved layout changes."

L.Designer.SettingNames = {
	ELEMENT_ACTIVE = VIDEO_OPTIONS_ENABLED,
	ELEMENT_WIDTH = "Width",
	ELEMENT_HEIGHT = "Height",
	ELEMENT_X = "X Offset",
	ELEMENT_Y = "Y Offset",
	ELEMENT_FONT_SIZE = FONT_SIZE,
	ELEMENT_FONT = "Font",
	ELEMENT_FONT_FLAGS = "Font Style",
	ELEMENT_TEXT_COLOR = "Text Color",
	ELEMENT_JUSTIFY_H = "Alignment",
	ELEMENT_MAX_WIDTH = "Max Width",
	ELEMENT_GAP = "Gap",
	ELEMENT_USE_CLASS_COLOR = "Use Class Color",
	ELEMENT_ICON_ZOOM = "Icon Zoom",
	ELEMENT_SHOW_SWIPE = "Show Swipe",
	ELEMENT_SHOW_COUNTDOWN = "Show Duration",
	ELEMENT_FRACTION_THRESHOLD = "Fraction Below (s)",
	ELEMENT_BORDER_TEXTURE = "Border Texture",
	ELEMENT_BORDER_COLOR = "Border Color",
	ELEMENT_BORDER_SIZE = "Border Size",
	ELEMENT_BAR_TEXTURE = "Bar Texture",
	ELEMENT_BAR_COLOR_MODE = "Color Mode",
	ELEMENT_BAR_COLOR = "Bar Color",
	ELEMENT_INTERRUPTIBLE_COLOR = "Interruptible Color",
	ELEMENT_UNINTERRUPTIBLE_COLOR = "Uninterruptible Color",
	ELEMENT_BACKGROUND_TEXTURE = "Background Texture",
	ELEMENT_BACKGROUND_COLOR = "Background Color",
}

L.Designer.Options = {
	JUSTIFY_LEFT = "Left",
	JUSTIFY_CENTER = "Center",
	JUSTIFY_RIGHT = "Right",
	BAR_COLOR_STATIC = "Static",
	BAR_COLOR_INTERRUPTIBILITY = "Interruptibility",
	BAR_COLOR_TARGET_CLASS = "Target Class Color",
}

L.Designer.FontFlagNames = {
	[Private.Enum.FontFlags.OUTLINE] = "Outline",
	[Private.Enum.FontFlags.SHADOW] = "Shadow",
}
L.Designer.FontFlagsNone = "None"

L.Designer.ElementNames = {
	[Private.Enum.Element.Icon] = UNIT_NAMEPLATES_CAST_BAR_DISPLAY_SPELL_ICON,
	[Private.Enum.Element.Overlay] = "Cooldown Manager Bezel",
	[Private.Enum.Element.Cooldown] = "Cooldown",
	[Private.Enum.Element.Border] = "Border",
	[Private.Enum.Element.InterruptSource] = "Interrupter Name",
	[Private.Enum.Element.ProgressBar] = "Progress Bar",
	[Private.Enum.Element.Background] = "Background",
	[Private.Enum.Element.TargetMarker] = "Target Marker",
	[Private.Enum.Element.DurationCooldown] = "Duration",
	[Private.Enum.Element.SpellName] = UNIT_NAMEPLATES_CAST_BAR_DISPLAY_SPELL_NAME,
	[Private.Enum.Element.TargetName] = UNIT_NAMEPLATES_CAST_BAR_DISPLAY_SPELL_TARGET,
	[Private.Enum.Element.InterruptShield] = "Interrupt Shield",
	[Private.Enum.Element.Duration] = "Duration",
}

L.SlashCommands.Header = "Targeted Spells commands:"
L.SlashCommands.OptionsDescription = "Open the settings panel"
L.SlashCommands.SettingsDescription = "Open the settings panel"
L.SlashCommands.DesignDescription = "Open the layout designer"

L.Settings.EditModeReminder =
	string.format("All settings are exposed via %s and \"/targetedspells design\".", HUD_EDIT_MODE_MENU)
L.EditMode.TargetedSpellsSelfLabel = "Targeted Spells - Self"
L.EditMode.TargetedSpellsPartyLabel = "Targeted Spells - Party"

L.Functionality.CVarWarning = string.format(
	"%s\n\nThe Nameplate Setting '%s' was disabled.\n\nWithout it, %s will not work on off-screen enemies.\n\nClick '%s' to enable it again.",
	addonNameWithIcon,
	UNIT_NAMEPLATES_SHOW_OFFSCREEN,
	addonName,
	ENABLE
)

L.Functionality.V3MigrationWarning = string.format(
	"%s\n\nDue to API restriction updates, the Party functionality for Targeted Spells had to be completely overhauled. Please check out %s for a preview.",
	addonNameWithIcon,
	HUD_EDIT_MODE_MENU
)

L.Settings.EnabledLabel = VIDEO_OPTIONS_ENABLED
L.Settings.DisabledLabel = VIDEO_OPTIONS_DISABLED

L.Settings.AddonCompartmentTooltipLine1 =
	string.format("%s is %s", WrapTextInColorCode(L.EditMode.TargetedSpellsSelfLabel, "ffeda55f"), "%s")
L.Settings.AddonCompartmentTooltipLine2 =
	string.format("%s is %s", WrapTextInColorCode(L.EditMode.TargetedSpellsPartyLabel, "ffeda55f"), "%s")

L.Settings.LoadConditionContentTypeLabel = "Load Condition: Content Type"
L.Settings.LoadConditionContentTypeTooltip = nil
L.Settings.LoadConditionContentTypeLabels = {
	[Private.Enum.ContentType.OpenWorld] = "Open World",
	[Private.Enum.ContentType.Delve] = "Delves",
	[Private.Enum.ContentType.Dungeon] = DUNGEONS,
	[Private.Enum.ContentType.Raid] = RAIDS,
	[Private.Enum.ContentType.Arena] = ARENA,
	[Private.Enum.ContentType.Battleground] = BATTLEGROUNDS,
}

L.Settings.LoadConditionRoleLabel = "Load Condition: Role"
L.Settings.LoadConditionRoleTooltip = nil
L.Settings.LoadConditionRoleLabels = {
	[Private.Enum.Role.Healer] = HEALER,
	[Private.Enum.Role.Tank] = TANK,
	[Private.Enum.Role.Damager] = DAMAGER,
}

L.Settings.FrameGapLabel = "Gap"
L.Settings.FrameGapTooltip = nil

L.Settings.FrameDirectionLabel = HUD_EDIT_MODE_SETTING_AURA_FRAME_ORIENTATION
L.Settings.FrameDirectionTooltip = nil
L.Settings.FrameDirectionHorizontal = HUD_EDIT_MODE_SETTING_AURA_FRAME_ORIENTATION_HORIZONTAL
L.Settings.FrameDirectionVertical = HUD_EDIT_MODE_SETTING_AURA_FRAME_ORIENTATION_VERTICAL

L.Settings.FrameSortOrderLabel = "Sort Order"
L.Settings.FrameSortOrderTooltip = nil
L.Settings.FrameSortOrderAscending = "Ascending"
L.Settings.FrameSortOrderDescending = "Descending"

L.Settings.FrameGrowLabel = "Grow"
L.Settings.FrameGrowTooltip = nil
L.Settings.FrameGrowLabels = {
	[Private.Enum.Grow.Start] = "Start",
	[Private.Enum.Grow.End] = "End",
}

L.Settings.GlowImportantLabel = "Glow Important Spells"

L.Settings.OnlyImportantLabel = "Only Show Important Spells"

L.Settings.GlowTypeLabel = "Glow Type"
L.Settings.GlowTypeTooltip = nil
L.Settings.GlowTypeLabels = {
	[Private.Enum.GlowType.PixelGlow] = "Pixel Glow",
	[Private.Enum.GlowType.AutoCastGlow] = "Auto Cast Glow",
	[Private.Enum.GlowType.ProcGlow] = "Proc Glow",
	[Private.Enum.GlowType.Star4] = "Star 4",
}

L.Settings.IndicateInterruptsLabel = "Indicate Interrupts"

L.Settings.TextToSpeechVoiceLabel = "TTS Voice"
L.Settings.TextToSpeechVoiceTooltip = "Voice used for Text-To-Speech announcements. Shared between all groups."

L.Settings.AnnounceUntargetedSpellsLabel = "Untargeted TTS Settings"
L.Settings.AnnounceUntargetedSpellsTooltip = "Text-To-Speech for untargeted spells (AoE, frontals, etc.) by NPC type."

L.Settings.AnnounceTargetedSpellsLabel = "Targeted TTS Settings"
L.Settings.AnnounceTargetedSpellsTooltip = "Text-To-Speech for spells that target a specific player, by NPC type."

L.Settings.NpcTypeLabels = {
	[Private.Enum.NpcType.Boss] = "Bosses",
	[Private.Enum.NpcType.Lieutenant] = "Lieutenants",
	[Private.Enum.NpcType.Other] = "Any Other",
	[Private.Enum.NpcType.Minion] = "Minions",
}

L.Settings.ClickToOpenSettingsLabel = "Click to open settings"

L.Settings.Import = HUD_EDIT_MODE_IMPORT_LAYOUT
L.Settings.Export = "Export"

L.Settings.FeatureFlagsLabel = "Features"
L.Settings.FeatureFlagsTooltip = nil

L.Settings.GroupNameLabel = "Rename Group"
L.Settings.GroupNamePrompt = "Enter a name for this group:"

L.Settings.TemplateLabel = "Template"
L.Settings.TemplateTooltip = "Switching template resets this group's element layout to the template default."
L.Settings.TemplateLabels = {
	[Private.Enum.Template.Icon] = "Icon",
	[Private.Enum.Template.Bar] = "Bar",
	[Private.Enum.Template.IconDuration] = "Icon + Duration",
}

L.Settings.FilterLabel = "Show Casts Targeting"
L.Settings.FilterTooltip = "Which cast targets this group displays."
L.Settings.TargetClassLabels = {
	[Private.Enum.TargetClass.Player] = "You",
	[Private.Enum.TargetClass.PartyMember] = "Party Members",
	[Private.Enum.TargetClass.Nobody] = "Nobody (untargeted)",
}

L.Settings.CreateGroup = "Create Group"
L.Settings.DeleteGroup = "Delete Group"
L.Settings.DeleteGroupConfirm = "Delete this group? This cannot be undone."
L.Settings.CannotDeleteLastGroup = "You cannot delete the last remaining group."

L.Groups.DefaultName = "Group %d"
L.Groups.StarterSelfName = "Self - Icon"
L.Groups.StarterUntargetedName = "Untargeted AoE - Bar"
L.Groups.MigratedSelfName = "Self"
L.Groups.MigratedPartyName = "Party"
