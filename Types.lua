---@meta

---@class TargetedSpells
---@field EventRegistry CallbackRegistryMixin
---@field Events table<string, string>
---@field Enum TargetedSpellsEnums
---@field Settings TargetedSpellsSettings
---@field LoginFnQueue table<string, function>
---@field L table<string, table<string, string|nil>>
---@field Utils TargetedSpellsUtils

---@class TargetedSpellsUtils
---@field CalculateCoordinate fun(index: number, dimension: number, gap: number, parentDimension: number, total: number, offset: number, grow: Grow): number
---@field SortFrames fun(frames: TargetedSpellsMixin[], sortOrder: SortOrder)
---@field AttemptToPlaySound fun(sound: string|number, channel: SoundChannel)
---@field RollDice fun(): boolean
---@field FindAppropriateTTSVoiceId fun(): number
---@field PlayTTS fun(text: string, voiceId: number?, rate: number?)
---@field FindThirdPartyGroupFrameForUnit fun(unit: string, kind: FrameKind): Frame?

---@class TargetedSpellsEnums

---@class CustomSound
---@field soundKitID number|string
---@field text string
---@field isFile boolean?

---@class SliderSettings
---@field min number
---@field max number
---@field step number

---@class DelayInfo
---@field unit string
---@field kinds table<FrameKind, boolean>
---@field id number|string|nil

---@class TargetedSpellsSettings
---@field Keys table<'Self' | 'Party', table<string, string>>
---@field GetSettingsDisplayOrder fun(kind: FrameKind): string[]
---@field GetDefaultEditModeFramePosition fun(): FramePosition
---@field GetSliderSettingsForOption fun(key: string): SliderSettings
---@field GetSelfDefaultSettings fun(): SavedVariablesSettingsSelf
---@field GetPartyDefaultSettings fun(): SavedVariablesSettingsParty
---@field GetCooldownViewerSounds fun(): SoundInfo
---@field GetCustomSoundGroups fun(groupSizeThreshold: number?):  SoundInfo
---@field SampleTTSVoice fun(voiceId: number)
---@field IsContentTypeAvailableForKind fun(kind: FrameKind, contentTypeId: ContentType): boolean
---@field SoundIsFile fun(sound: string|number): boolean

---@class SoundInfo
---@field soundCategoryKeyToLabel table<string, string>
---@field data table<string, CustomSound[]>

---@class SavedVariables
---@field Settings SavedVariablesSettings
---@field nameplateShowOffscreenWasInitialized boolean

---@class SavedVariablesSettings
---@field Self SavedVariablesSettingsSelf
---@field Party SavedVariablesSettingsParty

---@class FramePosition
---@field point Anchor
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
---@field PlaySound boolean
---@field SoundChannel SoundChannel
---@field Sound string
---@field LoadConditionSoundContentType table<number, boolean>
---@field SortOrder SortOrder
---@field Grow Grow
---@field ShowDuration boolean
---@field ShowDurationFractions boolean
---@field FontSize number
---@field Position FramePosition
---@field ShowBorder boolean
---@field GlowImportant boolean
---@field GlowType GlowType
---@field Opacity number
---@field PlayTTS boolean
---@field TTSVoice number
---@field IndicateInterrupts boolean
---@field TargetingFilterApi TargetingFilterApi

---@class SavedVariablesSettingsParty
---@field Enabled boolean
---@field Width number
---@field Height number
---@field Gap number
---@field Direction Direction
---@field LoadConditionContentType table<number, boolean>
---@field LoadConditionRole table<number, boolean>
---@field OffsetX number
---@field OffsetY number
---@field SourceAnchor Anchor
---@field TargetAnchor Anchor
---@field SortOrder SortOrder
---@field Grow Grow
---@field ShowDuration boolean
---@field ShowDurationFractions boolean
---@field FontSize number
---@field ShowBorder boolean
---@field GlowImportant boolean
---@field GlowType GlowType
---@field Opacity number
---@field IndicateInterrupts boolean
---@field TargetingFilterApi TargetingFilterApi

---@class TargetedSpellsSelfPreviewFrame: Frame
---@field GetChildren fun(self: TargetedSpellsSelfPreviewFrame): TargetedSpellsMixin

---@class Star4Glow : Frame
---@field Inner Texture
---@field Outer Texture
---@field Animation AnimationGroup

---@class TargetedSpellsMixin : Frame
---@field Overlay Texture
---@field Icon Texture
---@field Cooldown ExtendedCooldownTypes
---@field kind FrameKind?
---@field unit string? -- secret?
---@field startTime number?
---@field duration DurationObjectDummy|nil -- secret
---@field spellId number? -- secret
---@field id number? -- secret
---@field _AutoCastGlow Frame?
---@field _ButtonGlow Frame?
---@field _PixelGlow Frame?
---@field _ProcGlow Frame?
---@field _Star4 Star4Glow?
---@field DurationText FontString
---@field Border Frame | BackdropTemplate
---@field InterruptIcon Texture
---@field OnLoad fun(self: TargetedSpellsMixin)
---@field SetId fun(self: TargetedSpellsMixin, id: number?)
---@field GetId fun(self: TargetedSpellsMixin): number?
---@field SetInterrupted fun(self: TargetedSpellsMixin)
---@field CanBeHidden fun(self: TargetedSpellsMixin, id: number?): boolean
---@field OnUpdate fun(self: TargetedSpellsMixin, elapsed: number)
---@field SetShowDuration fun(self: TargetedSpellsMixin, showDuration: boolean, showFractions: boolean)
---@field SetShowBorder fun(self: TargetedSpellsMixin, bool: boolean)
---@field OnSizeChanged fun(self: TargetedSpellsMixin, width: number, height: number)
---@field OnSettingChanged fun(self: TargetedSpellsMixin, key: string, value: number|string)
---@field SetDuration fun(self: TargetedSpellsMixin, duration: DurationObjectDummy|number)
---@field SetStartTime fun(self: TargetedSpellsMixin, startTime: number?)
---@field GetStartTime fun(self: TargetedSpellsMixin): number?
---@field ShowGlow fun(self: TargetedSpellsMixin, isImportant: boolean) -- secret bool, but passed explicitly in EditMode code
---@field HideGlow fun(self: TargetedSpellsMixin)
---@field IsSpellImportant fun(self: TargetedSpellsMixin, boolOverride: boolean?): boolean
---@field SetSpellId fun(self: TargetedSpellsMixin, spellId: number?)
---@field ShouldBeShown fun(self: TargetedSpellsMixin): boolean
---@field ClearStartTime fun(self: TargetedSpellsMixin)
---@field Reposition fun(self: TargetedSpellsMixin, point: string, relativeTo: Frame, relativePoint: string, offsetX: number, offsetY: number)
---@field SetUnit fun(self: TargetedSpellsMixin, unit: string)
---@field SetKind fun(self: TargetedSpellsMixin, kind: FrameKind)
---@field GetKind fun(self: TargetedSpellsMixin): FrameKind?
---@field GetUnit fun(self: TargetedSpellsMixin): string
---@field PostCreate fun(self: TargetedSpellsMixin, unit: string, kind: FrameKind, castingUnit: string?)
---@field Reset fun(self: TargetedSpellsMixin)
---@field SetFontSize fun(self: TargetedSpellsMixin, fontSize: number)

---@class TargetedSpellsEditModeMixin : Frame
---@field editModeFrame Frame
---@field demoPlaying boolean
---@field framePool FramePool
---@field frames table<number, TargetedSpellsMixin[]> | TargetedSpellsMixin[]
---@field demoTimers { tickers: table<number, FunctionContainer>, timers: table<number, FunctionContainer> }
---@field buildingFrames true|nil
---@field Init fun(self: TargetedSpellsEditModeMixin, displayName: string, frameKind: FrameKind)
---@field OnSettingsChanged fun(self: TargetedSpellsEditModeMixin, key: string, value: number|string)
---@field CreateSetting fun(self: TargetedSpellsEditModeMixin, key: string, defaults: SavedVariablesSettingsParty|SavedVariablesSettingsSelf): LibEditModeCheckbox | LibEditModeDropdown | LibEditModeSlider
---@field OnLayoutSettingChanged fun(self: TargetedSpellsEditModeMixin, key: string, value: number|string)
---@field AppendSettings fun(self: TargetedSpellsEditModeMixin)
---@field AcquireFrame fun(self: TargetedSpellsEditModeMixin): TargetedSpellsMixin
---@field ReleaseFrame fun(self: TargetedSpellsEditModeMixin, frame: TargetedSpellsMixin)
---@field OnEditModePositionChanged fun(self: TargetedSpellsEditModeMixin, frame: Frame, layoutName: string, point: string, x: number, y: number)
---@field RepositionPreviewFrames fun(self: TargetedSpellsEditModeMixin)
---@field LoopFrame fun(self: TargetedSpellsEditModeMixin, frame: TargetedSpellsMixin, index: number)
---@field StartDemo fun(self: TargetedSpellsEditModeMixin)
---@field ReleaseAllFrames fun(self: TargetedSpellsEditModeMixin)
---@field EndDemo fun(self: TargetedSpellsEditModeMixin)

---@class TargetedSpellsSelfEditMode : TargetedSpellsEditModeMixin
---@field maxFrames number
---@field frames TargetedSpellsMixin[]
---@field Init fun(self: TargetedSpellsSelfEditMode)
---@field ResizeEditModeFrame fun(self: TargetedSpellsSelfEditMode)
---@field ReleaseAllFrames fun(self: TargetedSpellsEditModeMixin)
---@field AppendSettings fun(self: TargetedSpellsEditModeMixin)
---@field RestoreEditModePosition fun(self: TargetedSpellsSelfEditMode)
---@field OnEditModePositionChanged fun(self: TargetedSpellsEditModeMixin, frame: Frame, layoutName: string, point: string, x: number, y: number)
---@field RepositionPreviewFrames fun(self: TargetedSpellsEditModeMixin)
---@field StartDemo fun(self: TargetedSpellsSelfEditMode)
---@field OnLayoutSettingChanged fun(self: TargetedSpellsEditModeMixin, key: string, value: number|string)

---@class TargetedSpellsPartyEditMode : TargetedSpellsEditModeMixin
---@field maxUnitCount number
---@field useRaidStylePartyFrames boolean
---@field amountOfPreviewFramesPerUnit number
---@field frames table<number, TargetedSpellsMixin[]>
---@field Init fun(self: TargetedSpellsPartyEditMode)
---@field AppendSettings fun(self: TargetedSpellsEditModeMixin)
---@field RepositionPreviewFrames fun(self: TargetedSpellsEditModeMixin)
---@field OnEditModePositionChanged fun(self: TargetedSpellsEditModeMixin, frame: Frame, layoutName: string, point: string, x: number, y: number)
---@field OnLayoutSettingChanged fun(self: TargetedSpellsEditModeMixin, key: string, value: number|string)
---@field RepositionPreviewFrames fun(self: TargetedSpellsEditModeMixin)
---@field StartDemo fun(self: TargetedSpellsEditModeMixin)
---@field ReleaseAllFrames fun(self: TargetedSpellsEditModeMixin)

---@class TargetedSpellsDriver
---@field framePool FramePool
---@field listenerFrame Frame
---@field role Role
---@field contentType ContentType
---@field sawPlayerLogin boolean
---@field frames table<string, TargetedSpellsMixin[]>
---@field SetupFrame fun(self: TargetedSpellsDriver, isBoot: boolean)
---@field AcquireFrames fun(self: TargetedSpellsDriver, castingUnit: string): TargetedSpellsMixin[]
---@field RepositionFrames fun(self: TargetedSpellsDriver)
---@field CleanUpUnit fun(self: TargetedSpellsDriver, unit: string, exceptSpellId?: number, id?: number): boolean
---@field LoadConditionsProhibitExecution fun(self: TargetedSpellsDriver, kind: FrameKind): boolean
---@field UnitIsIrrelevant fun(self: TargetedSpellsDriver, unit: string, skipTargetCheck?: boolean): boolean
---@field OnFrameEvent fun(self: TargetedSpellsDriver, listenerFrame: Frame, event: WowEvent, ...)
---@field OnSettingsChanged fun(self: TargetedSpellsDriver, key: string, value: number|string|table)
---@field MaybeApplyCombatAudioAlertOverride fun(self: TargetedSpellsMixin)
---@field ReleaseFrame fun(self: TargetedSpellsDriver, frame: TargetedSpellsMixin)
---@field DetermineSpellDelayRequirement fun(self: TargetedSpellsDriver): boolean

----- type patching / completion

---@class ExtendedCooldownTypes : Cooldown
---@field SetMinimumCountdownDuration fun(self: ExtendedCooldownTypes, minimumDuration: number)
---@field GetCountdownFontString fun(self: ExtendedCooldownTypes): FontString
---@field SetCooldownFromDurationObject fun(self: ExtendedCooldownTypes, durationObject: DurationObjectDummy, clearIfZero?: boolean)

---@class IconDataProviderMixin
---@field GetRandomIcon fun(self: IconDataProviderMixin): number

---@class FramePool
---@field Acquire fun(self: FramePool): TargetedSpellsMixin
---@field Release fun(self: FramePool, frame: TargetedSpellsMixin)

---@class LibEditModeSetting
---@field name string
---@field kind string
---@field desc string?
---@field default number|string|boolean|table
---@field disabled boolean?

---@class LibEditModeGetterSetter
---@field set fun(layoutName: string, value: number|string|boolean|table, fromReset: boolean)
---@field get fun(layoutName: string): number|string|boolean|table

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

---@class Frame
---@field SetAlphaFromBoolean fun(self: Frame, value: boolean)

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
function UnitIsSpellTarget(castingUnit, unit)
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

COOLDOWN_VIEWER_SETTINGS_ALERT_MENU_PLAY_SAMPLE = ""
COOLDOWN_VIEWER_SETTINGS_SOUND_ALERT_CATEGORY_ANIMALS = ""
COOLDOWN_VIEWER_SETTINGS_SOUND_ALERT_CATEGORY_DEVICES = ""
COOLDOWN_VIEWER_SETTINGS_SOUND_ALERT_CATEGORY_IMPACTS = ""
COOLDOWN_VIEWER_SETTINGS_SOUND_ALERT_CATEGORY_INSTRUMENTS = ""
COOLDOWN_VIEWER_SETTINGS_SOUND_ALERT_CATEGORY_WAR2 = ""
COOLDOWN_VIEWER_SETTINGS_SOUND_ALERT_CATEGORY_WAR3 = ""

CAA_COMBAT_AUDIO_ALERTS_LABEL = ""
ACCESSIBILITY_AUDIO_LABEL = ""
UNIT_NAMEPLATES_SHOW_OFFSCREEN = ""
CAA_SAY_IF_TARGETED_LABEL = ""

---@class Plater
---@field db { profile: { script_data: PlaterScriptData[] } }?

---@class PlaterScriptData
---@field Name string
---@field SpellIds number[]

---@type Plater
Plater = {}

C_CombatAudioAlert = {
	GetSpecSetting = function(id)
		return 0
	end,
}

---@type string|nil
GAME_LOCALE = ""

---@class CurveObjectBaseDummy
---@field GetType fun(self: CurveObjectBaseDummy): CurveType
---@field HasSecretValues fun(self: CurveObjectBaseDummy): boolean
---@field SetType fun(self: CurveObjectBaseDummy, type: CurveType)

---@class CurveObjectDummy: CurveObjectBaseDummy
---@field AddPoint fun(self: CurveObjectDummy, pointX: number, pointY: number)
---@field ClearPoints fun(self: CurveObjectDummy)
---@field Copy fun(self: CurveObjectDummy): CurveObjectDummy
---@field Evaluate fun(self: CurveObjectDummy, x: number): number
---@field GetPoint fun(self: CurveObjectDummy, index: number): number
---@field GetPointCount fun(self: CurveObjectDummy): number
---@field GetPointCount fun(self: CurveObjectDummy): number
---@field RemovePoint fun(self: CurveObjectDummy, index: number)
---@field SetPoints fun(self: CurveObjectDummy, point: nil)
---@field SetToDefaults fun(self: CurveObjectDummy)

---@class DurationObjectDummy
---@field Assign fun(self: DurationObjectDummy, other: DurationObjectDummy)
---@field copy fun(self: DurationObjectDummy): DurationObjectDummy
---@field EvaluateElapsedPercent fun(self: DurationObjectDummy, curve: CurveObjectDummy, modifier: number?): number
---@field EvaluateRemainingPercent fun(self: DurationObjectDummy, curve: CurveObjectDummy, modifier: number?): number
---@field GetElapsedDuration fun(self: DurationObjectDummy, modifier: number?): number
---@field GetElapsedPercent fun(self: DurationObjectDummy, modifier: number?): number
---@field GetEndTime fun(self: DurationObjectDummy, modifier: number?): number
---@field GetModRate fun(self: DurationObjectDummy): number
---@field GetRemainingDuration fun(self: DurationObjectDummy, modifier: number?): number
---@field GetRemainingPercent fun(self: DurationObjectDummy, modifier: number?): number
---@field GetStartTime fun(self: DurationObjectDummy, modifier: number?): number
---@field GetTotalDuration fun(self: DurationObjectDummy, modifier: number?): number
---@field HasSecretValues fun(self: DurationObjectDummy): boolean
---@field IsZero fun(self: DurationObjectDummy): boolean
---@field Reset fun(self: DurationObjectDummy)
---@field SetTimeFromEnd fun(self: DurationObjectDummy, endTime: number, duration: number, modRate: number?)
---@field SetTimeFromStart fun(self: DurationObjectDummy, startTime: number, duration: number, modRate: number?)
---@field SetTimeSpan fun(self: DurationObjectDummy, startTime: number, endTime: number)
---@field SetToDefaults fun(self: DurationObjectDummy)

---@param unit string
---@return DurationObjectDummy
UnitCastingDuration = function(unit)
	return {}
end

---@param unit string
---@return DurationObjectDummy
UnitChannelDuration = function(unit)
	return {}
end

---@class UnitFrameButton : Button
---@field castBar StatusBar

---@class Nameplate
---@field UnitFrame UnitFrameButton

---@class CombatAudioAlertManager : Frame
---@field GetUnitFormattedTargetingString fun(self: CombatAudioAlertManager, unit: string): string

CombatAudioAlertManager = {
	GetUnitFormattedTargetingString = function(unit)
		return ""
	end,
}

-- third party unit frame addons
---@class DandersFrames
---@field Api { GetFrameForUnit: fun(unit: string, kind: FrameKind): Frame? }

---@type DandersFrames?
DandersFrames = nil

---@type Frame?
DandersPartyGroupContainer = nil

---@type table<string, CustomSound[]>
CooldownViewerSoundData = {}
