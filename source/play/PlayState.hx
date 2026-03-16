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
import flixel.math.FlxMath;
import flixel.effects.FlxFlicker;
import flixel.input.touch.FlxTouch;
import backend.Controls;
import backend.Controls.Action;

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

        makeGraphic(radius * 2, radius * 2, FlxColor.TRANSPARENT);
        drawCircle(col, radius);

        color = col;
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

    function drawCircle(col:FlxColor, radius:Int):Void
    {
        var glow = FlxColor.fromRGBFloat(
            col.redFloat   * 0.6 + 0.4,
            col.greenFloat * 0.6 + 0.4,
            col.blueFloat  * 0.6 + 0.4,
            0.4
        );
        makeGraphic(radius * 2 + 4, radius * 2 + 4, FlxColor.TRANSPARENT);
        // Glow externo
        for (px in 0...pixels.width)
        {
            for (py in 0...pixels.height)
            {
                var cx = px - (radius + 2);
                var cy = py - (radius + 2);
                var dist = Math.sqrt(cx * cx + cy * cy);
                if (dist <= radius + 2)
                {
                    var a = dist <= radius ? 1.0 : 1.0 - (dist - radius) / 2;
                    var c = dist <= radius * 0.5
                        ? FlxColor.WHITE
                        : (dist <= radius ? col : glow);
                    c.alphaFloat = a;
                    pixels.setPixel32(px, py, c);
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

        // Hitbox visual
        hitboxSprite = new FlxSprite();
        hitboxSprite.makeGraphic(10, 10, FlxColor.TRANSPARENT);
        drawHitbox();
        hitboxSprite.exists = false;

        // Anel de foco girando
        focusRing = new FlxSprite();
        focusRing.makeGraphic(32, 32, FlxColor.TRANSPARENT);
        drawFocusRing();
        focusRing.exists = false;
    }

    function drawPlayerSprite():Void
    {
        // Corpo triangular estilo danmaku
        for (px in 0...pixels.width)
        {
            for (py in 0...pixels.height)
            {
                var cx    = px - pixels.width  / 2;
                var cy    = py - pixels.height / 2;
                var norm  = 1 - (py / pixels.height);
                var halfW = (pixels.width / 2) * norm * 0.9;

                if (Math.abs(cx) <= halfW)
                {
                    var glow = norm > 0.7 ? FlxColor.WHITE : FlxColor.fromRGB(100, 220, 255);
                    pixels.setPixel32(px, py, glow);
                }
            }
        }

        // Brilho central
        for (py in 4...pixels.height - 4)
        {
            var norm  = 1 - (py / pixels.height);
            var halfW = Std.int((pixels.width / 2) * norm * 0.4);
            for (px in Std.int(pixels.width / 2) - halfW...Std.int(pixels.width / 2) + halfW)
                pixels.setPixel32(px, py, FlxColor.WHITE);
        }
        dirty = true;
    }

    function drawHitbox():Void
    {
        var r = 5;
        var cx = hitboxSprite.pixels.width  / 2;
        var cy = hitboxSprite.pixels.height / 2;
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
        var r  = 14;
        var cx = focusRing.pixels.width  / 2;
        var cy = focusRing.pixels.height / 2;
        for (px in 0...focusRing.pixels.width)
        {
            for (py in 0...focusRing.pixels.height)
            {
                var dx   = px - cx;
                var dy   = py - cy;
                var dist = Math.sqrt(dx * dx + dy * dy);
                if (dist <= r && dist >= r - 2)
                {
                    var a = dist >= r - 0.5 ? 0.5 : 1.0;
                    var col:FlxColor = FlxColor.fromRGB(180, 220, 255);
                    col.alphaFloat = a;
                    focusRing.pixels.setPixel32(px, py, col);
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

        FlxFlicker.flicker(this, 2.0, 0.12, true, true, function(_)
        {
            invincible = false;
        });

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
    var bgOverlay:FlxSprite;

    // UI
    var uiPanel:FlxSprite;
    var scoreText:FlxText;
    var livesText:FlxText;
    var bombsText:FlxText;
    var grazeText:FlxText;
    var bossHPBar:FlxSprite;
    var bossHPBarBG:FlxSprite;
    var bossHPBarGlow:FlxSprite;
    var bossNameText:FlxText;
    var focusHint:FlxText;
    var diffText:FlxText;

    // Mobile UI
    var pauseButton:FlxSprite;
    var joystickBG:FlxSprite;
    var joystickKnob:FlxSprite;
    var shootButton:FlxSprite;
    var focusButton:FlxSprite;
    var bombButton:FlxSprite;

    var joystickTouchID:Int    = -1;
    var joystickBaseX:Float    = 0;
    var joystickBaseY:Float    = 0;
    static final JOYSTICK_RADIUS:Float = 60;
    static final KNOB_RADIUS:Float     = 24;

    var mobileShoot:Bool = false;
    var mobileFocus:Bool = false;
    var mobileBomb:Bool  = false;

    // Score
    var score:Int        = 0;
    var graze:Int        = 0;
    var grazeTimer:Float = 0;

    // State
    var gameOver:Bool    = false;
    var paused:Bool      = false;
    var bossDefeated:Bool = false;

    // Play area
    static final PLAY_X:Float = 32;
    static final PLAY_Y:Float = 16;
    static final PLAY_W:Float = 384;
    static inline function playH():Float return FlxG.height - 32;

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

        #if desktop
        discord.Discord.setPlaying("Stage 1", player.lives, score);
        #end
    }

    // ==================== Background ====================

    function createBackground():Void
    {
        // Fundo gradiente
        var bgBase = new FlxSprite(PLAY_X, PLAY_Y).makeGraphic(Std.int(PLAY_W), Std.int(playH()), FlxColor.fromRGB(2, 2, 18));
        add(bgBase);

        // Camadas de estrelas
        var starColors = [
            [FlxColor.fromRGB(60,  60,  100), FlxColor.fromRGB(40,  40,  80)],
            [FlxColor.fromRGB(120, 120, 180), FlxColor.fromRGB(80,  80,  140)],
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

        // Overlay vinheta
        bgOverlay = new FlxSprite(PLAY_X, PLAY_Y).makeGraphic(Std.int(PLAY_W), Std.int(playH()), FlxColor.TRANSPARENT);
        add(bgOverlay);

        // Bordas da área de jogo
        var borderColor = FlxColor.fromRGB(40, 40, 80);
        var bLeft  = new FlxSprite(PLAY_X - 2,          PLAY_Y).makeGraphic(2, Std.int(playH()), borderColor);
        var bRight = new FlxSprite(PLAY_X + PLAY_W,     PLAY_Y).makeGraphic(2, Std.int(playH()), borderColor);
        var bTop   = new FlxSprite(PLAY_X,              PLAY_Y - 2).makeGraphic(Std.int(PLAY_W), 2, borderColor);
        var bBot   = new FlxSprite(PLAY_X,              PLAY_Y + playH()).makeGraphic(Std.int(PLAY_W), 2, borderColor);
        for (b in [bLeft, bRight, bTop, bBot]) add(b);
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
        // Glow
        bossGlow = new FlxSprite(0, 0).makeGraphic(80, 80, FlxColor.TRANSPARENT);
        drawBossGlow();
        bossGlow.x = PLAY_X + PLAY_W / 2 - 40;
        bossGlow.y = -100;
        add(bossGlow);

        // Boss sprite
        boss = new FlxSprite(PLAY_X + PLAY_W / 2 - 20, -80);
        boss.makeGraphic(40, 40, FlxColor.TRANSPARENT);
        drawBossSprite();
        add(boss);

        FlxTween.tween(boss,     {y: PLAY_Y + 80}, 1.8, {ease: FlxEase.quartOut, startDelay: 0.3});
        FlxTween.tween(bossGlow, {y: PLAY_Y + 60}, 1.8, {ease: FlxEase.quartOut, startDelay: 0.3});
    }

    function drawBossSprite():Void
    {
        var cx = boss.pixels.width  / 2;
        var cy = boss.pixels.height / 2;
        var r  = 18;
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
                    col.alphaFloat = 1.0;
                    boss.pixels.setPixel32(px, py, col);
                }
            }
        }
        boss.dirty = true;
        boss.setSize(32, 32);
        boss.centerOffsets();
    }

    function drawBossGlow():Void
    {
        var cx = bossGlow.pixels.width  / 2;
        var cy = bossGlow.pixels.height / 2;
        var r  = 38;
        for (px in 0...bossGlow.pixels.width)
        {
            for (py in 0...bossGlow.pixels.height)
            {
                var dx   = px - cx;
                var dy   = py - cy;
                var dist = Math.sqrt(dx * dx + dy * dy);
                if (dist <= r)
                {
                    var a:Float = (1 - dist / r) * 0.35;
                    var col = FlxColor.fromRGB(255, 80, 100);
                    col.alphaFloat = a;
                    bossGlow.pixels.setPixel32(px, py, col);
                }
            }
        }
        bossGlow.dirty = true;
    }

    // ==================== UI ====================

    function createUI():Void
    {
        // Painel lateral
        uiPanel = new FlxSprite(PLAY_X + PLAY_W + 2, 0).makeGraphic(
            Std.int(FlxG.width - PLAY_W - PLAY_X - 2), FlxG.height,
            FlxColor.fromRGB(6, 6, 16)
        );
        add(uiPanel);

        var uiX:Float = PLAY_X + PLAY_W + 14;
        var panelW    = FlxG.width - Std.int(PLAY_W) - Std.int(PLAY_X) - 28;

        // Título do jogo
        var gameTitle = new FlxText(uiX, 14, panelW, "Kareshi Project");
        gameTitle.setFormat(null, 14, FlxColor.fromRGB(160, 160, 220), "center");
        gameTitle.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 1);
        add(gameTitle);

        var divider = new FlxSprite(uiX, 34).makeGraphic(panelW, 1, FlxColor.fromRGB(40, 40, 80));
        add(divider);

        // Score
        var scoreLabel = new FlxText(uiX, 44, panelW, "SCORE");
        scoreLabel.setFormat(null, 11, FlxColor.fromRGB(140, 140, 200), "left");
        add(scoreLabel);

        scoreText = new FlxText(uiX, 56, panelW, "0");
        scoreText.setFormat(null, 18, FlxColor.WHITE, "right");
        scoreText.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 2);
        add(scoreText);

        // Vidas
        var livesLabel = new FlxText(uiX, 90, panelW, "LIVES");
        livesLabel.setFormat(null, 11, FlxColor.fromRGB(140, 140, 200), "left");
        add(livesLabel);

        livesText = new FlxText(uiX, 102, panelW, "♥ ♥ ♥");
        livesText.setFormat(null, 20, FlxColor.fromRGB(255, 80, 100), "left");
        livesText.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 2);
        add(livesText);

        // Bombas
        var bombsLabel = new FlxText(uiX, 136, panelW, "BOMBS");
        bombsLabel.setFormat(null, 11, FlxColor.fromRGB(140, 140, 200), "left");
        add(bombsLabel);

        bombsText = new FlxText(uiX, 148, panelW, "✦ ✦ ✦");
        bombsText.setFormat(null, 20, FlxColor.fromRGB(80, 180, 255), "left");
        bombsText.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 2);
        add(bombsText);

        // Graze
        var grazeLabel = new FlxText(uiX, 182, panelW, "GRAZE");
        grazeLabel.setFormat(null, 11, FlxColor.fromRGB(140, 140, 200), "left");
        add(grazeLabel);

        grazeText = new FlxText(uiX, 194, panelW, "0");
        grazeText.setFormat(null, 16, FlxColor.YELLOW, "right");
        grazeText.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 2);
        add(grazeText);

        // Dificuldade
        var diff = new FlxSprite(uiX, 230).makeGraphic(panelW, 1, FlxColor.fromRGB(40, 40, 80));
        add(diff);

        diffText = new FlxText(uiX, 238, panelW, "EASY");
        diffText.setFormat(null, 13, FlxColor.fromRGB(100, 255, 120), "center");
        add(diffText);

        // HP bar do boss
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

        // Hint desktop
        #if desktop
        focusHint = new FlxText(PLAY_X, PLAY_Y + playH() + 4, PLAY_W, "Z: Shoot   X: Bomb   Shift: Focus   ESC: Pause");
        focusHint.setFormat(null, 11, FlxColor.fromRGBFloat(1, 1, 1, 0.45), "center");
        add(focusHint);
        #end
    }

    // ==================== Mobile UI ====================

    #if mobile
    function createMobileUI():Void
    {
        // Botão pause (canto superior direito)
        pauseButton = new FlxSprite(FlxG.width - 52, 8);
        pauseButton.loadGraphic("images/mobile/pause.png");
        pauseButton.setGraphicSize(40, 40);
        pauseButton.updateHitbox();
        pauseButton.scrollFactor.set(0, 0);
        add(pauseButton);

        // Joystick base
        joystickBG = new FlxSprite(0, 0).makeGraphic(
            Std.int(JOYSTICK_RADIUS * 2 + 20),
            Std.int(JOYSTICK_RADIUS * 2 + 20),
            FlxColor.TRANSPARENT
        );
        drawCircleSprite(joystickBG, JOYSTICK_RADIUS + 10, JOYSTICK_RADIUS, FlxColor.fromRGBFloat(1, 1, 1, 0.15), false);
        joystickBG.scrollFactor.set(0, 0);
        joystickBG.visible = false;
        add(joystickBG);

        // Joystick knob
        joystickKnob = new FlxSprite(0, 0).makeGraphic(
            Std.int(KNOB_RADIUS * 2 + 4),
            Std.int(KNOB_RADIUS * 2 + 4),
            FlxColor.TRANSPARENT
        );
        drawCircleSprite(joystickKnob, KNOB_RADIUS + 2, KNOB_RADIUS, FlxColor.fromRGBFloat(0.6, 0.8, 1, 0.7), true);
        joystickKnob.scrollFactor.set(0, 0);
        joystickKnob.visible = false;
        add(joystickKnob);

        // Botão Shoot
        shootButton = makeMobileButton(FlxG.width - 110, FlxG.height - 80, "SHOT", FlxColor.fromRGB(100, 200, 255));
        add(shootButton);

        // Botão Focus
        focusButton = makeMobileButton(FlxG.width - 55, FlxG.height - 130, "FOCUS", FlxColor.fromRGB(255, 220, 80));
        add(focusButton);

        // Botão Bomb
        bombButton = makeMobileButton(FlxG.width - 55, FlxG.height - 55, "BOMB", FlxColor.fromRGB(255, 100, 100));
        add(bombButton);
    }

    function makeMobileButton(x:Float, y:Float, label:String, col:FlxColor):FlxSprite
    {
        var btn = new FlxSprite(x, y).makeGraphic(48, 48, FlxColor.TRANSPARENT);
        var r   = 22;
        var cx  = btn.pixels.width  / 2;
        var cy  = btn.pixels.height / 2;
        for (px in 0...btn.pixels.width)
        {
            for (py in 0...btn.pixels.height)
            {
                var dx   = px - cx;
                var dy   = py - cy;
                var dist = Math.sqrt(dx * dx + dy * dy);
                if (dist <= r)
                {
                    var c = FlxColor.interpolate(FlxColor.WHITE, col, dist / r);
                    c.alphaFloat = dist <= r - 2 ? 0.75 : 0.4;
                    btn.pixels.setPixel32(px, py, c);
                }
            }
        }
        btn.dirty = true;
        btn.scrollFactor.set(0, 0);

        var txt = new FlxText(x, y + 14, 48, label);
        txt.setFormat(null, 10, FlxColor.WHITE, "center");
        txt.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 1);
        txt.scrollFactor.set(0, 0);
        add(txt);

        return btn;
    }

    function drawCircleSprite(sprite:FlxSprite, cx:Float, cy:Float, r:Float, col:FlxColor, filled:Bool):Void
    {
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
                    var a:Float = filled ? (1 - dist / r) * col.alphaFloat : col.alphaFloat;
                    var c:FlxColor = col;
                    c.alphaFloat = a;
                    sprite.pixels.setPixel32(px, py, c);
                }
            }
        }
        sprite.dirty = true;
    }
    #end

    // ==================== Update ====================

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        if (gameOver || bossDefeated) return;

        // Pause
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
        bossGlow.x = boss.x + boss.width  / 2 - bossGlow.width  / 2;
        bossGlow.y = boss.y + boss.height / 2 - bossGlow.height / 2;
        bossGlow.alpha = 0.6 + Math.sin(haxe.Timer.stamp() * 3) * 0.4;
    }

    // ==================== Mobile Input ====================

    #if mobile
    function handleMobileInput(elapsed:Float):Void
    {
        mobileShoot = false;
        mobileFocus = false;
        mobileBomb  = false;

        var leftHalf = FlxG.width / 2;

        for (touch in FlxG.touches.justStarted())
        {
            // Pause button
            if (pauseButton.overlapsPoint(touch.getWorldPosition()))
            {
                paused = true;
                openSubState(new substates.PauseSubState());
                return;
            }

            // Joystick inicia no lado esquerdo
            if (touch.screenX < leftHalf)
            {
                joystickTouchID = touch.touchPointID;
                joystickBaseX   = touch.screenX;
                joystickBaseY   = touch.screenY;
                joystickBG.x    = joystickBaseX - JOYSTICK_RADIUS - 10;
                joystickBG.y    = joystickBaseY - JOYSTICK_RADIUS - 10;
                joystickKnob.x  = joystickBaseX - KNOB_RADIUS - 2;
                joystickKnob.y  = joystickBaseY - KNOB_RADIUS - 2;
                joystickBG.visible  = true;
                joystickKnob.visible = true;
            }
        }

        // Movimento do joystick
        var joyX:Float = 0;
        var joyY:Float = 0;

        for (touch in FlxG.touches.list)
        {
            if (touch.touchPointID == joystickTouchID)
            {
                var dx = touch.screenX - joystickBaseX;
                var dy = touch.screenY - joystickBaseY;
                var dist = Math.sqrt(dx * dx + dy * dy);

                if (dist > JOYSTICK_RADIUS)
                {
                    dx = dx / dist * JOYSTICK_RADIUS;
                    dy = dy / dist * JOYSTICK_RADIUS;
                }

                joyX = dx / JOYSTICK_RADIUS;
                joyY = dy / JOYSTICK_RADIUS;

                joystickKnob.x = joystickBaseX + dx - KNOB_RADIUS - 2;
                joystickKnob.y = joystickBaseY + dy - KNOB_RADIUS - 2;
            }

            // Botões do lado direito
            if (shootButton.overlapsPoint(touch.getWorldPosition())) mobileShoot = true;
            if (focusButton.overlapsPoint(touch.getWorldPosition())) mobileFocus = true;
            if (bombButton.overlapsPoint(touch.getWorldPosition()))  mobileBomb  = true;
        }

        // Joystick released
        for (touch in FlxG.touches.justReleased())
        {
            if (touch.touchPointID == joystickTouchID)
            {
                joystickTouchID = -1;
                joystickBG.visible   = false;
                joystickKnob.visible = false;
                joyX = 0;
                joyY = 0;
            }
        }

        // Aplica movimento do joystick ao player
        var spd = mobileFocus ? player.focusSpeed : player.moveSpeed;
        player.velocity.set(joyX * spd, joyY * spd);

        player.x = Math.max(PLAY_X, Math.min(PLAY_X + PLAY_W - player.width,  player.x));
        player.y = Math.max(PLAY_Y, Math.min(PLAY_Y + playH() - player.height, player.y));

        // Anel de foco
        player.focusRing.exists  = mobileFocus;
        player.hitboxSprite.exists = mobileFocus;
        if (mobileFocus)
        {
            player.focusRing.x = player.x + (player.width  - player.focusRing.width)  / 2;
            player.focusRing.y = player.y + (player.height - player.focusRing.height) / 2;
            player.focusRing.angle += 60 * (1 / 60);

            player.hitboxSprite.x = player.x + (player.width  - player.hitboxSprite.width)  / 2;
            player.hitboxSprite.y = player.y + (player.height - player.hitboxSprite.height) / 2;
        }
    }
    #end

    // ==================== Player Movement ====================

    function handlePlayerMovement(elapsed:Float):Void
    {
        #if mobile
        // Movimento já tratado em handleMobileInput
        #else
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
            player.focusRing.exists = true;
            player.focusRing.x = player.x + (player.width  - player.focusRing.width)  / 2;
            player.focusRing.y = player.y + (player.height - player.focusRing.height) / 2;
            player.focusRing.angle += 90 * elapsed;

            player.hitboxSprite.x = player.x + (player.width  - player.hitboxSprite.width)  / 2;
            player.hitboxSprite.y = player.y + (player.height - player.hitboxSprite.height) / 2;
        }
        #end
    }

    // ==================== Player Shoot ====================

    function handlePlayerShoot(elapsed:Float):Void
    {
        player.shootCooldown -= elapsed;

        #if desktop
        var shooting  = controls.pressed(Action.SHOOT);
        var isFocused = controls.pressed(Action.FOCUS);
        #else
        var shooting  = mobileShoot;
        var isFocused = mobileFocus;
        #end

        if (shooting && player.shootCooldown <= 0)
        {
            player.shootCooldown = isFocused ? 0.06 : 0.09;

            var bx = player.x + player.width  / 2;
            var by = player.y;

            if (isFocused)
            {
                // Tiro concentrado: 3 balas centrais mais fortes
                playerBullets.fire(bx,     by, -90, 650, FlxColor.fromRGB(220, 255, 255), true, 4);
                playerBullets.fire(bx - 4, by, -90, 640, FlxColor.fromRGB(180, 230, 255), true, 3);
                playerBullets.fire(bx + 4, by, -90, 640, FlxColor.fromRGB(180, 230, 255), true, 3);
            }
            else
            {
                // Tiro espalhado: 5 balas em leque
                playerBullets.fire(bx,      by, -90,  560, FlxColor.fromRGB(100, 220, 255), true, 4);
                playerBullets.fire(bx - 10, by, -93,  540, FlxColor.fromRGB(80,  200, 255), true, 3);
                playerBullets.fire(bx + 10, by, -87,  540, FlxColor.fromRGB(80,  200, 255), true, 3);
                playerBullets.fire(bx - 22, by, -98,  510, FlxColor.fromRGB(60,  180, 255), true, 3);
                playerBullets.fire(bx + 22, by, -82,  510, FlxColor.fromRGB(60,  180, 255), true, 3);
            }
        }
    }

    // ==================== Boss ====================

    function handleBoss(elapsed:Float):Void
    {
        bossSwingAngle += elapsed * 55;
        boss.x = PLAY_X + PLAY_W / 2 - boss.width / 2
            + Math.sin(bossSwingAngle * Math.PI / 180) * 140;

        bossPatternTimer += elapsed;
        var patternDuration = bossPhase == 0 ? 7.0 : 5.0;
        if (bossPatternTimer >= patternDuration)
        {
            bossPatternTimer = 0;
            bossPattern      = (bossPattern + 1) % (bossPhase == 0 ? 4 : 5);
            bossWaveAngle    = 0;
        }

        // Fase 2 quando HP < 50%
        if (bossHP <= bossHPMax * 0.5 && bossPhase == 0)
        {
            bossPhase = 1;
            boss.color = FlxColor.fromRGB(255, 150, 50);
            FlxFlicker.flicker(boss, 0.8, 0.06);
        }

        bossFireTimer += elapsed;
        var baseRate:Float  = bossPhase == 0 ? 0.10 : 0.07;
        var fireRate:Float  = baseRate - (1 - bossHP / bossHPMax) * 0.04;

        if (bossFireTimer >= fireRate)
        {
            bossFireTimer = 0;
            fireBossPattern();
        }
    }

    function fireBossPattern():Void
    {
        var cx = boss.x + boss.width  / 2;
        var cy = boss.y + boss.height / 2;
        var phase2 = bossPhase == 1;

        switch (bossPattern)
        {
            // Círculo pulsante
            case 0:
                var count = phase2 ? 20 : 14;
                for (i in 0...count)
                {
                    var a = (360 / count) * i + bossWaveAngle;
                    var spd = phase2 ? 160 : 130;
                    enemyBullets.fire(cx, cy, a, spd, FlxColor.fromRGB(255, 80, 100), false, 5);
                }
                bossWaveAngle += phase2 ? 7 : 5;

            // Espiral tripla
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

            // Leque direcionado ao player
            case 2:
                var toPlayer = FlxAngle.angleBetween(boss, player, true);
                var spread   = phase2 ? 50 : 38;
                var count    = phase2 ? 9  : 7;
                for (i in 0...count)
                {
                    var a = toPlayer - spread + (spread * 2 / (count - 1)) * i;
                    enemyBullets.fire(cx, cy, a, phase2 ? 220 : 190, FlxColor.fromRGB(200, 80, 255), false, 4);
                }

            // Anel lento denso
            case 3:
                var count = phase2 ? 32 : 24;
                for (i in 0...count)
                {
                    var a = (360 / count) * i + bossWaveAngle;
                    enemyBullets.fire(cx, cy, a, phase2 ? 110 : 85, FlxColor.fromRGB(80, 200, 255), false, 6);
                }
                bossWaveAngle += phase2 ? 4 : 3;

            // Fase 2 exclusivo: chuva de balas
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
            bossHP -= phase2Multiplier();
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

    function phase2Multiplier():Float
    {
        return bossPhase == 0 ? 1 : 1.5;
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
                    FlxTween.tween(grazeText, {alpha: 0}, 0.4, {ease: FlxEase.quartIn});
                }
            }
        }
    }

    // ==================== UI ====================

    function updateUI():Void
    {
        scoreText.text = Std.string(score).lpad("0", 8);

        var livesStr = "";
        for (_ in 0...player.lives) livesStr += "♥ ";
        livesText.text = livesStr == "" ? "—" : livesStr;

        var bombsStr = "";
        for (_ in 0...player.bombs) bombsStr += "✦ ";
        bombsText.text = bombsStr == "" ? "—" : bombsStr;

        grazeText.text = Std.string(graze).lpad("0", 4);

        var ratio = Math.max(0, bossHP / bossHPMax);
        bossHPBar.scale.x      = ratio;
        bossHPBarGlow.scale.x  = ratio;
        bossHPBar.x            = PLAY_X;
        bossHPBarGlow.x        = PLAY_X;

        // Cor da barra por fase
        bossHPBar.color = bossPhase == 0
            ? FlxColor.fromRGB(220, 60,  80)
            : FlxColor.fromRGB(255, 140, 40);
    }

    // ==================== Events ====================

    function triggerBossDeath():Void
    {
        bossDefeated = true;
        boss.exists      = false;
        bossGlow.exists  = false;
        score           += 50000;

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
        FlxTween.tween(bonusText, {alpha: 1}, 0.6, {ease: FlxEase.quartOut, startDelay: 0.3,
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
        FlxTween.tween(scoreOver, {alpha: 1}, 0.6, {ease: FlxEase.quartOut, startDelay: 0.3,
            onComplete: function(_)
            {
                new FlxTimer().start(3, function(_)
                    FlxG.switchState(new menus.MainMenuState()));
            }
        });
    }
}