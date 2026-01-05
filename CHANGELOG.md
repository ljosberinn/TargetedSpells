## Version 1.0.0-alpha5

- raid content type is now only disabled for Party frames
- the sound selection under Settings is now scrollable, containing 20 items before having to scroll
- synchronize min gap with max frame dimensions
- added a new setting to show fractions of cast durations
- added support to use DandersFrames if present
- added a new setting that briefly highlights interrupted spells - only works for non-channels
- added a disclaimer to the settings that the edit mode should be the primary way to change options
- no longer prints in chat about CAA when resetting the Self settings to default
- the addon will now continue to mute the CAA - Say If Targeted setting while it is active if the Sound settings for Self (or the entire module) are disabled
  - this is not optimal, still figuring out how to deal with these circumstances
- changed underlying API of target indication to `UnitIsSpellTarget`
- added a new setting to swap between the two APIs

## Version 1.0.0-alpha4

- more retail compatibility

## Version 1.0.0-alpha3

- fixed a bug where the default state of TTS was incorrectly being set to `true`
- the Raid load condition has been disabled until there's demand
- updated the Party default positioning to be more obvious for first time users
- more retail compatibility

## Version 1.0.0-alpha2

- fixed a bug where spells wouldn't be shown if the player wasn't in combat with the casting enemy
- fixed a bug where some settings would apply to both party and self frames, despite only changing one of them
- fixed a bug leading to the inability of displaying the cast duration when using nameplate addons
  - thanks to plusmouse for suggesting to use APIs that eluded me, `UnitCastingDuration` & `UnitChannelDuration`
- fixed a bug where the addon was incorrectly establishing whether the Combat Audio Assist - Say If Targeted setting was active on login
- changed the Edit Mode default position for Self in Midnight to the same as before Retail, slightly off-center
- in Midnight, the Party Frame Edit Mode option is now automatically enabled until dust settles, as the expectation is that players will use the default frames for a while
- fixed a bug where the Party Edit Mode demo would continue to play even after disabling the Party Frame Edit Mode option
- more Retail compatibility

## Version 1.0.0-alpha1

- initial private release
