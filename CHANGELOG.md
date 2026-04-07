## Version 3.0.1

- fixed a bug where frames weren't properly cleaned up when hiding nameplates
- fixed a bug where Party frames would linger until the next cast of the same unit if the unit started channeling directly after finishing a cast
- ElvUI skinning support has been removed due to bugs
- fixed a bug in unit filtering which led to improper Party frame creation and as a result, improper cleanup
  - looking at you, Lothraxion
  - this has the unfortunate side effect of seeing all RP channels again, if you have a nameplate for the unit
