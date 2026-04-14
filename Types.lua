---@meta

---@class TargetedSpells
---@field EventRegistry CallbackRegistryMixin
---@field Events table<string, string>
---@field Enum TargetedSpellsEnums
---@field Settings TargetedSpellsSettings
---@field LoginFnQueue table<string, function>
---@field L table<string, table<string, string|nil>>
---@field Utils TargetedSpellsUtils
---@field Glows GlowFunctions

---@class CollectLayoutingArguments
---@field isHorizontal boolean
---@field isGrowEnd boolean
---@field orientation "HORIZONTAL"|"VERTICAL"
---@field x number
---@field y number
---@field originPoint FramePoint
---@field relativePoint FramePoint

---@class TargetedSpellsUtils
---@field CollectLayoutingArguments fun(direction: Direction, grow: Grow, width: number, height: number, gap: number): CollectLayoutingArguments
---@field AdjustLayout fun(frames: TargetedSpellsIconMixin[], geo: CollectLayoutingArguments, barParent: Frame, firstAnchorPoint: FramePoint, firstOffsetX: number, firstOffsetY: number, isEditMode: boolean)
---@field SortFrames fun(frames: TargetedSpellsIconMixin[], sortOrder: SortOrder)
---@field RollDice fun(): boolean
---@field ShowStaticPopup fun(args: StaticPopupDialogsArgs)
---@field Import fun(string: string): boolean
---@field Export fun(): string
---@field RegisterEditModeFrame fun(frameKind: FrameKind, frame: Frame)
---@field GetEditModeFrame fun(frameKind: FrameKind): Frame?
---@field CreateEditablePopup fun(title: string, text: string, button1: string): StaticPopupDialogsArgs
---@field Pools { Self: FramePool<TargetedSpellsIconMixin>, Bar: FramePool<TargetedSpellsBarMixin> }
---@field ShowMigrationPopup fun()
---@field MigratePartySettingsToV3 fun(existing: table): SavedVariablesSettingsParty
---@field ApplyMigration fun(key: string, kind: FrameKind, defaults: SavedVariablesSettingsSelf|SavedVariablesSettingsParty)

---@class GlowFunctions
---@field PixelGlow_Start fun(frame: Frame, width: number, height: number)
---@field PixelGlow_Stop fun(frame: Frame)
---@field AutoCastGlow_Start fun(frame: Frame, width: number, height: number)
---@field AutoCastGlow_Stop fun(frame: Frame)
---@field ProcGlow_Start fun(frame: Frame, width: number, height: number)
---@field ProcGlow_Stop fun(frame: Frame)

---@class ProcGlowAnimGroup : AnimationGroup
---@field AlphaRepeat Animation
---@field FlipbookRepeat Animation

---@class ProcGlowFrame : Frame
---@field ProcStart Texture
---@field ProcLoop Texture
---@field ProcLoopAnim ProcGlowAnimGroup
---@field ProcStartAnim AnimationGroup
---@field key string?
---@field StartAnim boolean?

---@class StaticPopupDialogsArgs
---@field text string
---@field button1 string
---@field button2 string?
---@field OnAccept fun()?
---@field hasEditBox boolean?
---@field hasWideEditBox boolean?
---@field editBoxWidth number?
---@field hideOnEscape boolean?
---@field id string?
---@field whileDead boolean?

---@class TargetedSpellsEnums

---@class SliderSettings
---@field min number
---@field max number
---@field step number

---@class DelayInfo
---@field unit string
---@field kinds table<FrameKind, boolean>
---@field id number|string|nil

---@class SpellCastInfo
---@field unit string
---@field spellId number
---@field startTime number
---@field id number|string
---@field duration DurationObject
---@field isChannel boolean
---@field isRetarget boolean?

---@class FontInfo
---@field fonts table<string, string>
---@field byLabel table<string, string>

---@class TargetedSpellsSettings
---@field Keys table<'Self' | 'Party', table<string, string>>
---@field GetSettingsDisplayOrder fun(kind: FrameKind): string[]
---@field GetDefaultEditModeFramePosition fun(kind: FrameKind): FramePosition
---@field GetSliderSettingsForOption fun(key: string): SliderSettings
---@field GetSelfDefaultSettings fun(): SavedVariablesSettingsSelf
---@field GetPartyDefaultSettings fun(): SavedVariablesSettingsParty
---@field GetContentTypesForKind fun(kind: FrameKind): table<string, ContentType>
---@field GetGlowTypesForKind fun(kind: FrameKind): GlowType[]
---@field GetFontOptions fun(): FontInfo
---@field GetFeatureFlagsForKind fun(kind: FrameKind): FeatureFlag[]

---@class SavedVariables
---@field Settings SavedVariablesSettings
---@field nameplateShowOffscreenWasInitialized boolean

---@class SavedVariablesSettings
---@field Self SavedVariablesSettingsSelf
---@field Party SavedVariablesSettingsParty

---@class FramePosition
---@field point FramePoint
---@field x number
---@field y number

---@class SavedVariablesSettingsSelf
---@field Enabled boolean
---@field Width number
---@field Height number
---@field Gap number
---@field Direction Direction
---@field LoadConditionContentType table<number, boolean>
---@field LoadConditionRole table<number, boolean>
---@field SortOrder SortOrder
---@field Grow Grow
---@field FontSize number
---@field Position FramePosition
---@field GlowType GlowType
---@field IconZoom number
---@field Font string
---@field FontFlags table<FontFlags, boolean>
---@field FeatureFlags table<FeatureFlag, boolean>
---@field BorderStyle string
---@field AnnounceUntargetedSpells boolean

---@class SavedVariablesSettingsParty
---@field Enabled boolean
---@field Width number
---@field Height number
---@field Gap number
---@field LoadConditionContentType table<number, boolean>
---@field LoadConditionRole table<number, boolean>
---@field SortOrder SortOrder
---@field Grow Grow
---@field FontSize number
---@field GlowType GlowType
---@field Font string
---@field FontFlags table<FontFlags, boolean>
---@field FeatureFlags table<FeatureFlag, boolean>
---@field ForegroundBarTexture string
---@field BackgroundBarTexture string
---@field BackgroundBarColor string
---@field ProgressBarColor string
---@field UseInterruptabilityColors boolean
---@field UseTargetClassColor boolean
---@field UninterruptibleColor string
---@field InterruptibleColor string
---@field AnnounceUntargetedSpells boolean
---@field Position FramePosition

---@class TargetedSpellsSelfPreviewFrame: Frame
---@field GetChildren fun(self: TargetedSpellsSelfPreviewFrame): TargetedSpellsIconMixin

---@class GlowTargetFrame : Frame
---@field _Star4 Star4Glow?
---@field _PixelGlow Frame?
---@field _AutoCastGlow Frame?
---@field _ProcGlow ProcGlowFrame?

---@class Star4Glow : Frame
---@field Inner Texture
---@field Outer Texture
---@field Animation AnimationGroup

---@class CustomCooldown : ExtendedCooldownTypes
---@field DurationText FontString

---@class TargetedSpellsMixin : Frame
---@field private kind FrameKind?
---@field private startTime number?
---@field private spellId number?
---@field private id number?
---@field private elapsed number
---@field protected wasInterrupted boolean
---@field private doNotHideBefore number?
---@field info SpellCastInfo?
---@field Bar StatusBar
---@field Icon Texture
---@field InterruptIcon Texture
---@field OnLoad fun(self: TargetedSpellsMixin)
---@field SetId fun(self: TargetedSpellsMixin, id: number?)
---@field GetId fun(self: TargetedSpellsMixin): number?
---@field GetKind fun(self: TargetedSpellsMixin): FrameKind?
---@field CanBeHidden fun(self: TargetedSpellsMixin, id: number|string|nil): boolean
---@field SetStartTime fun(self: TargetedSpellsMixin, startTime: number?)
---@field GetStartTime fun(self: TargetedSpellsMixin): number?
---@field ClearStartTime fun(self: TargetedSpellsMixin)
---@field ShouldBeShown fun(self: TargetedSpellsMixin): boolean
---@field IsSpellImportant fun(self: TargetedSpellsMixin, boolOverride: boolean?): boolean
---@field GetGlowTarget fun(self: TargetedSpellsMixin): GlowTargetFrame, number, number
---@field HideGlow fun(self: TargetedSpellsMixin)
---@field ShowGlow fun(self: TargetedSpellsMixin, isImportant: boolean)
---@field GetSpellId fun(self: TargetedSpellsMixin): number?
---@field SetSpellId fun(self: TargetedSpellsMixin, spellId: number?)
---@field SetInterrupted fun(self: TargetedSpellsMixin, name: string?, color: colorRGB?)
---@field Reset fun(self: TargetedSpellsMixin)
---@field SetFont fun(self: TargetedSpellsMixin)
---@field SetShowDuration fun(self: TargetedSpellsMixin, showDuration: boolean)
---@field SetDuration fun(self: TargetedSpellsMixin, duration: DurationObject): number

---@class TargetedSpellsIconMixin : TargetedSpellsMixin
---@field private Overlay Texture
---@field Cooldown CustomCooldown
---@field private unit string?
---@field private duration DurationObject|nil
---@field private InterruptSource FontString
---@field OnCooldownDoneCallback fun(info: SpellCastInfo)
---@field OnCooldownDoneClosure fun()
---@field private BorderSolidTop Texture
---@field private BorderSolidBottom Texture
---@field private BorderSolidLeft Texture
---@field private BorderSolidRight Texture
---@field private BorderTopLeft Texture
---@field private BorderTopRight Texture
---@field private BorderBottomLeft Texture
---@field private BorderBottomRight Texture
---@field private BorderTop Texture
---@field private BorderBottom Texture
---@field private BorderLeft Texture
---@field private BorderRight Texture
---@field OnLoad fun(self: TargetedSpellsIconMixin)
---@field SetShowDuration fun(self: TargetedSpellsIconMixin, showDuration: boolean)
---@field ApplyBorderStyle fun(self: TargetedSpellsIconMixin, styleName: string)
---@field OnSizeChanged fun(self: TargetedSpellsIconMixin)
---@field OnSettingChanged fun(self: TargetedSpellsIconMixin, key: string, flagIdOrValue: number|string|boolean|table, newBool: boolean?)
---@field PostCreate fun(self: TargetedSpellsIconMixin, info: SpellCastInfo?, OnCooldownDoneCallback: fun(info: SpellCastInfo))
---@field Reset fun(self: TargetedSpellsIconMixin)
---@field SetFont fun(self: TargetedSpellsIconMixin)

---@class TargetedSpellsBarProgressBar : StatusBar
---@field Background Texture
---@field SpellName FontString
---@field TargetName FontString
---@field InterruptSource FontString
---@field Duration FontString

---@class TargetedSpellsBarCustomElementsFrame : Frame
---@field TargetMarker Texture

---@class TargetedSpellsBarMixin : TargetedSpellsMixin
---@field unit string?
---@field ProgressBar TargetedSpellsBarProgressBar
---@field CustomElementsFrame TargetedSpellsBarCustomElementsFrame
---@field OnLoad fun(self: TargetedSpellsBarMixin)
---@field OnSizeChanged fun(self: TargetedSpellsBarMixin)
---@field OnUpdate fun(self: TargetedSpellsBarMixin, elapsed: number)
---@field Reset fun(self: TargetedSpellsBarMixin)
---@field PostCreate fun(self: TargetedSpellsBarMixin, info: SpellCastInfo?)
---@field SetShowDuration fun(self: TargetedSpellsBarMixin, showDuration: boolean)
---@field SetFont fun(self: TargetedSpellsBarMixin)
---@field SetDuration fun(self: TargetedSpellsBarMixin, duration: DurationObject): number
---@field SetForegroundBarTexture fun(self: TargetedSpellsBarMixin)
---@field SetBackgroundBarTexture fun(self: TargetedSpellsBarMixin)
---@field SetBackgroundBarColor fun(self: TargetedSpellsBarMixin)
---@field SetProgressBarColor fun(self: TargetedSpellsBarMixin)
---@field SetPreviewBarColor fun(self: TargetedSpellsBarMixin)
---@field AdjustInterruptibleColor fun(self: TargetedSpellsBarMixin, isInterruptible: boolean)
---@field SetTargetMarker fun(self: TargetedSpellsBarMixin, raidTargetIndex: number?)

---@class EditModeFrame : Frame
---@field firstFrameTimestamp number

---@class TargetedSpellsEditModeMixin : Frame
---@field protected editModeFrame EditModeFrame
---@field protected frameKind FrameKind
---@field protected displayName string
---@field protected maxFrames number
---@field protected pool FramePool<TargetedSpellsIconMixin>|FramePool<TargetedSpellsBarMixin>
---@field private demoPlaying boolean
---@field private frames TargetedSpellsIconMixin[] | TargetedSpellsBarMixin[]
---@field protected demoTimers { tickers: table<number, FunctionContainer>, timers: table<number, FunctionContainer> }
---@field Init fun(self: TargetedSpellsEditModeMixin, displayName: string, frameKind: FrameKind)
---@field OnSettingsChanged fun(self: TargetedSpellsEditModeMixin, key: string, flagIdOrValue: number|string|boolean|table, newBool: boolean?)
---@field CreateSetting fun(self: TargetedSpellsEditModeMixin, key: string, defaults: SavedVariablesSettingsParty|SavedVariablesSettingsSelf): LibEditModeButton|LibEditModeCheckbox|LibEditModeDropdown|LibEditModeSlider|LibEditModeColorPicker
---@field ResizeEditModeFrame fun(self: TargetedSpellsEditModeMixin)
---@field RestoreEditModePosition fun(self: TargetedSpellsEditModeMixin)
---@field OnEditModePositionChanged fun(self: TargetedSpellsEditModeMixin, frame: Frame, layoutName: string, point: FramePoint, x: number, y: number)
---@field AppendSettings fun(self: TargetedSpellsEditModeMixin)
---@field OnLayoutSettingChanged fun(self: TargetedSpellsEditModeMixin, key: string, value: number|string, newBool: boolean?)
---@field RepositionPreviewFrames fun(self: TargetedSpellsEditModeMixin)
---@field LoopFrame fun(self: TargetedSpellsEditModeMixin, index: number)
---@field StartDemo fun(self: TargetedSpellsEditModeMixin)
---@field ReleaseAllFrames fun(self: TargetedSpellsEditModeMixin)
---@field EndDemo fun(self: TargetedSpellsEditModeMixin)
---@field CreateImportExportButtons fun(self: TargetedSpellsEditModeMixin) : LibEditModeButton[]
---@field OnExportButtonClick fun(self: TargetedSpellsEditModeMixin)
---@field OnImportButtonClick fun(self: TargetedSpellsEditModeMixin)
---@field OnImportConfirmation fun(self: TargetedSpellsEditModeMixin, encodedString: string)
---@field IsPastLoadingScreen fun(self: TargetedSpellsEditModeMixin): boolean

---@class TargetedSpellsSelfEditMode : TargetedSpellsEditModeMixin
---@field private frames TargetedSpellsIconMixin[]
---@field pool FramePool<TargetedSpellsIconMixin>
---@field Init fun(self: TargetedSpellsSelfEditMode)
---@field OnLayoutSettingChanged fun(self: TargetedSpellsSelfEditMode, key: string, value: number|string, newBool: boolean?): nil

---@class TargetedSpellsPartyEditMode : TargetedSpellsEditModeMixin
---@field private frames TargetedSpellsBarMixin[]
---@field pool FramePool<TargetedSpellsBarMixin>
---@field Init fun(self: TargetedSpellsPartyEditMode)
---@field OnLayoutSettingChanged fun(self: TargetedSpellsPartyEditMode, key: string, value: number|string, newBool: boolean?)
---@field LoopFrame fun(self: TargetedSpellsPartyEditMode, index: number)

---@class TargetedSpellsDriver
---@field private frame Frame
---@field private role Role
---@field private contentType ContentType
---@field private delay number
---@field private OnCooldownDoneClosure fun(info: SpellCastInfo)
---@field private ttsAnnouncementCache table<string, number>
---@field private voiceId number
---@field frames table<string, (TargetedSpellsIconMixin|TargetedSpellsBarMixin)[]>
---@field SetupFrame fun(self: TargetedSpellsDriver, isBoot: boolean)
---@field ProcessInfo fun(self: TargetedSpellsDriver, info: SpellCastInfo)
---@field RepositionFrames fun(self: TargetedSpellsDriver)
---@field ReleaseFrameForUnit fun(self: TargetedSpellsDriver, unit: string, removeUnit: boolean, id?: number): boolean
---@field LoadConditionsProhibitExecution fun(self: TargetedSpellsDriver, kind: FrameKind): boolean
---@field UnitIsIrrelevant fun(self: TargetedSpellsDriver, unit: string, skipTargetCheck?: boolean): boolean
---@field OnFrameEvent fun(self: TargetedSpellsDriver, listenerFrame: Frame, event: WowEvent, ...)
---@field OnSettingsChanged fun(self: TargetedSpellsDriver, key: string, value: number|string|boolean|table)
---@field DetermineSpellDelayRequirement fun(self: TargetedSpellsDriver): boolean
---@field MaybeMarkAsInterruptedAndDelay fun(self: TargetedSpellsDriver, unit: string, id: number|string|nil, interruptedBy: string?)
---@field CleanupDanglingFrames fun(self: TargetedSpellsDriver)
---@field MaybeAnnounceUntargetedSpell fun(self: TargetedSpellsDriver, info: SpellCastInfo)
---@field GetCastInformation fun(self: TargetedSpellsDriver, unit: string): boolean, number, number
---@field ClearAnnouncementCacheForUnit fun(self: TargetedSpellsDriver, unit: string)
---@field DetectMostReasonableVoiceId fun(self: TargetedSpellsDriver)
---@field GetDefaultVoiceId fun(self: TargetedSpellsDriver): number

---@class NumericFormatter
---@field SetBreakpoints fun(self: NumericFormatter, breakpoints: table)

---@class DurationObject
---@field FormatRemainingDuration fun(self: DurationObject, formatter: NumericFormatter, modifier?: string): string
---@field GetRemainingDuration fun(self: DurationObject): number
---@field GetTimeFraction fun(self: DurationObject): number
---@field EvaluateRemainingDuration fun(self: DurationObject, curve: fun(remaining: number): number): number
---@field SetTimeSpan fun(self: DurationObject, startTime: number, endTime: number)

----- type patching / completion

---@class ExtendedCooldownTypes : Cooldown
---@field SetMinimumCountdownDuration fun(self: ExtendedCooldownTypes, minimumDuration: number)
---@field GetCountdownFontString fun(self: ExtendedCooldownTypes): FontString
---@field SetCooldownFromDurationObject fun(self: ExtendedCooldownTypes, durationObject: DurationObject, clearIfZero?: boolean)
---@field SetCountdownFormatter fun(self: ExtendedCooldownTypes, formatter: NumericFormatter)

---@class IconDataProviderMixin
---@field GetRandomIcon fun(self: IconDataProviderMixin): number

---@class FramePool<T>
---@field Acquire fun(self: FramePool<T>): T, boolean
---@field Release fun(self: FramePool<T>, frame: T, canFailToFindObject: boolean?)
---@field ReleaseAll fun(self: FramePool<T>)
---@field EnumerateActive fun(self: FramePool<T>): fun(): T
---@field GetNextActive fun(self: FramePool<T>, current: T?): T?
---@field IsActive fun(self: FramePool<T>, frame: T): boolean
---@field GetNumActive fun(self: FramePool<T>): number
---@field DoesObjectBelongToPool fun(self: FramePool<T>, frame: T): boolean
---@field GetTemplate fun(self: FramePool<T>): string

---@generic T: Frame
---@param frameType string
---@param parent Frame?
---@param template string?
---@param resetFunc (fun(pool: FramePool<T>, frame: T, new: boolean?))?
---@param forbidden boolean?
---@param postCreate (fun(frame: T))?
---@param capacity number?
---@return FramePool<T>
function CreateFramePool(frameType, parent, template, resetFunc, forbidden, postCreate, capacity) end

---@class LibEditModeSetting
---@field name string
---@field kind string
---@field desc string?
---@field default number|string|boolean|table
---@field disabled boolean?

---@class LibEditModeGetterSetter
---@field set fun(layoutName: string, value: number|string|boolean|table, fromReset: boolean)
---@field get fun(layoutName: string): number|string|boolean|table

---@class LibEditModeButton
---@field text string
---@field click function

---@class LibEditModeCheckbox : LibEditModeSetting, LibEditModeGetterSetter

---@class LibEditModeDropdownBase : LibEditModeSetting
---@field generator fun(owner, rootDescription, data)
---@field height number?
---@field multiple boolean?

---@class LibEditModeDropdownGenerator : LibEditModeDropdownBase
---@field generator fun(owner, rootDescription, data)

---@class LibEditModeDropdownSet : LibEditModeDropdownBase
---@field set fun(layoutName: string, value: number|string|boolean|table, fromReset: boolean)

---@alias LibEditModeDropdown LibEditModeDropdownGenerator | LibEditModeDropdownSet

---@class LibEditModeSlider : LibEditModeSetting, LibEditModeGetterSetter
---@field minValue number?
---@field maxValue number?
---@field valueStep number?
---@field formatter (fun(value: number): string)|nil

---@class LibEditModeColorPicker : LibEditModeSetting, LibEditModeGetterSetter
---@field hasOpacity boolean?

---@return function?
local function GenerateClosureInternal(generatorArray, f, ...)
	local count = select("#", ...)
	local generator = generatorArray[count + 1]
	if generator then
		return generator(f, ...)
	end

	assertsafe("Closure generation does not support more than " .. (#generatorArray - 1) .. " parameters")
	return nil
end

local s_passThroughClosureGenerators = {
	function(f)
		return function(...)
			return f(...)
		end
	end,
	function(f, a)
		return function(...)
			return f(a, ...)
		end
	end,
	function(f, a, b)
		return function(...)
			return f(a, b, ...)
		end
	end,
	function(f, a, b, c)
		return function(...)
			return f(a, b, c, ...)
		end
	end,
	function(f, a, b, c, d)
		return function(...)
			return f(a, b, c, d, ...)
		end
	end,
	function(f, a, b, c, d, e)
		return function(...)
			return f(a, b, c, d, e, ...)
		end
	end,
}

-- Syntactic sugar for function(...) return f(a, b, c, ...); end
function GenerateClosure(f, ...)
	return GenerateClosureInternal(s_passThroughClosureGenerators, f, ...)
end

---@param castingUnit string
---@param unit string
---@return boolean
function PlayerIsSpellTarget(castingUnit, unit)
	return true
end

---@class PlayerUtil
---@field GetCurrentSpecID fun(): number?
---@field GetSpecName fun(specId: number): string

---@type PlayerUtil
PlayerUtil = {
	GetCurrentSpecID = function()
		return nil
	end,
	GetSpecName = function()
		return ""
	end,
}

UNIT_NAMEPLATES_SHOW_OFFSCREEN = ""

---@type string|nil
GAME_LOCALE = ""

---@type table<string, StaticPopupDialogsArgs>
StaticPopupDialogs = {}

PixelUtil = {
	SetPoint =
		---@param region Region
		---@param point FramePoint
		---@param relativeTo Region
		---@param relativePoint FramePoint
		---@param offsetX number
		---@param offsetY number
		---@param minOffsetXPixels number?
		---@param minOffsetYPixels number?
		function(region, point, relativeTo, relativePoint, offsetX, offsetY, minOffsetXPixels, minOffsetYPixels)
			region:SetPoint(point, relativeTo, relativePoint, offsetX, offsetY)
		end,
	SetSize =
		---@param region Region
		---@param width number
		---@param height number
		function(region, width, height)
			region:SetSize(width, height)
		end,
}

function StaticPopup_Hide(name) end
function StaticPopup_Show(name) end

---@enum Enum.StatusBarInterpolation
Enum.StatusBarInterpolation = {
	None = 0,
	Linear = 1,
}
