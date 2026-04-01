---@type string, TargetedSpells
local _, Private = ...

---@class TargetedSpellsBarMixin
TargetedSpellsBarMixin = {}

function TargetedSpellsBarMixin:OnLoad()
	self.Bar:SetStatusBarTexture("")
end

function TargetedSpellsBarMixin:OnSizeChanged() end

function TargetedSpellsBarMixin:OnUpdate() end

function TargetedSpellsBarMixin:Reset()
	self:SetParent(UIParent)
	self.Bar:ClearAllPoints()
	self.Bar:SetParent(self)
	self:ClearAllPoints()
	self.startTime = nil
	self:Hide()
end

function TargetedSpellsBarMixin:PostCreate(castingUnit) end

function TargetedSpellsBarMixin:GetKind()
	return self.kind
end

function TargetedSpellsBarMixin:SetStartTime(startTime)
	self.startTime = startTime or GetTime()
end

function TargetedSpellsBarMixin:ClearStartTime()
	self.startTime = nil
end

function TargetedSpellsBarMixin:GetStartTime()
	return self.startTime
end

function TargetedSpellsBarMixin:ShouldBeShown()
	return self.startTime ~= nil
end
