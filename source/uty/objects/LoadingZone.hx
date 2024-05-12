package uty.objects;

import uty.components.Collision;

class LoadingZone extends FlxSprite
{
    //an object that stores info about a connected room or loading zone, with spawn coordinates, 
    //and changes the room + takes the player there when collided with
    //i think the transition itself should probably be in overworld

    public var toRoom:String; //contains the name for the next room's json
    //where to move the player
    public var toX:Int = 0; 
    public var toY:Int = 0;
    //collision
    public var collision:Collision;
    //debug
    public var hitboxVisible:Bool = false;

    public function new(x:Int, y:Int, width:Int, height:Int, toRoom:String, toX:Int, toY:Int)
    {
        super(x, y);

        makeGraphic(width, height, 0x384EFF95);
        setWarp(toRoom, toX, toY);
        //use LoadingZone.collision.checkOverlap to check for things overlapping the loading zone
        collision = new Collision(x, y, width, height);
    }

    public function setWarp(toRoom:String, toX:Int, toY:Int)
    {
        this.toRoom = toRoom;
        this.toX = toX;
        this.toY = toY;
    }

    public function checkPlayerOverlap(hitbox:FlxSprite):Bool
    {
        //generic in-bounds check. returns true if player is overlapping this loading zone.
        if(hitbox.x + hitbox.width > this.x && hitbox.x < this.x + this.width) //horizontal check
        {
            if(hitbox.y + hitbox.height > this.y && hitbox.y < this.y + this.height) //vertical check
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