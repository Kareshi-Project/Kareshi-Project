package menus;

import flixel.FlxState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import backend.Controls;
import backend.Controls.Action;
import backend.debug.DebugDisplay;

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
    var subText:FlxText;
    var optionTexts:Array<FlxText> = [];
    var cursor:FlxSprite;
    var hintText:FlxText;
    var versionText:FlxText;

    var curSelected:Int = 0;
    var canInput:Bool   = false;
    var controls:Controls;

    var inputCooldown:Float = 0;
    static final INPUT_COOLDOWN:Float = 0.14;

    var touchStartX:Float   = 0;
    var touchStartY:Float   = 0;
    var touchMoved:Bool     = false;
    var lastSwipeTime:Float = 0;
    static final SWIPE_THRESHOLD:Float = 35;
    static final TAP_THRESHOLD:Float   = 12;
    static final SWIPE_COOLDOWN:Float  = 0.18;

    #if debug
    var debugDisplay:DebugDisplay;
    #end

    override public function create():Void
    {
        super.create();

        controls = Controls.instance;

        // Background
        bg = new FlxSprite(0, 0);
        bg.loadGraphic("images/titleBG.png");
        bg.setGraphicSize(FlxG.width, FlxG.height);
        bg.updateHitbox();
        bg.alpha = 0;
        add(bg);

        // Overlay
        overlay = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGBFloat(0, 0, 0, 0.5));
        overlay.alpha = 0;
        add(overlay);

        // Logo
        logoText = new FlxText(0, 60, FlxG.width, "Kareshi Project");
        logoText.setFormat(null, 56, FlxColor.WHITE, "center");
        logoText.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 5);
        logoText.alpha = 0;
        add(logoText);

        // Subtítulo
        subText = new FlxText(0, 126, FlxG.width, "— Touhou Fangame —");
        subText.setFormat(null, 18, FlxColor.fromRGB(200, 200, 255), "center");
        subText.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 2);
        subText.alpha = 0;
        add(subText);

        // Separador
        var separator = new FlxSprite(FlxG.width * 0.3, 160).makeGraphic(Std.int(FlxG.width * 0.4), 1, FlxColor.fromRGBFloat(1, 1, 1, 0.3));
        separator.alpha = 0;
        add(separator);

        // Cursor
        cursor = new FlxSprite(0, 0).makeGraphic(6, 34, FlxColor.YELLOW);
        cursor.alpha = 0;
        add(cursor);

        // Itens do menu
        for (i in 0...OPTIONS.length)
        {
            var item = new FlxText(0, 240 + i * 80, FlxG.width, OPTIONS[i]);
            item.setFormat(null, 36, FlxColor.WHITE, "center");
            item.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 3);
            item.alpha = 0;
            add(item);
            optionTexts.push(item);
        }

        // Hint de controles
        hintText = new FlxText(0, FlxG.height - 28, FlxG.width, "");
        hintText.setFormat(null, 14, FlxColor.fromRGBFloat(1, 1, 1, 0.5), "center");
        hintText.alpha = 0;
        add(hintText);

        #if desktop
        hintText.text = "↑↓ Navigate   Enter/Z Confirm   Esc/X Quit";
        if (controls.isGamepadConnected())
            hintText.text = "D-Pad Navigate   A Confirm   B Back   " + controls.getGamepadName();
        #end
        #if mobile
        hintText.text = "Tap to select   Swipe to navigate";
        #end

        // Versão
        versionText = new FlxText(FlxG.width - 90, FlxG.height - 20, 86, "v0.0.2");
        versionText.setFormat(null, 12, FlxColor.fromRGBFloat(1, 1, 1, 0.3), "right");
        add(versionText);

        updateSelection();

        // DebugDisplay no canto superior esquerdo
        #if debug
        debugDisplay = new DebugDisplay(4, 4);
        add(debugDisplay);
        #end

        // Discord
        #if desktop
        discord.Discord.setInMainMenu();
        #end

        // Fade in
        FlxTween.tween(bg,        {alpha: 1}, 0.5, {ease: FlxEase.quartOut});
        FlxTween.tween(overlay,   {alpha: 1}, 0.5, {ease: FlxEase.quartOut});
        FlxTween.tween(logoText,  {alpha: 1}, 0.6, {ease: FlxEase.quartOut, startDelay: 0.1});
        FlxTween.tween(subText,   {alpha: 1}, 0.5, {ease: FlxEase.quartOut, startDelay: 0.2});
        FlxTween.tween(separator, {alpha: 1}, 0.5, {ease: FlxEase.quartOut, startDelay: 0.25});
        FlxTween.tween(cursor,    {alpha: 1}, 0.4, {ease: FlxEase.quartOut, startDelay: 0.3});
        FlxTween.tween(hintText,  {alpha: 1}, 0.4, {ease: FlxEase.quartOut, startDelay: 0.4});

        for (i in 0...OPTIONS.length)
        {
            FlxTween.tween(optionTexts[i], {alpha: 1}, 0.4, {
                ease: FlxEase.quartOut,
                startDelay: 0.25 + i * 0.08,
                onComplete: i == OPTIONS.length - 1 ? function(_) canInput = true : null
            });
        }
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        if (!canInput) return;

        inputCooldown -= elapsed;
        lastSwipeTime -= elapsed;

        cursor.alpha = 0.5 + Math.sin(haxe.Timer.stamp() * 5) * 0.5;

        #if desktop
        updateHint();
        handleKeyboardAndGamepad(elapsed);
        #end

        #if mobile
        handleTouch(elapsed);
        #end
    }

    // ==================== Hint ====================

    #if desktop
    function updateHint():Void
    {
        if (controls.isGamepadConnected())
            hintText.text = "D-Pad Navigate   A Confirm   B Back   " + controls.getGamepadName();
        else
            hintText.text = "↑↓ Navigate   Enter/Z Confirm   Esc/X Quit";
    }
    #end

    // ==================== Keyboard + Gamepad ====================

    #if desktop
    function handleKeyboardAndGamepad(elapsed:Float):Void
    {
        if (controls.justPressed(Action.UP) || (controls.pressed(Action.UP) && inputCooldown <= 0))
        {
            changeSelection(-1);
            inputCooldown = controls.justPressed(Action.UP) ? 0 : INPUT_COOLDOWN;
        }
        else if (controls.justPressed(Action.DOWN) || (controls.pressed(Action.DOWN) && inputCooldown <= 0))
        {
            changeSelection(1);
            inputCooldown = controls.justPressed(Action.DOWN) ? 0 : INPUT_COOLDOWN;
        }

        if (controls.justPressed(Action.CONFIRM))
            confirmSelection();

        if (controls.justPressed(Action.BACK))
            selectAndConfirm(OPTIONS.length - 1);

        if (controls.justPressed(Action.PAUSE))
            selectAndConfirm(OPTIONS.length - 1);

        #if debug
        if (FlxG.keys.justPressed.SEVEN)
            FlxG.switchState(new menus.debug.EditorState());

        if (FlxG.keys.justPressed.F2)
            debugDisplay.toggle();
        #end
    }
    #end

    // ==================== Touch ====================

    #if mobile
    function handleTouch(elapsed:Float):Void
    {
        for (touch in FlxG.touches.justStarted())
        {
            touchStartX = touch.screenX;
            touchStartY = touch.screenY;
            touchMoved  = false;
        }

        for (touch in FlxG.touches.list)
        {
            var dx = touch.screenX - touchStartX;
            var dy = touch.screenY - touchStartY;

            if (!touchMoved && lastSwipeTime <= 0)
            {
                if (Math.abs(dy) > SWIPE_THRESHOLD && Math.abs(dy) > Math.abs(dx))
                {
                    touchMoved    = true;
                    lastSwipeTime = SWIPE_COOLDOWN;
                    changeSelection(dy > 0 ? 1 : -1);
                    touchStartX = touch.screenX;
                    touchStartY = touch.screenY;
                }
            }
        }

        for (touch in FlxG.touches.justReleased())
        {
            var dx = Math.abs(touch.screenX - touchStartX);
            var dy = Math.abs(touch.screenY - touchStartY);

            if (dx < TAP_THRESHOLD && dy < TAP_THRESHOLD)
            {
                var tapped = false;
                for (i in 0...optionTexts.length)
                {
                    if (optionTexts[i].overlapsPoint(touch.getWorldPosition()))
                    {
                        tapped = true;
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
                if (!tapped) confirmSelection();
            }

            touchMoved = false;
        }
    }
    #end

    // ==================== Seleção ====================

    function changeSelection(dir:Int):Void
    {
        curSelected = (curSelected + dir + OPTIONS.length) % OPTIONS.length;
        updateSelection();
    }

    function selectAndConfirm(index:Int):Void
    {
        curSelected = index;
        updateSelection();
        confirmSelection();
    }

    function updateSelection():Void
    {
        for (i in 0...optionTexts.length)
        {
            var isSelected = i == curSelected;
            optionTexts[i].color = isSelected ? FlxColor.YELLOW : FlxColor.WHITE;
            optionTexts[i].size  = isSelected ? 40 : 36;
        }

        var sel           = optionTexts[curSelected];
        var approxTextW:Float = sel.text.length * sel.size * 0.55;
        var centerX:Float = (FlxG.width - approxTextW) / 2;

        cursor.x = centerX - 24;
        cursor.y = sel.y + (sel.height - cursor.height) / 2;
    }

    function confirmSelection():Void
    {
        canInput = false;

        FlxTween.tween(optionTexts[curSelected], {size: 44}, 0.07, {
            ease: FlxEase.quartOut,
            onComplete: function(_) transitionTo(curSelected)
        });
    }

    // ==================== Transição ====================

    function transitionTo(index:Int):Void
    {
        var fadeAll = function(onDone:Void -> Void)
        {
            FlxTween.tween(bg,       {alpha: 0}, 0.4, {ease: FlxEase.quartIn});
            FlxTween.tween(overlay,  {alpha: 0}, 0.4, {ease: FlxEase.quartIn});
            FlxTween.tween(logoText, {alpha: 0}, 0.4, {ease: FlxEase.quartIn});
            FlxTween.tween(subText,  {alpha: 0}, 0.3, {ease: FlxEase.quartIn});
            FlxTween.tween(cursor,   {alpha: 0}, 0.3, {ease: FlxEase.quartIn});
            FlxTween.tween(hintText, {alpha: 0}, 0.3, {ease: FlxEase.quartIn});

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
            case 0: fadeAll(function() FlxG.switchState(new play.PlayState()));
            case 1: fadeAll(function() FlxG.switchState(new menus.OptionsState()));
            case 2: fadeAll(function() FlxG.switchState(new menus.CreditsState()));
            case 3:
                #if desktop
                discord.Discord.shutdown();
                #end
                fadeAll(function() Sys.exit(0));
        }
    }
}