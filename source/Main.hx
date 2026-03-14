package;

import openfl.display.Sprite;
import flixel.FlxGame;
import play.PlayState;

class Main extends Sprite
{
    public function new()
    {
        super();

        addChild(new FlxGame(
            1280, // width
            720,  // height
            PlayState,
            1,    // zoom
            60,   // updateFramerate (INT)
            60,   // drawFramerate (INT)
            true,
            false
        ));
    }
}