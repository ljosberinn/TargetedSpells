---@class TargetedSpells
---@field IsMidnight boolean
---@field EventRegistry CallbackRegistryMixin
---@field Events table<string, string>
---@field Enum TargetedSpellsEnums
---@field Settings TargetedSpellsSettings
---@field LoginFnQueue table<string, function>

---@class TargetedSpellsEnums
---@field GrowDirection table<string, number>
---@field ContentType table<string, number>
---@field Role table<string, number>
---@field FrameKind table<'Party' | 'Self', string>

---@class SliderSettings
---@field min number
---@field max number
---@field step number

---@class TargetedSpellsSettings
---@field CreateSettings fun()
---@field Keys table<'Party' | 'Self', table<string, string>>
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
---@field Spacing number
---@field GrowDirection number
---@field LoadConditionContentType boolean[]
---@field LoadConditionRole boolean[]
---@field PlaySound boolean
---@field Sound string
---@field LoadConditionSoundContentType boolean[]

---@class SavedVariablesSettingsParty
---@field Enabled boolean
---@field Width number
---@field Height number
---@field Spacing number
---@field GrowDirection number
---@field LoadConditionContentType boolean[]
---@field LoadConditionRole boolean[]

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
---@field relationalUnit string?
---@field SetRelationalUnit fun(self: TargetedSpellsMixin, unit: string)
---@field GetRelationalUnit fun(self: TargetedSpellsMixin): string?

---@class IconDataProviderMixin
---@field GetRandomIcon fun(self: IconDataProviderMixin): number
