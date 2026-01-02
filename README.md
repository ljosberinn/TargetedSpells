# Targeted Spells

## Known Issues

### Sound / TTS

**Not fixable unless Blizzard changes how fast/when mobs change targets while casting (or changes some restrictions). Possibly also not a big issue in practice.**

Built on top of Blizzards recently added Combat Audio Alerts (and thus requiring that to be enabled), it's unfortunately unreliable. You can test this without `TargetedSpells` enabled relatively easily in Follower Dungeons.

Blizzards function solely relies on the `UNIT_TARGET` event which sometimes (~10-20% of the time) simply doesn't fire. Ironically, if in such a case the enemy is casting something on you, the `UnitIsSpellTarget` API will correctly identify you're actually being cast on. But since the event they're looking for doesn't fire, nothing happens. In these cases you'll see the spell icon for the spell being cast, but no sound will be played, making this addon - for now - clearly superior over default UI functionality.

There's also the following edge case: if an enemy does not change target between 2 spells on you, it'll only announce the first one, as the npc hasn't swapped back and forth between tank and you between the casts. In that case, again, the addon will correctly show both spells on you, but again, no sound will be played for the second spell.

There's also a non-zero chance that Blizzard will simply **prevent** overriding this functionality.

### Layouting

**Possibly fixable, have to investigate still.**

The elephant in the room. Since it's no longer possible to filter which player is being targeted by which enemy, the way the addon works is as follows:

- create frames for every possible target: player and everyone in the party, if in a party
- the API allows checking whether "unit x targets y" which in the past was used for filtering, but the result is now secret
- based on said secret, change the alpha (`SetAlphaFromBoolean`) of the frame
- adjust positioning of all frames per possible target

A frame with 0% alpha however still takes up space, leading to gaps: all spells currently being cast on the whole party are always _present_, but not _visible_.

You can query the current alpha (which will be 0), but as a result of `SetAlphaFromBoolean` it's also secret so you can't perform logic on it and show/hide the frame because of that.

### Toggling Nameplates Mid Combat & Cast

**Not fixable unless Blizzard declassifies the `startTimeMs` return of `UnitCastingInfo(unit)` / `UnitChannelInfo(unit)`.**

It's no longer possible to determine when a cast started unless you observed it starting. This only really applies to edge cases but the shown info will be incorrect in this case:

- enemy starts casting something with a cast time of 5 seconds (for the sake of the argument)
- you accidentally toggle off nameplates at 1s
- you then toggle nameplates on at 1.3s
- we lost all info about when the cast started, so for all the addon is concerned, it started just now and it'll show a remaining time of 5 seconds
- 3.7s later, the cast finishes - the addon will correctly hide the icon(s) now

## Features

- compatible with both The War Within and Midnight
- no sound overlap if multiple spells target the player at the same time
- deep Edit Mode integration thanks to [LibEditMode](https://github.com/p3lim-wow/LibEditMode/wiki/LibEditMode)
  - additional exhaustive Settings menu integration
- support for both raid-style and classic party frames
  - no third-party party-frame addons support at this time until the dust settles
- while it lasts: integration for Plater scripts indicating important spells (**becomes obsolete with Midnight Pre-Patch**)
- blizzlike look - built on top of the Cooldown Manager design
- customization options are heavily inspired by what's available in WeakAuras - that's where the aura lived before, so resurrecting most of that functionality only makes sense
- not vibecoded
- performance profiled - tiny footprint and doesn't do more than it should
- the usual (and more!) glow options for important spell highlighting

### Self

- customization options for:
  - enabled state
  - frame dimensions
  - gap between frames
  - direction
  - sort order
  - grow
  - glowing important spells
  - 5 glow types
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
  - 5 glow types
  - include self additionally in party (when using Raid-Style Party Frames)
  - show duration
  - font size
  - show border
  - opacity
  - option to selectively toggle this feature based on player role or content type

## Sounds

[WaterDrop - Attribution 3.0 - Mike Koenig](https://soundbible.com/1126-Water-Drop.html)
[BananaPeelSlip - Sampling Plus 1.0 Generic - Mike Koenig](https://soundbible.com/1438-Banana-Peel-Slip.html)

## Honorary Mentions

- [Targeted Spells by Buds](https://wago.io/TargetedSpells)
- [Targeted by Damage Spells by Causese](https://wago.io/TsFNFG1H7)

## Legal

See [LICENSE](LICENSE.txt)
