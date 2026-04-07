## Version 3.0.0

## Breaking Changes

Due to the hotfixed restrictions, the Party functionality has been redesigned and now offers to render bars per ongoing cast. It is no longer possible to attach icons to frames.

Settings not applying to the new Party functionality were dropped.

Please make sure to look around in Edit Mode again.

## Other

- beginning with patch 12.0.5, the remaining duration, if shown, is now always showing fractions below 3 seconds and is properly formatted above
  - the `Show Duration Fractions` has been removed
  - until then, fractions will always be shown
- Opacity was removed in general for technical reasons
- temporarily disabled ElvUI skinning for self-targeting casts while investigating a possible bug
- added machine translated internationalization for the following locales:
  - italian
  - russian
  - brazilian

## Version 2.0.1

- use a more future-proof approach of dealing with Layouting given the presumably upcoming restriction changes
- fix Icon Zoom and Border Style internationalization breaking non-English clients

## Version 2.0.0

### Layouting

- reworked layouting - no more gaps!
  - thanks to surarn for the lead on this

### Settings

- deprecated `Glow Type` > `Button Glow` option
  - this glow type was effectively incompatible with secrets which I unfortunately noticed too late
  - users of this option were automatically migrated to `Glow Type` > `Pixel Glow`
- deprecated `Grow` > `Center` option
  - no longer possible due to the layouting workarounds
  - users of this option were automatically migrated to `Grow` > `Start`
- consolidated checkbox settings into a new Features dropdown
  - your settings will automatically be migrated to the new format
- NEW: `Role Filter` setting for Party frames
  - allows you to never render spells targeting certain roles
- NEW: `Icon Zoom` setting
  - self explanatory, niche, go wild
- NEW: `Border Style` setting
  - via LibSharedMedia borders
  - you'll find not all borders work well but such is life

### Bug Fixes

- fixed a bug where, when using duration fractions, the duration text would be rendered behind the swipe animation
- fixed a couple of rare layouting issues when using DandersFrames
- fixed a bug where, when using another unit frame addon but also using ElvUI, party demo frames were anchoring incorrectly in Edit Mode
- fixed a bug where, where when using Self _or_ Party interrupt indication, frames of the other frame type may linger

### AddOn Compatibility

- added support for QUI and Cell

### Other

- cast duration for abilities with a remaining duration of more than 60 seconds will now be hidden to reduce clutter
  - with 12.0.5, this will again render these durations, but properly formatted (e.g. 59m)
  - with 12.0.5, casts with a duration of more than 3 seconds will not show fractions above 3 seconds

## Version 1.1.18

- added support for KR locale, thanks to 007bbb

## Version 1.1.17

- added support for ShadowedUnitFrames
- improved support for VuhDo

## Version 1.1.16

- added support for VuhDo

## Version 1.1.15

- made elements propagate mouse inputs

## Version 1.1.14

- removed leftovers of the Targeting Filter API now that `UnitIsSpellTarget` is gone
- NEW: `Render Interrupt Source Name` setting
  - allows using the interrupt indication functionality without rendering the interrupt source unit name

## Version 1.1.13

- made elements clickthrough, preventing them from eating mouseover events
- fixed a bug that led to glows reused by other addons through `LibCustomGlow` to keep their possibly 0 alpha values (sorry lmao)

## Version 1.1.12

- PTR compatibility for the removal of `UnitIsSpellTarget`
  - addon will default to use `UnitIsUnit` instead, effectively works more or less the same as before
  - will provide feedback to Blizzard that this functionality is deemed highly valuable to healers in particular
  - ability to highlight casts targeting the player is unaffected (`UnitIsSpellTarget` becomes `PlayerIsSpellTarget`)

## Version 1.1.11

- fixed a secret error comparison error occuring in PvP with Empower casts

## Version 1.1.10

- fixed a bug where the position of spells targeting the player wasn't instantly updated when importing a profile
- fixed various bugs leading to different positioning of spells targeting the player in contrast to its preview in Edit Mode
  - this should only apply to a minority of players heavily deviating from the centered default position
- fixed a bug where the Button Glow wasn't hiding correctly for non-important spells
  - note that it still briefly shows up when an icon appears until the entry animation is finished. this is unavoidable, the alternative would be disallowing this glow type altogether
  - fixed an error when trying to colorize interrupt source

## Version 1.1.9

- fixed import not doing anything (hehecat moment)

## Version 1.1.8

- fixed a bug leading to off-center positioning for casts targeting the player
- fixed a bug where, when leaving a dungeon mid-cast would have orphaned frames remain onscreen until a /reload

## Version 1.1.7

- fix an error for CN/FR/ES/MX locales

## Version 1.1.6

- in Edit Mode, the font selection now renders the font name in the font family
- changed category to Archon
- fixed a bug where the Import API was not correctly handling `false` values for checkboxes
- add esES and esMX locale thanks to ferrancarril
- added Font Options for Shadow and Outline
- minor performance improvements
- add support for Enhance QoL party frames
- added Discord link to Edit Mode
- updated ToC
- fixed a bug with icon resizing leading to very broken visuals
- fixed a regression where, using Grid2, the Edit Mode party selection element wouldn't correctly anchor
- fixed a bug where, using Grid2, party elements wouldn't be reliably layered on top of the party frame

## Version 1.1.5

- fixed a bug where the cooldown swipe animation would linger under specific circumstances in the Edit Mode preview
- fixed a bug when opening Edit Mode when `Include Self in Party` was disabled

## Version 1.1.4

- NEW: option to change the font
- NEW: added support for all (most) oUF-based unit frames, most notably ElvUI
- NEW: added support for ElvUI Skinning - automatically applies when you have Elv enabled
- NEW: added API for unit frames to register themselves, see README -> API section

- performance improvements
- fixed a bug where changing the Party glow in Edit Mode type wouldn't respect the Glow setting if that was disabled
- increase OffsetX / OffsetY for Party frames to 200
- fix bug introduced in 1.1.2 that led to incorrect layouting for the Self preview in Edit Mode

## Version 1.1.3

_skipped_

## Version 1.1.2

- harden Grid2 support
  - now uses their API to determine the best frame
  - now correctly layers on top of the frame
- fixed a bug where changing the duration fraction or interrupt indication setting would toggle enabled state
- NEW: option to toggle cooldown swipe animation
- fixed a bug where interrupt indicators were incorrectly showing for Self despite explicitly turned off
- fixed a bug leading to incorrect layouting when Source and Target anchors were set to Center for Party frames
- improved loading speed slightly should other addons toggle Edit Mode on login

## Version 1.1.1

- remove now-redundant sounds
- preliminary support for Grid2

## Version 1.1.0

- NEW: Import/Export functionality
  - this always includes _both_ Self and Party settings
- updated French locale
- removed all pre-Midnight code

KNOWN ISSUES:

- due to the state of the 12.0.0 patch, in some cases casts may not get cleaned up until the nameplate gets removed or the caster casts again.
  - this fixes itself with the 12.0.1 patch

## Version 1.0.7

- further CN locale updates
- removed Sound / TTS options for Midnight as it's no longer possible

## Version 1.0.6

- add CN locale, thanks to nanjuekaien1
- extend French locale
- update README

## Version 1.0.5

- fixed a bug incorrectly leading to event registration when both Self and Party modules were disabled
- fixed a bug where the sound selection would show an empty selected value if another addon registered the selected sound under the same name before this addon loaded
- reduced memory footprint by a tiny amount
- fixed a bug where sometimes a frame would not properly reposition and appear behind others
- fixed a bug where player-targeted frames were incorrectly positioned in relation to the edit mode element

## Version 1.0.4

- _interrupted_ (not stopped) channels are now correctly highlighted as such
- when using interrupt indication, the source of the interrupt will now be mentioned at the top
- glows will now get hidden upon interrupting an important spell

## Version 1.0.3

- fixed a bug where icons were lingering as interrupted when an enemy died mid-cast
- fixed a bug failing to account for the Midnight Beta realm being behind the Midnight PTR in terms of API level

## Version 1.0.2

- reintroduce unconditional delay of 200ms for each cast again as it breaks channels with windup casts
- add support for cast ids to more accurately keep track of casts
- omit enemy casts targeting other enemies entirely
- omit enemy casts targeting a unit the player cannot attack (e.g. Forgeweaver Araz casting Invoke Collector on Arcane Collectors)
- on Retail, sort order now sorts by end time of casts instead of start time

## Version 1.0.1

- fixed a bug for Retail for when `UNIT_TARGET` occurs before spell cast events leading to double triggers
- removed the need for delay when using the `Spell Target` API

## Version 1.0.0

- re-release of alpha5

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
