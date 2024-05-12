package uty.objects;

import uty.states.Overworld;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.group.FlxSpriteGroup;
import forever.display.ForeverSprite;
import flixel.math.FlxMath;
import uty.components.Collision;

class Follower extends NPC
{
    //a type of NPC that follows the player around.
    //a controller should be used to make them follow the player when following is on

    //make them walk towards the player if they're enough distance away
    //and stop when they're close enough

    public var followPlayer:Bool = true;
    public var nodePath:Array<FlxPoint>;
    public var catchingUp:Bool = false;
    public var runDistance:Float = 150.0; //how far away the npc should be before they start running to catch up
    private var nodeCheckRadius:Float = 10.0;
    public var catchUpRadius = 1.8; //will be multiplied in setup

    public function new(charName:String, x:Float, y:Float, facing:String, dialogueName:String)
    {
        super(charName, x, y, facing, dialogueName);

        collision.enableCollide = false;
        //followers must be double-clicked to talk to them. 
        //avoids the menu shit in UTY without taking away ur ability to talk to them
        interactable.clickRequirement = 2;

        targetRadius = 70.0;
        catchUpRadius *= targetRadius;

        nodePath = new Array<FlxPoint>();
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if(nodePath.length <= 0)
        {
            nodePath.push(new FlxPoint(target.x, target.y));
        }

        if(catchingUp)
        {
            if(reachedTarget())
            {
                trace("reached target, pausing");
                pausePathing();
            }
            else if(reachedClosestNode())
            {
                updateNodePath();
            }
        }
        else if(!catchingUp && tooFarFromTarget())
        {
            continuePathing();
        }
    }

    public function reachedClosestNode():Bool
    {
        //will return true if the follower is within [nodeCheckRadius] pixels of the closest node's coordinates.
        if(nodePath.length <= 0) return false;
        return bottomCenter.distanceTo(nodePath[0]) < nodeCheckRadius;
    }

    public function reachedTarget():Bool
    {
        //will return true if the follower is within [targetRadius] pixels of the target. in this case, probably the player.
        return bottomCenter.distanceTo(target) < targetRadius;
    }

    public function tooFarFromTarget():Bool
    {
        return bottomCenter.distanceTo(target) > catchUpRadius;
    }

    public function isRunningDistance():Bool
    {
        return bottomCenter.distanceTo(target) > runDistance;
    }

    public function updateNodePath()
    {
        nodePath = new Array<FlxPoint>();
        //creates a path for the follower to walk on based on the target.x and target.y values.
        //this should probably be called every time the follower reaches a node.
        //when the follower is within the target radius of their destination, stop their movement
        if(!FlxMath.inBounds(target.x, bottomCenter.x - nodeCheckRadius, bottomCenter.x + nodeCheckRadius) && 
            !FlxMath.inBounds(target.y, bottomCenter.y - nodeCheckRadius, bottomCenter.y + nodeCheckRadius))
        {
            var node1:FlxPoint;
            //find out which axis is shorter away and by how much
            var xDist = target.x - bottomCenter.x;
            var yDist = target.y - bottomCenter.y;
            if(Math.abs(xDist) > Math.abs(yDist)) //if further away horizontally than vertically
            {
                node1 = new FlxPoint(bottomCenter.x + yDist, target.y);
            }
            else
            {
                node1 = new FlxPoint(target.x, bottomCenter.y + xDist);
            }
            nodePath.push(node1);
        }
        else
            nodePath.push(new FlxPoint(target.x, target.y));

        trace("NODEPATH: " + nodePath);
    }

    public function calculateMoveInput():FlxPoint
    {
        //returns the direction to move as an FlxPoint. 1 = move positive, -1 = move negative, 0 = don't move.

        if(!catchingUp)
            return new FlxPoint(0, 0);
        else
        {
            var radius = nodeCheckRadius; //isRunningDistance() ? targetRadius : nodeCheckRadius;
            
            var moveX:Int = FlxMath.inBounds(target.x, bottomCenter.x - radius, bottomCenter.x + radius) ? 
                0 : FlxMath.signOf(target.x - bottomCenter.x);
            var moveY:Int = FlxMath.inBounds(target.y, bottomCenter.y - radius, bottomCenter.y + radius) ? 
                0 : FlxMath.signOf(target.y - bottomCenter.y);
            return new FlxPoint(moveX, moveY);
        };
    }

    public function pausePathing()
    {
        //run this when the follower gets within range of the target point
        nodePath = new Array<FlxPoint>();
        catchingUp = false;
    }

    public function continuePathing()
    {
        catchingUp = true;
    }
}