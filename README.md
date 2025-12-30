# Targeted Spells

## Features

- no sound overlap if multiple spells target the player at the same time
- deep Edit Mode integration thanks to [LibEditMode](https://github.com/p3lim-wow/LibEditMode/wiki/LibEditMode)
  - additional exhaustive Settings menu integration
- support for both raid-style and classic party frames
- while it lasts: integration for Plater scripts indicating important spells (**becomes obsolete with Midnight Pre-Patch**)
- blizzlike look - built on top of the Cooldown Manager design
- customization options are heavily inspired by what's available in WeakAuras - that's where the aura lived before, so resurrecting most of that functionality only makes sense
- not vibecoded
- performance profiled - tiny footprint and doesn't do more than it should

### Self

- customization options for:
  - enabled state
  - frame dimensions
  - gap between frames
  - direction
  - sort order
  - grow
  - glowing important spells
  - play sound if targeted
  - exhaustive sound options
    - using all available sounds of Blizzards Cooldown Manager
    - as well as all available third party sounds through `LibSharedMedia`
  - sound channel selection
  - option to selectively play sound based on content type you're in
  - show duration
  - font size
  - show border
  - opacity
  - option to selectively toggle this feature based on player role or content type

### Party

- customization options for:
  - enabled state
  - frame dimensions
  - gap between frames
  - direction
  - sort order
  - manual x/y offsets
  - source & target anchors
  - grow
  - sort order
  - glowing important spells
  - include self additionally in party (when using Raid-Style Party Frames)
  - show duration
  - font size
  - show border
  - opacity
  - option to selectively toggle this feature based on player role or content type

## Sounds

[WaterDrop - Attribution 3.0 - Mike Koenig](https://soundbible.com/1126-Water-Drop.html)

## Legal

See [LICENSE](LICENSE.txt)
