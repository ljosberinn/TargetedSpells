This repository contains the Retail World of Warcraft addon `Targeted Spells`. There is no support for non-Retail World of Warcraft addons.

## Repository Overview

It fills a rather narrow niche: display ongoing casts of hostile enemies based on nameplate events.

Multiple display presets are available, each with their own settings (see Mixins).

Each display preset is collected in a Group (see Groups and GroupController). They're orchestrated through the Driver which handles events.

EditMode orchestrates the avaialble options via LibEditMode.

Types are for internal use only and aren't published and do not have any executable code either.

Consider any file/subfolder within Libs to be third-party and it may not get touched.

The Designer is a custom frame exposing a variety of customization options per template, isolated to each group.

Init bootstraps the addon and SavedVariables.

## Coding Conventions

- local-first coding style: if something is not re-used across files, keep it local
- if something is not repeated, do not extract it to its own function
- use a new line before each `return`
- never use excessive abbreviations such as `desc` for `description`. always write it out
- avoid unnecessary comments, **especially** phase-related stuff like "7a - ..."
- do not expose unnecessary globals. prefer using the addon namespace
- functions declared within another function should have types for their arguments
  - if its a method on a class, it belongs into Types.lua

## Testing Conventions

Using busted, a growing number of unit tests can be found in `spec`. New code should be covered by tests as far as possible, within the limits of the aforementioned coding conventions.

What can't be unit tested needs to be prompted by you for the user to verify manual. Unless there's explicit consent, refuse to continue before verification.

## Naming Conventions

- PascalCase for everything

## Performance Guidance

The addon is designed to be as performant as possible. Memory consumption should also be kept to a minimum. We leverage frame pools for this where possible.

Where needed, we use the Profiling.lua utility file which is by default disabled. New code should use it by default IF there's concerns about performance.

## References

- https://github.com/Gethe/wow-ui-source
  - git mirror of the user interface source code for World of Warcraft
  - exclusively use the `live` branch
  - locally, you may find this adjacent to this projects folder. ignore the branch requirement for this should it not be `live`. warn the user if its not any of these: `live`, `beta`, `ptr`, `ptr2`
- https://warcraft.wiki.gg/
  - API documentation for World of Warcraft
  - may lack behind the above but may contain more exhaustive information for certain APIs

## Copyright

This project is licensed under the GNU General Public License v3.0. See the LICENSE file for more information.
