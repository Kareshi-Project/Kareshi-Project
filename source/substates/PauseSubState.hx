package substates;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.input.touch.FlxTouch;

class PauseSubState extends FlxSubState
{
    static final OPTIONS:Array<String> = [
        "Resume",
        "Options",
        "Main Menu",
        "Quit"
    ];

    var bg:FlxSprite;
    var overlay:FlxSprite;
    var titleText:FlxText;
    var optionTexts:Array<FlxText> = [];
    var cursor:FlxSprite;
    var resumeHint:FlxText;

    var curSelected:Int = 0;
    var canInput:Bool   = false;

    // ==================== Mobile Touch ====================
    var touchStartX:Float = 0;
    var touchStartY:Float = 0;
    var touchMoved:Bool   = false;
    static final SWIPE_THRESHOLD:Float = 40;
    static final TAP_THRESHOLD:Float   = 10;

    public function new()
    {
        super(FlxColor.TRANSPARENT);
    }

    // ==================== Create ====================

    override public function create():Void
    {
        super.create();

        // Fundo escuro semitransparente sobre o jogo
        bg = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGBFloat(0, 0, 0, 0));
        bg.scrollFactor.set(0, 0);
        add(bg);

        // Painel central
        var panelW:Int  = 400;
        var panelH:Int  = 360;
        var panelX:Float = (FlxG.width  - panelW) / 2;
        var panelY:Float = (FlxG.height - panelH) / 2;

        overlay = new FlxSprite(panelX, panelY).makeGraphic(panelW, panelH, FlxColor.fromRGB(10, 10, 25));
        overlay.scrollFactor.set(0, 0);
        overlay.alpha = 0;
        add(overlay);

        // Borda do painel
        var borderTop    = new FlxSprite(panelX, panelY).makeGraphic(panelW, 2, FlxColor.fromRGB(80, 80, 160));
        var borderBottom = new FlxSprite(panelX, panelY + panelH - 2).makeGraphic(panelW, 2, FlxColor.fromRGB(80, 80, 160));
        var borderLeft   = new FlxSprite(panelX, panelY).makeGraphic(2, panelH, FlxColor.fromRGB(80, 80, 160));
        var borderRight  = new FlxSprite(panelX + panelW - 2, panelY).makeGraphic(2, panelH, FlxColor.fromRGB(80, 80, 160));
        for (b in [borderTop, borderBottom, borderLeft, borderRight])
        {
            b.scrollFactor.set(0, 0);
            b.alpha = 0;
            add(b);
        }

        // Título
        titleText = new FlxText(panelX, panelY + 24, panelW, "PAUSED");
        titleText.setFormat(null, 42, FlxColor.WHITE, "center");
        titleText.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 4);
        titleText.scrollFactor.set(0, 0);
        titleText.alpha = 0;
        add(titleText);

        // Separador
        var separator = new FlxSprite(panelX + 20, panelY + 80).makeGraphic(panelW - 40, 2, FlxColor.fromRGBFloat(1, 1, 1, 0.2));
        separator.scrollFactor.set(0, 0);
        separator.alpha = 0;
        add(separator);

        // Cursor
        cursor = new FlxSprite(0, 0).makeGraphic(8, 32, FlxColor.YELLOW);
        cursor.scrollFactor.set(0, 0);
        cursor.alpha = 0;
        add(cursor);

        // Itens do menu
        for (i in 0...OPTIONS.length)
        {
            var item = new FlxText(panelX, panelY + 100 + i * 58, panelW, OPTIONS[i]);
            item.setFormat(null, 30, FlxColor.WHITE, "center");
            item.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 2);
            item.scrollFactor.set(0, 0);
            item.alpha = 0;
            add(item);
            optionTexts.push(item);
        }

        // Hint
        resumeHint = new FlxText(0, FlxG.height - 30, FlxG.width, "");
        resumeHint.setFormat(null, 16, FlxColor.fromRGBFloat(1, 1, 1, 0.5), "center");
        resumeHint.scrollFactor.set(0, 0);
        resumeHint.alpha = 0;
        add(resumeHint);

        #if desktop
        resumeHint.text = "ESC / P to Resume";
        #end
        #if mobile
        resumeHint.text = "Tap Resume to continue";
        #end

        updateSelection();

        // Discord
        #if desktop
        discord.Discord.setPresence("Paused", "Taking a break");
        #end

        // Fade in
        FlxTween.tween(bg, {alpha: 0.6}, 0.3, {ease: FlxEase.quartOut});
        FlxTween.tween(overlay, {alpha: 1}, 0.3, {ease: FlxEase.quartOut});
        FlxTween.tween(titleText, {alpha: 1}, 0.3, {ease: FlxEase.quartOut, startDelay: 0.1});
        FlxTween.tween(separator, {alpha: 1}, 0.3, {ease: FlxEase.quartOut, startDelay: 0.15});
        FlxTween.tween(cursor,    {alpha: 1}, 0.3, {ease: FlxEase.quartOut, startDelay: 0.2});
        FlxTween.tween(resumeHint,{alpha: 1}, 0.3, {ease: FlxEase.quartOut, startDelay: 0.2});

        for (b in [borderTop, borderBottom, borderLeft, borderRight])
            FlxTween.tween(b, {alpha: 1}, 0.3, {ease: FlxEase.quartOut, startDelay: 0.05});

        for (i in 0...OPTIONS.length)
        {
            FlxTween.tween(optionTexts[i], {alpha: 1}, 0.3, {
                ease: FlxEase.quartOut,
                startDelay: 0.15 + i * 0.06,
                onComplete: i == OPTIONS.length - 1 ? function(_) canInput = true : null
            });
        }
    }

    // ==================== Update ====================

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        if (!canInput) return;

        cursor.alpha = 0.5 + Math.sin(haxe.Timer.stamp() * 6) * 0.5;

        #if desktop
        handleKeyboard();
        #end

        #if mobile
        handleTouch();
        #end
    }

    // ==================== Keyboard ====================

    #if desktop
    function handleKeyboard():Void
    {
        if (FlxG.keys.justPressed.UP)
            changeSelection(-1);
        else if (FlxG.keys.justPressed.DOWN)
            changeSelection(1);
        else if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.Z)
            confirmSelection();
        else if (FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.P)
            resumeGame();
    }
    #end

    // ==================== Touch ====================

    #if mobile
    function handleTouch():Void
    {
        for (touch in FlxG.touches.justStarted())
        {
            touchStartX = touch.screenX;
            touchStartY = touch.screenY;
            touchMoved  = false;
        }

        for (touch in FlxG.touches.list)
        {
            var dy = touch.screenY - touchStartY;
            if (!touchMoved && Math.abs(dy) > SWIPE_THRESHOLD)
            {
                touchMoved = true;
                changeSelection(dy > 0 ? 1 : -1);
                touchStartY = touch.screenY;
            }
        }

        for (touch in FlxG.touches.justReleased())
        {
            var dx = Math.abs(touch.screenX - touchStartX);
            var dy = Math.abs(touch.screenY - touchStartY);

            if (dx < TAP_THRESHOLD && dy < TAP_THRESHOLD)
            {
                for (i in 0...optionTexts.length)
                {
                    if (optionTexts[i].overlapsPoint(touch.getWorldPosition()))
                    {
                        if (curSelected == i)
                            confirmSelection();
                        else
                        {
                            curSelected = i;
                            updateSelection();
                        }
                        break;
                    }
                }
            }
        }
    }
    #end

    // ==================== Lógica ====================

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
            optionTexts[i].size  = isSelected ? 32 : 30;
        }

        var sel = optionTexts[curSelected];
        var textWidth:Float  = 400;
        var centerX:Float    = (FlxG.width - textWidth) / 2;
        cursor.x = centerX - 24;
        cursor.y = sel.y + (sel.height - cursor.height) / 2;
    }

    function confirmSelection():Void
    {
        switch (curSelected)
        {
            case 0: resumeGame();
            case 1: openOptions();
            case 2: goToMainMenu();
            case 3: quitGame();
        }
    }

    // ==================== Ações ====================

    function resumeGame():Void
    {
        canInput = false;

        #if desktop
        discord.Discord.setPlaying("Stage 1", 3, 0);
        #end

        FlxTween.tween(bg,        {alpha: 0}, 0.3, {ease: FlxEase.quartIn});
        FlxTween.tween(overlay,   {alpha: 0}, 0.3, {ease: FlxEase.quartIn});
        FlxTween.tween(titleText, {alpha: 0}, 0.3, {ease: FlxEase.quartIn});
        FlxTween.tween(cursor,    {alpha: 0}, 0.2, {ease: FlxEase.quartIn});

        for (i in 0...OPTIONS.length)
        {
            FlxTween.tween(optionTexts[i], {alpha: 0}, 0.2, {
                ease: FlxEase.quartIn,
                startDelay: i * 0.03,
                onComplete: i == OPTIONS.length - 1 ? function(_) close() : null
            });
        }
    }

    function openOptions():Void
    {
        canInput = false;
        FlxTween.tween(bg, {alpha: 0}, 0.3, {
            ease: FlxEase.quartIn,
            onComplete: function(_)
            {
                close();
                FlxG.switchState(new menus.OptionsState());
            }
        });
    }

    function goToMainMenu():Void
    {
        canInput = false;

        #if desktop
        discord.Discord.setInMainMenu();
        #end

        FlxTween.tween(bg, {alpha: 0}, 0.4, {
            ease: FlxEase.quartIn,
            onComplete: function(_)
            {
                close();
                FlxG.switchState(new menus.MainMenuState());
            }
        });
    }

    function quitGame():Void
    {
        canInput = false;

        #if desktop
        discord.Discord.shutdown();
        #end

        FlxTween.tween(bg, {alpha: 0}, 0.3, {
            ease: FlxEase.quartIn,
            onComplete: function(_) Sys.exit(0)
        });
    }
}
