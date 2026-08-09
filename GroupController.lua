---@type string, TargetedSpells
local _, Private = ...

---@class TargetedSpellsGroupController
local GroupController = {}
GroupController.__index = GroupController
Private.GroupController = GroupController

local TEMPLATE_TRAITS = {
	[Private.Enum.Template.Icon] = {
		pool = Private.Utils.Pools.Icon,
		coreElement = Private.Enum.Element.Icon,
	},
	[Private.Enum.Template.Bar] = {
		pool = Private.Utils.Pools.Bar,
		coreElement = Private.Enum.Element.ProgressBar,
	},
	[Private.Enum.Template.IconDuration] = {
		pool = Private.Utils.Pools.IconDuration,
		coreElement = Private.Enum.Element.Icon,
	},
}

---@param controller TargetedSpellsGroupController
---@param group TargetedSpellsGroup
local function DeriveFromTemplate(controller, group)
	local traits = TEMPLATE_TRAITS[group.Template] or TEMPLATE_TRAITS[Private.Enum.Template.Bar]

	controller.pool = traits.pool
	controller.coreElement = traits.coreElement
end

---@param group TargetedSpellsGroup
---@return TargetedSpellsGroupController
function GroupController.New(group)
	local controller = setmetatable({}, GroupController)
	controller.group = group
	---@type (TargetedSpellsIconMixin|TargetedSpellsBarMixin)[]
	controller.frames = {}
	controller.layoutScratch = {}
	DeriveFromTemplate(controller, group)
	return controller
end

---@return Frame
function GroupController:GetContainer()
	if self.container == nil then
		local frame = CreateFrame("Frame", "TargetedSpellsGroupContainer" .. self.group.Id, UIParent)
		frame:SetSize(1, 1)
		self.container = frame
	end

	return self.container
end

do
	local ANCHOR_SIGN = {
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

	local GROW_TARGET = {
		[Private.Enum.Direction.Horizontal] = {
			[Private.Enum.Grow.Start] = { x = -1, y = 0 },
			[Private.Enum.Grow.End] = { x = 1, y = 0 },
		},
		[Private.Enum.Direction.Vertical] = {
			[Private.Enum.Grow.Start] = { x = 0, y = -1 },
			[Private.Enum.Grow.End] = { x = 0, y = 1 },
		},
	}

	-- the edit-mode frame anchors via its own position.point, but the container always
	-- anchors via CENTER, so the offset compensates for the difference in origins
	function GroupController:Position()
		local group = self.group
		local container = self:GetContainer()

		local offsetX = 0
		local offsetY = 0

		local editModeFrame = Private.Utils.GetEditModeFrame(group.Id)

		if editModeFrame ~= nil then
			local width, height = editModeFrame:GetSize()

			local anchor = ANCHOR_SIGN[group.Position.point]
			local target = GROW_TARGET[group.Direction][group.Grow]

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
end

---@param info SpellCastInfo
---@param onCooldownClosure fun(info: SpellCastInfo)
---@return TargetedSpellsIconMixin|TargetedSpellsBarMixin
function GroupController:Acquire(info, onCooldownClosure)
	local frame = self.pool:Acquire()

	frame:SetGroup(self.group)
	frame:PostCreate(info, onCooldownClosure)

	table.insert(self.frames, frame)

	return frame
end

---@param unit string
---@param id number|string|nil the cast id to match, or nil for "any cast of this unit"
---@return boolean released whether anything was actually returned to the pool
---@return boolean remaining whether any frame for this unit is still held
function GroupController:ReleaseForUnit(unit, id)
	local frames = self.frames
	local released = false
	local remaining = false

	for index = #frames, 1, -1 do
		local frame = frames[index]

		if frame:GetUnit() == unit then
			if frame:CanBeHidden(id) then
				table.remove(frames, index)
				self.pool:Release(frame)
				released = true
			else
				remaining = true
			end
		end
	end

	return released, remaining
end

function GroupController:ReleaseAll()
	local frames = self.frames

	for index = #frames, 1, -1 do
		self.pool:Release(frames[index])
		frames[index] = nil
	end
end

---@param unit string
---@param isInterruptible boolean
function GroupController:SetInterruptibleForUnit(unit, isInterruptible)
	local frames = self.frames

	for index = 1, #frames do
		local frame = frames[index]

		if frame:GetUnit() == unit and frame.AdjustInterruptibleColor then
			frame:AdjustInterruptibleColor(isInterruptible)
			frame:AdjustInterruptShield(isInterruptible)
		end
	end
end

function GroupController:UpdateTargetMarkers()
	local frames = self.frames

	for index = 1, #frames do
		local frame = frames[index]

		if frame.SetTargetMarker then
			frame:SetTargetMarker()
		end
	end
end

---@param unit string
---@param interruptName string?
---@param interruptColor colorRGB?
---@return boolean indicated whether any frame was marked (the Driver only schedules the
--- delayed cleanup when something is actually lingering)
function GroupController:MarkInterruptedForUnit(unit, interruptName, interruptColor)
	if not self.group.IndicateInterrupts then
		return false
	end

	local frames = self.frames
	local indicated = false

	for index = 1, #frames do
		local frame = frames[index]

		if frame:GetUnit() == unit then
			frame:SetInterrupted(interruptName, interruptColor)
			indicated = true
		end
	end

	return indicated
end

function GroupController:Relayout()
	if #self.frames == 0 then
		return
	end

	local group = self.group
	local width, height = Private.Utils.ComputeGroupFootprint(group.Template, group.Elements)

	Private.Utils.SortFrames(self.frames, group.SortOrder)
	Private.Utils.AdjustLayout(
		self.frames,
		Private.Utils.CollectLayoutingArguments(
			group.Direction,
			group.Grow,
			width,
			height,
			group.Gap,
			self.layoutScratch
		),
		self:GetContainer(),
		"CENTER",
		0,
		0
	)
end

---@param group TargetedSpellsGroup
function GroupController:Reconfigure(group)
	self.group = group
	DeriveFromTemplate(self, group)
end

function GroupController:Discard()
	if self.container ~= nil then
		self.container:ClearAllPoints()
		self.container:Hide()
	end
end

function GroupController:LoadConditionsApply(role, contentType)
	if not self.group.LoadConditionRole[role] then
		return false
	end

	if not self.group.LoadConditionContentType[contentType] then
		return false
	end

	return true
end
