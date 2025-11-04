---@type string, TargetedSpells
local addonName, Private = ...
local LEM = LibStub("LibEditMode")

---@param key string
local function CreateSetting(key)
	if key == Private.Settings.Keys.Self.Enabled or key == Private.Settings.Keys.Party.Enabled then
		local isSelf = key == Private.Settings.Keys.Self.Enabled
		local tableRef = isSelf and TargetedSpellsSaved.Settings.Self or TargetedSpellsSaved.Settings.Party

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

---@param frames TargetedSpellsMixin[]
---@param sortOrder SortOrder
local function SortFrames(frames, sortOrder)
	local isAscending = sortOrder == Private.Enum.SortOrder.Ascending

	table.sort(frames, function(a, b)
		if isAscending then
			return a:GetStartTime() < b:GetStartTime()
		end

		return a:GetStartTime() > b:GetStartTime()
	end)
end

local function SetupSelfEditMode()
	local amountOfPreviewFrames = 5
	local EditModeParentFrame = CreateFrame("Frame", "Targeted Spells Self", UIParent)
	EditModeParentFrame:SetClampedToScreen(true)

	do
		local width, gap, height =
			TargetedSpellsSaved.Settings.Self.Width,
			TargetedSpellsSaved.Settings.Self.Gap,
			TargetedSpellsSaved.Settings.Self.Height

		if TargetedSpellsSaved.Settings.Self.Direction == Private.Enum.Direction.Horizontal then
			EditModeParentFrame:SetSize(amountOfPreviewFrames * width + (amountOfPreviewFrames - 1) * gap, height)
		else
			EditModeParentFrame:SetSize(width, amountOfPreviewFrames * height + (amountOfPreviewFrames - 1) * gap)
		end
	end

	-- todo: restore position from layout
	EditModeParentFrame:SetPoint("CENTER", UIParent)

	---@type TargetedSpellsMixin[]
	local previewFrames = {}

	for i = 1, amountOfPreviewFrames do
		local previewFrame = CreateFrame(
			"Frame",
			"EditModeTargetedSpellsSelfPreview" .. i,
			EditModeParentFrame,
			"TargetedSpellsFrameTemplate"
		)

		previewFrame:SetUnit("preview" .. i)
		previewFrame:SetKind(Private.Enum.FrameKind.Self)

		table.insert(previewFrames, previewFrame)

		if not TargetedSpellsSaved.Settings.Self.Enabled then
			previewFrame:Hide()
		end
	end

	local defaultPosition = { point = "CENTER", x = 0, y = 0 }

	local function onPositionChanged(frame, layoutName, point, x, y)
		print(layoutName, point, x, y)

		-- TagsTrivialTweaks_Settings.LEM[layoutName].point = point
		-- TagsTrivialTweaks_Settings.LEM[layoutName].x = x
		-- TagsTrivialTweaks_Settings.LEM[layoutName].y = y
	end

	LEM:AddFrame(EditModeParentFrame, onPositionChanged, defaultPosition)

	local function RepositionPreviewFrames()
		local width, height, gap, direction, sortOrder, grow =
			TargetedSpellsSaved.Settings.Self.Width,
			TargetedSpellsSaved.Settings.Self.Height,
			TargetedSpellsSaved.Settings.Self.Gap,
			TargetedSpellsSaved.Settings.Self.Direction,
			TargetedSpellsSaved.Settings.Self.SortOrder,
			TargetedSpellsSaved.Settings.Self.Grow

		---@type TargetedSpellsMixin[]
		local frames = {}
		for _, frame in pairs(previewFrames) do
			if frame:ShouldBeShown() then
				table.insert(frames, frame)
			end
		end

		SortFrames(frames, sortOrder)

		local activeFrameCount = #frames
		local isHorizontal = direction == Private.Enum.Direction.Horizontal

		if isHorizontal then
			local totalWidth = (activeFrameCount * width) + (activeFrameCount - 1) * gap

			for i, frame in ipairs(frames) do
				local x = (i - 1) * width + (i - 1) * gap - totalWidth / 2
				frame:Reposition("LEFT", EditModeParentFrame, "CENTER", x, 0)
			end
		else
			local totalHeight = (activeFrameCount * height) + (activeFrameCount - 1) * gap

			for i, frame in ipairs(frames) do
				local y = (i - 1) * height + (i - 1) * gap - totalHeight / 2
				frame:Reposition("BOTTOM", EditModeParentFrame, "CENTER", 0, y)
			end
		end
	end

	local playing = false

	---@param forceDisable boolean?
	local function ToggleDemo(forceDisable)
		if forceDisable == nil then
			forceDisable = false
		end

		if not TargetedSpellsSaved.Settings.Self.Enabled and not forceDisable then
			return
		end

		for _, frame in pairs(previewFrames) do
			if playing or forceDisable then
				frame:StopPreviewLoop()
			else
				frame:StartPreviewLoop(RepositionPreviewFrames)
			end
		end

		playing = not playing
	end

	Private.EventRegistry:RegisterCallback(Private.Events.SETTING_CHANGED, function(self, key, value)
		if
			key == Private.Settings.Keys.Self.Gap
			or key == Private.Settings.Keys.Self.Direction
			or key == Private.Settings.Keys.Self.Width
			or key == Private.Settings.Keys.Self.Height
			or key == Private.Settings.Keys.Self.SortOrder
			or key == Private.Settings.Keys.Self.Grow
		then
			if key == Private.Settings.Keys.Self.Width or key == Private.Settings.Keys.Self.Height then
				local isHorizontal = TargetedSpellsSaved.Settings.Self.Direction == Private.Enum.Direction.Horizontal
				local activeFrameCount = #previewFrames
				local gap = TargetedSpellsSaved.Settings.Self.Gap

				if isHorizontal then
					local width = TargetedSpellsSaved.Settings.Self.Width
					local totalWidth = (activeFrameCount * width) + (activeFrameCount - 1) * gap
					self:SetSize(totalWidth, TargetedSpellsSaved.Settings.Self.Height)
				else
					local height = TargetedSpellsSaved.Settings.Self.Height
					local totalHeight = (activeFrameCount * height) + (activeFrameCount - 1) * gap
					self:SetSize(TargetedSpellsSaved.Settings.Self.Width, totalHeight)
				end
			end

			RepositionPreviewFrames()
		elseif key == Private.Settings.Keys.Self.Enabled then
			local forceDisable = not TargetedSpellsSaved.Settings.Self.Enabled and playing
			ToggleDemo(forceDisable)
		end
	end, EditModeParentFrame)

	LEM:RegisterCallback("enter", ToggleDemo)
	LEM:RegisterCallback("exit", ToggleDemo)

	-- todo: layouting
	LEM:AddFrameSettings(EditModeParentFrame, {
		CreateSetting(Private.Settings.Keys.Self.Enabled),
		CreateSetting(Private.Settings.Keys.Self.LoadConditionContentType),
		CreateSetting(Private.Settings.Keys.Self.LoadConditionRole),
		CreateSetting(Private.Settings.Keys.Self.Width),
		CreateSetting(Private.Settings.Keys.Self.Height),
		CreateSetting(Private.Settings.Keys.Self.Gap),
		CreateSetting(Private.Settings.Keys.Self.Direction),
		CreateSetting(Private.Settings.Keys.Self.SortOrder),
		CreateSetting(Private.Settings.Keys.Self.Grow),
	})

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

-- table.insert(Private.LoginFnQueue, SetupSelfEditMode)

---@type TargetedSpellsPartyEditModeFrame
local PartyEditModeParentFrame = CreateFrame("Frame", "Targeted Spells Party", UIParent)
-- todo: show something in this frame as it otherwise has no preview

-- when this executes, layouts aren't loaded yet
hooksecurefunc(EditModeManagerFrame, "UpdateLayoutInfo", function(self)
	PartyEditModeParentFrame.useRaidStylePartyFrames = EditModeManagerFrame:UseRaidStylePartyFrames()
end)

hooksecurefunc(EditModeSystemSettingsDialog, "OnSettingValueChanged", function(self, setting, checked)
	if setting == Enum.EditModeUnitFrameSetting.UseRaidStylePartyFrames then
		local nextUseRaidStylePartyFrames = checked == 1

		if nextUseRaidStylePartyFrames ~= PartyEditModeParentFrame.useRaidStylePartyFrames then
			PartyEditModeParentFrame.useRaidStylePartyFrames = nextUseRaidStylePartyFrames

			PartyEditModeParentFrame:EndDemo()
			PartyEditModeParentFrame:StartDemo()
			PartyEditModeParentFrame:RepositionSelf()
		end
	end
end)

function PartyEditModeParentFrame:OnLoad()
	self.maxUnitCount = 5
	self.amountOfPreviewFramesPerUnit = 3
	self.demoPlaying = false
	self.framePool = CreateFramePool("Frame", UIParent, "TargetedSpellsFrameTemplate")
	self.frames = {}
	self.useRaidStylePartyFrames = self.useRaidStylePartyFrames or false
	self.demoTimers = {
		tickers = {},
		timers = {},
	}

	self:SetClampedToScreen(true)
	self:RepositionSelf()

	Private.EventRegistry:RegisterCallback(Private.Events.SETTING_CHANGED, self.OnSettingsChanged, self)

	LEM:AddFrame(self, GenerateClosure(self.OnEditModePositionChanged, self), { point = "CENTER", x = 0, y = 0 })
	LEM:RegisterCallback("enter", GenerateClosure(self.StartDemo, self))
	LEM:RegisterCallback("exit", GenerateClosure(self.EndDemo, self))

	-- todo: layouting
	LEM:AddFrameSettings(self, {
		CreateSetting(Private.Settings.Keys.Party.Enabled),
		CreateSetting(Private.Settings.Keys.Party.LoadConditionContentType),
		CreateSetting(Private.Settings.Keys.Party.LoadConditionRole),
		CreateSetting(Private.Settings.Keys.Party.Width),
		CreateSetting(Private.Settings.Keys.Party.Height),
		CreateSetting(Private.Settings.Keys.Party.Gap),
		CreateSetting(Private.Settings.Keys.Party.Direction),
		CreateSetting(Private.Settings.Keys.Party.OffsetX),
		CreateSetting(Private.Settings.Keys.Party.OffsetY),
		CreateSetting(Private.Settings.Keys.Party.SourceAnchor),
		CreateSetting(Private.Settings.Keys.Party.TargetAnchor),
		CreateSetting(Private.Settings.Keys.Party.Grow),
		CreateSetting(Private.Settings.Keys.Party.SortOrder),
	})
end

---@return TargetedSpellsMixin
function PartyEditModeParentFrame:AcquireFrame()
	local frame = self.framePool:Acquire()

	frame:PostCreate("preview", Private.Enum.FrameKind.Party)

	return frame
end

---@param frame TargetedSpellsMixin
function PartyEditModeParentFrame:ReleaseFrame(frame)
	frame:Reset()
end

function PartyEditModeParentFrame:RepositionSelf()
	local parent = self.useRaidStylePartyFrames and CompactPartyFrame or PartyFrame
	local width = self.useRaidStylePartyFrames and 250 or 125
	local height = self.useRaidStylePartyFrames and 24 or 16

	self:SetSize(width, height)
	self:ClearAllPoints()
	self:SetPoint("CENTER", parent, "TOP", 0, 16)
end

---@param key string
---@param value string|number|table|boolean
function PartyEditModeParentFrame:OnSettingsChanged(key, value)
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

function PartyEditModeParentFrame:RepositionPreviewFrames()
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
			SortFrames(activeFrames, sortOrder)

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

			if direction == Private.Enum.Direction.Horizontal then
				local totalWidth = (activeFrameCount * width) + (activeFrameCount - 1) * gap

				for j, frame in ipairs(activeFrames) do
					local x = (j - 1) * width + (j - 1) * gap - totalWidth / 2 + offsetX
					frame:Reposition(sourceAnchor, parentFrame, targetAnchor, x, offsetY)
				end
			else
				local totalHeight = (activeFrameCount * height) + (activeFrameCount - 1) * gap

				for j, frame in ipairs(activeFrames) do
					local y = (j - 1) * height + (j - 1) * gap - totalHeight / 2 + offsetY
					frame:Reposition(sourceAnchor, parentFrame, targetAnchor, offsetX, y)
				end
			end
		end
	end
end

---@param frame TargetedSpellsPartyEditModeFrame
---@param layoutName string
---@param point string
---@param x number
---@param y number
function PartyEditModeParentFrame:OnEditModePositionChanged(frame, layoutName, point, x, y)
	-- don't do anything here as the element will stay attached to the party frames when reopening edit mode
	-- but still allow repositioning this frame while editing to temporarily move it out of the way
end

---@param frame TargetedSpellsMixin
---@param index number
function PartyEditModeParentFrame:LoopFrame(frame, index)
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

function PartyEditModeParentFrame:StartDemo()
	if self.demoPlaying then
		return
	end

	self.demoPlaying = true
	self.buildingFrames = true

	for unit = 1, self.maxUnitCount do
		if self.frames[unit] == nil then
			self.frames[unit] = {}
		end

		if unit == self.maxUnitCount and not self.useRaidStylePartyFrames then
			break
		end

		for index = 1, self.amountOfPreviewFramesPerUnit do
			if self.frames[unit][index] == nil then
				self.frames[unit][index] = self:AcquireFrame()
			end

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

function PartyEditModeParentFrame:EndDemo(forceDisable)
	if forceDisable == nil then
		forceDisable = false
	end

	if not self.demoPlaying and not forceDisable then
		return
	end

	local cleared = 0
	for _, ticker in pairs(self.demoTimers.tickers) do
		ticker:Cancel()
		cleared = cleared + 1
	end

	cleared = 0
	for _, timer in pairs(self.demoTimers.timers) do
		timer:Cancel()
		cleared = cleared + 1
	end

	table.wipe(self.demoTimers.tickers)
	table.wipe(self.demoTimers.timers)

	local releasedFrames = 0

	for unit = 1, self.maxUnitCount do
		for index = 1, self.amountOfPreviewFramesPerUnit do
			local frame = self.frames[unit][index]

			if frame then
				self:ReleaseFrame(frame)
				releasedFrames = releasedFrames + 1
			end
		end
	end

	self.demoPlaying = false
end

table.insert(Private.LoginFnQueue, GenerateClosure(PartyEditModeParentFrame.OnLoad, PartyEditModeParentFrame))
