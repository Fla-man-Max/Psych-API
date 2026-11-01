package funkin.modding.psychlua;

#if FEATURE_PSYCH_LUA
import llua.Lua;
import llua.Lua.Lua_helper;
import llua.LuaL;
import llua.Convert;
import llua.State;

class PsychLuaScript
{
  public static inline var CONTINUE = '##PSYCHLUA_FUNCTIONCONTINUE';
  public static inline var STOP = '##PSYCHLUA_FUNCTIONSTOP';
  public static inline var STOP_LUA = '##PSYCHLUA_FUNCTIONSTOPLUA';
  public static inline var STOP_ALL = '##PSYCHLUA_FUNCTIONSTOPALL';
  static var nextId:Int = 0;
  public final id:Int;
  public final path:String;
  public final root:String;
  public final host:PsychLuaHost;
  public var lua(default, null):State;
  public var closed:Bool = false;
  public var depth(default, null):Int = 0;
  public var api:PsychLuaAPI;
  var destroying:Bool = false;
  final callbackNames:Array<String> = [];
  final reported:Map<String, Bool> = [];

  public function new(host:PsychLuaHost, path:String, root:String)
  {
    this.host = host;
    this.path = path;
    this.root = root;
    id = ++nextId;
    lua = LuaL.newstate();
    if (lua == null) throw 'Could not create Lua state for $path';
    LuaL.openlibs(lua);
    Lua.init_callbacks(lua);
    PsychLuaAPI.register(this);
    set('Function_Continue', CONTINUE);
    set('Function_Stop', STOP);
    set('Function_StopLua', STOP_LUA);
    set('Function_StopAll', STOP_ALL);
    set('Function_StopHScript', '##PSYCHLUA_FUNCTIONSTOPHSCRIPT');
    set('version', '1.0.4');
    set('vSliceVersion', '0.8.7');
    set('scriptName', path);
    set('modFolder', root);
    set('luaDebugMode', false);
    set('luaDeprecatedWarnings', true);
    set('__psychModulePath', root + '/?.lua;' + root + '/?/init.lua');
    execute("package.path = __psychModulePath .. ';' .. package.path", '@module-path');
    host.updateGlobals(this);
  }

  public function register(name:String, callback:Dynamic):Void
  {
    var unique = '__psych_' + id + '_' + name;
    Lua_helper.add_callback(lua, unique, callback);
    callbackNames.push(unique);
    Lua.getglobal(lua, unique);
    Lua.setglobal(lua, name);
    Lua.pushnil(lua);
    Lua.setglobal(lua, unique);
  }

  public function compile(source:String):Bool
  {
    if (source.length > 0 && source.charCodeAt(0) == 0xFEFF) source = source.substr(1);
    var top = Lua.gettop(lua);
    var result = LuaL.loadstring(lua, source);
    if (result != Lua.LUA_OK) report('parse', Lua.tostring(lua, -1));
    Lua.settop(lua, top);
    return result == Lua.LUA_OK;
  }

  public function execute(source:String, label:String):Bool
  {
    if (closed || lua == null) return false;
    if (source.length > 0 && source.charCodeAt(0) == 0xFEFF) source = source.substr(1);
    var top = Lua.gettop(lua);
    depth++;
    var result = LuaL.loadstring(lua, source);
    if (result == Lua.LUA_OK) result = Lua.pcall(lua, 0, 0, 0);
    if (result != Lua.LUA_OK) report(label, Lua.tostring(lua, -1));
    Lua.settop(lua, top);
    depth--;
    return result == Lua.LUA_OK;
  }

  public function call(name:String, args:Array<Dynamic>):Dynamic
  {
    if (closed || lua == null) return CONTINUE;
    var top = Lua.gettop(lua);
    Lua.getglobal(lua, name);
    if (Lua.type(lua, -1) != Lua.LUA_TFUNCTION)
    {
      Lua.settop(lua, top);
      return CONTINUE;
    }
    depth++;
    for (arg in args) if (!Convert.toLua(lua, arg)) Lua.pushnil(lua);
    var status = Lua.pcall(lua, args.length, 1, 0);
    var result:Dynamic = CONTINUE;
    if (status == Lua.LUA_OK) result = Convert.fromLua(lua, -1);
    else report(name, Lua.tostring(lua, -1));
    Lua.settop(lua, top);
    depth--;
    return result == null ? CONTINUE : result;
  }

  public function set(name:String, value:Dynamic):Void
  {
    if (closed || lua == null) return;
    if (!Convert.toLua(lua, value)) Lua.pushnil(lua);
    Lua.setglobal(lua, name);
  }

  public function get(name:String):Dynamic
  {
    if (closed || lua == null) return null;
    Lua.getglobal(lua, name);
    var value = Convert.fromLua(lua, -1);
    Lua.pop(lua, 1);
    return value;
  }

  public function report(hook:String, message:String):Void
  {
    var key = hook + ':' + message;
    if (reported.exists(key)) return;
    reported.set(key, true);
    host.report('[$path][$hook] $message');
  }

  public function destroy():Void
  {
    if (lua == null || destroying) return;
    if (depth != 0) { closed = true; return; }
    destroying = true;
    if (!closed) call('onDestroy', []);
    closed = true;
    host.releaseOwned(this);
    api?.destroy();
    api = null;
    for (name in callbackNames) Lua_helper.callbacks.remove(name);
    callbackNames.resize(0);
    Lua.close(lua);
    lua = null;
  }
}
#end
