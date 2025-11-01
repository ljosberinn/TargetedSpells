---@type string, TargetedSpells
local addonName, Private = ...

table.insert(Private.LoginFnQueue, function()
	local LEM = LibStub("LibEditMode")

	local amountOfPreviewFrames = 4
	local EditModeTargetedSpellsSelfParentFrame = CreateFrame("Frame", "Targeted Spells Self", UIParent)

	if TargetedSpellsSaved.Settings.Self.GrowDirection == Private.Enum.GrowDirection.Horizontal then
		EditModeTargetedSpellsSelfParentFrame:SetSize(
			amountOfPreviewFrames * TargetedSpellsSaved.Settings.Self.Width
				+ (amountOfPreviewFrames - 1) * TargetedSpellsSaved.Settings.Self.Spacing,
			TargetedSpellsSaved.Settings.Self.Height
		)
	else
		EditModeTargetedSpellsSelfParentFrame:SetSize(
			TargetedSpellsSaved.Settings.Self.Width,
			amountOfPreviewFrames * TargetedSpellsSaved.Settings.Self.Height
				+ (amountOfPreviewFrames - 1) * TargetedSpellsSaved.Settings.Self.Spacing
		)
	end

	EditModeTargetedSpellsSelfParentFrame:SetPoint("CENTER", UIParent)
	EditModeTargetedSpellsSelfParentFrame:SetClampedToScreen(true)

	local selfPreviewFrames = {}

	-- self
	for i = 1, amountOfPreviewFrames do
		local previewFrame = CreateFrame(
			"Frame",
			"EditModeTargetedSpellsPreviewEditMode" .. i,
			EditModeTargetedSpellsSelfParentFrame,
			"TargetedSpellsFrameTemplate"
		)

		previewFrame:SetUnit("preview" .. i)
		previewFrame:SetKind(Private.Enum.FrameKind.Self)

		table.insert(selfPreviewFrames, previewFrame)
	end

	-- party
	-- raid

	local defaultPosition = { point = "CENTER", x = 0, y = 0 }

	local function onPositionChanged(frame, layoutName, point, x, y)
		print(layoutName, point, x, y)

		-- TagsTrivialTweaks_Settings.LEM[layoutName].point = point
		-- TagsTrivialTweaks_Settings.LEM[layoutName].x = x
		-- TagsTrivialTweaks_Settings.LEM[layoutName].y = y
	end

	LEM:AddFrame(EditModeTargetedSpellsSelfParentFrame, onPositionChanged, defaultPosition)

	local function RepositionPreviewFrames()
		local width, height, spacing, growDirection =
			TargetedSpellsSaved.Settings.Self.Width,
			TargetedSpellsSaved.Settings.Self.Height,
			TargetedSpellsSaved.Settings.Self.Spacing,
			TargetedSpellsSaved.Settings.Self.GrowDirection

		---@type TargetedSpellsMixin[]
		local frames = {}
		for _, frame in pairs(selfPreviewFrames) do
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
				frame:Reposition("LEFT", EditModeTargetedSpellsSelfParentFrame, "CENTER", x, 0)
			end
		else
			local totalHeight = (activeFrameCount * height) + (activeFrameCount - 1) * spacing

			for i, frame in ipairs(frames) do
				local y = (i - 1) * height + (i - 1) * spacing - totalHeight / 2
				frame:Reposition("BOTTOM", EditModeTargetedSpellsSelfParentFrame, "CENTER", 0, y)
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
			local activeFrameCount = #selfPreviewFrames
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
	end, EditModeTargetedSpellsSelfParentFrame)

	local playing = false

	local function ToggleDemo()
		for _, frame in pairs(selfPreviewFrames) do
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

	table.insert(frameSettings, {
		name = "Grow Direction",
		kind = Enum.EditModeSettingDisplayType.Dropdown,
		default = Private.Settings.GetSelfDefaultSettings().GrowDirection,
		generator = function(owner, rootDescription, data)
			for label, enumValue in pairs(Private.Enum.GrowDirection) do
				local function Get()
					return TargetedSpellsSaved.Settings.Self.GrowDirection == enumValue
				end

				local function Set()
					if TargetedSpellsSaved.Settings.Self.GrowDirection ~= enumValue then
						TargetedSpellsSaved.Settings.Self.GrowDirection = enumValue
						Private.EventRegistry:TriggerEvent(
							Private.Events.SETTING_CHANGED,
							Private.Settings.Keys.Self.GrowDirection,
							enumValue
						)
					end
				end

				rootDescription:CreateCheckbox(label, Get, Set, {
					value = label,
					isRadio = true,
				})
			end
		end,
	})

	-- todo: layouting
	LEM:AddFrameSettings(EditModeTargetedSpellsSelfParentFrame, frameSettings)

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
end)
