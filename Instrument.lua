---@type string, TargetedSpells
local addonName, Private = ...

---@class TargetedSpellsDriver
local TargetedSpellsDriver = {}

function TargetedSpellsDriver:Init()
	self.framePool = CreateFramePool("Frame", UIParent, "TargetedSpellsFrameTemplate")
	self.hookedCastBars = {}
	self.delay = 0.1
	self.unitToCastMetaInformation = {}

	self:SetupListenerFrame()
end

function TargetedSpellsDriver:SetupListenerFrame()
	self.listenerFrame = self.listenerFrame or CreateFrame("Frame")

	if
		(Private.Settings.Keys.Self.Enabled or Private.Settings.Keys.Party.Enabled)
		and not self.listenerFrame:IsEventRegistered("UNIT_SPELLCAST_START")
	then
		self.listenerFrame:RegisterUnitEvent("UNIT_SPELLCAST_START")
		self.listenerFrame:RegisterUnitEvent("UNIT_SPELLCAST_STOP")
		self.listenerFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START")
		self.listenerFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP")
		-- todo: empowered spells
		-- self.listenerFrame:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_START")
		-- self.listenerFrame:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_STOP")
		self.listenerFrame:RegisterUnitEvent("NAME_PLATE_UNIT_ADDED")
		self.listenerFrame:RegisterUnitEvent("NAME_PLATE_UNIT_REMOVED")
		-- self.listenerFrame:RegisterUnitEvent("UNIT_DIED")
		self.listenerFrame:SetScript("OnEvent", GenerateClosure(self.OnFrameEvent, self))
	end
end

local last = GetTime()

local function pprint(...)
	local now = GetTime()
	local diff = now - last
	last = now
	print(diff, ...)
end

function TargetedSpellsDriver:AcquireFrames(castingUnit)
	local frames = {}

	if UnitIsUnit("player", castingUnit .. "target") then
		local selfTargetingFrame = self.framePool:Acquire()
		selfTargetingFrame:PostCreate("player", Private.Enum.FrameKind.Self)
		table.insert(frames, selfTargetingFrame)
	end

	-- todo: account for showing/ignoring self on party frame too
	if TargetedSpellsSaved.Settings.Party.Enabled and IsInGroup() then
		for i = 1, GetNumGroupMembers() do
			local unit = "party" .. i

			if UnitIsUnit(castingUnit .. "target", unit) then
				local frame = self.framePool:Acquire()
				frame:PostCreate(unit, Private.Enum.FrameKind.Party)
				table.insert(frames, frame)
				break
			end
		end
	end

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
	local width, height, gap, direction, sortOrder, grow =
		TargetedSpellsSaved.Settings.Self.Width,
		TargetedSpellsSaved.Settings.Self.Height,
		TargetedSpellsSaved.Settings.Self.Gap,
		TargetedSpellsSaved.Settings.Self.Direction,
		TargetedSpellsSaved.Settings.Self.SortOrder,
		TargetedSpellsSaved.Settings.Self.Grow

	---@type TargetedSpellsMixin[]
	local activeFrames = {}

	for unit, castMetaInformation in pairs(self.unitToCastMetaInformation) do
		if castMetaInformation.frames ~= nil then
			for _, frame in pairs(castMetaInformation.frames) do
				if frame ~= nil and frame:ShouldBeShown() then
					table.insert(activeFrames, frame)
				end
			end
		end
	end

	local activeFrameCount = #activeFrames

	if activeFrameCount == 0 then
		return
	end

	pprint("activeFrameCount", activeFrameCount)

	self:SortFrames(activeFrames, sortOrder)

	local isHorizontal = direction == Private.Enum.Direction.Horizontal

	local point = isHorizontal and "LEFT" or "BOTTOM"
	local total = (activeFrameCount * (isHorizontal and width or height)) + (activeFrameCount - 1) * gap
	local parent = _G["Targeted Spells Self"]
	local parentDimension = isHorizontal and 100 or 100
	if parent then
		parentDimension = isHorizontal and parent:GetWidth() or parent:GetHeight()
	end

	for i, frame in ipairs(activeFrames) do
		frame:Reposition(
			point,
			UIParent,
			"CENTER",
			isHorizontal and self:CalculateCoordinate(i, width, gap, parentDimension, total, 0, grow) or 0,
			isHorizontal and 0 or self:CalculateCoordinate(i, width, gap, parentDimension, total, 0, grow)
		)
	end
end

function TargetedSpellsDriver:CleanUpUnit(unit, event)
	local castMetaInformation = self.unitToCastMetaInformation[unit]

	if castMetaInformation ~= nil and castMetaInformation.frames ~= nil then
		for _, frame in pairs(castMetaInformation.frames) do
			frame:Reset()
			self.framePool:Release(frame)
		end

		self.unitToCastMetaInformation[unit] = nil

		pprint("removed meta info for", unit, "through", event)

		return true
	end

	return false
end

---@param listenerFrame Frame -- identical to self.listenerFrame
---@param event "DELAYED_UNIT_SPELLCAST_START" | "DELAYED_UNIT_SPELLCAST_CHANNEL_START" | "UNIT_SPELLCAST_START" | "UNIT_SPELLCAST_STOP" | "UNIT_SPELLCAST_CHANNEL_START" | "UNIT_SPELLCAST_CHANNEL_STOP" | "NAME_PLATE_UNIT_ADDED" | "NAME_PLATE_UNIT_REMOVED"
function TargetedSpellsDriver:OnFrameEvent(listenerFrame, event, ...)
	if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" then
		local unit, castGuid, spellId = ...

		if
			UnitInParty(unit)
			or not UnitExists(unit)
			or UnitIsUnit("player", unit)
			or string.find(unit, "nameplate") == nil
		then
			return
		end

		local closure = GenerateClosure(
			self.OnFrameEvent,
			self,
			listenerFrame,
			event == "UNIT_SPELLCAST_START" and Private.Enum.Events.DELAYED_UNIT_SPELLCAST_START
				or Private.Enum.Events.DELAYED_UNIT_SPELLCAST_CHANNEL_START,
			unit,
			spellId
		)

		C_Timer.After(self.delay, closure)
	elseif event == "NAME_PLATE_UNIT_ADDED" then
		local unit = ...

		local nameplate = C_NamePlate.GetNamePlateForUnit(unit, issecure())

		if nameplate == nil or UnitIsUnit("player", unit) or self.hookedCastBars[unit] ~= nil then
			return
		end

		self.hookedCastBars[unit] = true

		-- all of this wouldn't be necessary if C_Spell.GetSpellInfo(spellId).castTime provided by UNIT_SPELLCAST_START etc.
		-- would would 1. not be hasted by player haste 2. not be milliseconds. since its secret, we cannot use the milliseconds
		nameplate.UnitFrame.castBar:HookScript("OnShow", function(castBarSelf, ...)
			pprint("CastBarOnShow", GetTime(), select(2, castBarSelf:GetMinMaxValues()))
			if
				TargetedSpellsSaved.Settings.Self.Enabled == false
				and TargetedSpellsSaved.Settings.Party.Enabled == false
			then
				return
			end

			self.unitToCastMetaInformation[unit] = {
				castTime = select(2, castBarSelf:GetMinMaxValues()),
				startTime = GetTime(),
				frames = nil,
			}
		end)

		nameplate.UnitFrame.castBar:HookScript("OnHide", function(castBarSelf, ...)
			if
				TargetedSpellsSaved.Settings.Self.Enabled == false
				and TargetedSpellsSaved.Settings.Party.Enabled == false
			then
				return
			end

			if self:CleanUpUnit(unit, event) then
				self:RepositionFrames()
			end
		end)

		pprint("cast bar hooked for", unit)
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
	elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
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
		local unit, spellId = ...

		-- cast vanished during the delay
		if event == Private.Enum.Events.DELAYED_UNIT_SPELLCAST_START and UnitCastingInfo(unit) == nil then
			return
		elseif event == Private.Enum.Events.DELAYED_UNIT_SPELLCAST_CHANNEL_START and UnitChannelInfo(unit) == nil then
			return
		end

		local hasValidTarget = false
		if TargetedSpellsSaved.Settings.Self.Enabled then
			hasValidTarget = UnitIsUnit(unit .. "target", "player")
		elseif TargetedSpellsSaved.Settings.Party.Enabled then
			hasValidTarget = UnitInParty(unit .. "target")
			-- todo: account for ignoring player in party (setting NYI)
		end

		if not hasValidTarget then
			pprint(event, unit, "target is irrelevant")
			return
		end

		local castMetaInformation = self.unitToCastMetaInformation[unit]

		if castMetaInformation == nil then
			return
		end

		pprint(event, unit, "matched info")

		local frames = self:AcquireFrames(unit)

		for _, frame in ipairs(frames) do
			self.unitToCastMetaInformation[unit].frames = frames
			frame:SetSpellTexture(C_Spell.GetSpellTexture(spellId))
			frame:SetStartTime(castMetaInformation.startTime)
			frame:SetCastTime(castMetaInformation.castTime)
			frame:RefreshSpellCooldownInfo()
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
			self:SetupListenerFrame()
			print("TargetedSpellsDriver:OnSettingsChanged: reattached listeners")
		end
	elseif key == Private.Settings.Keys.Self.LoadConditionContentType then
	elseif key == Private.Settings.Keys.Self.LoadConditionRole then
	elseif key == Private.Settings.Keys.Party.LoadConditionContentType then
	elseif key == Private.Settings.Keys.Party.LoadConditionRole then
	end
end

table.insert(Private.LoginFnQueue, GenerateClosure(TargetedSpellsDriver.Init, TargetedSpellsDriver))
