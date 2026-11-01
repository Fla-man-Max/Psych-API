local hits = 0
local timerPassed = false
local tweenPassed = false
local ready = false

local function status()
    if not ready then return end
    setTextString('luaTestStatus', 'Psych Lua: ' .. songName
        .. '\nTimer: ' .. tostring(timerPassed)
        .. ' | Tween: ' .. tostring(tweenPassed)
        .. ' | Hits: ' .. hits
        .. '\nCtrl+Shift+R: reload scripts | F6: change color')
end

function onCreate()
    assert(isLuaFunctionSupported('makeLuaSprite'))
    assert(isLuaFunctionSupported('getProperty'))
    assert(getPropertyFromGroup('playerStrums', 0, 'x') ~= nil)
    assert(isLuaFunctionSupported('runHaxeCode'), 'This executable needs rebuilding: runHaxeCode is missing')
    assert(runHaxeCode('return 6 * 7;') == 42)
    runHaxeCode('function doubleValue(value) { return value * 2; }')
    assert(runHaxeFunction('doubleValue', {21}) == 42)
    local autoPause = getPropertyFromClass('flixel.FlxG', 'autoPause')
    setPropertyFromClass('flixel.FlxG', 'autoPause', not autoPause)
    assert(getPropertyFromClass('flixel.FlxG', 'autoPause') == not autoPause)
    setPropertyFromClass('flixel.FlxG', 'autoPause', autoPause)
    assert(callMethodFromClass('Std', 'string', {42}) == '42')

    makeLuaSprite('luaTestPanel', nil, 16, 16)
    makeGraphic('luaTestPanel', 560, 104, '101824')
    setObjectCamera('luaTestPanel', 'hud')
    setProperty('luaTestPanel.alpha', 0.85)
    addLuaSprite('luaTestPanel', true)

    makeLuaText('luaTestStatus', '', 536, 28, 24)
    setTextSize('luaTestStatus', 18)
    setTextColor('luaTestStatus', 'A7E8FF')
    addLuaText('luaTestStatus')
    ready = true
    status()

    initSaveData('psychLuaTest')
    local launches = getDataFromSave('psychLuaTest', 'launches', 0) + 1
    setDataFromSave('psychLuaTest', 'launches', launches)
    assert(getDataFromSave('psychLuaTest', 'launches', 0) == launches)
    debugPrint('PSYCH_TEST_CREATE_OK', launches)
    runTimer('luaTestTimer', 0.5)
    doTweenAlpha('luaTestTween', 'luaTestPanel', 0.7, 0.3, 'linear')
end

function onCreatePost()
    debugPrint('PSYCH_TEST_CREATE_POST_OK')
end

function onTimerCompleted(tag, loops, loopsLeft)
    if tag == 'luaTestTimer' then
        timerPassed = true
        status()
        debugPrint('PSYCH_TEST_TIMER_OK')
    end
end

function onTweenCompleted(tag)
    if tag == 'luaTestTween' then
        tweenPassed = true
        status()
        debugPrint('PSYCH_TEST_TWEEN_OK')
    end
end

function goodNoteHit(id, direction, noteType, isSustainNote)
    hits = hits + 1
    status()
end

function onUpdate(elapsed)
    if keyboardJustPressed('F6') then
        setTextColor('luaTestStatus', 'FFE08A')
    end
end

function onReload()
    debugPrint('PSYCH_TEST_RELOAD_OK')
end

function onDestroy()
    debugPrint('PSYCH_TEST_DESTROY_OK')
end
