---@type string, TargetedSpells
local addonName, Private = ...

---@class TargetedSpellsDriver
local TargetedSpellsDriver = {}

function TargetedSpellsDriver:Init()
	self.delay = 0.2
	self.frames = {}
	self.role = Private.Enum.Role.Damager
	self.contentType = Private.Enum.ContentType.OpenWorld
	Private.EventRegistry:RegisterCallback(Private.Enum.Events.SETTING_CHANGED, self.OnSettingsChanged, self)

	self:SetupFrame(true)
end

function TargetedSpellsDriver:PositionSelfFrame()
	local offsetX = 0
	local offsetY = 0

	-- the edit mode frame anchors via its own position.point, but self.frame always anchors via CENTER,
	-- so the offset must compensate for the difference between those two anchor origins
	local editModeFrame = Private.Utils.GetEditModeFrame(Private.Enum.FrameKind.Self)

	if editModeFrame ~= nil then
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

		local width, height = editModeFrame:GetSize()

		local anchor = AnchorSign[TargetedSpellsSaved.Settings.Self.Position.point]
		local target = GrowTarget[TargetedSpellsSaved.Settings.Self.Direction][TargetedSpellsSaved.Settings.Self.Grow]

		offsetX = (target.x - anchor.x) * (width / 2)
		offsetY = (target.y - anchor.y) * (height / 2)
	end

	self.frame:ClearAllPoints()
	PixelUtil.SetPoint(
		self.frame,
		"CENTER",
		UIParent,
		TargetedSpellsSaved.Settings.Self.Position.point,
		TargetedSpellsSaved.Settings.Self.Position.x + offsetX,
		TargetedSpellsSaved.Settings.Self.Position.y + offsetY
	)
	self.frame:Show()
end

function TargetedSpellsDriver:SetupFrame(isBoot)
	if isBoot then
		self.frame = CreateFrame("Frame", "TargetedSpellsDriverFrame", UIParent)
		self.frame:SetSize(1, 1)
		self:PositionSelfFrame()

		Private.EventRegistry:RegisterCallback(
			Private.Enum.Events.EDIT_MODE_POSITION_CHANGED,
			self.OnFrameEvent,
			self,
			self.frame,
			Private.Enum.Events.EDIT_MODE_POSITION_CHANGED
			-- the remaining args are being passed when the event gets triggered
		)
	end

	if
		(TargetedSpellsSaved.Settings.Self.Enabled or TargetedSpellsSaved.Settings.Party.Enabled)
		and not self.frame:IsEventRegistered("UNIT_SPELLCAST_START")
	then
		self.frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
		self.frame:RegisterEvent("LOADING_SCREEN_DISABLED")
		self.frame:RegisterEvent("UPDATE_INSTANCE_INFO")
		self.frame:RegisterUnitEvent("UNIT_TARGET")
		self.frame:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")
		self.frame:RegisterUnitEvent("UNIT_SPELLCAST_START")
		self.frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED")
		self.frame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED")
		self.frame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED_QUIET")
		self.frame:RegisterUnitEvent("UNIT_SPELLCAST_STOP")
		self.frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START")
		self.frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP")
		self.frame:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_START")
		self.frame:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_STOP")
		self.frame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
		self.frame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
		self.frame:RegisterEvent("CVAR_UPDATE")

		self.frame:SetScript("OnEvent", GenerateClosure(self.OnFrameEvent, self))
	end
end

do
	---@type table<string, TargetedSpellsIconMixin[]>
	local frames = {}

	function TargetedSpellsDriver:AcquireFrames(castingUnit)
		table.wipe(frames)

		if
			TargetedSpellsSaved.Settings.Self.Enabled
			and not self:LoadConditionsProhibitExecution(Private.Enum.FrameKind.Self)
		then
			local selfTargetingFrame = Private.Utils.Pools.Self:Acquire()
			selfTargetingFrame:PostCreate("player", castingUnit)
			table.insert(frames, selfTargetingFrame)
		end

		if
			TargetedSpellsSaved.Settings.Party.Enabled
			and IsInGroup()
			and not self:LoadConditionsProhibitExecution(Private.Enum.FrameKind.Party)
		then
			local partyMemberCount = GetNumGroupMembers()

			for i = 1, partyMemberCount do
				local unit = i == partyMemberCount and "player" or "party" .. i

				if
					(
						unit == "player"
						and TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.IncludeSelfInParty]
					) or unit ~= "player"
				then
					local frame = Private.Utils.Pools.Bar:Acquire()
					frame:PostCreate(unit)
					table.insert(frames, frame)
				end
			end
		end

		return frames
	end
end

function TargetedSpellsDriver:RepositionFrames()
	---@type table<string, TargetedSpellsIconMixin[]>
	local activeFrames = {}

	for sourceUnit, frames in pairs(self.frames) do
		for i, frame in pairs(frames) do
			if frame then
				local kind = frame:GetKind()

				if kind == Private.Enum.FrameKind.Self then
					if activeFrames[kind] == nil then
						activeFrames[kind] = {}
					end

					table.insert(activeFrames[kind], frame)
				elseif kind == Private.Enum.FrameKind.Party then
					-- todo: this needs to be adjusted for bars
					local targetUnit = frame:GetUnit()

					if activeFrames[targetUnit] == nil then
						activeFrames[targetUnit] = {}
					end

					table.insert(activeFrames[targetUnit], frame)
				end
			end
		end
	end

	local selfTableRef = TargetedSpellsSaved.Settings.Self
	-- local partyTableRef = TargetedSpellsSaved.Settings.Party

	for targetUnit, frames in pairs(activeFrames) do
		-- may not use "player" here as the unit token in party for the player is identical
		if targetUnit == Private.Enum.FrameKind.Self then
			Private.Utils.SortFrames(frames, selfTableRef.SortOrder)

			local layouting = Private.Utils.CollectLayoutingArguments(
				selfTableRef.Direction,
				selfTableRef.Grow,
				selfTableRef.Width,
				selfTableRef.Height,
				selfTableRef.Gap
			)

			Private.Utils.AdjustLayout(frames, layouting, self.frame, "CENTER", 0, 0, false)
		else
			-- todo: this entire branch needs to be restructured as there's no longer a party frame to anchor to
			-- local parentFrame = FindParentFrameForPartyMember(targetUnit)

			-- if parentFrame ~= nil then
			-- 	Private.Utils.SortFrames(frames, partyTableRef.SortOrder)

			-- 	local layouting = Private.Utils.CollectLayoutingArguments(
			-- 		partyTableRef.Direction,
			-- 		partyTableRef.Grow,
			-- 		partyTableRef.Width,
			-- 		partyTableRef.Height,
			-- 		partyTableRef.Gap
			-- 	)

			-- 	Private.Utils.AdjustLayout(
			-- 		frames,
			-- 		layouting,
			-- 		parentFrame,
			-- 		partyTableRef.TargetAnchor,
			-- 		partyTableRef.OffsetX,
			-- 		partyTableRef.OffsetY,
			-- 		false
			-- 	)
			-- end
		end
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
				if frame:GetKind() == Private.Enum.FrameKind.Self then
					Private.Utils.Pools.Self:Release(frame)
				else
					Private.Utils.Pools.Bar:Release(frame)
				end
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

function TargetedSpellsDriver:LoadConditionsProhibitExecution(kind)
	local tableRef = kind == Private.Enum.FrameKind.Self and TargetedSpellsSaved.Settings.Self
		or TargetedSpellsSaved.Settings.Party

	if not tableRef.LoadConditionRole[self.role] then
		return true
	end

	if not tableRef.LoadConditionContentType[self.contentType] then
		return true
	end

	return false
end

function TargetedSpellsDriver:UnitIsIrrelevant(unit, skipTargetCheck)
	if string.sub(unit, 1, 9) ~= "nameplate" then
		return true
	end

	if UnitInParty(unit) then
		return true
	end

	if not UnitExists(unit) then
		return true
	end

	if not UnitCanAttack("player", unit) then
		return true
	end

	if skipTargetCheck then
		return false
	end

	local target = string.format("%starget", unit)

	if not UnitExists(target) then
		return true
	end

	if UnitCanAttack("player", target) then
		return true
	end

	if IsInGroup() and not UnitInParty(target) then
		return true
	end

	return false
end

---@param _ Frame -- identical to self.frame
---@param event "DELAYED_FRAME_CLEANUP" | "UNIT_SPELLCAST_INTERRUPTED" | "UNIT_SPELLCAST_FAILED_QUIET" | "ZONE_CHANGED_NEW_AREA" | "LOADING_SCREEN_DISABLED" | "PLAYER_SPECIALIZATION_CHANGED" | "UNIT_SPELLCAST_EMPOWER_STOP" | "UNIT_SPELLCAST_EMPOWER_START" | "UNIT_SPELLCAST_SUCCEEDED" |"EDIT_MODE_POSITION_CHANGED" | "DELAYED_UNIT_SPELLCAST_START" | "DELAYED_UNIT_SPELLCAST_CHANNEL_START" | "UNIT_SPELLCAST_START" | "UNIT_SPELLCAST_STOP" | "UNIT_SPELLCAST_CHANNEL_START" | "UNIT_SPELLCAST_CHANNEL_STOP" | "NAME_PLATE_UNIT_REMOVED" | "NAME_PLATE_UNIT_ADDED"
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

		if event == "UNIT_SPELLCAST_EMPOWER_START" then
			spellId, id = select(3, ...)
		end

		C_Timer.After(
			self.delay,
			GenerateClosure(
				self.OnFrameEvent,
				self,
				self.frame,
				event == "UNIT_SPELLCAST_START" and Private.Enum.Events.DELAYED_UNIT_SPELLCAST_START
					or Private.Enum.Events.DELAYED_UNIT_SPELLCAST_CHANNEL_START,
				{
					unit = unit,
					spellId = spellId,
					startTime = GetTime(),
					id = id,
				}
			)
		)
	elseif event == "UNIT_TARGET" then
		---@type string
		local unit = ...

		if self:UnitIsIrrelevant(unit) then
			return
		end

		local delayEvent = Private.Enum.Events.DELAYED_UNIT_SPELLCAST_START
		local startTime = GetTime()

		local _, _, _, _, _, _, _, _, spellId, castId = UnitCastingInfo(unit)

		if spellId == nil then
			_, _, _, _, _, _, _, spellId, _, _, castId = UnitChannelInfo(unit)

			delayEvent = Private.Enum.Events.DELAYED_UNIT_SPELLCAST_CHANNEL_START
		end

		self:OnFrameEvent(self.frame, delayEvent, {
			unit = unit,
			spellId = spellId,
			startTime = startTime,
			id = castId,
		})
	elseif event == "NAME_PLATE_UNIT_ADDED" then
		---@type string
		local unit = ...

		if self:UnitIsIrrelevant(unit) then
			return
		end

		local isChannel = false
		local _, _, _, _, _, _, _, _, spellId, id = UnitCastingInfo(unit)

		if spellId == nil then
			_, _, _, _, _, _, _, spellId, _, _, id = UnitChannelInfo(unit)
			isChannel = true
		end

		if spellId == nil then
			return
		end

		local duration = (isChannel and UnitChannelDuration(unit) or nil) or UnitCastingDuration(unit)

		if duration == nil then
			return
		end

		local frames = self:AcquireFrames(unit)

		if #frames == 0 then
			return
		end

		if self.frames[unit] == nil then
			self.frames[unit] = {}
		else
			self:ReleaseFrameForUnit(unit, false)
		end

		local startTime = GetTime() -- todo: this is wrong, but we can't do better yet
		local OnCooldownDone = GenerateClosure(self.OnCooldownDone, self, {
			unit = unit,
			spellId = spellId,
			startTime = startTime,
			id = id,
		})

		for i, frame in ipairs(frames) do
			table.insert(self.frames[unit], frame)
			frame:SetSpellId(spellId)
			frame:SetStartTime(startTime)
			frame:SetId(id)
			frame:SetDuration(duration)
			frame:SetOnCooldownDone(OnCooldownDone)
		end

		self:RepositionFrames()
	elseif event == "CVAR_UPDATE" then
		local name, value = ...

		if name == "nameplateShowEnemies" then
			if value ~= 0 then
				return
			end

			local cleanedSomethingUp = false

			for unit in pairs(self.frames) do
				if self:ReleaseFrameForUnit(unit, true) then
					cleanedSomethingUp = true
				end
			end

			if cleanedSomethingUp then
				self:RepositionFrames()
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
						-- Settings.OpenToCategory(Settings.NAMEPLATE_OPTIONS_CATEGORY_ID, UNIT_NAMEPLATES_SHOW_OFFSCREEN)
					end,
				})
			end
		end
	elseif
		event == "UNIT_SPELLCAST_STOP"
		or event == "UNIT_SPELLCAST_CHANNEL_STOP"
		or event == "UNIT_SPELLCAST_SUCCEEDED"
		or event == "UNIT_SPELLCAST_EMPOWER_STOP"
		or event == "NAME_PLATE_UNIT_REMOVED"
		or event == "UNIT_SPELLCAST_INTERRUPTED"
		or event == "UNIT_SPELLCAST_FAILED_QUIET"
	then
		---@type string, string
		local unit, castGuid = ...

		if self:UnitIsIrrelevant(unit, true) then
			return
		end

		local frames = self.frames[unit]

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
	elseif
		event == Private.Enum.Events.DELAYED_UNIT_SPELLCAST_START
		or event == Private.Enum.Events.DELAYED_UNIT_SPELLCAST_CHANNEL_START
	then
		local info = ...

		-- cast vanished during the delay
		if event == Private.Enum.Events.DELAYED_UNIT_SPELLCAST_START and UnitCastingInfo(info.unit) == nil then
			return
		elseif
			event == Private.Enum.Events.DELAYED_UNIT_SPELLCAST_CHANNEL_START and UnitChannelInfo(info.unit) == nil
		then
			return
		end

		local frames = self:AcquireFrames(info.unit)

		if #frames == 0 then
			if self:ReleaseFrameForUnit(info.unit, true) then
				self:RepositionFrames()
			end

			return
		end

		if self.frames[info.unit] == nil then
			self.frames[info.unit] = {}
		else
			self:ReleaseFrameForUnit(info.unit, false, info.id)
		end

		local duration = UnitCastingDuration(info.unit) or UnitChannelDuration(info.unit)

		-- without `nameplateShowOffscreen` active, castTime may stay nil

		if duration == nil then
			return
		end

		local OnCooldownDone = GenerateClosure(self.OnCooldownDone, self, info)

		for i, frame in ipairs(frames) do
			table.insert(self.frames[info.unit], frame)
			frame:SetSpellId(info.spellId)
			frame:SetStartTime(info.startTime)
			frame:SetId(info.id)
			frame:SetDuration(duration)
			frame:SetOnCooldownDone(OnCooldownDone)
		end

		self:RepositionFrames()
	elseif event == Private.Enum.Events.DELAYED_FRAME_CLEANUP then
		---@type DelayInfo
		local delayInfo = ...

		local frames = self.frames[delayInfo.unit]

		if frames == nil or #frames == 0 then
			return
		end

		local cleanedSomethingUp = false

		for i, frame in pairs(frames) do
			local kind = frame:GetKind()

			if delayInfo.kinds[kind] and frame:GetId() == delayInfo.id then
				if kind == Private.Enum.FrameKind.Self then
					Private.Utils.Pools.Self:Release(frame)
				else
					Private.Utils.Pools.Bar:Release(frame)
				end
				frames[i] = nil
				cleanedSomethingUp = true
			end
		end

		if cleanedSomethingUp then
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
	elseif event == Private.Enum.Events.EDIT_MODE_POSITION_CHANGED then
		self:PositionSelfFrame()
	end
end

function TargetedSpellsDriver:CleanupDanglingFrames()
	local cleanedSomethingUp = false

	for unit in pairs(self.frames) do
		local thisUnitWasCleanedUp = self:ReleaseFrameForUnit(unit, true)

		cleanedSomethingUp = cleanedSomethingUp or thisUnitWasCleanedUp
	end

	if cleanedSomethingUp then
		self:RepositionFrames()
	end
end

function TargetedSpellsDriver:OnSettingsChanged(key, value)
	if key == Private.Settings.Keys.Self.Enabled or key == Private.Settings.Keys.Party.Enabled then
		local allDisabled = TargetedSpellsSaved.Settings.Self.Enabled == false
			and TargetedSpellsSaved.Settings.Party.Enabled == false

		if allDisabled then
			self.frame:UnregisterAllEvents()
			self.frame:SetScript("OnEvent", nil)
		else
			self:SetupFrame(false)
		end
	elseif
		key == Private.Settings.Keys.Self.Grow
		or key == Private.Settings.Keys.Self.Direction
		or key == Private.Settings.Keys.Self.Width
		or key == Private.Settings.Keys.Self.Height
		or key == Private.Settings.Keys.Self.Gap
	then
		self:PositionSelfFrame()
	end
end

function TargetedSpellsDriver:MaybeMarkAsInterruptedAndDelay(unit, id, interruptedBy)
	if
		not TargetedSpellsSaved.Settings.Self.FeatureFlags[Private.Enum.FeatureFlag.IndicateInterrupts]
		and not TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.IndicateInterrupts]
	then
		return
	end

	-- either via events that don't communicate interruptedBy, or via interrupt events briefly before deaths, e.g. on totems that cast something like Cinderbrew Meadery barrels
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

	local kindsToDelay = {
		[Private.Enum.FrameKind.Self] = false,
		[Private.Enum.FrameKind.Party] = false,
	}

	local frames = self.frames[unit]

	for i, frame in pairs(frames) do
		local indicateInterrupts = false
		local kind = frame:GetKind()

		if kind == Private.Enum.FrameKind.Self then
			indicateInterrupts =
				TargetedSpellsSaved.Settings.Self.FeatureFlags[Private.Enum.FeatureFlag.IndicateInterrupts]
		else
			indicateInterrupts =
				TargetedSpellsSaved.Settings.Party.FeatureFlags[Private.Enum.FeatureFlag.IndicateInterrupts]
		end

		if indicateInterrupts then
			frame:SetInterrupted(interruptName, interruptColor)

			kindsToDelay[kind] = true
		end
	end

	if not kindsToDelay[Private.Enum.FrameKind.Self] and not kindsToDelay[Private.Enum.FrameKind.Party] then
		return
	end

	---@type DelayInfo
	local delayInfo = {
		unit = unit,
		kinds = kindsToDelay,
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

table.insert(Private.LoginFnQueue, GenerateClosure(TargetedSpellsDriver.Init, TargetedSpellsDriver))
