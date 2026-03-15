package;

import openfl.display.Sprite;
import openfl.events.Event;
import flixel.FlxG;
import flixel.FlxGame;
import menus.TitleState;
import backend.debug.DebugDisplay;
import discord.Discord;

class Main extends Sprite
{
    #if debug
    var debugDisplay:DebugDisplay;
    #end

    public function new()
    {
        super();

        var game = new FlxGame(1280, 720, TitleState, 60, 60, true);
        addChild(game);

        #if desktop
        Discord.init();
        stage.addEventListener(Event.DEACTIVATE, onDeactivate);
        #end

        #if debug
        game.addEventListener(Event.ENTER_FRAME, onEnterFrame);
        #end
    }

    #if desktop
    function onDeactivate(_):Void
    {
        Discord.shutdown();
    }
    #end

    #if debug
    function onEnterFrame(_):Void
    {
        if (FlxG.state != null && debugDisplay == null)
        {
            debugDisplay = DebugDisplay.attach();
        }
    }
    #end
}