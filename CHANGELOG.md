## Version 4.0.0

NEW: Designer

`/targetedspells design` opens a window letting you customize next to anything for a template.

This also introduces a bunch of new settings, such as Border customization and an Interrupt shield.

NEW: Groups

You can now create theoretically infinite amount of groups.

The built-in templates (Bar for Self, Icon for Party) were migrated to groups and continue to be shipped as defaults.

Each group has its own design and settings, allowing you to e.g. have this setup:

- casts targeting you via Icon as per default
- aoe casts (casts targeting nobody) via Bar as per default, colored by interruptibility with certain dimensions
- casts targeting party members as Bars, showing the target name, colored by class with other dimension
- ... and more

You can copy designs from an existing one to start your new design from that.

NEW: a third template

[Icon][Cast Duration][Icon] was a popular setup in the past.

### Bugfixes

- fixed a layouting bug sometimes leaving gaps between vertically aligned progress bars
- fixed a bug where sometimes a cast that was cancelled within the built-tin delay before rendering of 200ms would mix its duration with a followup cast of much shorter duration
- fixed a bug where empower spells were not correctly detected on cast start

### Other

Significantly improved performance. This was not an issue before but well, now its even faster. Laughably fast even, I want to say.

A lot of optimization were made, leading an additional improvement of 75-90% depending on machine and ongoing casts, measured in Cinderbrew Meadery pulling the entire room and running in circles for two minutes.
