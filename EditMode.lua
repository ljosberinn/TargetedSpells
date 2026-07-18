---@type string, TargetedSpells
local addonName, Private = ...
local LibEditMode = LibStub("LibEditMode")

---@class TargetedSpellsEditModeMixin
local TargetedSpellsEditModeMixin = {}

---@param group TargetedSpellsGroup
function TargetedSpellsEditModeMixin:Init(group)
	self.group = group
	self.groupId = group.Id
	self.displayName = group.Name
	self.pool = self:GroupTemplatePool()
	self.maxFrames = 5
	self.demoPlaying = false
	self.frames = {}
	self.demoTimers = {
		tickers = {},
		timers = {},
	}

	-- stable, unique global frame name (independent of the user-editable Name)
	self.editModeFrame = CreateFrame("Frame", "TargetedSpellsGroupEditMode" .. group.Id, UIParent)
	self.editModeFrame:SetClampedToScreen(true)
	-- some addons such as BetterCooldownManager toggle the edit mode briefly on login/loading screen end
	-- which would toggle demos on our end. by flipping this bool, we can avoid that entirely, speeding up load time
	self.editModeFrame.firstFrameTimestamp = 0

	self.editModeFrame:RegisterEvent("FIRST_FRAME_RENDERED")
	self.editModeFrame:SetScript("OnEvent", function(frameSelf)
		frameSelf.firstFrameTimestamp = GetTime()
		frameSelf:SetScript("OnEvent", nil)
		frameSelf:UnregisterAllEvents()
	end)

	Private.Utils.RegisterEditModeFrame(group.Id, self.editModeFrame)
	Private.EventRegistry:RegisterCallback(Private.Enum.Events.GROUP_CHANGED, self.OnGroupChanged, self)
	Private.EventRegistry:RegisterCallback(Private.Enum.Events.PROFILE_IMPORTED, self.OnProfileImported, self)
	LibEditMode:RegisterCallback("enter", GenerateClosure(self.StartDemo, self))
	LibEditMode:RegisterCallback("exit", GenerateClosure(self.EndDemo, self))

	self:AppendSettings()
	self:RestoreEditModePosition()
	self:ResizeEditModeFrame()
end

function TargetedSpellsEditModeMixin:IsPastLoadingScreen()
	return (GetTime() - self.editModeFrame.firstFrameTimestamp) > 1
end

function TargetedSpellsEditModeMixin:CreateImportExportButtons()
	return {
		{
			click = function()
				self:OnImportButtonClick()
			end,
			text = Private.L.Settings.Import,
		},
		{
			click = function()
				self:OnExportButtonClick()
			end,
			text = Private.L.Settings.Export,
		},
		{
			click = function()
				self:OnDiscordButtonClick()
			end,
			text = "Discord",
		},
	}
end

function TargetedSpellsEditModeMixin:OnDiscordButtonClick()
	local link = C_EncodingUtil.DeserializeCBOR(
		C_EncodingUtil.DecodeBase64("oURsaW5rWB1odHRwczovL2Rpc2NvcmQuZ2cvQzVTVGpZUnNDRA==")
	).link

	Private.Utils.ShowStaticPopup(Private.Utils.CreateEditablePopup("Discord", link, ACCEPT))
end

function TargetedSpellsEditModeMixin:OnExportButtonClick()
	Private.Utils.ShowStaticPopup(
		Private.Utils.CreateEditablePopup(Private.L.Settings.Export, Private.Utils.Export(), ACCEPT)
	)
end

function TargetedSpellsEditModeMixin:OnImportButtonClick()
	Private.Utils.ShowStaticPopup({
		text = Private.L.Settings.Import,
		button1 = Private.L.Settings.Import,
		button2 = CLOSE,
		hasEditBox = true,
		hasWideEditBox = true,
		editBoxWidth = 350,
		hideOnEscape = true,
		OnAccept = function(popupSelf)
			local editBox = popupSelf:GetEditBox()
			self:OnImportConfirmation(editBox:GetText())
		end,
	})
end

function TargetedSpellsEditModeMixin:OnImportConfirmation(encodedString)
	local hasAnyChange = Private.Utils.Import(encodedString)

	if hasAnyChange then
		LibEditMode:RefreshFrameSettings(self.editModeFrame)
	end
end

-- Rename / Create / Delete manage the group list; Import / Export round-trip config.
function TargetedSpellsEditModeMixin:CreateManagementButtons()
	return {
		{
			text = Private.L.Settings.GroupNameLabel,
			click = function()
				self:OnRenameButtonClick()
			end,
		},
		{
			text = Private.L.Settings.CreateGroup,
			click = function()
				Private.EditMode.CreateGroup()
			end,
		},
		{
			text = Private.L.Settings.DeleteGroup,
			click = function()
				self:OnDeleteButtonClick()
			end,
		},
		{
			text = Private.L.Settings.Import,
			click = function()
				self:OnImportButtonClick()
			end,
		},
		{
			text = Private.L.Settings.Export,
			click = function()
				self:OnExportButtonClick()
			end,
		},
	}
end

function TargetedSpellsEditModeMixin:OnRenameButtonClick()
	Private.Utils.ShowStaticPopup({
		text = Private.L.Settings.GroupNamePrompt,
		button1 = ACCEPT,
		button2 = CLOSE,
		hasEditBox = true,
		hasWideEditBox = true,
		editBoxWidth = 350,
		hideOnEscape = true,
		OnAccept = function(popupSelf)
			local name = popupSelf:GetEditBox():GetText()

			if name ~= nil and name ~= "" then
				self.group.Name = name
				-- the LibEditMode frame label updates on the next reload
				Private.EventRegistry:TriggerEvent(Private.Enum.Events.GROUP_CHANGED, self.groupId)
			end
		end,
	})
end

function TargetedSpellsEditModeMixin:OnDeleteButtonClick()
	if Private.Groups.Count() <= 1 then
		Private.Utils.ShowStaticPopup({
			text = Private.L.Settings.CannotDeleteLastGroup,
			button1 = OKAY,
			hideOnEscape = true,
		})

		return
	end

	Private.Utils.ShowStaticPopup({
		text = Private.L.Settings.DeleteGroupConfirm,
		button1 = YES,
		button2 = NO,
		hideOnEscape = true,
		OnAccept = function()
			Private.EditMode.DeleteGroup(self.groupId)
		end,
	})
end

-- ── Phase 4: compact, group-based edit-mode panel ───────────────────────────
-- Overrides the legacy CreateSetting above (later assignment wins). The old one is
-- dead code, kept only until a cleanup pass removes it. Every widget edits this
-- instance's `self.group` directly and fires GROUP_CHANGED(self.groupId); the Driver
-- refreshes that group and this instance restarts its demo. Element-level settings
-- are gone — they live in the designer now.
---@param base string
function TargetedSpellsEditModeMixin:CreateSetting(base)
	-- The WoW global Enum stays in scope for EditModeSettingDisplayType; the addon's
	-- own enums are referenced as Private.Enum.* so nothing shadows that global.

	local function Changed()
		Private.EventRegistry:TriggerEvent(Private.Enum.Events.GROUP_CHANGED, self.groupId)
	end

	-- single-select radio dropdown over `choices` ({ id, label }), bound to self.group[field]
	---@param name string
	---@param tooltip string
	---@param field string
	---@param choices table<number, {label: string, id: number}>
	---@param default number
	---@param disabled boolean?
	---@return LibEditModeDropdownGenerator
	local function RadioDropdown(name, tooltip, field, choices, default, disabled)
		local function Set(_, value)
			if self.group[field] ~= value then
				self.group[field] = value
				Changed()
			end
		end

		local function Generator(owner, rootDescription)
			for _, option in ipairs(choices) do
				rootDescription:CreateRadio(
					option.label,
					function()
						return self.group[field] == option.id
					end,
					function()
						Set(nil, option.id)
					end)
			end
		end

		return {
			name = name,
			kind = Enum.EditModeSettingDisplayType.Dropdown,
			desc = tooltip,
			default = default,
			generator = Generator,
			set = Set,
			disabled = disabled,
		}
	end

	-- multi-select checkbox dropdown over `choices` ({ id, label }), bound to boolTable[id]
	---@param name string
	---@param tooltip string
	---@param boolTable table<number, boolean>
	---@param choices table<number, {label: string, id: number}>
	---@param default table<number, boolean>	
	---@return LibEditModeDropdown
	local function MultiDropdown(name, tooltip, boolTable, choices, default)
		local function Set(_, values)
			for id, bool in pairs(values) do
				boolTable[id] = bool
			end

			Changed()
		end

		local function Generator(owner, rootDescription)
			for _, option in ipairs(choices) do
				rootDescription:CreateCheckbox(
					option.label,
					function()
						return boolTable[option.id] == true
					end,
					function()
						boolTable[option.id] = not boolTable[option.id]
						Changed()
					end,
					{ value = option.id, multiple = true }
				)
			end
		end

		return {
			name = name,
			kind = Enum.EditModeSettingDisplayType.Dropdown,
			desc = tooltip,
			default = default,
			generator = Generator,
			set = Set,
		}
	end

	---@param name string
	---@param tooltip string
	---@param field string
	---@param minValue number
	---@param maxValue number
	---@param step number
	---@param default number
	---@return LibEditModeSlider
	local function Slider(name, tooltip, field, minValue, maxValue, step, default)
		return {
			name = name,
			kind = Enum.EditModeSettingDisplayType.Slider,
			desc = tooltip,
			default = default,
			minValue = minValue,
			maxValue = maxValue,
			valueStep = step,
			get = function()
				return self.group[field]
			end,
			set = function(_, value)
				if self.group[field] ~= value then
					self.group[field] = value
					Changed()
				end
			end,
		}
	end

	-- builds an { id, label } option list from an id→label map over `ids`
	---@param ids table<number, string>
	---@param labels table<number, string>
	---@return table<number, {id: number, label: string}>
	local function Options(ids, labels)
		local list = {}

		for _, id in ipairs(ids) do
			list[#list + 1] = { id = id, label = labels[id] }
		end

		return list
	end

	if base == "Enabled" then
		return {
			name = Private.L.Settings.EnabledLabel,
			kind = Enum.EditModeSettingDisplayType.Checkbox,
			default = true,
			get = function()
				return self.group.Enabled
			end,
			set = function(_, value)
				if self.group.Enabled ~= value then
					self.group.Enabled = value
					Changed()
				end
			end,
		}
	elseif base == "Template" then
		local function Set(_, template)
			if self.group.Template ~= template then
				-- release old-pool demo frames BEFORE the pool changes, then reseed
				self:EndDemo()
				Private.Groups.SetTemplate(self.group, template)
				self.pool = self:GroupTemplatePool()
				Changed()
				self:StartDemo()
			end
		end

		local function Generator(owner, rootDescription)
			for _, id in ipairs({ Private.Enum.Template.Icon, Private.Enum.Template.Bar }) do
				rootDescription:CreateRadio(Private.L.Settings.TemplateLabels[id], function()
					return self.group.Template == id
				end, function()
					Set(nil, id)
				end)
			end
		end

		return {
			name = Private.L.Settings.TemplateLabel,
			kind = Enum.EditModeSettingDisplayType.Dropdown,
			desc = Private.L.Settings.TemplateTooltip,
			default = self.group.Template,
			generator = Generator,
			set = Set,
		}
	elseif base == "Filter" then
		return MultiDropdown(
			Private.L.Settings.FilterLabel,
			Private.L.Settings.FilterTooltip,
			self.group.Filter,
			Options(
				{
					Private.Enum.TargetClass.Player,
					Private.Enum.TargetClass.PartyMember,
					Private.Enum.TargetClass.Nobody
				},
				Private.L.Settings.TargetClassLabels
			),
			self.group.Filter
		)
	elseif base == "LoadConditionContentType" then
		return MultiDropdown(
			Private.L.Settings.LoadConditionContentTypeLabel,
			Private.L.Settings.LoadConditionContentTypeTooltip,
			self.group.LoadConditionContentType,
			Options({
				Private.Enum.ContentType.OpenWorld,
				Private.Enum.ContentType.Delve,
				Private.Enum.ContentType.Dungeon,
				Private.Enum.ContentType.Raid,
				Private.Enum.ContentType.Arena,
				Private.Enum.ContentType.Battleground,
			}, Private.L.Settings.LoadConditionContentTypeLabels),
			self.group.LoadConditionContentType
		)
	elseif base == "LoadConditionRole" then
		return MultiDropdown(
			Private.L.Settings.LoadConditionRoleLabel,
			Private.L.Settings.LoadConditionRoleTooltip,
			self.group.LoadConditionRole,
			Options(
				{ Private.Enum.Role.Healer, Private.Enum.Role.Tank, Private.Enum.Role.Damager },
				Private.L.Settings.LoadConditionRoleLabels
			),
			self.group.LoadConditionRole
		)
	elseif base == "Gap" then
		return Slider(Private.L.Settings.FrameGapLabel, Private.L.Settings.FrameGapTooltip, "Gap", 0, 100, 1, 2)
	elseif base == "MaxItems" then
		return Slider(Private.L.Settings.MaxItemsLabel, Private.L.Settings.MaxItemsTooltip, "MaxItems", 1, 20, 1, 10)
	elseif base == "Direction" then
		return RadioDropdown(
			Private.L.Settings.FrameDirectionLabel,
			Private.L.Settings.FrameDirectionTooltip,
			"Direction",
			{
				{ id = Private.Enum.Direction.Horizontal, label = Private.L.Settings.FrameDirectionHorizontal },
				{ id = Private.Enum.Direction.Vertical,   label = Private.L.Settings.FrameDirectionVertical },
			},
			Private.Enum.Direction.Horizontal)
	elseif base == "SortOrder" then
		return RadioDropdown(Private.L.Settings.FrameSortOrderLabel, Private.L.Settings.FrameSortOrderTooltip,
			"SortOrder", {
				{ id = Private.Enum.SortOrder.Ascending,  label = Private.L.Settings.FrameSortOrderAscending },
				{ id = Private.Enum.SortOrder.Descending, label = Private.L.Settings.FrameSortOrderDescending },
			}, Private.Enum.SortOrder.Ascending)
	elseif base == "Grow" then
		return RadioDropdown(
			Private.L.Settings.FrameGrowLabel,
			Private.L.Settings.FrameGrowTooltip,
			"Grow",
			Options({ Private.Enum.Grow.Start, Private.Enum.Grow.End }, Private.L.Settings.FrameGrowLabels),
			Private.Enum.Grow.Start
		)
	elseif base == "GlowType" then
		return RadioDropdown(
			Private.L.Settings.GlowTypeLabel,
			Private.L.Settings.GlowTypeTooltip,
			"GlowType",
			Options(Private.Settings.GetGlowTypesForKind(Private.Enum.FrameKind.Self), Private.L.Settings.GlowTypeLabels),
			Private.Enum.GlowType.PixelGlow,
			not self.group.GlowImportant
		)
	elseif base == "Behaviour" then
		local entries = {
			{ field = "GlowImportant",      label = Private.L.Settings.GlowImportantLabel },
			{ field = "OnlyImportant",      label = Private.L.Settings.OnlyImportantLabel },
			{ field = "IndicateInterrupts", label = Private.L.Settings.IndicateInterruptsLabel },
		}

		local function Set(_, values)
			for _, entry in ipairs(entries) do
				if values[entry.field] ~= nil then
					self.group[entry.field] = values[entry.field]
				end
			end
			Changed()
		end

		local function Generator(owner, rootDescription)
			for _, entry in ipairs(entries) do
				rootDescription:CreateCheckbox(entry.label, function()
					return self.group[entry.field] == true
				end, function()
					self.group[entry.field] = not self.group[entry.field]
					Changed()
				end, { value = entry.field, multiple = true })
			end
		end

		return {
			name = Private.L.Settings.FeatureFlagsLabel,
			kind = Enum.EditModeSettingDisplayType.Dropdown,
			desc = Private.L.Settings.FeatureFlagsTooltip,
			default = { GlowImportant = true, OnlyImportant = false, IndicateInterrupts = false },
			generator = Generator,
			set = Set,
		}
	elseif base == "AnnounceUntargetedSpells" or base == "AnnounceTargetedSpells" then
		local boolTable = TargetedSpellsSaved.TextToSpeech[base]
		local label = base == "AnnounceUntargetedSpells" and Private.L.Settings.AnnounceUntargetedSpellsLabel
			or Private.L.Settings.AnnounceTargetedSpellsLabel
		local tooltip = base == "AnnounceUntargetedSpells" and Private.L.Settings.AnnounceUntargetedSpellsTooltip
			or Private.L.Settings.AnnounceTargetedSpellsTooltip

		return MultiDropdown(label, tooltip, boolTable, Options({
			Private.Enum.NpcType.Boss,
			Private.Enum.NpcType.Lieutenant,
			Private.Enum.NpcType.Caster,
			Private.Enum.NpcType.Melee,
			Private.Enum.NpcType.Minion,
		}, Private.L.Settings.NpcTypeLabels), boolTable)
	elseif base == "TextToSpeechVoice" then
		local function Set(_, value)
			TargetedSpellsSaved.TextToSpeech.TextToSpeechVoice = value
		end

		local function Generator(owner, rootDescription)
			for _, voice in ipairs(Private.Settings.GetTtsVoiceOptions()) do
				rootDescription:CreateRadio(voice.name, function()
					return TargetedSpellsSaved.TextToSpeech.TextToSpeechVoice == voice.voiceID
				end, function()
					Set(nil, voice.voiceID)
				end)
			end
		end

		return {
			name = Private.L.Settings.TextToSpeechVoiceLabel,
			kind = Enum.EditModeSettingDisplayType.Dropdown,
			desc = Private.L.Settings.TextToSpeechVoiceTooltip,
			default = 0,
			generator = Generator,
			set = Set,
		}
	end

	error(string.format("Edit Mode settings for base '%s' are not implemented.", base or "NO BASE"))
end

-- the pool this instance's frames come from, following the group's current template
function TargetedSpellsEditModeMixin:GroupTemplatePool()
	if self.group.Template == Private.Enum.Template.Icon then
		return Private.Utils.Pools.Icon
	end

	return Private.Utils.Pools.Bar
end

-- the group's core element table (Icon or ProgressBar) for its current template
function TargetedSpellsEditModeMixin:CoreElement()
	local coreTag = self.group.Template == Private.Enum.Template.Icon and Private.Enum.Element.Icon
		or Private.Enum.Element.ProgressBar

	return self.group.Elements[coreTag]
end

-- Phase 7: size the placeholder to the group's full *visual extent*, not just its
-- core box, so free-positioned elements sitting outside the core (e.g. the bar's
-- icon/duration boxes flanking the narrower ProgressBar) fall inside the grab
-- target. The layout *footprint* — the frame-to-frame stride when MaxItems > 1 —
-- deliberately stays core-based (free positioning does not reflow); only the last
-- cell and the cross-axis span grow to the extent. When extent == core this is
-- byte-identical to the old core-based sizing.
function TargetedSpellsEditModeMixin:ResizeEditModeFrame()
	local core = self:CoreElement()
	local extent = Private.Utils.ComputeElementExtent(self.group.Elements)

	if self.group.Direction == Private.Enum.Direction.Horizontal then
		local totalWidth = (self.maxFrames - 1) * (core.width + self.group.Gap) + extent.width
		PixelUtil.SetSize(self.editModeFrame, totalWidth, extent.height)
	else
		local totalHeight = (self.maxFrames - 1) * (core.height + self.group.Gap) + extent.height
		PixelUtil.SetSize(self.editModeFrame, extent.width, totalHeight)
	end
end

function TargetedSpellsEditModeMixin:RestoreEditModePosition()
	local position = self.group.Position

	self.editModeFrame:ClearAllPoints()
	PixelUtil.SetPoint(self.editModeFrame, position.point, UIParent, position.point, position.x, position.y)
end

-- A v4 profile import updated the group tables in place, so self.group is still
-- valid; refresh the frame's size/position and restart the demo if it's running.
function TargetedSpellsEditModeMixin:OnProfileImported()
	if self.deleted then
		return
	end

	self:RestoreEditModePosition()
	self:ResizeEditModeFrame()

	if self.demoPlaying then
		self:EndDemo()
		self:StartDemo()
	end
end

-- A container/behaviour setting changed for some group; if it's ours, resize the
-- placeholder and restart the demo so the preview reflects it.
---@param groupId integer
function TargetedSpellsEditModeMixin:OnGroupChanged(groupId)
	if groupId ~= self.groupId then
		return
	end

	self:ResizeEditModeFrame()

	if self.demoPlaying then
		self:EndDemo()
		self:StartDemo()
	end
end

function TargetedSpellsEditModeMixin:OnEditModePositionChanged(_, _, point, x, y)
	local position = self.group.Position
	position.point = point
	position.x = x
	position.y = y

	-- lightweight: reposition the container only (no frame release), unlike GROUP_CHANGED
	Private.EventRegistry:TriggerEvent(Private.Enum.Events.GROUP_POSITION_CHANGED, self.groupId)
end

-- container-only panel; element appearance moved to the designer (Phase 5)
local SETTINGS_ORDER = {
	"Enabled",
	"Template",
	"Filter",
	"LoadConditionContentType",
	"LoadConditionRole",
	"Gap",
	"Direction",
	"SortOrder",
	"Grow",
	"MaxItems",
	"GlowType",
	"Behaviour",
	"AnnounceUntargetedSpells",
	"AnnounceTargetedSpells",
	"TextToSpeechVoice",
}

function TargetedSpellsEditModeMixin:AppendSettings()
	LibEditMode:AddFrame(
		self.editModeFrame,
		GenerateClosure(self.OnEditModePositionChanged, self),
		self.group.Position,
		self.displayName
	)

	LibEditMode:RegisterCallback("layout", GenerateClosure(self.RestoreEditModePosition, self))

	local settings = {}

	for _, base in ipairs(SETTINGS_ORDER) do
		table.insert(settings, self:CreateSetting(base))
	end

	LibEditMode:AddFrameSettings(self.editModeFrame, settings)
	LibEditMode:AddFrameSettingsButtons(self.editModeFrame, self:CreateManagementButtons())
end

function TargetedSpellsEditModeMixin:RepositionPreviewFrames()
	if not self.demoPlaying then
		return
	end

	---@type (TargetedSpellsIconMixin|TargetedSpellsBarMixin)[]
	local activeFrames = {}

	for index = 1, self.maxFrames do
		if self.frames[index] == nil then
			table.insert(
				self.demoTimers.tickers,
				C_Timer.NewTicker(5 + index, GenerateClosure(self.LoopFrame, self, index))
			)

			self:LoopFrame(index)
		end

		local frame = self.frames[index]

		if frame ~= nil and frame:ShouldBeShown() then
			table.insert(activeFrames, frame)
		end
	end

	if #activeFrames == 0 then
		return
	end

	local core = self:CoreElement()

	Private.Utils.SortFrames(activeFrames, self.group.SortOrder)

	local layouting = Private.Utils.CollectLayoutingArguments(
		self.group.Direction,
		self.group.Grow,
		core.width,
		core.height,
		self.group.Gap
	)

	local parentDimension = layouting.isHorizontal and self.editModeFrame:GetWidth() or self.editModeFrame:GetHeight()
	local offset = layouting.isGrowEnd and (parentDimension / 2 - self.group.Gap) or (-parentDimension / 2)

	-- The placeholder is sized to the element extent, whose centre is offset from the
	-- core centre when the active elements skew to one side (e.g. the migrated bar's
	-- icon reaches further left than its duration reaches right → extent.offsetX < 0).
	-- The content anchors on the *core* centre, so without correction it sits off-centre
	-- inside the box — bleeding past one edge with padding on the other. Shift it by
	-- -extent.offset on the CROSS axis so the content's extent centres in the box. The
	-- grow axis keeps its stacking offset (multi-frame spacing stays core-based).
	local extent = Private.Utils.ComputeElementExtent(self.group.Elements)

	Private.Utils.AdjustLayout(
		activeFrames,
		layouting,
		self.editModeFrame,
		"CENTER",
		layouting.isHorizontal and offset or -extent.offsetX,
		(not layouting.isHorizontal) and offset or -extent.offsetY,
		true
	)
end

function TargetedSpellsEditModeMixin:LoopFrame(index)
	if self.frames[index] == nil then
		self.frames[index] = self.pool:Acquire()
	end

	local frame = self.frames[index]
	-- demo frames render from this instance's group, just like live frames
	frame:SetGroup(self.group)
	local castTime = 4 + index / 2
	local duration = C_DurationUtil.CreateDuration()
	duration:SetTimeFromStart(GetTime(), castTime)

	frame:PostCreate({
		unit = "player",
		spellId = nil,
		startTime = GetTime(),
		id = index,
		duration = duration,
		isChannel = false,
	})

	frame:Show()
	frame:SetAlpha(secretwrap(1))

	-- bar demo frames get their preview colour + a random raid marker
	if frame.SetPreviewBarColor then
		frame:SetPreviewBarColor()
		frame:SetTargetMarker(Private.Utils.RollDice() and math.random(1, 8) or nil)
	end

	if self.group.GlowImportant and Private.Utils.RollDice() then
		frame:ShowGlow(secretwrap(true))

		if self.group.OnlyImportant then
			frame:SetAlpha(secretwrap(1))
		end
	else
		frame:HideGlow()

		if self.group.OnlyImportant then
			frame:SetAlpha(secretwrap(0))
		end
	end

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

function TargetedSpellsEditModeMixin:StartDemo()
	if self.deleted or self.demoPlaying or not self.group.Enabled or not self:IsPastLoadingScreen() then
		return
	end

	self.demoPlaying = true

	self:RepositionPreviewFrames()
end

function TargetedSpellsEditModeMixin:ReleaseAllFrames()
	for index = 1, self.maxFrames do
		local frame = self.frames[index]

		if frame ~= nil then
			self.pool:Release(frame)
			self.frames[index] = nil
		end
	end
end

function TargetedSpellsEditModeMixin:EndDemo()
	if not self.demoPlaying then
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

-- ── Instance factory + group management ──────────────────────────────────────
-- One edit-mode instance per group, created at login and on Create Group.

Private.EditMode = {}
---@type table<integer, TargetedSpellsEditModeMixin>
Private.EditMode.instances = {}

---@param group TargetedSpellsGroup
function Private.EditMode.CreateInstance(group)
	local instance = CreateFromMixins(TargetedSpellsEditModeMixin)
	instance:Init(group)
	Private.EditMode.instances[group.Id] = instance
	return instance
end

-- New group (defaults to a Bar) + its instance; position its container and, if
-- edit mode is open, start its demo.
function Private.EditMode.CreateGroup()
	local id, group = Private.Groups.Create(Private.Enum.Template.Bar)
	local instance = Private.EditMode.CreateInstance(group)

	Private.EventRegistry:TriggerEvent(Private.Enum.Events.GROUP_POSITION_CHANGED, id)

	if LibEditMode:IsInEditMode() then
		instance:StartDemo()
	end
end

-- Delete a group + its instance (guarded against the last group). LibEditMode has
-- no RemoveFrame, so the frame is just hidden and flagged deleted so its lingering
-- callbacks no-op; a full refresh drops any live frames of the group.
---@param groupId integer
function Private.EditMode.DeleteGroup(groupId)
	if not Private.Groups.Delete(groupId) then
		return
	end

	local instance = Private.EditMode.instances[groupId]
	if instance ~= nil then
		instance.deleted = true
		instance:EndDemo()
		instance.editModeFrame:Hide()
		Private.EditMode.instances[groupId] = nil
	end

	Private.EventRegistry:TriggerEvent(Private.Enum.Events.PROFILE_IMPORTED)
end

table.insert(Private.LoginFnQueue, function()
	for _, group in pairs(TargetedSpellsSaved.Groups) do
		Private.EditMode.CreateInstance(group)
	end
end)
