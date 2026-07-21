---@meta

---@class TargetedSpells
---@field EventRegistry CallbackRegistryMixin
---@field Events table<string, string>
---@field Enum TargetedSpellsEnums
---@field Settings TargetedSpellsSettings
---@field LoginFnQueue table<string, function>
---@field L table<string, table<string, string|nil>>
---@field Utils TargetedSpellsUtils
---@field Design TargetedSpellsDesign
---@field Groups TargetedSpellsGroups
---@field GroupController TargetedSpellsGroupController
---@field Migration TargetedSpellsMigration
---@field EditMode TargetedSpellsEditModeManager
---@field Designer TargetedSpellsDesigner
---@field __test table?
---@field Glows GlowFunctions
---@field TextToSpeechUtil TargetedSpellsTextToSpeechUtil

---@class TargetedSpellsTextToSpeechUtil
---@field MaybeAnnounceSpell fun(info: SpellCastInfo, contentType: ContentType, activeEncounterId: number)
---@field ClearAnnouncementCacheForUnit fun(unit: string)

---@class TargetedSpellsDesigner
---@field Toggle fun()

---@class CollectLayoutingArguments
---@field isHorizontal boolean
---@field isGrowEnd boolean
---@field orientation "HORIZONTAL"|"VERTICAL"
---@field x number
---@field y number
---@field originPoint FramePoint
---@field relativePoint FramePoint

---@class TargetedSpellsUtils
---@field DeepCopy fun(source: any): any
---@field CollectLayoutingArguments fun(direction: Direction, grow: Grow, width: number, height: number, gap: number, out?: CollectLayoutingArguments): CollectLayoutingArguments
---@field ComputeElementExtent fun(elements: table<Element, table<string, any>>): { width: number, height: number, offsetX: number, offsetY: number }
---@field ComputeGroupExtent fun(elements: table<Element, table<string, any>>): { width: number, height: number, offsetX: number, offsetY: number }
---@field ComputeBarLayout fun(elements: table<Element, table<string, any>>): table<any, any>
---@field AdjustLayout fun(frames: TargetedSpellsIconMixin[], geo: CollectLayoutingArguments, barParent: Frame, firstAnchorPoint: FramePoint, firstOffsetX: number, firstOffsetY: number)
---@field SortFrames fun(frames: TargetedSpellsIconMixin[], sortOrder: SortOrder)
---@field RollDice fun(): boolean
---@field ShowStaticPopup fun(args: StaticPopupDialogsArgs)
---@field Import fun(string: string): boolean
---@field Export fun(): string
---@field RegisterEditModeFrame fun(groupId: integer, frame: Frame)
---@field GetEditModeFrame fun(groupId: integer): Frame?
---@field CreateEditablePopup fun(title: string, text: string, button1: string): StaticPopupDialogsArgs
---@field Pools { Icon: FramePool<TargetedSpellsIconMixin>, Bar: FramePool<TargetedSpellsBarMixin> }
---@field ShowMigrationPopup fun()
---@field MigratePartySettingsToV3 fun(existing: table): SavedVariablesSettingsParty
---@field ApplyMigration fun(key: string, kind: FrameKind, defaults: SavedVariablesSettingsSelf|SavedVariablesSettingsParty)
---@field SafelySetFont fun(fontString: FontString, font: string, fontSize: number, fontFlags: string)
---@field CreateCountdownFormatter fun(): NumericFormatter
---@field ApplyFractionThreshold fun(formatter: NumericFormatter, fractionThreshold: number?)
---@field RegisterSlashCommand fun(name: string, description: string, handler: fun(rest: string))

-- ── v4 model ───────────────────────────────────────────────────────

-- One schema record: mirrors Blizzard's systemSettingDisplayInfo shape. `type`
-- selects the designer widget (boolean/number/color/enum/font/fontFlags/texture).
---@class TargetedSpellsElementRecord
---@field setting string
---@field name string
---@field type string
---@field default any
---@field min number?
---@field max number?
---@field step number?
---@field options table[]?
---@field mediaType string? -- for texture records: "statusbar" | "background" | "border"

-- A group owns its Template + Elements 1:1 (no shared Design). Core element's
-- width/height live in Elements[core]; there is no top-level Width/Height.
---@class TargetedSpellsGroup
---@field Id integer -- denormalised from the Groups map key at load (Driver)
---@field Name string
---@field Enabled boolean
---@field Filter table<TargetClass, boolean>
---@field Template TargetedSpellsTemplate
---@field Elements table<Element, table<string, any>>
---@field Position FramePosition
---@field Gap number
---@field Grow Grow
---@field Direction Direction
---@field SortOrder SortOrder
---@field LoadConditionContentType table<number, boolean>
---@field LoadConditionRole table<number, boolean>
---@field GlowType GlowType
---@field GlowImportant boolean
---@field OnlyImportant boolean
---@field IndicateInterrupts boolean

---@class TargetedSpellsDesign
---@field GetDefault fun(template: TargetedSpellsTemplate): table<Element, table<string, any>>
---@field GetSchema fun(template: TargetedSpellsTemplate): table<Element, TargetedSpellsElementRecord[]>
---@field CopyElements fun(elements: table): table
---@field BackfillElements fun(group: TargetedSpellsGroup)

---@class TargetedSpellsGroups
---@field GetMatching fun(info: { targetClasses: table<TargetClass, boolean> }, groups: table<any, TargetedSpellsGroup>?): TargetedSpellsGroup[]
---@field Create fun(template: TargetedSpellsTemplate, saved: table?): integer, TargetedSpellsGroup
---@field Delete fun(id: integer, saved: table?): boolean
---@field SetTemplate fun(group: TargetedSpellsGroup, template: TargetedSpellsTemplate)
---@field Count fun(saved: table?): number
---@field SortedIds fun(groups: table): integer[]
---@field InvalidateOrder fun(groups: table)
---@field ComputeCapabilities fun(groups: table<integer, TargetedSpellsGroup>): TargetedSpellsGroupCapabilities
---@field LoadConditionsApply fun(self: TargetedSpellsGroups, role: Role, contentType: ContentType): boolean

---@class TargetedSpellsGroupCapabilities
---@field enabled boolean -- any group Enabled
---@field usesInterruptibility boolean -- any enabled Bar group colouring by interruptibility
---@field usesShield boolean -- any enabled Bar group with an active InterruptShield
---@field showsTargetMarker boolean -- any enabled Bar group with an active TargetMarker
---@field indicatesInterrupts boolean -- any group with IndicateInterrupts (independent of Enabled)

---@class TargetedSpellsTextToSpeech
---@field AnnounceUntargetedSpells table<NpcType, boolean>
---@field AnnounceTargetedSpells table<NpcType, boolean>
---@field TextToSpeechVoice integer|nil

-- v4 SavedVariables container. Groups replace the fixed Settings.Self/Party
-- trees; TTS is hoisted to one global table. No `Designs` map (layout is 1:1).
---@class SavedVariablesV4
---@field SchemaVersion integer
---@field Groups table<integer, TargetedSpellsGroup>
---@field TextToSpeech TargetedSpellsTextToSpeech

---@class TargetedSpellsMigration
---@field Apply fun(saved: table): table

---@class TargetedSpellsEditModeManager
---@field instances table<integer, TargetedSpellsEditModeMixin>
---@field CreateInstance fun(group: TargetedSpellsGroup): TargetedSpellsEditModeMixin
---@field CreateGroup fun()
---@field DeleteGroup fun(groupId: integer)

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
---@field id number|string|nil

---@class SpellCastInfo
---@field unit string
---@field spellId number
---@field startTime number
---@field id number|string
---@field duration DurationObject
---@field isChannel boolean
---@field isRetarget boolean?
---@field targetClasses table<TargetClass, boolean>?
---@field dueAt number?

---@class FontInfo
---@field fonts table<string, string>
---@field byLabel table<string, string>

---@class TargetedSpellsSettings
---@field Keys table<'Self' | 'Party', table<string, string>>
---@field GetDefaultEditModeFramePosition fun(kind: FrameKind): FramePosition
---@field GetSelfDefaultSettings fun(): SavedVariablesSettingsSelf
---@field GetPartyDefaultSettings fun(): SavedVariablesSettingsParty
---@field GetGlowTypesForKind fun(kind: FrameKind): GlowType[]
---@field GetFontOptions fun(): FontInfo

---@class SavedVariables
---@field Settings SavedVariablesSettings
---@field nameplateShowOffscreenWasInitialized boolean
---@field SchemaVersion integer?
---@field Groups table<integer, TargetedSpellsGroup>?
---@field TextToSpeech TargetedSpellsTextToSpeech?

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
---@field AnnounceUntargetedSpells table<NpcType, boolean>
---@field AnnounceTargetedSpells table<NpcType, boolean>
---@field TextToSpeechVoice integer|nil

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
---@field AnnounceUntargetedSpells table<NpcType, boolean>
---@field AnnounceTargetedSpells table<NpcType, boolean>
---@field TextToSpeechVoice integer|nil
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

---@class TargetedSpellsMixin : Frame
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
---@field private group TargetedSpellsGroup?
---@field private layoutOverride table<Element, table<string, any>>?
---@field SetGroup fun(self: TargetedSpellsMixin, group: TargetedSpellsGroup?)
---@field GetGroup fun(self: TargetedSpellsMixin): TargetedSpellsGroup?
---@field SetLayoutOverride fun(self: TargetedSpellsMixin, elements: table<Element, table<string, any>>?)
---@field ClearLayoutOverride fun(self: TargetedSpellsMixin)
---@field GetElements fun(self: TargetedSpellsMixin): table<Element, table<string, any>>?
---@field GetElement fun(self: TargetedSpellsMixin, element: Element): table<string, any>?
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
---@field Cooldown ExtendedCooldownTypes
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
---@field PostCreate fun(self: TargetedSpellsIconMixin, info: SpellCastInfo?, OnCooldownDoneCallback: fun(info: SpellCastInfo))
---@field Reset fun(self: TargetedSpellsIconMixin)
---@field SetFont fun(self: TargetedSpellsIconMixin)

---@class TargetedSpellsBarProgressBar : StatusBar
---@field Background Texture
---@field SpellName FontString
---@field TargetName FontString
---@field InterruptSource FontString

---@class TargetedSpellsBarCustomElementsFrame : Frame
---@field TargetMarker Texture
---@field InterruptShield Texture

---@class TargetedSpellsBarMixin : TargetedSpellsMixin
---@field unit string?
---@field ProgressBar TargetedSpellsBarProgressBar
---@field CustomElementsFrame TargetedSpellsBarCustomElementsFrame
---@field DurationCooldown ExtendedCooldownTypes
---@field OnLoad fun(self: TargetedSpellsBarMixin)
---@field OnSizeChanged fun(self: TargetedSpellsBarMixin)
---@field Reset fun(self: TargetedSpellsBarMixin)
---@field PostCreate fun(self: TargetedSpellsBarMixin, info: SpellCastInfo?, OnCooldownDoneCallback: fun(info: SpellCastInfo)?)
---@field SetShowDuration fun(self: TargetedSpellsBarMixin, showDuration: boolean)
---@field SetFont fun(self: TargetedSpellsBarMixin)
---@field SetDuration fun(self: TargetedSpellsBarMixin, duration: DurationObject): number
---@field SetForegroundBarTexture fun(self: TargetedSpellsBarMixin)
---@field SetBackgroundBarTexture fun(self: TargetedSpellsBarMixin)
---@field SetBackgroundBarColor fun(self: TargetedSpellsBarMixin)
---@field SetProgressBarColor fun(self: TargetedSpellsBarMixin)
---@field SetPreviewBarColor fun(self: TargetedSpellsBarMixin)
---@field AdjustInterruptibleColor fun(self: TargetedSpellsBarMixin, isInterruptible: boolean)
---@field AdjustInterruptShield fun(self: TargetedSpellsBarMixin, isInterruptible: boolean)
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
---@field Init fun(self: TargetedSpellsEditModeMixin, group: TargetedSpellsGroup)
---@field group TargetedSpellsGroup
---@field groupId integer
---@field deleted boolean?
---@field OnGroupChanged fun(self: TargetedSpellsEditModeMixin, groupId: integer)
---@field GroupTemplatePool fun(self: TargetedSpellsEditModeMixin): FramePool<TargetedSpellsIconMixin>|FramePool<TargetedSpellsBarMixin>
---@field CreateManagementButtons fun(self: TargetedSpellsEditModeMixin): LibEditModeButton[]
---@field OnRenameButtonClick fun(self: TargetedSpellsEditModeMixin)
---@field OnDeleteButtonClick fun(self: TargetedSpellsEditModeMixin)
---@field CreateSetting fun(self: TargetedSpellsEditModeMixin, base: string): LibEditModeButton|LibEditModeCheckbox|LibEditModeDropdown|LibEditModeSlider|LibEditModeColorPicker
---@field ResizeEditModeFrame fun(self: TargetedSpellsEditModeMixin)
---@field RestoreEditModePosition fun(self: TargetedSpellsEditModeMixin)
---@field OnProfileImported fun(self: TargetedSpellsEditModeMixin)
---@field OnEditModePositionChanged fun(self: TargetedSpellsEditModeMixin, frame: Frame, layoutName: string, point: FramePoint, x: number, y: number)
---@field AppendSettings fun(self: TargetedSpellsEditModeMixin)
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

---@class TargetedSpellsGroupController
---@field group TargetedSpellsGroup
---@field container Frame?
---@field pool FramePool<TargetedSpellsIconMixin|TargetedSpellsBarMixin>
---@field coreElement Element
---@field frames (TargetedSpellsIconMixin|TargetedSpellsBarMixin)[]
---@field layoutScratch CollectLayoutingArguments
---@field New fun(group: TargetedSpellsGroup): TargetedSpellsGroupController
---@field GetContainer fun(self: TargetedSpellsGroupController): Frame
---@field Position fun(self: TargetedSpellsGroupController)
---@field Acquire fun(self: TargetedSpellsGroupController, info: SpellCastInfo, onCooldownClosure: fun(info: SpellCastInfo)): TargetedSpellsIconMixin|TargetedSpellsBarMixin
---@field Release fun(self: TargetedSpellsGroupController, frame: TargetedSpellsIconMixin|TargetedSpellsBarMixin)
---@field Relayout fun(self: TargetedSpellsGroupController)
---@field Reconfigure fun(self: TargetedSpellsGroupController, group: TargetedSpellsGroup)

---@class TargetedSpellsDriver
---@field private frame Frame
---@field private role Role
---@field private contentType ContentType
---@field private delay number
---@field private pendingCasts table<integer, SpellCastInfo>
---@field private pendingHead integer
---@field private pendingTail integer
---@field private drainScheduled boolean
---@field private DrainPendingCastsClosure fun()
---@field private DrainPendingCasts fun(self: TargetedSpellsDriver)
---@field private OnCooldownDoneClosure fun(info: SpellCastInfo)
---@field private activeEncounterId number?
---@field frames table<string, (TargetedSpellsIconMixin|TargetedSpellsBarMixin)[]>
---@field controllers table<integer, TargetedSpellsGroupController>
---@field OnGroupPositionChanged fun(self: TargetedSpellsDriver, groupId: integer)
---@field GetController fun(self: TargetedSpellsDriver, group: TargetedSpellsGroup): TargetedSpellsGroupController
---@field SetupFrame fun(self: TargetedSpellsDriver, isBoot: boolean)
---@field capabilities TargetedSpellsGroupCapabilities? -- cached summary; nil = dirty
---@field GetCapabilities fun(self: TargetedSpellsDriver): TargetedSpellsGroupCapabilities
---@field InvalidateCapabilities fun(self: TargetedSpellsDriver)
---@field AnyGroupLoadConditionsAllow fun(self: TargetedSpellsDriver): boolean
---@field GetTargetClasses fun(self: TargetedSpellsDriver, info: SpellCastInfo): table<TargetClass, boolean>
---@field ProcessInfo fun(self: TargetedSpellsDriver, info: SpellCastInfo)
---@field ReleaseFrame fun(self: TargetedSpellsDriver, frame: TargetedSpellsIconMixin|TargetedSpellsBarMixin)
---@field ReleaseAllOwnFrames fun(self: TargetedSpellsDriver)
---@field RepositionFrames fun(self: TargetedSpellsDriver, dirtyGroups?: table<integer, boolean>)
---@field ReleaseFrameForUnit fun(self: TargetedSpellsDriver, unit: string, removeUnit: boolean, id?: number, dirtyGroups?: table<integer, boolean>): boolean
---@field UnitIsIrrelevant fun(self: TargetedSpellsDriver, unit: string, skipTargetCheck?: boolean): boolean
---@field OnFrameEvent fun(self: TargetedSpellsDriver, listenerFrame: Frame, event: WowEvent, ...)
---@field OnProfileImported fun(self: TargetedSpellsDriver)
---@field MaybeMarkAsInterruptedAndDelay fun(self: TargetedSpellsDriver, unit: string, id: number|string|nil, interruptedBy: string?)
---@field CleanupDanglingFrames fun(self: TargetedSpellsDriver)
---@field GetCastInformation fun(self: TargetedSpellsDriver, unit: string): boolean, number, number

---@class NumericFormatter
---@field SetBreakpoints fun(self: NumericFormatter, breakpoints: table)

---@class DurationObject
---@field FormatRemainingDuration fun(self: DurationObject, formatter: NumericFormatter, modifier?: string): string
---@field GetTimeFraction fun(self: DurationObject): number

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
