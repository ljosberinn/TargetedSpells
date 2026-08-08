---@type string, TargetedSpells
local addonName, Private = ...

---@class TargetedSpellsDriver
local TargetedSpellsDriver = {}

function TargetedSpellsDriver:Init()
	self.delay = 0.2
	-- Routing index: unit -> the set of group ids currently displaying that unit. Holds
	-- ids, never frames — frame ownership is the controllers' alone. Events arrive keyed
	-- by unit, so this is what turns a unit into the (usually one or two) controllers
	-- that have anything to say about it, without fanning out over every group.
	---@type table<string, table<integer, boolean>>
	self.unitGroups = {}
	self.dirtyGroups = {}
	-- scratch for Groups.GetMatching, reused per cast (ProcessInfo iterates it and drops it)
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
	-- OnFrameEvent ignores the frame it was invoked for, so the driver frame and every shard share this one closure
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

	-- Being driven from NAME_PLATE_UNIT_ADDED is what makes creating these lazily safe: a cast
	-- starting after this point reaches the shard normally, and one already running when the
	-- nameplate appeared is picked up by HandleNameplateAdded itself. The only window a fresh
	-- shard can miss is the one that handler already covers.
	function TargetedSpellsDriver:EnsureShardForUnit(unit)
		-- `unit` is always a nameplate token, so the suffix past "nameplate" is always numeric
		local tokenIndex = tonumber(string.sub(unit, 10))
		local shardIndex = math.floor((tokenIndex - 1) / Constants.UnitEventConstants.MAX_UNIT_TOKENS_IN_EVENT) + 1

		if self.shards[shardIndex] ~= nil then
			return
		end

		-- the whole slice is registered now, so the other tokens in it cost nothing when their
		-- nameplates show up later
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

-- Ensures the driver frame exists and its event registration matches the current
-- group state. Safe to call repeatedly: the driver frame's own events wire a single time
-- (they never change while any display is active), while the enabled/disabled teardown and
-- the conditional events (interruptibility colours, target marker) are reconciled on every
-- call — so a group edit that toggles them takes effect live rather than at the next reload.
--
-- Carries only what is not per-unit; the spellcast events live on the shards.
-- PLAYER_SPECIALIZATION_CHANGED stays here because "player" needs no shard.
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
		-- no display active: stop listening entirely until a group is re-enabled
		self.frame:UnregisterAllEvents()
		self.frame:SetScript("OnEvent", nil)

		-- the CVar callbacks live outside the frame, so UnregisterAllEvents above does not
		-- reach them the way it used to reach the CVAR_UPDATE registration
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

	-- shards that already exist follow the new capabilities; later ones pick them up on
	-- creation, from the same function
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

-- Classifies a cast and hands it to every matching, loaded group. Returns how many groups
-- acquired a frame for it — a non-zero count means at least one group's load conditions
-- allowed, which is what the TTS gate in HandleDelayedStart needs to know.
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
		-- the unit was already displayed (a retarget, or a new cast replacing the old);
		-- drop what it had before re-classifying. removeUnit is false: we are about to
		-- write into `groups`, so the entry must survive even if it empties out here.
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

-- Relayouts group controllers. With no argument, every controller relayouts (global
-- refreshes: dangling cleanup, container moves; empty controllers no-op). With a
-- dirtyGroups set {[groupId]=true}, only those controllers relayout — a group's layout
-- is self-contained (the controller chains its frames under its own container), so a
-- lifecycle event that changed one group's membership must not pay the ~12 C-side frame
---@param dirtyGroups table<integer, boolean>? nil = all controllers; otherwise the set to scope to
function TargetedSpellsDriver:RepositionFrames(dirtyGroups)
	if dirtyGroups == nil then
		for _, controller in pairs(self.controllers) do
			controller:Relayout()
		end

		return
	end

	-- A dirty group was always dirtied by an Acquire/Release, so its controller already
	-- exists: index self.controllers directly (no lazy-create, no saved-vars lookup).
	-- Iterating all controllers here would re-sort/re-anchor non-dirty groups and break
	-- the scoping guarantee (spec/reposition_scope_spec.lua: "group B never re-anchored").
	for groupId in pairs(dirtyGroups) do
		local controller = self.controllers[groupId]

		if controller then
			controller:Relayout()
		end
	end
end

-- Asks every controller currently displaying `unit` to drop its frames for it. The
-- routing entry is pruned as controllers report themselves empty, so it stays an exact
-- description of who holds what — a controller that still has a lingering interrupt
-- frame keeps its id in the set and will be revisited by the delayed cleanup.
---@param dirtyGroups table<integer, boolean>? if given, records the id of every group that released something
---@return boolean
function TargetedSpellsDriver:ReleaseFrameForUnit(unit, removeUnit, id, dirtyGroups)
	local groups = self.unitGroups[unit]

	if groups == nil then
		return false
	end

	local cleanedSomethingUp = false
	local cleanedEverythingUp = true

	-- clearing keys of the table being traversed is well-defined in Lua, so pruning
	-- the routing set as we go is safe here
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
	if
		not UnitAffectingCombat(unit)
	then
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
		-- fully drained: reset cursors so indices don't climb forever
		self.pendingHead = 1
		self.pendingTail = 0
	else
		-- next entry isn't due yet; reschedule the single timer for it
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

	-- equivalent to `instanceType == "none"`
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

-- Queues the cast rather than acting on it: the target is not reliable this early, so
-- everything real happens once the drain timer fires HandleDelayedStart.
function TargetedSpellsDriver:HandleCastStart(unit)
	if self:UnitIsIrrelevant(unit) then
		return
	end

	local now = GetTime()
	local tail = self.pendingTail + 1

	-- Only what the drain cannot read back off the unit: which unit, when the cast actually
	-- began, and when to look. spellId/castId/isChannel/duration are all re-derived in
	-- HandleDelayedStart, so nothing queued here can go stale.
	--
	-- `startTime` is the exception and has to be captured now. The real value is available as
	-- UnitCastingInfo's startTimeMs, but that call is SecretWhenUnitSpellCastRestricted, so the
	-- value is a plain number in most content and secret in PvP — and Utils.SortFrames orders
	-- frames with `<` on it. A sort key that works everywhere except arenas is worse than an
	-- approximate one, which is what the `startTime is wrong` note in HandleNameplateAdded is about.
	--
	-- Deliberately partial: the four missing fields are what `reverify` exists to fill, and
	-- nothing reads them before HandleDelayedStart has.
	---@diagnostic disable-next-line: missing-fields
	self.pendingCasts[tail] = {
		unit = unit,
		startTime = now,
		dueAt = now + self.delay,
	}
	self.pendingTail = tail

	-- one timer serves the whole queue; only (re)start it when nothing is scheduled
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

-- Enemy nameplates off means every tracked unit's plate is gone, so nothing we are showing
-- can still be valid.
function TargetedSpellsDriver:HandleShowEnemiesChanged(value)
	if value == 0 or value == "0" then
		self:ReleaseAllOwnFrames()
	end
end

-- Without this one, casts from units the camera cannot see never get a duration, so
-- HandleDelayedStart drops them (see its `info.duration == nil` guard).
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

	-- nothing on screen for this unit: the single hash lookup that keeps the stop
	-- events of every non-matching cast in a pull off the rest of this path
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

-- `reverify` means "this info was captured earlier and anything in it may be stale": read the
-- cast back off the unit. Only the queue takes it — a caller that has just read the unit itself
-- passes false and keeps what it found.
--
-- Re-reading everything rather than just the duration is what makes the queue entry a note
-- ("look at this unit at time T") instead of a snapshot. It also means no caller has to map an
-- event name onto isChannel, which is what used to drop empowered casts: GetCastInformation is
-- the single thing that knows an empower is served by the channel APIs.
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

	-- ProcessInfo has just tested LoadConditionsApply for every group this cast matched, so
	-- anything it acquired already answers the gate; only a cast that matched nothing (or
	-- matched only unloaded groups) has to pay for the full walk over every group.
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
	-- global event: every group's frames may need a new marker, so this is the one
	-- path that legitimately visits all controllers rather than routing by unit
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

-- Releases every frame the Driver itself acquired and clears the routing index.
-- Deliberately NOT Pools:ReleaseAll — the Bar/Icon pools are shared with the EditMode
-- and Designer demo frames, which the Driver does not own; releasing those out from
-- under a live demo double-releases (assertsafe error) and can alias a demo frame onto
-- a live cast. Going through the controllers satisfies that by construction: a
-- controller only ever holds frames it acquired for a live cast.
function TargetedSpellsDriver:ReleaseAllOwnFrames()
	for _, controller in pairs(self.controllers) do
		controller:ReleaseAll()
	end

	table.wipe(self.unitGroups)
end

-- A v4 profile import updates the group tables in place (Utils.ImportV4Profile),
-- so refs stay valid; here we drop live frames (they re-acquire with the new
-- settings), reconfigure + reposition every controller (a v4 import can change a
-- group's Template in place), and re-evaluate event registration. Reconfigure is
-- safe here because ReleaseAllOwnFrames just cleared every live frame.
function TargetedSpellsDriver:OnProfileImported()
	self:ReleaseAllOwnFrames()

	-- a delete (EditMode.DeleteGroup routes here) or an import can drop a group
	-- outright; its controller would otherwise linger holding a stale group ref and a
	-- shown, empty container. Safe after ReleaseAllOwnFrames: the routing index is wiped,
	-- so no unit can still name a controller we drop here.
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

-- Releases just one group's live frames (they re-acquire with the current settings
-- on the next cast) and repositions its container. Shared by the group-change refresh.
---@param group TargetedSpellsGroup
function TargetedSpellsDriver:RefreshGroup(group)
	local groupId = group.Id
	local controller = self:GetController(group)

	controller:ReleaseAll()

	-- the group no longer displays anything, so drop it from every unit's routing set.
	-- Units left with an empty set are harmless (they fall out on the next cast or
	-- CleanupDanglingFrames) and the unit key space is bounded by the nameplate count.
	for _, groups in pairs(self.unitGroups) do
		groups[groupId] = nil
	end

	controller:Position()
end

-- Fired when an edit-mode setting changes a group's container/behaviour. Refreshes
-- that group's live frames + container and re-evaluates event registration (marker /
-- interruptibility / enabled may have changed). The group's edit-mode instance
-- handles its own demo refresh.
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

	-- only this group's frames/container changed; other groups are untouched
	local dirtyGroups = self.dirtyGroups
	table.wipe(dirtyGroups)
	dirtyGroups[groupId] = true
	self:RepositionFrames(dirtyGroups)
end

-- Position-only refresh (a drag): the container moves but capabilities are unchanged,
-- so the cache is left intact. Group *create* deliberately goes through GROUP_CHANGED,
-- not this event, precisely because it does change capabilities (see EditMode.CreateGroup).
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

	-- each controller decides for itself whether its group indicates interrupts
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

-- A cast is finished with, by whichever route: its cooldown ran out, or the interrupt
-- indication above finished lingering. Both callers hand over something carrying the
-- unit and the cast id, which is all the release needs.
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
