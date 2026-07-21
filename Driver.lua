---@type string, TargetedSpells
local addonName, Private = ...

---@class TargetedSpellsDriver
local TargetedSpellsDriver = {}

function TargetedSpellsDriver:Init()
	self.delay = 0.2
	-- secondary index: unit -> its live frames, for release-by-unit (events arrive
	-- keyed by unit). Primary frame ownership lives on each group's controller.
	self.frames = {}
	self.dirtyGroups = {}
	---@type table<integer, TargetedSpellsGroupController>
	self.controllers = {}
	self.role = Private.Enum.Role.Damager
	self.contentType = Private.Enum.ContentType.OpenWorld
	self.OnCooldownDoneClosure = GenerateClosure(self.OnCooldownDone, self)
	self.pendingCasts = {}
	self.pendingHead = 1
	self.pendingTail = 0
	self.drainScheduled = false
	self.DrainPendingCastsClosure = GenerateClosure(self.DrainPendingCasts, self)
	Private.EventRegistry:RegisterCallback(Private.Enum.Events.PROFILE_IMPORTED, self.OnProfileImported, self)
	Private.EventRegistry:RegisterCallback(Private.Enum.Events.GROUP_CHANGED, self.OnGroupChanged, self)
	Private.EventRegistry:RegisterCallback(Private.Enum.Events.GROUP_POSITION_CHANGED, self.OnGroupPositionChanged, self)
	self.activeEncounterId = nil
	self.capabilities = nil

	-- denormalise the id onto each group so frames can find their container
	for id, group in pairs(TargetedSpellsSaved.Groups) do
		group.Id = id
	end

	self:SetupFrame(true)
end

-- ── Group controllers ────────────────────────────────────────────────────────
-- Per-group display state (container, pool, active frames, layout) lives on a
-- TargetedSpellsGroupController, created lazily on first use. Takes the group table
-- (not just an id) so callers that already hold it skip a TargetedSpellsSaved lookup
-- that would return nil for a group deleted mid-flight — the ReleaseFrame path can
-- outlive the group.
---@param group TargetedSpellsGroup
---@return TargetedSpellsGroupController
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

-- Ensures the driver frame exists and its event registration matches the current
-- group state. Safe to call repeatedly: the core spellcast/nameplate events wire a
-- single time (they never change while any display is active), while the enabled/
-- disabled teardown and the conditional events (interruptibility colours, target
-- marker) are reconciled on every call — so a group edit that toggles them takes
-- effect live rather than at the next reload.
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
		return
	end

	-- core events are the same for any active display; register them once
	if not self.frame:IsEventRegistered("UNIT_SPELLCAST_START") then
		self.frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
		self.frame:RegisterEvent("LOADING_SCREEN_DISABLED")
		self.frame:RegisterEvent("UPDATE_INSTANCE_INFO")
		self.frame:RegisterUnitEvent("UNIT_TARGET")
		self.frame:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")
		self.frame:RegisterUnitEvent("UNIT_SPELLCAST_START")
		self.frame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED")
		self.frame:RegisterUnitEvent("UNIT_SPELLCAST_STOP")
		self.frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START")
		self.frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP")
		self.frame:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_START")
		self.frame:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_STOP")
		self.frame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
		self.frame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
		self.frame:RegisterEvent("CVAR_UPDATE")
		self.frame:RegisterEvent("ENCOUNTER_START")
		self.frame:RegisterEvent("ENCOUNTER_END")

		self.frame:SetScript("OnEvent", GenerateClosure(self.OnFrameEvent, self))
	end

	if capabilities.usesInterruptibility or capabilities.usesShield then
		self.frame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTIBLE")
		self.frame:RegisterUnitEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE")
	else
		self.frame:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE")
		self.frame:UnregisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE")
	end

	if capabilities.showsTargetMarker then
		self.frame:RegisterEvent("RAID_TARGET_UPDATE")
	else
		self.frame:UnregisterEvent("RAID_TARGET_UPDATE")
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

function TargetedSpellsDriver:ProcessInfo(info)
	local dirtyGroups = self.dirtyGroups
	table.wipe(dirtyGroups)

	if self.frames[info.unit] == nil then
		self.frames[info.unit] = {}
	else
		self:ReleaseFrameForUnit(info.unit, false, nil, dirtyGroups)
	end

	info.targetClasses = self:GetTargetClasses(info)

	local count = 0

	for _, group in ipairs(Private.Groups.GetMatching(info, TargetedSpellsSaved.Groups)) do
		local controller = self:GetController(group)

		if controller:LoadConditionsApply(self.role, self.contentType) then
			local frame = controller:Acquire(info, self.OnCooldownDoneClosure)
			table.insert(self.frames[info.unit], frame)
			dirtyGroups[group.Id] = true
			count = count + 1
		end
	end

	if count == 0 then
		self:ReleaseFrameForUnit(info.unit, true, nil, dirtyGroups)
	end

	self:RepositionFrames(dirtyGroups)
end

---@param frame TargetedSpellsIconMixin|TargetedSpellsBarMixin
function TargetedSpellsDriver:ReleaseFrame(frame)
	self:GetController(frame:GetGroup()):Release(frame)
end

-- Relayouts group controllers. With no argument, every controller relayouts (global
-- refreshes: dangling cleanup, container moves; empty controllers no-op). With a
-- dirtyGroups set {[groupId]=true}, only those controllers relayout — a group's layout
-- is self-contained (the controller chains its frames under its own container), so a
-- lifecycle event that changed one group's membership must not pay the ~12 C-side frame
-- ops per frame to re-anchor every *other* group. See sprint-3.
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

---@param dirtyGroups table<integer, boolean>? if given, records the group id of every released frame
function TargetedSpellsDriver:ReleaseFrameForUnit(unit, removeUnit, id, dirtyGroups)
	local frames = self.frames[unit]

	if frames == nil then
		return false
	end

	local cleanedSomethingUp = false
	local cleanedEverythingUp = true

	for i = #frames, 1, -1 do
		local frame = frames[i]

		if frame then
			if frame:CanBeHidden(id) then
				if dirtyGroups ~= nil then
					local group = frame:GetGroup()

					if group ~= nil then
						dirtyGroups[group.Id] = true
					end
				end

				self:ReleaseFrame(frame)
				table.remove(frames, i)
				cleanedSomethingUp = true
			else
				cleanedEverythingUp = false
			end
		end
	end

	if cleanedEverythingUp then
		table.wipe(frames)

		if removeUnit then
			self.frames[unit] = nil
		end

		return true
	end

	return cleanedSomethingUp
end

function TargetedSpellsDriver:UnitIsIrrelevant(unit, skipTargetCheck)
	if
		string.sub(unit, 1, 9) ~= "nameplate"
		or UnitInParty(unit)
		or UnitIsFriend(unit, "player")
		or not UnitAffectingCombat(unit)
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
	local isChannel = false
	local _, _, _, _, _, _, _, _, spellId, castId = UnitCastingInfo(unit)

	if spellId == nil then
		_, _, _, _, _, _, _, spellId, _, _, castId = UnitChannelInfo(unit)
		isChannel = true
	end

	return isChannel, spellId, castId
end

-- Drains every pending cast that has come due, dispatching each through the
-- DELAYED_UNIT_SPELLCAST_START branch (which recomputes duration and self-cancels
-- stale casts). Entries carry their own dueAt, so this stays correct if self.delay
-- ever becomes per-cast; with the constant delay the queue is already in dueAt order.
-- OnFrameEvent's delayed branch never enqueues, so mutating the queue mid-loop is safe.
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
		self:OnFrameEvent(self.frame, Private.Enum.Events.DELAYED_UNIT_SPELLCAST_START, info)
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

---@param _ Frame -- identical to self.frame
---@param event string
function TargetedSpellsDriver:OnFrameEvent(_, event, ...)
	if
		event == "UNIT_SPELLCAST_START"
		or event == "UNIT_SPELLCAST_CHANNEL_START"
		or event == "UNIT_SPELLCAST_EMPOWER_START"
	then
		local unit, castGuid, spellId, id = ...

		if self:UnitIsIrrelevant(unit) then
			return
		end

		local isChannel = false

		if event == "UNIT_SPELLCAST_EMPOWER_START" then
			spellId, id = select(3, ...)
		elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
			isChannel = true
		end

		local now = GetTime()
		local tail = self.pendingTail + 1

		self.pendingCasts[tail] = {
			unit = unit,
			spellId = spellId,
			startTime = now,
			id = id,
			isChannel = isChannel,
			dueAt = now + self.delay,
		}
		self.pendingTail = tail

		-- one timer serves the whole queue; only (re)start it when nothing is scheduled
		if not self.drainScheduled then
			self.drainScheduled = true
			C_Timer.After(self.delay, self.DrainPendingCastsClosure)
		end
	elseif event == "UNIT_TARGET" then
		---@type string
		local unit = ...

		if self:UnitIsIrrelevant(unit) then
			return
		end

		local isChannel, spellId, castId = self:GetCastInformation(unit)

		self:OnFrameEvent(self.frame, Private.Enum.Events.DELAYED_UNIT_SPELLCAST_START, {
			unit = unit,
			spellId = spellId,
			startTime = GetTime(),
			id = castId,
			isChannel = isChannel,
			isRetarget = true,
		})
	elseif event == "NAME_PLATE_UNIT_ADDED" then
		---@type string
		local unit = ...

		if self:UnitIsIrrelevant(unit) then
			return
		end

		local isChannel, spellId, castId = self:GetCastInformation(unit)
		local duration = (isChannel and UnitChannelDuration(unit) or nil) or UnitCastingDuration(unit)

		if duration == nil then
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
	elseif event == "CVAR_UPDATE" then
		local name, value = ...

		if name == "nameplateShowEnemies" then
			if value == 0 or value == "0" then
				self:ReleaseAllOwnFrames()
			end
		elseif name == "nameplateShowOffscreen" then
			if value == "1" or value == 1 then
			else
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
	elseif
		event == "UNIT_SPELLCAST_STOP"
		or event == "UNIT_SPELLCAST_CHANNEL_STOP"
		or event == "UNIT_SPELLCAST_EMPOWER_STOP"
		or event == "NAME_PLATE_UNIT_REMOVED"
		or event == "UNIT_SPELLCAST_INTERRUPTED"
	then
		---@type string
		local unit = ...

		if self:UnitIsIrrelevant(unit, true) then
			return
		end

		local frames = self.frames[unit]
		Private.TextToSpeechUtil.ClearAnnouncementCacheForUnit(unit)

		if frames == nil or #frames == 0 then
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
	elseif event == Private.Enum.Events.DELAYED_UNIT_SPELLCAST_START then
		---@type SpellCastInfo
		local info = ...

		-- cast vanished during the delay
		info.duration = info.isChannel and UnitChannelDuration(info.unit) or UnitCastingDuration(info.unit)

		-- without `nameplateShowOffscreen` active, castTime may stay nil
		if info.duration == nil then
			return
		end

		self:ProcessInfo(info)

		if info.isRetarget or not self:AnyGroupLoadConditionsAllow() then
			return
		end

		Private.TextToSpeechUtil.MaybeAnnounceSpell(info, self.contentType, self.activeEncounterId)
	elseif event == Private.Enum.Events.DELAYED_FRAME_CLEANUP then
		---@type DelayInfo
		local delayInfo = ...

		local dirtyGroups = self.dirtyGroups
		table.wipe(dirtyGroups)

		if self:ReleaseFrameForUnit(delayInfo.unit, true, delayInfo.id, dirtyGroups) then
			self:RepositionFrames(dirtyGroups)
		end
	elseif
		event == "ZONE_CHANGED_NEW_AREA"
		or event == "LOADING_SCREEN_DISABLED"
		or event == "PLAYER_SPECIALIZATION_CHANGED"
		or event == "UPDATE_INSTANCE_INFO"
	then
		if event == "LOADING_SCREEN_DISABLED" then
			self:CleanupDanglingFrames()
		end

		local _, instanceType, difficultyId = GetInstanceInfo()
		-- equivalent to `instanceType == "none"`
		local nextContentType = Private.Enum.ContentType.OpenWorld

		if instanceType == "raid" then
			nextContentType = Private.Enum.ContentType.Raid
		elseif instanceType == "party" then
			if
				difficultyId == DifficultyUtil.ID.DungeonTimewalker
				or difficultyId == DifficultyUtil.ID.DungeonNormal
				or difficultyId == DifficultyUtil.ID.DungeonHeroic
				or difficultyId == DifficultyUtil.ID.DungeonMythic
				or difficultyId == DifficultyUtil.ID.DungeonChallenge
				or difficultyId == 205 -- follower dungeons
			then
				nextContentType = Private.Enum.ContentType.Dungeon
			end
		elseif instanceType == "pvp" then
			nextContentType = Private.Enum.ContentType.Battleground
		elseif instanceType == "arena" then
			nextContentType = Private.Enum.ContentType.Arena
		elseif instanceType == "scenario" then
			if difficultyId == 208 then
				nextContentType = Private.Enum.ContentType.Delve
			end
		end

		self.contentType = nextContentType

		local specId = PlayerUtil.GetCurrentSpecID()
		local role = GetSpecializationRoleByID(specId)

		if
			role == "HEALER"
		then
			self.role = Private.Enum.Role.Healer
		elseif role == "TANK" then
			self.role = Private.Enum.Role.Tank
		else
			self.role = Private.Enum.Role.Damager
		end
	elseif event == "UNIT_SPELLCAST_INTERRUPTIBLE" or event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" then
		local unit = ...

		if self:UnitIsIrrelevant(unit) then
			return
		end

		local frames = self.frames[unit]

		if frames == nil or #frames == 0 then
			return
		end

		local isInterruptible = event == "UNIT_SPELLCAST_INTERRUPTIBLE"

		for _, frame in ipairs(frames) do
			if frame.AdjustInterruptibleColor then
				frame:AdjustInterruptibleColor(isInterruptible)
				frame:AdjustInterruptShield(isInterruptible)
			end
		end
	elseif event == "RAID_TARGET_UPDATE" then
		for _, frames in pairs(self.frames) do
			for _, frame in ipairs(frames) do
				if frame.SetTargetMarker then
					frame:SetTargetMarker()
				end
			end
		end
	elseif event == "ENCOUNTER_START" then
		local encounterId = ...
		self.activeEncounterId = encounterId
	elseif event == "ENCOUNTER_END" then
		self.activeEncounterId = nil
	end
end

function TargetedSpellsDriver:CleanupDanglingFrames()
	local cleanedSomethingUp = false

	for unit in pairs(self.frames) do
		local thisUnitWasCleanedUp = self:ReleaseFrameForUnit(unit, true)

		Private.TextToSpeechUtil.ClearAnnouncementCacheForUnit(unit)

		cleanedSomethingUp = cleanedSomethingUp or thisUnitWasCleanedUp
	end

	if cleanedSomethingUp then
		self:RepositionFrames()
	end
end

-- Releases every frame the Driver itself acquired and clears the live frame set.
-- Deliberately NOT Pools:ReleaseAll — the Bar/Icon pools are shared with the EditMode
-- and Designer demo frames, which the Driver does not own; releasing those out from
-- under a live demo double-releases (assertsafe error) and can alias a demo frame onto
-- a live cast.
function TargetedSpellsDriver:ReleaseAllOwnFrames()
	for _, frames in pairs(self.frames) do
		for _, frame in ipairs(frames) do
			self:ReleaseFrame(frame)
		end
	end

	table.wipe(self.frames)
end

-- A v4 profile import updates the group tables in place (Utils.ImportV4Profile),
-- so refs stay valid; here we drop live frames (they re-acquire with the new
-- settings), reconfigure + reposition every controller (a v4 import can change a
-- group's Template in place), and re-evaluate event registration. Reconfigure is
-- safe here because ReleaseAllOwnFrames just cleared every live frame.
function TargetedSpellsDriver:OnProfileImported()
	self:ReleaseAllOwnFrames()

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
	for _, frames in pairs(self.frames) do
		for index = #frames, 1, -1 do
			if frames[index]:GetGroup() == group then
				self:ReleaseFrame(frames[index])
				table.remove(frames, index)
			end
		end
	end

	self:GetController(group):Position()
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

	local frames = self.frames[unit]
	local anyIndicated = false

	for _, frame in pairs(frames) do
		local group = frame:GetGroup()

		if group ~= nil and group.IndicateInterrupts then
			frame:SetInterrupted(interruptName, interruptColor)
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

	C_Timer.After(
		1,
		GenerateClosure(self.OnFrameEvent, self, self.frame, Private.Enum.Events.DELAYED_FRAME_CLEANUP, delayInfo)
	)
end

function TargetedSpellsDriver:OnCooldownDone(info)
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
