package;

import openfl.display.Sprite;
import openfl.events.Event;
import flixel.FlxG;
import flixel.FlxGame;
import menus.TitleState;
import backend.debug.DebugDisplay;
import scripting.HScript;

class Main extends Sprite
{
    // ==================== Game Config ====================

    static final GAME_WIDTH:Int  = 1280;
    static final GAME_HEIGHT:Int = 720;
    static final TARGET_FPS:Int  = 60;

    // ==================== State ====================

    var globalScript:HScript = null;
    var scriptReady:Bool     = false;

    #if debug
    var debugDisplay:DebugDisplay;
    var debugReady:Bool = false;
    #end

    // ==================== Constructor ====================

    public function new()
    {
        super();

        var game = new FlxGame(
            GAME_WIDTH,
            GAME_HEIGHT,
            TitleState,
            TARGET_FPS,
            TARGET_FPS,
            true  // skipSplash
        );
        addChild(game);

        // Aguarda o primeiro frame para que FlxG.state esteja pronto
        game.addEventListener(Event.ENTER_FRAME, onFirstFrame);

        // Shutdown limpo ao fechar a janela
        #if desktop
        stage.addEventListener(Event.DEACTIVATE, onDeactivate);
        #end
    }

    // ==================== First Frame ====================

    function onFirstFrame(_):Void
    {
        if (FlxG.state == null) return;

        // Remove o listener — só roda uma vez
        removeEventListener(Event.ENTER_FRAME, onFirstFrame);

        initGlobalScript();
        initDiscord();

        #if debug
        initDebugDisplay();
        #end

        // Listener de update para o script global
        addEventListener(Event.ENTER_FRAME, onUpdate);
    }

    // ==================== Global Script ====================

    function initGlobalScript():Void
    {
        globalScript = new HScript();

        globalScript.onError = function(msg)
        {
            trace('[Main] Script error: $msg');
        };

        globalScript.onTrace = function(msg)
        {
            trace('[Script] $msg');
        };

        // Expõe o FlxG para o script global
        globalScript.set("getScreenWidth",  function() return FlxG.width);
        globalScript.set("getScreenHeight", function() return FlxG.height);
        globalScript.set("getVersion",      function() return "0.0.2");
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
                trace("[Main] global.hscript loaded successfully.");
            }
            else
            {
                trace('[Main] global.hscript execute failed: ${result.error}');
            }
        }
        else
        {
            trace('[Main] Failed to load global.hscript: ${globalScript.lastError}');
        }
    }

    // ==================== Discord ====================

    function initDiscord():Void
    {
        #if desktop
        try
        {
            discord.Discord.init();
            trace("[Main] Discord RPC initialized.");
        }
        catch (e:Dynamic)
        {
            trace('[Main] Discord RPC failed to initialize: $e');
        }
        #end
    }

    // ==================== Debug Display ====================

    #if debug
    function initDebugDisplay():Void
    {
        if (FlxG.state != null && !debugReady)
        {
            debugDisplay = DebugDisplay.attach();
            debugReady   = true;
            trace("[Main] DebugDisplay attached.");
        }
    }
    #end

    // ==================== Update ====================

    function onUpdate(_):Void
    {
        // Tick do script global
        if (scriptReady && globalScript != null)
        {
            var elapsed = FlxG.elapsed;
            globalScript.onUpdate(elapsed);
        }

        // Toggle debug com F2 (desktop + debug)
        #if (debug && desktop)
        if (FlxG.keys != null && FlxG.keys.justPressed.F2 && debugDisplay != null)
            debugDisplay.toggle();
        #end
    }

    // ==================== Deactivate ====================

    #if desktop
    function onDeactivate(_):Void
    {
        trace("[Main] Window deactivated — shutting down.");

        // Chama onDestroy do script global
        if (scriptReady && globalScript != null)
            globalScript.onDestroy();

        // Desliga Discord RPC
        try
        {
            discord.Discord.shutdown();
        }
        catch (e:Dynamic)
        {
            trace('[Main] Discord shutdown error: $e');
        }
    }
    #end
}