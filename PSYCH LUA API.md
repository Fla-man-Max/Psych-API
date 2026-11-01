# Psych Lua API for official FNF

Base: **FNF v0.8.7**. Lua syntax/runtime and callback conventions follow **Psych Engine 1.0.4**, adapted to V-Slice objects. This is a separate project, not LuaSlice. LuaJIT and Iris 1.1.3 are the scripting dependencies.

## Installation and script folders

### Building

On Windows, run `Setup FNF.bat` from this folder. Pick Windows, Android, Linux, or All. It downloads the selected build tools and the pinned libraries, then asks what to build. SDK licenses and administrator prompts still need your approval. Linux builds use Ubuntu through WSL; a first-time WSL installation may need a restart.

After setup, use `Build FNF.bat` to pick a platform and Release or Debug. The normal builds are under `export/release/windows/bin`, `export/release/android/bin/app/build/outputs/apk/release`, and `export/release/linux/bin`. Keep the Windows/Linux executable with its accompanying assets. Android release signing needs your own key; setup does not replace an existing key.

Only Windows, Android and Linux are offered. The source keeps the official game's UI, editors, assets and branding; the added game feature is the Psych Lua API.

Put a mod folder inside `mods` next to `Funkin.exe`. Keep the base game's `_polymod_meta.json` in that folder. This build uses the official mod loader; it does not load disabled or rejected mods behind the loader's back. The metadata's `api_version` describes the **FNF** version, e.g. `0.8.7`, not Psych's version.

Each Lua file has its own globals. The following folders are relative to the mod:

| Folder | When it loads |
| --- | --- |
| `scripts/*.lua` | Every song |
| `data/<song-id>/*.lua`, `data/songs/<song-id>/*.lua`, or `songs/<song-id>/*.lua` | That song |
| `stages/<stage-id>.lua` | The current native stage |
| `characters/<character-id>.lua` | Each character used by that stage |
| `custom_notetypes/<kind>.lua` | A note kind present in the chart |
| `custom_events/<event-name>.lua` | An event present in the chart |

Use `images/`, `sounds/`, `music/`, `fonts/`, and `shaders/` for Lua assets. Image/sound helpers accept extensionless names. `require` can read Lua modules relative to the mod. Only install trusted scripts: Lua's standard libraries and Haxe execution are not a security sandbox.

The included `example_mods/psych-lua-test` is a runnable smoke test. Copy it to the executable's `mods` folder. Launch normally and choose a song, or run `Funkin.exe --lua-song=tutorial` to enter Tutorial directly.

## Script examples

### Text and a solid-color sprite

```lua
function onCreate()
    makeLuaSprite('panel', nil, 24, 24)
    makeGraphic('panel', 380, 80, '14243A')
    setObjectCamera('panel', 'hud')
    addLuaSprite('panel', true)

    makeLuaText('message', 'Hello from Lua!', 350, 40, 45)
    setTextSize('message', 24)
    setTextColor('message', 'A7E8FF')
    addLuaText('message')
end
```

### Tween, timer, and callbacks

```lua
function onCreatePost()
    doTweenAlpha('fadePanel', 'panel', 0.5, 0.4, 'quadOut')
    runTimer('changeMessage', 2)
end

function onTimerCompleted(tag, loops, loopsLeft)
    if tag == 'changeMessage' then
        setTextString('message', 'Timer finished')
    end
end

function onTweenCompleted(tag, target)
    debugPrint('Completed', tag, target)
end
```

### Note kind behavior

Save as `custom_notetypes/Bonus.lua` and assign `Bonus` as a native chart note's kind.

```lua
function goodNoteHit(id, direction, noteType, isSustainNote)
    if noteType == 'Bonus' and not isSustainNote then
        addHealth(0.04)
        addScore(50)
    end
end
```

### Existing character and native camera event

```lua
function onBeatHit()
    if curBeat == 16 then
        triggerVSliceEvent('FocusCamera', {
            char = 0,
            x = 0,
            y = -40,
            duration = 4,
            ease = 'quad',
            easeDir = 'Out'
        })
    end
end
```

### Mod-local save data

```lua
function onCreate()
    initSaveData('settings')
    local visits = getDataFromSave('settings', 'visits', 0)
    setDataFromSave('settings', 'visits', visits + 1)
    flushSaveData('settings')
end
```

### Reloading

Press **F5** to use the official game's asset reload. It reloads the current native state/song, which also recreates the Lua host and scripts. The former Ctrl+Shift+R shortcut is not used.

For a Lua-only reload without restarting the music, call `reloadLuaScripts()`. To watch files automatically, call `setLuaAutoReload(true)`. Discovery is checked once per second, not once per frame.

Before a Lua-only reload replaces running scripts, all replacement files are syntax-checked. A syntax error keeps the running scripts. Runtime errors are reported with the script and hook name; arbitrary script side effects cannot be rolled back. Lua-only reload destroys script-owned sprites, text, timers, tweens, sounds, save handles, and Haxe interpreters. It reruns `onCreate`, `onCreatePost`, and then `onReload`. It does **not** restart the music. `getVar`/`setVar` host variables survive a Lua-only reload; ordinary Lua globals do not. F5 instead follows native state replacement, so it does not preserve the old host's variables.

`onCreate` runs after native stage/characters/receptors exist, before countdown. This differs from Psych's earliest creation phase and lets Lua safely use the official game's objects.

## Advanced script examples

### Haxe calls and a callable Haxe function

```lua
function onCreate()
    local result = runHaxeCode('return 6 * 7;')
    debugPrint(result)
    runHaxeCode([[
        function doubleValue(value) {
            return value * 2;
        }
    ]])
    debugPrint(runHaxeFunction('doubleValue', {21}))
end
```

Haxe's `game` points to the current native PlayState. Common `FlxG`, `FlxSprite`, `FlxText`, `FlxCamera`, `FlxTween`, `FlxEase`, `FlxTimer`, `Paths`, `PlayState`, `Conductor`, `ShaderFilter`, and `FlxRuntimeShader` types are supplied. `addHaxeLibrary('TypeName', 'package.name')` exposes another type compiled into the game. It cannot install missing Haxe libraries at runtime. Haxe objects added directly with `game.add()` must be removed by your script on reload; use Lua object helpers for automatic ownership.

### Custom pause overlay

```lua
function onUpdate()
    if keyboardJustPressed('F7') then
        openCustomSubstate('info', true)
    end
end

function onCustomSubstateCreate(name)
    if name == 'info' then
        makeLuaText('infoText', 'Press Escape to return', 600, 80, 80)
        setObjectCamera('infoText', 'other')
        addToCustomSubstate('infoText')
    end
end

function onCustomSubstateUpdate(name, elapsed)
    if name == 'info' and keyboardJustPressed('ESCAPE') then
        closeCustomSubstate()
    end
end
```

Objects moved into the custom substate are destroyed when it closes. Native stages, characters, other mod systems, and the game itself keep their original ownership.

Opening and closing use Flixel's deferred state transitions. `closeCustomSubstate()` requests a close; objects can still exist until the next state-update boundary. Use `onCustomSubstateDestroy` for the close notification, or check for cleanup on a later frame rather than immediately after requesting it.

## Callbacks and globals

Callbacks: `onCreate`, `onCreatePost`, `onDestroy`, `onReload`, `onUpdate(elapsed)`, `onUpdatePost(elapsed)`, `onStartCountdown`, `onCountdownTick(index)`, `onSongStart`, `onEndSong`, `onPause`, `onResume`, `onGameOver`, `onSongRetry`, `onBeatHit`, `onStepHit`, `onSectionHit`, `onMoveCamera(target)`, `onSpawnNote(id, direction, kind, isSustainNote)`, `goodNoteHit`, `opponentNoteHit`, `noteMiss`, `noteMissPress(direction)`, `onEvent(name, value1, value2, time)`, `onTimerCompleted`, `onTweenCompleted`, `onSoundFinished`, and the custom-substate callbacks shown above plus `onCustomSubstateCreatePost`, `onCustomSubstateUpdatePost`, and `onCustomSubstateDestroy`.

`Function_Continue`, `Function_Stop`, `Function_StopLua`, and `Function_StopAll` are available. Native cancellable events honor Stop/StopAll. Stopping Lua propagation is not permission to undo already-run native callbacks.

Globals include `version` (Psych API reference version), `vSliceVersion`, `scriptName`, `modFolder`, `curBeat`, `curStep`, `curDecBeat`, `curDecStep`, `curSection`, `bpm`, `curBpm`, `crochet`, `stepCrochet`, `songPosition`, `songName`, `songPath`, `songLength`, `curStage`, `screenWidth`, `screenHeight`, `downscroll`, `scrollSpeed`, `score`, `health`, `difficultyName`, `inGameOver`, and `mustHitSection`. The last is derived from native FocusCamera events, because V-Slice has no Psych `mustHitSection` chart sections.

## Compatibility boundaries

Song scripts also load from `data/songs/<song-id>/`. For example, use `data/songs/black-knife/knightscript.lua`. A unique case-insensitive song-folder match is accepted, so `Black-Knife` can match the `black-knife` song ID. Mod-local image and audio lookup also accepts unique case-insensitive matches; fixing filename capitalization in the mod is still recommended.

`addCharacterToList(id, role)` precaches a **native V-Slice character**. `triggerEvent('Change Character', role, id)` swaps it into the current stage and updates the health icon. Roles accept `bf`/`boyfriend`/`0`, `dad`/`1`, and `gf`/`2`. Character JSON and its assets must exist; these calls do not convert Psych character JSON or invent missing images. Character properties `curCharacter`, `imageFile`, and `healthColorArray` are supported. Setting `isCameraOnForcedPos` prevents native FocusCamera events from replacing the scripted camera target.

Animated sprites made from a current Sparrow character's `imageFile` reuse its frames and animation names. This supports ghost-trail scripts without reloading the atlas on every frame. Native Animate/MultiAtlas characters are not converted into Sparrow sprites.

This is an API adapter, **not the complete Psych engine**. Native V-Slice song, character, stage, event, notestyle, and asset formats still apply. Psych chart/character JSON, stage code that assumes Psych's class fields, and complete Psych mods are not automatically converted by adding Lua.

- `boyfriend`, `dad`, `gf`, `camGame`, `camHUD`, `camOther`, `camFollow`, `notes`, `unspawnNotes`, `playerStrums`, `opponentStrums`, and `strumLineNotes` map to native objects. Receptor indexes are opponent 0–3, player 4–7. Active-note indexes are temporary: do not retain them across frames.
- Native holds are continuous trails, not separate Psych sustain segments. Their note callbacks use `isSustainNote = true` at step intervals while held; no extra segmented hold sprites are generated.
- Note properties `texture`, `noteSplashTexture`, `antialiasing`, `ignoreNote`, `hitCausesMiss`, `missHealth`, `hitHealth`, and `noteSplashDisabled` work through group/property helpers. Settings on chart notes are applied when their native sprites spawn and do not transfer to other notes when sprites are recycled. `ignoreNote` suppresses missed-note and dropped-hold penalties, not player hits; botplay skips ignored notes. `hitCausesMiss` uses `missHealth` as the loss amount when hit (zero is valid).
- Custom note heads use mod-local Sparrow atlases, or Psych pixel sheets under `images/pixelUI` when the chart uses the `pixel` note style. Pixel sheets have four columns and five rows; their matching `nameENDS.png` files have four columns and two rows. The pixel tails are converted to native continuous trails in memory. Non-pixel custom hold atlases are not converted yet. The native hold style remains in use for those.
- `noteSplashTexture` accepts a mod-local legacy Psych Sparrow splash atlas (`note splash purple1`, etc.). A missing splash atlas keeps the native splash and logs one warning, rather than crashing. This is not a replacement for an asset the mod author omitted. Advanced Psych 1.0 splash configuration is not converted.
- `triggerVSliceEvent` accepts native event-value objects. `triggerEvent` supplies Psych-style `value1`/`value2` to Lua callbacks; it does not invent implementations for every Psych built-in event.
- Native HScript `.hxc` modules remain the official FNF system. `runHaxeCode` uses a separate Iris interpreter owned by its Lua script. Lua cross-script helpers do not silently dispatch into native HScript modules.
- `camOther` uses the native cutscene camera. Default cameras and native character animation names are not renamed.
- `saveFile`, `deleteFile`, and directory helpers operate within the owning mod. Legacy absolute-path flags do not grant access outside it.
- Psych-only achievements, dialogue JSON, FlxAnimate-specific Lua helpers, rating overrides, and engine-specific class fields are not claimed as supported here. Use the native game systems or adapt the script.

Check a callback with `isLuaFunctionSupported('callbackName')` before using optional behavior. An unsupported callback must not be treated as a successful operation. See `source/funkin/modding/psychlua/PsychLuaAPI.hx` for exact signatures and registered names.

## Attribution

API conventions reference Psych Engine 1.0.4 by Shadow Mario, RiverOaken, and contributors (Apache-2.0; license in `licenses`). The integration and V-Slice mappings are modified/new code. FNF retains its original credits and license. LuaJIT and Iris retain their own licenses.
