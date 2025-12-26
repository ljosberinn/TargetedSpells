-- ---@type string, TargetedSpells
-- local _, Private = ...

-- local pool = CreateFramePool("Frame", UIParent)

-- local listenerFrame = CreateFrame("Frame")
-- listenerFrame:Hide()
-- listenerFrame:RegisterEvent("LOADING_SCREEN_DISABLED")

-- function listenerFrame:RegisterUnitEvents()
-- 	self:RegisterUnitEvent("UNIT_SPELLCAST_START")
-- 	self:RegisterUnitEvent("UNIT_SPELLCAST_STOP")
-- 	self:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START")
-- 	self:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_START")
-- 	self:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_STOP")
-- 	self:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP")
-- 	self:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED")
-- 	self:RegisterUnitEvent("UNIT_SPELLCAST_FAILED")
-- end

-- function listenerFrame:UnregisterUnitEvents()
-- 	self:UnregisterEvent("UNIT_SPELLCAST_START")
-- 	self:UnregisterEvent("UNIT_SPELLCAST_STOP")
-- 	self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_START")
-- 	self:UnregisterEvent("UNIT_SPELLCAST_EMPOWER_START")
-- 	self:UnregisterEvent("UNIT_SPELLCAST_EMPOWER_STOP")
-- 	self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
-- 	self:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED")
-- 	self:UnregisterEvent("UNIT_SPELLCAST_FAILED")
-- end

-- ---@class TargetedSpellInfo
-- ---@field spellId number
-- ---@field startTime number
-- ---@field endTime number
-- ---@field unit string
-- ---@field texture number

-- ---@type table<string, TargetedSpellsFrame>
-- local frames = {}

-- ---@param unit string
-- ---@return TargetedSpellsFrame
-- local function SetupFrameForUnit(unit)
-- 	local frame = pool:Acquire()
-- 	frame.unit = unit
-- 	frame:SetPoint("CENTER", UIParent, "CENTER")

-- 	return frame
-- end

-- table.insert(Private.LoginFnQueue, function()
-- 	-- todo: find a better place for this
-- 	hooksecurefunc(NamePlateDriverFrame, "OnNamePlateAdded", function(_, unit)
-- 		if not TargetedSpellsSaved.Settings.Party.Enabled and not TargetedSpellsSaved.Settings.Self.Enabled then
-- 			return
-- 		end

-- 		local nameplate = C_NamePlate.GetNamePlateForUnit(unit, issecure())

-- 		if nameplate ~= nil and not UnitIsUnit("player", unit) then
-- 			local frame = SetupFrameForUnit(unit)
-- 			frames[unit] = frame
-- 		end
-- 	end)

-- 	hooksecurefunc(NamePlateDriverFrame, "OnNamePlateRemoved", function(_, unit)
-- 		if not TargetedSpellsSaved.Settings.Party.Enabled and not TargetedSpellsSaved.Settings.Self.Enabled then
-- 			return
-- 		end

-- 		local frame = frames[unit]

-- 		if frame ~= nil then
-- 			-- frame:Down()
-- 			pool:Release(frame)
-- 			frames[unit] = nil
-- 			-- RepositionActiveFrames()
-- 		end
-- 	end)
-- end)
