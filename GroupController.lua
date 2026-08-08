---@type string, TargetedSpells
local _, Private = ...

-- ── Group display controller ─────────────────────────────────────────────────
-- One controller per group id. Owns everything per-group: the 1x1 container its
-- frames anchor to, the frame pool it draws from, its currently active frames, and the
-- layout that arranges them. It is the *sole* holder of frame references — the Driver
-- classifies casts and routes them here by group id, but never touches a frame itself.
--
-- Per-unit work (release, interrupt marking, interruptibility) scans this controller's
-- own frame list comparing frame:GetUnit(). That list is one group's worth — a handful
-- at most — and the Driver's unit→groups routing index has already narrowed us to the
-- controllers that actually hold something for that unit, so a scan beats carrying a
-- per-unit sub-table per group (one extra table per unit *per group*, churned on every
-- cast). The flat list is needed for Relayout regardless.
--
-- The group table is held by reference so Direction/Grow/Position/Elements reads never
-- go stale (a v4 import mutates the group tables in place rather than replacing them).

---@class TargetedSpellsGroupController
local GroupController = {}
GroupController.__index = GroupController
Private.GroupController = GroupController

-- Pool + core element are a pure function of the group's Template. Derived once at
-- New (and again at Reconfigure, since the Designer can flip a group's template).
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
	-- an unknown template would strand frames in no pool at all; Bar is the historical
	-- fallback the if/else this replaced happened to give
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

-- Releases this group's frames for `unit`, honouring the per-frame hide delay: an
-- interrupted frame lingers (CanBeHidden false) and is reported back as `remaining` so
-- the Driver keeps its routing entry for the unit alive.
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

-- Drops every frame this controller holds, ignoring the hide delay. Used where the
-- display is being torn down or rebuilt wholesale (group edit, profile import,
-- nameplates turned off) rather than a cast ending, so lingering interrupt frames
-- have nothing left to linger on.
function GroupController:ReleaseAll()
	local frames = self.frames

	for index = #frames, 1, -1 do
		self.pool:Release(frames[index])
		frames[index] = nil
	end
end

-- Recolours this group's frames for `unit` after an interruptibility change. Bar
-- frames carry the colour/shield treatment; icon frames have no equivalent.
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

-- Refreshes the raid target marker on every frame this controller holds (the event is
-- global, not per-unit — any marker may have moved).
function GroupController:UpdateTargetMarkers()
	local frames = self.frames

	for index = 1, #frames do
		local frame = frames[index]

		if frame.SetTargetMarker then
			frame:SetTargetMarker()
		end
	end
end

-- Marks this group's frames for `unit` as interrupted, if the group opted in. Owns the
-- IndicateInterrupts read: whether a group indicates interrupts is group policy, and
-- the Driver has no business reaching through a frame to learn it.
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

-- Sorts and re-anchors this group's frames under its own container. Self-contained:
-- AdjustLayout chains the frames off the container, so relayouting one group never
-- touches another (the scoping guarantee the Driver's router relies on).
function GroupController:Relayout()
	if #self.frames == 0 then
		return
	end

	local group = self.group
	-- NOT the core element's box: the icon+duration frame is wider than its Icon core. A wrong
	-- value here is invisible in Vertical mode (AdjustLayout still centres each frame on the
	-- spine) and only misspaces a Horizontal group, so it goes through the named helper.
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

-- Re-points at the (possibly re-templated) group and re-derives pool + core element.
-- The Designer can flip a group Icon<->Bar at runtime; callers MUST release this
-- controller's frames first (RefreshGroup does) so no live frame is stranded in the
-- wrong pool.
---@param group TargetedSpellsGroup
function GroupController:Reconfigure(group)
	self.group = group
	DeriveFromTemplate(self, group)
end

-- Tears down a controller whose group no longer exists (a delete or an import that
-- drops it). Frames are already gone — the Driver releases them before pruning — so
-- this only has to take the container off screen; WoW has no way to destroy a frame,
-- so it is hidden and dropped along with the controller.
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
