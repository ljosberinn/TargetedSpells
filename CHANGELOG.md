## Version 3.2.0

### Features

- the Text-to-Speech `Announce Untargeted Spells` Setting has been made significantly more granular
  - there's now `Announce Untargeted Spells` as well as `Announce Targeted Spells`
  - your previous setting will be migrated automatically
  - you can now control which NPC types get their spells announced
    - e.g. Minions are off by default for untargeted spells, while everything else is enabled
  - `Announce Targeted Spells` is inherently noisy so I'll suggest to be careful what to enable here
  - as always, to play around with this, head into a follower dungeon and try things out!

### Other

- beginning with 12.0.5, the realm name of targeted players can finally be omitted
- fixed a bug where the Text-To-Speech voice was not being detected properly after reloading on Linux
  - thanks to kerriganx
- fixed a bug where `Only Show Important Spells` was not working as intended for Party/Bars
- fixed a bug where `Only Show Important Spells` would only work for Self/Icons when glows were enabled
- fixed a bug where the TTS announcements would not use the user-preferred voice
  - this implicitly also fixes a bug where overlapping TTS wouldn't work using English locale
- fixed a bug where units outside of combat weren't fully ignored
