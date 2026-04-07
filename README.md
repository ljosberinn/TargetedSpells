# Targeted Spells

[![](https://img.shields.io/badge/patreon-red?logo=patreon&style=for-the-badge)](https://www.patreon.com/cw/warcraftlogs)
[![](https://shields.io/badge/discord-lightblue?logo=discord&style=for-the-badge)](https://discord.gg/C5STjYRsCD)

- [Curseforge](https://www.curseforge.com/wow/addons/targetedspells)
- [Wago](https://addons.wago.io/addons/targeted-spells)

## Why?

- the default UI continues to be not-so-good at communicating this info
  - overlapping nameplates, important spell highlight being faint, targeting obscured, pick your poison
- Spell Reflection timing gets improved significantly
- healers have to split their attention less between nameplates and party frames

## Features

- deep Edit Mode integration thanks to [LibEditMode](https://github.com/p3lim-wow/LibEditMode/wiki/LibEditMode)
  - additional exhaustive Settings menu integration
- blizzlike look - built on top of the Cooldown Manager design
- customization options are heavily inspired by what's available in WeakAuras - that's where the aura lived before, so resurrecting most of that functionality only makes sense
- not vibecoded
- performance profiled - tiny footprint and doesn't do more than it should
- glow options for important spell highlighting

### Self

- customization options for:
  - enabled state
  - load conditions, supporting dungeons, delves, arena, battlegrounds and raids
  - role-based load conditions: tank, healer, dps (unsurprisingly)
  - layouting options
    - width, height, gap, direction, sort order, grow
  - glow important spells
    - 4 kinds of glows
  - show duration
    - option for fraction of seconds
  - font and font size
  - show border
  - option to selectively toggle this feature based on player role or content type
  - option to briefly highlight interrupted spells
    - this desaturates the frame, puts the cross raid marker on top of it, puts the interrupt source if available at the top of the frame and delays hiding by one second
    - handy for vod review

### Party

- customization options for:
  - enabled state
  - load conditions, supporting dungeons, delves, arena, battlegrounds and raids
  - role-based load conditions: tank, healer, dps (unsurprisingly)
  - layouting options
    - width, height, gap, direction, sort order, grow
  - glow important spells
    - 2 kinds of glows
  - show duration
  - font and font size
  - option to briefly highlight interrupted spells
    - this desaturates the frame, puts the cross raid marker on top of it, puts the interrupt source if available at the top of the frame and delays hiding by one second
    - handy for vod review

## Known Issues / Limitations

### Sound / TTS

No longer possible in Midnight after the Beta Build 65337 as expected.

### Sorting

**Currently not fixable as the cast time of a spell is secret.**

It's not possible to sort spells targeting a player in order of cast end, making it impossible to easily surface which spell hits first.

## API

### Importing / Exporting

- `_G.TargetedSpellsAPI.Import(string)`
- `_G.TargetedSpellsAPI.Export(): string`

## Honorary Mentions

- [Targeted Spells by Buds](https://wago.io/TargetedSpells)
- [Targeted by Damage Spells by Causese](https://wago.io/TsFNFG1H7)
- [Wago.tools](https://wago.tools/db2)
- all public repositories mirroring Blizzard Interface Code
- Krakón, Luckyone, Isaure, Ziv, Zorthas for helping me testing/translating

## Legal

See [LICENSE](LICENSE.txt)
