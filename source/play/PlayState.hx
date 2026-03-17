package play;

import flixel.FlxState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.group.FlxGroup;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.math.FlxAngle;
import flixel.effects.FlxFlicker;
import backend.Controls;
import backend.Controls.Action;
import backend.debug.DebugDisplay;

// ==================== Bullet ====================
class Bullet extends FlxSprite
{
    public var speed:Float     = 300;
    public var moveAngle:Float = 0;
    public var isPlayer:Bool   = false;

    public function new()
    {
        super();
        exists = false;
    }

    public function fire(x:Float, y:Float, fireAngle:Float, spd:Float, col:FlxColor, fromPlayer:Bool = false, radius:Int = 6):Void
    {
        isPlayer  = fromPlayer;
        speed     = spd;
        moveAngle = fireAngle;

        makeGraphic(radius * 2 + 4, radius * 2 + 4, FlxColor.TRANSPARENT);
        drawCircleBullet(col, radius);

        setPosition(x - width / 2, y - height / 2);
        velocity.set(
            Math.cos(fireAngle * Math.PI / 180) * spd,
            Math.sin(fireAngle * Math.PI / 180) * spd
        );
        setSize(radius * 1.2, radius * 1.2);
        centerOffsets();
        exists = true;
        alive  = true;
    }

    function drawCircleBullet(col:FlxColor, radius:Int):Void
    {
        var cx = pixels.width  / 2.0;
        var cy = pixels.height / 2.0;
        for (px in 0...pixels.width)
        {
            for (py in 0...pixels.height)
            {
                var dx   = px - cx;
                var dy   = py - cy;
                var dist = Math.sqrt(dx * dx + dy * dy);
                if (dist <= radius + 2)
                {
                    var a:Float;
                    var c:FlxColor;
                    if (dist <= radius * 0.4)      { c = FlxColor.WHITE; a = 1.0; }
                    else if (dist <= radius)        { c = col;            a = 1.0; }
                    else                            { c = col;            a = 1.0 - (dist - radius) / 2.0; }
                    pixels.setPixel32(px, py, FlxColor.fromRGBFloat(c.redFloat, c.greenFloat, c.blueFloat, Math.max(0, a)));
                }
            }
        }
        dirty = true;
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);
        if (x < -60 || x > FlxG.width + 60 || y < -60 || y > FlxG.height + 60)
            kill();
    }
}

// ==================== BulletPool ====================
class BulletPool extends FlxGroup
{
    public function new(size:Int)
    {
        super(size);
        for (_ in 0...size)
            add(new Bullet());
    }

    public function fire(x:Float, y:Float, fireAngle:Float, spd:Float, col:FlxColor, fromPlayer:Bool = false, radius:Int = 6):Bullet
    {
        var b:Bullet = cast getFirstDead();
        if (b != null)
            b.fire(x, y, fireAngle, spd, col, fromPlayer, radius);
        return b;
    }
}

// ==================== Player ====================
class Player extends FlxSprite
{
    public var moveSpeed:Float     = 200;
    public var focusSpeed:Float    = 90;
    public var lives:Int           = 3;
    public var bombs:Int           = 3;
    public var invincible:Bool     = false;
    public var shootCooldown:Float = 0;
    public var hitboxSprite:FlxSprite;
    public var focusRing:FlxSprite;

    public function new(x:Float, y:Float)
    {
        super(x, y);
        makeGraphic(20, 28, FlxColor.TRANSPARENT);
        drawPlayerSprite();
        setSize(5, 5);
        centerOffsets();

        hitboxSprite = new FlxSprite();
        hitboxSprite.makeGraphic(12, 12, FlxColor.TRANSPARENT);
        drawHitbox();
        hitboxSprite.exists = false;

        focusRing = new FlxSprite();
        focusRing.makeGraphic(36, 36, FlxColor.TRANSPARENT);
        drawFocusRing();
        focusRing.exists = false;
    }

    function drawPlayerSprite():Void
    {
        for (px in 0...pixels.width)
        {
            for (py in 0...pixels.height)
            {
                var cx    = px - pixels.width  / 2.0;
                var norm  = 1.0 - (py / pixels.height);
                var halfW = (pixels.width / 2.0) * norm * 0.9;
                if (Math.abs(cx) <= halfW)
                {
                    var col = norm > 0.7 ? FlxColor.WHITE : FlxColor.fromRGB(100, 220, 255);
                    pixels.setPixel32(px, py, col);
                }
            }
        }
        for (py in 4...pixels.height - 4)
        {
            var norm  = 1.0 - (py / pixels.height);
            var halfW = Std.int((pixels.width / 2.0) * norm * 0.4);
            var mid   = Std.int(pixels.width / 2);
            for (px in mid - halfW...mid + halfW)
                pixels.setPixel32(px, py, FlxColor.WHITE);
        }
        dirty = true;
    }

    function drawHitbox():Void
    {
        var r  = 5.0;
        var cx = hitboxSprite.pixels.width  / 2.0;
        var cy = hitboxSprite.pixels.height / 2.0;
        for (px in 0...hitboxSprite.pixels.width)
        {
            for (py in 0...hitboxSprite.pixels.height)
            {
                var dx   = px - cx;
                var dy   = py - cy;
                var dist = Math.sqrt(dx * dx + dy * dy);
                if (dist <= r && dist >= r - 1.5)
                    hitboxSprite.pixels.setPixel32(px, py, FlxColor.WHITE);
            }
        }
        hitboxSprite.dirty = true;
    }

    function drawFocusRing():Void
    {
        var r  = 16.0;
        var cx = focusRing.pixels.width  / 2.0;
        var cy = focusRing.pixels.height / 2.0;
        for (px in 0...focusRing.pixels.width)
        {
            for (py in 0...focusRing.pixels.height)
            {
                var dx   = px - cx;
                var dy   = py - cy;
                var dist = Math.sqrt(dx * dx + dy * dy);
                if (dist <= r && dist >= r - 2.5)
                {
                    var a:Float = dist >= r - 0.5 ? 0.4 : 0.9;
                    focusRing.pixels.setPixel32(px, py, FlxColor.fromRGBFloat(0.7, 0.87, 1.0, a));
                }
            }
        }
        focusRing.dirty = true;
    }

    public function takeDamage():Bool
    {
        if (invincible) return false;
        lives--;
        invincible = true;
        FlxFlicker.flicker(this, 2.0, 0.12, true, true, function(_) invincible = false);
        return lives <= 0;
    }
}

// ==================== PlayState ====================
class PlayState extends FlxState
{
    // Core
    var player:Player;
    var playerBullets:BulletPool;
    var enemyBullets:BulletPool;
    var controls:Controls;

    // Boss
    var boss:FlxSprite;
    var bossGlow:FlxSprite;
    var bossHP:Float           = 200;
    var bossHPMax:Float        = 200;
    var bossSwingAngle:Float   = 0;
    var bossPatternTimer:Float = 0;
    var bossPattern:Int        = 0;
    var bossFireTimer:Float    = 0;
    var bossWaveAngle:Float    = 0;
    var bossPhase:Int          = 0;

    // Background
    var starLayers:Array<Array<FlxSprite>> = [];
    var bgScrollSpeeds:Array<Float>        = [15, 35, 65];

    // UI
    var scoreText:FlxText;
    var livesText:FlxText;
    var bombsText:FlxText;
    var grazeText:FlxText;
    var bossHPBar:FlxSprite;
    var bossHPBarBG:FlxSprite;
    var bossHPBarGlow:FlxSprite;
    var bossNameText:FlxText;

    // Score
    var score:Int        = 0;
    var graze:Int        = 0;
    var grazeTimer:Float = 0;

    // State
    var gameOver:Bool     = false;
    var paused:Bool       = false;
    var bossDefeated:Bool = false;

    // Shoot
    var shootHeldTime:Float = 0;

    // Debug
    #if debug
    var debugDisplay:DebugDisplay;
    #end

    // Play area
    static final PLAY_X:Float = 32;
    static final PLAY_Y:Float = 16;
    static final PLAY_W:Float = 448;
    static inline function playH():Float return FlxG.height - 32;

    // ==================== Mobile ====================
    #if mobile

    // Pause
    var pauseButton:FlxSprite;

    // Joystick
    var joystickBG:FlxSprite;
    var joystickKnob:FlxSprite;
    var joystickTouchID:Int  = -1;
    var joystickBaseX:Float  = 0;
    var joystickBaseY:Float  = 0;
    var joystickDX:Float     = 0;
    var joystickDY:Float     = 0;
    static final JOYSTICK_RADIUS:Float = 65;
    static final KNOB_RADIUS:Float     = 26;
    static final JOYSTICK_DEAD:Float   = 0.10;

    // Botões
    var shootButton:FlxSprite;
    var focusButton:FlxSprite;
    var bombButton:FlxSprite;

    // Touch IDs dos botões
    var shootTouchID:Int = -1;
    var focusTouchID:Int = -1;
    var bombTouchID:Int  = -1;

    // Estado dos botões
    var mobileShoot:Bool = false;
    var mobileFocus:Bool = false;
    var mobileBomb:Bool  = false;

    // Regiões dos botões (para overlap preciso)
    var shootBtnCX:Float = 0;
    var shootBtnCY:Float = 0;
    var focusBtnCX:Float = 0;
    var focusBtnCY:Float = 0;
    var bombBtnCX:Float  = 0;
    var bombBtnCY:Float  = 0;
    static final BTN_RADIUS:Float = 28;

    #end

    // ==================== Create ====================

    override public function create():Void
    {
        super.create();

        controls = Controls.instance;
        FlxG.camera.bgColor = FlxColor.fromRGB(2, 2, 10);

        createBackground();
        createPlayer();
        createBoss();
        createUI();

        #if mobile
        createMobileUI();
        #end

        #if debug
        debugDisplay = new DebugDisplay(4, 4);
        add(debugDisplay);
        #end

        #if desktop
        discord.Discord.setPlaying("Stage 1", player.lives, score);
        #end
    }

    // ==================== Background ====================

    function createBackground():Void
    {
        var bgBase = new FlxSprite(PLAY_X, PLAY_Y).makeGraphic(Std.int(PLAY_W), Std.int(playH()), FlxColor.fromRGB(2, 2, 18));
        add(bgBase);

        var starColors = [
            [FlxColor.fromRGB(60,  60,  100), FlxColor.fromRGB(40,  40,  80)],
            [FlxColor.fromRGB(120, 120, 180), FlxColor.fromRGB(80,  80, 140)],
            [FlxColor.fromRGB(220, 220, 255), FlxColor.fromRGB(180, 180, 220)]
        ];
        var starCounts = [100, 60, 30];
        var starSizes  = [1,   2,  3];

        for (layer in 0...3)
        {
            var stars:Array<FlxSprite> = [];
            for (_ in 0...starCounts[layer])
            {
                var star = new FlxSprite(
                    PLAY_X + FlxG.random.float(0, PLAY_W),
                    FlxG.random.float(0, FlxG.height)
                );
                var col = starColors[layer][FlxG.random.int(0, 1)];
                star.makeGraphic(starSizes[layer], starSizes[layer], col);
                star.alpha = FlxG.random.float(0.3, 1.0);
                add(star);
                stars.push(star);
            }
            starLayers.push(stars);
        }

        var bc = FlxColor.fromRGB(40, 40, 80);
        add(new FlxSprite(PLAY_X - 2,      PLAY_Y).makeGraphic(2, Std.int(playH()), bc));
        add(new FlxSprite(PLAY_X + PLAY_W, PLAY_Y).makeGraphic(2, Std.int(playH()), bc));
        add(new FlxSprite(PLAY_X, PLAY_Y - 2).makeGraphic(Std.int(PLAY_W), 2, bc));
        add(new FlxSprite(PLAY_X, PLAY_Y + playH()).makeGraphic(Std.int(PLAY_W), 2, bc));
    }

    // ==================== Player ====================

    function createPlayer():Void
    {
        player = new Player(PLAY_X + PLAY_W / 2, PLAY_Y + playH() - 80);
        add(player.focusRing);
        add(player.hitboxSprite);
        add(player);

        playerBullets = new BulletPool(300);
        add(playerBullets);

        enemyBullets = new BulletPool(1500);
        add(enemyBullets);
    }

    // ==================== Boss ====================

    function createBoss():Void
    {
        bossGlow = new FlxSprite(0, 0).makeGraphic(80, 80, FlxColor.TRANSPARENT);
        drawBossGlow();
        bossGlow.x = PLAY_X + PLAY_W / 2 - 40;
        bossGlow.y = -100;
        add(bossGlow);

        boss = new FlxSprite(PLAY_X + PLAY_W / 2 - 20, -80);
        boss.makeGraphic(40, 40, FlxColor.TRANSPARENT);
        drawBossSprite();
        add(boss);

        FlxTween.tween(boss,     {y: PLAY_Y + 80}, 1.8, {ease: FlxEase.quartOut, startDelay: 0.3});
        FlxTween.tween(bossGlow, {y: PLAY_Y + 60}, 1.8, {ease: FlxEase.quartOut, startDelay: 0.3});
    }

    function drawBossSprite():Void
    {
        var cx = boss.pixels.width  / 2.0;
        var cy = boss.pixels.height / 2.0;
        var r  = 18.0;
        for (px in 0...boss.pixels.width)
        {
            for (py in 0...boss.pixels.height)
            {
                var dx   = px - cx;
                var dy   = py - cy;
                var dist = Math.sqrt(dx * dx + dy * dy);
                if (dist <= r)
                {
                    var t   = dist / r;
                    var col = FlxColor.interpolate(FlxColor.WHITE, FlxColor.fromRGB(255, 60, 80), t);
                    boss.pixels.setPixel32(px, py, FlxColor.fromRGBFloat(col.redFloat, col.greenFloat, col.blueFloat, 1.0));
                }
            }
        }
        boss.dirty = true;
        boss.setSize(32, 32);
        boss.centerOffsets();
    }

    function drawBossGlow():Void
    {
        var cx = bossGlow.pixels.width  / 2.0;
        var cy = bossGlow.pixels.height / 2.0;
        var r  = 38.0;
        for (px in 0...bossGlow.pixels.width)
        {
            for (py in 0...bossGlow.pixels.height)
            {
                var dx   = px - cx;
                var dy   = py - cy;
                var dist = Math.sqrt(dx * dx + dy * dy);
                if (dist <= r)
                {
                    var a = (1.0 - dist / r) * 0.35;
                    bossGlow.pixels.setPixel32(px, py, FlxColor.fromRGBFloat(1.0, 0.31, 0.39, a));
                }
            }
        }
        bossGlow.dirty = true;
    }

    // ==================== UI ====================

    function createUI():Void
    {
        var uiPanel = new FlxSprite(PLAY_X + PLAY_W + 2, 0).makeGraphic(
            Std.int(FlxG.width - PLAY_W - PLAY_X - 2), FlxG.height,
            FlxColor.fromRGB(6, 6, 16)
        );
        add(uiPanel);

        var uiX:Float = PLAY_X + PLAY_W + 14;
        var panelW    = FlxG.width - Std.int(PLAY_W) - Std.int(PLAY_X) - 28;

        var gameTitle = new FlxText(uiX, 14, panelW, "Kareshi Project");
        gameTitle.setFormat(null, 14, FlxColor.fromRGB(160, 160, 220), "center");
        gameTitle.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 1);
        add(gameTitle);

        add(new FlxSprite(uiX, 34).makeGraphic(panelW, 1, FlxColor.fromRGB(40, 40, 80)));

        var scoreLabel = new FlxText(uiX, 44, panelW, "SCORE");
        scoreLabel.setFormat(null, 11, FlxColor.fromRGB(140, 140, 200), "left");
        add(scoreLabel);

        scoreText = new FlxText(uiX, 56, panelW, "00000000");
        scoreText.setFormat(null, 18, FlxColor.WHITE, "right");
        scoreText.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 2);
        add(scoreText);

        var livesLabel = new FlxText(uiX, 90, panelW, "LIVES");
        livesLabel.setFormat(null, 11, FlxColor.fromRGB(140, 140, 200), "left");
        add(livesLabel);

        livesText = new FlxText(uiX, 102, panelW, "♥ ♥ ♥");
        livesText.setFormat(null, 20, FlxColor.fromRGB(255, 80, 100), "left");
        livesText.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 2);
        add(livesText);

        var bombsLabel = new FlxText(uiX, 136, panelW, "BOMBS");
        bombsLabel.setFormat(null, 11, FlxColor.fromRGB(140, 140, 200), "left");
        add(bombsLabel);

        bombsText = new FlxText(uiX, 148, panelW, "✦ ✦ ✦");
        bombsText.setFormat(null, 20, FlxColor.fromRGB(80, 180, 255), "left");
        bombsText.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 2);
        add(bombsText);

        var grazeLabel = new FlxText(uiX, 182, panelW, "GRAZE");
        grazeLabel.setFormat(null, 11, FlxColor.fromRGB(140, 140, 200), "left");
        add(grazeLabel);

        grazeText = new FlxText(uiX, 194, panelW, "0000");
        grazeText.setFormat(null, 16, FlxColor.YELLOW, "right");
        grazeText.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 2);
        add(grazeText);

        add(new FlxSprite(uiX, 224).makeGraphic(panelW, 1, FlxColor.fromRGB(40, 40, 80)));

        var diffLabel = new FlxText(uiX, 232, panelW, "EASY");
        diffLabel.setFormat(null, 13, FlxColor.fromRGB(100, 255, 120), "center");
        add(diffLabel);

        bossHPBarBG = new FlxSprite(PLAY_X, PLAY_Y - 14).makeGraphic(Std.int(PLAY_W), 8, FlxColor.fromRGB(30, 30, 30));
        add(bossHPBarBG);

        bossHPBarGlow = new FlxSprite(PLAY_X, PLAY_Y - 14).makeGraphic(Std.int(PLAY_W), 8, FlxColor.fromRGB(255, 120, 130));
        bossHPBarGlow.alpha = 0.3;
        add(bossHPBarGlow);

        bossHPBar = new FlxSprite(PLAY_X, PLAY_Y - 14).makeGraphic(Std.int(PLAY_W), 8, FlxColor.fromRGB(220, 60, 80));
        add(bossHPBar);

        bossNameText = new FlxText(PLAY_X, PLAY_Y - 30, PLAY_W, "??? — Stage Boss");
        bossNameText.setFormat(null, 13, FlxColor.fromRGB(255, 200, 210), "center");
        bossNameText.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 2);
        add(bossNameText);

        #if desktop
        var hint = new FlxText(PLAY_X, PLAY_Y + playH() + 4, PLAY_W,
            "Z: Shoot   X: Bomb   Shift: Focus   ESC: Pause");
        hint.setFormat(null, 11, FlxColor.fromRGBFloat(1, 1, 1, 0.4), "center");
        add(hint);
        #end
    }

    // ==================== Mobile UI ====================

    #if mobile
    function createMobileUI():Void
    {
        // ---- Pause button (canto superior direito) ----
        pauseButton = new FlxSprite(FlxG.width - 52, 8);
        pauseButton.loadGraphic("images/mobile/pause.png");
        pauseButton.setGraphicSize(40, 40);
        pauseButton.updateHitbox();
        pauseButton.scrollFactor.set(0, 0);
        add(pauseButton);

        // ---- Joystick (lado esquerdo, fixo) ----
        var joyBX:Float = 100;
        var joyBY:Float = FlxG.height - 130;
        joystickBaseX = joyBX;
        joystickBaseY = joyBY;

        joystickBG = new FlxSprite(
            joyBX - JOYSTICK_RADIUS - 10,
            joyBY - JOYSTICK_RADIUS - 10
        ).makeGraphic(
            Std.int((JOYSTICK_RADIUS + 10) * 2),
            Std.int((JOYSTICK_RADIUS + 10) * 2),
            FlxColor.TRANSPARENT
        );
        drawCircleOnSprite(joystickBG, JOYSTICK_RADIUS + 10, JOYSTICK_RADIUS, FlxColor.fromRGBFloat(1, 1, 1, 0.10), false);
        joystickBG.scrollFactor.set(0, 0);
        add(joystickBG);

        joystickKnob = new FlxSprite(
            joyBX - KNOB_RADIUS,
            joyBY - KNOB_RADIUS
        ).makeGraphic(
            Std.int(KNOB_RADIUS * 2),
            Std.int(KNOB_RADIUS * 2),
            FlxColor.TRANSPARENT
        );
        drawCircleOnSprite(joystickKnob, KNOB_RADIUS, KNOB_RADIUS, FlxColor.fromRGBFloat(0.6, 0.85, 1.0, 0.65), true);
        joystickKnob.scrollFactor.set(0, 0);
        add(joystickKnob);

        // ---- Botões lado direito ----
        // Layout:
        //   [FOCUS]
        //            [BOMB]
        //   [SHOT]
        var rightEdge:Float = FlxG.width - 20;
        var botY:Float      = FlxG.height - 70;
        var midY:Float      = FlxG.height - 140;
        var topY:Float      = FlxG.height - 210;
        var leftCol:Float   = rightEdge - BTN_RADIUS * 2 - 50;
        var rightCol:Float  = rightEdge - BTN_RADIUS * 2;

        // Centros dos botões para detecção por distância
        shootBtnCX = leftCol  + BTN_RADIUS;
        shootBtnCY = botY     + BTN_RADIUS;
        focusBtnCX = leftCol  + BTN_RADIUS;
        focusBtnCY = topY     + BTN_RADIUS;
        bombBtnCX  = rightCol + BTN_RADIUS;
        bombBtnCY  = midY     + BTN_RADIUS;

        shootButton = makeMobileButton(leftCol,  botY, FlxColor.fromRGB(100, 200, 255), "SHOT");
        focusButton = makeMobileButton(leftCol,  topY, FlxColor.fromRGB(255, 220, 80),  "FOCUS");
        bombButton  = makeMobileButton(rightCol, midY, FlxColor.fromRGB(255, 100, 100), "BOMB");

        add(shootButton);
        add(focusButton);
        add(bombButton);
    }

    function makeMobileButton(bx:Float, by:Float, col:FlxColor, label:String):FlxSprite
    {
        var size = Std.int(BTN_RADIUS * 2);
        var btn  = new FlxSprite(bx, by).makeGraphic(size, size, FlxColor.TRANSPARENT);
        var cx   = BTN_RADIUS;
        var cy   = BTN_RADIUS;

        for (px in 0...size)
        {
            for (py in 0...size)
            {
                var dx   = px - cx;
                var dy   = py - cy;
                var dist = Math.sqrt(dx * dx + dy * dy);
                if (dist <= BTN_RADIUS)
                {
                    var t  = dist / BTN_RADIUS;
                    var rc = FlxColor.interpolate(FlxColor.WHITE, col, t);
                    var a  = dist <= BTN_RADIUS - 2 ? 0.70 : 0.30;
                    btn.pixels.setPixel32(px, py, FlxColor.fromRGBFloat(rc.redFloat, rc.greenFloat, rc.blueFloat, a));
                }
            }
        }
        btn.dirty = true;
        btn.scrollFactor.set(0, 0);

        var txt = new FlxText(bx, by + BTN_RADIUS - 8, size, label);
        txt.setFormat(null, 10, FlxColor.WHITE, "center");
        txt.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 1);
        txt.scrollFactor.set(0, 0);
        add(txt);

        return btn;
    }

    function drawCircleOnSprite(sprite:FlxSprite, cx:Float, r:Float, col:FlxColor, filled:Bool):Void
    {
        var cy = cx;
        for (px in 0...sprite.pixels.width)
        {
            for (py in 0...sprite.pixels.height)
            {
                var dx   = px - cx;
                var dy   = py - cy;
                var dist = Math.sqrt(dx * dx + dy * dy);
                var hit  = filled ? dist <= r : (dist <= r && dist >= r - 3);
                if (hit)
                {
                    var a = filled ? (1.0 - dist / r) * col.alphaFloat : col.alphaFloat;
                    sprite.pixels.setPixel32(px, py, FlxColor.fromRGBFloat(col.redFloat, col.greenFloat, col.blueFloat, Math.max(0, a)));
                }
            }
        }
        sprite.dirty = true;
    }

    // Detecta se um toque está dentro de um botão circular
    function touchInButton(tx:Float, ty:Float, cx:Float, cy:Float):Bool
    {
        var dx = tx - cx;
        var dy = ty - cy;
        return Math.sqrt(dx * dx + dy * dy) <= BTN_RADIUS + 8; // margem extra
    }
    #end

    // ==================== Update ====================

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        if (gameOver || bossDefeated) return;

        #if desktop
        if (controls.justPressed(Action.PAUSE))
        {
            paused = true;
            openSubState(new substates.PauseSubState());
            return;
        }
        #end

        if (paused) return;

        scrollBackground(elapsed);
        updateBossGlow(elapsed);

        #if mobile
        handleMobileInput(elapsed);
        #end

        handlePlayerMovement(elapsed);
        handlePlayerShoot(elapsed);
        handleBoss(elapsed);
        handleCollisions();
        handleGraze(elapsed);
        updateUI();

        #if (debug && desktop)
        if (FlxG.keys.justPressed.F2)
            debugDisplay.toggle();
        #end
    }

    override public function closeSubState():Void
    {
        super.closeSubState();
        paused = false;

        #if desktop
        discord.Discord.setPlaying("Stage 1", player.lives, score);
        #end
    }

    // ==================== Background ====================

    function scrollBackground(elapsed:Float):Void
    {
        for (layer in 0...starLayers.length)
            for (star in starLayers[layer])
            {
                star.y += bgScrollSpeeds[layer] * elapsed;
                if (star.y > PLAY_Y + playH()) star.y = PLAY_Y - 4;
            }
    }

    function updateBossGlow(elapsed:Float):Void
    {
        bossGlow.x     = boss.x + boss.width  / 2 - bossGlow.width  / 2;
        bossGlow.y     = boss.y + boss.height / 2 - bossGlow.height / 2;
        bossGlow.alpha = 0.6 + Math.sin(haxe.Timer.stamp() * 3) * 0.4;
    }

    // ==================== Mobile Input ====================

    #if mobile
    function handleMobileInput(elapsed:Float):Void
    {
        // Reset estados dos botões
        mobileShoot = false;
        mobileFocus = false;
        mobileBomb  = false;

        // ---- Toque iniciado ----
        for (touch in FlxG.touches.justStarted())
        {
            var tx = touch.screenX;
            var ty = touch.screenY;
            var id = touch.touchPointID;

            // Pause button
            if (tx > FlxG.width - 60 && ty < 56)
            {
                paused = true;
                openSubState(new substates.PauseSubState());
                return;
            }

            // Botões (lado direito da tela — metade direita)
            if (tx > FlxG.width * 0.5)
            {
                if (touchInButton(tx, ty, shootBtnCX, shootBtnCY) && shootTouchID == -1)
                {
                    shootTouchID = id;
                }
                else if (touchInButton(tx, ty, focusBtnCX, focusBtnCY) && focusTouchID == -1)
                {
                    focusTouchID = id;
                }
                else if (touchInButton(tx, ty, bombBtnCX, bombBtnCY) && bombTouchID == -1)
                {
                    bombTouchID = id;
                }
            }

            // Joystick (lado esquerdo — qualquer toque que não seja botão)
            if (tx < FlxG.width * 0.5 && joystickTouchID == -1)
            {
                joystickTouchID = id;

                // Reposiciona joystick onde o dedo tocou
                joystickBaseX  = tx;
                joystickBaseY  = ty;

                joystickBG.x   = tx - JOYSTICK_RADIUS - 10;
                joystickBG.y   = ty - JOYSTICK_RADIUS - 10;
                joystickKnob.x = tx - KNOB_RADIUS;
                joystickKnob.y = ty - KNOB_RADIUS;
            }
        }

        // ---- Toque mantido ----
        joystickDX = 0;
        joystickDY = 0;

        for (touch in FlxG.touches.list)
        {
            var tx = touch.screenX;
            var ty = touch.screenY;
            var id = touch.touchPointID;

            // Atualiza estados dos botões por ID
            if (id == shootTouchID) mobileShoot = true;
            if (id == focusTouchID) mobileFocus = true;
            if (id == bombTouchID)  mobileBomb  = true;

            // Atualiza joystick
            if (id == joystickTouchID)
            {
                var dx   = tx - joystickBaseX;
                var dy   = ty - joystickBaseY;
                var dist = Math.sqrt(dx * dx + dy * dy);

                // Clamp no raio
                if (dist > JOYSTICK_RADIUS)
                {
                    dx = dx / dist * JOYSTICK_RADIUS;
                    dy = dy / dist * JOYSTICK_RADIUS;
                    dist = JOYSTICK_RADIUS;
                }

                var nx = dx / JOYSTICK_RADIUS;
                var ny = dy / JOYSTICK_RADIUS;

                // Dead zone
                joystickDX = Math.abs(nx) > JOYSTICK_DEAD ? nx : 0;
                joystickDY = Math.abs(ny) > JOYSTICK_DEAD ? ny : 0;

                // Move o knob
                joystickKnob.x = joystickBaseX + dx - KNOB_RADIUS;
                joystickKnob.y = joystickBaseY + dy - KNOB_RADIUS;
            }
        }

        // ---- Toque liberado ----
        for (touch in FlxG.touches.justReleased())
        {
            var id = touch.touchPointID;

            if (id == joystickTouchID)
            {
                joystickTouchID = -1;
                joystickDX      = 0;
                joystickDY      = 0;
                // Volta o knob ao centro
                joystickKnob.x  = joystickBaseX - KNOB_RADIUS;
                joystickKnob.y  = joystickBaseY - KNOB_RADIUS;
            }
            if (id == shootTouchID) { shootTouchID = -1; mobileShoot = false; }
            if (id == focusTouchID) { focusTouchID = -1; mobileFocus = false; }
            if (id == bombTouchID)  { bombTouchID  = -1; mobileBomb  = false; }
        }

        // ---- Aplica movimento ao player ----
        var spd = mobileFocus ? player.focusSpeed : player.moveSpeed;
        player.velocity.set(joystickDX * spd, joystickDY * spd);

        player.x = Math.max(PLAY_X, Math.min(PLAY_X + PLAY_W - player.width,  player.x));
        player.y = Math.max(PLAY_Y, Math.min(PLAY_Y + playH() - player.height, player.y));

        // Focus ring e hitbox
        player.focusRing.exists    = mobileFocus;
        player.hitboxSprite.exists = mobileFocus;
        if (mobileFocus)
        {
            player.focusRing.angle += 90 * elapsed;
            player.focusRing.x = player.x + (player.width  - player.focusRing.width)  / 2;
            player.focusRing.y = player.y + (player.height - player.focusRing.height) / 2;
            player.hitboxSprite.x = player.x + (player.width  - player.hitboxSprite.width)  / 2;
            player.hitboxSprite.y = player.y + (player.height - player.hitboxSprite.height) / 2;
        }
    }
    #end

    // ==================== Player Movement ====================

    function handlePlayerMovement(elapsed:Float):Void
    {
        #if !mobile
        var isFocused = controls.pressed(Action.FOCUS);
        var spd       = isFocused ? player.focusSpeed : player.moveSpeed;
        var move      = controls.getMovement();

        player.velocity.set(move.x * spd, move.y * spd);

        player.x = Math.max(PLAY_X, Math.min(PLAY_X + PLAY_W - player.width,  player.x));
        player.y = Math.max(PLAY_Y, Math.min(PLAY_Y + playH() - player.height, player.y));

        player.focusRing.exists    = isFocused;
        player.hitboxSprite.exists = isFocused;
        if (isFocused)
        {
            player.focusRing.angle += 90 * elapsed;
            player.focusRing.x = player.x + (player.width  - player.focusRing.width)  / 2;
            player.focusRing.y = player.y + (player.height - player.focusRing.height) / 2;
            player.hitboxSprite.x = player.x + (player.width  - player.hitboxSprite.width)  / 2;
            player.hitboxSprite.y = player.y + (player.height - player.hitboxSprite.height) / 2;
        }
        #end
    }

    // ==================== Player Shoot ====================

    function handlePlayerShoot(elapsed:Float):Void
    {
        player.shootCooldown -= elapsed;

        #if mobile
        var shooting  = mobileShoot;
        var isFocused = mobileFocus;
        #else
        var shooting  = controls.pressed(Action.SHOOT);
        var isFocused = controls.pressed(Action.FOCUS);
        #end

        if (shooting)
        {
            shootHeldTime += elapsed;
            var cooldown = isFocused ? 0.055 : 0.085;
            if (shootHeldTime > 1.5) cooldown *= 0.85;

            if (player.shootCooldown <= 0)
            {
                player.shootCooldown = cooldown;
                firePlayerBullets(isFocused);
            }
        }
        else
        {
            shootHeldTime = 0;
        }
    }

    function firePlayerBullets(isFocused:Bool):Void
    {
        var bx = player.x + player.width  / 2;
        var by = player.y;

        if (isFocused)
        {
            playerBullets.fire(bx,     by,     -90, 660, FlxColor.fromRGB(220, 255, 255), true, 4);
            playerBullets.fire(bx - 4, by + 2, -90, 645, FlxColor.fromRGB(180, 230, 255), true, 3);
            playerBullets.fire(bx + 4, by + 2, -90, 645, FlxColor.fromRGB(180, 230, 255), true, 3);
        }
        else
        {
            playerBullets.fire(bx,      by,     -90, 560, FlxColor.fromRGB(100, 220, 255), true, 4);
            playerBullets.fire(bx - 10, by + 2, -93, 540, FlxColor.fromRGB(80,  200, 255), true, 3);
            playerBullets.fire(bx + 10, by + 2, -87, 540, FlxColor.fromRGB(80,  200, 255), true, 3);
            playerBullets.fire(bx - 22, by + 4, -97, 510, FlxColor.fromRGB(60,  180, 255), true, 3);
            playerBullets.fire(bx + 22, by + 4, -83, 510, FlxColor.fromRGB(60,  180, 255), true, 3);
        }
    }

    // ==================== Boss ====================

    function handleBoss(elapsed:Float):Void
    {
        bossSwingAngle += elapsed * 55;
        boss.x = PLAY_X + PLAY_W / 2 - boss.width / 2
            + Math.sin(bossSwingAngle * Math.PI / 180) * 140;

        bossPatternTimer += elapsed;
        var patternDur = bossPhase == 0 ? 7.0 : 5.0;
        if (bossPatternTimer >= patternDur)
        {
            bossPatternTimer = 0;
            bossPattern      = (bossPattern + 1) % (bossPhase == 0 ? 4 : 5);
            bossWaveAngle    = 0;
        }

        if (bossHP <= bossHPMax * 0.5 && bossPhase == 0)
        {
            bossPhase  = 1;
            boss.color = FlxColor.fromRGB(255, 150, 50);
            FlxFlicker.flicker(boss, 0.8, 0.06);
        }

        bossFireTimer += elapsed;
        var baseRate:Float = bossPhase == 0 ? 0.10 : 0.07;
        var fireRate:Float = baseRate - (1 - bossHP / bossHPMax) * 0.04;

        if (bossFireTimer >= fireRate)
        {
            bossFireTimer = 0;
            fireBossPattern();
        }
    }

    function fireBossPattern():Void
    {
        var cx     = boss.x + boss.width  / 2;
        var cy     = boss.y + boss.height / 2;
        var phase2 = bossPhase == 1;

        switch (bossPattern)
        {
            case 0:
                var count = phase2 ? 20 : 14;
                for (i in 0...count)
                {
                    var a = (360 / count) * i + bossWaveAngle;
                    enemyBullets.fire(cx, cy, a, phase2 ? 160 : 130, FlxColor.fromRGB(255, 80, 100), false, 5);
                }
                bossWaveAngle += phase2 ? 7 : 5;

            case 1:
                var arms = phase2 ? 3 : 2;
                for (k in 0...arms)
                {
                    var a = bossWaveAngle + (360 / arms) * k;
                    enemyBullets.fire(cx, cy, a,      phase2 ? 200 : 180, FlxColor.fromRGB(255, 180, 50), false, 4);
                    enemyBullets.fire(cx, cy, a + 20, phase2 ? 175 : 155, FlxColor.fromRGB(255, 140, 50), false, 4);
                    enemyBullets.fire(cx, cy, a + 40, phase2 ? 150 : 130, FlxColor.fromRGB(255, 100, 50), false, 4);
                }
                bossWaveAngle += phase2 ? 10 : 8;

            case 2:
                var toPlayer = FlxAngle.angleBetween(boss, player, true);
                var spread   = phase2 ? 50 : 38;
                var count    = phase2 ? 9  : 7;
                for (i in 0...count)
                {
                    var a = toPlayer - spread + (spread * 2 / (count - 1)) * i;
                    enemyBullets.fire(cx, cy, a, phase2 ? 220 : 190, FlxColor.fromRGB(200, 80, 255), false, 4);
                }

            case 3:
                var count = phase2 ? 32 : 24;
                for (i in 0...count)
                {
                    var a = (360 / count) * i + bossWaveAngle;
                    enemyBullets.fire(cx, cy, a, phase2 ? 110 : 85, FlxColor.fromRGB(80, 200, 255), false, 6);
                }
                bossWaveAngle += phase2 ? 4 : 3;

            case 4:
                for (_ in 0...6)
                {
                    var rx = PLAY_X + FlxG.random.float(20, PLAY_W - 20);
                    enemyBullets.fire(rx, cy, 90, FlxG.random.float(120, 180), FlxColor.fromRGB(255, 220, 100), false, 4);
                }
        }
    }

    // ==================== Collisions ====================

    function handleCollisions():Void
    {
        FlxG.overlap(playerBullets, boss, function(b:FlxObject, _)
        {
            var bullet:Bullet = cast b;
            bullet.kill();
            bossHP -= bossPhase == 0 ? 1.0 : 1.5;
            score  += 10;
            if (bossHP <= 0) triggerBossDeath();
        });

        if (!player.invincible)
        {
            FlxG.overlap(enemyBullets, player, function(b:FlxObject, _)
            {
                var bullet:Bullet = cast b;
                bullet.kill();
                var dead = player.takeDamage();

                #if desktop
                discord.Discord.setPlaying("Stage 1", player.lives, score);
                #end

                if (dead) triggerGameOver();
            });
        }
    }

    // ==================== Graze ====================

    function handleGraze(elapsed:Float):Void
    {
        grazeTimer -= elapsed;

        for (basic in enemyBullets.members)
        {
            var bullet:Bullet = cast basic;
            if (bullet == null || !bullet.exists || !bullet.alive) continue;

            var dx   = (bullet.x + bullet.width  / 2) - (player.x + player.width  / 2);
            var dy   = (bullet.y + bullet.height / 2) - (player.y + player.height / 2);
            var dist = Math.sqrt(dx * dx + dy * dy);

            if (dist < 30 && dist > 5)
            {
                graze++;
                score += 3;

                if (grazeTimer <= 0)
                {
                    grazeTimer = 0.4;
                    FlxTween.cancelTweensOf(grazeText);
                    grazeText.alpha = 1;
                    FlxTween.tween(grazeText, {alpha: 0.3}, 0.4, {ease: FlxEase.quartIn});
                }
            }
        }
    }

    // ==================== UI ====================

    function updateUI():Void
    {
        scoreText.text = StringTools.lpad(Std.string(score), "0", 8);

        var livesStr = "";
        for (_ in 0...player.lives) livesStr += "♥ ";
        livesText.text = livesStr == "" ? "—" : livesStr;

        var bombsStr = "";
        for (_ in 0...player.bombs) bombsStr += "✦ ";
        bombsText.text = bombsStr == "" ? "—" : bombsStr;

        grazeText.text = StringTools.lpad(Std.string(graze), "0", 4);

        var ratio = Math.max(0, bossHP / bossHPMax);
        bossHPBar.scale.x     = ratio;
        bossHPBarGlow.scale.x = ratio;
        bossHPBar.x           = PLAY_X;
        bossHPBarGlow.x       = PLAY_X;

        bossHPBar.color = bossPhase == 0
            ? FlxColor.fromRGB(220, 60,  80)
            : FlxColor.fromRGB(255, 140, 40);
    }

    // ==================== Events ====================

    function triggerBossDeath():Void
    {
        bossDefeated    = true;
        boss.exists     = false;
        bossGlow.exists = false;
        score          += 50000;

        #if desktop
        discord.Discord.setStageClear(score);
        #end

        var clear = new FlxText(PLAY_X, PLAY_Y + playH() / 2 - 30, PLAY_W, "Stage Clear!");
        clear.setFormat(null, 42, FlxColor.YELLOW, "center");
        clear.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.fromRGB(200, 100, 0), 3);
        clear.alpha = 0;
        add(clear);

        var bonusText = new FlxText(PLAY_X, PLAY_Y + playH() / 2 + 20, PLAY_W, "Score: " + score);
        bonusText.setFormat(null, 24, FlxColor.WHITE, "center");
        bonusText.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 2);
        bonusText.alpha = 0;
        add(bonusText);

        FlxTween.tween(clear,     {alpha: 1}, 0.6, {ease: FlxEase.quartOut});
        FlxTween.tween(bonusText, {alpha: 1}, 0.6, {
            ease: FlxEase.quartOut,
            startDelay: 0.3,
            onComplete: function(_)
            {
                new FlxTimer().start(3, function(_)
                    FlxG.switchState(new menus.MainMenuState()));
            }
        });
    }

    function triggerGameOver():Void
    {
        if (player.lives > 0) return;

        gameOver = true;

        #if desktop
        discord.Discord.setGameOver(score);
        #end

        var over = new FlxText(PLAY_X, PLAY_Y + playH() / 2 - 30, PLAY_W, "Game Over");
        over.setFormat(null, 42, FlxColor.RED, "center");
        over.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 4);
        over.alpha = 0;
        add(over);

        var scoreOver = new FlxText(PLAY_X, PLAY_Y + playH() / 2 + 20, PLAY_W, "Score: " + score);
        scoreOver.setFormat(null, 22, FlxColor.WHITE, "center");
        scoreOver.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 2);
        scoreOver.alpha = 0;
        add(scoreOver);

        FlxTween.tween(over,      {alpha: 1}, 0.6, {ease: FlxEase.quartOut});
        FlxTween.tween(scoreOver, {alpha: 1}, 0.6, {
            ease: FlxEase.quartOut,
            startDelay: 0.3,
            onComplete: function(_)
            {
                new FlxTimer().start(3, function(_)
                    FlxG.switchState(new menus.MainMenuState()));
            }
        });
    }
}