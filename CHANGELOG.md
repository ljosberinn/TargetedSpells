## Version 3.1.0

### Features

- NEW party setting: Hide Untargeted Spells
  - default off, allows to hide spells not targeting any player

### Layouting

Party bars have had their layout slightly tweaked.

Before:

[Raid Marker][Spell Icon][Bar with SpellName + Divider + TargetName + Duration]

Now:

[Raid Marker][Spell Icon][Bar with SpellName at the start, TargetName at the end][Duration]

### Other

- Party: minor adjustments to default settings as a result of the layouting change
- Party: removed option for `Direction`
- Party: removed option for `Spell Name Length` and `TargetName Length`
  - these will now always take up to 50% of the bar width
- Party: fixed a bug where, when showing Raid Marker and Important Spell Glows, the glow would encompass the possibly empty Raid Marker space
- Party: fixed a bug where, when not showing Target Name, some other Party settings were ignored
- Party: fixed a bug where, when toggling Show Target Marker while Edit Mode is opened, a marker would only be chosen for new demo frames, ignoring existing
