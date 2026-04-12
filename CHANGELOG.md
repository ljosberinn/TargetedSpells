## Version 3.1.1

### Features

- new global setting: `Announce Untargeted Spells`
  - default off
  - if enabled, any spells that don't target anyone will be announced via text-to-speech
  - it is not possible to announce spells targeting the player only
  - whether Blizzard will like this remains to be seen
- Party: added an option to `Hide Targeted Spells`
  - ironic for this addon, I know
  - default off, allows you to hide any spells targeting a player
- Party: addded an option to `Only Show Player-Targeting Spells`
  - this is a bandaid fix until I invest the time to allow choosing which display to use for self/party
  - default off
  - disables the `Hide Targeted Spells` option if its active

### Other

- casts longer than 60 seconds will no longer show
  - again, looking at you Lothraxion (but also a couple others)
- casts originating from units that are not in combat will no longer show
  - this is experimental but seems to have worked fine in the couple dungeons I did
- Party: spell names will no longer get cut off if the spell has no target
- Party: the Edit Mode preview will now sometimes simulate a channel
- Party: when hiding the spell name, the target name will now take its position instead
- "significant" performance improvements
  - the addon was already peaking around only 1% CPU on my machine, but hey, now its ~10x faster
- fixed a bug where on-death channels such as Reanimated Warriors in Maisara Caverns would create too many bars that also end up not getting removed
- fixed a couple missing translations
