package;

import openfl.display.Sprite;
import openfl.events.Event;
import flixel.FlxG;
import flixel.FlxGame;
import menus.TitleState;
import backend.debug.DebugDisplay;
import scripting.HScript;

#if desktop
import polymod.Polymod;
import polymod.Polymod.PolymodError;
import sys.FileSystem;
#end

class Main extends Sprite
{
    static final GAME_WIDTH:Int      = 1280;
    static final GAME_HEIGHT:Int     = 720;
    static final TARGET_FPS:Int      = 60;
    static final GAME_VERSION:String = "0.0.2";
    static final MOD_API:String      = "0.0.2";

    var globalScript:HScript = null;
    var scriptReady:Bool     = false;

    #if debug
    var debugDisplay:DebugDisplay;
    var debugReady:Bool = false;
    #end

    public function new()
    {
        super();

        #if desktop
        initPolymod();
        #end

        var game = new FlxGame(
            GAME_WIDTH,
            GAME_HEIGHT,
            TitleState,
            TARGET_FPS,
            TARGET_FPS,
            true
        );
        addChild(game);

        game.addEventListener(Event.ENTER_FRAME, onFirstFrame);

        #if desktop
        stage.addEventListener(Event.DEACTIVATE, onDeactivate);
        #end
    }

    #if desktop
    function initPolymod():Void
    {
        var modRoot = "mods";

        if (!FileSystem.exists(modRoot))
            FileSystem.createDirectory(modRoot);

        Polymod.init({
            modRoot: modRoot,
            dirs: getModDirectories(modRoot),
            framework: FLIXEL,
            apiVersionRule: MOD_API,
            errorCallback: onPolymodError
        });
    }

    function getModDirectories(root:String):Array<String>
    {
        var result:Array<String> = [];

        for (entry in FileSystem.readDirectory(root))
            if (FileSystem.isDirectory('$root/$entry'))
                result.push(entry);

        return result;
    }

    function onPolymodError(error:PolymodError):Void {}
    #end

    function onFirstFrame(_):Void
    {
        if (FlxG.state == null) return;

        removeEventListener(Event.ENTER_FRAME, onFirstFrame);

        initGlobalScript();
        initDiscord();

        #if debug
        initDebugDisplay();
        #end

        addEventListener(Event.ENTER_FRAME, onUpdate);
    }

    function initGlobalScript():Void
    {
        globalScript = new HScript();

        globalScript.onError = function(msg) {};

        globalScript.set("getScreenWidth",  function() return FlxG.width);
        globalScript.set("getScreenHeight", function() return FlxG.height);
        globalScript.set("getVersion",      function() return GAME_VERSION);
        globalScript.set("getBuildType",    function()
        {
            #if debug
            return "DEBUG";
            #else
            return "RELEASE";
            #end
        });

        if (globalScript.load("data/scripts/global.hscript"))
        {
            var result = globalScript.execute();

            if (result.success)
            {
                globalScript.onCreate();
                scriptReady = true;
            }
        }
    }

    function initDiscord():Void
    {
        #if desktop
        try
        {
            discord.Discord.init();
        }
        catch (e:Dynamic) {}
        #end
    }

    #if debug
    function initDebugDisplay():Void
    {
        if (FlxG.state != null && !debugReady)
        {
            debugDisplay = DebugDisplay.attach();
            debugReady   = true;
        }
    }
    #end

    function onUpdate(_):Void
    {
        if (scriptReady && globalScript != null)
            globalScript.onUpdate(FlxG.elapsed);

        #if (debug && desktop)
        if (FlxG.keys != null && FlxG.keys.justPressed.F2 && debugDisplay != null)
            debugDisplay.toggle();
        #end
    }

    #if desktop
    function onDeactivate(_):Void
    {
        if (scriptReady && globalScript != null)
            globalScript.onDestroy();

        try
        {
            discord.Discord.shutdown();
        }
        catch (e:Dynamic) {}
    }
    #end
}
