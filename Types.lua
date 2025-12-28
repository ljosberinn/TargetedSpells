---@meta

---@class TargetedSpells
---@field IsMidnight boolean
---@field EventRegistry CallbackRegistryMixin
---@field Events table<string, string>
---@field Enum TargetedSpellsEnums
---@field Settings TargetedSpellsSettings
---@field LoginFnQueue table<string, function>
---@field L table<string, table<string, string|nil>>
---@field Utils TargetedSpellsUtils

---@class TargetedSpellsUtils
---@field FlipCoin fun(): boolean
---@field CalculateCoordinate fun(index: number, dimension: number, gap: number, parentDimension: number, total: number, offset: number, grow: Grow): number
---@field SortFrames fun(frames: TargetedSpellsMixin[], sortOrder: SortOrder)
---@field AttemptToPlaySound fun(sound: string|number, channel: SoundChannel)

---@class TargetedSpellsEnums

---@class CustomSound
---@field soundKitID number|string
---@field text string
---@field isFile boolean?

---@class SliderSettings
---@field min number
---@field max number
---@field step number

---@class TargetedSpellsSettings
---@field CreateSettings fun()
---@field Keys table<'Self' | 'Party', table<string, string>>
---@field GetSelfDefaultSettings fun(): SavedVariablesSettingsSelf
---@field GetPartyDefaultSettings fun(): SavedVariablesSettingsParty
---@field GetSliderSettingsForOption fun(key: string): SliderSettings
---@field GetDefaultEditModeFramePosition fun(): SelfFramePosition
---@field GetCustomSoundGroups fun(groupThreshold: number?):  SoundInfo
---@field GetCooldownViewerSounds fun(): SoundInfo

---@class SoundInfo
---@field soundCategoryKeyToLabel table<string, string>
---@field data table<string, CustomSound[]>

---@class SavedVariables
---@field Settings SavedVariablesSettings

---@class SavedVariablesSettings
---@field Self SavedVariablesSettingsSelf
---@field Party SavedVariablesSettingsParty

---@class SelfFramePosition
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
---@field Position SelfFramePosition
---@field MaxElements number
---@field ShowBorder boolean
---@field GlowImportant boolean

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
---@field ShowBorder boolean
---@field GlowImportant boolean

---@class TargetedSpellsSelfPreviewFrame: Frame
---@field GetChildren fun(self: TargetedSpellsSelfPreviewFrame): TargetedSpellsMixin

---@class ExtendedCooldownTypes : Cooldown
---@field SetMinimumCountdownDuration fun(self: ExtendedCooldownTypes, minimumDuration: number)
---@field GetCountdownFontString fun(self: ExtendedCooldownTypes): FontString

---@class TargetedSpellsMixin : Frame, BackdropTemplate
---@field Overlay Texture
---@field Icon Texture
---@field Cooldown ExtendedCooldownTypes
---@field SpellActivationAlert ActionButtonSpellAlertTemplate? -- only present if important spells should be highlighted
---@field kind FrameKind?
---@field unit string? -- secret?
---@field startTime number?
---@field castTime number? -- secret
---@field OnLoad fun(self: TargetedSpellsMixin)
---@field SetKind fun(self: TargetedSpellsMixin, kind: FrameKind)
---@field GetKind fun(self: TargetedSpellsMixin): FrameKind?
---@field OnKindChanged fun(self: TargetedSpellsMixin, kind: FrameKind)
---@field SetUnit fun(self: TargetedSpellsMixin, unit: string)
---@field GetUnit fun(self: TargetedSpellsMixin): string
---@field ClearStartTime fun(self: TargetedSpellsMixin)
---@field GetStartTime fun(self: TargetedSpellsMixin): number
---@field SetStartTime fun(self: TargetedSpellsMixin, startTime: number?)
---@field SetCastTime fun(self: TargetedSpellsMixin, castTime: number)
---@field SetSpellId fun(self: TargetedSpellsMixin, spellId: number?)
---@field RefreshSpellCooldownInfo fun(self: TargetedSpellsMixin)
---@field OnSizeChanged fun(self: TargetedSpellsMixin, width: number, height: number)
---@field OnSettingChanged fun(self: TargetedSpellsMixin, key: string, value: number|string)
---@field ShouldBeShown fun(self: TargetedSpellsMixin): boolean
---@field Reposition fun(self: TargetedSpellsMixin, point: string, relativeTo: Frame, relativePoint: string, offsetX: number, offsetY: number)
---@field AttemptToPlaySound fun(self: TargetedSpellsMixin)
---@field SetShowDuration fun(self: TargetedSpellsMixin, showDuration: boolean)
---@field SetFontSize fun(self: TargetedSpellsMixin, fontSize: number)
---@field PostCreate fun(self: TargetedSpellsMixin, unit: string, kind: FrameKind, castingUnit: string?)

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

---@class ActionButtonSpellAlertTemplate: Frame

---@class TargetedSpellsEditModeMixin : Frame
---@field Init fun(self: TargetedSpellsEditModeMixin, displayName: string, frameKind: FrameKind)
---@field editModeFrame Frame
---@field demoPlaying boolean
---@field framePool FramePool
---@field frames table<number, TargetedSpellsMixin[]> | TargetedSpellsMixin[]
---@field demoTimers { tickers: table<number, FunctionContainer>, timers: table<number, FunctionContainer> }
---@field StartDemo fun(self: TargetedSpellsEditModeMixin)
---@field EndDemo fun(self: TargetedSpellsEditModeMixin, forceDisable: boolean?)
---@field OnEditModePositionChanged fun(self: TargetedSpellsEditModeMixin, frame: Frame, layoutName: string, point: string, x: number, y: number)
---@field RepositionPreviewFrames fun(self: TargetedSpellsEditModeMixin)
---@field SortFrames fun(self: TargetedSpellsEditModeMixin, frames: TargetedSpellsMixin[], sortOrder: SortOrder)
---@field buildingFrames true|nil
---@field CreateSetting fun(self: TargetedSpellsEditModeMixin, key: string): LibEditModeCheckbox | LibEditModeDropdown | LibEditModeSlider
---@field AcquireFrame fun(self: TargetedSpellsEditModeMixin): TargetedSpellsMixin
---@field LoopFrame fun(self: TargetedSpellsEditModeMixin, frame: TargetedSpellsMixin, index: number)
---@field ReleaseFrame fun(self: TargetedSpellsEditModeMixin, frame: TargetedSpellsMixin)
---@field OnSettingsChanged fun(self: TargetedSpellsEditModeMixin, key: string, value: number|string)
---@field ReleaseAllFrames fun(self: TargetedSpellsEditModeMixin)
---@field CalculateCoordinate fun(self: TargetedSpellsEditModeMixin, index: number, dimension: number, gap: number, parentDimension: number, total: number, offset: number, grow: Grow): number

---@class TargetedSpellsSelfEditMode : TargetedSpellsEditModeMixin
---@field Init fun(self: TargetedSpellsSelfEditMode)
---@field frames TargetedSpellsMixin[]
---@field ResizeEditModeFrame fun(self: TargetedSpellsSelfEditMode)
---@field StartDemo fun(self: TargetedSpellsSelfEditMode)

---@class TargetedSpellsPartyEditMode : TargetedSpellsEditModeMixin
---@field Init fun(self: TargetedSpellsPartyEditMode)
---@field maxUnitCount number
---@field useRaidStylePartyFrames boolean
---@field amountOfPreviewFramesPerUnit number
---@field frames table<number, TargetedSpellsMixin[]>
---@field RepositionEditModeFrame fun(self: TargetedSpellsPartyEditMode)
---@field StartDemo fun(self: TargetedSpellsPartyEditMode)

---@class TargetedSpellsDriver
---@field framePool FramePool
---@field listenerFrame Frame
---@field frames table<string, TargetedSpellsMixin[]>
---@field OnSettingsChanged fun(self: TargetedSpellsDriver, key: string, value: number|string)
---@field OnFrameEvent fun(self: TargetedSpellsDriver, listenerFrame: Frame, event: WowEvent, ...)
---@field SetupListenerFrame fun(self: TargetedSpellsDriver, isBoot: boolean)
---@field AcquireFrames fun(self: TargetedSpellsDriver, castingUnit: string): TargetedSpellsMixin
---@field SortFrames fun(self: TargetedSpellsDriver, frames: TargetedSpellsMixin[], sortOrder: SortOrder)

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
