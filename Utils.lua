---@type string, TargetedSpells
local addonName, Private = ...

---@class TargetedSpellsUtils
Private.Utils = {}

Private.Utils.Pool = CreateFramePool(
	"Frame",
	UIParent,
	"TargetedSpellsFrameTemplate",
	---@param pool FramePool<TargetedSpellsMixin>
	---@param frame TargetedSpellsMixin
	function(pool, frame)
		frame:Reset()
	end
)

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

function Private.Utils.ShowMigrationPopup(resetKeys, kind)
	local text = string.format(Private.L.Functionality.V2DeprecationWarning, table.concat(resetKeys, "\n"))
	if kind == "import" then
		-- cannot show StaticPopup while in Edit Mode apparently
		print(text)
	elseif kind == "login" then
		EventRegistry:RegisterFrameEventAndCallback("FIRST_FRAME_RENDERED", function(ownerId)
			EventRegistry:UnregisterFrameEventAndCallback("FIRST_FRAME_RENDERED", ownerId)

			C_Timer.After(3, function()
				Private.Utils.ShowStaticPopup({
					whileDead = true,
					button1 = OKAY,
					text = text,
				})
			end)
		end)
	end
end

function Private.Utils.ApplyMigration(key, kind, defaults)
	local tableRef = kind == Private.Enum.FrameKind.Self and TargetedSpellsSaved.Settings.Self
		or TargetedSpellsSaved.Settings.Party
	local prefix = kind == Private.Enum.FrameKind.Self and Private.L.EditMode.TargetedSpellsSelfLabel
		or Private.L.EditMode.TargetedSpellsPartyLabel

	if key == "Grow" and tableRef[key] == 1 then
		tableRef[key] = Private.Enum.Grow.Start
		return prefix .. ": " .. Private.L.Settings.FrameGrowLabel
	end

	if key == "GlowType" and tableRef[key] == 3 then
		tableRef[key] = Private.Enum.GlowType.PixelGlow
		return prefix .. ": " .. Private.L.Settings.GlowTypeLabel
	end

	if key == "ShowBorder" then
		local shown = tableRef[key]
		tableRef[key] = nil
		tableRef.BorderStyle = shown and defaults.BorderStyle or "None"
		return prefix .. ": " .. Private.L.Settings.BorderStyleLabel
	end

	return nil
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

do
	function Private.Utils.MaybeApplyElvUISkin(frame) end

	if ElvUI then
		local E = unpack(ElvUI)
		local S = E:GetModule("Skins")

		S:AddCallbackForAddon(addonName, addonName, function()
			function Private.Utils.MaybeApplyElvUISkin(frame)
				S:HandleButton(frame)
			end
		end)
	end
end

do
	---@type table<string, true>
	local thirdPartyFrameNames = {}
	local registerdFrames = 0
	local hasManualThirdPartyRegistrations = false

	function Private.Utils.RegisterFrameByName(frameName)
		thirdPartyFrameNames[frameName] = true
		hasManualThirdPartyRegistrations = true
		registerdFrames = registerdFrames + 1

		return true
	end

	function Private.Utils.UnregisterFrameByName(frameName)
		if thirdPartyFrameNames[frameName] == nil then
			return false
		end

		thirdPartyFrameNames[frameName] = nil
		registerdFrames = registerdFrames - 1
		hasManualThirdPartyRegistrations = registerdFrames > 0

		if not hasManualThirdPartyRegistrations then
			table.wipe(thirdPartyFrameNames)
		end

		return true
	end

	function Private.Utils.HasThirdPartyCandidates()
		return hasManualThirdPartyRegistrations
	end

	for index = 1, C_AddOns.GetNumAddOns() do
		local meta = C_AddOns.GetAddOnMetadata(index, "X-oUF")

		if meta and _G[meta] then
			hooksecurefunc(_G[meta], "SpawnHeader", function(ref)
				for _, header in next, ref.headers do
					local headerName = header:GetName()

					if headerName and string.find(headerName, "Party") ~= nil then
						for unitIndex = 1, 5 do
							Private.Utils.RegisterFrameByName(string.format("%sUnitButton%d", headerName, unitIndex))
						end
					end
				end
			end)
		end
	end

	function Private.Utils.FindThirdPartyGroupFrameForUnit(unit)
		if Grid2 then
			return (next(Grid2:GetUnitFrames(unit)))
		end

		if VUHDO_getUnitButtons then
			local frames = VUHDO_getUnitButtons(unit)

			if frames ~= nil then
				for _, frame in pairs(frames) do
					if frame.raidid == unit and frame:IsVisible() then
						return frame
					end
				end
			end
		end

		if ShadowUF and SUFHeaderparty then
			for i = 1, 5 do
				local frame = _G["SUFHeaderpartyUnitButton" .. i]

				if frame and frame.unit == unit then
					return frame
				end
			end
		end

		if EnhanceQoL and EQOLUFPartyHeader then
			for i = 1, 5 do
				local frame = _G["EQOLUFPartyHeaderUnitButton" .. i]

				if frame and frame.unit == unit then
					return frame
				end
			end
		end

		if DandersFrames and DandersFrames.Api and DandersFrames.Api.GetFrameForUnit then
			local frame = DandersFrames.Api.GetFrameForUnit(unit, Private.Enum.FrameKind.Party)

			if frame then
				return frame
			end
		end

		if QUI then
			for i = 1, 5 do
				local frame = _G["QUI_PartyHeaderUnitButton" .. i]

				if frame and frame.unit == unit then
					return frame
				end
			end

			-- of course this vibecoded mess doesn't adhere to any standards so its using completely different
			-- frames in edit mode that also don't communicate the unit they intend to resemble. 🤡
			local id = (unit == "player" and 5 or string.gsub(unit, "party", ""))
			-- even worse, it uses two frames with the same name so you can't globally access them as needed.
			-- only occurs after opening edit mode the second time tho
			local frameName = "QUI_TestFrame" .. id
			local frame = _G[frameName]

			if frame and frame:IsShown() then
				return frame
			end

			if QUI_GroupFramesMover and QUI_GroupFramesMover:IsShown() then
				local relevantParent = select(7, QUI_GroupFramesMover:GetChildren())

				if relevantParent then
					local children = { relevantParent:GetChildren() }

					for i = 1, #children do
						local child = children[i]

						if child and child:GetName() == frameName then
							return child
						end
					end
				end
			end
		end

		if Cell then
			for i = 1, 5 do
				local frame = _G["CellPartyFrameHeaderUnitButton" .. i]

				if frame and frame.unit == unit then
					return frame
				end
			end
		end

		-- use these last, including e.g. ElvUI. people using multiple unit frame addons (god knows for what reason)
		-- _likely_ prefer using the other one over oUF derivates because what else would be the point of having them.
		if hasManualThirdPartyRegistrations then
			for frameName, bool in pairs(thirdPartyFrameNames) do
				local frame = _G[frameName]

				if frame and frame.unit == unit then
					return frame
				end
			end
		end

		return nil
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
		local resetKeys = {}

		for kind, kindString in pairs(Private.Enum.FrameKind) do
			local tableRef = TargetedSpellsSaved.Settings[kind]

			if kindString == Private.Enum.FrameKind.Self then
				local frame = editModeFrameByKind[kindString]

				local point, x, y = result[kind].Position.point, result[kind].Position.x, result[kind].Position.y

				if
					frame ~= nil
					and (point ~= tableRef.Position.point or x ~= tableRef.Position.x or y ~= tableRef.Position.y)
				then
					frame:ClearAllPoints()
					PixelUtil.SetPoint(frame, point, UIParent, "CENTER", x, y)
					tableRef.Position.point = point
					tableRef.Position.x = x
					tableRef.Position.y = y
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.EDIT_MODE_POSITION_CHANGED, point, x, y)
				end
			end

			local anyPrimaryLoadConditionIsDisabled = false

			local defaults = kindString == Private.Enum.FrameKind.Self and Private.Settings.GetSelfDefaultSettings()
				or Private.Settings.GetPartyDefaultSettings()
			local eventKeys = kindString == Private.Enum.FrameKind.Self and Private.Settings.Keys.Self
				or Private.Settings.Keys.Party

			for key, defaultValue in pairs(defaults) do
				local newValue = result[kind][key]
				local expectedType = type(defaultValue)

				if newValue ~= nil and type(newValue) == expectedType then
					local eventKey = eventKeys[key]
					local hasChanges = false

					if expectedType == "table" then
						local enumToCompareAgainst = nil
						if key == "LoadConditionContentType" then
							enumToCompareAgainst = Private.Enum.ContentType
						elseif key == "LoadConditionRole" or key == "RoleFilter" then
							enumToCompareAgainst = Private.Enum.Role
						elseif key == "FontFlags" then
							enumToCompareAgainst = Private.Enum.FontFlags
						elseif key == "FeatureFlags" then
							enumToCompareAgainst = Private.Enum.FeatureFlag
						end

						-- only other case is Position but that's taken care of above

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

							if allDisabled then
								anyPrimaryLoadConditionIsDisabled = true
							end

							if hasChanges then
								tableRef[key] = newTable

								local resetKey = Private.Utils.ApplyMigration(key, kindString, defaults)

								if resetKey then
									table.insert(resetKeys, resetKey)
								end

								Private.EventRegistry:TriggerEvent(
									Private.Enum.Events.SETTING_CHANGED,
									eventKey,
									newTable
								)
							end
						end
					elseif newValue ~= tableRef[key] then
						tableRef[key] = newValue

						local resetKey = Private.Utils.ApplyMigration(key, kindString, defaults)

						if resetKey then
							table.insert(resetKeys, resetKey)
						end

						hasChanges = true

						if eventKey and hasChanges then
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

		if #resetKeys > 0 then
			Private.Utils.ShowMigrationPopup(resetKeys, "import")
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
		RegisterFrameByName = Private.Utils.RegisterFrameByName,
		UnregisterFrameByName = Private.Utils.UnregisterFrameByName,
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
