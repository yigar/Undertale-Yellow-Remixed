package uty.components;


import flixel.FlxBasic;
import haxe.ds.StringMap;
import uty.components.OverworldUtil;
import uty.states.Overworld;
import uty.objects.NPC;
import uty.objects.SavePoint;
import uty.objects.LoadingZone;
import uty.objects.Interactable;
import uty.objects.Follower;
import uty.objects.Stairs;
import flixel.group.FlxGroup;

//manages objects interacting with each other in the overworld, like collision, etc.
class OverworldInteractionManager extends FlxBasic
{
    public var interactables:FlxTypedGroup<Interactable>;
    public var stairs:FlxTypedGroup<Stairs>;

    public function new()
    {
        super();

        interactables = new FlxTypedGroup<Interactable>();
        stairs = new FlxTypedGroup<Stairs>();
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        playerMoveAndCollide(); //moves player while checking for collision
        loadingZoneCheck(); //checks if the player has entered a loading zone, updates and starts a room transition if so
        stairsCheck(); //checks all added stairs for player overlap. sets slope value accordingly (and back to zero if no stairs found)
    }

    //adds all interactables from the overworld to the list of them to track here.
    //includes everything that should be tracked normally, like signs, NPCs, followers, etc.
    public function setupInteractables()
    {
        Overworld.current.room.interactables.forEach(function(i:Interactable) {
            interactables.add(i);
        });
        Overworld.current.npcs.forEach(function(n:NPC) {
            interactables.add(n.interactable);
        });
        Overworld.current.followers.forEach(function(f:Follower) {
            interactables.add(f.interactable);
        });
    }

    public function setupStairs()
    {
        Overworld.current.room.stairs.forEach(function(s:Stairs) {
            addStair(s);
        });
    }

    public function addStair(stair:Stairs)
    {
        stairs.add(stair);
    }

    //manages player movement and collision.
    //in the future, might want to add all collision objects to a general dynamic list, not check groups of them like this
    public function playerMoveAndCollide()
    {
        var futurePos:Array<Float> = Overworld.current.playerController.calculateMove();

        //ROOM COLLISION MAP
        var dirCol = OverworldUtil.isPlayerTilemapCollideAfterMove(futurePos[0], futurePos[1]);

        //NPCS
        Overworld.current.npcs.forEach(function(n:NPC)
            {
                if(n.collision.enableCollide)
                {
                    dirCol = getBoolArrayOr(dirCol, OverworldUtil.isPlayerColOverlapAfterMove(
                        n.collision, futurePos[0], futurePos[1]));
                }
            });

        //SAVE POINT
        if(Overworld.current.room.savePoint != null)
        {
            dirCol = getBoolArrayOr(dirCol, OverworldUtil.isPlayerColOverlapAfterMove(
                Overworld.current.room.savePoint.collision, futurePos[0], futurePos[1]));
        }

        //if we can at least move in a direction
        if(!dirCol[0] || !dirCol[1])
        {
            Overworld.current.playerController.move(dirCol[0], dirCol[1]);
        }
    }

    public function loadingZoneCheck()
    {
        //if the player's overlapping a loading zone, get that zone's data, transition, and warp to the next room
        var isCol:Bool = false;
        Overworld.current.room.loadingZones.forEach(function(zone:LoadingZone)
        {
            if(zone.collision.checkOverlap(Overworld.current.playerHitbox))
            {
                isCol = true;
                //this only gets triggered once. is NOT called unless the player wasn't in a loading zone before.
                if(!Overworld.current.isPlayerInLoadingZone)
                {
                    Overworld.current.isPlayerInLoadingZone = true;
                    Overworld.current.nextRoomTransition(zone.toRoom, zone.toX, zone.toY);
                }
            }
        });
        //will set this var to false if no collision happened
        Overworld.current.isPlayerInLoadingZone = isCol;
    }

    public function interactableCheck()
    {
        interactables.forEach(function(i:Interactable)
        {
            if(i.collision.checkOverlap(Overworld.current.playerHitbox) && i.areClicksReached(1))
            {
                Overworld.current.openDialogue(i.dialogueJson, i.checkCount);
                i.checkIncrement();
                return; //don't open multiple dialogues
            }
        });

        //the save point is unique and rare enough that it doesn't need to be dynamic like the other stuff
        if(Overworld.current.room.savePoint != null && 
            Overworld.current.room.savePoint.interactable.collision.checkOverlap(Overworld.current.playerHitbox))
        {
            Overworld.current.setLockAllInput(true);
            Overworld.current.room.savePoint.startDialogue();
        }
    }

    public function stairsCheck()
    {
        var inStairs = false;
        stairs.forEach(function(stair:Stairs)
        {
            if(stair.parallelogram.containsXYPara(Overworld.current.player.bottomCenter.x, Overworld.current.player.bottomCenter.y))
            {
                Overworld.current.playerController.slope = stair.parallelogram.slope;
                inStairs = true;
                return;
            }
        });
        if(!inStairs)
            Overworld.current.playerController.slope = 0;
    }

    //quick function to make bool overrides easier. orCheck will check if either of the bools is [true/false] and set it to that
    private function getBoolArrayOr(ary1:Array<Bool>, ary2:Array<Bool>, ?orCheck:Bool = true):Array<Bool>
    {
        if(ary1.length != ary2.length)
            return [false, false];
        for(i in 0...ary1.length)
        {
            if(ary1[i] == orCheck || ary2[i] == orCheck)
                ary1[i] = orCheck;
        }
        return ary1;
    }
}