package;

import openfl.display.Sprite;
import flixel.FlxGame;
import play.PlayState;

class Main extends Sprite
{
    public function new()
    {
        super();

        var game = new FlxGame(1280, 720, PlayState);
        addChild(game);
    }
}