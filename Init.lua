---@type string, TargetedSpells
local addonName, Private = ...

Private.IsMidnight = select(4, GetBuildInfo()) >= 120000
Private.Events = {
	SETTING_CHANGED = "SETTING_CHANGED",
}

Private.EventRegistry = CreateFromMixins(CallbackRegistryMixin)
Private.EventRegistry:OnLoad()

do
	local tbl = {}

	for _, value in pairs(Private.Events) do
		table.insert(tbl, value)
	end

	Private.EventRegistry:GenerateCallbackEvents(tbl)
end

Private.LoginFnQueue = {}

function Private.DebugLog(...)
	if DevTool then
		DevTool:AddData({ data = ... })
	else
		print(...)
	end
end

EventUtil.ContinueOnAddOnLoaded(addonName, function()
	---@type SavedVariables
	TargetedSpellsSaved = TargetedSpellsSaved or {}
	TargetedSpellsSaved.Settings = TargetedSpellsSaved.Settings or {}

	TargetedSpellsSaved.Settings.Self = TargetedSpellsSaved.Settings.Self or {}
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
