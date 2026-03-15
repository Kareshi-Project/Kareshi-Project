package menus;

import flixel.FlxState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

class MainMenuState extends FlxState
{
    static final OPTIONS:Array<String> = [
        "Play",
        "Options",
        "Credits",
        "Quit"
    ];

    var bg:FlxSprite;
    var overlay:FlxSprite;
    var logoText:FlxText;
    var optionTexts:Array<FlxText> = [];
    var cursor:FlxSprite;

    var curSelected:Int = 0;
    var canInput:Bool   = false;

    override public function create():Void
    {
        super.create();

        // Background
        bg = new FlxSprite(0, 0);
        bg.loadGraphic("images/titleBG.png");
        bg.setGraphicSize(FlxG.width, FlxG.height);
        bg.updateHitbox();
        bg.alpha = 0;
        add(bg);

        // Overlay escuro para legibilidade
        overlay = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGBFloat(0, 0, 0, 0.5));
        overlay.alpha = 0;
        add(overlay);

        // Logo / título
        logoText = new FlxText(0, 60, FlxG.width, "Kareshi Project");
        logoText.setFormat(null, 56, FlxColor.WHITE, "center");
        logoText.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 5);
        logoText.alpha = 0;
        add(logoText);

        // Cursor triangular
        cursor = new FlxSprite(0, 0).makeGraphic(14, 14, FlxColor.YELLOW);
        cursor.alpha = 0;
        add(cursor);

        // Itens do menu
        for (i in 0...OPTIONS.length)
        {
            var item = new FlxText(0, 260 + i * 80, FlxG.width, OPTIONS[i]);
            item.setFormat(null, 36, FlxColor.WHITE, "center");
            item.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 3);
            item.alpha = 0;
            add(item);
            optionTexts.push(item);
        }

        updateSelection();

        // Fade in
        FlxTween.tween(bg,      {alpha: 1}, 0.5, {ease: FlxEase.quartOut});
        FlxTween.tween(overlay, {alpha: 1}, 0.5, {ease: FlxEase.quartOut});
        FlxTween.tween(logoText, {alpha: 1}, 0.6, {ease: FlxEase.quartOut, startDelay: 0.2});
        FlxTween.tween(cursor,   {alpha: 1}, 0.4, {ease: FlxEase.quartOut, startDelay: 0.4});

        for (i in 0...OPTIONS.length)
        {
            FlxTween.tween(optionTexts[i], {alpha: 1}, 0.4, {
                ease: FlxEase.quartOut,
                startDelay: 0.3 + i * 0.08,
                onComplete: i == OPTIONS.length - 1 ? function(_) canInput = true : null
            });
        }
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        if (!canInput) return;

        // Cursor pisca suavemente
        cursor.alpha = 0.6 + Math.sin(haxe.Timer.stamp() * 6) * 0.4;

        #if desktop
        if (FlxG.keys.justPressed.UP)
            changeSelection(-1);
        else if (FlxG.keys.justPressed.DOWN)
            changeSelection(1);
        else if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.Z)
            confirmSelection();
        else if (FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.X)
            changeSelection(OPTIONS.length - 1); // pula para Quit
        #end

        #if mobile
        var touches = FlxG.touches.justStarted();
        if (touches.length > 0)
        {
            var touch = touches[0];
            for (i in 0...optionTexts.length)
            {
                if (optionTexts[i].overlapsPoint(touch.getWorldPosition()))
                {
                    curSelected = i;
                    updateSelection();
                    confirmSelection();
                    break;
                }
            }
        }
        #end
    }

    function changeSelection(dir:Int):Void
    {
        curSelected = (curSelected + dir + OPTIONS.length) % OPTIONS.length;
        updateSelection();
    }

    function updateSelection():Void
    {
        for (i in 0...optionTexts.length)
        {
            var isSelected = i == curSelected;
            optionTexts[i].color = isSelected ? FlxColor.YELLOW : FlxColor.WHITE;
            optionTexts[i].size  = isSelected ? 40 : 36;
        }

        // Posiciona o cursor à esquerda do item selecionado
        var selected = optionTexts[curSelected];
        var textWidth:Float = selected.width;
        var centerX:Float   = (FlxG.width - textWidth) / 2;
        cursor.x = centerX - 28;
        cursor.y = selected.y + (selected.height - cursor.height) / 2;
    }

    function confirmSelection():Void
    {
        canInput = false;

        FlxTween.tween(optionTexts[curSelected], {size: 44}, 0.08, {
            ease: FlxEase.quartOut,
            onComplete: function(_) transitionTo(curSelected)
        });
    }

    function transitionTo(index:Int):Void
    {
        var fadeAll = function(onDone:Void -> Void)
        {
            FlxTween.tween(bg,       {alpha: 0}, 0.4, {ease: FlxEase.quartIn});
            FlxTween.tween(overlay,  {alpha: 0}, 0.4, {ease: FlxEase.quartIn});
            FlxTween.tween(logoText, {alpha: 0}, 0.4, {ease: FlxEase.quartIn});
            FlxTween.tween(cursor,   {alpha: 0}, 0.3, {ease: FlxEase.quartIn});

            for (i in 0...OPTIONS.length)
            {
                FlxTween.tween(optionTexts[i], {alpha: 0}, 0.3, {
                    ease: FlxEase.quartIn,
                    startDelay: i * 0.04,
                    onComplete: i == OPTIONS.length - 1 ? function(_) onDone() : null
                });
            }
        };

        switch (index)
        {
            case 0: // Play
                fadeAll(function() FlxG.switchState(new play.PlayState()));

            case 1: // Options
                fadeAll(function() FlxG.switchState(new menus.OptionsState()));

            case 2: // Credits
                fadeAll(function() FlxG.switchState(new menus.CreditsState()));

            case 3: // Quit
                fadeAll(function() Sys.exit(0));
        }
    }
}
