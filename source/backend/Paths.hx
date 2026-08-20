package backend;

import openfl.utils.Assets;
import openfl.media.Sound;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;

using StringTools;

class Paths
{
    inline static var IMAGES:String = "images";
    inline static var SOUNDS:String = "sounds";
    inline static var MUSIC:String  = "music";
    inline static var DATA:String   = "data";
    inline static var FONTS:String  = "fonts";
    inline static var VIDEOS:String = "videos";

    #if html5
    inline static var SOUND_EXT:String = "mp3";
    #else
    inline static var SOUND_EXT:String = "ogg";
    #end

    static var currentLevel:String;

    public static function setCurrentLevel(name:String):Void
    {
        currentLevel = name;
    }

    static function getLibraryPath(file:String, library:String = "shared"):String
    {
        return library == "shared" ? 'assets/$file' : 'assets/$library/$file';
    }

    static function getPath(file:String, type:String, library:String):String
    {
        return getLibraryPath('$type/$file', library);
    }

    public static function exists(path:String):Bool
    {
        return Assets.exists(path);
    }

    public static function image(key:String, ?library:String):FlxGraphic
    {
        var path = getPath('$key.png', IMAGES, library ?? "shared");
        return FlxGraphic.fromAssetKey(path, false, null, false);
    }

    public static function sparrow(key:String, ?library:String):FlxAtlasFrames
    {
        var path = getPath(key, IMAGES, library ?? "shared");
        return FlxAtlasFrames.fromSparrow('$path.png', '$path.xml');
    }

    public static function packerAtlas(key:String, ?library:String):FlxAtlasFrames
    {
        var path = getPath(key, IMAGES, library ?? "shared");
        return FlxAtlasFrames.fromSpriteSheetPacker('$path.png', '$path.txt');
    }

    public static function sound(key:String, ?library:String):Sound
    {
        var path = getPath('$key.$SOUND_EXT', SOUNDS, library ?? "shared");
        return Assets.getSound(path);
    }

    public static function music(key:String, ?library:String):Sound
    {
        var path = getPath('$key.$SOUND_EXT', MUSIC, library ?? "shared");
        return Assets.getSound(path);
    }

    public static function font(key:String):String
    {
        return getLibraryPath('$FONTS/$key');
    }

    public static function json(key:String, ?library:String):Dynamic
    {
        var path = getPath('$key.json', DATA, library ?? "shared");
        return haxe.Json.parse(Assets.getText(path));
    }

    public static function txt(key:String, ?library:String):String
    {
        var path = getPath('$key.txt', DATA, library ?? "shared");
        return Assets.getText(path);
    }

    public static function video(key:String):String
    {
        return getLibraryPath('$VIDEOS/$key.mp4');
    }
}
