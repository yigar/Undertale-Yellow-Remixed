package uty.components;

import flixel.math.FlxPoint;
import uty.objects.*;
import uty.objects.Player;
import flixel.tile.FlxTilemap;
import flixel.FlxCamera;
import flixel.math.FlxRect;
import flixel.FlxObject;
import flixel.util.typeLimit.OneOfTwo;
import funkin.states.base.FNFState;
import forever.display.ForeverSprite;
import flixel.tweens.FlxTween;
import uty.components.RoomParser;
import uty.components.DialogueParser;
import uty.objects.Interactable;
import uty.substates.DialogueSubState;
import uty.substates.OverworldMenuSubState;
import uty.substates.SoulTransitionSubState;
import flixel.system.ui.FlxSoundTray;
import uty.objects.OverworldCharacter;
import flixel.group.FlxGroup;
import flixel.util.FlxSort;
import funkin.states.PlayState;
import uty.components.PlayerData;
import uty.components.StoryData;
import uty.components.Inventory;
import uty.components.SoundManager;
import flixel.tile.FlxTilemap;
import flixel.FlxBasic;
import haxe.ds.StringMap;
import uty.components.OverworldUtil;

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
        var futurePos:Array<Int> = Overworld.current.playerController.calculateMove();
        var dirCol = OverworldUtil.isPlayerCollideAtCoords(futurePos[0], futurePos[1]);
        //if we can at least move in a direction
        if(dirCol[0] || dirCol[1])
        {
            Overworld.current.playerController.updateMove(dirCol[0], dirCol[1]);
        }
    }
}