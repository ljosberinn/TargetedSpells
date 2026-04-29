---@type string, TargetedSpells
local addonName, Private = ...

---@class TargetedSpellsUtils
Private.Utils = {}

function Private.Utils.SafelySetFont(kind, fontString, font, fontSize, fontFlags)
	local ok = pcall(function()
		fontString:SetFont(font, fontSize, fontFlags)
	end)

	if not ok then
		local tableRef = kind == Private.Enum.FrameKind.Self and TargetedSpellsSaved.Settings.Self
			or TargetedSpellsSaved.Settings.Party
		local defaults = kind == Private.Enum.FrameKind.Self and Private.Settings.GetSelfDefaultSettings()
			or Private.Settings.GetPartyDefaultSettings()

		tableRef.Font = defaults.Font
		fontString:SetFont(defaults.Font, fontSize, fontFlags)
	end
end

do
	local IsLongCastCurve = C_CurveUtil.CreateCurve()
	IsLongCastCurve:SetType(Enum.LuaCurveType.Linear)
	IsLongCastCurve:AddPoint(0, 1)
	IsLongCastCurve:AddPoint(60, 1)
	IsLongCastCurve:AddPoint(60.001, 0)

	Private.Utils.IsLongCastCurve = IsLongCastCurve
end

do
	Private.Utils.Formatter = C_StringUtil.CreateNumericRuleFormatter()

	-- thanks to m33shoq for this
	Private.Utils.Formatter:SetBreakpoints({
		{
			threshold = 0,
			format = "%.1f",
		},
		{
			threshold = 3.01,
			format = "%d",
		},
		{
			threshold = 60,
			format = "%d:%02d",
			components = {
				{
					div = 60,
				},
				{
					mod = 60,
				},
			},
		},
		{
			threshold = 600, -- 10 minutes
			format = "%dm",
			components = {
				{
					div = 60,
				},
			},
		},
		{
			threshold = 3600, -- 1 hour
			format = "%dh",
			components = {
				{
					div = 3600,
				},
			},
		},
		{
			threshold = 86400, -- 1 day
			format = "%dd",
			components = {
				{
					div = 86400,
				},
			},
		},
	})
end

Private.Utils.Pools = {
	Self = CreateFramePool(
		"Frame",
		UIParent,
		"TargetedSpellsFrameTemplate",
		---@param pool FramePool<TargetedSpellsIconMixin>
		---@param frame TargetedSpellsIconMixin
		function(pool, frame)
			frame:Reset()
		end
	),
	Bar = CreateFramePool(
		"Frame",
		UIParent,
		"TargetedSpellsBarFrameTemplate",
		---@param pool FramePool<TargetedSpellsBarMixin>
		---@param frame TargetedSpellsBarMixin
		function(pool, frame)
			frame:Reset()
		end
	),
}

do
	local function sortAsc(a, b)
		return a:GetStartTime() < b:GetStartTime()
	end

	local function sortDesc(a, b)
		return a:GetStartTime() > b:GetStartTime()
	end

	function Private.Utils.SortFrames(frames, sortOrder)
		local isAscending = sortOrder == Private.Enum.SortOrder.Ascending

		table.sort(frames, isAscending and sortAsc or sortDesc)
	end
end

function Private.Utils.RollDice()
	return math.random(1, 6) == 6
end

function Private.Utils.CollectLayoutingArguments(direction, grow, width, height, gap)
	local isHorizontal = direction == Private.Enum.Direction.Horizontal
	local isGrowEnd = grow == Private.Enum.Grow.End

	return {
		isHorizontal = isHorizontal,
		isGrowEnd = isGrowEnd,
		orientation = isHorizontal and "HORIZONTAL" or "VERTICAL",
		x = (isHorizontal and width or height) + gap,
		y = isHorizontal and height or width,
		originPoint = isHorizontal and (isGrowEnd and "RIGHT" or "LEFT") or (isGrowEnd and "TOP" or "BOTTOM"),
		relativePoint = isHorizontal and (isGrowEnd and "LEFT" or "RIGHT") or (isGrowEnd and "BOTTOM" or "TOP"),
	}
end

function Private.Utils.ShowMigrationPopup()
	EventRegistry:RegisterFrameEventAndCallback("FIRST_FRAME_RENDERED", function(ownerId)
		EventRegistry:UnregisterFrameEventAndCallback("FIRST_FRAME_RENDERED", ownerId)

		C_Timer.After(3, function()
			Private.Utils.ShowStaticPopup({
				whileDead = true,
				button1 = OKAY,
				text = Private.L.Functionality.V3MigrationWarning,
			})
		end)
	end)
end

function Private.Utils.MigratePartySettingsToV3(existing)
	local defaults = Private.Settings.GetPartyDefaultSettings()

	local compatibleKeys = {
		"Enabled",
		"LoadConditionContentType",
		"LoadConditionRole",
		"Font",
		"GlowType",
		"FontFlags",
	}

	for _, key in ipairs(compatibleKeys) do
		local value = existing[key]

		if value ~= nil and type(value) == type(defaults[key]) then
			defaults[key] = value
		end
	end

	return defaults
end

function Private.Utils.ApplyMigration(key, kind, defaults)
	local tableRef = kind == Private.Enum.FrameKind.Self and TargetedSpellsSaved.Settings.Self
		or TargetedSpellsSaved.Settings.Party

	if key == "Grow" and tableRef[key] == 1 then
		tableRef[key] = Private.Enum.Grow.Start
	end

	if key == "GlowType" and tableRef[key] == 3 then
		tableRef[key] = Private.Enum.GlowType.PixelGlow
	end

	if key == "ShowBorder" then
		local shown = tableRef[key]
		tableRef[key] = nil
		tableRef.BorderStyle = shown and defaults.BorderStyle or "None"
	end
end

function Private.Utils.AdjustLayout(
	frames,
	layouting,
	barParent,
	firstAnchorPoint,
	firstOffsetX,
	firstOffsetY,
	isEditMode
)
	---@type Texture?
	local prevStatusBarTexture = nil

	for _, frame in ipairs(frames) do
		if layouting.isHorizontal then
			frame.Bar:SetSize(layouting.x, layouting.y)
		else
			frame.Bar:SetSize(layouting.y, layouting.x)
		end

		local texture = frame.Bar:GetStatusBarTexture()
		frame:ClearAllPoints()
		frame:SetPoint(layouting.originPoint, texture, layouting.originPoint)

		frame.Bar:SetOrientation(layouting.orientation)
		frame.Bar:SetReverseFill(layouting.isGrowEnd)
		frame.Bar:SetParent(barParent)
		frame:SetParent(frame.Bar)
		frame:SetFrameLevel(frame.Bar:GetFrameLevel() + 10)
		frame.Bar:ClearAllPoints()

		if isEditMode then
			frame.Bar:SetValue(frame:GetAlpha())
		end

		if prevStatusBarTexture == nil then
			frame.Bar:SetPoint(layouting.originPoint, barParent, firstAnchorPoint, firstOffsetX, firstOffsetY)
		else
			frame.Bar:SetPoint(layouting.originPoint, prevStatusBarTexture, layouting.relativePoint, 0, 0)
		end

		frame:Show()

		prevStatusBarTexture = texture
	end
end

function Private.Utils.CreateEditablePopup(title, text, button1)
	return {
		text = title,
		button1 = button1,
		hasEditBox = true,
		hasWideEditBox = true,
		editBoxWidth = 350,
		hideOnEscape = true,
		OnShow = function(popupSelf)
			local editBox = popupSelf:GetEditBox()
			editBox:SetText(text)
			editBox:HighlightText()

			local ctrlDown = false

			editBox:SetScript("OnKeyDown", function(_, key)
				if key == "LCTRL" or key == "RCTRL" or key == "LMETA" or key == "RMETA" then
					ctrlDown = true
				end
			end)
			editBox:SetScript("OnKeyUp", function(_, key)
				C_Timer.After(0.2, function()
					ctrlDown = false
				end)

				if ctrlDown and (key == "C" or key == "X") then
					StaticPopup_Hide(addonName)
				end
			end)
		end,
		EditBoxOnEscapePressed = function(popupSelf)
			popupSelf:GetParent():Hide()
		end,
		EditBoxOnTextChanged = function(popupSelf)
			-- ctrl + x sets the text to "" but this triggers hiding and shouldn't trigger resetting the text
			local currentText = popupSelf:GetText()

			if currentText == "" or currentText == text then
				return
			end

			popupSelf:SetText(text)
		end,
	}
end

function Private.Utils.ShowStaticPopup(args)
	args.id = addonName
	args.whileDead = true

	StaticPopupDialogs[addonName] = args

	StaticPopup_Hide(addonName)
	StaticPopup_Show(addonName)
end

---@param string string
---@return table
local function DecodeProfileString(string)
	return C_EncodingUtil.DeserializeCBOR(C_EncodingUtil.DecodeBase64(string))
end

do
	---@type table<string, Frame|nil>
	local editModeFrameByKind = {
		[Private.Enum.FrameKind.Self] = nil,
		[Private.Enum.FrameKind.Party] = nil,
	}

	function Private.Utils.RegisterEditModeFrame(frameKind, frame)
		editModeFrameByKind[frameKind] = frame
	end

	function Private.Utils.GetEditModeFrame(frameKind)
		return editModeFrameByKind[frameKind]
	end

	function Private.Utils.Import(string)
		local ok, result = pcall(DecodeProfileString, string)

		if not ok then
			if result ~= nil then
				print(result)
			end

			return false
		end

		-- just a type check
		if result == nil then
			return false
		end

		local hasAnyChange = false

		---@param tableRef SavedVariablesSettingsParty|SavedVariablesSettingsSelf
		---@param kindString string
		---@param sourceData table
		---@param defaults table
		---@param eventKeys table
		local function ImportKindSettings(tableRef, kindString, sourceData, defaults, eventKeys)
			local anyPrimaryLoadConditionIsDisabled = false

			local enumByKey = {
				LoadConditionContentType = Private.Enum.ContentType,
				LoadConditionRole = Private.Enum.Role,
				FontFlags = Private.Enum.FontFlags,
				FeatureFlags = Private.Enum.FeatureFlag,
				AnnounceUntargetedSpells = Private.Enum.NpcType,
				AnnounceTargetedSpells = Private.Enum.NpcType,
			}

			local isLoadConditionKey = {
				LoadConditionContentType = true,
				LoadConditionRole = true,
			}

			for key, defaultValue in pairs(defaults) do
				local newValue = sourceData[key]
				local expectedType = type(defaultValue)

				if newValue ~= nil and type(newValue) == expectedType then
					local eventKey = eventKeys[key]
					local hasChanges = false

					if expectedType == "table" then
						local enumToCompareAgainst = enumByKey[key]

						if enumToCompareAgainst then
							local newTable = {}
							local allDisabled = true

							for _, id in pairs(enumToCompareAgainst) do
								if newValue[id] == nil then
									newTable[id] = tableRef[key][id]
								else
									newTable[id] = newValue[id]

									if newValue[id] ~= tableRef[key][id] then
										hasChanges = true
									end

									if newValue[id] then
										allDisabled = false
									end
								end
							end

							if allDisabled and isLoadConditionKey[key] then
								anyPrimaryLoadConditionIsDisabled = true
							end

							if hasChanges then
								tableRef[key] = newTable
								Private.Utils.ApplyMigration(key, kindString, defaults)
								Private.EventRegistry:TriggerEvent(
									Private.Enum.Events.SETTING_CHANGED,
									eventKey,
									newTable
								)
							end
						end
					elseif newValue ~= tableRef[key] then
						tableRef[key] = newValue
						Private.Utils.ApplyMigration(key, kindString, defaults)
						hasChanges = true

						if eventKey then
							Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, eventKey, newValue)
						end
					end

					if hasChanges then
						hasAnyChange = true
					end
				end
			end

			if anyPrimaryLoadConditionIsDisabled then
				tableRef.Enabled = false
				Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, eventKeys.Enabled, false)
			end
		end

		TargetedSpellsSaved.V3MigrationWarningSeen = true

		for kind, kindString in pairs(Private.Enum.FrameKind) do
			local sourceData = result[kind]

			if sourceData ~= nil then
				local tableRef = TargetedSpellsSaved.Settings[kind]
				local isSelf = kind == "Self"
				local defaults = isSelf and Private.Settings.GetSelfDefaultSettings()
					or Private.Settings.GetPartyDefaultSettings()
				local eventKeys = isSelf and Private.Settings.Keys.Self or Private.Settings.Keys.Party

				ImportKindSettings(tableRef, kindString, sourceData, defaults, eventKeys)

				if sourceData.Position ~= nil then
					local point, x, y = sourceData.Position.point, sourceData.Position.x, sourceData.Position.y
					local frame = editModeFrameByKind[kindString]

					if
						frame ~= nil
						and (point ~= tableRef.Position.point or x ~= tableRef.Position.x or y ~= tableRef.Position.y)
					then
						frame:ClearAllPoints()
						PixelUtil.SetPoint(frame, "CENTER", UIParent, point, x, y)

						tableRef.Position.point = point
						tableRef.Position.x = x
						tableRef.Position.y = y

						local event = isSelf and Private.Enum.Events.SETTING_CHANGED
							or Private.Enum.Events.SETTING_CHANGED
						Private.EventRegistry:TriggerEvent(event, point, x, y)
					end
				end
			end
		end

		return hasAnyChange
	end

	function Private.Utils.Export()
		return C_EncodingUtil.EncodeBase64(C_EncodingUtil.SerializeCBOR(TargetedSpellsSaved.Settings))
	end
end

do
	local function noop() end

	_G.TargetedSpellsAPI = {
		Import = Private.Utils.Import,
		Export = Private.Utils.Export,
		DecodeProfileString = DecodeProfileString,
		RegisterFrameByName = noop,
		UnregisterFrameByName = noop,
		SetProfile = noop,
		GetProfileKeys = function()
			return { "Global" }
		end,
		GetCurrentProfileKey = function()
			return "Global"
		end,
		OpenConfig = noop,
		CloseConfig = noop,
	}
end
