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
	---@class SavedVariables
	TargetedSpellsSaved = TargetedSpellsSaved or {}

	if TargetedSpellsSaved.nameplateShowOffscreenWasInitialized == nil then
		TargetedSpellsSaved.nameplateShowOffscreenWasInitialized = true
		C_CVar.SetCVar("nameplateShowOffscreen", 1)
	end

	---@class TargetedSpellsSettings
	TargetedSpellsSaved.Settings = TargetedSpellsSaved.Settings or {}
	---@class SavedVariablesSettingsSelf
	TargetedSpellsSaved.Settings.Self = TargetedSpellsSaved.Settings.Self or {}
	---@class SavedVariablesSettingsParty
	TargetedSpellsSaved.Settings.Party = TargetedSpellsSaved.Settings.Party or {}

	local selfDefaults = Private.Settings.GetSelfDefaultSettings()
	local partyDefaults = Private.Settings.GetPartyDefaultSettings()

	do
		local oldTTS = TargetedSpellsSaved.Settings.Self.AnnounceUntargetedSpells

		if type(oldTTS) == "boolean" then
			local migrated = {
				[Private.Enum.NpcType.Boss] = oldTTS,
				[Private.Enum.NpcType.Lieutenant] = oldTTS,
				[Private.Enum.NpcType.Caster] = oldTTS,
				[Private.Enum.NpcType.Melee] = oldTTS,
				[Private.Enum.NpcType.Minion] = false,
			}
			TargetedSpellsSaved.Settings.Self.AnnounceUntargetedSpells = migrated
			TargetedSpellsSaved.Settings.Party.AnnounceUntargetedSpells = migrated
		end
	end

	for key, value in pairs(selfDefaults) do
		if
			TargetedSpellsSaved.Settings.Self[key] == nil
			or type(value) ~= type(TargetedSpellsSaved.Settings.Self[key])
		then
			TargetedSpellsSaved.Settings.Self[key] = value
		end

		Private.Utils.ApplyMigration(key, Private.Enum.FrameKind.Self, selfDefaults)
	end

	for key, value in pairs(partyDefaults) do
		if
			TargetedSpellsSaved.Settings.Party[key] == nil
			or type(value) ~= type(TargetedSpellsSaved.Settings.Party[key])
		then
			TargetedSpellsSaved.Settings.Party[key] = value
		end
	end

	if TargetedSpellsSaved.V3MigrationWarningSeen == nil and not isFirstRun then
		TargetedSpellsSaved.V3MigrationWarningSeen = true
		TargetedSpellsSaved.Settings.Party = Private.Utils.MigratePartySettingsToV3(TargetedSpellsSaved.Settings.Party)
		Private.Utils.ShowMigrationPopup()
		Private.EventRegistry:TriggerEvent(Private.Enum.Events.PARTY_SETTINGS_MIGRATED)
	end

	for i = 1, #Private.LoginFnQueue do
		local fn = Private.LoginFnQueue[i]
		fn()
	end

	table.wipe(Private.LoginFnQueue)
end)
