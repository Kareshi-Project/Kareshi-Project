package menus;

import flixel.FlxState;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.group.FlxGroup;

class CreditsState extends FlxState
{
    static final CREDITS:Array<Array<String>> = [
        ["Kareshi Project", ""],
        ["", ""],
        ["Development", ""],
        ["Lead Developer",   "Brenninho123"],
        ["", ""],
        ["Art & Design", ""],
        ["Character Art",    "Kareshi Project Team"],
        ["Background Art",   "Kareshi Project Team"],
        ["UI Design",        "Kareshi Project Team"],
        ["", ""],
        ["Music & Sound", ""],
        ["Composer",         "Kareshi Project Team"],
        ["Sound Effects",    "Kareshi Project Team"],
        ["", ""],
        ["Special Thanks", ""],
        ["HaxeFlixel Team",  "github.com/HaxeFlixel"],
        ["OpenFL Team",      "github.com/openfl"],
        ["Touhou Project",   "ZUN / Team Shanghai Alice"],
        ["", ""],
        ["Thank you for playing!", ""],
    ];

    var bg:FlxSprite;
    var overlay:FlxSprite;
    var titleText:FlxText;
    var backHint:FlxText;
    var scrollGroup:FlxGroup;

    var scrollSpeed:Float = 40;
    var canInput:Bool     = false;
    var totalHeight:Float = 0;
    var startY:Float      = 0;

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

        // Overlay
        overlay = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGBFloat(0, 0, 0, 0.65));
        overlay.alpha = 0;
        add(overlay);

        // Título fixo
        titleText = new FlxText(0, 20, FlxG.width, "Credits");
        titleText.setFormat(null, 48, FlxColor.WHITE, "center");
        titleText.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 4);
        titleText.alpha = 0;
        add(titleText);

        // Separador
        var separator = new FlxSprite(FlxG.width * 0.1, 80).makeGraphic(Std.int(FlxG.width * 0.8), 2, FlxColor.fromRGBFloat(1, 1, 1, 0.3));
        separator.alpha = 0;
        add(separator);

        // Hint
        backHint = new FlxText(0, FlxG.height - 40, FlxG.width, "Press ESCAPE / X to go back");
        backHint.setFormat(null, 18, FlxColor.fromRGBFloat(1, 1, 1, 0.6), "center");
        backHint.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 2);
        backHint.alpha = 0;
        add(backHint);

        // Scroll group
        scrollGroup = new FlxGroup();
        add(scrollGroup);

        startY = FlxG.height + 20;
        var lineHeight:Float = 48;
        var itemIndex:Int = 0;

        for (i in 0...CREDITS.length)
        {
            var role = CREDITS[i][0];
            var name = CREDITS[i][1];

            if (role == "" && name == "")
            {
                itemIndex++;
                continue;
            }

            var yPos:Float = startY + itemIndex * lineHeight;

            if (name == "" && role != "")
            {
                var header = new FlxText(0, yPos, FlxG.width, role);
                header.setFormat(null, 26, FlxColor.YELLOW, "center");
                header.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 3);
                scrollGroup.add(header);
            }
            else
            {
                var roleText = new FlxText(FlxG.width * 0.15, yPos, FlxG.width * 0.35, role);
                roleText.setFormat(null, 22, FlxColor.fromRGBFloat(0.7, 0.7, 0.7, 1), "right");
                roleText.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 2);
                scrollGroup.add(roleText);

                var dot = new FlxText(FlxG.width * 0.5 - 10, yPos, 20, "—");
                dot.setFormat(null, 22, FlxColor.fromRGBFloat(0.5, 0.5, 0.5, 1), "center");
                scrollGroup.add(dot);

                var nameText = new FlxText(FlxG.width * 0.52, yPos, FlxG.width * 0.35, name);
                nameText.setFormat(null, 22, FlxColor.WHITE, "left");
                nameText.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 2);
                scrollGroup.add(nameText);
            }

            itemIndex++;
            totalHeight = itemIndex * lineHeight;
        }

        // Fade in
        FlxTween.tween(bg,        {alpha: 1}, 0.5, {ease: FlxEase.quartOut});
        FlxTween.tween(overlay,   {alpha: 1}, 0.5, {ease: FlxEase.quartOut});
        FlxTween.tween(titleText, {alpha: 1}, 0.6, {ease: FlxEase.quartOut, startDelay: 0.2});
        FlxTween.tween(separator, {alpha: 1}, 0.6, {ease: FlxEase.quartOut, startDelay: 0.3});
        FlxTween.tween(backHint,  {alpha: 1}, 0.6, {
            ease: FlxEase.quartOut,
            startDelay: 0.4,
            onComplete: function(_) canInput = true
        });
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        if (!canInput) return;

        // Scroll automático
        scrollItems(-scrollSpeed * elapsed);

        // Pisca hint
        backHint.alpha = 0.4 + Math.sin(haxe.Timer.stamp() * 2) * 0.3;

        // Reinicia quando tudo passou
        var firstItem = getFirstItem();
        if (firstItem != null && firstItem.y < -(totalHeight))
            resetScroll();

        #if desktop
        if (FlxG.keys.pressed.DOWN)
            scrollItems(-scrollSpeed * elapsed * 2);
        else if (FlxG.keys.pressed.UP)
            scrollItems(scrollSpeed * elapsed * 2);

        if (FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.X)
            goBack();
        #end

        #if mobile
        if (FlxG.touches.justStarted().length > 0)
            goBack();
        #end
    }

    function scrollItems(amount:Float):Void
    {
        for (basic in scrollGroup.members)
        {
            var item = cast(basic, FlxObject);
            if (item != null)
                item.y += amount;
        }
    }

    function getFirstItem():FlxObject
    {
        for (basic in scrollGroup.members)
            if (basic != null)
                return cast(basic, FlxObject);
        return null;
    }

    function resetScroll():Void
    {
        for (basic in scrollGroup.members)
        {
            var item = cast(basic, FlxObject);
            if (item != null)
                item.y += totalHeight + FlxG.height;
        }
    }

    function goBack():Void
    {
        canInput = false;

        FlxTween.tween(bg,          {alpha: 0}, 0.4, {ease: FlxEase.quartIn});
        FlxTween.tween(overlay,     {alpha: 0}, 0.4, {ease: FlxEase.quartIn});
        FlxTween.tween(titleText,   {alpha: 0}, 0.4, {ease: FlxEase.quartIn});
        FlxTween.tween(backHint,    {alpha: 0}, 0.3, {ease: FlxEase.quartIn});
        FlxTween.tween(scrollGroup, {alpha: 0}, 0.4, {
            ease: FlxEase.quartIn,
            onComplete: function(_) FlxG.switchState(new menus.MainMenuState())
        });
    }
}