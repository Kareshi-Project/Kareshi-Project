package menus;

import flixel.FlxState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

class TitleState extends FlxState
{
    var bg:FlxSprite;
    var pressStartText:FlxText;

    var blinkTimer:Float = 0;
    var canStart:Bool    = false;

    override public function create():Void
    {
        super.create();

        // Background
        bg = new FlxSprite(0, 0);
        bg.loadGraphic("images/titleBG.png");
        bg.setGraphicSize(FlxG.width, FlxG.height);
        bg.updateHitbox();
        add(bg);

        // Press Start
        pressStartText = new FlxText(0, FlxG.height - 100, FlxG.width, "Press ENTER to Start");
        pressStartText.setFormat(null, 24, FlxColor.WHITE, "center");
        pressStartText.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 2);
        pressStartText.alpha = 0;
        add(pressStartText);

        // Fade in do press start
        FlxTween.tween(pressStartText, {alpha: 1}, 1.0, {
            ease: FlxEase.quartOut,
            startDelay: 0.5,
            onComplete: function(_) canStart = true
        });
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        if (canStart)
        {
            blinkTimer += elapsed;
            if (blinkTimer >= 0.5)
            {
                blinkTimer = 0;
                pressStartText.visible = !pressStartText.visible;
            }
        }

        #if desktop
        if (canStart && FlxG.keys.justPressed.ENTER)
            startGame();
        #end

        #if mobile
        if (canStart && FlxG.touches.justStarted().length > 0)
            startGame();
        #end
    }

    function startGame():Void
    {
        canStart = false;
        pressStartText.visible = true;

        FlxTween.tween(bg, {alpha: 0}, 0.6, {ease: FlxEase.quartIn});
        FlxTween.tween(pressStartText, {alpha: 0}, 0.6, {
            ease: FlxEase.quartIn,
            onComplete: function(_) FlxG.switchState(new menus.MainMenuState())
        });
    }
}
