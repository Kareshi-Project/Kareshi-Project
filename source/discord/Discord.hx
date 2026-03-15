package discord;

#if desktop
import hxdiscord_rpc.Discord as DiscordRPC;
import hxdiscord_rpc.Types;
import sys.thread.Thread;
#end

class Discord
{
    #if desktop

    static final CLIENT_ID:String = "SEU_CLIENT_ID_AQUI";

    static var initialized:Bool  = false;
    static var rpcThread:Thread  = null;

    // Dados do presence atual
    static var currentState:String   = "";
    static var currentDetails:String = "";
    static var startTimestamp:Float  = 0;

    // ==================== Init ====================

    public static function init():Void
    {
        if (initialized) return;

        var handlers = new DiscordEventHandlers();
        handlers.ready         = cpp.Function.fromStaticFunction(onReady);
        handlers.disconnected  = cpp.Function.fromStaticFunction(onDisconnected);
        handlers.errored       = cpp.Function.fromStaticFunction(onError);

        DiscordRPC.Initialize(CLIENT_ID, cpp.RawPointer.addressOf(handlers), 1, null);

        initialized    = true;
        startTimestamp = Date.now().getTime() / 1000;

        // Thread separada para callbacks do RPC
        rpcThread = Thread.create(function()
        {
            while (initialized)
            {
                DiscordRPC.RunCallbacks();
                Sys.sleep(2);
            }
        });

        setPresence("Starting...", "Loading game");

        trace("[Discord] RPC initialized.");
    }

    // ==================== Shutdown ====================

    public static function shutdown():Void
    {
        if (!initialized) return;

        initialized = false;
        DiscordRPC.Shutdown();
        trace("[Discord] RPC shutdown.");
    }

    // ==================== Presence ====================

    public static function setPresence(details:String, state:String = "", ?largeImageKey:String, ?largeImageText:String, ?smallImageKey:String, ?smallImageText:String):Void
    {
        if (!initialized) return;

        currentDetails = details;
        currentState   = state;

        var presence = new RichPresence();

        presence.details        = details;
        presence.state          = state;
        presence.startTimestamp = Std.int(startTimestamp);

        presence.largeImageKey  = largeImageKey  != null ? largeImageKey  : "game_logo";
        presence.largeImageText = largeImageText != null ? largeImageText : "Kareshi Project";
        presence.smallImageKey  = smallImageKey  != null ? smallImageKey  : "";
        presence.smallImageText = smallImageText != null ? smallImageText : "";

        DiscordRPC.UpdatePresence(cpp.RawConstPointer.addressOf(presence));
    }

    // ==================== Presets ====================

    public static function setInMainMenu():Void
    {
        setPresence(
            "In Main Menu",
            "Choosing an option",
            "game_logo",
            "Kareshi Project"
        );
    }

    public static function setInOptions():Void
    {
        setPresence(
            "In Options",
            "Configuring settings",
            "game_logo",
            "Kareshi Project"
        );
    }

    public static function setInCredits():Void
    {
        setPresence(
            "Reading Credits",
            "",
            "game_logo",
            "Kareshi Project"
        );
    }

    public static function setPlaying(stageName:String, lives:Int, score:Int):Void
    {
        setPresence(
            "Playing: " + stageName,
            "Lives: " + lives + "  |  Score: " + score,
            "gameplay",
            "In Battle",
            "life_icon",
            "Lives: " + lives
        );
    }

    public static function setGameOver(score:Int):Void
    {
        setPresence(
            "Game Over",
            "Final Score: " + score,
            "game_logo",
            "Kareshi Project"
        );
    }

    public static function setStageClear(score:Int):Void
    {
        setPresence(
            "Stage Clear!",
            "Score: " + score,
            "game_logo",
            "Kareshi Project"
        );
    }

    // ==================== Callbacks ====================

    static function onReady(request:cpp.RawConstPointer<DiscordUser>):Void
    {
        trace("[Discord] Connected as: " + request[0].username);
    }

    static function onDisconnected(errorCode:Int, message:cpp.ConstCharStar):Void
    {
        trace("[Discord] Disconnected (" + errorCode + "): " + message);
    }

    static function onError(errorCode:Int, message:cpp.ConstCharStar):Void
    {
        trace("[Discord] Error (" + errorCode + "): " + message);
    }

    #end
}
