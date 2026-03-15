package backend;

import flixel.FlxG;
import flixel.input.touch.FlxTouch;

enum abstract Action(Int)
{
    var UP     = 0;
    var DOWN   = 1;
    var LEFT   = 2;
    var RIGHT  = 3;
    var SHOOT  = 4;
    var BOMB   = 5;
    var FOCUS  = 6;
    var PAUSE  = 7;
    var BACK   = 8;
    var CONFIRM = 9;
}

class Controls
{
    // ==================== Singleton ====================
    static var _instance:Controls;
    public static var instance(get, never):Controls;
    static function get_instance():Controls
    {
        if (_instance == null)
            _instance = new Controls();
        return _instance;
    }

    // ==================== Touch state (mobile) ====================
    var _touchDown:Bool  = false;
    var _touchX:Float    = 0;
    var _touchY:Float    = 0;

    // Dead zone para swipe
    static final SWIPE_THRESHOLD:Float = 30;

    // ==================== Constructor ====================
    function new() {}

    // ==================== Desktop: Pressed (held) ====================

    public function pressed(action:Action):Bool
    {
        #if desktop
        return switch (action)
        {
            case UP:      FlxG.keys.pressed.UP    || FlxG.keys.pressed.W;
            case DOWN:    FlxG.keys.pressed.DOWN  || FlxG.keys.pressed.S;
            case LEFT:    FlxG.keys.pressed.LEFT  || FlxG.keys.pressed.A;
            case RIGHT:   FlxG.keys.pressed.RIGHT || FlxG.keys.pressed.D;
            case SHOOT:   FlxG.keys.pressed.Z;
            case BOMB:    FlxG.keys.pressed.X;
            case FOCUS:   FlxG.keys.pressed.SHIFT;
            case PAUSE:   false;
            case BACK:    false;
            case CONFIRM: false;
        };
        #elseif mobile
        return touchPressed(action);
        #else
        return false;
        #end
    }

    // ==================== Desktop: Just Pressed (single frame) ====================

    public function justPressed(action:Action):Bool
    {
        #if desktop
        return switch (action)
        {
            case UP:      FlxG.keys.justPressed.UP    || FlxG.keys.justPressed.W;
            case DOWN:    FlxG.keys.justPressed.DOWN  || FlxG.keys.justPressed.S;
            case LEFT:    FlxG.keys.justPressed.LEFT  || FlxG.keys.justPressed.A;
            case RIGHT:   FlxG.keys.justPressed.RIGHT || FlxG.keys.justPressed.D;
            case SHOOT:   FlxG.keys.justPressed.Z;
            case BOMB:    FlxG.keys.justPressed.X;
            case FOCUS:   FlxG.keys.justPressed.SHIFT;
            case PAUSE:   FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.P;
            case BACK:    FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.X;
            case CONFIRM: FlxG.keys.justPressed.ENTER  || FlxG.keys.justPressed.Z;
        };
        #elseif mobile
        return touchJustPressed(action);
        #else
        return false;
        #end
    }

    // ==================== Desktop: Just Released ====================

    public function justReleased(action:Action):Bool
    {
        #if desktop
        return switch (action)
        {
            case UP:      FlxG.keys.justReleased.UP    || FlxG.keys.justReleased.W;
            case DOWN:    FlxG.keys.justReleased.DOWN  || FlxG.keys.justReleased.S;
            case LEFT:    FlxG.keys.justReleased.LEFT  || FlxG.keys.justReleased.A;
            case RIGHT:   FlxG.keys.justReleased.RIGHT || FlxG.keys.justReleased.D;
            case SHOOT:   FlxG.keys.justReleased.Z;
            case BOMB:    FlxG.keys.justReleased.X;
            case FOCUS:   FlxG.keys.justReleased.SHIFT;
            case PAUSE:   FlxG.keys.justReleased.ESCAPE || FlxG.keys.justReleased.P;
            case BACK:    FlxG.keys.justReleased.ESCAPE || FlxG.keys.justReleased.X;
            case CONFIRM: FlxG.keys.justReleased.ENTER  || FlxG.keys.justReleased.Z;
        };
        #elseif mobile
        return false;
        #else
        return false;
        #end
    }

    // ==================== Mobile Touch ====================

    function touchPressed(action:Action):Bool
    {
        #if mobile
        var touches = FlxG.touches.list;
        if (touches.length == 0) return false;

        return switch (action)
        {
            // Qualquer toque ativo = shoot
            case SHOOT:   touches.length >= 1;
            // Dois dedos = bomb
            case BOMB:    touches.length >= 2;
            // Três dedos = focus
            case FOCUS:   touches.length >= 3;
            // Movimento por posição do primeiro toque
            case UP:      touches[0].screenY < FlxG.height * 0.4;
            case DOWN:    touches[0].screenY > FlxG.height * 0.6;
            case LEFT:    touches[0].screenX < FlxG.width  * 0.4;
            case RIGHT:   touches[0].screenX > FlxG.width  * 0.6;
            default:      false;
        };
        #else
        return false;
        #end
    }

    function touchJustPressed(action:Action):Bool
    {
        #if mobile
        var started = FlxG.touches.justStarted();
        if (started.length == 0) return false;

        return switch (action)
        {
            case CONFIRM: started.length >= 1;
            case BACK:    started.length >= 2;
            case PAUSE:   started.length >= 3;
            default:      false;
        };
        #else
        return false;
        #end
    }

    // ==================== Helpers ====================

    /** Retorna true se qualquer direção está pressionada */
    public function anyDirectional():Bool
    {
        return pressed(UP) || pressed(DOWN) || pressed(LEFT) || pressed(RIGHT);
    }

    /** Retorna o vetor de movimento normalizado */
    public function getMovement():{ x:Float, y:Float }
    {
        var mx:Float = 0;
        var my:Float = 0;

        if (pressed(LEFT))  mx -= 1;
        if (pressed(RIGHT)) mx += 1;
        if (pressed(UP))    my -= 1;
        if (pressed(DOWN))  my += 1;

        // Normaliza diagonal
        if (mx != 0 && my != 0)
        {
            mx *= 0.7071;
            my *= 0.7071;
        }

        return { x: mx, y: my };
    }

    /** Velocidade modificada pelo foco (focus mode = metade da velocidade) */
    public function applyFocus(speed:Float):Float
    {
        return pressed(FOCUS) ? speed * 0.5 : speed;
    }
}
