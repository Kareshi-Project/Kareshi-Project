package menus;

import flixel.FlxState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

class OptionsState extends FlxState
{
    static final OPTIONS:Array<String> = [
        "Master Volume",
        "Music Volume",
        "SFX Volume",
        "Fullscreen",
        "FPS Counter",
        "Back"
    ];

    var bg:FlxSprite;
    var overlay:FlxSprite;
    var titleText:FlxText;
    var optionTexts:Array<FlxText> = [];
    var arrowLeft:Array<FlxText>   = [];
    var arrowRight:Array<FlxText>  = [];
    var valueTexts:Array<FlxText>  = [];

    var curSelected:Int = 0;

    var masterVolume:Int = 10;
    var musicVolume:Int  = 10;
    var sfxVolume:Int    = 10;
    var fullscreen:Bool  = false;
    var showFPS:Bool     = false;

    var canInput:Bool = false;

    override public function create():Void
    {
        super.create();

        // Background da pasta options
        bg = new FlxSprite(0, 0);
        bg.loadGraphic("images/options/optionsBG.png");
        bg.setGraphicSize(FlxG.width, FlxG.height);
        bg.updateHitbox();
        bg.alpha = 0;
        add(bg);

        // Overlay escuro para melhorar legibilidade
        overlay = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGBFloat(0, 0, 0, 0.55));
        overlay.alpha = 0;
        add(overlay);

        // Título
        titleText = new FlxText(0, 40, FlxG.width, "Options");
        titleText.setFormat(null, 48, FlxColor.WHITE, "center");
        titleText.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 4);
        titleText.alpha = 0;
        add(titleText);

        // Linhas de opções
        for (i in 0...OPTIONS.length)
        {
            var yPos:Float = 160 + i * 72;

            var label = new FlxText(100, yPos, 400, OPTIONS[i]);
            label.setFormat(null, 28, FlxColor.WHITE, "left");
            label.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 2);
            label.alpha = 0;
            add(label);
            optionTexts.push(label);

            var left = new FlxText(520, yPos, 40, "<");
            left.setFormat(null, 28, FlxColor.YELLOW, "center");
            left.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 2);
            left.alpha = 0;
            add(left);
            arrowLeft.push(left);

            var val = new FlxText(560, yPos, 160, "");
            val.setFormat(null, 28, FlxColor.CYAN, "center");
            val.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 2);
            val.alpha = 0;
            add(val);
            valueTexts.push(val);

            var right = new FlxText(720, yPos, 40, ">");
            right.setFormat(null, 28, FlxColor.YELLOW, "center");
            right.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 2);
            right.alpha = 0;
            add(right);
            arrowRight.push(right);
        }

        refreshValues();
        updateSelection();

        // Fade in
        FlxTween.tween(bg,        {alpha: 1},    0.5, {ease: FlxEase.quartOut});
        FlxTween.tween(overlay,   {alpha: 1},    0.5, {ease: FlxEase.quartOut});
        FlxTween.tween(titleText, {alpha: 1},    0.5, {ease: FlxEase.quartOut});

        for (i in 0...OPTIONS.length)
        {
            var delay = 0.3 + i * 0.07;
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

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        if (!canInput) return;

        #if desktop
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
        #end

        #if mobile
        if (FlxG.touches.justStarted().length > 0)
            confirmSelection();
        #end
    }

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
    }

    function refreshValues():Void
    {
        valueTexts[0].text = masterVolume + " / 10";
        valueTexts[1].text = musicVolume  + " / 10";
        valueTexts[2].text = sfxVolume    + " / 10";
        valueTexts[3].text = fullscreen   ? "ON" : "OFF";
        valueTexts[4].text = showFPS      ? "ON" : "OFF";
    }

    function applyValues():Void
    {
        FlxG.sound.volume = masterVolume / 10;
        if (FlxG.sound.music != null)
            FlxG.sound.music.volume = musicVolume / 10;
        FlxG.fullscreen = fullscreen;
    }

    function goBack():Void
    {
        canInput = false;

        FlxTween.tween(bg,        {alpha: 0}, 0.4, {ease: FlxEase.quartIn});
        FlxTween.tween(overlay,   {alpha: 0}, 0.4, {ease: FlxEase.quartIn});
        FlxTween.tween(titleText, {alpha: 0}, 0.4, {ease: FlxEase.quartIn});

        for (i in 0...OPTIONS.length)
        {
            FlxTween.tween(optionTexts[i], {alpha: 0}, 0.3, {ease: FlxEase.quartIn, startDelay: i * 0.04});
            FlxTween.tween(valueTexts[i],  {alpha: 0}, 0.3, {ease: FlxEase.quartIn, startDelay: i * 0.04});
            FlxTween.tween(arrowLeft[i],   {alpha: 0}, 0.3, {ease: FlxEase.quartIn, startDelay: i * 0.04});
            FlxTween.tween(arrowRight[i],  {alpha: 0}, 0.3, {
                ease: FlxEase.quartIn,
                startDelay: i * 0.04,
                onComplete: i == OPTIONS.length - 1 ? function(_) FlxG.switchState(new menus.TitleState()) : null
            });
        }
    }
}