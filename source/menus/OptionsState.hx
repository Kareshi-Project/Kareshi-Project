package menus;

import flixel.FlxState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
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
    var hintText:FlxText;

    var curSelected:Int = 0;
    var canInput:Bool   = false;

    // ==================== Valores ====================

    var masterVolume:Int = 10;
    var musicVolume:Int  = 10;
    var sfxVolume:Int    = 10;
    var fullscreen:Bool  = false;
    var showFPS:Bool     = false;

    #if desktop
    var discordRPC:Bool  = true;
    #end

    // ==================== Debug ====================

    #if debug
    var debugDisplay:DebugDisplay;
    #end

    // ==================== Mobile Touch ====================

    var touchStartX:Float  = 0;
    var touchStartY:Float  = 0;
    var touchMoved:Bool    = false;
    var lastSwipeTime:Float = 0;
    static final SWIPE_THRESHOLD:Float  = 35;
    static final TAP_THRESHOLD:Float    = 12;
    static final SWIPE_COOLDOWN:Float   = 0.18;

    // ==================== Input cooldown ====================

    var inputCooldown:Float = 0;
    static final INPUT_COOLDOWN:Float = 0.12;

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
        overlay = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGBFloat(0, 0, 0, 0.58));
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
        cursor = new FlxSprite(0, 0).makeGraphic(6, 34, FlxColor.YELLOW);
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

        // Hint
        hintText = new FlxText(0, FlxG.height - 28, FlxG.width, "");
        hintText.setFormat(null, 14, FlxColor.fromRGBFloat(1, 1, 1, 0.5), "center");
        hintText.alpha = 0;
        add(hintText);

        #if desktop
        hintText.text = "↑↓ Navigate   ←→ Change   Enter/Z Confirm   Esc/X Back   F2 Debug";
        #end
        #if mobile
        hintText.text = "Swipe ↑↓ to navigate   Swipe ←→ to change   Tap to confirm";
        #end

        refreshValues();
        updateSelection();

        // DebugDisplay no canto superior esquerdo (igual Main.hx)
        #if debug
        debugDisplay = new DebugDisplay(4, 4);
        add(debugDisplay);
        #end

        // Discord
        #if desktop
        discord.Discord.setInOptions();
        #end

        // Fade in
        FlxTween.tween(bg,        {alpha: 1}, 0.5, {ease: FlxEase.quartOut});
        FlxTween.tween(overlay,   {alpha: 1}, 0.5, {ease: FlxEase.quartOut});
        FlxTween.tween(titleText, {alpha: 1}, 0.5, {ease: FlxEase.quartOut});
        FlxTween.tween(separator, {alpha: 1}, 0.5, {ease: FlxEase.quartOut, startDelay: 0.1});
        FlxTween.tween(cursor,    {alpha: 1}, 0.4, {ease: FlxEase.quartOut, startDelay: 0.2});
        FlxTween.tween(hintText,  {alpha: 1}, 0.4, {ease: FlxEase.quartOut, startDelay: 0.3});

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

        inputCooldown -= elapsed;

        // Cursor pisca
        cursor.alpha = 0.5 + Math.sin(haxe.Timer.stamp() * 6) * 0.5;

        #if desktop
        handleKeyboard(elapsed);
        #end

        #if mobile
        handleTouch(elapsed);
        #end
    }

    // ==================== Keyboard ====================

    #if desktop
    function handleKeyboard(elapsed:Float):Void
    {
        // Navegação com cooldown para segurar tecla
        if (FlxG.keys.justPressed.UP || (FlxG.keys.pressed.UP && inputCooldown <= 0))
        {
            changeSelection(-1);
            inputCooldown = FlxG.keys.justPressed.UP ? 0 : INPUT_COOLDOWN;
        }
        else if (FlxG.keys.justPressed.DOWN || (FlxG.keys.pressed.DOWN && inputCooldown <= 0))
        {
            changeSelection(1);
            inputCooldown = FlxG.keys.justPressed.DOWN ? 0 : INPUT_COOLDOWN;
        }
        else if (FlxG.keys.justPressed.LEFT || (FlxG.keys.pressed.LEFT && inputCooldown <= 0))
        {
            changeValue(-1);
            inputCooldown = FlxG.keys.justPressed.LEFT ? 0 : INPUT_COOLDOWN;
        }
        else if (FlxG.keys.justPressed.RIGHT || (FlxG.keys.pressed.RIGHT && inputCooldown <= 0))
        {
            changeValue(1);
            inputCooldown = FlxG.keys.justPressed.RIGHT ? 0 : INPUT_COOLDOWN;
        }

        if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.Z)
            confirmSelection();

        if (FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.X)
            goBack();

        // Toggle DebugDisplay com F2
        #if debug
        if (FlxG.keys.justPressed.F2)
            debugDisplay.toggle();
        #end
    }
    #end

    // ==================== Touch ====================

    #if mobile
    function handleTouch(elapsed:Float):Void
    {
        lastSwipeTime -= elapsed;

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
                else if (Math.abs(dx) > SWIPE_THRESHOLD && Math.abs(dx) > Math.abs(dy))
                {
                    touchMoved    = true;
                    lastSwipeTime = SWIPE_COOLDOWN;
                    changeValue(dx > 0 ? 1 : -1);
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

                if (!tapped && curSelected < OPTIONS.length - 1)
                {
                    if (arrowLeft[curSelected].overlapsPoint(touch.getWorldPosition()))
                        changeValue(-1);
                    else if (arrowRight[curSelected].overlapsPoint(touch.getWorldPosition()))
                        changeValue(1);
                }
            }

            touchMoved = false;
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
        cursor.x = sel.x - 18;
        cursor.y = sel.y + (sel.height - cursor.height) / 2;
    }

    function refreshValues():Void
    {
        valueTexts[0].text  = masterVolume + " / 10";
        valueTexts[0].color = volumeColor(masterVolume);
        valueTexts[1].text  = musicVolume  + " / 10";
        valueTexts[1].color = volumeColor(musicVolume);
        valueTexts[2].text  = sfxVolume    + " / 10";
        valueTexts[2].color = volumeColor(sfxVolume);
        valueTexts[3].text  = fullscreen   ? "ON" : "OFF";
        valueTexts[3].color = fullscreen   ? FlxColor.fromRGB(100, 255, 120) : FlxColor.fromRGB(180, 180, 180);
        valueTexts[4].text  = showFPS      ? "ON" : "OFF";
        valueTexts[4].color = showFPS      ? FlxColor.fromRGB(100, 255, 120) : FlxColor.fromRGB(180, 180, 180);

        #if desktop
        valueTexts[5].text  = discordRPC   ? "ON" : "OFF";
        valueTexts[5].color = discordRPC
            ? FlxColor.fromRGB(114, 137, 218)
            : FlxColor.fromRGB(180, 180, 180);
        #end
    }

    function volumeColor(v:Int):FlxColor
    {
        if (v >= 8) return FlxColor.fromRGB(100, 255, 120);
        if (v >= 5) return FlxColor.CYAN;
        if (v >= 2) return FlxColor.YELLOW;
        return FlxColor.fromRGB(255, 80, 80);
    }

    function applyValues():Void
    {
        FlxG.sound.volume = masterVolume / 10;
        if (FlxG.sound.music != null)
            FlxG.sound.music.volume = musicVolume / 10;
        FlxG.fullscreen = fullscreen;

        #if debug
        debugDisplay.visible = showFPS;
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
        FlxTween.tween(hintText,  {alpha: 0}, 0.3, {ease: FlxEase.quartIn});

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