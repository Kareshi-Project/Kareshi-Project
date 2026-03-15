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

        FlxG.camera.bgColor = FlxColor.BLACK;

        titleText = new FlxText(0, 0, FlxG.width, "Kareshi Project");
        titleText.setFormat(null, 32, FlxColor.WHITE, "center");
        titleText.screenCenter();

        add(titleText);
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        #if desktop
        if (FlxG.keys.justPressed.R)
        {
            FlxG.resetState();
        }
        #end

        #if mobile
        if (FlxG.touches.justStarted().length > 0)
        {
            FlxG.resetState();
        }
        #end
    }
}