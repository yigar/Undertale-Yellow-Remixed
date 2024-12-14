package uty.components;

//various utilities for stuff in the overworld.
class OverworldUtil
{
    public static function isPlayerCollideAfterMove(x:Float, y:Float):Array<Bool>
    {
        return isPlayerCollideAtCoords(Overworld.current.playerHitbox.x + x, Overworld.current.playerHitbox.y + y);
    }

    public static function isPlayerCollideAtCoords(x:Float, y:Float):Array<Bool>
    {
        var bumpX:Bool = false;
        var bumpY:Bool = false;
        var prevX:Float = Overworld.current.playerHitbox.x;
        var prevY:Float = Overworld.current.playerHitbox.y;
        Overworld.current.playerHitbox.x = x;
        if(Overworld.current.room.collisionGrid.overlaps(Overworld.current.playerHitbox, false, Overworld.current.camGame))
        {
            bumpX = true;
        }
        Overworld.current.playerHitbox.x = prevX;
        Overworld.current.playerHitbox.y = y;
        if(Overworld.current.room.collisionGrid.overlaps(Overworld.current.playerHitbox, false, Overworld.current.camGame))
        {
            bumpY = true;
        }
        Overworld.current.playerHitbox.y = prevY;

        return [bumpX, bumpY];
    }
}