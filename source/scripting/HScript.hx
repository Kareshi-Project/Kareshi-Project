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

// ==================== Script Result ====================

typedef ScriptResult =
{
    var success:Bool;
    var value:Dynamic;
    var error:String;
}

// ==================== HScript ====================

class HScript
{
    // ==================== Core ====================

    var parser:Parser;
    var interp:Interp;
    var ast:Expr;

    public var scriptPath:String  = "";
    public var isLoaded:Bool      = false;
    public var hasError:Bool      = false;
    public var lastError:String   = "";

    // Callbacks externos
    public var onError:String -> Void = null;
    public var onTrace:String -> Void = null;

    // ==================== Static Cache ====================

    static var cache:Map<String, Expr> = new Map();

    // ==================== Constructor ====================

    public function new()
    {
        parser = new Parser();
        interp = new Interp();

        parser.allowJSON    = true;
        parser.allowTypes   = true;
        parser.allowMetadata = true;

        setupDefaultVariables();
    }

    // ==================== Default Variables ====================

    function setupDefaultVariables():Void
    {
        // ---- Flixel ----
        set("FlxG",       FlxG);
        set("FlxSprite",  FlxSprite);
        set("FlxText",    FlxText);
        set("FlxColor",   FlxColor);
        set("FlxTween",   FlxTween);
        set("FlxEase",    FlxEase);
        set("FlxMath",    FlxMath);

        // ---- Haxe stdlib ----
        set("Math",       Math);
        set("Std",        Std);
        set("StringTools",StringTools);
        set("Reflect",    Reflect);
        set("Type",       Type);
        set("Date",       Date);
        set("Lambda",     Lambda);

        // ---- Helpers ----
        set("trace", function(v:Dynamic)
        {
            var msg = Std.string(v);
            if (onTrace != null)
                onTrace(msg);
            else
                trace('[HScript] $msg');
        });

        set("print", function(v:Dynamic)
        {
            var msg = Std.string(v);
            if (onTrace != null)
                onTrace(msg);
            else
                trace('[HScript] $msg');
        });

        // ---- Interop com o jogo ----
        set("switchState", function(state:FlxState)
        {
            FlxG.switchState(state);
        });

        set("playSound", function(key:String, volume:Float = 1.0)
        {
            FlxG.sound.play(key, volume);
        });

        set("playMusic", function(key:String, volume:Float = 1.0)
        {
            FlxG.sound.playMusic(key, volume);
        });

        set("stopMusic", function()
        {
            if (FlxG.sound.music != null)
                FlxG.sound.music.stop();
        });

        set("random", function(min:Float, max:Float):Float
        {
            return FlxG.random.float(min, max);
        });

        set("randomInt", function(min:Int, max:Int):Int
        {
            return FlxG.random.int(min, max);
        });

        set("lerp", function(a:Float, b:Float, t:Float):Float
        {
            return FlxMath.lerp(a, b, t);
        });

        set("colorFromRGB", function(r:Int, g:Int, b:Int):FlxColor
        {
            return FlxColor.fromRGB(r, g, b);
        });

        set("colorFromHex", function(hex:String):FlxColor
        {
            return frontend.JsonHelper.hexToColor(hex);
        });

        set("getWidth",  function() return FlxG.width);
        set("getHeight", function() return FlxG.height);

        set("log", function(msg:String)
        {
            trace('[HScript:LOG] $msg');
        });
    }

    // ==================== Load ====================

    /**
     * Carrega e compila um script pelo caminho de asset.
     */
    public function load(path:String):Bool
    {
        scriptPath = path;
        isLoaded   = false;
        hasError   = false;
        lastError  = "";

        if (!Assets.exists(path))
        {
            setError('Script not found: $path');
            return false;
        }

        var raw = Assets.getText(path);
        if (raw == null || raw.length == 0)
        {
            setError('Script is empty: $path');
            return false;
        }

        return loadFromString(raw, path);
    }

    /**
     * Carrega e compila um script a partir de uma string.
     */
    public function loadFromString(code:String, label:String = "inline"):Bool
    {
        scriptPath = label;
        isLoaded   = false;
        hasError   = false;
        lastError  = "";

        // Usa cache se disponível
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
            setError('Parse error in $label: $e');
            return false;
        }

        return true;
    }

    // ==================== Execute ====================

    /**
     * Executa o script carregado.
     */
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

    /**
     * Executa e retorna o valor tipado.
     */
    public function executeTyped<T>():T
    {
        var result = execute();
        if (!result.success) return null;
        return cast result.value;
    }

    // ==================== Function Calls ====================

    /**
     * Chama uma função definida no script.
     */
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

    /**
     * Verifica se uma função existe no script.
     */
    public function hasFunction(funcName:String):Bool
    {
        if (!isLoaded) return false;
        var func = interp.variables.get(funcName);
        return func != null && Reflect.isFunction(func);
    }

    // ==================== Variables ====================

    /**
     * Define uma variável acessível pelo script.
     */
    public function set(name:String, value:Dynamic):Void
    {
        interp.variables.set(name, value);
    }

    /**
     * Obtém o valor de uma variável do script.
     */
    public function get(name:String):Dynamic
    {
        return interp.variables.get(name);
    }

    /**
     * Remove uma variável do escopo do script.
     */
    public function unset(name:String):Void
    {
        interp.variables.remove(name);
    }

    /**
     * Verifica se uma variável existe no script.
     */
    public function exists(name:String):Bool
    {
        return interp.variables.exists(name);
    }

    // ==================== State Injection ====================

    /**
     * Injeta referências de um FlxState no script.
     */
    public function injectState(state:FlxState):Void
    {
        set("state",     state);
        set("add",       function(obj:Dynamic) state.add(obj));
        set("remove",    function(obj:Dynamic) state.remove(obj));
        set("openSub",   function(sub:Dynamic) state.openSubState(sub));
        set("closeSub",  function()            state.closeSubState());
    }

    /**
     * Injeta um objeto com um nome no escopo.
     */
    public function injectObject(name:String, obj:Dynamic):Void
    {
        set(name, obj);

        // Expõe campos públicos do objeto diretamente
        for (field in Reflect.fields(obj))
        {
            var val = Reflect.field(obj, field);
            if (val != null)
                set('${name}_$field', val);
        }
    }

    // ==================== Lifecycle Hooks ====================

    /**
     * Chama onCreate() se existir no script.
     */
    public function onCreate():Void
    {
        if (hasFunction("onCreate"))
            call("onCreate");
    }

    /**
     * Chama onUpdate(elapsed) se existir no script.
     */
    public function onUpdate(elapsed:Float):Void
    {
        if (hasFunction("onUpdate"))
            call("onUpdate", [elapsed]);
    }

    /**
     * Chama onDestroy() se existir no script.
     */
    public function onDestroy():Void
    {
        if (hasFunction("onDestroy"))
            call("onDestroy");
    }

    /**
     * Chama um hook genérico pelo nome.
     */
    public function callHook(name:String, ?args:Array<Dynamic>):Dynamic
    {
        if (!hasFunction(name)) return null;
        var result = call(name, args);
        return result.success ? result.value : null;
    }

    // ==================== Error Handling ====================

    function setError(msg:String):Void
    {
        hasError  = true;
        lastError = msg;
        trace('[HScript:ERROR] $msg');

        if (onError != null)
            onError(msg);
    }

    // ==================== Static Helpers ====================

    /**
     * Cria e executa um script inline rapidamente.
     */
    public static function run(code:String, ?vars:Map<String, Dynamic>):ScriptResult
    {
        var hs = new HScript();
        if (vars != null)
            for (k => v in vars)
                hs.set(k, v);

        if (!hs.loadFromString(code))
            return { success: false, value: null, error: hs.lastError };

        return hs.execute();
    }

    /**
     * Executa um script de arquivo rapidamente.
     */
    public static function runFile(path:String, ?vars:Map<String, Dynamic>):ScriptResult
    {
        var hs = new HScript();
        if (vars != null)
            for (k => v in vars)
                hs.set(k, v);

        if (!hs.load(path))
            return { success: false, value: null, error: hs.lastError };

        return hs.execute();
    }

    /**
     * Limpa o cache de scripts compilados.
     */
    public static function clearCache():Void
    {
        cache.clear();
    }

    /**
     * Remove um script específico do cache.
     */
    public static function removeFromCache(path:String):Void
    {
        cache.remove(path);
    }
}
