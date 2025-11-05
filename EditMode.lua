---@type string, TargetedSpells
local addonName, Private = ...
local LEM = LibStub("LibEditMode")

---@class TargetedSpellsEditModeParentFrameMixin
local TargetedSpellsEditModeParentFrameMixin = {}

function TargetedSpellsEditModeParentFrameMixin:Init(displayName, frameKind)
	self.frameKind = frameKind
	self.demoPlaying = false
	self.framePool = CreateFramePool("Frame", UIParent, "TargetedSpellsFrameTemplate")
	self.frames = {}
	self.demoTimers = {
		tickers = {},
		timers = {},
	}
	self.editModeFrame = CreateFrame("Frame", displayName, UIParent)
	self.editModeFrame:SetClampedToScreen(true)

	Private.EventRegistry:RegisterCallback(Private.Events.SETTING_CHANGED, self.OnSettingsChanged, self)

	LEM:RegisterCallback("enter", GenerateClosure(self.StartDemo, self))
	LEM:RegisterCallback("exit", GenerateClosure(self.EndDemo, self))

	self:AppendSettings()
end

function TargetedSpellsEditModeParentFrameMixin:CreateSetting(key)
	if key == Private.Settings.Keys.Self.Enabled or key == Private.Settings.Keys.Party.Enabled then
		local isSelf = key == Private.Settings.Keys.Self.Enabled
		local tableRef = isSelf and TargetedSpellsSaved.Settings.Self or TargetedSpellsSaved.Settings.Party

		---@type LibEditModeCheckbox
		return {
			name = "Enabled",
			kind = Enum.EditModeSettingDisplayType.Checkbox,
			default = isSelf and Private.Settings.GetSelfDefaultSettings().Enabled
				or Private.Settings.GetPartyDefaultSettings().Enabled,
			get =
				---@param layoutName string
				function(layoutName)
					return tableRef.Enabled
				end,
			---@param layoutName string
			---@param value boolean
			set = function(layoutName, value)
				local hasChanges = false

				if value ~= tableRef.Enabled then
					tableRef.Enabled = value
					hasChanges = true
				end

				if hasChanges then
					Private.EventRegistry:TriggerEvent(Private.Events.SETTING_CHANGED, key, value)
				end
			end,
		}
	end

	if
		key == Private.Settings.Keys.Self.LoadConditionContentType
		or key == Private.Settings.Keys.Party.LoadConditionContentType
	then
		local isSelf = key == Private.Settings.Keys.Self.LoadConditionContentType
		local tableRef = isSelf and TargetedSpellsSaved.Settings.Self.LoadConditionContentType
			or TargetedSpellsSaved.Settings.Party.LoadConditionContentType

		---@type LibEditModeDropdown
		return {
			name = "Load in Content",
			kind = Enum.EditModeSettingDisplayType.Dropdown,
			default = isSelf and Private.Settings.GetSelfDefaultSettings().LoadConditionContentType
				or Private.Settings.GetPartyDefaultSettings().LoadConditionContentType,
			generator = function(owner, rootDescription, data)
				for label, id in pairs(Private.Enum.ContentType) do
					local function IsEnabled()
						return tableRef[id]
					end

					local function Toggle()
						tableRef[id] = not tableRef[id]

						Private.EventRegistry:TriggerEvent(Private.Events.SETTING_CHANGED, key, tableRef)
					end

					rootDescription:CreateCheckbox(label, IsEnabled, Toggle, {
						value = label,
						isRadio = false,
					})
				end
			end,
			-- technically is a reset only
			set =
				---@param layoutName string
				---@param values table<string, boolean>
				function(layoutName, values)
					local hasChanges = false

					for id, bool in pairs(values) do
						if tableRef[id] ~= bool then
							tableRef[id] = bool
							hasChanges = true
						end
					end

					if hasChanges then
						Private.EventRegistry:TriggerEvent(Private.Events.SETTING_CHANGED, key, tableRef)
					end
				end,
		}
	end

	if key == Private.Settings.Keys.Self.LoadConditionRole or key == Private.Settings.Keys.Party.LoadConditionRole then
		local isSelf = key == Private.Settings.Keys.Self.LoadConditionRole
		local tableRef = isSelf and TargetedSpellsSaved.Settings.Self.LoadConditionRole
			or TargetedSpellsSaved.Settings.Party.LoadConditionRole

		---@type LibEditModeDropdown
		return {
			name = "Load on Role",
			kind = Enum.EditModeSettingDisplayType.Dropdown,
			default = Private.Settings.GetSelfDefaultSettings().LoadConditionRole,
			generator = function(owner, rootDescription, data)
				for label, id in pairs(Private.Enum.Role) do
					local function IsEnabled()
						return tableRef[id]
					end

					local function Toggle()
						tableRef[id] = not tableRef[id]

						Private.EventRegistry:TriggerEvent(Private.Events.SETTING_CHANGED, key, tableRef)
					end

					rootDescription:CreateCheckbox(label, IsEnabled, Toggle, {
						value = label,
						isRadio = false,
					})
				end
			end,
			-- technically is a reset only
			set = function(layoutName, values)
				local hasChanges = false
				for id, bool in pairs(values) do
					if tableRef[id] ~= bool then
						tableRef[id] = bool
						hasChanges = true
					end
				end

				if hasChanges then
					Private.EventRegistry:TriggerEvent(Private.Events.SETTING_CHANGED, key, tableRef)
				end
			end,
		}
	end

	if key == Private.Settings.Keys.Self.Width or key == Private.Settings.Keys.Party.Width then
		local isSelf = key == Private.Settings.Keys.Self.Width
		local tableRef = isSelf and TargetedSpellsSaved.Settings.Self or TargetedSpellsSaved.Settings.Party

		local sliderSettings = Private.Settings.GetSliderSettingsForOption(key)

		---@type LibEditModeSlider
		return {
			name = "Width",
			kind = Enum.EditModeSettingDisplayType.Slider,
			default = isSelf and Private.Settings.GetSelfDefaultSettings().Width
				or Private.Settings.GetPartyDefaultSettings().Width,
			get = function(layoutName)
				return tableRef.Width
			end,
			set = function(layoutName, value)
				tableRef.Width = value
				Private.EventRegistry:TriggerEvent(Private.Events.SETTING_CHANGED, key, value)
			end,
			minValue = sliderSettings.min,
			maxValue = sliderSettings.max,
			valueStep = sliderSettings.step,
		}
	end

	if key == Private.Settings.Keys.Self.Height or key == Private.Settings.Keys.Party.Height then
		local isSelf = key == Private.Settings.Keys.Self.Height
		local tableRef = isSelf and TargetedSpellsSaved.Settings.Self or TargetedSpellsSaved.Settings.Party

		local sliderSettings = Private.Settings.GetSliderSettingsForOption(key)

		---@type LibEditModeSlider
		return {
			name = "Height",
			kind = Enum.EditModeSettingDisplayType.Slider,
			default = isSelf and Private.Settings.GetSelfDefaultSettings().Height
				or Private.Settings.GetPartyDefaultSettings().Height,
			get = function(layoutName)
				return tableRef.Height
			end,
			set = function(layoutName, value)
				tableRef.Height = value
				Private.EventRegistry:TriggerEvent(Private.Events.SETTING_CHANGED, key, value)
			end,
			minValue = sliderSettings.min,
			maxValue = sliderSettings.max,
			valueStep = sliderSettings.step,
		}
	end

	if key == Private.Settings.Keys.Self.Gap or key == Private.Settings.Keys.Party.Gap then
		local isSelf = key == Private.Settings.Keys.Self.Gap
		local tableRef = isSelf and TargetedSpellsSaved.Settings.Self or TargetedSpellsSaved.Settings.Party

		local sliderSettings = Private.Settings.GetSliderSettingsForOption(key)

		---@type LibEditModeSlider
		return {
			name = "Gap",
			kind = Enum.EditModeSettingDisplayType.Slider,
			default = isSelf and Private.Settings.GetSelfDefaultSettings().Gap
				or Private.Settings.GetPartyDefaultSettings().Gap,
			get = function(layoutName)
				return tableRef.Gap
			end,
			set = function(layoutName, value)
				tableRef.Gap = value
				Private.EventRegistry:TriggerEvent(Private.Events.SETTING_CHANGED, key, value)
			end,
			minValue = sliderSettings.min,
			maxValue = sliderSettings.max,
			valueStep = sliderSettings.step,
		}
	end

	if key == Private.Settings.Keys.Self.Direction or key == Private.Settings.Keys.Party.Direction then
		local isSelf = key == Private.Settings.Keys.Self.Direction
		local tableRef = isSelf and TargetedSpellsSaved.Settings.Self or TargetedSpellsSaved.Settings.Party

		---@param layoutName string
		---@param value string
		local function Set(layoutName, value)
			if tableRef.Direction ~= value then
				tableRef.Direction = value
				Private.EventRegistry:TriggerEvent(Private.Events.SETTING_CHANGED, key, value)
			end
		end

		---@type LibEditModeDropdown
		return {
			name = "Direction",
			kind = Enum.EditModeSettingDisplayType.Dropdown,
			default = Private.Settings.GetPartyDefaultSettings().Direction,
			generator = function(owner, rootDescription, data)
				for label, enumValue in pairs(Private.Enum.Direction) do
					local function IsEnabled()
						return tableRef.Direction == enumValue
					end

					local function SetProxy()
						Set(LEM:GetActiveLayoutName(), enumValue)
					end

					rootDescription:CreateCheckbox(label, IsEnabled, SetProxy, {
						value = label,
						isRadio = true,
					})
				end
			end,
			set = Set,
		}
	end

	if key == Private.Settings.Keys.Party.OffsetX or key == Private.Settings.Keys.Party.OffsetY then
		local isX = key == Private.Settings.Keys.Party.OffsetX
		local sliderSettings = Private.Settings.GetSliderSettingsForOption(key)

		---@type LibEditModeSlider
		return {
			name = isX and "Offset X" or "Offset Y",
			kind = Enum.EditModeSettingDisplayType.Slider,
			default = isX and Private.Settings.GetPartyDefaultSettings().OffsetX
				or Private.Settings.GetPartyDefaultSettings().OffsetY,
			get =
				---@param layoutName string
				function(layoutName)
					if isX then
						return TargetedSpellsSaved.Settings.Party.OffsetX
					end

					return TargetedSpellsSaved.Settings.Party.OffsetY
				end,
			set =
				---@param layoutName string
				---@param value number
				function(layoutName, value)
					if isX then
						TargetedSpellsSaved.Settings.Party.OffsetX = value
					else
						TargetedSpellsSaved.Settings.Party.OffsetY = value
					end

					Private.EventRegistry:TriggerEvent(Private.Events.SETTING_CHANGED, key, value)
				end,
			minValue = sliderSettings.min,
			maxValue = sliderSettings.max,
			valueStep = sliderSettings.step,
		}
	end

	if key == Private.Settings.Keys.Party.SourceAnchor or key == Private.Settings.Keys.Party.TargetAnchor then
		local isSource = key == Private.Settings.Keys.Party.SourceAnchor
		local tableKey = isSource and "SourceAnchor" or "TargetAnchor"

		---@param layoutName string
		---@param value string
		local function Set(layoutName, value)
			if TargetedSpellsSaved.Settings.Party[tableKey] ~= value then
				TargetedSpellsSaved.Settings.Party[tableKey] = value
				Private.EventRegistry:TriggerEvent(Private.Events.SETTING_CHANGED, key, value)
			end
		end

		---@type LibEditModeDropdown
		return {
			name = isSource and "Source Anchor" or "Target Anchor",
			kind = Enum.EditModeSettingDisplayType.Dropdown,
			default = isSource and Private.Settings.GetPartyDefaultSettings().SourceAnchor
				or Private.Settings.GetPartyDefaultSettings().TargetAnchor,
			generator = function(owner, rootDescription, data)
				for label, enumValue in pairs(Private.Enum.Anchor) do
					local function IsEnabled()
						return TargetedSpellsSaved.Settings.Party[tableKey] == enumValue
					end

					local function SetProxy()
						Set(LEM:GetActiveLayoutName(), enumValue)
					end

					rootDescription:CreateCheckbox(label, IsEnabled, SetProxy, {
						value = label,
						isRadio = true,
					})
				end
			end,
			set = Set,
		}
	end

	if key == Private.Settings.Keys.Self.SortOrder or key == Private.Settings.Keys.Party.SortOrder then
		local isSelf = key == Private.Settings.Keys.Self.SortOrder
		local tableRef = isSelf and TargetedSpellsSaved.Settings.Self or TargetedSpellsSaved.Settings.Party

		---@param layoutName string
		---@param value string
		local function Set(layoutName, value)
			if tableRef.SortOrder ~= value then
				tableRef.SortOrder = value
				Private.EventRegistry:TriggerEvent(Private.Events.SETTING_CHANGED, key, value)
			end
		end

		---@type LibEditModeDropdown
		return {
			name = "Sort Order",
			kind = Enum.EditModeSettingDisplayType.Dropdown,
			default = Private.Settings.GetPartyDefaultSettings().SortOrder,
			generator = function(owner, rootDescription, data)
				for label, enumValue in pairs(Private.Enum.SortOrder) do
					local function IsEnabled()
						return tableRef.SortOrder == enumValue
					end

					local function SetProxy()
						Set(LEM:GetActiveLayoutName(), enumValue)
					end

					rootDescription:CreateCheckbox(label, IsEnabled, SetProxy, {
						value = label,
						isRadio = true,
					})
				end
			end,
			set = Set,
		}
	end

	if key == Private.Settings.Keys.Self.Grow or key == Private.Settings.Keys.Party.Grow then
		local isSelf = key == Private.Settings.Keys.Self.Grow
		local tableRef = isSelf and TargetedSpellsSaved.Settings.Self or TargetedSpellsSaved.Settings.Party

		---@param layoutName string
		---@param value string
		local function Set(layoutName, value)
			if tableRef.Grow ~= value then
				tableRef.Grow = value
				Private.EventRegistry:TriggerEvent(Private.Events.SETTING_CHANGED, key, value)
			end
		end

		---@type LibEditModeDropdown
		return {
			name = "Grow",
			kind = Enum.EditModeSettingDisplayType.Dropdown,
			default = Private.Settings.GetPartyDefaultSettings().Grow,
			generator = function(owner, rootDescription, data)
				for label, enumValue in pairs(Private.Enum.Grow) do
					local function IsEnabled()
						return tableRef.Grow == enumValue
					end

					local function SetProxy()
						Set(LEM:GetActiveLayoutName(), enumValue)
					end

					rootDescription:CreateCheckbox(label, IsEnabled, SetProxy, {
						value = label,
						isRadio = true,
					})
				end
			end,
			set = Set,
		}
	end

	error(
		string.format(
			"Edit Mode Settings for key '%s' are either not implemented or you're calling this with the wrong key.",
			key or "NO KEY"
		)
	)
end

function TargetedSpellsEditModeParentFrameMixin:SortFrames(frames, sortOrder)
	local isAscending = sortOrder == Private.Enum.SortOrder.Ascending

	table.sort(frames, function(a, b)
		if isAscending then
			return a:GetStartTime() < b:GetStartTime()
		end

		return a:GetStartTime() > b:GetStartTime()
	end)
end

function TargetedSpellsEditModeParentFrameMixin:AppendSettings()
	-- Implement in your derived mixin.
end

function TargetedSpellsEditModeParentFrameMixin:OnSettingsChanged(key, value)
	-- Implement in your derived mixin.
end

function TargetedSpellsEditModeParentFrameMixin:AcquireFrame()
	local frame = self.framePool:Acquire()

	frame:PostCreate("preview", self.frameKind)

	return frame
end

function TargetedSpellsEditModeParentFrameMixin:ReleaseFrame(frame)
	frame:Reset()

	self.framePool:Release(frame)
end

function TargetedSpellsEditModeParentFrameMixin:OnEditModePositionChanged(frame, layoutName, point, x, y)
	-- todo: restore position from layout
end

function TargetedSpellsEditModeParentFrameMixin:RepositionPreviewFrames()
	-- Implement in your derived mixin.
end

function TargetedSpellsEditModeParentFrameMixin:LoopFrame(frame, index)
	frame:SetSpellTexture()
	frame:SetStartTime()
	local castTime = 4 + index / 2
	frame:SetCastTime(castTime)
	frame:RefreshSpellCooldownInfo()
	frame:RefreshSpellTexture()
	frame:Show()
	self:RepositionPreviewFrames()

	table.insert(
		self.demoTimers.timers,
		C_Timer.NewTimer(castTime, function()
			frame:ClearStartTime()
			frame:Hide()
			self:RepositionPreviewFrames()
		end)
	)
end

function TargetedSpellsEditModeParentFrameMixin:StartDemo()
	-- Implement in your derived mixin.
end

function TargetedSpellsEditModeParentFrameMixin:ReleaseAllFrames()
	-- Implement in your derived mixin.
end

function TargetedSpellsEditModeParentFrameMixin:EndDemo(forceDisable)
	if forceDisable == nil then
		forceDisable = false
	end

	if not self.demoPlaying and not forceDisable then
		return
	end

	for _, ticker in pairs(self.demoTimers.tickers) do
		ticker:Cancel()
	end

	for _, timer in pairs(self.demoTimers.timers) do
		timer:Cancel()
	end

	table.wipe(self.demoTimers.tickers)
	table.wipe(self.demoTimers.timers)

	self:ReleaseAllFrames()

	self.demoPlaying = false
end

function TargetedSpellsEditModeParentFrameMixin:CalculateCoordinate(
	index,
	dimension,
	gap,
	parentDimension,
	total,
	offset,
	grow
)
	if grow == Private.Enum.Grow.Start then
		return (index - 1) * (dimension + gap) - parentDimension / 2 + offset
	elseif grow == Private.Enum.Grow.Center then
		return (index - 1) * (dimension + gap) - total / 2 + offset
	elseif grow == Private.Enum.Grow.End then
		return parentDimension / 2 - index * (dimension + gap) + offset
	end

	return 0
end

---@class TargetedSpellsSelfEditModeFrame
local SelfEditModeMixin = CreateFromMixins(TargetedSpellsEditModeParentFrameMixin)

function SelfEditModeMixin:Init(displayName, frameKind)
	TargetedSpellsEditModeParentFrameMixin.Init(self, displayName, frameKind)
	self.maxFrameCount = 5

	self.editModeFrame:SetPoint("CENTER", UIParent)
	self:ResizeEditModeFrame()
end

function SelfEditModeMixin:ResizeEditModeFrame()
	local width, gap, height, direction =
		TargetedSpellsSaved.Settings.Self.Width,
		TargetedSpellsSaved.Settings.Self.Gap,
		TargetedSpellsSaved.Settings.Self.Height,
		TargetedSpellsSaved.Settings.Self.Direction

	if direction == Private.Enum.Direction.Horizontal then
		local totalWidth = (self.maxFrameCount * width) + (self.maxFrameCount - 1) * gap
		self.editModeFrame:SetSize(totalWidth, height)
	else
		local totalHeight = (self.maxFrameCount * height) + (self.maxFrameCount - 1) * gap
		self.editModeFrame:SetSize(width, totalHeight)
	end
end

function SelfEditModeMixin:ReleaseAllFrames()
	for index = 1, self.maxFrameCount do
		local frame = self.frames[index]

		if frame then
			self:ReleaseFrame(frame)
			self.frames[index] = nil
		end
	end
end

function SelfEditModeMixin:AppendSettings()
	LEM:AddFrame(
		self.editModeFrame,
		GenerateClosure(self.OnEditModePositionChanged, self),
		{ point = "CENTER", x = 0, y = 0 }
	)

	-- todo: layouting
	LEM:AddFrameSettings(self.editModeFrame, {
		self:CreateSetting(Private.Settings.Keys.Self.Enabled),
		self:CreateSetting(Private.Settings.Keys.Self.LoadConditionContentType),
		self:CreateSetting(Private.Settings.Keys.Self.LoadConditionRole),
		self:CreateSetting(Private.Settings.Keys.Self.Width),
		self:CreateSetting(Private.Settings.Keys.Self.Height),
		self:CreateSetting(Private.Settings.Keys.Self.Gap),
		self:CreateSetting(Private.Settings.Keys.Self.Direction),
		self:CreateSetting(Private.Settings.Keys.Self.SortOrder),
		self:CreateSetting(Private.Settings.Keys.Self.Grow),
	})
end

function SelfEditModeMixin:OnEditModePositionChanged(frame, layoutName, point, x, y)
	-- todo: restore position from layout
end

function SelfEditModeMixin:RepositionPreviewFrames()
	if not self.demoPlaying then
		return
	end

	-- await for the setup to be finished
	if self.buildingFrames ~= nil then
		return
	end

	local width, height, gap, direction, sortOrder, grow =
		TargetedSpellsSaved.Settings.Self.Width,
		TargetedSpellsSaved.Settings.Self.Height,
		TargetedSpellsSaved.Settings.Self.Gap,
		TargetedSpellsSaved.Settings.Self.Direction,
		TargetedSpellsSaved.Settings.Self.SortOrder,
		TargetedSpellsSaved.Settings.Self.Grow

	---@type TargetedSpellsMixin[]
	local activeFrames = {}

	for i = 1, self.maxFrameCount do
		local frame = self.frames[i]
		if frame and frame:ShouldBeShown() then
			table.insert(activeFrames, frame)
		end
	end

	local activeFrameCount = #activeFrames

	if activeFrameCount == 0 then
		return
	end

	self:SortFrames(activeFrames, sortOrder)

	local isHorizontal = direction == Private.Enum.Direction.Horizontal

	local point = isHorizontal and "LEFT" or "BOTTOM"
	local total = (activeFrameCount * (isHorizontal and width or height)) + (activeFrameCount - 1) * gap
	local parentDimension = isHorizontal and self.editModeFrame:GetWidth() or self.editModeFrame:GetHeight()

	for i, frame in ipairs(activeFrames) do
		frame:Reposition(
			point,
			self.editModeFrame,
			"CENTER",
			isHorizontal and self:CalculateCoordinate(i, width, gap, parentDimension, total, 0, grow) or 0,
			isHorizontal and 0 or self:CalculateCoordinate(i, width, gap, parentDimension, total, 0, grow)
		)
	end
end

function SelfEditModeMixin:StartDemo()
	if self.demoPlaying or not TargetedSpellsSaved.Settings.Self.Enabled then
		return
	end

	self.demoPlaying = true
	self.buildingFrames = true

	for index = 1, self.maxFrameCount do
		self.frames[index] = self.frames[index] or self:AcquireFrame()

		local frame = self.frames[index]

		if frame then
			table.insert(
				self.demoTimers.tickers,
				C_Timer.NewTicker(5 + index, GenerateClosure(self.LoopFrame, self, frame, index))
			)

			self:LoopFrame(frame, index)
		end
	end

	self.buildingFrames = nil

	self:RepositionPreviewFrames()
end

function SelfEditModeMixin:OnSettingsChanged(key, value)
	if
		key == Private.Settings.Keys.Self.Gap
		or key == Private.Settings.Keys.Self.Direction
		or key == Private.Settings.Keys.Self.Width
		or key == Private.Settings.Keys.Self.Height
		or key == Private.Settings.Keys.Self.SortOrder
		or key == Private.Settings.Keys.Self.Grow
	then
		if
			key == Private.Settings.Keys.Self.Width
			or key == Private.Settings.Keys.Self.Height
			or key == Private.Settings.Keys.Self.Gap
			or key == Private.Settings.Keys.Self.Direction
		then
			self:ResizeEditModeFrame()
		end

		self:RepositionPreviewFrames()
	elseif key == Private.Settings.Keys.Self.Enabled then
		if value then
			self:StartDemo()
		else
			local forceDisable = not TargetedSpellsSaved.Settings.Self.Enabled and self.demoPlaying
			self:EndDemo(forceDisable)
		end
	end
end

table.insert(
	Private.LoginFnQueue,
	GenerateClosure(SelfEditModeMixin.Init, SelfEditModeMixin, "Targeted Spells Self", Private.Enum.FrameKind.Self)
)

---@class TargetedSpellsPartyEditModeFrame
local PartyEditModeMixin = CreateFromMixins(TargetedSpellsEditModeParentFrameMixin)

function PartyEditModeMixin:Init(displayName, frameKind)
	TargetedSpellsEditModeParentFrameMixin.Init(self, displayName, frameKind)
	self.maxUnitCount = 5
	self.amountOfPreviewFramesPerUnit = 3
	self.useRaidStylePartyFrames = self.useRaidStylePartyFrames or false
	self:RepositionEditModeFrame()

	-- todo: show something in self.editModeFrame as it otherwise has no preview
end

function PartyEditModeMixin:AppendSettings()
	LEM:AddFrame(
		self.editModeFrame,
		GenerateClosure(self.OnEditModePositionChanged, self),
		{ point = "CENTER", x = 0, y = 0 }
	)

	-- todo: layouting
	LEM:AddFrameSettings(self.editModeFrame, {
		self:CreateSetting(Private.Settings.Keys.Party.Enabled),
		self:CreateSetting(Private.Settings.Keys.Party.LoadConditionContentType),
		self:CreateSetting(Private.Settings.Keys.Party.LoadConditionRole),
		self:CreateSetting(Private.Settings.Keys.Party.Width),
		self:CreateSetting(Private.Settings.Keys.Party.Height),
		self:CreateSetting(Private.Settings.Keys.Party.Gap),
		self:CreateSetting(Private.Settings.Keys.Party.Direction),
		self:CreateSetting(Private.Settings.Keys.Party.OffsetX),
		self:CreateSetting(Private.Settings.Keys.Party.OffsetY),
		self:CreateSetting(Private.Settings.Keys.Party.SourceAnchor),
		self:CreateSetting(Private.Settings.Keys.Party.TargetAnchor),
		self:CreateSetting(Private.Settings.Keys.Party.Grow),
		self:CreateSetting(Private.Settings.Keys.Party.SortOrder),
	})
end

function PartyEditModeMixin:RepositionEditModeFrame()
	local parent = self.useRaidStylePartyFrames and CompactPartyFrame or PartyFrame
	local width = self.useRaidStylePartyFrames and 250 or 125
	local height = self.useRaidStylePartyFrames and 24 or 16

	self.editModeFrame:SetSize(width, height)
	self.editModeFrame:ClearAllPoints()
	self.editModeFrame:SetPoint("CENTER", parent, "TOP", 0, 16)
end

function PartyEditModeMixin:OnSettingsChanged(key, value)
	if
		key == Private.Settings.Keys.Party.Gap
		or key == Private.Settings.Keys.Party.Direction
		or key == Private.Settings.Keys.Party.Width
		or key == Private.Settings.Keys.Party.Height
		or key == Private.Settings.Keys.Party.OffsetX
		or key == Private.Settings.Keys.Party.OffsetY
		or key == Private.Settings.Keys.Party.SourceAnchor
		or key == Private.Settings.Keys.Party.TargetAnchor
		or key == Private.Settings.Keys.Party.SortOrder
		or key == Private.Settings.Keys.Party.Grow
	then
		self:RepositionPreviewFrames()
	elseif key == Private.Settings.Keys.Party.Enabled then
		if value then
			self:StartDemo()
		else
			local forceDisable = not TargetedSpellsSaved.Settings.Party.Enabled and self.demoPlaying
			self:EndDemo(forceDisable)
		end
	end
end

function PartyEditModeMixin:RepositionPreviewFrames()
	if not self.demoPlaying then
		return
	end

	-- await for the setup to be finished
	if self.buildingFrames ~= nil then
		return
	end

	local width, height, gap, direction, offsetX, offsetY, sortOrder, sourceAnchor, targetAnchor, grow =
		TargetedSpellsSaved.Settings.Party.Width,
		TargetedSpellsSaved.Settings.Party.Height,
		TargetedSpellsSaved.Settings.Party.Gap,
		TargetedSpellsSaved.Settings.Party.Direction,
		TargetedSpellsSaved.Settings.Party.OffsetX,
		TargetedSpellsSaved.Settings.Party.OffsetY,
		TargetedSpellsSaved.Settings.Party.SortOrder,
		TargetedSpellsSaved.Settings.Party.SourceAnchor,
		TargetedSpellsSaved.Settings.Party.TargetAnchor,
		TargetedSpellsSaved.Settings.Party.Grow

	local isHorizontal = direction == Private.Enum.Direction.Horizontal

	for i = 1, self.maxUnitCount do
		if i == self.maxUnitCount and not self.useRaidStylePartyFrames then
			break
		end

		---@type TargetedSpellsMixin[]
		local activeFrames = {}

		for j = 1, self.amountOfPreviewFramesPerUnit do
			local frame = self.frames[i][j]

			if frame and frame:ShouldBeShown() then
				table.insert(activeFrames, frame)
			end
		end

		local activeFrameCount = #activeFrames

		if activeFrameCount > 0 then
			self:SortFrames(activeFrames, sortOrder)

			local parentFrame = nil

			if self.useRaidStylePartyFrames then
				parentFrame = CompactPartyFrame.memberUnitFrames[i]
			else
				for memberFrame in PartyFrame.PartyMemberFramePool:EnumerateActive() do
					if memberFrame.layoutIndex == i then
						parentFrame = memberFrame
						break
					end
				end
			end

			-- cannot happen
			if parentFrame == nil then
				error("couldn't establish a parent frame")
			end

			local total = (activeFrameCount * (isHorizontal and width or height)) + (activeFrameCount - 1) * gap
			local parentDimension = isHorizontal and parentFrame:GetWidth() or parentFrame:GetHeight()

			for j, frame in ipairs(activeFrames) do
				frame:Reposition(
					sourceAnchor,
					parentFrame,
					targetAnchor,
					isHorizontal and self:CalculateCoordinate(j, width, gap, parentDimension, total, offsetX, grow)
						or offsetX,
					isHorizontal and offsetY
						or self:CalculateCoordinate(j, width, gap, parentDimension, total, offsetX, grow)
				)
			end
		end
	end
end

function PartyEditModeMixin:StartDemo()
	if self.demoPlaying or not TargetedSpellsSaved.Settings.Party.Enabled then
		return
	end

	self.demoPlaying = true
	self.buildingFrames = true

	for unit = 1, self.maxUnitCount do
		self.frames[unit] = self.frames[unit] or {}

		if unit == self.maxUnitCount and not self.useRaidStylePartyFrames then
			break
		end

		for index = 1, self.amountOfPreviewFramesPerUnit do
			self.frames[unit][index] = self.frames[unit][index] or self:AcquireFrame()
			local frame = self.frames[unit][index]

			if frame then
				table.insert(
					self.demoTimers.tickers,
					C_Timer.NewTicker(5 + index + unit, GenerateClosure(self.LoopFrame, self, frame, index + unit))
				)

				self:LoopFrame(frame, index + unit)
			end
		end
	end

	self.buildingFrames = nil

	self:RepositionPreviewFrames()
end

function PartyEditModeMixin:ReleaseAllFrames()
	for unit = 1, self.maxUnitCount do
		for index = 1, self.amountOfPreviewFramesPerUnit do
			local frame = self.frames[unit][index]

			if frame then
				self:ReleaseFrame(frame)
				self.frames[unit][index] = nil
			end
		end
	end
end

-- when this executes, layouts aren't loaded yet
hooksecurefunc(EditModeManagerFrame, "UpdateLayoutInfo", function(self)
	PartyEditModeMixin.useRaidStylePartyFrames = EditModeManagerFrame:UseRaidStylePartyFrames()
	PartyEditModeMixin:RepositionEditModeFrame()
end)

-- dirtying settings while edit mode is opened doesn't fire any events
hooksecurefunc(EditModeSystemSettingsDialog, "OnSettingValueChanged", function(self, setting, checked)
	if setting ~= Enum.EditModeUnitFrameSetting.UseRaidStylePartyFrames then
		return
	end

	local useRaidStylePartyFrames = checked == 1

	if useRaidStylePartyFrames == PartyEditModeMixin.useRaidStylePartyFrames then
		return
	end

	PartyEditModeMixin.useRaidStylePartyFrames = useRaidStylePartyFrames
	PartyEditModeMixin:RepositionEditModeFrame()

	if TargetedSpellsSaved.Settings.Party.Enabled then
		PartyEditModeMixin:EndDemo()
		PartyEditModeMixin:StartDemo()
	end
end)

table.insert(
	Private.LoginFnQueue,
	GenerateClosure(PartyEditModeMixin.Init, PartyEditModeMixin, "Targeted Spells Party", Private.Enum.FrameKind.Party)
)

local function SetupSelfEditMode()
	local function RepositionPreviewFrames() end

	-- todo: layouting

	-- LEM:RegisterCallback("layout", function(layoutName)
	--     if not TagsTrivialTweaks_Settings.LEM then
	--         TagsTrivialTweaks_Settings.LEM = {}
	--     end
	--     if not TagsTrivialTweaks_Settings.LEM[layoutName] then
	--         TagsTrivialTweaks_Settings.LEM[layoutName] = CopyTable(defaultPosition)
	--     end

	--     app.ArtifactAbility:SetScale(TagsTrivialTweaks_Settings.LEM[layoutName].scale or 1)
	--     app.ArtifactAbility:ClearAllPoints()
	--     app.ArtifactAbility:SetPoint(TagsTrivialTweaks_Settings.LEM[layoutName].point, TagsTrivialTweaks_Settings.LEM[layoutName].x, TagsTrivialTweaks_Settings.LEM[layoutName].y)
	--     app.ArtifactAbility.Texture:SetAtlas(app.ButtonSkin[TagsTrivialTweaks_Settings.LEM[layoutName].style] or "stormwhite-extrabutton", true)
	-- end)
end
