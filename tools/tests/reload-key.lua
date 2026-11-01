-- Isolated regression fixture. Requires the example mod metadata and --lua-song=tutorial.
local elapsedTotal = 0
local requested = false

function onCreate()
    setPropertyFromClass('flixel.FlxG', 'autoPause', false)
    setPropertyFromClass('funkin.Preferences', 'autoPause', false)
    setProperty('isPracticeMode', true)
    local launches = (getVar('reloadKeyLaunches') or 0) + 1
    setVar('reloadKeyLaunches', launches)
    if launches > 1 then
        saveFile('legacy-chord-failed.txt', 'Ctrl+Shift+R reloaded Lua scripts')
    end
    if checkFileExists('native-f5-requested.txt') then
        assert(getVar('reloadKeyLaunches') == 1, 'F5 must create a new host, not reload scripts twice')
        saveFile('native-f5-passed.txt', 'F5 restarted the native state and loaded Lua scripts')
        requested = true
    end
end

function onUpdate(elapsed)
    elapsedTotal = elapsedTotal + elapsed
    if requested or elapsedTotal < 1 then return end
    requested = true
    addHaxeLibrary('File', 'sys.io')
    addHaxeLibrary('ReloadAssetsDebugPlugin', 'funkin.util.plugins')
    runHaxeCode([[
        var host = game.psychLua;
        new FlxTimer().start(0.1, function(timer) {
            FlxG.keys._keyListMap.get(17).press();
            FlxG.keys._keyListMap.get(16).press();
            FlxG.keys._keyListMap.get(82).press();
            host.update(0);
            FlxG.keys.reset();
            if (host.variables.get('reloadKeyLaunches') != 1) return;
            File.saveContent(reloadTestRoot + '/legacy-chord-passed.txt', 'Obsolete chord did not reload');
            File.saveContent(reloadTestRoot + '/native-f5-requested.txt', 'requested');
            new FlxTimer().start(0.1, function(timer) {
                FlxG.keys._keyListMap.get(116).press();
                var plugin = FlxG.plugins.get(ReloadAssetsDebugPlugin);
                if (plugin == null) throw 'Native F5 reload plugin is unavailable';
                plugin.update(0);
                FlxG.keys.reset();
            });
        });
    ]], {reloadTestRoot = modFolder})
end
