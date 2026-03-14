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
        var initialState = PlayState;
        var zoom:Float = -1;
        var framerate:Int = 60;
        var skipSplash:Bool = true;
        var startFullscreen:Bool = false;

        var game = new FlxGame(
            gameWidth,
            gameHeight,
            initialState,
            zoom,
            framerate,
            framerate,
            skipSplash,
            startFullscreen
        );

        addChild(game);
    }
}