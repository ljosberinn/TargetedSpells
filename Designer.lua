---@type string, TargetedSpells
local _, Private = ...

local LibSharedMedia = LibStub("LibSharedMedia-3.0")

local FRAME_WIDTH = 760
local FRAME_HEIGHT = 520

local DEMO_CAST_TIME = 6

local PANEL_PAD = 12
local PANEL_ROW_GAP = 6
local PANEL_LABEL_WIDTH = 92

local SettingType = {
	Boolean = "boolean",
	Number = "number",
	Color = "color",
	Enum = "enum",
	Font = "font",
	FontFlags = "fontFlags",
	Texture = "texture",
}

local Element = Private.Enum.Element

local FONT_FLAG_ORDER = { Private.Enum.FontFlags.OUTLINE, Private.Enum.FontFlags.SHADOW }

local MEDIA_MENU_MAX_HEIGHT = 400

local TEXTURE_PREVIEW_HEIGHT = 14
local TEXTURE_PREVIEW_WIDTH = 64

local previewFontCache = {}
local previewFontCounter = 0

-- ColorMixin:GenerateHexColor forwards to C_ColorUtil.GenerateTextColorCode, which forces alpha to 255.
---@param red number
---@param green number
---@param blue number
---@param alpha number
---@return string
local function ToHexString(red, green, blue, alpha)
	local r, g, b, a = CreateColor(red, green, blue, alpha):GetRGBAAsBytes()
	return ("%.2X%.2X%.2X%.2X"):format(a, r, g, b)
end

---@param path string
---@return string globalFontName
local function PreviewFontObject(path)
	if previewFontCache[path] then
		return previewFontCache[path]
	end

	previewFontCounter = previewFontCounter + 1
	local globalName = "TargetedSpellsDesignerPreviewFont" .. previewFontCounter

	local overrideAlphabet = ({
		koKR = "korean",
		zhCN = "simplifiedchinese",
		zhTW = "traditionalchinese",
		ruRU = "russian",
	})[GAME_LOCALE or GetLocale()] or "roman"

	---@type CreateFontFamilyMemberInfo[]
	local members = {}
	for _, alphabet in ipairs({ "roman", "korean", "simplifiedchinese", "traditionalchinese", "russian" }) do
		local file, size = GameFontNormal:GetFontObjectForAlphabet(alphabet):GetFont()
		members[#members + 1] = {
			alphabet = alphabet,
			file = alphabet == overrideAlphabet and path or file,
			height = size,
			flags = "",
		}
	end

	local font = CreateFontFamily(globalName, members)
	font:SetTextColor(1, 1, 1)

	previewFontCache[path] = globalName
	return globalName
end

local ELEMENT_ORDER = {
	[Private.Enum.Template.Icon] = {
		Element.Icon,
		Element.Overlay,
		Element.Cooldown,
		Element.Border,
		Element.InterruptSource,
	},
	[Private.Enum.Template.Bar] = {
		Element.ProgressBar,
		Element.Background,
		Element.Icon,
		Element.TargetMarker,
		Element.DurationCooldown,
		Element.SpellName,
		Element.TargetName,
		Element.InterruptSource,
		Element.InterruptShield,
		Element.Border,
	},
	[Private.Enum.Template.IconDuration] = {
		Element.Icon,
		Element.Duration,
		Element.Overlay,
		Element.Cooldown,
		Element.Border,
	},
}

local CORE_ELEMENT = {
	[Private.Enum.Template.Icon] = Element.Icon,
	[Private.Enum.Template.Bar] = Element.ProgressBar,
	[Private.Enum.Template.IconDuration] = Element.Icon,
}

---@class TargetedSpellsDesignerFrame : Frame
local DesignerMixin = {}

---@return integer[]
function DesignerMixin:SortedGroupIds()
	return Private.Groups.SortedIds(TargetedSpellsSaved.Groups)
end

function DesignerMixin:RebuildTabs()
	self.tabPool:ReleaseAll()
	table.wipe(self.tabs)

	local ids = self:SortedGroupIds()
	local previousTab

	for _, id in ipairs(ids) do
		local group = TargetedSpellsSaved.Groups[id]
		local tab = self.tabPool:Acquire()

		tab:SetID(id)
		tab:SetText(group.Name)
		tab:SetScript("OnClick", function(clickedTab)
			self:RequestSelectGroup(clickedTab:GetID())
		end)
		tab:Show()
		PanelTemplates_TabResize(tab, 0)

		tab:ClearAllPoints()
		if previousTab then
			tab:SetPoint("TOPLEFT", previousTab, "TOPRIGHT", 3, 0)
		else
			tab:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 11, 2)
		end

		previousTab = tab
		self.tabs[id] = tab
	end

	if self.selectedGroupId == nil or self.tabs[self.selectedGroupId] == nil then
		self.selectedGroupId = ids[1]
	end

	self:SelectGroup(self.selectedGroupId)
end

---@param groupId integer
function DesignerMixin:SelectGroup(groupId)
	local group = groupId and TargetedSpellsSaved.Groups[groupId]
	if group == nil then
		return
	end

	self.selectedGroupId = groupId

	for id, tab in pairs(self.tabs) do
		if id == groupId then
			PanelTemplates_SelectTab(tab)
		else
			PanelTemplates_DeselectTab(tab)
		end
	end

	self.scratchTemplate = group.Template
	self.scratchElements = Private.Design.CopyElements(group.Elements)
	self.dirty = false
	self:UpdateApplyState()

	self:RefreshCanvas()
end

---@param groupId integer
function DesignerMixin:RequestSelectGroup(groupId)
	if groupId == self.selectedGroupId then
		return
	end

	if self.dirty then
		self:PromptUnsavedSwitch(groupId)
	else
		self:SelectGroup(groupId)
	end
end

---@param group TargetedSpellsGroup
function DesignerMixin:GroupPool(group)
	if group.Template == Private.Enum.Template.Icon then
		return Private.Utils.Pools.Icon
	elseif group.Template == Private.Enum.Template.IconDuration then
		return Private.Utils.Pools.IconDuration
	end

	return Private.Utils.Pools.Bar
end

function DesignerMixin:RefreshCanvas()
	self:EndDemo()
	self:StartDemo()
	self:BuildMarkers()
end

function DesignerMixin:StartDemo()
	local group = self.selectedGroupId and TargetedSpellsSaved.Groups[self.selectedGroupId]

	if group == nil or not self:IsShown() then
		return
	end

	self.demoPool = self:GroupPool(group)
	self.demoFrame = self.demoPool:Acquire()

	self.demoFrame:SetGroup(group)
	self.demoFrame:SetLayoutOverride(self.scratchElements)
	self.demoFrame:SetParent(self.Preview)
	self.demoFrame:ClearAllPoints()
	self.demoFrame:SetPoint("CENTER", self.Preview, "CENTER", 0, 0)
	self.demoFrame:SetFrameStrata(self.Preview:GetFrameStrata())
	self.demoFrame:SetFrameLevel(self.Preview:GetFrameLevel() + 5)

	self.demoMarkerIndex = math.random(1, 8)

	self:PlayDemoCast()

	self.demoTicker = C_Timer.NewTicker(DEMO_CAST_TIME, function()
		self:PlayDemoCast()
	end)
end

function DesignerMixin:PlayDemoCast()
	if self.demoFrame == nil then
		return
	end

	local duration = C_DurationUtil.CreateDuration()
	duration:SetTimeFromStart(GetTime(), DEMO_CAST_TIME)

	self.demoFrame:PostCreate({
		unit = "player",
		spellId = nil,
		startTime = GetTime(),
		id = 1,
		duration = duration,
		isChannel = false,
	})

	self.demoFrame:Show()
	self.demoFrame:SetAlpha(secretwrap(1))

	if self.demoFrame.SetPreviewBarColor then
		self.demoFrame:SetPreviewBarColor()
	end

	self:PopulateDemoContent()

	local group = self.selectedGroupId and TargetedSpellsSaved.Groups[self.selectedGroupId]
	if group ~= nil and group.GlowImportant then
		self.demoFrame:ShowGlow(self.demoFrame:IsSpellImportant(Private.Utils.RollDice()))
	else
		self.demoFrame:HideGlow()
	end
end

function DesignerMixin:PopulateDemoContent()
	local frame = self.demoFrame
	if frame == nil then
		return
	end

	local playerName = UnitName("player")
	local _, classToken = UnitClass("player")
	local classColor = classToken and C_ClassColor.GetClassColor(classToken)

	if frame.ProgressBar then
		self:StyleDemoText(frame.ProgressBar.TargetName, self.scratchElements[Element.TargetName], playerName, classColor)
		self:StyleDemoText(frame.ProgressBar.InterruptSource, self.scratchElements[Element.InterruptSource], playerName,
			classColor)

		frame:ApplySpellNameWidth()

		local shield = self.scratchElements[Element.InterruptShield]
		frame.CustomElementsFrame.InterruptShield:Show()
		frame.CustomElementsFrame.InterruptShield:SetAlphaFromBoolean(secretwrap(shield ~= nil and shield.active == true))
	else
		self:StyleDemoText(frame.InterruptSource, self.scratchElements[Element.InterruptSource], playerName, classColor)
	end

	if frame.SetTargetMarker then
		frame:SetTargetMarker(self.demoMarkerIndex)
	end
end

---@param region FontString?
---@param element table<string, any>?
---@param sampleText string
---@param classColor colorRGB?
function DesignerMixin:StyleDemoText(region, element, sampleText, classColor)
	if region == nil then
		return
	end

	if element == nil or element.active == false then
		region:Hide()
		return
	end

	region:SetText(sampleText)

	if element.useClassColor and classColor then
		region:SetTextColor(classColor.r, classColor.g, classColor.b)
	elseif element.textColor then
		local color = CreateColorFromHexString(element.textColor)
		region:SetTextColor(color.r, color.g, color.b, color.a)
	end

	region:Show()
end

function DesignerMixin:EndDemo()
	if self.demoTicker ~= nil then
		self.demoTicker:Cancel()
		self.demoTicker = nil
	end

	if self.demoFrame ~= nil then
		self.demoPool:Release(self.demoFrame)
		self.demoFrame = nil
	end
end

---@param record table<string, any>
---@param tag Element?
---@param layout table?
function DesignerMixin:ElementMarkerRect(record, tag, layout)
	if layout ~= nil then
		local geom = layout[tag]
		if geom == nil then
			return nil -- footprint-less element, or an inactive gutter slot (no marker)
		end

		if geom.text then
			local width = (geom.maxWidth ~= nil and geom.maxWidth > 0) and geom.maxWidth or 120
			local x = geom.edgeX
			if geom.justifyH == "LEFT" then
				x = x + width / 2
			elseif geom.justifyH == "RIGHT" then
				x = x - width / 2
			end
			return x, geom.centerY, width, (geom.fontSize or record.fontSize or 0) * 1.8
		end

		return geom.centerX, geom.centerY, geom.width, geom.height
	end

	local x = record.x or 0
	local y = record.y or 0

	if record.width ~= nil and record.height ~= nil then
		return x, y, record.width, record.height
	end

	if record.fontSize ~= nil then
		local capped = record.maxWidth ~= nil and record.maxWidth > 0
		local width = capped and record.maxWidth or 120

		local justifyH = record.justifyH or "CENTER"
		if justifyH == "LEFT" then
			x = x + width / 2
		elseif justifyH == "RIGHT" then
			x = x - width / 2
		end

		return x, y, width, record.fontSize * 1.8
	end

	return nil
end

function DesignerMixin:ScratchLayout()
	if self.scratchElements == nil then
		return nil
	end

	if self.scratchTemplate == Private.Enum.Template.Bar then
		return Private.Utils.ComputeBarLayout(self.scratchElements)
	elseif self.scratchTemplate == Private.Enum.Template.IconDuration then
		return Private.Utils.ComputeIconDurationLayout(self.scratchElements)
	end

	return nil
end

---@param marker Button
function DesignerMixin:EnsureMarkerVisuals(marker)
	if marker.SelectedBorder ~= nil then
		return
	end

	marker:RegisterForClicks("LeftButtonUp")

	local highlight = marker:CreateTexture(nil, "HIGHLIGHT")
	highlight:SetAllPoints()
	highlight:SetColorTexture(1, 1, 1, 0.10)

	marker.SelectedBorder = {}
	local edges = {
		{ points = { "TOPLEFT", "TOPRIGHT" },       height = 2 },
		{ points = { "BOTTOMLEFT", "BOTTOMRIGHT" }, height = 2 },
		{ points = { "TOPLEFT", "BOTTOMLEFT" },     width = 2 },
		{ points = { "TOPRIGHT", "BOTTOMRIGHT" },   width = 2 },
	}

	for _, edge in ipairs(edges) do
		local line = marker:CreateTexture(nil, "OVERLAY")
		line:SetColorTexture(1, 0.82, 0, 0.9)
		line:SetPoint(edge.points[1])
		line:SetPoint(edge.points[2])

		if edge.height ~= nil then
			line:SetHeight(edge.height)
		else
			line:SetWidth(edge.width)
		end

		line:Hide()
		table.insert(marker.SelectedBorder, line)
	end
end

function DesignerMixin:BuildMarkers()
	self.selectorPool:ReleaseAll()
	table.wipe(self.markers)

	if self.scratchElements == nil then
		return
	end

	local layout = self:ScratchLayout()

	for elementTag in pairs(Private.Design.GetSchema(self.scratchTemplate)) do
		local record = self.scratchElements[elementTag]
		local x, y, width, height = nil, nil, nil, nil

		if record ~= nil then
			x, y, width, height = self:ElementMarkerRect(record, elementTag, layout)
		end

		if width ~= nil then
			local marker = self.selectorPool:Acquire()
			self:EnsureMarkerVisuals(marker)

			marker.element = elementTag
			marker:ClearAllPoints()
			PixelUtil.SetSize(marker, width, height)
			PixelUtil.SetPoint(marker, "CENTER", self.Preview, "CENTER", x, y)
			local areaLevel = math.min(200, math.floor(50000 / math.max(1, width * height)))
			marker:SetFrameLevel(self.Preview:GetFrameLevel() + 20 + areaLevel)
			marker:SetScript("OnClick", function(clicked)
				self:SelectElement(clicked.element)
			end)
			marker:Show()

			self.markers[elementTag] = marker
		end
	end

	local schema = Private.Design.GetSchema(self.scratchTemplate)
	if self.selectedElement == nil or schema[self.selectedElement] == nil then
		self.selectedElement = CORE_ELEMENT[self.scratchTemplate]
	end

	self:SelectElement(self.selectedElement)
end

---@param elementTag Element
function DesignerMixin:SelectElement(elementTag)
	self.selectedElement = elementTag

	for tag, marker in pairs(self.markers) do
		local isSelected = tag == elementTag
		for _, line in ipairs(marker.SelectedBorder) do
			line:SetShown(isSelected)
		end
	end

	self:RefreshElementDropdown()
	self:BuildPanel()
end

function DesignerMixin:SetupElementDropdown()
	self.Panel.ElementDropdown:SetupMenu(function(_, rootDescription)
		local order = self.scratchTemplate and ELEMENT_ORDER[self.scratchTemplate]
		if order == nil then
			return
		end

		for _, elementTag in ipairs(order) do
			rootDescription:CreateRadio(
				Private.L.Designer.ElementNames[elementTag] or elementTag,
				function()
					return self.selectedElement == elementTag
				end,
				function()
					self:SelectElement(elementTag)
				end
			)
		end
	end)
end

function DesignerMixin:RefreshElementDropdown()
	if self.Panel.ElementDropdown ~= nil then
		self.Panel.ElementDropdown:GenerateMenu()
	end
end

---@return integer[]
function DesignerMixin:CopyableSourceGroups()
	local sources = {}

	for _, id in ipairs(self:SortedGroupIds()) do
		local group = TargetedSpellsSaved.Groups[id]
		if id ~= self.selectedGroupId and group.Template == self.scratchTemplate then
			sources[#sources + 1] = id
		end
	end

	return sources
end

function DesignerMixin:SetupCopyFromDropdown()
	local dropdown = self.Preview.CopyFromDropdown

	dropdown:SetupMenu(function(_, rootDescription)
		local sources = self:CopyableSourceGroups()

		if #sources == 0 then
			rootDescription:CreateTitle(Private.L.Designer.CopyFromEmpty)
			return
		end

		for _, id in ipairs(sources) do
			local group = TargetedSpellsSaved.Groups[id]
			rootDescription:CreateButton(group.Name, function()
				self:CopyLayoutFromGroup(id)
			end)
		end
	end)

	dropdown:OverrideText(Private.L.Designer.CopyFrom)
end

---@param sourceGroupId integer
function DesignerMixin:CopyLayoutFromGroup(sourceGroupId)
	local source = TargetedSpellsSaved.Groups[sourceGroupId]
	if source == nil or source.Template ~= self.scratchTemplate then
		return
	end

	self.scratchElements = Private.Design.CopyElements(source.Elements)
	self:MarkDirty()
	self:RefreshCanvas()
end

---@return table<string, any>?
function DesignerMixin:SelectedScratchRecord()
	if self.selectedElement == nil or self.scratchElements == nil then
		return nil
	end
	return self.scratchElements[self.selectedElement]
end

---@param record table
function DesignerMixin:SettingLabel(record)
	return Private.L.Designer.SettingNames[record.name] or record.name
end

---@param option { value: any, name: string }
function DesignerMixin:OptionLabel(option)
	return Private.L.Designer.Options[option.name] or _G[option.name] or option.name
end

---@param widget Frame
function DesignerMixin:WidgetLabel(widget)
	if widget.tsLabel == nil then
		widget.tsLabel = widget:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	end
	widget.tsLabel:Show()
	return widget.tsLabel
end

---@param setting string
---@param value any
function DesignerMixin:OnWidgetValueChanged(setting, value)
	if self.buildingPanel then
		return
	end

	local record = self:SelectedScratchRecord()
	if record == nil then
		return
	end

	if record[setting] == value then
		return
	end

	record[setting] = value
	Private.Utils.InvalidateLayout(self.scratchElements)
	self:ApplyScratchToDemo()

	if setting == "active" and self.scratchTemplate == Private.Enum.Template.Bar then
		self:BuildMarkers()
	else
		self:UpdateMarkerRects()
	end

	self:MarkDirty()
end

---@param record table
---@param yOffset number
function DesignerMixin:BuildCheckbox(record, yOffset)
	local checkbox = self.widgetPools[SettingType.Boolean]:Acquire()

	local label = self:WidgetLabel(checkbox)
	label:ClearAllPoints()
	label:SetPoint("RIGHT", checkbox, "LEFT", -6, 0)
	label:SetWidth(PANEL_LABEL_WIDTH)
	label:SetJustifyH("RIGHT")
	label:SetText(self:SettingLabel(record))

	checkbox:ClearAllPoints()
	checkbox:SetPoint("TOPLEFT", self.Panel.Content, "TOPLEFT", PANEL_PAD + PANEL_LABEL_WIDTH + 10, -yOffset)
	checkbox:SetChecked(self:SelectedScratchRecord()[record.setting] == true)
	checkbox:SetScript("OnClick", function(box)
		self:OnWidgetValueChanged(record.setting, box:GetChecked() and true or false)
	end)
	checkbox:Show()

	return 26
end

---@param record table
---@param yOffset number
function DesignerMixin:BuildSlider(record, yOffset)
	local slider = self.widgetPools[SettingType.Number]:Acquire()
	local controlWidth = self.Panel.Content:GetWidth() - 2 * PANEL_PAD

	local label = self:WidgetLabel(slider)
	label:ClearAllPoints()
	label:SetPoint("BOTTOMLEFT", slider, "TOPLEFT", 0, 2)
	label:SetWidth(controlWidth)
	label:SetJustifyH("LEFT")
	label:SetText(self:SettingLabel(record))

	slider:ClearAllPoints()
	slider:SetPoint("TOPLEFT", self.Panel.Content, "TOPLEFT", PANEL_PAD, -yOffset - 16)
	slider:SetWidth(controlWidth)

	local numberFormat = record.step < 1 and "%.2f" or "%d"
	local steps = math.max(1, math.floor((record.max - record.min) / record.step + 0.5))
	local formatters = {
		[MinimalSliderWithSteppersMixin.Label.Top] = function(value)
			return string.format(numberFormat, value)
		end,
		[MinimalSliderWithSteppersMixin.Label.Min] = function()
			return string.format(numberFormat, record.min)
		end,
		[MinimalSliderWithSteppersMixin.Label.Max] = function()
			return string.format(numberFormat, record.max)
		end,
	}

	slider:Init(self:SelectedScratchRecord()[record.setting] or record.default, record.min, record.max, steps, formatters)

	slider.Slider:SetScript("OnValueChanged", function(_, value)
		slider:FormatValue(value)
		self:OnWidgetValueChanged(record.setting, math.floor(value / record.step + 0.5) * record.step)
	end)

	slider:Show()

	return 52
end

---@param record table
---@param yOffset number
---@param poolKey string?
function DesignerMixin:AcquireDropdownRow(record, yOffset, poolKey)
	local dropdown = self.widgetPools[poolKey or SettingType.Enum]:Acquire()
	local controlX = PANEL_PAD + PANEL_LABEL_WIDTH + 10
	local controlWidth = self.Panel.Content:GetWidth() - controlX - PANEL_PAD

	local label = self:WidgetLabel(dropdown)
	label:ClearAllPoints()
	label:SetPoint("RIGHT", dropdown, "LEFT", -6, 0)
	label:SetWidth(PANEL_LABEL_WIDTH)
	label:SetJustifyH("RIGHT")
	label:SetText(self:SettingLabel(record))

	dropdown:ClearAllPoints()
	dropdown:SetPoint("TOPLEFT", self.Panel.Content, "TOPLEFT", controlX, -yOffset)
	dropdown:SetWidth(controlWidth)

	return dropdown
end

---@param dropdown table
---@param setting string
---@param options table[] each { value = any, label = string }
-- Builds the radio menu for an enum / texture / font dropdown. An option may carry
-- an inline preview: `option.texture` (a resolved media path) prefixes the label with
-- a |T texture escape; `option.font` (a font path) renders that row's label in the
-- font itself. Both mirror AdvancedFocusCastBar's media pickers.
function DesignerMixin:PopulateRadioMenu(dropdown, setting, options)
	dropdown:SetupMenu(function(_, rootDescription)
		if #options > 12 then
			rootDescription:SetScrollMode(MEDIA_MENU_MAX_HEIGHT)
		end

		for _, option in ipairs(options) do
			local label = option.label
			if option.texture then
				label = string.format("|T%s:%d:%d|t %s", option.texture, TEXTURE_PREVIEW_HEIGHT, TEXTURE_PREVIEW_WIDTH,
					option.label)
			end

			local radio = rootDescription:CreateRadio(label, function()
				return self:SelectedScratchRecord()[setting] == option.value
			end, function()
				self:OnWidgetValueChanged(setting, option.value)
			end)

			if option.font then
				radio:AddInitializer(function(button)
					button.fontString:SetFontObject(PreviewFontObject(option.font))
				end)
			end
		end
	end)

	dropdown:Show()
end

---@param record table
---@param yOffset number
function DesignerMixin:BuildDropdown(record, yOffset)
	local dropdown = self:AcquireDropdownRow(record, yOffset)

	local options = {}
	for _, option in ipairs(record.options) do
		options[#options + 1] = { value = option.value, label = self:OptionLabel(option) }
	end

	self:PopulateRadioMenu(dropdown, record.setting, options)

	return 30
end

---@param record table
---@param yOffset number
function DesignerMixin:BuildTextureDropdown(record, yOffset)
	local dropdown = self:AcquireDropdownRow(record, yOffset)

	local options = {}
	for _, name in ipairs(self:MediaNameList(record.mediaType)) do
		-- inline texture preview: the stored value is the LSM name; Fetch resolves the
		-- path the |T escape needs (record.mediaType == the LSM MediaType string)
		options[#options + 1] = { value = name, label = name, texture = LibSharedMedia:Fetch(record.mediaType, name) }
	end

	self:PopulateRadioMenu(dropdown, record.setting, options)

	return 30
end

---@param record table
---@param yOffset number
function DesignerMixin:BuildFontDropdown(record, yOffset)
	local dropdown = self:AcquireDropdownRow(record, yOffset)
	local fontInfo = Private.Settings.GetFontOptions()

	local options = {}
	for _, name in ipairs(fontInfo.fonts) do
		local path = fontInfo.byLabel[name]
		options[#options + 1] = { value = path, label = name, font = path }
	end

	self:PopulateRadioMenu(dropdown, record.setting, options)

	return 30
end

---@param record table
---@param yOffset number
function DesignerMixin:BuildFontFlagsDropdown(record, yOffset)
	local dropdown = self:AcquireDropdownRow(record, yOffset, SettingType.FontFlags)
	local flags = self:SelectedScratchRecord()[record.setting]

	dropdown:SetupMenu(function(_, rootDescription)
		for _, flag in ipairs(FONT_FLAG_ORDER) do
			rootDescription:CreateCheckbox(Private.L.Designer.FontFlagNames[flag], function()
				return flags[flag] == true
			end, function()
				flags[flag] = not flags[flag]
				self:OnFontFlagChanged(dropdown, record)
			end)
		end
	end)

	dropdown:OverrideText(self:FontFlagsSummary(flags))
	dropdown:Show()

	return 30
end

---@param flags table<integer, boolean>
function DesignerMixin:FontFlagsSummary(flags)
	local parts = {}
	for _, flag in ipairs(FONT_FLAG_ORDER) do
		if flags[flag] then
			parts[#parts + 1] = Private.L.Designer.FontFlagNames[flag]
		end
	end

	if #parts == 0 then
		return Private.L.Designer.FontFlagsNone
	end

	return table.concat(parts, ", ")
end

---@param dropdown table
---@param record table
function DesignerMixin:OnFontFlagChanged(dropdown, record)
	if self.buildingPanel then
		return
	end

	dropdown:OverrideText(self:FontFlagsSummary(self:SelectedScratchRecord()[record.setting]))
	Private.Utils.InvalidateLayout(self.scratchElements)
	self:ApplyScratchToDemo()
	self:UpdateMarkerRects()
	self:MarkDirty()
end

---@param mediaType string
---@return string[]
function DesignerMixin:MediaNameList(mediaType)
	if mediaType == "statusbar" then
		return Private.Settings.GetStatusBarOptions()
	elseif mediaType == "background" then
		return Private.Settings.GetBackgroundOptions()
	elseif mediaType == "border" then
		return Private.Settings.GetBorderOptions()
	end

	return {}
end

---@param record table
---@param yOffset number
function DesignerMixin:BuildColorSwatch(record, yOffset)
	local swatch = self.widgetPools[SettingType.Color]:Acquire()

	local label = self:WidgetLabel(swatch)
	label:ClearAllPoints()
	label:SetPoint("RIGHT", swatch, "LEFT", -6, 0)
	label:SetWidth(PANEL_LABEL_WIDTH)
	label:SetJustifyH("RIGHT")
	label:SetText(self:SettingLabel(record))

	swatch:ClearAllPoints()
	swatch:SetPoint("TOPLEFT", self.Panel.Content, "TOPLEFT", PANEL_PAD + PANEL_LABEL_WIDTH + 10, -yOffset)

	local color = CreateColorFromHexString(self:SelectedScratchRecord()[record.setting] or record.default)
	swatch:SetColorRGB(color.r, color.g, color.b)

	swatch:EnableMouse(true)
	swatch:SetScript("OnMouseUp", function()
		self:OpenColorPicker(record, swatch)
	end)
	swatch:Show()

	return 24
end

---@param record table
---@param swatch table
function DesignerMixin:OpenColorPicker(record, swatch)
	local startColor = CreateColorFromHexString(self:SelectedScratchRecord()[record.setting] or record.default)

	-- SetupColorPickerAndShow fires OnColorSelect before OnShow applies the requested opacity, so the
	-- first callback would otherwise commit whatever alpha the picker was left on by a previous swatch.
	local ready = false

	local function Commit()
		if not ready then
			return
		end

		local r, g, b = ColorPickerFrame:GetColorRGB()
		local a = ColorPickerFrame:GetColorAlpha()
		swatch:SetColorRGB(r, g, b)
		self:OnWidgetValueChanged(record.setting, ToHexString(r, g, b, a))
	end

	ColorPickerFrame:SetupColorPickerAndShow({
		r = startColor.r,
		g = startColor.g,
		b = startColor.b,
		opacity = startColor.a,
		hasOpacity = true,
		swatchFunc = Commit,
		opacityFunc = Commit,
		cancelFunc = function(previous)
			swatch:SetColorRGB(previous.r, previous.g, previous.b)
			self:OnWidgetValueChanged(record.setting, ToHexString(previous.r, previous.g, previous.b, previous.a))
		end,
	})

	ready = true
end

---@param record table
---@param yOffset number
function DesignerMixin:BuildPlaceholder(record, yOffset)
	local row = self.widgetPools.placeholder:Acquire()
	row:ClearAllPoints()
	row:SetPoint("TOPLEFT", self.Panel.Content, "TOPLEFT", PANEL_PAD, -yOffset)
	row:SetSize(self.Panel.Content:GetWidth() - 2 * PANEL_PAD, 18)

	local label = self:WidgetLabel(row)
	label:ClearAllPoints()
	label:SetPoint("LEFT", row, "LEFT", 0, 0)
	label:SetWidth(row:GetWidth())
	label:SetJustifyH("LEFT")
	label:SetText(self:SettingLabel(record) .. "  |cff808080(editing soon)|r")

	row:Show()

	return 20
end

---@param record table
---@param yOffset number
function DesignerMixin:BuildWidget(record, yOffset)
	if record.type == SettingType.Boolean then
		return self:BuildCheckbox(record, yOffset)
	elseif record.type == SettingType.Number then
		return self:BuildSlider(record, yOffset)
	elseif record.type == SettingType.Enum then
		return self:BuildDropdown(record, yOffset)
	elseif record.type == SettingType.Color then
		return self:BuildColorSwatch(record, yOffset)
	elseif record.type == SettingType.Texture then
		return self:BuildTextureDropdown(record, yOffset)
	elseif record.type == SettingType.Font then
		return self:BuildFontDropdown(record, yOffset)
	elseif record.type == SettingType.FontFlags then
		return self:BuildFontFlagsDropdown(record, yOffset)
	end

	return self:BuildPlaceholder(record, yOffset)
end

function DesignerMixin:BuildPanel()
	self.buildingPanel = true

	for _, pool in pairs(self.widgetPools) do
		pool:ReleaseAll()
	end

	local record = self:SelectedScratchRecord()
	if record == nil then
		self.buildingPanel = false
		return
	end

	self.Panel.Content:SetWidth(self.Panel.Scroll:GetWidth())

	local yOffset = 8

	for _, schemaRecord in ipairs(Private.Design.GetSchema(self.scratchTemplate)[self.selectedElement]) do
		yOffset = yOffset + self:BuildWidget(schemaRecord, yOffset) + PANEL_ROW_GAP
	end

	self.Panel.Content:SetHeight(yOffset + 8)
	self.Panel.Scroll:UpdateScrollChildRect()

	self.buildingPanel = false
end

function DesignerMixin:ResetSelectedElement()
	if self.selectedElement == nil or self.scratchElements == nil or self.scratchTemplate == nil then
		return
	end

	local defaultRecord = Private.Design.GetDefault(self.scratchTemplate)[self.selectedElement]
	if defaultRecord == nil then
		return
	end

	self.scratchElements[self.selectedElement] = defaultRecord
	Private.Utils.InvalidateLayout(self.scratchElements)
	self:ApplyScratchToDemo()
	self:BuildMarkers()
	self:MarkDirty()
end

function DesignerMixin:ApplyScratchToDemo()
	if self.demoFrame == nil then
		return
	end

	self.demoFrame:ApplyLayout()

	self.demoFrame:OnSizeChanged()

	local previousTexture = self.demoFrame.Icon and self.demoFrame.Icon:GetTexture()
	self.demoFrame:SetSpellId(self.demoFrame:GetSpellId())
	if previousTexture ~= nil then
		self.demoFrame:SetIconTexture(previousTexture)
	end

	if self.demoFrame.SetPreviewBarColor then
		self.demoFrame:SetPreviewBarColor()
	end

	self:PopulateDemoContent()
end

function DesignerMixin:UpdateMarkerRects()
	local layout = self:ScratchLayout()

	for elementTag, marker in pairs(self.markers) do
		local record = self.scratchElements[elementTag]

		if record ~= nil then
			local x, y, width, height = self:ElementMarkerRect(record, elementTag, layout)

			if width ~= nil then
				marker:Show()
				PixelUtil.SetSize(marker, width, height)
				marker:ClearAllPoints()
				PixelUtil.SetPoint(marker, "CENTER", self.Preview, "CENTER", x, y)
			else
				marker:Hide()
			end
		end
	end
end

function DesignerMixin:MarkDirty()
	self.dirty = true
	self:UpdateApplyState()
end

function DesignerMixin:UpdateApplyState()
	if self.ApplyButton == nil then
		return
	end
	self.ApplyButton:SetEnabled(self.dirty == true)
	self.RevertButton:SetEnabled(self.dirty == true)
end

function DesignerMixin:ApplyScratch()
	local group = self.selectedGroupId and TargetedSpellsSaved.Groups[self.selectedGroupId]
	if group == nil or self.scratchElements == nil then
		return
	end

	group.Elements = Private.Design.CopyElements(self.scratchElements)
	self.dirty = false
	self:UpdateApplyState()

	Private.EventRegistry:TriggerEvent(Private.Enum.Events.GROUP_CHANGED, self.selectedGroupId)
end

function DesignerMixin:RevertScratch()
	local group = self.selectedGroupId and TargetedSpellsSaved.Groups[self.selectedGroupId]
	if group == nil then
		return
	end

	self.scratchTemplate = group.Template
	self.scratchElements = Private.Design.CopyElements(group.Elements)
	self.dirty = false
	self:UpdateApplyState()
	self:RefreshCanvas()
end

---@param groupId integer
function DesignerMixin:PromptUnsavedSwitch(groupId)
	Private.Utils.ShowStaticPopup({
		text = Private.L.Designer.UnsavedPrompt,
		button1 = SAVE,
		button2 = CANCEL,
		button3 = Private.L.Designer.Discard,
		OnAccept = function()
			self:ApplyScratch()
			self:SelectGroup(groupId)
		end,
		OnAlt = function()
			self:SelectGroup(groupId)
		end,
	})
end

function DesignerMixin:OnDesignerHide()
	self:EndDemo()

	if not self.dirty then
		return
	end

	Private.Utils.ShowStaticPopup({
		text = Private.L.Designer.UnsavedPrompt,
		button1 = SAVE,
		button2 = Private.L.Designer.Discard,
		OnAccept = function()
			self:ApplyScratch()
		end,
		OnCancel = function()
			self:RevertScratch()
		end,
	})
end

function DesignerMixin:Initialize()
	self.Canvas = CreateFrame("Frame", nil, self, "InsetFrameTemplate")
	self.Canvas:SetPoint("TOPLEFT", self, "TOPLEFT", 12, -32)
	self.Canvas:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -12, 42)
	self.Canvas:SetFrameLevel(self:GetFrameLevel() + 10)

	self.ApplyButton = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
	self.ApplyButton:SetSize(130, 22)
	self.ApplyButton:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -12, 12)
	self.ApplyButton:SetText(Private.L.Designer.Apply)
	self.ApplyButton:SetScript("OnClick", function()
		self:ApplyScratch()
	end)

	self.RevertButton = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
	self.RevertButton:SetSize(100, 22)
	self.RevertButton:SetPoint("RIGHT", self.ApplyButton, "LEFT", -6, 0)
	self.RevertButton:SetText(Private.L.Designer.Revert)
	self.RevertButton:SetScript("OnClick", function()
		self:RevertScratch()
	end)

	self.UnsavedHint = self:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
	self.UnsavedHint:SetPoint("LEFT", self, "BOTTOMLEFT", 14, 23)
	self.UnsavedHint:SetText(Private.L.Designer.UnsavedHint)

	self.Panel = CreateFrame("Frame", nil, self.Canvas, "InsetFrameTemplate")
	self.Panel:SetPoint("TOPRIGHT", self.Canvas, "TOPRIGHT", -6, -6)
	self.Panel:SetPoint("BOTTOMRIGHT", self.Canvas, "BOTTOMRIGHT", -6, 6)
	self.Panel:SetWidth(260)

	self.Panel.Header = self.Panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	self.Panel.Header:SetPoint("TOP", self.Panel, "TOP", 0, -8)
	self.Panel.Header:SetText(Private.L.Designer.ElementPickerLabel)

	self.Panel.ElementDropdown = CreateFrame("DropdownButton", nil, self.Panel, "WowStyle1DropdownTemplate")
	self.Panel.ElementDropdown:SetPoint("TOP", self.Panel.Header, "BOTTOM", 0, -4)
	self.Panel.ElementDropdown:SetWidth(self.Panel:GetWidth() - 24)
	self:SetupElementDropdown()

	self.Panel.ResetButton = CreateFrame("Button", nil, self.Panel, "UIPanelButtonTemplate")
	self.Panel.ResetButton:SetSize(140, 22)
	self.Panel.ResetButton:SetPoint("BOTTOM", self.Panel, "BOTTOM", 0, 8)
	self.Panel.ResetButton:SetText(Private.L.Designer.ResetElement)
	self.Panel.ResetButton:SetScript("OnClick", function()
		self:ResetSelectedElement()
	end)

	self.Panel.Scroll = CreateFrame("ScrollFrame", nil, self.Panel, "ScrollFrameTemplate")
	self.Panel.Scroll:SetPoint("TOPLEFT", self.Panel, "TOPLEFT", 8, -56)
	self.Panel.Scroll:SetPoint("BOTTOMRIGHT", self.Panel, "BOTTOMRIGHT", -20, 38)
	self.Panel.Scroll.ScrollBar:SetHideIfUnscrollable(true)
	self.Panel.Content = CreateFrame("Frame", nil, self.Panel.Scroll)
	self.Panel.Content:SetSize(1, 1)
	self.Panel.Scroll:SetScrollChild(self.Panel.Content)
	self.Panel.Scroll:EnableMouseWheel(true)

	self.Preview = CreateFrame("Frame", nil, self.Canvas)
	self.Preview:SetPoint("TOPLEFT", self.Canvas, "TOPLEFT", 6, -6)
	self.Preview:SetPoint("BOTTOMRIGHT", self.Panel, "BOTTOMLEFT", -6, 6)

	self.Preview.Hint = self.Preview:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
	self.Preview.Hint:SetPoint("BOTTOM", self.Preview, "BOTTOM", 0, 6)
	self.Preview.Hint:SetText(Private.L.Designer.SelectHint)

	self.Preview.CopyFromDropdown = CreateFrame("DropdownButton", nil, self.Preview, "WowStyle1DropdownTemplate")
	self.Preview.CopyFromDropdown:SetPoint("TOPLEFT", self.Preview, "TOPLEFT", 4, -4)
	self.Preview.CopyFromDropdown:SetWidth(200)
	self.Preview.CopyFromDropdown:SetFrameLevel(self.Preview:GetFrameLevel() + 500)
	self:SetupCopyFromDropdown()

	self.selectorPool = CreateFramePool("Button", self.Preview, nil, function(_, marker)
		marker:Hide()
		marker:ClearAllPoints()
		marker:SetScript("OnClick", nil)
		if marker.SelectedBorder ~= nil then
			for _, line in ipairs(marker.SelectedBorder) do
				line:Hide()
			end
		end
	end)
	---@type table<Element, Button>
	self.markers = {}
	self.selectedElement = nil

	local function HideWidget(_, widget)
		widget:Hide()
		widget:ClearAllPoints()
		-- a pooled slider keeps the OnValueChanged we set; clear it so a later Init on
		-- a different setting can't fire the stale handler
		if widget.Slider ~= nil then
			widget.Slider:SetScript("OnValueChanged", nil)
		end
	end
	self.widgetPools = {
		[SettingType.Boolean] = CreateFramePool("CheckButton", self.Panel.Content, "UICheckButtonTemplate", HideWidget),
		[SettingType.Number] = CreateFramePool("Frame", self.Panel.Content, "MinimalSliderWithSteppersTemplate",
			HideWidget),
		[SettingType.Enum] = CreateFramePool("DropdownButton", self.Panel.Content, "WowStyle1DropdownTemplate",
			HideWidget),
		[SettingType.FontFlags] = CreateFramePool("DropdownButton", self.Panel.Content, "WowStyle1DropdownTemplate",
			HideWidget),
		[SettingType.Color] = CreateFramePool("Frame", self.Panel.Content, "ColorSwatchTemplate", HideWidget),
		placeholder = CreateFramePool("Frame", self.Panel.Content, nil, HideWidget),
	}

	self.tabPool = CreateFramePool("Button", self, "PanelTabButtonTemplate")
	---@type table<integer, Button>
	self.tabs = {}
	self.selectedGroupId = nil
	self.dirty = false
	self:UpdateApplyState()

	self:SetScript("OnShow", self.RebuildTabs)
	self:HookScript("OnHide", self.OnDesignerHide)

	local function RebuildIfShown()
		if self:IsShown() then
			self:RebuildTabs()
		end
	end
	Private.EventRegistry:RegisterCallback(Private.Enum.Events.GROUP_CHANGED, RebuildIfShown)
	Private.EventRegistry:RegisterCallback(Private.Enum.Events.PROFILE_IMPORTED, RebuildIfShown)
end

---@class TargetedSpellsDesigner
Private.Designer = {}

do
	---@type TargetedSpellsDesignerFrame?
	local designerFrame

	function Private.Designer.Toggle()
		if designerFrame == nil then
			designerFrame = CreateFrame("Frame", "TargetedSpellsDesigner", UIParent, "ButtonFrameTemplate")

			ButtonFrameTemplate_HidePortrait(designerFrame)
			ButtonFrameTemplate_HideButtonBar(designerFrame)
			designerFrame.Inset:Hide()

			designerFrame:SetTitle(Private.L.Designer.Title)
			designerFrame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
			designerFrame:SetPoint("CENTER")
			designerFrame:SetFrameStrata("HIGH")
			designerFrame:SetClampedToScreen(true)
			designerFrame:SetMovable(true)
			designerFrame:EnableMouse(true)
			designerFrame:RegisterForDrag("LeftButton")
			designerFrame:SetScript("OnDragStart", designerFrame.StartMoving)
			designerFrame:SetScript("OnDragStop", designerFrame.StopMovingOrSizing)

			table.insert(UISpecialFrames, designerFrame:GetName())

			Mixin(designerFrame, DesignerMixin)
			designerFrame:Initialize()

			designerFrame:Hide()
		end

		designerFrame:SetShown(not designerFrame:IsShown())
	end
end

Private.Utils.RegisterSlashCommand("design", Private.L.SlashCommands.DesignDescription, function()
	Private.Designer.Toggle()
end)
