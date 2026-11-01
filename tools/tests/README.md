# Isolated note compatibility regression

`TestSourceArchive.ps1` runs the real Git metadata macros in a temporary source archive without `.git`. It requires Haxe on PATH and verifies archive metadata compiles without Git history. It does not build the game.

`reload-key.lua` is another isolated runtime fixture. In a separate runtime directory, copy the example mod and place this file in its `scripts` folder, then start Tutorial with `--lua-song=tutorial`. It checks that Ctrl+Shift+R no longer reloads scripts and that the original F5 plugin replaces the native state and loads a fresh Lua host. Success produces `legacy-chord-passed.txt` and `native-f5-passed.txt` inside that isolated mod; `legacy-chord-failed.txt`, callback errors, crashes, or missing success markers are failures. Never install this fixture in a normal playable mod directory.

`note-compat.lua` is an automated test, not a playable mod. Do not install it into the normal release's mods folder. Run it in a separate copy of the executable with its own mods directory, using `--lua-song=tutorial`.

The test mod ID is `psych-lua-test` (use the example mod's metadata). Place the test under its `scripts/` folder. It uses the supplied RoaringBoy mod's `custom_notetypes/RoaringNote.lua`, corrected `custom_notetypes/ItemNotePixel.lua`, `sounds/heal.ogg`, and four pixel PNGs under `images/pixelUI/`: itemnote, itemnoteENDS, RoaringNote, and RoaringNoteENDS. Third-party assets are not bundled with this regression script.

The test creates a `note-check-passed.txt` marker only after checking raw-chart property writes, real pixel head dimensions, continuous-hold texture conversion, ignored misses/hold drops, hurt-note behavior with zero and nonzero miss damage, botplay ignoring optional notes, missing-splash fallback, and recycling back to native graphics/flags. Check stdout/stderr for Lua callback errors as well. It does not establish compatibility for the rest of the mod or every Psych texture format.
