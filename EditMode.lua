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

						print(id, key)

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

	if key == Private.Settings.Keys.Party.Anchor then
		---@param layoutName string
		---@param value string
		local function Set(layoutName, value)
			if TargetedSpellsSaved.Settings.Party.Anchor ~= value then
				TargetedSpellsSaved.Settings.Party.Anchor = value
				Private.EventRegistry:TriggerEvent(Private.Events.SETTING_CHANGED, key, value)
			end
		end

		return {
			name = "Anchor",
			kind = Enum.EditModeSettingDisplayType.Dropdown,
			default = Private.Settings.GetPartyDefaultSettings().Anchor,
			generator = function(owner, rootDescription, data)
				for label, enumValue in pairs(Private.Enum.Anchor) do
					local function IsEnabled()
						return TargetedSpellsSaved.Settings.Party.Anchor == enumValue
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
			key
		)
	)
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
		local width, height, gap, direction =
			TargetedSpellsSaved.Settings.Self.Width,
			TargetedSpellsSaved.Settings.Self.Height,
			TargetedSpellsSaved.Settings.Self.Gap,
			TargetedSpellsSaved.Settings.Self.Direction

		---@type TargetedSpellsMixin[]
		local frames = {}
		for _, frame in pairs(previewFrames) do
			if frame:ShouldBeShown() then
				table.insert(frames, frame)
			end
		end

		local isHorizontal = direction == Private.Enum.Direction.Horizontal

		table.sort(frames, function(a, b)
			if a:GetStartTime() and b:GetStartTime() then
				if isHorizontal then
					return a:GetStartTime() < b:GetStartTime()
				end

				return a:GetStartTime() > b:GetStartTime()
			end

			return false
		end)

		local activeFrameCount = #frames

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
		then
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

table.insert(Private.LoginFnQueue, SetupSelfEditMode)

local function SetupPartyEditMode()
	local amountOfPreviewFramesPerUnit = 3
	---@type boolean
	local useRaidStylePartyFrames = false

	-- when this executes, layouts aren't loaded yet
	hooksecurefunc(EditModeManagerFrame, "UpdateLayoutInfo", function(self)
		useRaidStylePartyFrames = EditModeManagerFrame:UseRaidStylePartyFrames()
	end)

	local EditModeParentFrame = CreateFrame("Frame", "Targeted Spells Party", UIParent)
	EditModeParentFrame:SetClampedToScreen(true)
	EditModeParentFrame:SetSize(250, 24)
	-- todo: show something in this frame as it otherwise has no preview

	local function RepositionEditModeParentFrame()
		EditModeParentFrame:SetPoint(
			"CENTER",
			useRaidStylePartyFrames and CompactPartyFrame or PartyFrame,
			"TOP",
			0,
			16
		)
	end

	RepositionEditModeParentFrame()

	---@type table<number, TargetedSpellsMixin[]>
	local previewFrames = {}

	for i = 1, 5 do
		for j = 1, amountOfPreviewFramesPerUnit do
			local index = #previewFrames + 1
			local previewFrame = CreateFrame(
				"Frame",
				"EditModeTargetedSpellsPartyPreview" .. index,
				EditModeParentFrame,
				"TargetedSpellsFrameTemplate"
			)

			previewFrame:SetUnit("preview" .. j)
			previewFrame:SetKind(Private.Enum.FrameKind.Party)

			if previewFrames[i] == nil then
				previewFrames[i] = {}
			end

			table.insert(previewFrames[i], previewFrame)

			if not TargetedSpellsSaved.Settings.Party.Enabled then
				previewFrame:Hide()
			end
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
		local width, height, gap, direction, offsetX, offsetY, anchor =
			TargetedSpellsSaved.Settings.Party.Width,
			TargetedSpellsSaved.Settings.Party.Height,
			TargetedSpellsSaved.Settings.Party.Gap,
			TargetedSpellsSaved.Settings.Party.Direction,
			TargetedSpellsSaved.Settings.Party.OffsetX,
			TargetedSpellsSaved.Settings.Party.OffsetY,
			TargetedSpellsSaved.Settings.Party.Anchor

		for index, frames in pairs(previewFrames) do
			---@type table<string, TargetedSpellsMixin[]>
			local activeFrames = {}

			for _, frame in pairs(frames) do
				if frame:ShouldBeShown() then
					table.insert(activeFrames, frame)
				end
			end

			local isHorizontal = direction == Private.Enum.Direction.Horizontal

			table.sort(activeFrames, function(a, b)
				if a:GetStartTime() and b:GetStartTime() then
					if isHorizontal then
						return a:GetStartTime() < b:GetStartTime()
					end

					return a:GetStartTime() > b:GetStartTime()
				end

				return false
			end)

			local parentFrame = nil
			if useRaidStylePartyFrames then
				parentFrame = CompactPartyFrame.memberUnitFrames[index]
			else
				for memberFrame in PartyFrame.PartyMemberFramePool:EnumerateActive() do
					if memberFrame.layoutIndex == index then
						parentFrame = memberFrame
						break
					end
				end
			end

			if parentFrame == nil then
				-- disabling raid-style party frames - which show only 4 frames - needs to hide the 5th
				for i, frame in ipairs(activeFrames) do
					frame:ClearAllPoints()
					frame:Hide()
				end

				return
			end

			local activeFrameCount = #activeFrames

			if isHorizontal then
				local totalWidth = (activeFrameCount * width) + (activeFrameCount - 1) * gap

				for i, frame in ipairs(activeFrames) do
					local x = (i - 1) * width + (i - 1) * gap - totalWidth / 2 + offsetX
					frame:Reposition("LEFT", parentFrame, anchor, x, offsetY)
				end
			else
				local totalHeight = (activeFrameCount * height) + (activeFrameCount - 1) * gap

				for i, frame in ipairs(frames) do
					local y = (i - 1) * height + (i - 1) * gap - totalHeight / 2 + offsetY
					frame:Reposition("BOTTOM", parentFrame, anchor, offsetX, y)
				end
			end
		end
	end

	hooksecurefunc(EditModeSystemSettingsDialog, "OnSettingValueChanged", function(self, setting, checked)
		if setting == Enum.EditModeUnitFrameSetting.UseRaidStylePartyFrames then
			local nextUseRaidStylePartyFrames = checked == 1

			if nextUseRaidStylePartyFrames ~= useRaidStylePartyFrames then
				useRaidStylePartyFrames = nextUseRaidStylePartyFrames
				RepositionPreviewFrames()
				RepositionEditModeParentFrame()
			end
		end
	end)

	local playing = false

	---@param forceDisable boolean?
	local function ToggleDemo(forceDisable)
		if forceDisable == nil then
			forceDisable = false
		end

		if not TargetedSpellsSaved.Settings.Party.Enabled and not forceDisable then
			return
		end

		for _, frames in pairs(previewFrames) do
			for _, frame in pairs(frames) do
				if playing then
					frame:StopPreviewLoop()
				else
					frame:StartPreviewLoop(RepositionPreviewFrames)
				end
			end
		end

		playing = not playing
	end

	Private.EventRegistry:RegisterCallback(Private.Events.SETTING_CHANGED, function(self, key, value)
		if
			key == Private.Settings.Keys.Party.Gap
			or key == Private.Settings.Keys.Party.Direction
			or key == Private.Settings.Keys.Party.Width
			or key == Private.Settings.Keys.Party.Height
			or key == Private.Settings.Keys.Party.OffsetX
			or key == Private.Settings.Keys.Party.OffsetY
			or key == Private.Settings.Keys.Party.Anchor
		then
			RepositionPreviewFrames()
		elseif key == Private.Settings.Keys.Party.Enabled then
			local forceDisable = not TargetedSpellsSaved.Settings.Party.Enabled and playing
			ToggleDemo(forceDisable)
		end
	end, EditModeParentFrame)

	LEM:RegisterCallback("enter", ToggleDemo)
	LEM:RegisterCallback("exit", ToggleDemo)

	-- todo: layouting
	LEM:AddFrameSettings(EditModeParentFrame, {
		CreateSetting(Private.Settings.Keys.Party.Enabled),
		CreateSetting(Private.Settings.Keys.Party.LoadConditionContentType),
		CreateSetting(Private.Settings.Keys.Party.LoadConditionRole),
		CreateSetting(Private.Settings.Keys.Party.Width),
		CreateSetting(Private.Settings.Keys.Party.Height),
		CreateSetting(Private.Settings.Keys.Party.Gap),
		CreateSetting(Private.Settings.Keys.Party.Direction),
		CreateSetting(Private.Settings.Keys.Party.OffsetX),
		CreateSetting(Private.Settings.Keys.Party.OffsetY),
		CreateSetting(Private.Settings.Keys.Party.Anchor),
	})
end

table.insert(Private.LoginFnQueue, SetupPartyEditMode)
