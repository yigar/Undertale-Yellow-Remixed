package uty.objects;

import flixel.math.FlxRect;
import flixel.math.FlxMath;

class Parallelogram extends FlxRect
{
    //top-left is the base point

    //the rise-over-run to augment the horizontal lines by.
    public var slope:Float;

    public function new(x:Float = 0, y:Float = 0, width:Float = 0, height:Float = 0, slope:Float = 0)
    {
        super(x, y, width, height);
        this.slope = slope;
    }

    public inline function overlapsPara(rect:FlxRect):Bool
    {
        var result = rect.right > left && rect.left < right;
        if (!(rect.bottom > top) && !containsXYPara(rect.right, rect.bottom))
            result = false;
        if (!(rect.top < bottom) && !containsXYPara(rect.right, rect.top))
            result = false;
        rect.putWeak();
        return result;
    }

	public inline function containsXYPara(xPos:Float, yPos:Float):Bool
    {
        yPos += ((xPos - left) * slope);

       return xPos >= left && xPos <= right && yPos >= top && yPos <= bottom;
    }
}