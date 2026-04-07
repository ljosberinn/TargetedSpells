## Version 3.0.1

NEW setting for Party: Use Target Class Color

Colors the bar in the class color of the targeted unit at 75% opacity. Untargeted spells will use a brightened Background Bar Color. Disables the Uninterruptible Color setting and vice versa.

NEW setting for Party: Mirror Layout

Self explanatory.

### Bug Fixes

- fixed a bug where frames weren't properly cleaned up when hiding nameplates
- fixed a bug where Party frames would linger until the next cast of the same unit if the unit started channeling directly after finishing a cast
- ElvUI skinning support has been removed due to bugs
- fixed a bug in unit filtering which led to improper Party frame creation and as a result, improper cleanup
  - looking at you, Lothraxion
  - this has the unfortunate side effect of seeing all RP channels again, if you have a nameplate for the unit
- added scrollbars to settings prone to have many options available
- fixed a positioning bug with the Edit Mode frame

### Other

- default Party frame height has been reduced to 30
- each kind of frame will now only render up to 10 frames at a time
