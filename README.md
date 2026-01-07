# Targeted Spells

- [Curseforge](https://www.curseforge.com/wow/addons/targetedspells)
- [Wago](https://addons.wago.io/addons/targeted-spells)

## Features

- compatible with both The War Within and Midnight
- no sound overlap if multiple spells target the player at the same time
- deep Edit Mode integration thanks to [LibEditMode](https://github.com/p3lim-wow/LibEditMode/wiki/LibEditMode)
  - additional exhaustive Settings menu integration
- support for both raid-style and classic party frames
- supported third-party unit frame addons:
  - [Danders Frames](https://www.curseforge.com/wow/addons/danders-frames)
  - more coming when the dust settles
- while it lasts: integration for Plater scripts indicating important spells (**becomes obsolete with Midnight Pre-Patch**)
- blizzlike look - built on top of the Cooldown Manager design
- customization options are heavily inspired by what's available in WeakAuras - that's where the aura lived before, so resurrecting most of that functionality only makes sense
- not vibecoded
- performance profiled - tiny footprint and doesn't do more than it should
- the usual (and more!) glow options for important spell highlighting

### Self

- customization options for:
  - enabled state
  - load conditions, supporting dungeons, delves, arena, battlegrounds and raids
  - role-based load conditions: tank, healer, dps (unsurprisingly)
  - targeting API (12.0+ only)
  - layouting options
    - width, height, gap, direction, sort order, grow
  - glow important spells
    - 5 kinds of glows
  - play sound
    - consumes all cooldown manager sounds (12.0+ only)
    - `LibSharedMedia` integration
    - ships two sounds
    - sound channel selection
  - play tts
    - voice selection, automatically picking the most likely based on your game locale
  - option to selectively play sound/tts based on content type you're in
  - show duration
    - option for fraction of seconds
  - font size
  - show border
  - opacity
  - option to selectively toggle this feature based on player role or content type
  - option to briefly highlight interrupted spells - only works for non-channels
    - this desaturates the frame, puts the cross raid marker on top of it, puts the interrupt source if available at the top of the frame and delays hiding by one second
    - handy for vod review

### Party

- customization options for:
  - enabled state
  - load conditions, supporting dungeons, delves, arena, battlegrounds and raids
  - role-based load conditions: tank, healer, dps (unsurprisingly)
  - targeting API (12.0+ only)
  - option to include self in party
  - layouting options
    - width, height, gap, direction, sort order, grow, source & target anchoring, manual x/y offsets
  - glow important spells
    - 5 kinds of glows
  - show duration
    - option for fraction of seconds
  - font size
  - show border
  - opacity
  - option to selectively toggle this feature based on player role or content type
  - option to briefly highlight interrupted spells - only works for non-channels
    - this desaturates the frame, puts the cross raid marker on top of it, puts the interrupt source if available at the top of the frame and delays hiding by one second
    - handy for vod review

## Known Issues / Limitations

**All of these below apply to 12.0 / Midnight onwards only.**

### Sound / TTS

Built on top of Blizzards recently added Combat Audio Alerts (and thus requiring that to be enabled), it's unfortunately unreliable. You can test this with `TargetedSpells` disabled relatively easily in Follower Dungeons.

There's also a non-zero chance that Blizzard will simply **prevent** overriding this functionality, I was honestly surprised that it's currently possible which may or may not be intentional.

#### Sound / TTS Sometimes Not Playing

**Unfixable for addon authors, Blizzard needs to fix the missing events.**. Possibly also not a big issue in practice.

Blizzards function solely relies on the `UNIT_TARGET` event which sometimes (~10-20% of the time) simply doesn't fire, confirmed via `/etrace`. Ironically, if in such a case the enemy is casting something on you, the `UnitIsSpellTarget` API will correctly identify you're actually being cast on. But since the event they're looking for doesn't occur, nothing happens.

In these cases you'll see the spell icon for the spell being cast, but no sound will be played, making this addon - for now - clearly superior over default UI functionality.

There's also the following edge case: if an enemy does not change target between two consecutive spells on you, it'll only announce the first one, as the enemy hasn't swapped back and forth between tank and you between the casts. In that case, again, the addon will correctly show both spells on you, but again, no sound will be played for the second spell.

#### Sound / TTS Only Sometimes Playing As Tank

Goes hand in hand with the above. The Blizzard function is intended to only fire on enemies changing target to you. You as a tank should be targeted most of the time, so the only times this will work as expected are:

- an enemy spamcasts spells, first on another player (targeting them), then on you
- someone else had aggro first, then you and instantly started casting

### Sorting

**Currently not fixable as the cast time of a spell is secret.**

It's not possible to sort spells targeting a player in order of cast end, making it impossible to easily surface which spell hits first.

### Layouting

**Currently not fixable due to API restrictions.**

The elephant in the room. Since it's no longer possible to filter which player is being targeted by which enemy, the way the addon works is as follows:

- create frames for every possible target: player and everyone in the party, if in a party
- the API allows checking whether "unit x targets y" which in the past was used for filtering, but the result is now secret
- based on said secret, change the alpha (`SetAlphaFromBoolean`) of the frame
- adjust positioning of all frames per possible target

A frame with 0% alpha however still takes up space, leading to gaps: all spells currently being cast on the whole party are always _present_, but not _visible_.

You can query the current alpha (which will be 0), but as a result of `SetAlphaFromBoolean` it's also secret so you can't perform logic on it and show/hide the frame because of that.

_However_, you can work around this with the `Gap` settings:

- you can completely overlap frames by using the same gap value as the frames dimensions
  - this naturally has the downside of not being able to see casts beyond the first on the target because the first one is layering on top, but they'll all be in the same spot
- you can alternatively use a negative gap larger than the frame dimensions, resulting in an overlapping fan-like effect
  - it'll still move around, it'll still obscure _some_ info but it's better than nothing

### Glowing Affected Players Frame

**Currently not possible due to API restrictions.**

While it's possible to apply a glow to the affected player frame, the underlying data for it is secret, so the next cast that happens to target the same player **while the first is still pending** is forced to remove the glow.

## Sounds

- [WaterDrop - Attribution 3.0 - Mike Koenig](https://soundbible.com/1126-Water-Drop.html)
- [BananaPeelSlip - Sampling Plus 1.0 Generic - Mike Koenig](https://soundbible.com/1438-Banana-Peel-Slip.html)

## Honorary Mentions

- [Targeted Spells by Buds](https://wago.io/TargetedSpells)
- [Targeted by Damage Spells by Causese](https://wago.io/TsFNFG1H7)
- [Wago.tools](https://wago.tools/db2)
- all public repositories mirroring Blizzard Interface Code

## Legal

See [LICENSE](LICENSE.txt)
