package uty.components;

import flixel.math.FlxRect;
import flixel.math.FlxPoint;

class Collision extends FlxRect
{
    //a component to give to objects and sprites to allow for collision checks.
    //if this is false then any COLLISION related stuff should be ignored
    //maybe im confusing "collision" with hitboxes but whatever
    public var enableCollide:Bool = true;
    public var isTrigger:Bool = false; //if true, the player can enter the object, but something happens when they do
    public var hbOffset:FlxPoint;

    public function new(x:Float, y:Float, width:Float, height:Float, ?offsetX:Int = 0, ?offsetY:Int = 0)
    {
        super(x, y, width, height);
        hbOffset = new FlxPoint(offsetX, offsetY);
    }

    public function checkOverlap(hitbox:FlxSprite):Bool
        {
            //generic in-bounds check. returns true if player is overlapping this loading zone.
            if(hitbox.x + hitbox.width > this.left && hitbox.x < this.right) //horizontal check
            {
                if(hitbox.y + hitbox.height > this.top && hitbox.y < this.bottom) //vertical check
                {
                    return true;
                }
                else
                    return false;
            }
            else
                return false;
        }
}