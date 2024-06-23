package uty.objects;

import forever.display.ForeverSprite;
import flixel.math.FlxPoint;
import uty.ui.SaveMenu;
import uty.components.StoryData;
import flixel.util.FlxTimer;
import uty.states.Overworld;

//because flowey and save points are essentially one-in-the-same, i'm writing them as the same
//save points are characters/NPCs that show the save menu when interacted with
//contains some positioning info to pass to the save file too
class SavePoint extends NPC
{
    public var name:String = "Save Point";
    public var spawnPoint:FlxPoint;
    public var dialogue:String;

    public final _emergeTime:Float = 0.6;
    public final _descendTime:Float = 0.5;
    
    public function new(x:Float, y:Float, ?spawnX:Int = 0, ?spawnY:Int = 0, 
        ?name:String, ?file:String = "flowey", ?dialogue:String = "saveDialogueDefault")
    {
        spawnPoint = new FlxPoint(spawnX, spawnY);
        if(name != null) this.name = name;

        super(file, x, y, "down", dialogue);

    }

    public function startDialogue()
    {
        
        if(StoryData.getActiveData().followers.length > 0) //if clover is not alone, and another character is in the party
        {
            this.characterSprite.animation.play('save');
            createSaveMenu();
        }
        else
        {
            this.playBasicAnimation("emerge", "down");
            new FlxTimer().start(1.5, function(tmr:FlxTimer){
                Overworld.current.openDialogue(dialogue, interactable.checkCount);
            });
        }
    }

    public function createSaveMenu()
    {
        var saveMenu:SaveMenu = new SaveMenu(name, spawnPoint);
    }
}