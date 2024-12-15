package uty.components;


import flixel.FlxBasic;
import haxe.ds.StringMap;
import uty.components.OverworldUtil;
import uty.states.Overworld;
import uty.objects.NPC;
import uty.objects.SavePoint;

//manages objects interacting with each other in the overworld, like collision, etc.
class OverworldInteractionManager extends FlxBasic
{
    
    public function new()
    {
        super();
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        playerMoveAndCollide();
    }

    //manages player movement and collision.
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