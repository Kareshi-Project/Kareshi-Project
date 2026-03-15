package backend.debug;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.group.FlxGroup;
import openfl.system.System;

class DebugDisplay extends FlxGroup
{
    // Textos
    var fpsText:FlxText;
    var memText:FlxText;
    var resText:FlxText;
    var stateText:FlxText;
    var bg:FlxSprite;

    // FPS tracking
    var fpsBuffer:Array<Float> = [];
    var fpsTimer:Float         = 0;
    static final FPS_SAMPLE:Int   = 30;
    static final UPDATE_RATE:Float = 0.1;

    // Visibilidade
    public var visible(default, set):Bool = true;

    // Cor base
    static final COLOR_GOOD:FlxColor    = FlxColor.fromRGB(100, 255, 120);
    static final COLOR_MEDIUM:FlxColor  = FlxColor.fromRGB(255, 220, 60);
    static final COLOR_BAD:FlxColor     = FlxColor.fromRGB(255, 80,  80);
    static final COLOR_LABEL:FlxColor   = FlxColor.fromRGBFloat(0.6, 0.6, 0.8);

    public function new(x:Float = 4, y:Float = 4)
    {
        super();

        // Fundo semitransparente
        bg = new FlxSprite(x, y).makeGraphic(180, 80, FlxColor.fromRGBFloat(0, 0, 0, 0.55));
        bg.scrollFactor.set(0, 0);
        add(bg);

        // FPS
        fpsText = makeText(x + 6, y + 4, "FPS: --");
        add(fpsText);

        // Memória
        memText = makeText(x + 6, y + 20, "MEM: --");
        add(memText);

        // Resolução
        resText = makeText(x + 6, y + 36, "RES: --");
        add(resText);

        // State atual
        stateText = makeText(x + 6, y + 52, "STATE: --");
        add(stateText);

        setScrollFactor(0, 0);
    }

    function makeText(x:Float, y:Float, str:String):FlxText
    {
        var t = new FlxText(x, y, 170, str);
        t.setFormat(null, 12, FlxColor.WHITE, "left");
        t.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 1);
        t.scrollFactor.set(0, 0);
        return t;
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        if (!visible) return;

        // Coleta amostras de FPS
        fpsBuffer.push(1 / elapsed);
        if (fpsBuffer.length > FPS_SAMPLE)
            fpsBuffer.shift();

        fpsTimer += elapsed;
        if (fpsTimer >= UPDATE_RATE)
        {
            fpsTimer = 0;
            refresh();
        }
    }

    function refresh():Void
    {
        // FPS médio
        var sum:Float = 0;
        for (f in fpsBuffer) sum += f;
        var fps = Math.round(sum / fpsBuffer.length);

        fpsText.text  = "FPS: " + fps + " / " + FlxG.drawFramerate;
        fpsText.color = fpsColor(fps);

        // Memória (MB)
        var mem = Math.round(System.totalMemory / 1024 / 1024 * 10) / 10;
        memText.text  = "MEM: " + mem + " MB";
        memText.color = memColor(mem);

        // Resolução
        resText.text  = "RES: " + FlxG.width + "x" + FlxG.height;
        resText.color = COLOR_LABEL;

        // State atual
        var stateName = Type.getClassName(Type.getClass(FlxG.state));
        var parts     = stateName.split(".");
        stateText.text  = "STATE: " + parts[parts.length - 1];
        stateText.color = COLOR_LABEL;
    }

    function fpsColor(fps:Int):FlxColor
    {
        if (fps >= 55) return COLOR_GOOD;
        if (fps >= 30) return COLOR_MEDIUM;
        return COLOR_BAD;
    }

    function memColor(mb:Float):FlxColor
    {
        if (mb < 100)  return COLOR_GOOD;
        if (mb < 200)  return COLOR_MEDIUM;
        return COLOR_BAD;
    }

    // ==================== Toggle ====================

    public function toggle():Void
    {
        visible = !visible;
    }

    function set_visible(v:Bool):Bool
    {
        visible = v;
        for (member in members)
            if (member != null) member.visible = v;
        return v;
    }

    // ==================== Helpers ====================

    /** Adiciona o DebugDisplay ao state atual e retorna a instância */
    public static function attach():DebugDisplay
    {
        var dd = new DebugDisplay();
        FlxG.state.add(dd);
        return dd;
    }
}
