---@type string, TargetedSpells
local addonName, Private = ...

Private.L = {}

Private.EventRegistry = CreateFromMixins(CallbackRegistryMixin)
Private.EventRegistry:OnLoad()

do
	local tbl = {}

	for _, value in pairs(Private.Enum.Events) do
		table.insert(tbl, value)
	end

	Private.EventRegistry:GenerateCallbackEvents(tbl)
end

Private.LoginFnQueue = {}

EventUtil.ContinueOnAddOnLoaded(addonName, function()
	local isFirstRun = TargetedSpellsSaved == nil

	if isFirstRun then
		TargetedSpellsSaved = {
			SchemaVersion = 4,
			Groups = Private.Groups.CreateStarterGroups(),
			TextToSpeech = {
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
				nameplateShowOffscreenWasInitialized = false,
			}
		}
	else
		Private.Migration.Apply(TargetedSpellsSaved)
	end

	if not TargetedSpellsSaved.nameplateShowOffscreenWasInitialized then
		TargetedSpellsSaved.nameplateShowOffscreenWasInitialized = true
		C_CVar.SetCVar("nameplateShowOffscreen", 1)
	end

	Private.Groups.Conform(TargetedSpellsSaved.Groups)

	for i = 1, #Private.LoginFnQueue do
		Private.LoginFnQueue[i]()
	end

	table.wipe(Private.LoginFnQueue)
end)
