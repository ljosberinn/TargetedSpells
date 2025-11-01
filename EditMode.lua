---@type string, TargetedSpells
local addonName, Private = ...
local LEM = LibStub("LibEditMode")

local function SetupSelfEditMode()
	local amountOfPreviewFrames = 5
	local EditModeParentFrame = CreateFrame("Frame", "Targeted Spells Self", UIParent)
	EditModeParentFrame:SetClampedToScreen(true)

	if TargetedSpellsSaved.Settings.Self.GrowDirection == Private.Enum.GrowDirection.Horizontal then
		EditModeParentFrame:SetSize(
			amountOfPreviewFrames * TargetedSpellsSaved.Settings.Self.Width
				+ (amountOfPreviewFrames - 1) * TargetedSpellsSaved.Settings.Self.Spacing,
			TargetedSpellsSaved.Settings.Self.Height
		)
	else
		EditModeParentFrame:SetSize(
			TargetedSpellsSaved.Settings.Self.Width,
			amountOfPreviewFrames * TargetedSpellsSaved.Settings.Self.Height
				+ (amountOfPreviewFrames - 1) * TargetedSpellsSaved.Settings.Self.Spacing
		)
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
		local width, height, spacing, growDirection =
			TargetedSpellsSaved.Settings.Self.Width,
			TargetedSpellsSaved.Settings.Self.Height,
			TargetedSpellsSaved.Settings.Self.Spacing,
			TargetedSpellsSaved.Settings.Self.GrowDirection

		---@type TargetedSpellsMixin[]
		local frames = {}
		for _, frame in pairs(previewFrames) do
			if frame:ShouldBeShown() then
				table.insert(frames, frame)
			end
		end

		local isHorizontal = growDirection == Private.Enum.GrowDirection.Horizontal

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
			local totalWidth = (activeFrameCount * width) + (activeFrameCount - 1) * spacing

			for i, frame in ipairs(frames) do
				local x = (i - 1) * width + (i - 1) * spacing - totalWidth / 2
				frame:Reposition("LEFT", EditModeParentFrame, "CENTER", x, 0)
			end
		else
			local totalHeight = (activeFrameCount * height) + (activeFrameCount - 1) * spacing

			for i, frame in ipairs(frames) do
				local y = (i - 1) * height + (i - 1) * spacing - totalHeight / 2
				frame:Reposition("BOTTOM", EditModeParentFrame, "CENTER", 0, y)
			end
		end
	end

	Private.EventRegistry:RegisterCallback(Private.Events.SETTING_CHANGED, function(self, key, value)
		if
			key == Private.Settings.Keys.Self.Spacing
			or key == Private.Settings.Keys.Self.GrowDirection
			or key == Private.Settings.Keys.Self.Width
			or key == Private.Settings.Keys.Self.Height
		then
			local isHorizontal = TargetedSpellsSaved.Settings.Self.GrowDirection
				== Private.Enum.GrowDirection.Horizontal
			local activeFrameCount = #previewFrames
			local spacing = TargetedSpellsSaved.Settings.Self.Spacing

			if isHorizontal then
				local width = TargetedSpellsSaved.Settings.Self.Width
				local totalWidth = (activeFrameCount * width) + (activeFrameCount - 1) * spacing
				self:SetSize(totalWidth, TargetedSpellsSaved.Settings.Self.Height)
			else
				local height = TargetedSpellsSaved.Settings.Self.Height
				local totalHeight = (activeFrameCount * height) + (activeFrameCount - 1) * spacing
				self:SetSize(TargetedSpellsSaved.Settings.Self.Width, totalHeight)
			end

			RepositionPreviewFrames()
		elseif key == Private.Settings.Keys.Self.Enabled then
		end
	end, EditModeParentFrame)

	local playing = false

	local function ToggleDemo()
		for _, frame in pairs(previewFrames) do
			if playing then
				frame:StopPreviewLoop()
			else
				frame:StartPreviewLoop(RepositionPreviewFrames)
			end
		end

		playing = not playing
	end

	LEM:RegisterCallback("enter", ToggleDemo)
	LEM:RegisterCallback("exit", ToggleDemo)

	local frameSettings = {}

	-- Enabled
	-- Load Condition: Content Type
	do
		table.insert(frameSettings, {
			name = "Load in Content",
			kind = Enum.EditModeSettingDisplayType.Dropdown,
			default = Private.Settings.GetSelfDefaultSettings().LoadConditionContentType,
			generator = function(owner, rootDescription, data)
				for label, id in pairs(Private.Enum.ContentType) do
					local function IsEnabled()
						return TargetedSpellsSaved.Settings.Self.LoadConditionContentType[id]
					end

					local function Toggle()
						TargetedSpellsSaved.Settings.Self.LoadConditionContentType[id] =
							not TargetedSpellsSaved.Settings.Self.LoadConditionContentType[id]
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
					if TargetedSpellsSaved.Settings.Self.LoadConditionContentType[id] ~= bool then
						TargetedSpellsSaved.Settings.Self.LoadConditionContentType[id] = bool
						hasChanges = true
					end
				end

				if hasChanges then
					Private.EventRegistry:TriggerEvent(
						Private.Events.SETTING_CHANGED,
						Private.Settings.Keys.Self.LoadConditionContentType,
						TargetedSpellsSaved.Settings.Self.LoadConditionContentType
					)
				end
			end,
		})
	end
	-- Load Condition: Role
	do
		table.insert(frameSettings, {
			name = "Load on Role",
			kind = Enum.EditModeSettingDisplayType.Dropdown,
			default = Private.Settings.GetSelfDefaultSettings().LoadConditionRole,
			generator = function(owner, rootDescription, data)
				for label, id in pairs(Private.Enum.ContentType) do
					local function IsEnabled()
						return TargetedSpellsSaved.Settings.Self.LoadConditionRole[id]
					end

					local function Toggle()
						TargetedSpellsSaved.Settings.Self.LoadConditionRole[id] =
							not TargetedSpellsSaved.Settings.Self.LoadConditionRole[id]
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
					if TargetedSpellsSaved.Settings.Self.LoadConditionRole[id] ~= bool then
						TargetedSpellsSaved.Settings.Self.LoadConditionRole[id] = bool
						hasChanges = true
					end
				end

				if hasChanges then
					Private.EventRegistry:TriggerEvent(
						Private.Events.SETTING_CHANGED,
						Private.Settings.Keys.Self.LoadConditionRole,
						TargetedSpellsSaved.Settings.Self.LoadConditionRole
					)
				end
			end,
		})
	end

	-- Frame Width
	do
		local sliderSettings = Private.Settings.GetSliderSettingsForOption(Private.Settings.Keys.Self.Width)

		table.insert(frameSettings, {
			name = "Width",
			kind = Enum.EditModeSettingDisplayType.Slider,
			default = Private.Settings.GetSelfDefaultSettings().Width,
			get = function(layoutName)
				return TargetedSpellsSaved.Settings.Self.Width
			end,
			set = function(layoutName, value)
				TargetedSpellsSaved.Settings.Self.Width = value
				Private.EventRegistry:TriggerEvent(
					Private.Events.SETTING_CHANGED,
					Private.Settings.Keys.Self.Width,
					value
				)
			end,
			minValue = sliderSettings.min,
			maxValue = sliderSettings.max,
			valueStep = sliderSettings.step,
		})
	end

	-- Frame Height
	do
		local sliderSettings = Private.Settings.GetSliderSettingsForOption(Private.Settings.Keys.Self.Height)

		table.insert(frameSettings, {
			name = "Height",
			kind = Enum.EditModeSettingDisplayType.Slider,
			default = Private.Settings.GetSelfDefaultSettings().Height,
			get = function(layoutName)
				return TargetedSpellsSaved.Settings.Self.Height
			end,
			set = function(layoutName, value)
				TargetedSpellsSaved.Settings.Self.Height = value
				Private.EventRegistry:TriggerEvent(
					Private.Events.SETTING_CHANGED,
					Private.Settings.Keys.Self.Height,
					value
				)
			end,
			minValue = sliderSettings.min,
			maxValue = sliderSettings.max,
			valueStep = sliderSettings.step,
		})
	end

	-- Frame Spacing
	do
		local sliderSettings = Private.Settings.GetSliderSettingsForOption(Private.Settings.Keys.Self.Spacing)

		table.insert(frameSettings, {
			name = "Spacing",
			kind = Enum.EditModeSettingDisplayType.Slider,
			default = Private.Settings.GetSelfDefaultSettings().Spacing,
			get = function(layoutName)
				return TargetedSpellsSaved.Settings.Self.Spacing
			end,
			set = function(layoutName, value)
				TargetedSpellsSaved.Settings.Self.Spacing = value
				Private.EventRegistry:TriggerEvent(
					Private.Events.SETTING_CHANGED,
					Private.Settings.Keys.Self.Spacing,
					value
				)
			end,
			minValue = sliderSettings.min,
			maxValue = sliderSettings.max,
			valueStep = sliderSettings.step,
		})
	end

	-- Frame Grow Direction
	do
		---@param layoutName string
		---@param value number
		local function Set(layoutName, value)
			if TargetedSpellsSaved.Settings.Self.GrowDirection ~= value then
				TargetedSpellsSaved.Settings.Self.GrowDirection = value
				Private.EventRegistry:TriggerEvent(
					Private.Events.SETTING_CHANGED,
					Private.Settings.Keys.Self.GrowDirection,
					value
				)
			end
		end

		table.insert(frameSettings, {
			name = "Grow Direction",
			kind = Enum.EditModeSettingDisplayType.Dropdown,
			default = Private.Settings.GetSelfDefaultSettings().GrowDirection,
			generator = function(owner, rootDescription, data)
				for label, enumValue in pairs(Private.Enum.GrowDirection) do
					local function IsEnabled()
						return TargetedSpellsSaved.Settings.Self.GrowDirection == enumValue
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
		})
	end

	-- todo: layouting
	LEM:AddFrameSettings(EditModeParentFrame, frameSettings)

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
	local EditModeParentFrame = CreateFrame("Frame", "Targeted Spells Party", UIParent)
	EditModeParentFrame:SetClampedToScreen(true)

	-- todo: restore position from layout
	EditModeParentFrame:SetPoint("CENTER", UIParent)

	---@type TargetedSpellsMixin[]
	local previewFrames = {}

	for i = 1, 5 do
		local relationalUnit = "party" .. i

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
			previewFrame:SetRelationalUnit(relationalUnit)

			table.insert(previewFrames, previewFrame)
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

	-- todo: check CompactRaidFrameContainer.enabled

	local function RepositionPreviewFrames()
		local width, height, spacing, growDirection =
			TargetedSpellsSaved.Settings.Party.Width,
			TargetedSpellsSaved.Settings.Party.Height,
			TargetedSpellsSaved.Settings.Party.Spacing,
			TargetedSpellsSaved.Settings.Party.GrowDirection

		---@type table<string, TargetedSpellsMixin[]>
		local framesByUnit = {}

		for _, frame in pairs(previewFrames) do
			if frame:ShouldBeShown() then
				local relationalUnit = frame:GetRelationalUnit()

				if relationalUnit ~= nil then
					if framesByUnit[relationalUnit] == nil then
						framesByUnit[relationalUnit] = {}
					end

					table.insert(framesByUnit[relationalUnit], frame)
				end
			end
		end

		for unit, frames in pairs(framesByUnit) do
			-- local isHorizontal = growDirection == Private.Enum.GrowDirection.Horizontal

			table.sort(frames, function(a, b)
				if a:GetStartTime() and b:GetStartTime() then
					-- if isHorizontal then
					-- 	return a:GetStartTime() < b:GetStartTime()
					-- end

					return a:GetStartTime() > b:GetStartTime()
				end

				return false
			end)

			-- find unit frame
			local activeFrameCount = #frames

			-- local unitFrame = CompactRaidFrameContainer:GetUnitFrame(unit, "raid")

			print(unit, activeFrameCount)
		end

		-- if CompactRaidFrameContainer.units then
		-- 	for k, v in pairs(CompactRaidFrameContainer.units) do
		-- 		print(k, v)
		-- 	end
		-- end

		-- if isHorizontal then
		-- 	local totalWidth = (activeFrameCount * width) + (activeFrameCount - 1) * spacing

		-- 	for i, frame in ipairs(frames) do
		-- 		local x = (i - 1) * width + (i - 1) * spacing - totalWidth / 2
		-- 		frame:Reposition("LEFT", EditModeParentFrame, "CENTER", x, 0)
		-- 	end
		-- else
		-- 	local totalHeight = (activeFrameCount * height) + (activeFrameCount - 1) * spacing

		-- 	for i, frame in ipairs(frames) do
		-- 		local y = (i - 1) * height + (i - 1) * spacing - totalHeight / 2
		-- 		frame:Reposition("BOTTOM", EditModeParentFrame, "CENTER", 0, y)
		-- 	end
		-- end
	end

	local playing = false

	local function ToggleDemo()
		for _, frame in pairs(previewFrames) do
			if playing then
				frame:StopPreviewLoop()
			else
				frame:StartPreviewLoop(RepositionPreviewFrames)
			end
		end

		playing = not playing
	end

	LEM:RegisterCallback("enter", ToggleDemo)
	LEM:RegisterCallback("exit", ToggleDemo)
end

table.insert(Private.LoginFnQueue, SetupPartyEditMode)
