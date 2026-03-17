package menus.debug;

import flixel.FlxState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import backend.debug.DebugDisplay;
import backend.Controls;
import backend.Controls.Action;

// ==================== Editor Types ====================

enum EditorType
{
    STAGE;
    CHARACTER;
    BULLET_PATTERN;
    DIALOGUE;
    ITEM;
}

// ==================== Editor Entry ====================

typedef EditorEntry =
{
    var label:String;
    var description:String;
    var type:EditorType;
    var icon:String;
    var color:FlxColor;
}

// ==================== EditorState ====================

class EditorState extends FlxState
{
    static final EDITORS:Array<EditorEntry> = [
        {
            label:       "Stage Editor",
            description: "Edit stages, waves, backgrounds and boss data",
            type:        STAGE,
            icon:        "🗺",
            color:       FlxColor.fromRGB(80, 160, 255)
        },
        {
            label:       "Character Editor",
            description: "Edit player characters, stats and shot types",
            type:        CHARACTER,
            icon:        "🎭",
            color:       FlxColor.fromRGB(255, 120, 180)
        },
        {
            label:       "Bullet Pattern Editor",
            description: "Create and preview bullet patterns visually",
            type:        BULLET_PATTERN,
            icon:        "✦",
            color:       FlxColor.fromRGB(255, 200, 60)
        },
        {
            label:       "Dialogue Editor",
            description: "Write and preview in-game dialogue sequences",
            type:        DIALOGUE,
            icon:        "💬",
            color:       FlxColor.fromRGB(120, 220, 160)
        },
        {
            label:       "Item Editor",
            description: "Configure item drops, values and appearances",
            type:        ITEM,
            icon:        "⭐",
            color:       FlxColor.fromRGB(200, 140, 255)
        }
    ];

    // UI
    var bg:FlxSprite;
    var titleText:FlxText;
    var subtitleText:FlxText;
    var buildText:FlxText;
    var cards:Array<FlxSprite>      = [];
    var cardLabels:Array<FlxText>   = [];
    var cardDescs:Array<FlxText>    = [];
    var cardIcons:Array<FlxText>    = [];
    var cardAccents:Array<FlxSprite> = [];
    var cursor:FlxSprite;
    var hintText:FlxText;
    var previewPanel:FlxSprite;
    var previewTitle:FlxText;
    var previewDesc:FlxText;
    var previewType:FlxText;

    var curSelected:Int  = 0;
    var canInput:Bool    = false;
    var controls:Controls;

    // Input
    var inputCooldown:Float  = 0;
    static final INPUT_COOLDOWN:Float = 0.13;

    // Mobile
    var touchStartX:Float   = 0;
    var touchStartY:Float   = 0;
    var touchMoved:Bool     = false;
    var lastSwipeTime:Float = 0;
    static final SWIPE_THRESHOLD:Float = 35;
    static final TAP_THRESHOLD:Float   = 12;
    static final SWIPE_COOLDOWN:Float  = 0.18;

    // Layout
    static final CARD_W:Int    = 220;
    static final CARD_H:Int    = 130;
    static final CARD_GAP:Int  = 16;
    static final CARD_START_X  = 24;
    static final CARD_START_Y  = 140;
    static final PREVIEW_X     = 490;
    static final PREVIEW_Y     = 140;
    static final PREVIEW_W     = 270;
    static final PREVIEW_H     = 380;

    #if debug
    var debugDisplay:DebugDisplay;
    #end

    // ==================== Create ====================

    override public function create():Void
    {
        super.create();

        controls = Controls.instance;
        FlxG.camera.bgColor = FlxColor.fromRGB(8, 8, 20);

        createBackground();
        createHeader();
        createCards();
        createPreviewPanel();
        createHints();

        updateSelection();

        #if debug
        debugDisplay = new DebugDisplay(4, 4);
        add(debugDisplay);
        #end

        fadeIn();
    }

    // ==================== Background ====================

    function createBackground():Void
    {
        // Fundo gradiente simulado
        bg = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(8, 8, 20));
        add(bg);

        // Grid decorativo
        var gridCol = FlxColor.fromRGBFloat(1, 1, 1, 0.03);
        var gridSize = 32;
        var cols = Std.int(FlxG.width  / gridSize) + 1;
        var rows = Std.int(FlxG.height / gridSize) + 1;

        for (c in 0...cols)
        {
            var line = new FlxSprite(c * gridSize, 0).makeGraphic(1, FlxG.height, gridCol);
            add(line);
        }
        for (r in 0...rows)
        {
            var line = new FlxSprite(0, r * gridSize).makeGraphic(FlxG.width, 1, gridCol);
            add(line);
        }

        // Barra de topo
        var topBar = new FlxSprite(0, 0).makeGraphic(FlxG.width, 100, FlxColor.fromRGB(12, 12, 30));
        add(topBar);

        var topLine = new FlxSprite(0, 100).makeGraphic(FlxG.width, 2, FlxColor.fromRGB(40, 40, 100));
        add(topLine);

        // Accent lateral esquerdo
        var accent = new FlxSprite(0, 0).makeGraphic(4, FlxG.height, FlxColor.fromRGB(80, 80, 200));
        add(accent);
    }

    // ==================== Header ====================

    function createHeader():Void
    {
        // Ícone debug
        var debugBadge = new FlxSprite(16, 12).makeGraphic(70, 24, FlxColor.fromRGB(255, 80, 80));
        add(debugBadge);

        var debugLabel = new FlxText(16, 14, 70, "DEBUG");
        debugLabel.setFormat(null, 12, FlxColor.WHITE, "center");
        debugLabel.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 1);
        add(debugLabel);

        // Título
        titleText = new FlxText(100, 10, FlxG.width - 120, "Editor Hub");
        titleText.setFormat(null, 40, FlxColor.WHITE, "left");
        titleText.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 3);
        titleText.alpha = 0;
        add(titleText);

        subtitleText = new FlxText(100, 56, FlxG.width - 120, "Kareshi Project — Development Tools");
        subtitleText.setFormat(null, 16, FlxColor.fromRGB(160, 160, 220), "left");
        subtitleText.alpha = 0;
        add(subtitleText);

        // Build info
        buildText = new FlxText(FlxG.width - 200, 80, 192, "Build: DEBUG  v0.0.1");
        buildText.setFormat(null, 11, FlxColor.fromRGBFloat(1, 1, 1, 0.3), "right");
        add(buildText);
    }

    // ==================== Cards ====================

    function createCards():Void
    {
        // Cursor
        cursor = new FlxSprite(0, 0).makeGraphic(CARD_W + 4, CARD_H + 4, FlxColor.TRANSPARENT);
        drawCursorBorder();
        cursor.alpha = 0;
        add(cursor);

        for (i in 0...EDITORS.length)
        {
            var entry = EDITORS[i];
            var col   = i % 2;
            var row   = Std.int(i / 2);
            var cx    = CARD_START_X + col * (CARD_W + CARD_GAP);
            var cy    = CARD_START_Y + row * (CARD_H + CARD_GAP);

            // Card base
            var card = new FlxSprite(cx, cy).makeGraphic(CARD_W, CARD_H, FlxColor.fromRGB(16, 16, 36));
            card.alpha = 0;
            add(card);
            cards.push(card);

            // Accent lateral colorido
            var accent = new FlxSprite(cx, cy).makeGraphic(4, CARD_H, entry.color);
            accent.alpha = 0;
            add(accent);
            cardAccents.push(accent);

            // Borda sutil
            var borderT = new FlxSprite(cx, cy).makeGraphic(CARD_W, 1, FlxColor.fromRGBFloat(1, 1, 1, 0.08));
            var borderB = new FlxSprite(cx, cy + CARD_H - 1).makeGraphic(CARD_W, 1, FlxColor.fromRGBFloat(1, 1, 1, 0.08));
            var borderR = new FlxSprite(cx + CARD_W - 1, cy).makeGraphic(1, CARD_H, FlxColor.fromRGBFloat(1, 1, 1, 0.08));
            add(borderT);
            add(borderB);
            add(borderR);

            // Ícone
            var icon = new FlxText(cx + 14, cy + 12, 40, entry.icon);
            icon.setFormat(null, 28, entry.color, "left");
            icon.alpha = 0;
            add(icon);
            cardIcons.push(icon);

            // Label
            var label = new FlxText(cx + 14, cy + 50, CARD_W - 20, entry.label);
            label.setFormat(null, 18, FlxColor.WHITE, "left");
            label.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 2);
            label.alpha = 0;
            add(label);
            cardLabels.push(label);

            // Descrição curta
            var desc = new FlxText(cx + 14, cy + 74, CARD_W - 20, entry.description);
            desc.setFormat(null, 11, FlxColor.fromRGBFloat(0.6, 0.6, 0.8, 1), "left");
            desc.alpha = 0;
            add(desc);
            cardDescs.push(desc);
        }
    }

    function drawCursorBorder():Void
    {
        var w = cursor.pixels.width;
        var h = cursor.pixels.height;
        var col = FlxColor.fromRGB(180, 180, 255);

        for (px in 0...w)
        {
            cursor.pixels.setPixel32(px, 0,     col);
            cursor.pixels.setPixel32(px, h - 1, col);
        }
        for (py in 0...h)
        {
            cursor.pixels.setPixel32(0,     py, col);
            cursor.pixels.setPixel32(w - 1, py, col);
        }
        cursor.dirty = true;
    }

    // ==================== Preview Panel ====================

    function createPreviewPanel():Void
    {
        previewPanel = new FlxSprite(PREVIEW_X, PREVIEW_Y).makeGraphic(PREVIEW_W, PREVIEW_H, FlxColor.fromRGB(12, 12, 30));
        previewPanel.alpha = 0;
        add(previewPanel);

        // Borda do painel
        var pBorderT = new FlxSprite(PREVIEW_X, PREVIEW_Y).makeGraphic(PREVIEW_W, 2, FlxColor.fromRGB(40, 40, 100));
        var pBorderB = new FlxSprite(PREVIEW_X, PREVIEW_Y + PREVIEW_H - 2).makeGraphic(PREVIEW_W, 2, FlxColor.fromRGB(40, 40, 100));
        var pBorderL = new FlxSprite(PREVIEW_X, PREVIEW_Y).makeGraphic(2, PREVIEW_H, FlxColor.fromRGB(40, 40, 100));
        var pBorderR = new FlxSprite(PREVIEW_X + PREVIEW_W - 2, PREVIEW_Y).makeGraphic(2, PREVIEW_H, FlxColor.fromRGB(40, 40, 100));
        for (b in [pBorderT, pBorderB, pBorderL, pBorderR])
        {
            b.alpha = 0;
            add(b);
        }

        var previewHeader = new FlxText(PREVIEW_X + 12, PREVIEW_Y + 10, PREVIEW_W - 24, "PREVIEW");
        previewHeader.setFormat(null, 11, FlxColor.fromRGB(120, 120, 180), "left");
        previewHeader.alpha = 0;
        add(previewHeader);

        var previewDivider = new FlxSprite(PREVIEW_X + 12, PREVIEW_Y + 28).makeGraphic(PREVIEW_W - 24, 1, FlxColor.fromRGB(30, 30, 70));
        previewDivider.alpha = 0;
        add(previewDivider);

        previewTitle = new FlxText(PREVIEW_X + 12, PREVIEW_Y + 40, PREVIEW_W - 24, "");
        previewTitle.setFormat(null, 22, FlxColor.WHITE, "left");
        previewTitle.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 2);
        previewTitle.alpha = 0;
        add(previewTitle);

        previewDesc = new FlxText(PREVIEW_X + 12, PREVIEW_Y + 72, PREVIEW_W - 24, "");
        previewDesc.setFormat(null, 13, FlxColor.fromRGB(180, 180, 220), "left");
        previewDesc.wordWrap = true;
        previewDesc.alpha = 0;
        add(previewDesc);

        previewType = new FlxText(PREVIEW_X + 12, PREVIEW_Y + PREVIEW_H - 40, PREVIEW_W - 24, "");
        previewType.setFormat(null, 12, FlxColor.fromRGBFloat(0.5, 0.5, 0.7, 1), "left");
        previewType.alpha = 0;
        add(previewType);

        // Adiciona os elementos do painel ao grupo para fade
        for (e in [previewHeader, previewDivider])
            FlxTween.tween(e, {alpha: 1}, 0.5, {ease: FlxEase.quartOut, startDelay: 0.5});
    }

    // ==================== Hints ====================

    function createHints():Void
    {
        hintText = new FlxText(0, FlxG.height - 26, FlxG.width, "");
        hintText.setFormat(null, 13, FlxColor.fromRGBFloat(1, 1, 1, 0.4), "center");
        hintText.alpha = 0;
        add(hintText);

        #if desktop
        hintText.text = "↑↓←→ Navigate   Enter/Z Open   Esc/X Back to Menu   F2 Debug";
        #end
        #if mobile
        hintText.text = "Swipe to navigate   Tap to open";
        #end

        // Separador do rodapé
        var footerLine = new FlxSprite(0, FlxG.height - 34).makeGraphic(FlxG.width, 1, FlxColor.fromRGB(30, 30, 70));
        add(footerLine);
    }

    // ==================== Fade In ====================

    function fadeIn():Void
    {
        FlxTween.tween(titleText,    {alpha: 1}, 0.5, {ease: FlxEase.quartOut, startDelay: 0.1});
        FlxTween.tween(subtitleText, {alpha: 1}, 0.4, {ease: FlxEase.quartOut, startDelay: 0.2});
        FlxTween.tween(cursor,       {alpha: 1}, 0.4, {ease: FlxEase.quartOut, startDelay: 0.3});
        FlxTween.tween(previewPanel, {alpha: 1}, 0.5, {ease: FlxEase.quartOut, startDelay: 0.3});
        FlxTween.tween(previewTitle, {alpha: 1}, 0.5, {ease: FlxEase.quartOut, startDelay: 0.4});
        FlxTween.tween(previewDesc,  {alpha: 1}, 0.5, {ease: FlxEase.quartOut, startDelay: 0.45});
        FlxTween.tween(previewType,  {alpha: 1}, 0.5, {ease: FlxEase.quartOut, startDelay: 0.5});
        FlxTween.tween(hintText,     {alpha: 1}, 0.4, {ease: FlxEase.quartOut, startDelay: 0.4});

        for (i in 0...EDITORS.length)
        {
            var delay = 0.2 + i * 0.07;
            FlxTween.tween(cards[i],       {alpha: 1}, 0.4, {ease: FlxEase.quartOut, startDelay: delay});
            FlxTween.tween(cardAccents[i], {alpha: 1}, 0.4, {ease: FlxEase.quartOut, startDelay: delay});
            FlxTween.tween(cardIcons[i],   {alpha: 1}, 0.4, {ease: FlxEase.quartOut, startDelay: delay});
            FlxTween.tween(cardLabels[i],  {alpha: 1}, 0.4, {ease: FlxEase.quartOut, startDelay: delay});
            FlxTween.tween(cardDescs[i],   {alpha: 1}, 0.4, {
                ease: FlxEase.quartOut,
                startDelay: delay,
                onComplete: i == EDITORS.length - 1 ? function(_) canInput = true : null
            });
        }
    }

    // ==================== Update ====================

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        if (!canInput) return;

        inputCooldown  -= elapsed;
        lastSwipeTime  -= elapsed;

        cursor.alpha = 0.6 + Math.sin(haxe.Timer.stamp() * 4) * 0.4;

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
        var moved = false;

        if (controls.justPressed(Action.UP) || (controls.pressed(Action.UP) && inputCooldown <= 0))
        {
            moved = true;
            changeSelection(-2); // move uma linha acima (grid 2 colunas)
            inputCooldown = controls.justPressed(Action.UP) ? 0 : INPUT_COOLDOWN;
        }
        else if (controls.justPressed(Action.DOWN) || (controls.pressed(Action.DOWN) && inputCooldown <= 0))
        {
            moved = true;
            changeSelection(2); // move uma linha abaixo
            inputCooldown = controls.justPressed(Action.DOWN) ? 0 : INPUT_COOLDOWN;
        }
        else if (controls.justPressed(Action.LEFT) || (controls.pressed(Action.LEFT) && inputCooldown <= 0))
        {
            moved = true;
            changeSelection(-1);
            inputCooldown = controls.justPressed(Action.LEFT) ? 0 : INPUT_COOLDOWN;
        }
        else if (controls.justPressed(Action.RIGHT) || (controls.pressed(Action.RIGHT) && inputCooldown <= 0))
        {
            moved = true;
            changeSelection(1);
            inputCooldown = controls.justPressed(Action.RIGHT) ? 0 : INPUT_COOLDOWN;
        }

        if (controls.justPressed(Action.CONFIRM))
            openEditor(curSelected);

        if (controls.justPressed(Action.BACK) || controls.justPressed(Action.PAUSE))
            goBack();

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
                    changeSelection(dy > 0 ? 2 : -2);
                    touchStartX = touch.screenX;
                    touchStartY = touch.screenY;
                }
                else if (Math.abs(dx) > SWIPE_THRESHOLD && Math.abs(dx) > Math.abs(dy))
                {
                    touchMoved    = true;
                    lastSwipeTime = SWIPE_COOLDOWN;
                    changeSelection(dx > 0 ? 1 : -1);
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
                for (i in 0...cards.length)
                {
                    if (cards[i].overlapsPoint(touch.getWorldPosition()))
                    {
                        tapped = true;
                        if (curSelected == i)
                            openEditor(i);
                        else
                        {
                            curSelected = i;
                            updateSelection();
                        }
                        break;
                    }
                }
                if (!tapped) goBack();
            }
            touchMoved = false;
        }
    }
    #end

    // ==================== Selection ====================

    function changeSelection(dir:Int):Void
    {
        var next = curSelected + dir;
        if (next < 0) next = EDITORS.length - 1;
        if (next >= EDITORS.length) next = 0;
        curSelected = next;
        updateSelection();
    }

    function updateSelection():Void
    {
        for (i in 0...EDITORS.length)
        {
            var isSelected = i == curSelected;
            var entry      = EDITORS[i];

            cards[i].color       = isSelected ? FlxColor.fromRGB(22, 22, 50) : FlxColor.fromRGB(16, 16, 36);
            cardLabels[i].color  = isSelected ? FlxColor.YELLOW : FlxColor.WHITE;
            cardAccents[i].color = isSelected ? brighten(entry.color, 1.3) : entry.color;
        }

        // Posiciona cursor
        var col = curSelected % 2;
        var row = Std.int(curSelected / 2);
        cursor.x = CARD_START_X + col * (CARD_W + CARD_GAP) - 2;
        cursor.y = CARD_START_Y + row * (CARD_H + CARD_GAP) - 2;

        // Atualiza painel de preview
        var entry = EDITORS[curSelected];
        previewTitle.text = entry.icon + "  " + entry.label;
        previewTitle.color = entry.color;
        previewDesc.text  = entry.description + "\n\nClick or press Enter to open this editor.";
        previewType.text  = "TYPE: " + editorTypeName(entry.type);
    }

    function brighten(col:FlxColor, factor:Float):FlxColor
    {
        return FlxColor.fromRGBFloat(
            Math.min(1, col.redFloat   * factor),
            Math.min(1, col.greenFloat * factor),
            Math.min(1, col.blueFloat  * factor)
        );
    }

    function editorTypeName(type:EditorType):String
    {
        return switch (type)
        {
            case STAGE:          "STAGE DATA";
            case CHARACTER:      "CHARACTER DATA";
            case BULLET_PATTERN: "BULLET PATTERN";
            case DIALOGUE:       "DIALOGUE";
            case ITEM:           "ITEM DATA";
        };
    }

    // ==================== Open Editor ====================

    function openEditor(index:Int):Void
    {
        if (!canInput) return;

        canInput = false;
        var entry = EDITORS[index];

        // Flash no card selecionado
        FlxTween.tween(cards[index], {alpha: 0.3}, 0.06, {
            ease: FlxEase.quartOut,
            onComplete: function(_)
            {
                FlxTween.tween(cards[index], {alpha: 1}, 0.06, {
                    ease: FlxEase.quartOut,
                    onComplete: function(_) transitionToEditor(entry.type)
                });
            }
        });
    }

    function transitionToEditor(type:EditorType):Void
    {
        fadeOut(function()
        {
            switch (type)
            {
                case STAGE:          FlxG.switchState(new menus.debug.StageEditorState());
                case CHARACTER:      FlxG.switchState(new menus.debug.CharacterEditorState());
                case BULLET_PATTERN: FlxG.switchState(new menus.debug.BulletPatternEditorState());
                case DIALOGUE:       FlxG.switchState(new menus.debug.DialogueEditorState());
                case ITEM:           FlxG.switchState(new menus.debug.ItemEditorState());
            }
        });
    }

    // ==================== Back ====================

    function goBack():Void
    {
        if (!canInput) return;
        canInput = false;
        fadeOut(function() FlxG.switchState(new menus.MainMenuState()));
    }

    // ==================== Fade Out ====================

    function fadeOut(onDone:Void -> Void):Void
    {
        FlxTween.tween(titleText,    {alpha: 0}, 0.3, {ease: FlxEase.quartIn});
        FlxTween.tween(subtitleText, {alpha: 0}, 0.3, {ease: FlxEase.quartIn});
        FlxTween.tween(cursor,       {alpha: 0}, 0.2, {ease: FlxEase.quartIn});
        FlxTween.tween(previewPanel, {alpha: 0}, 0.3, {ease: FlxEase.quartIn});
        FlxTween.tween(previewTitle, {alpha: 0}, 0.3, {ease: FlxEase.quartIn});
        FlxTween.tween(previewDesc,  {alpha: 0}, 0.3, {ease: FlxEase.quartIn});
        FlxTween.tween(hintText,     {alpha: 0}, 0.2, {ease: FlxEase.quartIn});

        for (i in 0...EDITORS.length)
        {
            FlxTween.tween(cards[i],       {alpha: 0}, 0.25, {ease: FlxEase.quartIn, startDelay: i * 0.04});
            FlxTween.tween(cardAccents[i], {alpha: 0}, 0.25, {ease: FlxEase.quartIn, startDelay: i * 0.04});
            FlxTween.tween(cardIcons[i],   {alpha: 0}, 0.25, {ease: FlxEase.quartIn, startDelay: i * 0.04});
            FlxTween.tween(cardLabels[i],  {alpha: 0}, 0.25, {ease: FlxEase.quartIn, startDelay: i * 0.04});
            FlxTween.tween(cardDescs[i],   {alpha: 0}, 0.25, {
                ease: FlxEase.quartIn,
                startDelay: i * 0.04,
                onComplete: i == EDITORS.length - 1 ? function(_) onDone() : null
            });
        }
    }
}
