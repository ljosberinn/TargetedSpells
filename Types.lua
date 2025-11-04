---@meta

---@class TargetedSpells
---@field IsMidnight boolean
---@field EventRegistry CallbackRegistryMixin
---@field Events table<string, string>
---@field Enum TargetedSpellsEnums
---@field Settings TargetedSpellsSettings
---@field LoginFnQueue table<string, function>

---@class TargetedSpellsEnums

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

---@class SavedVariables
---@field Settings SavedVariablesSettings

---@class SavedVariablesSettings
---@field Self SavedVariablesSettingsSelf
---@field Party SavedVariablesSettingsParty

---@class SavedVariablesSettingsSelf
---@field Enabled boolean
---@field Width number
---@field Height number
---@field Gap number
---@field Direction Direction
---@field LoadConditionContentType boolean[]
---@field LoadConditionRole boolean[]
---@field PlaySound boolean
---@field Sound string
---@field LoadConditionSoundContentType boolean[]
---@field SortOrder SortOrder
---@field Grow Grow

---@class SavedVariablesSettingsParty
---@field Enabled boolean
---@field Width number
---@field Height number
---@field Gap number
---@field Direction Direction
---@field LoadConditionContentType boolean[]
---@field LoadConditionRole boolean[]
---@field OffsetX number
---@field OffsetY number
---@field SourceAnchor Anchor
---@field TargetAnchor Anchor
---@field SortOrder SortOrder
---@field Grow Grow

---@class TargetedSpellsSelfPreviewFrame: Frame
---@field GetChildren fun(self: TargetedSpellsSelfPreviewFrame): TargetedSpellsMixin

---@class TargetedSpellsMixin : Frame
---@field Overlay Texture
---@field Icon Texture
---@field Cooldown Cooldown
---@field OnLoad fun(self: TargetedSpellsMixin)
---@field kind string<'Party' | 'Self'>
---@field SetKind fun(self: TargetedSpellsMixin, kind: string)
---@field GetKind fun(self: TargetedSpellsMixin): string
---@field OnKindChanged fun(self: TargetedSpellsMixin, kind: string)
---@field unit string?
---@field SetUnit fun(self: TargetedSpellsMixin, unit: string)
---@field GetUnit fun(self: TargetedSpellsMixin): string
---@field startTime number?
---@field ClearStartTime fun(self: TargetedSpellsMixin)
---@field GetStartTime fun(self: TargetedSpellsMixin): number
---@field SetStartTime fun(self: TargetedSpellsMixin)
---@field castTime number?
---@field GetCastTime fun(self: TargetedSpellsMixin): number
---@field SetCastTime fun(self: TargetedSpellsMixin, castTime: number)
---@field texture number?
---@field SetSpellTexture fun(self: TargetedSpellsMixin, texture: number?)
---@field GetSpellTexture fun(self: TargetedSpellsMixin)
---@field RefreshSpellTexture fun(self: TargetedSpellsMixin)
---@field RefreshSpellCooldownInfo fun(self: TargetedSpellsMixin)
---@field hideTimer FunctionContainer?
---@field loopTicker FunctionContainer?
---@field OnSizeChanged fun(self: TargetedSpellsMixin, width: number, height: number)
---@field OnSettingChanged fun(self: TargetedSpellsMixin, key: string, value: number|string)
---@field UpdateShownState fun(self: TargetedSpellsMixin)
---@field ShouldBeShown fun(self: TargetedSpellsMixin): boolean
---@field Reposition fun(self: TargetedSpellsMixin, point: string, relativeTo: Frame, relativePoint: string, offsetX: number, offsetY: number)
---@field StartPreviewLoop fun(self: TargetedSpellsMixin, RepositionPreviewFrames: fun())
---@field StopPreviewLoop fun(self: TargetedSpellsMixin)
---@field settingsCallbackId number?

---@class IconDataProviderMixin
---@field GetRandomIcon fun(self: IconDataProviderMixin): number

---@class FramePool
---@field Acquire fun(self: FramePool): TargetedSpellsMixin
---@field Release fun(self: FramePool, frame: TargetedSpellsMixin)

---@class LibEditModeSetting
---@field name string
---@field kind string
---@field default number|string|boolean|table

---@class LibEditModeCheckbox : LibEditModeSetting
---@field get fun(layoutName: string): number|string|boolean|table
---@field set fun(layoutName: string, value: number|string|boolean|table)

---@class LibEditModeDropdown : LibEditModeSetting
---@field generator fun(owner, rootDescription, data)
---@field set fun(layoutName: string, value: number|string|boolean|table)

---@class LibEditModeSlider : LibEditModeSetting
---@field get fun(layoutName: string): number|string|boolean|table
---@field set fun(layoutName: string, value: number|string|boolean|table)
---@field minValue number
---@field maxValue number
---@field valueStep number

---@class TargetedSpellsEditModeParentFrameMixin
---@field Init fun(self: TargetedSpellsEditModeParentFrameMixin, displayName: string, frameKind: FrameKind)
---@field editModeFrame Frame
---@field demoPlaying boolean
---@field framePool FramePool
---@field frames table<number, TargetedSpellsMixin[]> | TargetedSpellsMixin[]
---@field demoTimers { tickers: table<number, FunctionContainer>, timers: table<number, FunctionContainer> }
---@field StartDemo fun(self: TargetedSpellsEditModeParentFrameMixin)
---@field EndDemo fun(self: TargetedSpellsEditModeParentFrameMixin, forceDisable: boolean?)
---@field OnEditModePositionChanged fun(self: TargetedSpellsEditModeParentFrameMixin, frame: Frame, layoutName: string, point: string, x: number, y: number)
---@field RepositionPreviewFrames fun(self: TargetedSpellsEditModeParentFrameMixin)
---@field SortFrames fun(self: TargetedSpellsEditModeParentFrameMixin, frames: TargetedSpellsMixin[], sortOrder: SortOrder)
---@field buildingFrames true|nil
---@field CreateSetting fun(self: TargetedSpellsEditModeParentFrameMixin, key: string): LibEditModeCheckbox | LibEditModeDropdown | LibEditModeSlider
---@field AcquireFrame fun(self: TargetedSpellsEditModeParentFrameMixin): TargetedSpellsMixin
---@field LoopFrame fun(self: TargetedSpellsEditModeParentFrameMixin, frame: TargetedSpellsMixin, index: number)
---@field ReleaseFrame fun(self: TargetedSpellsEditModeParentFrameMixin, frame: TargetedSpellsMixin)
---@field OnSettingsChanged fun(self: TargetedSpellsEditModeParentFrameMixin, key: string, value: number|string)
---@field ReleaseAllFrames fun(self: TargetedSpellsEditModeParentFrameMixin)

---@class TargetedSpellsSelfEditModeFrame : TargetedSpellsEditModeParentFrameMixin
---@field maxFrameCount number
---@field frames TargetedSpellsMixin[]
---@field ResizeEditModeFrame fun(self: TargetedSpellsSelfEditModeFrame)
---@field StartDemo fun(self: TargetedSpellsSelfEditModeFrame)

---@class TargetedSpellsPartyEditModeFrame : TargetedSpellsEditModeParentFrameMixin
---@field maxUnitCount number
---@field useRaidStylePartyFrames boolean
---@field amountOfPreviewFramesPerUnit number
---@field frames table<number, TargetedSpellsMixin[]>
---@field RepositionEditModeFrame fun(self: TargetedSpellsPartyEditModeFrame)
---@field StartDemo fun(self: TargetedSpellsPartyEditModeFrame)
