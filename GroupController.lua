---@type string, TargetedSpells
local _, Private = ...

-- ── Group display controller ─────────────────────────────────────────────────
-- One controller per group id. Owns everything per-group: the 1x1 container its
-- frames anchor to, the frame pool it draws from, the list of its currently active
-- frames, and the layout that arranges them. The Driver routes casts to controllers
-- (classify → hand to each matching controller) and keeps only a secondary unit→frames
-- index for release-by-unit; the controller is the primary owner of the frame list.
--
-- The group table is held by reference so Direction/Grow/Position/Elements reads never
-- go stale (a v4 import mutates the group tables in place rather than replacing them).

---@class TargetedSpellsGroupController
local GroupController = {}
GroupController.__index = GroupController
Private.GroupController = GroupController

-- Pool + core element are a pure function of the group's Template. Derived once at
-- New (and again at Reconfigure, since the Designer can flip a group Icon<->Bar).
---@param controller TargetedSpellsGroupController
---@param group TargetedSpellsGroup
local function DeriveFromTemplate(controller, group)
	if group.Template == Private.Enum.Template.Icon then
		controller.pool = Private.Utils.Pools.Icon
		controller.coreElement = Private.Enum.Element.Icon
	else
		controller.pool = Private.Utils.Pools.Bar
		controller.coreElement = Private.Enum.Element.ProgressBar
	end
end

---@param group TargetedSpellsGroup
---@return TargetedSpellsGroupController
function GroupController.New(group)
	local controller = setmetatable({}, GroupController)
	controller.group = group
	---@type (TargetedSpellsIconMixin|TargetedSpellsBarMixin)[]
	controller.frames = {}
	controller.layoutScratch = {}
	-- container stays nil until first needed (GetContainer lazy-creates it)
	DeriveFromTemplate(controller, group)
	return controller
end

-- Lazy-creates the 1x1 container this group's frames anchor to. Named per group id
-- so it can be found by external tooling (matches the old Driver:GetContainer name).
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

-- Acquires a frame for this cast, tags it with the group, styles it, and takes
-- ownership of it in the controller's frame list. Returns the frame so the Driver
-- can also record it in its unit index (self.frames[unit]).
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

-- Drops a frame from this controller's list and returns it to the pool. Removal is
-- by identity (not GetGroup-keyed): a released frame may already be recycled onto a
-- sibling group by the time we iterate, so its group tag is no longer reliable here.
---@param frame TargetedSpellsIconMixin|TargetedSpellsBarMixin
function GroupController:Release(frame)
	local frames = self.frames

	for index = 1, #frames do
		if frames[index] == frame then
			table.remove(frames, index)
			break
		end
	end

	self.pool:Release(frame)
end

-- Sorts and re-anchors this group's frames under its own container. Self-contained:
-- AdjustLayout chains the frames off the container, so relayouting one group never
-- touches another (the scoping guarantee the Driver's router relies on).
function GroupController:Relayout()
	if #self.frames == 0 then
		return
	end

	local group = self.group
	local core = group.Elements[self.coreElement]

	Private.Utils.SortFrames(self.frames, group.SortOrder)
	Private.Utils.AdjustLayout(
		self.frames,
		Private.Utils.CollectLayoutingArguments(
			group.Direction,
			group.Grow,
			core.width,
			core.height,
			group.Gap,
			self.layoutScratch
		),
		self:GetContainer(),
		"CENTER",
		0,
		0,
		false
	)
end

-- Re-points at the (possibly re-templated) group and re-derives pool + core element.
-- The Designer can flip a group Icon<->Bar at runtime; callers MUST release this
-- controller's frames first (RefreshGroup does) so no live frame is stranded in the
-- wrong pool.
---@param group TargetedSpellsGroup
function GroupController:Reconfigure(group)
	self.group = group
	DeriveFromTemplate(self, group)
end
