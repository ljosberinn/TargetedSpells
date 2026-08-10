---@type string, TargetedSpells
local addonName, Private = ...

---@class TargetedSpellsDriver
local TargetedSpellsDriver = {}

function TargetedSpellsDriver:Init()
	self.delay = 0.2
	---@type table<string, table<integer, boolean>>
	self.unitGroups = {}
	self.dirtyGroups = {}
	---@type TargetedSpellsGroup[]
	self.matchingGroups = {}
	---@type table<integer, TargetedSpellsGroupController>
	self.controllers = {}
	self.role = Private.Enum.Role.Damager
	self.contentType = Private.Enum.ContentType.OpenWorld
	self.OnCooldownDoneClosure = GenerateClosure(self.ReleaseCastFrames, self)
	self.pendingCasts = {}
	self.pendingHead = 1
	self.pendingTail = 0
	self.drainScheduled = false
	self.DrainPendingCastsClosure = GenerateClosure(self.DrainPendingCasts, self)
	self.OnFrameEventClosure = GenerateClosure(self.OnFrameEvent, self)
	---@type table<integer, TargetedSpellsShardFrame>
	self.shards = {}
	Private.EventRegistry:RegisterCallback(Private.Enum.Events.PROFILE_IMPORTED, self.OnProfileImported, self)
	Private.EventRegistry:RegisterCallback(Private.Enum.Events.GROUP_CHANGED, self.OnGroupChanged, self)
	Private.EventRegistry:RegisterCallback(Private.Enum.Events.GROUP_POSITION_CHANGED, self.OnGroupPositionChanged, self)
	self.activeEncounterId = nil
	self.capabilities = nil

	self:SetupFrame(true)
end

function TargetedSpellsDriver:GetController(group)
	local id = group.Id

	if self.controllers[id] == nil then
		self.controllers[id] = Private.GroupController.New(group)
	end

	return self.controllers[id]
end

function TargetedSpellsDriver:GetCapabilities()
	if self.capabilities == nil then
		self.capabilities = Private.Groups.ComputeCapabilities(TargetedSpellsSaved.Groups)
	end

	return self.capabilities
end

function TargetedSpellsDriver:InvalidateCapabilities()
	self.capabilities = nil
end

do
	---@type WowEvent[]
	local coreEvents = {
		"UNIT_TARGET",
		"UNIT_SPELLCAST_START",
		"UNIT_SPELLCAST_INTERRUPTED",
		"UNIT_SPELLCAST_STOP",
		"UNIT_SPELLCAST_CHANNEL_START",
		"UNIT_SPELLCAST_CHANNEL_STOP",
		"UNIT_SPELLCAST_EMPOWER_START",
		"UNIT_SPELLCAST_EMPOWER_STOP",
	}

	---@type WowEvent[]
	local interruptabilityEvents = {
		"UNIT_SPELLCAST_INTERRUPTIBLE",
		"UNIT_SPELLCAST_NOT_INTERRUPTIBLE",
	}

	function TargetedSpellsDriver:ConfigureShard(shard)
		local capabilities = self:GetCapabilities()

		if not capabilities.enabled then
			shard:UnregisterAllEvents()
			shard:SetScript("OnEvent", nil)

			return
		end

		shard:SetScript("OnEvent", self.OnFrameEventClosure)

		for _, event in ipairs(coreEvents) do
			shard:RegisterUnitEvent(event, unpack(shard.units))
		end

		local readsInterruptibility = capabilities.usesInterruptibility or capabilities.usesShield

		for _, event in ipairs(interruptabilityEvents) do
			if readsInterruptibility then
				shard:RegisterUnitEvent(event, unpack(shard.units))
			else
				shard:UnregisterEvent(event)
			end
		end
	end

	function TargetedSpellsDriver:EnsureShardForUnit(unit)
		local tokenIndex = tonumber(string.sub(unit, 10))
		local shardIndex = math.floor((tokenIndex - 1) / Constants.UnitEventConstants.MAX_UNIT_TOKENS_IN_EVENT) + 1

		if self.shards[shardIndex] ~= nil then
			return
		end

		local firstToken = (shardIndex - 1) * Constants.UnitEventConstants.MAX_UNIT_TOKENS_IN_EVENT + 1
		local units = {}

		for offset = 0, Constants.UnitEventConstants.MAX_UNIT_TOKENS_IN_EVENT - 1 do
			units[offset + 1] = "nameplate" .. (firstToken + offset)
		end

		---@type TargetedSpellsShardFrame
		local shard = CreateFrame("Frame", nil, self.frame)
		shard.units = units
		self.shards[shardIndex] = shard

		self:ConfigureShard(shard)
	end
end

function TargetedSpellsDriver:SetupFrame(isBoot)
	if isBoot then
		self.frame = CreateFrame("Frame", "TargetedSpellsDriverFrame", UIParent)
		self.frame:SetSize(1, 1)

		for _, group in pairs(TargetedSpellsSaved.Groups) do
			self:GetController(group):Position()
		end
	end

	local capabilities = self:GetCapabilities()

	if not capabilities.enabled then
		self.frame:UnregisterAllEvents()
		self.frame:SetScript("OnEvent", nil)

		CVarCallbackRegistry:UnregisterCallback("nameplateShowEnemies", self)
		CVarCallbackRegistry:UnregisterCallback("nameplateShowOffscreen", self)

		for _, shard in pairs(self.shards) do
			self:ConfigureShard(shard)
		end

		return
	end

	if not self.frame:IsEventRegistered("NAME_PLATE_UNIT_ADDED") then
		self.frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
		self.frame:RegisterEvent("LOADING_SCREEN_DISABLED")
		self.frame:RegisterEvent("UPDATE_INSTANCE_INFO")
		self.frame:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")
		self.frame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
		self.frame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
		self.frame:RegisterEvent("ENCOUNTER_START")
		self.frame:RegisterEvent("ENCOUNTER_END")

		self.frame:SetScript("OnEvent", self.OnFrameEventClosure)
	end

	CVarCallbackRegistry:RegisterCallback("nameplateShowEnemies", self.HandleShowEnemiesChanged, self)
	CVarCallbackRegistry:RegisterCallback("nameplateShowOffscreen", self.HandleShowOffscreenChanged, self)

	if capabilities.showsTargetMarker then
		self.frame:RegisterEvent("RAID_TARGET_UPDATE")
	else
		self.frame:UnregisterEvent("RAID_TARGET_UPDATE")
	end

	for _, shard in pairs(self.shards) do
		self:ConfigureShard(shard)
	end
end

do
	local nobody = {
		[Private.Enum.TargetClass.Nobody] = true
	}

	local everyone = {
		[Private.Enum.TargetClass.Player] = true,
		[Private.Enum.TargetClass.PartyMember] = true
	}

	function TargetedSpellsDriver:GetTargetClasses(info)
		local targetName = UnitSpellTargetName(info.unit)

		if targetName == nil then
			return nobody
		end

		return everyone
	end
end

---@param info SpellCastInfo
---@return integer acquired
function TargetedSpellsDriver:ProcessInfo(info)
	local dirtyGroups = self.dirtyGroups
	table.wipe(dirtyGroups)

	local unit = info.unit
	local groups = self.unitGroups[unit]

	if groups == nil then
		groups = {}
		self.unitGroups[unit] = groups
	else
		self:ReleaseFrameForUnit(unit, false, nil, dirtyGroups)
	end

	info.targetClasses = self:GetTargetClasses(info)

	local count = 0

	for _, group in ipairs(Private.Groups.GetMatching(info, TargetedSpellsSaved.Groups, self.matchingGroups)) do
		local controller = self:GetController(group)

		if controller:LoadConditionsApply(self.role, self.contentType) then
			controller:Acquire(info, self.OnCooldownDoneClosure)
			groups[group.Id] = true
			dirtyGroups[group.Id] = true
			count = count + 1
		end
	end

	if count == 0 then
		self:ReleaseFrameForUnit(unit, true, nil, dirtyGroups)
	end

	self:RepositionFrames(dirtyGroups)

	return count
end

---@param dirtyGroups table<integer, boolean>? nil = all controllers; otherwise the set to scope to
function TargetedSpellsDriver:RepositionFrames(dirtyGroups)
	if dirtyGroups == nil then
		for _, controller in pairs(self.controllers) do
			controller:Relayout()
		end

		return
	end

	for groupId in pairs(dirtyGroups) do
		local controller = self.controllers[groupId]

		if controller then
			controller:Relayout()
		end
	end
end

---@param dirtyGroups table<integer, boolean>? if given, records the id of every group that released something
---@return boolean
function TargetedSpellsDriver:ReleaseFrameForUnit(unit, removeUnit, id, dirtyGroups)
	local groups = self.unitGroups[unit]

	if groups == nil then
		return false
	end

	local cleanedSomethingUp = false
	local cleanedEverythingUp = true

	for groupId in pairs(groups) do
		local released, remaining = self.controllers[groupId]:ReleaseForUnit(unit, id)

		if released then
			cleanedSomethingUp = true

			if dirtyGroups ~= nil then
				dirtyGroups[groupId] = true
			end
		end

		if remaining then
			cleanedEverythingUp = false
		else
			groups[groupId] = nil
		end
	end

	if cleanedEverythingUp then
		if removeUnit then
			self.unitGroups[unit] = nil
		end

		return true
	end

	return cleanedSomethingUp
end

function TargetedSpellsDriver:UnitIsIrrelevant(unit, skipTargetCheck)
	if not UnitAffectingCombat(unit) or UnitCanAssist("player", unit) then
		return true
	end

	if skipTargetCheck then
		return false
	end

	local target = string.format("%starget", unit)

	if
		UnitExists(target)
		and (not UnitIsVisible(target) or UnitCanAttack("player", target) or IsInGroup() and not UnitInParty(target))
	then
		return true
	end

	return false
end

function TargetedSpellsDriver:GetCastInformation(unit)
	local _, _, _, _, _, _, _, _, castingSpellId, castingBarId = UnitCastingInfo(unit)

	if castingSpellId ~= nil then
		return false, castingSpellId, castingBarId, UnitCastingDuration(unit)
	end

	local _, _, _, _, _, _, _, channelSpellId, _, _, channelBarId = UnitChannelInfo(unit)

	if channelSpellId == nil then
		return false, nil, nil, nil
	end

	return true, channelSpellId, channelBarId, UnitChannelDuration(unit)
end

function TargetedSpellsDriver:DrainPendingCasts()
	self.drainScheduled = false

	local pending = self.pendingCasts
	local now = GetTime()
	local head = self.pendingHead
	local tail = self.pendingTail

	while head <= tail and pending[head].dueAt <= now do
		local info = pending[head]
		pending[head] = nil
		head = head + 1
		self:HandleDelayedStart(info, true)
	end

	if head > tail then
		self.pendingHead = 1
		self.pendingTail = 0
	else
		self.pendingHead = head
		self.drainScheduled = true
		C_Timer.After(pending[head].dueAt - now, self.DrainPendingCastsClosure)
	end
end

---@param instanceType string
---@param difficultyId number
---@return ContentType
local function ResolveContentType(instanceType, difficultyId)
	if instanceType == "raid" then
		return Private.Enum.ContentType.Raid
	end

	if instanceType == "party" and (difficultyId == DifficultyUtil.ID.DungeonTimewalker
			or difficultyId == DifficultyUtil.ID.DungeonNormal
			or difficultyId == DifficultyUtil.ID.DungeonHeroic
			or difficultyId == DifficultyUtil.ID.DungeonMythic
			or difficultyId == DifficultyUtil.ID.DungeonChallenge
			or difficultyId == 205 -- follower dungeons
		)
	then
		return Private.Enum.ContentType.Dungeon
	end

	if instanceType == "pvp" then
		return Private.Enum.ContentType.Battleground
	end

	if instanceType == "arena" then
		return Private.Enum.ContentType.Arena
	end

	if instanceType == "scenario" and difficultyId == 208 then
		return Private.Enum.ContentType.Delve
	end

	return Private.Enum.ContentType.OpenWorld
end

---@param specializationRole string|nil
---@return Role
local function ResolveRole(specializationRole)
	if specializationRole == "HEALER" then
		return Private.Enum.Role.Healer
	end

	if specializationRole == "TANK" then
		return Private.Enum.Role.Tank
	end

	return Private.Enum.Role.Damager
end

function TargetedSpellsDriver:OnFrameEvent(_, event, ...)
	if
		event == "UNIT_SPELLCAST_START"
		or event == "UNIT_SPELLCAST_CHANNEL_START"
		or event == "UNIT_SPELLCAST_EMPOWER_START"
	then
		self:HandleCastStart(...)
	elseif event == "UNIT_TARGET" then
		self:HandleUnitTarget(...)
	elseif event == "NAME_PLATE_UNIT_ADDED" then
		self:HandleNameplateAdded(...)
	elseif
		event == "UNIT_SPELLCAST_STOP"
		or event == "UNIT_SPELLCAST_CHANNEL_STOP"
		or event == "UNIT_SPELLCAST_EMPOWER_STOP"
		or event == "NAME_PLATE_UNIT_REMOVED"
		or event == "UNIT_SPELLCAST_INTERRUPTED"
	then
		self:HandleCastStop(event, ...)
	elseif
		event == "ZONE_CHANGED_NEW_AREA"
		or event == "LOADING_SCREEN_DISABLED"
		or event == "PLAYER_SPECIALIZATION_CHANGED"
		or event == "UPDATE_INSTANCE_INFO"
	then
		self:HandleWorldStateChanged(event)
	elseif event == "UNIT_SPELLCAST_INTERRUPTIBLE" or event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" then
		self:HandleInterruptibleChanged(event, ...)
	elseif event == "RAID_TARGET_UPDATE" then
		self:HandleRaidTargetUpdate()
	elseif event == "ENCOUNTER_START" then
		self:HandleEncounterStart(...)
	elseif event == "ENCOUNTER_END" then
		self:HandleEncounterEnd()
	end
end

function TargetedSpellsDriver:HandleCastStart(unit)
	if self:UnitIsIrrelevant(unit) then
		return
	end

	local now = GetTime()
	local tail = self.pendingTail + 1

	---@diagnostic disable-next-line: missing-fields
	self.pendingCasts[tail] = {
		unit = unit,
		startTime = now,
		dueAt = now + self.delay,
	}
	self.pendingTail = tail

	if not self.drainScheduled then
		self.drainScheduled = true
		C_Timer.After(self.delay, self.DrainPendingCastsClosure)
	end
end

function TargetedSpellsDriver:HandleUnitTarget(unit)
	if self:UnitIsIrrelevant(unit) then
		return
	end

	local isChannel, spellId, castId, duration = self:GetCastInformation(unit)

	if spellId == nil or duration == nil then
		return
	end

	self:HandleDelayedStart({
		unit = unit,
		spellId = spellId,
		startTime = GetTime(),
		id = castId,
		isChannel = isChannel,
		isRetarget = true,
		duration = duration
	}, false)
end

function TargetedSpellsDriver:HandleNameplateAdded(unit)
	self:EnsureShardForUnit(unit)

	if self:UnitIsIrrelevant(unit) then
		return
	end


	local isChannel, spellId, castId, duration = self:GetCastInformation(unit)

	if spellId == nil or duration == nil then
		return
	end

	-- todo: startTime is wrong, but we can't do better yet
	self:ProcessInfo({
		unit = unit,
		spellId = spellId,
		startTime = GetTime(),
		id = castId,
		duration = duration,
		isChannel = isChannel,
	})
end

function TargetedSpellsDriver:HandleShowEnemiesChanged(value)
	if value == 0 or value == "0" then
		self:ReleaseAllOwnFrames()
	end
end

function TargetedSpellsDriver:HandleShowOffscreenChanged(value)
	if value ~= "1" and value ~= 1 then
		Private.Utils.ShowStaticPopup({
			text = Private.L.Functionality.CVarWarning,
			button1 = ENABLE,
			button2 = CLOSE,
			OnAccept = function()
				C_CVar.SetCVar("nameplateShowOffscreen", 1)
			end,
		})
	end
end

function TargetedSpellsDriver:HandleCastStop(event, ...)
	---@type string
	local unit = ...

	if self:UnitIsIrrelevant(unit, true) then
		return
	end

	local groups = self.unitGroups[unit]
	Private.TextToSpeechUtil.ClearAnnouncementCacheForUnit(unit)

	if groups == nil or next(groups) == nil then
		return
	end

	---@type number|nil
	local id = nil
	---@type string|nil
	local interruptedBy = nil

	if event == "UNIT_SPELLCAST_CHANNEL_STOP" or event == "UNIT_SPELLCAST_INTERRUPTED" then
		interruptedBy, id = select(4, ...)
	elseif event == "UNIT_SPELLCAST_EMPOWER_STOP" then
		interruptedBy, id = select(5, ...)
	elseif event == "UNIT_SPELLCAST_STOP" then
		id = select(4, ...)
	end

	self:MaybeMarkAsInterruptedAndDelay(unit, id, interruptedBy)

	local dirtyGroups = self.dirtyGroups
	table.wipe(dirtyGroups)

	if self:ReleaseFrameForUnit(unit, true, id, dirtyGroups) then
		self:RepositionFrames(dirtyGroups)
	end
end

function TargetedSpellsDriver:HandleDelayedStart(info, reverify)
	if reverify then
		local isChannel, spellId, castId, duration = self:GetCastInformation(info.unit)

		info.isChannel = isChannel
		info.spellId = spellId
		info.id = castId
		info.duration = duration
	end

	-- the cast ended during the delay, or has no duration at all — the latter is what happens
	-- without `nameplateShowOffscreen`, for a unit the camera cannot see
	if info.spellId == nil or info.duration == nil then
		return
	end

	local acquired = self:ProcessInfo(info)

	if info.isRetarget then
		return
	end

	if acquired == 0 and not self:AnyGroupLoadConditionsAllow() then
		return
	end

	Private.TextToSpeechUtil.MaybeAnnounceSpell(info, self.contentType, self.activeEncounterId)
end

function TargetedSpellsDriver:HandleWorldStateChanged(event)
	if event == "LOADING_SCREEN_DISABLED" then
		self:CleanupDanglingFrames()
	end

	local _, instanceType, difficultyId = GetInstanceInfo()

	self.contentType = ResolveContentType(instanceType, difficultyId)
	self.role = ResolveRole(GetSpecializationRoleByID(PlayerUtil.GetCurrentSpecID()))
end

function TargetedSpellsDriver:HandleInterruptibleChanged(event, unit)
	if self:UnitIsIrrelevant(unit) then
		return
	end

	local groups = self.unitGroups[unit]

	if groups == nil then
		return
	end

	local isInterruptible = event == "UNIT_SPELLCAST_INTERRUPTIBLE"

	for groupId in pairs(groups) do
		self.controllers[groupId]:SetInterruptibleForUnit(unit, isInterruptible)
	end
end

function TargetedSpellsDriver:HandleRaidTargetUpdate()
	for _, controller in pairs(self.controllers) do
		controller:UpdateTargetMarkers()
	end
end

function TargetedSpellsDriver:HandleEncounterStart(encounterId)
	self.activeEncounterId = encounterId
end

function TargetedSpellsDriver:HandleEncounterEnd()
	self.activeEncounterId = nil
end

function TargetedSpellsDriver:CleanupDanglingFrames()
	local cleanedSomethingUp = false

	for unit in pairs(self.unitGroups) do
		local thisUnitWasCleanedUp = self:ReleaseFrameForUnit(unit, true)

		Private.TextToSpeechUtil.ClearAnnouncementCacheForUnit(unit)

		cleanedSomethingUp = cleanedSomethingUp or thisUnitWasCleanedUp
	end

	if cleanedSomethingUp then
		self:RepositionFrames()
	end
end

-- Release through controllers; pools are shared with preview frames.
function TargetedSpellsDriver:ReleaseAllOwnFrames()
	for _, controller in pairs(self.controllers) do
		controller:ReleaseAll()
	end

	table.wipe(self.unitGroups)
end

function TargetedSpellsDriver:OnProfileImported()
	self:ReleaseAllOwnFrames()

	-- The routing index is already empty after ReleaseAllOwnFrames.
	for id, controller in pairs(self.controllers) do
		if TargetedSpellsSaved.Groups[id] == nil then
			controller:Discard()
			self.controllers[id] = nil
		end
	end

	for _, group in pairs(TargetedSpellsSaved.Groups) do
		local controller = self:GetController(group)
		controller:Reconfigure(group)
		controller:Position()
	end

	self:InvalidateCapabilities()
	self:SetupFrame(false)
end

---@param group TargetedSpellsGroup
function TargetedSpellsDriver:RefreshGroup(group)
	local groupId = group.Id
	local controller = self:GetController(group)

	controller:ReleaseAll()

	for _, groups in pairs(self.unitGroups) do
		groups[groupId] = nil
	end

	controller:Position()
end

---@param groupId integer
function TargetedSpellsDriver:OnGroupChanged(groupId)
	local group = TargetedSpellsSaved.Groups[groupId]
	if group == nil then
		return
	end

	self:RefreshGroup(group)
	self:GetController(group):Reconfigure(group)
	self:InvalidateCapabilities()
	self:SetupFrame(false)

	local dirtyGroups = self.dirtyGroups
	table.wipe(dirtyGroups)
	dirtyGroups[groupId] = true
	self:RepositionFrames(dirtyGroups)
end

function TargetedSpellsDriver:OnGroupPositionChanged(groupId)
	local group = TargetedSpellsSaved.Groups[groupId]

	if group ~= nil then
		self:GetController(group):Position()
	end
end

function TargetedSpellsDriver:MaybeMarkAsInterruptedAndDelay(unit, id, interruptedBy)
	if not self:GetCapabilities().indicatesInterrupts then
		return
	end

	-- either via events that don't communicate interruptedBy, or via interrupt events briefly before deaths
	if interruptedBy == nil then
		return
	end

	-- event gets sent when unit dies mid-cast, incorrectly implying it was interrupted
	if not UnitExists(unit) then
		return
	end

	local interruptName = UnitNameFromGUID(interruptedBy)
	---@type string?
	local className = select(2, UnitClassFromGUID(interruptedBy))
	local interruptColor = nil

	if className ~= nil then
		interruptColor = C_ClassColor.GetClassColor(className)
	end

	local groups = self.unitGroups[unit]

	if groups == nil then
		return
	end

	local anyIndicated = false

	for groupId in pairs(groups) do
		if self.controllers[groupId]:MarkInterruptedForUnit(unit, interruptName, interruptColor) then
			anyIndicated = true
		end
	end

	if not anyIndicated then
		return
	end

	---@type DelayInfo
	local delayInfo = {
		unit = unit,
		id = id,
	}

	C_Timer.After(1, GenerateClosure(self.ReleaseCastFrames, self, delayInfo))
end

function TargetedSpellsDriver:ReleaseCastFrames(info)
	local dirtyGroups = self.dirtyGroups
	table.wipe(dirtyGroups)

	if self:ReleaseFrameForUnit(info.unit, true, info.id, dirtyGroups) then
		self:RepositionFrames(dirtyGroups)
	end
end

function TargetedSpellsDriver:AnyGroupLoadConditionsAllow()
	for _, group in pairs(TargetedSpellsSaved.Groups) do
		if group.Enabled then
			local controller = self:GetController(group)

			if controller:LoadConditionsApply(self.role, self.contentType) then
				return true
			end
		end
	end

	return false
end

table.insert(Private.LoginFnQueue, GenerateClosure(TargetedSpellsDriver.Init, TargetedSpellsDriver))
