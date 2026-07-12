---@type string, TargetedSpells
local addonName, Private = ...

---@class TargetedSpellsDriver
local TargetedSpellsDriver = {}

---@param group TargetedSpellsGroup
function TargetedSpellsDriver:PoolForGroup(group)
	if group.Template == Private.Enum.Template.Icon then
		return Private.Utils.Pools.Icon
	end

	return Private.Utils.Pools.Bar
end

---@param group TargetedSpellsGroup
function TargetedSpellsDriver:GroupCoreElement(group)
	if group.Template == Private.Enum.Template.Icon then
		return Private.Enum.Element.Icon
	end

	return Private.Enum.Element.ProgressBar
end

function TargetedSpellsDriver:Init()
	self.delay = 0.2
	self.frames = {}
	---@type table<integer, Frame>
	self.containers = {}
	self.role = Private.Enum.Role.Damager
	self.contentType = Private.Enum.ContentType.OpenWorld
	self.OnCooldownDoneClosure = GenerateClosure(self.OnCooldownDone, self)
	Private.EventRegistry:RegisterCallback(Private.Enum.Events.SETTING_CHANGED, self.OnSettingsChanged, self)
	Private.EventRegistry:RegisterCallback(Private.Enum.Events.PROFILE_IMPORTED, self.OnProfileImported, self)
	self.ttsAnnouncementCache = {}
	self.activeEncounterId = nil

	-- denormalise the id onto each group so frames can find their container
	for id, group in pairs(TargetedSpellsSaved.Groups) do
		group.Id = id
	end

	self:SetupFrame(true)
end

-- ── Group containers ─────────────────────────────────────────────────────────
-- Each group anchors its frames to a 1x1 container placed at the group's saved
-- Position. Created lazily; positions itself relative to the group's edit-mode
-- frame so the growth direction stays visually anchored.

---@param groupId integer
function TargetedSpellsDriver:GetContainer(groupId)
	if self.containers[groupId] == nil then
		local frame = CreateFrame("Frame", "TargetedSpellsGroupContainer" .. groupId, UIParent)
		frame:SetSize(1, 1)
		self.containers[groupId] = frame
	end

	return self.containers[groupId]
end

-- the edit-mode frame anchors via its own position.point, but the container always
-- anchors via CENTER, so the offset compensates for the difference in origins
---@param group TargetedSpellsGroup
function TargetedSpellsDriver:PositionFrame(group)
	local container = self:GetContainer(group.Id)

	local offsetX = 0
	local offsetY = 0

	local editModeFrame = Private.Utils.GetEditModeFrame(group.Id)

	if editModeFrame ~= nil then
		local width, height = editModeFrame:GetSize()

		local AnchorSign = {
			[Private.Enum.Anchor.Center] = { x = 0, y = 0 },
			[Private.Enum.Anchor.Top] = { x = 0, y = 1 },
			[Private.Enum.Anchor.Bottom] = { x = 0, y = -1 },
			[Private.Enum.Anchor.Left] = { x = -1, y = 0 },
			[Private.Enum.Anchor.Right] = { x = 1, y = 0 },
			[Private.Enum.Anchor.TopLeft] = { x = -1, y = 1 },
			[Private.Enum.Anchor.TopRight] = { x = 1, y = 1 },
			[Private.Enum.Anchor.BottomLeft] = { x = -1, y = -1 },
			[Private.Enum.Anchor.BottomRight] = { x = 1, y = -1 },
		}

		local GrowTarget = {
			[Private.Enum.Direction.Horizontal] = {
				[Private.Enum.Grow.Start] = { x = -1, y = 0 },
				[Private.Enum.Grow.End] = { x = 1, y = 0 },
			},
			[Private.Enum.Direction.Vertical] = {
				[Private.Enum.Grow.Start] = { x = 0, y = -1 },
				[Private.Enum.Grow.End] = { x = 0, y = 1 },
			},
		}

		local anchor = AnchorSign[group.Position.point]
		local target = GrowTarget[group.Direction][group.Grow]

		offsetX = (target.x - anchor.x) * (width / 2)
		offsetY = (target.y - anchor.y) * (height / 2)
	end

	container:ClearAllPoints()
	PixelUtil.SetPoint(
		container,
		"CENTER",
		UIParent,
		group.Position.point,
		group.Position.x + offsetX,
		group.Position.y + offsetY
	)
	container:Show()
end

-- ── Cross-group setting queries (event registration decisions) ───────────────

function TargetedSpellsDriver:AnyGroupEnabled()
	for _, group in pairs(TargetedSpellsSaved.Groups) do
		if group.Enabled then
			return true
		end
	end

	return false
end

function TargetedSpellsDriver:AnyGroupUsesInterruptibility()
	for _, group in pairs(TargetedSpellsSaved.Groups) do
		if group.Enabled and group.Template == Private.Enum.Template.Bar then
			local core = group.Elements[Private.Enum.Element.ProgressBar]

			if core ~= nil and core.barColorMode == Private.Enum.BarColorMode.Interruptibility then
				return true
			end
		end
	end

	return false
end

function TargetedSpellsDriver:AnyGroupShowsTargetMarker()
	for _, group in pairs(TargetedSpellsSaved.Groups) do
		if group.Enabled and group.Template == Private.Enum.Template.Bar then
			local marker = group.Elements[Private.Enum.Element.TargetMarker]

			if marker ~= nil and marker.active then
				return true
			end
		end
	end

	return false
end

function TargetedSpellsDriver:AnyGroupIndicatesInterrupts()
	for _, group in pairs(TargetedSpellsSaved.Groups) do
		if group.IndicateInterrupts then
			return true
		end
	end

	return false
end

function TargetedSpellsDriver:SetupFrame(isBoot)
	if isBoot then
		self.frame = CreateFrame("Frame", "TargetedSpellsDriverFrame", UIParent)
		self.frame:SetSize(1, 1)

		for _, group in pairs(TargetedSpellsSaved.Groups) do
			self:PositionFrame(group)
		end

		Private.EventRegistry:RegisterCallback(
			Private.Enum.Events.EDIT_MODE_SELF_POSITION_CHANGED,
			self.OnFrameEvent,
			self,
			self.frame,
			Private.Enum.Events.EDIT_MODE_SELF_POSITION_CHANGED
		)

		Private.EventRegistry:RegisterCallback(
			Private.Enum.Events.EDIT_MODE_PARTY_POSITION_CHANGED,
			self.OnFrameEvent,
			self,
			self.frame,
			Private.Enum.Events.EDIT_MODE_PARTY_POSITION_CHANGED
		)
	end

	if self:AnyGroupEnabled() and not self.frame:IsEventRegistered("UNIT_SPELLCAST_START") then
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

		if self:AnyGroupUsesInterruptibility() then
			self.frame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTIBLE")
			self.frame:RegisterUnitEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE")
		end

		if self:AnyGroupShowsTargetMarker() then
			self.frame:RegisterEvent("RAID_TARGET_UPDATE")
		end

		self.frame:SetScript("OnEvent", GenerateClosure(self.OnFrameEvent, self))
	end
end

-- ── Frame lifecycle ──────────────────────────────────────────────────────────

---@param info SpellCastInfo
---@return table<TargetClass, boolean>
function TargetedSpellsDriver:GetTargetClasses(info)
	local targetName = UnitSpellTargetName(info.unit)

	if targetName == nil then
		return {
			[Private.Enum.TargetClass.Nobody] = true
		}
	end

	-- A targeted cast is Player or PartyMember, but PlayerIsSpellTarget is a *secret*
	-- boolean that cannot be branched on here. Offer the cast to both classes; each
	-- acquired frame resolves the distinction secret-safely (mixin:ApplyCastAlpha).
	return {
		[Private.Enum.TargetClass.Player] = true,
		[Private.Enum.TargetClass.PartyMember] = true
	}
end

---@param group TargetedSpellsGroup
function TargetedSpellsDriver:GroupLoadConditionsProhibit(group)
	if not group.LoadConditionRole[self.role] then
		return true
	end

	if not group.LoadConditionContentType[self.contentType] then
		return true
	end

	return false
end

---@param group TargetedSpellsGroup
function TargetedSpellsDriver:CountActiveFramesForGroup(group)
	local count = 0

	for frame in self:PoolForGroup(group):EnumerateActive() do
		if frame:GetGroup() == group then
			count = count + 1
		end
	end

	return count
end

function TargetedSpellsDriver:ProcessInfo(info)
	if self.frames[info.unit] == nil then
		self.frames[info.unit] = {}
	else
		self:ReleaseFrameForUnit(info.unit, false)
	end

	info.targetClasses = self:GetTargetClasses(info)

	local count = 0

	for _, group in ipairs(Private.Groups.GetMatching(info, TargetedSpellsSaved.Groups)) do
		if
			not self:GroupLoadConditionsProhibit(group)
			and self:CountActiveFramesForGroup(group) < (group.MaxItems or 10)
		then
			local frame = self:PoolForGroup(group):Acquire()
			frame:SetGroup(group)
			frame:PostCreate(info, self.OnCooldownDoneClosure)
			table.insert(self.frames[info.unit], frame)
			count = count + 1
		end
	end

	if count == 0 then
		self:ReleaseFrameForUnit(info.unit, true)
	end

	self:RepositionFrames()
end

---@param frame TargetedSpellsIconMixin|TargetedSpellsBarMixin
function TargetedSpellsDriver:ReleaseFrame(frame)
	local group = frame:GetGroup()

	if group ~= nil then
		self:PoolForGroup(group):Release(frame)
	else
		-- fall back on the XML kind if the group tag was lost
		if frame:GetKind() == Private.Enum.FrameKind.Self then
			Private.Utils.Pools.Icon:Release(frame)
		else
			Private.Utils.Pools.Bar:Release(frame)
		end
	end
end

function TargetedSpellsDriver:RepositionFrames()
	---@type table<integer, { group: TargetedSpellsGroup, frames: table }>
	local byGroup = {}

	for _, frames in pairs(self.frames) do
		for _, frame in pairs(frames) do
			if frame ~= nil then
				local group = frame:GetGroup()

				if group ~= nil then
					if byGroup[group.Id] == nil then
						byGroup[group.Id] = { group = group, frames = {} }
					end

					table.insert(byGroup[group.Id].frames, frame)
				end
			end
		end
	end

	for groupId, entry in pairs(byGroup) do
		local group = entry.group
		local core = group.Elements[self:GroupCoreElement(group)]

		Private.Utils.SortFrames(entry.frames, group.SortOrder)
		Private.Utils.AdjustLayout(
			entry.frames,
			Private.Utils.CollectLayoutingArguments(group.Direction, group.Grow, core.width, core.height, group.Gap),
			self:GetContainer(groupId),
			"CENTER",
			0,
			0,
			false
		)
	end
end

function TargetedSpellsDriver:ReleaseFrameForUnit(unit, removeUnit, id)
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

		C_Timer.After(
			self.delay,
			GenerateClosure(self.OnFrameEvent, self, self.frame, Private.Enum.Events.DELAYED_UNIT_SPELLCAST_START, {
				unit = unit,
				spellId = spellId,
				startTime = GetTime(),
				id = id,
				isChannel = isChannel,
			})
		)
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
				Private.Utils.Pools.Bar:ReleaseAll()
				Private.Utils.Pools.Icon:ReleaseAll()
				table.wipe(self.frames)
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
		self:ClearAnnouncementCacheForUnit(unit)

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

		if self:ReleaseFrameForUnit(unit, true, id) then
			self:RepositionFrames()
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
		self:MaybeAnnounceSpell(info)
	elseif event == Private.Enum.Events.DELAYED_FRAME_CLEANUP then
		---@type DelayInfo
		local delayInfo = ...

		if self:ReleaseFrameForUnit(delayInfo.unit, true, delayInfo.id) then
			self:RepositionFrames()
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

		if
			specId == 105 -- restoration druid
			or specId == 1468 -- preservation evoker
			or specId == 270 -- mistweaver monk
			or specId == 65 -- holy paladin
			or specId == 256 -- discipline priest
			or specId == 257 -- holy priest
			or specId == 264 -- restoration shaman
		then
			self.role = Private.Enum.Role.Healer
		elseif
			specId == 250 -- blood death knight
			or specId == 581 -- vengeance demon hunter
			or specId == 104 -- guardian druid
			or specId == 268 -- brewmaster monk
			or specId == 66 -- protection paladin
			or specId == 73 -- protection warrior
		then
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
	elseif event == Private.Enum.Events.EDIT_MODE_SELF_POSITION_CHANGED then
		local group = TargetedSpellsSaved.Groups[1]
		if group ~= nil then
			self:PositionFrame(group)
		end
	elseif event == Private.Enum.Events.EDIT_MODE_PARTY_POSITION_CHANGED then
		local group = TargetedSpellsSaved.Groups[2]
		if group ~= nil then
			self:PositionFrame(group)
		end
	end
end

function TargetedSpellsDriver:CleanupDanglingFrames()
	local cleanedSomethingUp = false

	for unit in pairs(self.frames) do
		local thisUnitWasCleanedUp = self:ReleaseFrameForUnit(unit, true)
		self:ClearAnnouncementCacheForUnit(unit)

		cleanedSomethingUp = cleanedSomethingUp or thisUnitWasCleanedUp
	end

	if cleanedSomethingUp then
		self:RepositionFrames()
	end
end

-- A v4 profile import updates the group tables in place (Utils.ImportV4Profile),
-- so refs stay valid; here we drop live frames (they re-acquire with the new
-- settings), reposition every container, and re-evaluate event registration.
function TargetedSpellsDriver:OnProfileImported()
	-- Release only the Driver's own frames — NOT Pools:ReleaseAll, which would also
	-- release the edit-mode demo frames sharing these pools (double-release error).
	for _, frames in pairs(self.frames) do
		for _, frame in ipairs(frames) do
			self:ReleaseFrame(frame)
		end
	end

	table.wipe(self.frames)

	for _, group in pairs(TargetedSpellsSaved.Groups) do
		self:PositionFrame(group)
	end

	self:SetupFrame(false)
end

function TargetedSpellsDriver:OnSettingsChanged(key, value)
	local Keys = Private.Settings.Keys

	if key == Keys.Self.Enabled or key == Keys.Party.Enabled then
		if not self:AnyGroupEnabled() then
			self.frame:UnregisterAllEvents()
			self.frame:SetScript("OnEvent", nil)
		else
			self:SetupFrame(false)
		end
	elseif
		key == Keys.Self.Grow
		or key == Keys.Self.Direction
		or key == Keys.Self.Width
		or key == Keys.Self.Height
		or key == Keys.Self.Gap
	then
		local group = TargetedSpellsSaved.Groups[1]
		if group ~= nil then
			self:PositionFrame(group)
		end
	elseif
		key == Keys.Party.Grow
		or key == Keys.Party.Direction
		or key == Keys.Party.Width
		or key == Keys.Party.Height
		or key == Keys.Party.Gap
	then
		local group = TargetedSpellsSaved.Groups[2]
		if group ~= nil then
			self:PositionFrame(group)
		end
	elseif key == Keys.Party.UseInterruptabilityColors then
		if self:AnyGroupUsesInterruptibility() then
			self.frame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTIBLE")
			self.frame:RegisterUnitEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE")
		else
			self.frame:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE")
			self.frame:UnregisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE")
		end
	elseif key == Keys.Party.FeatureFlags then
		if value == Private.Enum.FeatureFlag.ShowTargetMarker then
			if self:AnyGroupShowsTargetMarker() then
				self.frame:RegisterEvent("RAID_TARGET_UPDATE")
			else
				self.frame:UnregisterEvent("RAID_TARGET_UPDATE")
			end
		end
	end
end

function TargetedSpellsDriver:MaybeMarkAsInterruptedAndDelay(unit, id, interruptedBy)
	if not self:AnyGroupIndicatesInterrupts() then
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
	if self:ReleaseFrameForUnit(info.unit, true, info.id) then
		self:RepositionFrames()
	end
end

function TargetedSpellsDriver:ClearAnnouncementCacheForUnit(unit)
	self.ttsAnnouncementCache[unit] = nil
end

function TargetedSpellsDriver:GetDefaultVoiceId()
	return C_TTSSettings.GetVoiceOptionID(Enum.TtsVoiceType.Standard)
end

function TargetedSpellsDriver:UnitMatchesTTSCriteria(unit)
	local settings = UnitSpellTargetName(unit) == nil and TargetedSpellsSaved.TextToSpeech.AnnounceUntargetedSpells or
		TargetedSpellsSaved.TextToSpeech.AnnounceTargetedSpells
	local classification = UnitClassification(unit)

	if UnitIsMinion(unit) or classification == "normal" or classification == "trivial" or classification == "minus" then
		return settings[Private.Enum.NpcType.Minion]
	end

	if UnitIsLieutenant(unit) or UnitLevel(unit) - 1 == UnitLevel("player") then
		return settings[Private.Enum.NpcType.Lieutenant]
	end

	if UnitIsBossMob(unit) or UnitLevel(unit) - 2 == UnitLevel("player") then
		return settings[Private.Enum.NpcType.Boss]
	end

	local class = UnitClassBase(unit)

	if class == "PALADIN" or class == "MAGE" or class == "PRIEST" then
		return settings[Private.Enum.NpcType.Caster]
	end

	return settings[Private.Enum.NpcType.Melee]
end

function TargetedSpellsDriver:EncounterPreventsTTSExecution(unit)
	if self.activeEncounterId == 3333 then -- Lothraxion, Nexus-Point Xenas
		if UnitLevel(unit) == -1 then
			local id = string.gsub(unit, "nameplate", "")
			-- ignores casts by a boss unit if the nameplateN id is greater than 1
			return tonumber(id) > 1
		end

		return false
	elseif self.activeEncounterId == 2001 then -- Ick and Krick, Pit of Saron
		return UnitLevel(unit) == 91 and UnitIsLieutenant(unit)
	elseif self.activeEncounterId == 2067 then -- Viceroy Nezhar, Seat of the Triumvirate
		return UnitLevel(unit) == 90
	end

	return false
end

function TargetedSpellsDriver:AnyGroupLoadConditionsAllow()
	for _, group in pairs(TargetedSpellsSaved.Groups) do
		if group.Enabled and not self:GroupLoadConditionsProhibit(group) then
			return true
		end
	end

	return false
end

function TargetedSpellsDriver:MaybeAnnounceSpell(info)
	if
		info.isRetarget
		or not self:AnyGroupLoadConditionsAllow()
		-- don't execute in open world if outside of combat, otherwise there's stray TTS from people casting stuff in town
		or (self.contentType == Private.Enum.ContentType.OpenWorld and (not InCombatLockdown() or not UnitAffectingCombat(
			info.unit
		)))
		or self:EncounterPreventsTTSExecution(info.unit)
	then
		return
	end

	local now = GetTime()

	if
		self.ttsAnnouncementCache[info.unit] ~= nil and now - self.ttsAnnouncementCache[info.unit] < 3
		or not self:UnitMatchesTTSCriteria(info.unit)
	then
		return
	end

	local spellName = C_Spell.GetSpellName(info.spellId)

	if spellName == nil then
		return
	end

	self.ttsAnnouncementCache[info.unit] = now

	local configuredVoice = TargetedSpellsSaved.TextToSpeech.TextToSpeechVoice
	local voiceId = configuredVoice ~= nil and configuredVoice > -1 and configuredVoice
		or C_TTSSettings.GetVoiceOptionID(Enum.TtsVoiceType.Standard)

	C_VoiceChat.SpeakText(voiceId, spellName, 2, C_TTSSettings.GetSpeechVolume(), true)
end

table.insert(Private.LoginFnQueue, GenerateClosure(TargetedSpellsDriver.Init, TargetedSpellsDriver))
