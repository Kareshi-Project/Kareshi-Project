package menus;

import flixel.FlxState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.input.touch.FlxTouch;
import backend.debug.DebugDisplay;

class OptionsState extends FlxState
{
    // ==================== Opções ====================

    #if desktop
    static final OPTIONS:Array<String> = [
        "Master Volume",
        "Music Volume",
        "SFX Volume",
        "Fullscreen",
        "FPS Counter",
        "Discord RPC",
        "Back"
    ];
    #else
    static final OPTIONS:Array<String> = [
        "Master Volume",
        "Music Volume",
        "SFX Volume",
        "Fullscreen",
        "FPS Counter",
        "Back"
    ];
    #end

    var bg:FlxSprite;
    var overlay:FlxSprite;
    var titleText:FlxText;
    var optionTexts:Array<FlxText> = [];
    var arrowLeft:Array<FlxText>   = [];
    var arrowRight:Array<FlxText>  = [];
    var valueTexts:Array<FlxText>  = [];
    var cursor:FlxSprite;

    var curSelected:Int = 0;
    var canInput:Bool   = false;

    // ==================== Valores ====================

    var masterVolume:Int  = 10;
    var musicVolume:Int   = 10;
    var sfxVolume:Int     = 10;
    var fullscreen:Bool   = false;
    var showFPS:Bool      = false;

    #if desktop
    var discordRPC:Bool   = true;
    #end

    // ==================== Debug ====================

    #if debug
    var debugDisplay:DebugDisplay;
    #end

    // ==================== Mobile Touch ====================

    var touchStartX:Float = 0;
    var touchStartY:Float = 0;
    var touchMoved:Bool   = false;
    static final SWIPE_THRESHOLD:Float = 40;
    static final TAP_THRESHOLD:Float   = 10;

    // ==================== Create ====================

    override public function create():Void
    {
        super.create();

        // Background
        bg = new FlxSprite(0, 0);
        bg.loadGraphic("images/options/optionsBG.png");
        bg.setGraphicSize(FlxG.width, FlxG.height);
        bg.updateHitbox();
        bg.alpha = 0;
        add(bg);

        // Overlay
        overlay = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGBFloat(0, 0, 0, 0.55));
        overlay.alpha = 0;
        add(overlay);

        // Título
        titleText = new FlxText(0, 30, FlxG.width, "Options");
        titleText.setFormat(null, 48, FlxColor.WHITE, "center");
        titleText.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 4);
        titleText.alpha = 0;
        add(titleText);

        // Separador
        var separator = new FlxSprite(FlxG.width * 0.1, 90).makeGraphic(Std.int(FlxG.width * 0.8), 2, FlxColor.fromRGBFloat(1, 1, 1, 0.25));
        separator.alpha = 0;
        add(separator);

        // Cursor
        cursor = new FlxSprite(0, 0).makeGraphic(8, 36, FlxColor.YELLOW);
        cursor.alpha = 0;
        add(cursor);

        // Itens
        for (i in 0...OPTIONS.length)
        {
            var yPos:Float = 150 + i * 76;

            var label = new FlxText(120, yPos, 380, OPTIONS[i]);
            label.setFormat(null, 28, FlxColor.WHITE, "left");
            label.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 2);
            label.alpha = 0;
            add(label);
            optionTexts.push(label);

            var left = new FlxText(510, yPos, 40, "<");
            left.setFormat(null, 28, FlxColor.YELLOW, "center");
            left.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 2);
            left.alpha = 0;
            add(left);
            arrowLeft.push(left);

            var val = new FlxText(550, yPos, 180, "");
            val.setFormat(null, 28, FlxColor.CYAN, "center");
            val.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 2);
            val.alpha = 0;
            add(val);
            valueTexts.push(val);

            var right = new FlxText(730, yPos, 40, ">");
            right.setFormat(null, 28, FlxColor.YELLOW, "center");
            right.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 2);
            right.alpha = 0;
            add(right);
            arrowRight.push(right);
        }

        refreshValues();
        updateSelection();

        // Debug display
        #if debug
        debugDisplay = new DebugDisplay(FlxG.width - 188, 4);
        add(debugDisplay);
        #end

        // Discord presence
        #if desktop
        discord.Discord.setInOptions();
        #end

        // Fade in
        FlxTween.tween(bg,        {alpha: 1}, 0.5, {ease: FlxEase.quartOut});
        FlxTween.tween(overlay,   {alpha: 1}, 0.5, {ease: FlxEase.quartOut});
        FlxTween.tween(titleText, {alpha: 1}, 0.5, {ease: FlxEase.quartOut});
        FlxTween.tween(separator, {alpha: 1}, 0.5, {ease: FlxEase.quartOut, startDelay: 0.1});
        FlxTween.tween(cursor,    {alpha: 1}, 0.4, {ease: FlxEase.quartOut, startDelay: 0.2});

        for (i in 0...OPTIONS.length)
        {
            var delay = 0.2 + i * 0.06;
            FlxTween.tween(optionTexts[i], {alpha: 1}, 0.4, {ease: FlxEase.quartOut, startDelay: delay});
            FlxTween.tween(arrowLeft[i],   {alpha: 1}, 0.4, {ease: FlxEase.quartOut, startDelay: delay});
            FlxTween.tween(valueTexts[i],  {alpha: 1}, 0.4, {ease: FlxEase.quartOut, startDelay: delay});
            FlxTween.tween(arrowRight[i],  {alpha: 1}, 0.4, {
                ease: FlxEase.quartOut,
                startDelay: delay,
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
        else if (FlxG.keys.justPressed.LEFT)
            changeValue(-1);
        else if (FlxG.keys.justPressed.RIGHT)
            changeValue(1);
        else if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.Z)
            confirmSelection();
        else if (FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.X)
            goBack();

        // Toggle debug com F2
        #if debug
        if (FlxG.keys.justPressed.F2)
            debugDisplay.toggle();
        #end
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
            var dx = touch.screenX - touchStartX;
            var dy = touch.screenY - touchStartY;

            if (!touchMoved)
            {
                if (Math.abs(dy) > SWIPE_THRESHOLD)
                {
                    touchMoved = true;
                    changeSelection(dy > 0 ? 1 : -1);
                    touchStartY = touch.screenY;
                }
                else if (Math.abs(dx) > SWIPE_THRESHOLD)
                {
                    touchMoved = true;
                    changeValue(dx > 0 ? 1 : -1);
                    touchStartX = touch.screenX;
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

                if (!tapped)
                {
                    if (arrowLeft[curSelected].overlapsPoint(touch.getWorldPosition()))
                        changeValue(-1);
                    else if (arrowRight[curSelected].overlapsPoint(touch.getWorldPosition()))
                        changeValue(1);
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

    function changeValue(dir:Int):Void
    {
        switch (curSelected)
        {
            case 0: masterVolume = Std.int(Math.max(0, Math.min(10, masterVolume + dir)));
            case 1: musicVolume  = Std.int(Math.max(0, Math.min(10, musicVolume  + dir)));
            case 2: sfxVolume    = Std.int(Math.max(0, Math.min(10, sfxVolume    + dir)));
            case 3: fullscreen   = !fullscreen;
            case 4: showFPS      = !showFPS;
            #if desktop
            case 5: toggleDiscord();
            #end
            default:
        }
        applyValues();
        refreshValues();
    }

    function confirmSelection():Void
    {
        if (curSelected == OPTIONS.length - 1)
            goBack();
        else
            changeValue(1);
    }

    function updateSelection():Void
    {
        for (i in 0...optionTexts.length)
        {
            var isSelected = i == curSelected;
            optionTexts[i].color = isSelected ? FlxColor.YELLOW : FlxColor.WHITE;
            optionTexts[i].size  = isSelected ? 30 : 28;

            var showArrows = isSelected && i < OPTIONS.length - 1;
            arrowLeft[i].visible  = showArrows;
            arrowRight[i].visible = showArrows;
            valueTexts[i].visible = i < OPTIONS.length - 1;
        }

        var sel = optionTexts[curSelected];
        cursor.x = sel.x - 20;
        cursor.y = sel.y + (sel.height - cursor.height) / 2;
    }

    function refreshValues():Void
    {
        valueTexts[0].text = masterVolume + " / 10";
        valueTexts[1].text = musicVolume  + " / 10";
        valueTexts[2].text = sfxVolume    + " / 10";
        valueTexts[3].text = fullscreen   ? "ON" : "OFF";
        valueTexts[4].text = showFPS      ? "ON" : "OFF";

        #if desktop
        valueTexts[5].text  = discordRPC ? "ON" : "OFF";
        valueTexts[5].color = discordRPC
            ? FlxColor.fromRGB(114, 137, 218)  // cor do Discord
            : FlxColor.fromRGBFloat(0.5, 0.5, 0.5);
        #end
    }

    function applyValues():Void
    {
        FlxG.sound.volume = masterVolume / 10;
        if (FlxG.sound.music != null)
            FlxG.sound.music.volume = musicVolume / 10;
        FlxG.fullscreen = fullscreen;

        #if debug
        if (showFPS)
            debugDisplay.visible = true;
        else
            debugDisplay.visible = false;
        #end
    }

    // ==================== Discord ====================

    #if desktop
    function toggleDiscord():Void
    {
        discordRPC = !discordRPC;

        if (discordRPC)
        {
            discord.Discord.init();
            discord.Discord.setInOptions();
        }
        else
        {
            discord.Discord.shutdown();
        }
    }
    #end

    // ==================== Transição ====================

    function goBack():Void
    {
        canInput = false;

        FlxTween.tween(bg,        {alpha: 0}, 0.4, {ease: FlxEase.quartIn});
        FlxTween.tween(overlay,   {alpha: 0}, 0.4, {ease: FlxEase.quartIn});
        FlxTween.tween(titleText, {alpha: 0}, 0.4, {ease: FlxEase.quartIn});
        FlxTween.tween(cursor,    {alpha: 0}, 0.3, {ease: FlxEase.quartIn});

        for (i in 0...OPTIONS.length)
        {
            FlxTween.tween(optionTexts[i], {alpha: 0}, 0.3, {ease: FlxEase.quartIn, startDelay: i * 0.04});
            FlxTween.tween(valueTexts[i],  {alpha: 0}, 0.3, {ease: FlxEase.quartIn, startDelay: i * 0.04});
            FlxTween.tween(arrowLeft[i],   {alpha: 0}, 0.3, {ease: FlxEase.quartIn, startDelay: i * 0.04});
            FlxTween.tween(arrowRight[i],  {alpha: 0}, 0.3, {
                ease: FlxEase.quartIn,
                startDelay: i * 0.04,
                onComplete: i == OPTIONS.length - 1 ? function(_) FlxG.switchState(new menus.MainMenuState()) : null
            });
        }
    }
}