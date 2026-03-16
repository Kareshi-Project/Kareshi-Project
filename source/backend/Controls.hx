package backend;

import flixel.FlxG;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;

enum abstract Action(Int)
{
    var UP      = 0;
    var DOWN    = 1;
    var LEFT    = 2;
    var RIGHT   = 3;
    var SHOOT   = 4;
    var BOMB    = 5;
    var FOCUS   = 6;
    var PAUSE   = 7;
    var BACK    = 8;
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

    function new() {}

    // ==================== Gamepad helper ====================

    static function pad():FlxGamepad
    {
        return FlxG.gamepads.firstActive;
    }

    // ==================== Pressed ====================

    public function pressed(action:Action):Bool
    {
        #if desktop
        if (keyboardPressed(action))   return true;
        if (gamepadPressed(action))    return true;
        return false;
        #elseif mobile
        return touchPressed(action);
        #else
        return false;
        #end
    }

    // ==================== Just Pressed ====================

    public function justPressed(action:Action):Bool
    {
        #if desktop
        if (keyboardJustPressed(action)) return true;
        if (gamepadJustPressed(action))  return true;
        return false;
        #elseif mobile
        return touchJustPressed(action);
        #else
        return false;
        #end
    }

    // ==================== Just Released ====================

    public function justReleased(action:Action):Bool
    {
        #if desktop
        if (keyboardJustReleased(action)) return true;
        if (gamepadJustReleased(action))  return true;
        return false;
        #else
        return false;
        #end
    }

    // ==================== Keyboard ====================

    #if desktop
    function keyboardPressed(action:Action):Bool
    {
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
    }

    function keyboardJustPressed(action:Action):Bool
    {
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
    }

    function keyboardJustReleased(action:Action):Bool
    {
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
    }
    #end

    // ==================== Gamepad ====================

    #if desktop
    function gamepadPressed(action:Action):Bool
    {
        var gp = pad();
        if (gp == null) return false;

        return switch (action)
        {
            // D-Pad + Analógico esquerdo
            case UP:
                gp.pressed.DPAD_UP
                || gp.pressed.LEFT_STICK_DIGITAL_UP;
            case DOWN:
                gp.pressed.DPAD_DOWN
                || gp.pressed.LEFT_STICK_DIGITAL_DOWN;
            case LEFT:
                gp.pressed.DPAD_LEFT
                || gp.pressed.LEFT_STICK_DIGITAL_LEFT;
            case RIGHT:
                gp.pressed.DPAD_RIGHT
                || gp.pressed.LEFT_STICK_DIGITAL_RIGHT;

            // Botões de ação
            // A/Cross  = Shoot
            case SHOOT:   gp.pressed.A || gp.pressed.X;
            // B/Circle = Bomb
            case BOMB:    gp.pressed.B || gp.pressed.Y;
            // Bumpers/Triggers = Focus
            case FOCUS:
                gp.pressed.LEFT_SHOULDER
                || gp.pressed.RIGHT_SHOULDER
                || gp.getAxis(FlxGamepadInputID.LEFT_TRIGGER)  > 0.3
                || gp.getAxis(FlxGamepadInputID.RIGHT_TRIGGER) > 0.3;

            case PAUSE:   false;
            case BACK:    false;
            case CONFIRM: false;
        };
    }

    function gamepadJustPressed(action:Action):Bool
    {
        var gp = pad();
        if (gp == null) return false;

        return switch (action)
        {
            case UP:
                gp.justPressed.DPAD_UP
                || gp.justPressed.LEFT_STICK_DIGITAL_UP;
            case DOWN:
                gp.justPressed.DPAD_DOWN
                || gp.justPressed.LEFT_STICK_DIGITAL_DOWN;
            case LEFT:
                gp.justPressed.DPAD_LEFT
                || gp.justPressed.LEFT_STICK_DIGITAL_LEFT;
            case RIGHT:
                gp.justPressed.DPAD_RIGHT
                || gp.justPressed.LEFT_STICK_DIGITAL_RIGHT;

            case SHOOT:   gp.justPressed.A || gp.justPressed.X;
            case BOMB:    gp.justPressed.B || gp.justPressed.Y;
            case FOCUS:
                gp.justPressed.LEFT_SHOULDER
                || gp.justPressed.RIGHT_SHOULDER;

            // Start / Options = Pause
            case PAUSE:   gp.justPressed.START;
            // Select / Share = Back
            case BACK:    gp.justPressed.BACK || gp.justPressed.GUIDE;
            // A/Cross = Confirm
            case CONFIRM: gp.justPressed.A;
        };
    }

    function gamepadJustReleased(action:Action):Bool
    {
        var gp = pad();
        if (gp == null) return false;

        return switch (action)
        {
            case UP:      gp.justReleased.DPAD_UP    || gp.justReleased.LEFT_STICK_DIGITAL_UP;
            case DOWN:    gp.justReleased.DPAD_DOWN  || gp.justReleased.LEFT_STICK_DIGITAL_DOWN;
            case LEFT:    gp.justReleased.DPAD_LEFT  || gp.justReleased.LEFT_STICK_DIGITAL_LEFT;
            case RIGHT:   gp.justReleased.DPAD_RIGHT || gp.justReleased.LEFT_STICK_DIGITAL_RIGHT;
            case SHOOT:   gp.justReleased.A || gp.justReleased.X;
            case BOMB:    gp.justReleased.B || gp.justReleased.Y;
            case FOCUS:   gp.justReleased.LEFT_SHOULDER || gp.justReleased.RIGHT_SHOULDER;
            case PAUSE:   gp.justReleased.START;
            case BACK:    gp.justReleased.BACK;
            case CONFIRM: gp.justReleased.A;
        };
    }
    #end

    // ==================== Mobile Touch ====================

    #if mobile
    function touchPressed(action:Action):Bool
    {
        var touches = FlxG.touches.list;
        if (touches.length == 0) return false;

        return switch (action)
        {
            case SHOOT:   touches.length >= 1;
            case BOMB:    touches.length >= 2;
            case FOCUS:   touches.length >= 3;
            case UP:      touches[0].screenY < FlxG.height * 0.4;
            case DOWN:    touches[0].screenY > FlxG.height * 0.6;
            case LEFT:    touches[0].screenX < FlxG.width  * 0.4;
            case RIGHT:   touches[0].screenX > FlxG.width  * 0.6;
            default:      false;
        };
    }

    function touchJustPressed(action:Action):Bool
    {
        var started = FlxG.touches.justStarted();
        if (started.length == 0) return false;

        return switch (action)
        {
            case CONFIRM: started.length >= 1;
            case BACK:    started.length >= 2;
            case PAUSE:   started.length >= 3;
            default:      false;
        };
    }
    #end

    // ==================== Helpers ====================

    public function anyDirectional():Bool
    {
        return pressed(UP) || pressed(DOWN) || pressed(LEFT) || pressed(RIGHT);
    }

    public function getMovement():{ x:Float, y:Float }
    {
        var mx:Float = 0;
        var my:Float = 0;

        #if desktop
        // Analógico esquerdo tem prioridade sobre D-Pad/teclado
        var gp = pad();
        if (gp != null)
        {
            var ax = gp.getXAxis(FlxGamepadInputID.LEFT_ANALOG_STICK);
            var ay = gp.getYAxis(FlxGamepadInputID.LEFT_ANALOG_STICK);

            // Dead zone
            if (Math.abs(ax) > 0.15) mx = ax;
            if (Math.abs(ay) > 0.15) my = ay;
        }

        // Teclado / D-Pad se analógico não está sendo usado
        if (mx == 0 && my == 0)
        {
            if (pressed(LEFT))  mx -= 1;
            if (pressed(RIGHT)) mx += 1;
            if (pressed(UP))    my -= 1;
            if (pressed(DOWN))  my += 1;
        }
        #end

        // Normaliza diagonal
        if (mx != 0 && my != 0)
        {
            mx *= 0.7071;
            my *= 0.7071;
        }

        return { x: mx, y: my };
    }

    public function applyFocus(speed:Float):Float
    {
        return pressed(FOCUS) ? speed * 0.5 : speed;
    }

    public function isGamepadConnected():Bool
    {
        #if desktop
        return pad() != null;
        #else
        return false;
        #end
    }

    public function getGamepadName():String
    {
        #if desktop
        var gp = pad();
        return gp != null ? gp.name : "None";
        #else
        return "None";
        #end
    }
}