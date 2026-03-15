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

// ==================== Bullet ====================
class Bullet extends FlxSprite
{
    public var speed:Float     = 300;
    public var moveAngle:Float = 0;
    public var isPlayer:Bool   = false;

    public function new()
    {
        super();
        makeGraphic(8, 8, FlxColor.WHITE);
        exists = false;
    }

    public function fire(x:Float, y:Float, fireAngle:Float, spd:Float, col:FlxColor, fromPlayer:Bool = false):Void
    {
        isPlayer  = fromPlayer;
        speed     = spd;
        moveAngle = fireAngle;
        color     = col;
        setPosition(x - width / 2, y - height / 2);
        velocity.set(
            Math.cos(fireAngle * Math.PI / 180) * spd,
            Math.sin(fireAngle * Math.PI / 180) * spd
        );
        exists = true;
        alive  = true;
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);
        if (x < -50 || x > FlxG.width + 50 || y < -50 || y > FlxG.height + 50)
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

    public function fire(x:Float, y:Float, fireAngle:Float, spd:Float, col:FlxColor, fromPlayer:Bool = false):Bullet
    {
        var b:Bullet = cast getFirstDead();
        if (b != null)
            b.fire(x, y, fireAngle, spd, col, fromPlayer);
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

    public function new(x:Float, y:Float)
    {
        super(x, y);
        makeGraphic(24, 32, FlxColor.CYAN);

        setSize(6, 6);
        centerOffsets();

        hitboxSprite = new FlxSprite();
        hitboxSprite.makeGraphic(6, 6, FlxColor.WHITE);
        hitboxSprite.exists = false;
    }

    public function takeDamage():Bool
    {
        if (invincible) return false;

        lives--;
        invincible = true;

        FlxFlicker.flicker(this, 2.0, 0.15, true, true, function(_)
        {
            invincible = false;
        });

        return lives <= 0;
    }
}

// ==================== PlayState ====================
class PlayState extends FlxState
{
    var player:Player;
    var playerBullets:BulletPool;
    var enemyBullets:BulletPool;

    var boss:FlxSprite;
    var bossHP:Float           = 100;
    var bossHPMax:Float        = 100;
    var bossSwingAngle:Float   = 0;
    var bossPatternTimer:Float = 0;
    var bossPattern:Int        = 0;
    var bossFireTimer:Float    = 0;
    var bossWaveAngle:Float    = 0;

    var starLayers:Array<Array<FlxSprite>> = [];
    var bgScrollSpeeds:Array<Float>        = [20, 40, 70];

    var scoreText:FlxText;
    var livesText:FlxText;
    var bombsText:FlxText;
    var bossHPBar:FlxSprite;
    var bossHPBarBG:FlxSprite;
    var focusHint:FlxText;
    var grazeText:FlxText;

    var score:Int        = 0;
    var graze:Int        = 0;
    var grazeTimer:Float = 0;

    var controls:Controls;
    var gameOver:Bool = false;
    var paused:Bool   = false;

    static final PLAY_X:Float = 32;
    static final PLAY_Y:Float = 16;
    static final PLAY_W:Float = 800;
    static inline function playH():Float return FlxG.height - 32;

    // ==================== Create ====================

    override public function create():Void
    {
        super.create();

        controls = Controls.instance;
        FlxG.camera.bgColor = FlxColor.fromRGB(5, 5, 15);

        createBackground();
        createPlayer();
        createBoss();
        createUI();
    }

    function createBackground():Void
    {
        for (layer in 0...3)
        {
            var stars:Array<FlxSprite> = [];
            var count  = [80, 50, 30][layer];
            var size   = [1,  2,  3 ][layer];
            var colors = [
                FlxColor.fromRGBFloat(0.3, 0.3, 0.5),
                FlxColor.fromRGBFloat(0.5, 0.5, 0.7),
                FlxColor.fromRGBFloat(0.8, 0.8, 1.0)
            ];

            for (_ in 0...count)
            {
                var star = new FlxSprite(
                    PLAY_X + FlxG.random.float(0, PLAY_W),
                    FlxG.random.float(0, FlxG.height)
                );
                star.makeGraphic(size, size, colors[layer]);
                star.alpha = FlxG.random.float(0.4, 1.0);
                add(star);
                stars.push(star);
            }
            starLayers.push(stars);
        }
    }

    function createPlayer():Void
    {
        player = new Player(PLAY_X + PLAY_W / 2, PLAY_Y + playH() - 80);
        add(player.hitboxSprite);
        add(player);

        playerBullets = new BulletPool(200);
        add(playerBullets);

        enemyBullets = new BulletPool(1000);
        add(enemyBullets);
    }

    function createBoss():Void
    {
        boss = new FlxSprite(PLAY_X + PLAY_W / 2 - 20, -60);
        boss.makeGraphic(40, 40, FlxColor.RED);
        add(boss);

        FlxTween.tween(boss, {y: PLAY_Y + 80}, 1.5, {
            ease: FlxEase.quartOut,
            startDelay: 0.5
        });
    }

    function createUI():Void
    {
        var panel = new FlxSprite(PLAY_X + PLAY_W, 0).makeGraphic(
            Std.int(FlxG.width - PLAY_W - PLAY_X), FlxG.height,
            FlxColor.fromRGB(8, 8, 18)
        );
        add(panel);

        var uiX:Float = PLAY_X + PLAY_W + 16;

        var titleLabel = new FlxText(uiX, 20, 200, "Kareshi Project");
        titleLabel.setFormat(null, 16, FlxColor.fromRGBFloat(0.8, 0.8, 1), "left");
        add(titleLabel);

        scoreText = new FlxText(uiX, 60, 200, "Score\n0");
        scoreText.setFormat(null, 18, FlxColor.WHITE, "left");
        add(scoreText);

        livesText = new FlxText(uiX, 130, 200, "Lives\n♥ ♥ ♥");
        livesText.setFormat(null, 18, FlxColor.fromRGB(255, 80, 80), "left");
        add(livesText);

        bombsText = new FlxText(uiX, 200, 200, "Bombs\n✦ ✦ ✦");
        bombsText.setFormat(null, 18, FlxColor.fromRGB(80, 180, 255), "left");
        add(bombsText);

        bossHPBarBG = new FlxSprite(PLAY_X, PLAY_Y - 12).makeGraphic(Std.int(PLAY_W), 6, FlxColor.fromRGB(40, 40, 40));
        add(bossHPBarBG);

        bossHPBar = new FlxSprite(PLAY_X, PLAY_Y - 12).makeGraphic(Std.int(PLAY_W), 6, FlxColor.fromRGB(220, 60, 60));
        add(bossHPBar);

        grazeText = new FlxText(uiX, 270, 200, "");
        grazeText.setFormat(null, 14, FlxColor.YELLOW, "left");
        grazeText.alpha = 0;
        add(grazeText);

        focusHint = new FlxText(0, FlxG.height - 24, FlxG.width, "");
        focusHint.setFormat(null, 14, FlxColor.fromRGBFloat(1, 1, 1, 0.5), "center");
        add(focusHint);

        #if desktop
        focusHint.text = "Z: Shoot   X: Bomb   Shift: Focus";
        #end
    }

    // ==================== Update ====================

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        if (gameOver) return;

        #if desktop
        if (controls.justPressed(Action.PAUSE))
        {
            paused = !paused;
            return;
        }
        #end

        if (paused) return;

        scrollBackground(elapsed);
        handlePlayerMovement(elapsed);
        handlePlayerShoot(elapsed);
        handleBoss(elapsed);
        handleCollisions();
        handleGraze(elapsed);
        updateUI();
    }

    // ==================== Background ====================

    function scrollBackground(elapsed:Float):Void
    {
        for (layer in 0...starLayers.length)
        {
            for (star in starLayers[layer])
            {
                star.y += bgScrollSpeeds[layer] * elapsed;
                if (star.y > FlxG.height)
                    star.y = -4;
            }
        }
    }

    // ==================== Player ====================

    function handlePlayerMovement(elapsed:Float):Void
    {
        var isFocused = controls.pressed(Action.FOCUS);
        var spd       = isFocused ? player.focusSpeed : player.moveSpeed;
        var move      = controls.getMovement();

        player.velocity.set(move.x * spd, move.y * spd);

        player.x = Math.max(PLAY_X, Math.min(PLAY_X + PLAY_W - player.width,  player.x));
        player.y = Math.max(PLAY_Y, Math.min(PLAY_Y + playH() - player.height, player.y));

        player.hitboxSprite.visible = isFocused;
        if (isFocused)
        {
            player.hitboxSprite.exists = true;
            player.hitboxSprite.x = player.x + (player.width  - player.hitboxSprite.width)  / 2;
            player.hitboxSprite.y = player.y + (player.height - player.hitboxSprite.height) / 2;
        }
    }

    function handlePlayerShoot(elapsed:Float):Void
    {
        player.shootCooldown -= elapsed;

        if (controls.pressed(Action.SHOOT) && player.shootCooldown <= 0)
        {
            var isFocused = controls.pressed(Action.FOCUS);
            player.shootCooldown = isFocused ? 0.07 : 0.10;

            var bx = player.x + player.width  / 2;
            var by = player.y;

            if (isFocused)
            {
                playerBullets.fire(bx - 3, by, -90, 600, FlxColor.fromRGB(200, 255, 255), true);
                playerBullets.fire(bx + 3, by, -90, 600, FlxColor.fromRGB(200, 255, 255), true);
            }
            else
            {
                playerBullets.fire(bx,      by, -90, 550, FlxColor.CYAN,  true);
                playerBullets.fire(bx - 12, by, -92, 530, FlxColor.CYAN,  true);
                playerBullets.fire(bx + 12, by, -88, 530, FlxColor.CYAN,  true);
                playerBullets.fire(bx - 24, by, -96, 500, FlxColor.WHITE, true);
                playerBullets.fire(bx + 24, by, -84, 500, FlxColor.WHITE, true);
            }
        }
    }

    // ==================== Boss ====================

    function handleBoss(elapsed:Float):Void
    {
        bossSwingAngle += elapsed * 60;
        boss.x = PLAY_X + PLAY_W / 2 - boss.width / 2
            + Math.sin(bossSwingAngle * Math.PI / 180) * 180;

        bossPatternTimer += elapsed;
        if (bossPatternTimer >= 8)
        {
            bossPatternTimer = 0;
            bossPattern      = (bossPattern + 1) % 4;
            bossWaveAngle    = 0;
        }

        bossFireTimer += elapsed;
        var fireRate:Float = 0.08 - (1 - bossHP / bossHPMax) * 0.04;

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

        switch (bossPattern)
        {
            case 0:
                var count = 16;
                for (i in 0...count)
                {
                    var a = (360 / count) * i + bossWaveAngle;
                    enemyBullets.fire(cx, cy, a, 140, FlxColor.fromRGB(255, 100, 100));
                }
                bossWaveAngle += 5;

            case 1:
                for (k in 0...2)
                {
                    var a = bossWaveAngle + k * 180;
                    enemyBullets.fire(cx, cy, a,      180, FlxColor.fromRGB(255, 200, 50));
                    enemyBullets.fire(cx, cy, a + 30, 160, FlxColor.fromRGB(255, 150, 50));
                    enemyBullets.fire(cx, cy, a + 60, 140, FlxColor.fromRGB(255, 100, 50));
                }
                bossWaveAngle += 8;

            case 2:
                var toPlayer = FlxAngle.angleBetween(boss, player, true);
                var spread   = 40;
                var count    = 7;
                for (i in 0...count)
                {
                    var a = toPlayer - spread + (spread * 2 / (count - 1)) * i;
                    enemyBullets.fire(cx, cy, a, 200, FlxColor.fromRGB(180, 100, 255));
                }

            case 3:
                var count = 24;
                for (i in 0...count)
                {
                    var a = (360 / count) * i + bossWaveAngle;
                    enemyBullets.fire(cx, cy, a, 90, FlxColor.fromRGB(100, 200, 255));
                }
                bossWaveAngle += 3;
        }
    }

    // ==================== Colisões ====================

    function handleCollisions():Void
    {
        FlxG.overlap(playerBullets, boss, function(b:FlxObject, _)
        {
            var bullet:Bullet = cast b;
            bullet.kill();
            bossHP -= 1;
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

            if (dist < 28 && dist > 6)
            {
                graze++;
                score += 2;

                if (grazeTimer <= 0)
                {
                    grazeTimer      = 0.5;
                    grazeText.text  = "Graze! +" + graze;
                    grazeText.alpha = 1;
                    FlxTween.tween(grazeText, {alpha: 0}, 0.5, {ease: FlxEase.quartIn});
                }
            }
        }
    }

    // ==================== UI ====================

    function updateUI():Void
    {
        scoreText.text = "Score\n" + score;

        var livesStr = "";
        for (_ in 0...player.lives) livesStr += "♥ ";
        livesText.text = "Lives\n" + (livesStr == "" ? "—" : livesStr);

        var bombsStr = "";
        for (_ in 0...player.bombs) bombsStr += "✦ ";
        bombsText.text = "Bombs\n" + (bombsStr == "" ? "—" : bombsStr);

        var ratio = Math.max(0, bossHP / bossHPMax);
        bossHPBar.scale.x = ratio;
        bossHPBar.x       = PLAY_X;
    }

    // ==================== Eventos ====================

    function triggerBossDeath():Void
    {
        boss.exists = false;
        score      += 10000;

        var clear = new FlxText(0, FlxG.height / 2 - 30, FlxG.width, "Stage Clear!");
        clear.setFormat(null, 48, FlxColor.YELLOW, "center");
        clear.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 4);
        clear.alpha = 0;
        add(clear);

        FlxTween.tween(clear, {alpha: 1}, 0.5, {
            ease: FlxEase.quartOut,
            onComplete: function(_)
            {
                new FlxTimer().start(2, function(_)
                {
                    FlxG.switchState(new menus.MainMenuState());
                });
            }
        });
    }

    function triggerGameOver():Void
    {
        if (player.lives > 0) return;

        gameOver = true;

        var over = new FlxText(0, FlxG.height / 2 - 30, FlxG.width, "Game Over");
        over.setFormat(null, 48, FlxColor.RED, "center");
        over.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 4);
        over.alpha = 0;
        add(over);

        FlxTween.tween(over, {alpha: 1}, 0.6, {
            ease: FlxEase.quartOut,
            onComplete: function(_)
            {
                new FlxTimer().start(2.5, function(_)
                {
                    FlxG.switchState(new menus.MainMenuState());
                });
            }
        });
    }
}