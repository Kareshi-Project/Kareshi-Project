package frontend;

import openfl.Assets;
import haxe.Json;

typedef CharacterData =
{
    var id:String;
    var name:String;
    var title:String;
    var description:String;
    var stats:CharacterStats;
    var sprite:CharacterSprite;
    var hitbox:CharacterHitbox;
    var shotTypes:Array<ShotType>;
    var bomb:BombData;
    var colors:CharacterColors;
    var unlock:UnlockData;
    var lore:Dynamic;
}

typedef CharacterStats =
{
    var lives:Int;
    var bombs:Int;
    var moveSpeed:Float;
    var focusSpeed:Float;
    var hitboxRadius:Float;
    var power:Float;
    var collectRadius:Float;
}

typedef CharacterSprite =
{
    var path:String;
    var frameWidth:Int;
    var frameHeight:Int;
    var animations:Dynamic;
}

typedef CharacterHitbox =
{
    var width:Float;
    var height:Float;
    var color:String;
    var showOnFocus:Bool;
}

typedef ShotType =
{
    var id:String;
    var name:String;
    var description:String;
    var cooldown:Float;
    var bullets:Array<BulletData>;
}

typedef BulletData =
{
    var angle:Float;
    var speed:Float;
    var color:String;
    var radius:Int;
    var damage:Float;
    @:optional var offsetX:Float;
    @:optional var offsetY:Float;
}

typedef BombData =
{
    var id:String;
    var name:String;
    var description:String;
    var duration:Float;
    var invincibleDuration:Float;
    var damage:Float;
    var bulletCount:Int;
    var bulletSpeed:Float;
    var bulletColor:String;
    var bulletRadius:Int;
}

typedef CharacterColors =
{
    var primary:String;
    var secondary:String;
    var ui:String;
    var name:String;
}

typedef UnlockData =
{
    var unlocked:Bool;
    var condition:String;
}

class JsonHelper
{
    // ==================== Cache ====================

    static var cache:Map<String, Dynamic> = new Map();

    // ==================== Core ====================

    /**
     * Carrega e faz parse de um JSON pelo caminho.
     * Usa cache para evitar leitura duplicada.
     */
    public static function load(path:String):Dynamic
    {
        if (cache.exists(path))
            return cache.get(path);

        if (!Assets.exists(path))
        {
            trace('[JsonHelper] File not found: $path');
            return null;
        }

        var raw = Assets.getText(path);
        if (raw == null || raw.length == 0)
        {
            trace('[JsonHelper] Empty file: $path');
            return null;
        }

        var parsed:Dynamic = null;
        try
        {
            parsed = Json.parse(raw);
            cache.set(path, parsed);
        }
        catch (e:Dynamic)
        {
            trace('[JsonHelper] Parse error in $path: $e');
            return null;
        }

        return parsed;
    }

    /**
     * Força recarregar um JSON ignorando o cache.
     */
    public static function reload(path:String):Dynamic
    {
        cache.remove(path);
        return load(path);
    }

    /**
     * Limpa todo o cache.
     */
    public static function clearCache():Void
    {
        cache.clear();
    }

    /**
     * Remove um item específico do cache.
     */
    public static function removeFromCache(path:String):Void
    {
        cache.remove(path);
    }

    // ==================== Typed Loaders ====================

    /**
     * Carrega um JSON de personagem tipado.
     */
    public static function loadCharacter(id:String):CharacterData
    {
        var path = 'data/characters/$id.json';
        var data = load(path);
        if (data == null) return null;
        return cast data;
    }

    /**
     * Carrega todos os personagens disponíveis.
     */
    public static function loadAllCharacters(ids:Array<String>):Array<CharacterData>
    {
        var result:Array<CharacterData> = [];
        for (id in ids)
        {
            var char = loadCharacter(id);
            if (char != null)
                result.push(char);
        }
        return result;
    }

    // ==================== Field Getters ====================

    /**
     * Retorna um campo de um objeto Dynamic com fallback.
     */
    public static function get(obj:Dynamic, field:String, fallback:Dynamic = null):Dynamic
    {
        if (obj == null) return fallback;
        var val = Reflect.field(obj, field);
        return val != null ? val : fallback;
    }

    /**
     * Retorna um campo como String.
     */
    public static function getString(obj:Dynamic, field:String, fallback:String = ""):String
    {
        return Std.string(get(obj, field, fallback));
    }

    /**
     * Retorna um campo como Int.
     */
    public static function getInt(obj:Dynamic, field:String, fallback:Int = 0):Int
    {
        var val = get(obj, field, fallback);
        return Std.parseInt(Std.string(val)) ?? fallback;
    }

    /**
     * Retorna um campo como Float.
     */
    public static function getFloat(obj:Dynamic, field:String, fallback:Float = 0.0):Float
    {
        var val = get(obj, field, fallback);
        return Std.parseFloat(Std.string(val));
    }

    /**
     * Retorna um campo como Bool.
     */
    public static function getBool(obj:Dynamic, field:String, fallback:Bool = false):Bool
    {
        var val = get(obj, field, fallback);
        if (Std.isOfType(val, Bool)) return val;
        return Std.string(val).toLowerCase() == "true";
    }

    /**
     * Retorna um campo como Array.
     */
    public static function getArray(obj:Dynamic, field:String):Array<Dynamic>
    {
        var val = get(obj, field, null);
        if (val == null) return [];
        return cast val;
    }

    // ==================== Color ====================

    /**
     * Converte uma string hexadecimal "#RRGGBB" para FlxColor.
     */
    public static function hexToColor(hex:String):flixel.util.FlxColor
    {
        if (hex == null || hex.length == 0)
            return flixel.util.FlxColor.WHITE;

        var clean = StringTools.replace(hex, "#", "");
        var value = Std.parseInt("0xFF" + clean);
        return value != null ? flixel.util.FlxColor.fromInt(value) : flixel.util.FlxColor.WHITE;
    }

    // ==================== Debug ====================

    /**
     * Imprime o conteúdo de um JSON formatado no trace.
     */
    public static function dump(path:String):Void
    {
        var data = load(path);
        if (data != null)
            trace('[JsonHelper] $path:\n' + Json.stringify(data, null, "  "));
    }

    /**
     * Verifica se um JSON possui todos os campos obrigatórios.
     */
    public static function validate(obj:Dynamic, requiredFields:Array<String>):Bool
    {
        if (obj == null) return false;
        for (field in requiredFields)
        {
            if (Reflect.field(obj, field) == null)
            {
                trace('[JsonHelper] Missing required field: $field');
                return false;
            }
        }
        return true;
    }
}
