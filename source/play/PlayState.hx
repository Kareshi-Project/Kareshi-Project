package play;

import flixel.FlxState;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class PlayState extends FlxState
{
    var titleText:FlxText;

    override public function create():Void
    {
        super.create();

        // Fundo preto
        FlxG.camera.bgColor = FlxColor.BLACK;

        // Texto do jogo
        titleText = new FlxText(0, 0, FlxG.width, "Kareshi Project");
        titleText.setFormat(null, 32, FlxColor.WHITE, "center");
        titleText.screenCenter();

        add(titleText);
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        // Reinicia o state apertando R
        if (FlxG.keys.justPressed.R)
        {
            FlxG.resetState();
        }
    }
}
