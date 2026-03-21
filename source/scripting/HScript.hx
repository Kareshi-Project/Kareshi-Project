package scripting;

import hscript.Parser;
import hscript.Interp;
import hscript.Expr;
import openfl.Assets;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.math.FlxMath;

typedef ScriptResult =
{
    var success:Bool;
    var value:Dynamic;
    var error:String;
}

class HScript
{
    var parser:Parser;
    var interp:Interp;
    var ast:Expr;

    public var scriptPath:String = "";
    public var isLoaded:Bool     = false;
    public var hasError:Bool     = false;
    public var lastError:String  = "";

    public var onError:String -> Void = null;
    public var onTrace:String -> Void = null;

    static var cache:Map<String, Expr> = new Map();

    public function new()
    {
        parser = new Parser();
        interp = new Interp();

        parser.allowJSON     = true;
        parser.allowTypes    = true;
        parser.allowMetadata = true;

        setupDefaultVariables();
    }

    function setupDefaultVariables():Void
    {
        // ==================== Flixel ====================
        set("FlxG",      FlxG);
        set("FlxSprite", FlxSprite);
        set("FlxText",   FlxText);
        set("FlxTween",  FlxTween);
        set("FlxEase",   FlxEase);
        set("FlxMath",   FlxMath);

        // FlxColor é abstract — expõe via objeto anônimo
        set("FlxColor", {
            RED:          (FlxColor.RED         : Int),
            GREEN:        (FlxColor.GREEN        : Int),
            BLUE:         (FlxColor.BLUE         : Int),
            WHITE:        (FlxColor.WHITE        : Int),
            BLACK:        (FlxColor.BLACK        : Int),
            YELLOW:       (FlxColor.YELLOW       : Int),
            CYAN:         (FlxColor.CYAN         : Int),
            MAGENTA:      (FlxColor.MAGENTA      : Int),
            ORANGE:       (FlxColor.ORANGE       : Int),
            PINK:         (FlxColor.PINK         : Int),
            PURPLE:       (FlxColor.PURPLE       : Int),
            GRAY:         (FlxColor.GRAY         : Int),
            TRANSPARENT:  (FlxColor.TRANSPARENT  : Int),
            fromRGB:      function(r:Int, g:Int, b:Int):Int
                              return (FlxColor.fromRGB(r, g, b) : Int),
            fromRGBFloat: function(r:Float, g:Float, b:Float):Int
                              return (FlxColor.fromRGBFloat(r, g, b) : Int),
            fromInt:      function(v:Int):Int
                              return (FlxColor.fromInt(v) : Int),
            interpolate:  function(a:Int, b:Int, t:Float):Int
                              return (FlxColor.interpolate(a, b, t) : Int)
        });

        // ==================== Haxe stdlib ====================
        set("Math",        Math);
        set("Std",         Std);
        set("StringTools", StringTools);
        set("Reflect",     Reflect);
        set("Type",        Type);
        set("Date",        Date);
        set("Lambda",      Lambda);

        // ==================== Trace / Print ====================
        set("trace", function(v:Dynamic)
        {
            var msg = Std.string(v);
            if (onTrace != null) onTrace(msg);
            else trace('[HScript] $msg');
        });

        set("print", function(v:Dynamic)
        {
            var msg = Std.string(v);
            if (onTrace != null) onTrace(msg);
            else trace('[HScript] $msg');
        });

        set("log", function(msg:String)
        {
            trace('[HScript:LOG] $msg');
        });

        // ==================== Game helpers ====================
        set("switchState", function(state:FlxState) FlxG.switchState(state));

        set("playSound",  function(key:String, volume:Float = 1.0)
            FlxG.sound.play(key, volume));

        set("playMusic",  function(key:String, volume:Float = 1.0)
            FlxG.sound.playMusic(key, volume));

        set("stopMusic",  function()
        {
            if (FlxG.sound.music != null) FlxG.sound.music.stop();
        });

        set("getWidth",  function() return FlxG.width);
        set("getHeight", function() return FlxG.height);

        // ==================== Math helpers ====================
        set("random",    function(min:Float, max:Float):Float  return FlxG.random.float(min, max));
        set("randomInt", function(min:Int,   max:Int):Int      return FlxG.random.int(min, max));

        set("lerp",      function(a:Float, b:Float, t:Float):Float return FlxMath.lerp(a, b, t));

        set("lerpColor", function(a:Int, b:Int, t:Float):Int
            return (FlxColor.interpolate(a, b, t) : Int));

        set("colorFromRGB", function(r:Int, g:Int, b:Int):Int
            return (FlxColor.fromRGB(r, g, b) : Int));

        set("colorFromHex", function(hex:String):Int
            return (frontend.JsonHelper.hexToColor(hex) : Int));
    }

    // ==================== Load ====================

    public function load(path:String):Bool
    {
        scriptPath = path;
        isLoaded   = false;
        hasError   = false;
        lastError  = "";

        if (!Assets.exists(path))
            return setError('Script not found: $path');

        var raw = Assets.getText(path);
        if (raw == null || raw.length == 0)
            return setError('Script is empty: $path');

        return loadFromString(raw, path);
    }

    public function loadFromString(code:String, label:String = "inline"):Bool
    {
        scriptPath = label;
        isLoaded   = false;
        hasError   = false;
        lastError  = "";

        if (cache.exists(label))
        {
            ast      = cache.get(label);
            isLoaded = true;
            return true;
        }

        try
        {
            ast = parser.parseString(code);
            cache.set(label, ast);
            isLoaded = true;
        }
        catch (e:Dynamic)
        {
            return setError('Parse error in $label: $e');
        }

        return true;
    }

    // ==================== Execute ====================

    public function execute():ScriptResult
    {
        if (!isLoaded || ast == null)
            return { success: false, value: null, error: 'Script not loaded: $scriptPath' };

        try
        {
            var result = interp.execute(ast);
            return { success: true, value: result, error: "" };
        }
        catch (e:Dynamic)
        {
            var msg = 'Runtime error in $scriptPath: $e';
            setError(msg);
            return { success: false, value: null, error: msg };
        }
    }

    public function executeTyped<T>():T
    {
        var result = execute();
        return result.success ? cast result.value : null;
    }

    // ==================== Function Calls ====================

    public function call(funcName:String, ?args:Array<Dynamic>):ScriptResult
    {
        if (!isLoaded)
            return { success: false, value: null, error: 'Script not loaded' };

        var func = interp.variables.get(funcName);

        if (func == null)
            return { success: false, value: null, error: 'Function not found: $funcName' };

        if (!Reflect.isFunction(func))
            return { success: false, value: null, error: '$funcName is not a function' };

        try
        {
            var result = Reflect.callMethod(null, func, args ?? []);
            return { success: true, value: result, error: "" };
        }
        catch (e:Dynamic)
        {
            var msg = 'Error calling $funcName in $scriptPath: $e';
            setError(msg);
            return { success: false, value: null, error: msg };
        }
    }

    public function hasFunction(funcName:String):Bool
    {
        if (!isLoaded) return false;
        var func = interp.variables.get(funcName);
        return func != null && Reflect.isFunction(func);
    }

    // ==================== Variables ====================

    public function set(name:String, value:Dynamic):Void
        interp.variables.set(name, value);

    public function get(name:String):Dynamic
        return interp.variables.get(name);

    public function unset(name:String):Void
        interp.variables.remove(name);

    public function exists(name:String):Bool
        return interp.variables.exists(name);

    // ==================== State Injection ====================

    public function injectState(state:FlxState):Void
    {
        set("state",    state);
        set("add",      function(obj:Dynamic) state.add(obj));
        set("remove",   function(obj:Dynamic) state.remove(obj));
        set("openSub",  function(sub:Dynamic) state.openSubState(sub));
        set("closeSub", function()            state.closeSubState());
    }

    public function injectObject(name:String, obj:Dynamic):Void
    {
        set(name, obj);
        for (field in Reflect.fields(obj))
        {
            var val = Reflect.field(obj, field);
            if (val != null) set('${name}_$field', val);
        }
    }

    // ==================== Lifecycle ====================

    public function onCreate():Void
    {
        if (hasFunction("onCreate")) call("onCreate");
    }

    public function onUpdate(elapsed:Float):Void
    {
        if (hasFunction("onUpdate")) call("onUpdate", [elapsed]);
    }

    public function onDestroy():Void
    {
        if (hasFunction("onDestroy")) call("onDestroy");
    }

    public function callHook(name:String, ?args:Array<Dynamic>):Dynamic
    {
        if (!hasFunction(name)) return null;
        var result = call(name, args);
        return result.success ? result.value : null;
    }

    // ==================== Error ====================

    function setError(msg:String):Bool
    {
        hasError  = true;
        lastError = msg;
        trace('[HScript:ERROR] $msg');
        if (onError != null) onError(msg);
        return false;
    }

    // ==================== Static ====================

    public static function run(code:String, ?vars:Map<String, Dynamic>):ScriptResult
    {
        var hs = new HScript();
        if (vars != null)
            for (k => v in vars) hs.set(k, v);

        if (!hs.loadFromString(code))
            return { success: false, value: null, error: hs.lastError };

        return hs.execute();
    }

    public static function runFile(path:String, ?vars:Map<String, Dynamic>):ScriptResult
    {
        var hs = new HScript();
        if (vars != null)
            for (k => v in vars) hs.set(k, v);

        if (!hs.load(path))
            return { success: false, value: null, error: hs.lastError };

        return hs.execute();
    }

    public static function clearCache():Void
        cache.clear();

    public static function removeFromCache(path:String):Void
        cache.remove(path);
}