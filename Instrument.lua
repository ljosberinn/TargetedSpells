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
			self,
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
		self.listenerFrame:RegisterUnitEvent("CVAR_UPDATE")
		self.listenerFrame:RegisterUnitEvent("UNIT_SPELLCAST_START")
		self.listenerFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED")
		self.listenerFrame:RegisterUnitEvent("UNIT_SPELLCAST_STOP")
		self.listenerFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START")
		self.listenerFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP")
		self.listenerFrame:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_START")
		self.listenerFrame:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_STOP")
		self.listenerFrame:RegisterUnitEvent("NAME_PLATE_UNIT_REMOVED")
		-- self.listenerFrame:RegisterUnitEvent("UNIT_DIED")
		self.listenerFrame:SetScript("OnEvent", GenerateClosure(self.OnFrameEvent, self))
	end
end

function TargetedSpellsDriver:AcquireFrames(castingUnit)
	local frames = {}

	local selfTargetingFrame = self.framePool:Acquire()
	selfTargetingFrame:SetParent(self.listenerFrame)
	selfTargetingFrame:PostCreate("player", Private.Enum.FrameKind.Self, castingUnit)
	table.insert(frames, selfTargetingFrame)

	-- todo: account for showing/ignoring self on party frame too
	if TargetedSpellsSaved.Settings.Party.Enabled and IsInGroup() then
		for i = 1, GetNumGroupMembers() do
			local frame = self.framePool:Acquire()
			frame:PostCreate("party" .. i, Private.Enum.FrameKind.Party, castingUnit)
			table.insert(frames, frame)
		end
	end

	if TargetedSpellsSaved.Settings.Party.IncludeSelfInParty then
		local frame = self.framePool:Acquire()
		frame:PostCreate("player", Private.Enum.FrameKind.Party, castingUnit)
		table.insert(frames, frame)
	end

	pprint("acquired", #frames, "frames for", castingUnit)

	return frames
end

function TargetedSpellsDriver:SortFrames(frames, sortOrder)
	local isAscending = sortOrder == Private.Enum.SortOrder.Ascending

	table.sort(frames, function(a, b)
		if isAscending then
			return a:GetStartTime() < b:GetStartTime()
		end

		return a:GetStartTime() > b:GetStartTime()
	end)
end

function TargetedSpellsDriver:CalculateCoordinate(index, dimension, gap, parentDimension, total, offset, grow)
	if grow == Private.Enum.Grow.Start then
		return (index - 1) * (dimension + gap) - parentDimension / 2 + offset
	elseif grow == Private.Enum.Grow.Center then
		return (index - 1) * (dimension + gap) - total / 2 + offset
	elseif grow == Private.Enum.Grow.End then
		return parentDimension / 2 - index * (dimension + gap) + offset
	end

	return 0
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

			self:SortFrames(frames, sortOrder)

			for i, frame in ipairs(frames) do
				local x = 0
				local y = -(height / 2)

				if isHorizontal then
					if grow == Private.Enum.Grow.Start then
						local frameDimension = isHorizontal and frame:GetWidth() or frame:GetHeight()
						x = (i - 1) * (width + gap) - frameDimension / 2
					elseif grow == Private.Enum.Grow.Center then
						x = (i - 1) * (width + gap) - total / 2
					elseif grow == Private.Enum.Grow.End then
						local frameDimension = isHorizontal and frame:GetWidth() or frame:GetHeight()
						x = frameDimension / 2 - i * (width + gap)
					end
				else
					if grow == Private.Enum.Grow.Start then
						local frameDimension = isHorizontal and frame:GetWidth() or frame:GetHeight()
						y = (i - 1) * (width + gap) - frameDimension / 2 + 0
					elseif grow == Private.Enum.Grow.Center then
						y = (i - 1) * (width + gap) - total / 2 + 0
					elseif grow == Private.Enum.Grow.End then
						local frameDimension = isHorizontal and frame:GetWidth() or frame:GetHeight()
						y = frameDimension / 2 - i * (width + gap) + 0
					end
				end

				frame:Reposition(point, parent, "CENTER", x, y)
			end
		else
			local parentFrame = nil

			if targetUnit == "player" then
				if not EditModeManagerFrame:UseRaidStylePartyFrames() then
					-- non-raid style party frames don't include the player
					return
				end

				for _, frame in pairs(CompactPartyFrame.memberUnitFrames) do
					if frame.unit == "player" then
						parentFrame = frame
						break
					end
				end
			else
				local index = tonumber(string.sub(targetUnit, 6))

				if EditModeManagerFrame:UseRaidStylePartyFrames() then
					parentFrame = CompactPartyFrame.memberUnitFrames[index]
				else
					for memberFrame in PartyFrame.PartyMemberFramePool:EnumerateActive() do
						if memberFrame.layoutIndex == index then
							parentFrame = memberFrame
							break
						end
					end
				end
			end

			-- no unit frame addon support at this time
			if parentFrame == nil then
				pprint("could not establish a parent frame for", targetUnit)
				return
			end

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
			self:SortFrames(frames, sortOrder)

			local isHorizontal = direction == Private.Enum.Direction.Horizontal
			local total = (#frames * (isHorizontal and width or height)) + (#frames - 1) * gap
			local parentDimension = isHorizontal and parentFrame:GetWidth() or parentFrame:GetHeight()

			for j, frame in ipairs(frames) do
				local x = 0
				local y = 0

				if isHorizontal then
					if grow == Private.Enum.Grow.Start then
						x = (j - 1) * (width + gap) - parentDimension / 2
					elseif grow == Private.Enum.Grow.Center then
						x = (j - 1) * (width + gap) - total / 2
					else
						x = parentDimension / 2 - j * (width + gap)
					end
				else
					if grow == Private.Enum.Grow.Start then
						y = (j - 1) * (width + gap) - parentDimension / 2 + 0
					elseif grow == Private.Enum.Grow.Center then
						y = (j - 1) * (width + gap) - total / 2 + 0
					else
						y = parentDimension / 2 - j * (width + gap) + 0
					end
				end

				x = x + offsetX
				y = y + offsetY

				frame:Reposition(sourceAnchor, parentFrame, targetAnchor, x, y)
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

---@param listenerFrame Frame -- identical to self.listenerFrame
---@param event "UNIT_SPELLCAST_EMPOWER_STOP" | "UNIT_SPELLCAST_EMPOWER_START" | "UNIT_SPELLCAST_SUCCEEDED" |"EDIT_MODE_POSITION_CHANGED" | "DELAYED_UNIT_SPELLCAST_START" | "DELAYED_UNIT_SPELLCAST_CHANNEL_START" | "UNIT_SPELLCAST_START" | "UNIT_SPELLCAST_STOP" | "UNIT_SPELLCAST_CHANNEL_START" | "UNIT_SPELLCAST_CHANNEL_STOP" | "NAME_PLATE_UNIT_REMOVED"
function TargetedSpellsDriver:OnFrameEvent(listenerFrame, event, ...)
	if event == Private.Enum.Events.EDIT_MODE_POSITION_CHANGED then
		local point, x, y = ...

		self.listenerFrame:ClearAllPoints()
		self.listenerFrame:SetPoint(point, x, y)
		self.listenerFrame:Show()
	elseif
		event == "UNIT_SPELLCAST_START"
		or event == "UNIT_SPELLCAST_CHANNEL_START"
		or event == "UNIT_SPELLCAST_EMPOWER_START"
	then
		local unit, castGuid, spellId = ...

		if
			UnitInParty(unit)
			or not UnitExists(unit)
			or UnitIsUnit("player", unit)
			or not UnitAffectingCombat(unit) -- todo: needs testing. intended to skip rp casts
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
	elseif event == "UNIT_DIED" then
		-- todo: not registered yet, doesn't exist yet. once it does, check whether it provides the unit and then also try to clean up lingering state
	elseif event == "NAME_PLATE_UNIT_REMOVED" then
		local unit = ...

		-- todo: decide whether we actually care about this
		if
			UnitInParty(unit)
			-- or not UnitExists(unit) -- ? this might not make sense here
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
			return
		elseif name == "nameplateShowOffscreen" then
			if value == "0" or value == 0 then
				print(
					"The CVar nameplateShowOffscreen is set to 0 - this will lead to TargetedSpells not working on offscreen enemies."
				)
			end
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
		local unit = info.unit
		local spellId = info.spellId
		local startTime = info.startTime

		-- cast vanished during the delay
		if event == Private.Enum.Events.DELAYED_UNIT_SPELLCAST_START and UnitCastingInfo(unit) == nil then
			return
		elseif event == Private.Enum.Events.DELAYED_UNIT_SPELLCAST_CHANNEL_START and UnitChannelInfo(unit) == nil then
			return
		end

		local nameplate = C_NamePlate.GetNamePlateForUnit(unit, issecure())

		-- without `nameplateShowOffscreen` active, it may be offscreen
		if nameplate == nil then
			return
		end

		local castTime = select(2, nameplate.UnitFrame.castBar:GetMinMaxValues())

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
			print("TargetedSpellsDriver:OnSettingsChanged: reattached listeners")
		end
	elseif key == Private.Settings.Keys.Self.LoadConditionContentType then
	elseif key == Private.Settings.Keys.Self.LoadConditionRole then
	elseif key == Private.Settings.Keys.Party.LoadConditionContentType then
	elseif key == Private.Settings.Keys.Party.LoadConditionRole then
	end
end

table.insert(Private.LoginFnQueue, GenerateClosure(TargetedSpellsDriver.Init, TargetedSpellsDriver))
