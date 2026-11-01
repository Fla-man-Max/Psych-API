# Psych Lua test

Copy this folder into `mods` next to the Windows executable. The official v0.8.7 loader loads installed mod folders at startup. Open a song (Tutorial is enough), or run `Funkin.exe --lua-song=tutorial`.

Expected: a small blue text panel, then `Timer: true` and `Tween: true`. Player note hits increment the counter. F6 changes the text color. F5 uses the official game's asset/state reload and recreates the panel when the song restarts. For Lua-only reload without restarting the song, call `reloadLuaScripts()` or enable automatic reload below. Leave and enter another song to check cleanup. The script also verifies saved data and prints `PSYCH_TEST_*` markers to the game log/console.

For automatic reload while editing, add `setLuaAutoReload(true)` inside `onCreate`. A Lua syntax error should be reported without replacing the currently running scripts.

This is a smoke-test script, not a claim that every Psych Engine mod is compatible with V-Slice.
