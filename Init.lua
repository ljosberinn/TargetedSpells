---@type string, TargetedSpells
local addonName, Private = ...

Private.IsMidnight = select(4, GetBuildInfo()) >= 120000
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
	---@class SavedVariables
	TargetedSpellsSaved = TargetedSpellsSaved or {}
	if TargetedSpellsSaved.nameplateShowOffscreenWasInitialized == nil and Private.IsMidnight then
		TargetedSpellsSaved.nameplateShowOffscreenWasInitialized = true
		C_CVar.SetCVar("nameplateShowOffscreen", 1)
	end

	---@class TargetedSpellsSettings
	TargetedSpellsSaved.Settings = TargetedSpellsSaved.Settings or {}
	---@class SavedVariablesSettingsSelf
	TargetedSpellsSaved.Settings.Self = TargetedSpellsSaved.Settings.Self or {}
	---@class SavedVariablesSettingsParty
	TargetedSpellsSaved.Settings.Party = TargetedSpellsSaved.Settings.Party or {}

	for key, value in pairs(Private.Settings.GetSelfDefaultSettings()) do
		if TargetedSpellsSaved.Settings.Self[key] == nil then
			TargetedSpellsSaved.Settings.Self[key] = value
		end
	end

	for key, value in pairs(Private.Settings.GetPartyDefaultSettings()) do
		if TargetedSpellsSaved.Settings.Party[key] == nil then
			TargetedSpellsSaved.Settings.Party[key] = value
		end
	end

	for i = 1, #Private.LoginFnQueue do
		local fn = Private.LoginFnQueue[i]
		fn()
	end

	table.wipe(Private.LoginFnQueue)
end)
