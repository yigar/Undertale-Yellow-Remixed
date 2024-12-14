package uty.objects;

import uty.states.Overworld;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.group.FlxSpriteGroup;
import forever.display.ForeverSprite;
import flixel.math.FlxMath;
import flixel.util.FlxColor;

//an overworld object that acts as an incline, adjusting the player's Y with X movement.
class Stairs extends OverworldSprite
{
    public var parallelogram:Parallelogram;

    public function new(x:Float = 0, y:Float = 0, width:Float = 0, height:Float = 0, slope:Float = 0)
    {
        super(x, y);
        parallelogram = new Parallelogram(x, y, width, height, slope);
    }

    public function moveVertical(obj:OverworldSprite, xMove:Float)
    {
        obj.y -= (xMove * parallelogram.slope);
    }
}