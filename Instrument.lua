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
	self.delay = 0.1
	self.frames = {}
	self.playerRole = nil
	Private.EventRegistry:RegisterCallback(Private.Enum.Events.SETTING_CHANGED, self.OnSettingsChanged, self)

	self:SetupListenerFrame(true)
end

function TargetedSpellsDriver:SetupListenerFrame(isBoot)
	if isBoot then
		local frame = CreateFrame("Frame", "TargetedSpellsDriverFrame", UIParent)
		self.listenerFrame = frame

		Private.EventRegistry:RegisterCallback(
			Private.Enum.Events.EDIT_MODE_POSITION_CHANGED,
			self.OnFrameEvent,
			frame,
			frame,
			Private.Enum.Events.EDIT_MODE_POSITION_CHANGED
		)

		frame:SetSize(1, 1)
		frame:ClearAllPoints()
		frame:SetPoint(
			TargetedSpellsSaved.Settings.Self.Position.point,
			TargetedSpellsSaved.Settings.Self.Position.x,
			TargetedSpellsSaved.Settings.Self.Position.y
		)
		frame:Show()
	end

	if
		(Private.Settings.Keys.Self.Enabled or Private.Settings.Keys.Party.Enabled)
		and not self.listenerFrame:IsEventRegistered("UNIT_SPELLCAST_START")
	then
		self.listenerFrame:RegisterEvent("LOADING_SCREEN_DISABLED")
		self.listenerFrame:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")
		self.listenerFrame:RegisterUnitEvent("UNIT_SPELLCAST_START")
		self.listenerFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED")
		self.listenerFrame:RegisterUnitEvent("UNIT_SPELLCAST_STOP")
		self.listenerFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START")
		self.listenerFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP")
		self.listenerFrame:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_START")
		self.listenerFrame:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_STOP")
		self.listenerFrame:RegisterUnitEvent("NAME_PLATE_UNIT_REMOVED")
		self.listenerFrame:RegisterUnitEvent("NAME_PLATE_UNIT_ADDED")
		if Private.IsMidnight then
			self.listenerFrame:RegisterUnitEvent("CVAR_UPDATE")
		end
		self.listenerFrame:SetScript("OnEvent", GenerateClosure(self.OnFrameEvent, self))

		print(
			format(
				"TargetedSpellsDriver:OnSettingsChanged: %sattached listeners, the role is %d",
				isBoot and "" or "re"
			)
		)
	end
end

if Private.IsMidnight then
	function TargetedSpellsDriver:AcquireFrames(castingUnit)
		local frames = {}

		local selfTargetingFrame = self.framePool:Acquire()
		selfTargetingFrame:SetParent(self.listenerFrame)
		selfTargetingFrame:PostCreate("player", Private.Enum.FrameKind.Self, castingUnit)
		table.insert(frames, selfTargetingFrame)

		if TargetedSpellsSaved.Settings.Party.Enabled and IsInGroup() then
			local partyMemberCount = GetNumGroupMembers()

			for i = 1, partyMemberCount do
				local token = i == partyMemberCount and "player" or "party" .. i

				if
					(token == "player" and TargetedSpellsSaved.Settings.Party.IncludeSelfInParty)
					or token ~= "player"
				then
					local frame = self.framePool:Acquire()
					frame:PostCreate(token, Private.Enum.FrameKind.Party, castingUnit)
					table.insert(frames, frame)
					pprint("added frame for", token)
				end
			end
		end

		pprint("acquired", #frames, "frames for", castingUnit)

		return frames
	end
else
	function TargetedSpellsDriver:AcquireFrames(castingUnit)
		local frames = {}

		if UnitIsUnit(string.format("%starget", castingUnit), "player") then
			local selfTargetingFrame = self.framePool:Acquire()
			selfTargetingFrame:SetParent(self.listenerFrame)
			selfTargetingFrame:PostCreate("player", Private.Enum.FrameKind.Self, castingUnit)
			table.insert(frames, selfTargetingFrame)
		end

		if TargetedSpellsSaved.Settings.Party.Enabled and IsInGroup() then
			local partyMemberCount = GetNumGroupMembers()

			for i = 1, partyMemberCount do
				local token = i == partyMemberCount and "player" or "party" .. i

				if
					UnitIsUnit(string.format("%starget", castingUnit), token)
					and (
						(token == "player" and TargetedSpellsSaved.Settings.Party.IncludeSelfInParty)
						or token ~= "player"
					)
				then
					local frame = self.framePool:Acquire()
					frame:PostCreate(token, Private.Enum.FrameKind.Party, castingUnit)
					table.insert(frames, frame)
					pprint("added frame for", token)
				end
			end
		end

		pprint("acquired", #frames, "frames for", castingUnit)

		return frames
	end
end

-- this is where 3rd party unit frames would need addition
---@param unit string
---@return Frame?
local function FindParentFrameForUnit(unit)
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
					if activeFrames.self == nil then
						activeFrames.self = {}
					end

					table.insert(activeFrames.self, frame)
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
		if targetUnit == Private.Enum.FrameKind.Self then
			local width, height, gap, sortOrder, direction, grow =
				TargetedSpellsSaved.Settings.Self.Width,
				TargetedSpellsSaved.Settings.Self.Height,
				TargetedSpellsSaved.Settings.Self.Gap,
				TargetedSpellsSaved.Settings.Self.SortOrder,
				TargetedSpellsSaved.Settings.Self.Direction,
				TargetedSpellsSaved.Settings.Self.Grow
			local isHorizontal = direction == Private.Enum.Direction.Horizontal
			local parent = self.listenerFrame
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

				frame:Reposition(point, parent, "CENTER", x, y)
			end
		else
			local parentFrame = FindParentFrameForUnit(targetUnit)

			-- no unit frame addon support at this time
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

function TargetedSpellsDriver:CleanUpUnit(unit, event)
	local frames = self.frames[unit]

	if frames ~= nil and #frames > 0 then
		for _, frame in pairs(frames) do
			frame:Reset()
			self.framePool:Release(frame)
		end

		local nFrames = #frames

		table.wipe(self.frames[unit])

		pprint("removed " .. nFrames .. " frames for", unit, "through", event)

		return true
	end

	return false
end

function TargetedSpellsDriver:OnRoleChange(newRole)
	print("TargetedSpellsDriver:OnRoleChange()", newRole)
end

local function OnCVarChange(value)
	local staticPopupDialogKey = addonName

	if StaticPopupDialogs[staticPopupDialogKey] == nil then
		StaticPopupDialogs[staticPopupDialogKey] = {
			id = addonName,
			button1 = ACCEPT,
			button2 = CLOSE,
			whileDead = true,
			text = Private.L.Functionality.CVarWarning,
			OnAccept = function(dialog, data)
				C_CVar.SetCVar("nameplateShowOffscreen", 1)
				-- Settings.OpenToCategory(Settings.NAMEPLATE_OPTIONS_CATEGORY_ID, UNIT_NAMEPLATES_SHOW_OFFSCREEN)
			end,
		}
	end

	if value == "1" or value == 1 then
		StaticPopup_Hide(staticPopupDialogKey)
	else
		StaticPopup_Show(addonName)
	end
end

---@param listenerFrame Frame -- identical to self.listenerFrame
---@param event "LOADING_SCREEN_DISABLED" | "PLAYER_SPECIALIZATION_CHANGED" | "UNIT_SPELLCAST_EMPOWER_STOP" | "UNIT_SPELLCAST_EMPOWER_START" | "UNIT_SPELLCAST_SUCCEEDED" |"EDIT_MODE_POSITION_CHANGED" | "DELAYED_UNIT_SPELLCAST_START" | "DELAYED_UNIT_SPELLCAST_CHANNEL_START" | "UNIT_SPELLCAST_START" | "UNIT_SPELLCAST_STOP" | "UNIT_SPELLCAST_CHANNEL_START" | "UNIT_SPELLCAST_CHANNEL_STOP" | "NAME_PLATE_UNIT_REMOVED" | "NAME_PLATE_UNIT_ADDED"
function TargetedSpellsDriver:OnFrameEvent(listenerFrame, event, ...)
	if
		event == "UNIT_SPELLCAST_START"
		or event == "UNIT_SPELLCAST_CHANNEL_START"
		or event == "UNIT_SPELLCAST_EMPOWER_START"
	then
		local unit, castGuid, spellId = ...

		if
			UnitInParty(unit)
			or not UnitExists(unit)
			or UnitIsUnit("player", unit)
			or not UnitAffectingCombat(unit)
			or string.find(unit, "nameplate") == nil
		then
			return
		end

		C_Timer.After(
			self.delay,
			GenerateClosure(
				self.OnFrameEvent,
				self,
				listenerFrame,
				event == "UNIT_SPELLCAST_START" and Private.Enum.Events.DELAYED_UNIT_SPELLCAST_START
					or Private.Enum.Events.DELAYED_UNIT_SPELLCAST_CHANNEL_START,
				{
					unit = unit,
					spellId = spellId,
					startTime = GetTime(),
				}
			)
		)
	elseif event == "NAME_PLATE_UNIT_ADDED" then
		local unit = ...
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

		if self.frames[unit] == nil then
			self.frames[unit] = {}
		end

		local frames = self:AcquireFrames(unit)

		for _, frame in ipairs(frames) do
			table.insert(self.frames[unit], frame)
			frame:SetSpellId(spellId)
			frame:SetStartTime(startTime)
			frame:SetCastTime(castTime)
			frame:RefreshSpellCooldownInfo()
			frame:AttemptToPlaySound()
			frame:Show()
		end

		self:RepositionFrames()
	elseif event == "NAME_PLATE_UNIT_REMOVED" then
		local unit = ...

		-- todo: decide whether we actually care about this
		if
			UnitInParty(unit)
			or not UnitExists(unit)
			or UnitIsUnit("player", unit)
			or string.find(unit, "nameplate") == nil
		then
			return
		end

		if self:CleanUpUnit(unit, event) then
			self:RepositionFrames()
		end
	elseif event == "CVAR_UPDATE" then
		local name, value = ...

		if name == "nameplateShowEnemies" then
			if value ~= 0 then
				return
			end

			local cleanedSomethingUp = false

			for unit in pairs(self.frames) do
				if self:CleanUpUnit(unit, event) then
					cleanedSomethingUp = true
				end
			end

			if cleanedSomethingUp then
				self:RepositionFrames()
			end
		elseif name == "nameplateShowOffscreen" then
			OnCVarChange(value)
		end
	elseif
		event == "UNIT_SPELLCAST_STOP"
		or event == "UNIT_SPELLCAST_CHANNEL_STOP"
		or event == "UNIT_SPELLCAST_SUCCEEDED"
		or event == "UNIT_SPELLCAST_EMPOWER_STOP"
	then
		local unit = ...

		-- todo: decide whether we actually care about this
		if
			UnitInParty(unit)
			or not UnitExists(unit)
			or UnitIsUnit("player", unit)
			or string.find(unit, "nameplate") == nil
		then
			return
		end

		if self:CleanUpUnit(unit, event) then
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

		if self.frames[info.unit] == nil then
			self.frames[info.unit] = {}
		end

		local frames = self:AcquireFrames(info.unit)

		local castTime = select(2, nameplate.UnitFrame.castBar:GetMinMaxValues())

		for _, frame in ipairs(frames) do
			table.insert(self.frames[info.unit], frame)
			frame:SetSpellId(info.spellId)
			frame:SetStartTime(info.startTime)
			frame:SetCastTime(castTime)
			frame:RefreshSpellCooldownInfo()
			frame:AttemptToPlaySound()
			frame:Show()
		end

		self:RepositionFrames()
	elseif event == "LOADING_SCREEN_DISABLED" then
		local newRole = Private.Utils.GetCurrentRole()

		if newRole ~= self.playerRole then
			self:OnRoleChange(newRole)
		end
	elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
		local unit = ...

		if unit ~= "player" then
			return
		end

		local newRole = Private.Utils.GetCurrentRole()

		if newRole ~= self.playerRole then
			self:OnRoleChange(newRole)
		end
	elseif event == Private.Enum.Events.EDIT_MODE_POSITION_CHANGED then
		local point, x, y = ...

		listenerFrame:ClearAllPoints()
		listenerFrame:SetPoint(point, x, y)
		listenerFrame:Show()
	end
end

function TargetedSpellsDriver:OnSettingsChanged(key, value)
	if key == Private.Settings.Keys.Self.Enabled or key == Private.Settings.Keys.Party.Enabled then
		local allDisabled = TargetedSpellsSaved.Settings.Self.Enabled == false
			and TargetedSpellsSaved.Settings.Party.Enabled == false

		if allDisabled then
			self.listenerFrame:UnregisterAllEvents()
			self.listenerFrame:SetScript("OnEvent", nil)
			print("TargetedSpellsDriver:OnSettingsChanged: removed listeners")
		else
			self:SetupListenerFrame(false)
		end
	elseif key == Private.Settings.Keys.Self.LoadConditionContentType then
	elseif key == Private.Settings.Keys.Self.LoadConditionRole then
	elseif key == Private.Settings.Keys.Party.LoadConditionContentType then
	elseif key == Private.Settings.Keys.Party.LoadConditionRole then
	end
end

table.insert(Private.LoginFnQueue, GenerateClosure(TargetedSpellsDriver.Init, TargetedSpellsDriver))
