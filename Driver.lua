---@type string, TargetedSpells
local addonName, Private = ...

local last = GetTime()

local function pprint(...)
	local now = GetTime()
	local diff = now - last
	last = now
	print(diff, ...)
end

---@class TargetedSpellsDriver
local TargetedSpellsDriver = {}

function TargetedSpellsDriver:Init()
	self.framePool = CreateFramePool("Frame", UIParent, "TargetedSpellsFrameTemplate")
	self.delay = 0.2
	self.frames = {}
	self.role = Private.Enum.Role.Damager
	self.contentType = Private.Enum.ContentType.OpenWorld

	Private.EventRegistry:RegisterCallback(Private.Enum.Events.SETTING_CHANGED, self.OnSettingsChanged, self)

	self:SetupFrame(true)
end

function TargetedSpellsDriver:SetupFrame(isBoot)
	if isBoot then
		self.frame = CreateFrame("Frame", "TargetedSpellsDriverFrame", UIParent)

		-- awkward due to the need to pass self.frame to the callback
		Private.EventRegistry:RegisterCallback(
			Private.Enum.Events.EDIT_MODE_POSITION_CHANGED,
			self.OnFrameEvent,
			self,
			self,
			Private.Enum.Events.EDIT_MODE_POSITION_CHANGED
		)

		self.frame:SetSize(1, 1)
		self.frame:ClearAllPoints()
		self.frame:SetPoint(
			TargetedSpellsSaved.Settings.Self.Position.point,
			TargetedSpellsSaved.Settings.Self.Position.x,
			TargetedSpellsSaved.Settings.Self.Position.y
		)
		self.frame:Show()
	end

	if
		(Private.Settings.Keys.Self.Enabled or Private.Settings.Keys.Party.Enabled)
		and not self.frame:IsEventRegistered("UNIT_SPELLCAST_START")
	then
		self.frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
		self.frame:RegisterEvent("LOADING_SCREEN_DISABLED")
		self.frame:RegisterEvent("PLAYER_LOGIN")
		self.frame:RegisterEvent("UPDATE_INSTANCE_INFO")
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
		self.frame:RegisterUnitEvent("NAME_PLATE_UNIT_REMOVED")
		self.frame:RegisterUnitEvent("NAME_PLATE_UNIT_ADDED")
		if Private.IsMidnight then
			self.frame:RegisterUnitEvent("CVAR_UPDATE")
			-- self.frame:RegisterUnitEvent("UNIT_TARGET")
		end
		self.frame:SetScript("OnEvent", GenerateClosure(self.OnFrameEvent, self))

		print(format("TargetedSpellsDriver:OnSettingsChanged: %sattached listeners", isBoot and "" or "re"))
	end
end

function TargetedSpellsDriver:AcquireFrames(castingUnit)
	local frames = {}

	if
		TargetedSpellsSaved.Settings.Self.Enabled
		and not self:LoadConditionsProhibitExecution(Private.Enum.FrameKind.Self)
		and (Private.IsMidnight and true or UnitIsUnit(string.format("%starget", castingUnit), "player"))
	then
		local selfTargetingFrame = self.framePool:Acquire()
		selfTargetingFrame:SetParent(self.frame)
		selfTargetingFrame:PostCreate("player", Private.Enum.FrameKind.Self, castingUnit)
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
					(Private.IsMidnight and true or UnitIsUnit(string.format("%starget", castingUnit), unit))
					and unit == "player"
					and TargetedSpellsSaved.Settings.Party.IncludeSelfInParty
				) or unit ~= "player"
			then
				local frame = self.framePool:Acquire()
				frame:PostCreate(unit, Private.Enum.FrameKind.Party, castingUnit)
				table.insert(frames, frame)
			end
		end
	end

	return frames
end
-- function TargetedSpellsDriver:AcquireFrames(castingUnit)
-- 	local frames = {}

-- 	if
-- 		TargetedSpellsSaved.Settings.Self.Enabled
-- 		and not self:LoadConditionsProhibitExecution(Private.Enum.FrameKind.Self)
-- 		and UnitIsUnit(string.format("%starget", castingUnit), "player")
-- 	then
-- 		local selfTargetingFrame = self.framePool:Acquire()
-- 		selfTargetingFrame:SetParent(self.frame)
-- 		selfTargetingFrame:PostCreate("player", Private.Enum.FrameKind.Self, castingUnit)
-- 		table.insert(frames, selfTargetingFrame)
-- 	end

-- 	if
-- 		TargetedSpellsSaved.Settings.Party.Enabled
-- 		and IsInGroup()
-- 		and not self:LoadConditionsProhibitExecution(Private.Enum.FrameKind.Party)
-- 	then
-- 		local partyMemberCount = GetNumGroupMembers()

-- 		for i = 1, partyMemberCount do
-- 			local unit = i == partyMemberCount and "player" or "party" .. i

-- 			if
-- 				UnitIsUnit(string.format("%starget", castingUnit), unit)
-- 				and (
-- 					(unit == "player" and TargetedSpellsSaved.Settings.Party.IncludeSelfInParty)
-- 					or unit ~= "player"
-- 				)
-- 			then
-- 				local frame = self.framePool:Acquire()
-- 				frame:PostCreate(unit, Private.Enum.FrameKind.Party, castingUnit)
-- 				table.insert(frames, frame)
-- 			end
-- 		end
-- 	end

-- 	return frames
-- end

-- this is where 3rd party unit frames would need addition
---@param unit string
---@return Frame?
local function FindParentFrameForPartyMember(unit)
	if unit == "player" then
		if not EditModeManagerFrame:UseRaidStylePartyFrames() then
			-- non-raid style party frames don't include the player
			return nil
		end

		for _, frame in pairs(CompactPartyFrame.memberUnitFrames) do
			if frame.unit == "player" then
				return frame
			end
		end

		return nil
	end

	if EditModeManagerFrame:UseRaidStylePartyFrames() then
		for _, frame in pairs(CompactPartyFrame.memberUnitFrames) do
			if frame.unit == unit then
				return frame
			end
		end

		return nil
	end

	for memberFrame in PartyFrame.PartyMemberFramePool:EnumerateActive() do
		if memberFrame.unitToken == unit then
			return memberFrame
		end
	end

	return nil
end

function TargetedSpellsDriver:RepositionFrames()
	---@type table<string, TargetedSpellsMixin[]>
	local activeFrames = {}
	local activeFrameCount = 0

	for sourceUnit, frames in pairs(self.frames) do
		for i, frame in pairs(frames) do
			if frame:ShouldBeShown() then
				if frame:GetKind() == Private.Enum.FrameKind.Self then
					if activeFrames[Private.Enum.FrameKind.Self] == nil then
						activeFrames[Private.Enum.FrameKind.Self] = {}
					end

					table.insert(activeFrames[Private.Enum.FrameKind.Self], frame)
				else
					local targetUnit = frame:GetUnit()

					if activeFrames[targetUnit] == nil then
						activeFrames[targetUnit] = {}
					end

					table.insert(activeFrames[targetUnit], frame)
				end

				activeFrameCount = activeFrameCount + 1
			end
		end
	end

	for targetUnit, frames in pairs(activeFrames) do
		-- may not use "player" here as the unit token in party for the player is identical
		if targetUnit == Private.Enum.FrameKind.Self then
			local width, height, gap, sortOrder, direction, grow =
				TargetedSpellsSaved.Settings.Self.Width,
				TargetedSpellsSaved.Settings.Self.Height,
				TargetedSpellsSaved.Settings.Self.Gap,
				TargetedSpellsSaved.Settings.Self.SortOrder,
				TargetedSpellsSaved.Settings.Self.Direction,
				TargetedSpellsSaved.Settings.Self.Grow
			local isHorizontal = direction == Private.Enum.Direction.Horizontal
			local point = isHorizontal and "LEFT" or "BOTTOM"
			local total = (#frames * (isHorizontal and width or height)) + (#frames - 1) * gap

			Private.Utils.SortFrames(frames, sortOrder)

			for i, frame in ipairs(frames) do
				local x = 0
				local y = -(height / 2)

				if isHorizontal then
					x = Private.Utils.CalculateCoordinate(i, width, gap, width, total, 0, grow)
				else
					y = Private.Utils.CalculateCoordinate(i, width, gap, height, total, 0, grow)
				end

				frame:Reposition(point, self.frame, "CENTER", x, y)
			end
		else
			local parentFrame = FindParentFrameForPartyMember(targetUnit)

			if parentFrame ~= nil then
				local width, height, gap, sortOrder, sourceAnchor, targetAnchor, direction, grow, offsetX, offsetY =
					TargetedSpellsSaved.Settings.Party.Width,
					TargetedSpellsSaved.Settings.Party.Height,
					TargetedSpellsSaved.Settings.Party.Gap,
					TargetedSpellsSaved.Settings.Party.SortOrder,
					TargetedSpellsSaved.Settings.Party.SourceAnchor,
					TargetedSpellsSaved.Settings.Party.TargetAnchor,
					TargetedSpellsSaved.Settings.Party.Direction,
					TargetedSpellsSaved.Settings.Party.Grow,
					TargetedSpellsSaved.Settings.Party.OffsetX,
					TargetedSpellsSaved.Settings.Party.OffsetY

				Private.Utils.SortFrames(frames, sortOrder)

				local isHorizontal = direction == Private.Enum.Direction.Horizontal
				local total = (#frames * (isHorizontal and width or height)) + (#frames - 1) * gap
				local parentDimension = isHorizontal and parentFrame:GetWidth() or parentFrame:GetHeight()

				for j, frame in ipairs(frames) do
					local x = offsetX
					local y = offsetY

					if isHorizontal then
						x = Private.Utils.CalculateCoordinate(j, width, gap, parentDimension, total, offsetX, grow)
					else
						y = Private.Utils.CalculateCoordinate(j, width, gap, parentDimension, total, offsetY, grow)
					end

					frame:Reposition(sourceAnchor, parentFrame, targetAnchor, x, y)
				end
			end
		end
	end
end

function TargetedSpellsDriver:CleanUpUnit(unit)
	local frames = self.frames[unit]

	if frames ~= nil and #frames > 0 then
		for _, frame in pairs(frames) do
			frame:Reset()
			self.framePool:Release(frame)
		end

		table.wipe(self.frames[unit])

		return true
	end

	return false
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

---@enum StaticPopupKind
local StaticPopupKind = {
	NamePlateShowOffScreen = 1,
	CAAEnabled = 2,
	CAASayIfTargeted = 3,
}

---@param kind StaticPopupKind
local function SetupStaticPopup(kind)
	local text, OnAccept = nil, nil

	if kind == StaticPopupKind.NamePlateShowOffScreen then
		text = Private.L.Functionality.CVarWarning
		OnAccept = function(dialog, data)
			C_CVar.SetCVar("nameplateShowOffscreen", 1)
			-- Settings.OpenToCategory(Settings.NAMEPLATE_OPTIONS_CATEGORY_ID, UNIT_NAMEPLATES_SHOW_OFFSCREEN)
		end
	elseif kind == StaticPopupKind.CAAEnabled then
		text = Private.L.Functionality.CAAManuallyDisabledWarning
		OnAccept = function(dialog, data)
			C_CVar.SetCVar("CAAEnabled", 1)
		end
	elseif kind == StaticPopupKind.CAASayIfTargeted then
		text = Private.L.Functionality.CAASayIfTargetedDisabledWarning
		OnAccept = function(dialog, data)
			C_CombatAudioAlert.SetSpecSetting(Enum.CombatAudioAlertSpecSetting.SayIfTargeted, 1)
		end
	end

	if StaticPopupDialogs[addonName] == nil then
		StaticPopupDialogs[addonName] = {
			id = addonName,
			button1 = ENABLE,
			button2 = CLOSE,
			whileDead = true,
		}
	end

	StaticPopupDialogs[addonName].text = text
	StaticPopupDialogs[addonName].OnAccept = OnAccept

	local function Show()
		StaticPopup_Hide(addonName)
		StaticPopup_Show(addonName)
	end

	local function Hide()
		StaticPopup_Hide(addonName)
	end

	return Show, Hide
end

local sawPlayerLogin = false

---@param listenerFrame Frame -- identical to self.frame
---@param event "PLAYER_LOGIN" | "UNIT_SPELLCAST_INTERRUPTED" | "UNIT_SPELLCAST_FAILED_QUIET" | "ZONE_CHANGED_NEW_AREA" | "LOADING_SCREEN_DISABLED" | "PLAYER_SPECIALIZATION_CHANGED" | "UNIT_SPELLCAST_EMPOWER_STOP" | "UNIT_SPELLCAST_EMPOWER_START" | "UNIT_SPELLCAST_SUCCEEDED" |"EDIT_MODE_POSITION_CHANGED" | "DELAYED_UNIT_SPELLCAST_START" | "DELAYED_UNIT_SPELLCAST_CHANNEL_START" | "UNIT_SPELLCAST_START" | "UNIT_SPELLCAST_STOP" | "UNIT_SPELLCAST_CHANNEL_START" | "UNIT_SPELLCAST_CHANNEL_STOP" | "NAME_PLATE_UNIT_REMOVED" | "NAME_PLATE_UNIT_ADDED"
function TargetedSpellsDriver:OnFrameEvent(listenerFrame, event, ...)
	if
		event == "UNIT_SPELLCAST_START"
		or event == "UNIT_SPELLCAST_CHANNEL_START"
		or event == "UNIT_SPELLCAST_EMPOWER_START"
	then
		local unit, castGuid, spellId = ...

		if
			string.find(unit, "nameplate") == nil
			or UnitInParty(unit)
			or not UnitExists(unit)
			or not UnitAffectingCombat(unit)
		then
			return
		end

		C_Timer.After(
			self.delay,
			GenerateClosure(
				self.OnFrameEvent,
				self,
				self.listenerFrame,
				event == "UNIT_SPELLCAST_START" and Private.Enum.Events.DELAYED_UNIT_SPELLCAST_START
					or Private.Enum.Events.DELAYED_UNIT_SPELLCAST_CHANNEL_START,
				{
					unit = unit,
					spellId = spellId,
					startTime = GetTime(),
				}
			)
		)
	elseif event == "UNIT_TARGET" then
		local unit = ...

		if
			string.find(unit, "nameplate") == nil
			or UnitInParty(unit)
			or not UnitExists(unit)
			or not UnitAffectingCombat(unit)
		then
			return
		end

		local delayEvent = Private.Enum.Events.DELAYED_UNIT_SPELLCAST_START
		local spellId = select(9, UnitCastingInfo(unit))

		if spellId == nil then
			spellId = select(8, UnitChannelInfo(unit))
			delayEvent = Private.Enum.Events.DELAYED_UNIT_SPELLCAST_CHANNEL_START
		end

		if spellId == nil then
			return
		end

		self:OnFrameEvent(self.listenerFrame, delayEvent, {
			unit = unit,
			spellId = spellId,
			-- best we can do. _possibly_ wrong depending on when the enemy turned
			startTime = GetTime(),
		})
	elseif event == "NAME_PLATE_UNIT_ADDED" then
		local unit = ...

		if
			string.find(unit, "nameplate") == nil
			or UnitInParty(unit)
			or not UnitExists(unit)
			or not UnitAffectingCombat(unit)
		then
			return
		end

		local spellId = nil
		local castTime = nil
		local startTime = nil

		if Private.IsMidnight then
			spellId = select(9, UnitCastingInfo(unit)) or select(8, UnitChannelInfo(unit))

			if spellId == nil then
				return
			end

			local nameplate = C_NamePlate.GetNamePlateForUnit(unit, issecure())

			if nameplate == nil then
				return
			end

			castTime = select(2, nameplate.UnitFrame.castBar:GetMinMaxValues())
			startTime = GetTime() -- todo: this is wrong
		else
			local _, _, _, startTimeMs, endTimeMs, _, _, _, castingSpellId = UnitCastingInfo(unit)

			if castingSpellId == nil then
				_, _, _, startTimeMs, endTimeMs, _, _, castingSpellId = UnitChannelInfo(unit)
			end

			if castingSpellId == nil then
				return
			end

			spellId = castingSpellId
			startTime = startTimeMs / 1000
			castTime = (endTimeMs - startTimeMs) / 1000
		end

		local frames = self:AcquireFrames(unit)

		if #frames == 0 then
			return
		end

		if self.frames[unit] == nil then
			self.frames[unit] = {}
		else
			self:CleanUpUnit(unit)
		end

		for _, frame in ipairs(frames) do
			table.insert(self.frames[unit], frame)
			frame:SetSpellId(spellId)
			frame:SetStartTime(startTime)
			frame:SetCastTime(castTime)
			frame:RefreshSpellCooldownInfo()
			frame:AttemptToPlaySound(self.contentType, unit)
			frame:AttemptToPlayTTS(self.contentType, unit)
			frame:Show()
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
				if self:CleanUpUnit(unit) then
					cleanedSomethingUp = true
				end
			end

			if cleanedSomethingUp then
				self:RepositionFrames()
			end
		elseif name == "nameplateShowOffscreen" then
			local Show, Hide = SetupStaticPopup(StaticPopupKind.NamePlateShowOffScreen)

			if value == "1" or value == 1 then
				Hide()
			else
				Show()
			end
		elseif name == "CAAEnabled" then
			if not TargetedSpellsSaved.Settings.Self.PlayTTS and not TargetedSpellsSaved.Settings.Self.PlaySound then
				return
			end

			local Show, Hide = SetupStaticPopup(StaticPopupKind.CAAEnabled)

			if value == "1" or value == 1 then
				Hide()
			else
				Show()
			end
		elseif name == "CAASayIfTargeted" then
			if
				not sawPlayerLogin
				and not TargetedSpellsSaved.Settings.Self.PlayTTS
				and not TargetedSpellsSaved.Settings.Self.PlaySound
			then
				return
			end

			local Show, Hide = SetupStaticPopup(StaticPopupKind.CAASayIfTargeted)
			local state = C_CombatAudioAlert.GetSpecSetting(Enum.CombatAudioAlertSpecSetting.SayIfTargeted)

			if state == 0 then
				Show()
			else
				Hide()
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
		local unit = ...

		if string.find(unit, "nameplate") == nil or UnitInParty(unit) or not UnitExists(unit) then
			return
		end

		if self:CleanUpUnit(unit) then
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

		local nameplate = C_NamePlate.GetNamePlateForUnit(info.unit, issecure())

		-- without `nameplateShowOffscreen` active, it may be offscreen
		if nameplate == nil then
			return
		end

		local frames = self:AcquireFrames(info.unit)

		if #frames == 0 then
			return
		end

		if self.frames[info.unit] == nil then
			self.frames[info.unit] = {}
		else
			self:CleanUpUnit(info.unit)
		end

		local castTime = select(2, nameplate.UnitFrame.castBar:GetMinMaxValues())

		for _, frame in ipairs(frames) do
			table.insert(self.frames[info.unit], frame)
			frame:SetSpellId(info.spellId)
			frame:SetStartTime(info.startTime)
			frame:SetCastTime(castTime)
			frame:RefreshSpellCooldownInfo()
			frame:AttemptToPlaySound(self.contentType, info.unit)
			frame:AttemptToPlayTTS(self.contentType, info.unit)
			frame:Show()
		end

		self:RepositionFrames()
	elseif
		event == "ZONE_CHANGED_NEW_AREA"
		or event == "LOADING_SCREEN_DISABLED"
		or event == "PLAYER_SPECIALIZATION_CHANGED"
		or event == "UPDATE_INSTANCE_INFO"
	then
		local name, instanceType, difficultyId = GetInstanceInfo()
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

		if nextContentType ~= self.contentType then
			self.contentType = nextContentType
			for label, id in pairs(Private.Enum.ContentType) do
				if id == nextContentType then
					print("detected content type change", label)
					break
				end
			end

			self:MaybeApplyCombatAudioAlertOverride()
		end

		local specId = PlayerUtil.GetCurrentSpecID()
		local nextRole = self.role

		if
			specId == 105 -- restoration druid
			or specId == 1468 -- preservation evoker
			or specId == 270 -- mistweaver monk
			or specId == 65 -- holy paladin
			or specId == 256 -- discipline priest
			or specId == 257 -- holy priest
			or specId == 264 -- restoration shaman
		then
			nextRole = Private.Enum.Role.Healer
		elseif
			specId == 250 -- blood death knight
			or specId == 581 -- vengeance demon hunter
			or specId == 104 -- guardian druid
			or specId == 268 -- brewmaster monk
			or specId == 66 -- protection paladin
			or specId == 73 -- protection warrior
		then
			nextRole = Private.Enum.Role.Tank
		else
			nextRole = Private.Enum.Role.Damager
		end

		if nextRole ~= self.role then
			self.role = nextRole

			for label, id in pairs(Private.Enum.Role) do
				if id == self.role then
					print("detected role change", label)
					break
				end
			end
		end
	elseif event == Private.Enum.Events.EDIT_MODE_POSITION_CHANGED then
		local point, x, y = ...

		self.frame:ClearAllPoints()
		self.frame:SetPoint(point, x, y)
		self.frame:Show()
	elseif event == "PLAYER_LOGIN" then
		sawPlayerLogin = true

		if not TargetedSpellsSaved.Settings.Self.PlayTTS and not TargetedSpellsSaved.Settings.Self.PlaySound then
			return
		end

		local state = C_CombatAudioAlert.GetSpecSetting(Enum.CombatAudioAlertSpecSetting.SayIfTargeted)

		if state == 0 then
			print(Private.L.Functionality.CAASayIfTargetedDisabledWarning)
		end
	end
end

function TargetedSpellsDriver:OnSettingsChanged(key, value)
	if key == Private.Settings.Keys.Self.Enabled or key == Private.Settings.Keys.Party.Enabled then
		local allDisabled = TargetedSpellsSaved.Settings.Self.Enabled == false
			and TargetedSpellsSaved.Settings.Party.Enabled == false

		if allDisabled then
			self.frame:UnregisterAllEvents()
			self.frame:SetScript("OnEvent", nil)
			print("TargetedSpellsDriver:OnSettingsChanged: removed listeners")
		else
			self:SetupFrame(false)
		end
	elseif key == Private.Settings.Keys.Self.PlayTTS or key == Private.Settings.Keys.Self.PlaySound then
		if not Private.IsMidnight then
			return
		end

		if value then
			C_CVar.SetCVar("CAAEnabled", 1)
			C_CVar.SetCVar("CAASayCombatStart", 0)
			C_CVar.SetCVar("CAASayCombatEnd", 0)
			C_CVar.SetCVar("CAAVoice", Private.Utils.FindAppropriateTTSVoiceId())
			C_CVar.SetCVar("CAASayTargetName", 0)
			C_CVar.SetCVar("CAATargetHealthPercent", 0)
			C_CombatAudioAlert.SetSpecSetting(Enum.CombatAudioAlertSpecSetting.SayIfTargeted, 1)

			print(Private.L.Functionality.CAAEnabledWarning)
		else
			-- C_CVar.SetCVar("CAAEnabled", 0)
			-- print(Private.L.Functionality.CAADisabledWarning)
		end
	end
end

function TargetedSpellsDriver:MaybeApplyCombatAudioAlertOverride()
	if not Private.IsMidnight then
		return
	end

	if not TargetedSpellsSaved.Settings.Self.PlaySound and not TargetedSpellsSaved.Settings.Self.PlayTTS then
		return
	end

	local function GetCurrentContentType()
		return self.contentType
	end

	function CombatAudioAlertManager:GetUnitFormattedTargetingString(unit)
		local spellId = select(9, UnitCastingInfo(unit))

		if spellId == nil then
			spellId = select(8, UnitChannelInfo(unit))
		end

		if spellId == nil then
			return "" -- this is good old aggro
		end

		if TargetedSpellsSaved.Settings.Self.PlaySound then
			if TargetedSpellsSaved.Settings.Self.LoadConditionSoundContentType[GetCurrentContentType()] then
				Private.Utils.AttemptToPlaySound(
					TargetedSpellsSaved.Settings.Self.Sound,
					TargetedSpellsSaved.Settings.Self.SoundChannel
				)
			end
		elseif TargetedSpellsSaved.Settings.Self.PlayTTS then
			local spellName = C_Spell.GetSpellName(spellId)

			if spellName ~= nil then
				Private.Utils.PlayTTS(spellName)
			end
		end

		return ""
	end
end

table.insert(Private.LoginFnQueue, GenerateClosure(TargetedSpellsDriver.Init, TargetedSpellsDriver))
