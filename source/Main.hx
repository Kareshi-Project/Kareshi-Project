package;

import openfl.display.Sprite;
import flixel.FlxGame;
import play.PlayState;

class Main extends Sprite
{
    public function new()
    {
        super();

        var gameWidth:Int = 1280;
        var gameHeight:Int = 720;
        var zoom:Float = 1;
        var updateFPS:Int = 60;
        var drawFPS:Int = 60;

        var game = new FlxGame(
            gameWidth,
            gameHeight,
            PlayState,
            zoom,
            updateFPS,
            drawFPS,
            true,
            false
        );

        addChild(game);
    }
}