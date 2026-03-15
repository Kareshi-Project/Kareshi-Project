package;

import openfl.display.Sprite;
import flixel.FlxG;
import flixel.FlxGame;
import menus.TitleState;
import backend.debug.DebugDisplay;

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

        #if debug
        game.addEventListener(openfl.events.Event.ENTER_FRAME, onEnterFrame);
        #end
    }

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