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
