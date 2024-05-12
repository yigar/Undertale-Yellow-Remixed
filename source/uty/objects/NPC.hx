package uty.objects;

import uty.states.Overworld;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.group.FlxSpriteGroup;
import forever.display.ForeverSprite;
import flixel.math.FlxMath;
import uty.components.Collision;

/*
    standard NPCs in the overworld. extends overworldcharacter class.
    they mostly stand in place with attached interactable objects, with the capability to walk around and animate.
    this object can be spawned dynamically as an entity from the Ogmo map file.
*/

class NPC extends OverworldCharacter
{
    
    public var interactable:Interactable;
    //not to be confused with the interactable's collision detector
    private final _interactableThickness:Int = 30;

    //for cutscene scripting and the follower child class
    var target:FlxPoint;
    var targetRadius:Float = 0.0;
    
    public function new(charName:String, x:Float, y:Float, facing:String, dialogueName:String)
    {
        super(charName, x, y, facing);

        collision.enableCollide = true;

        interactable = new Interactable(0, 0,
            collision.width + (_interactableThickness * 2), collision.height + (_interactableThickness * 2),
            dialogueName);

        add(interactable);
        //visualDebug();
        target = new FlxPoint();
    }

    public function updateDialogue(dialogueName:String)
    {
        interactable.updateDialogue(dialogueName);
    }

    public function updateTargetCoords(x:Float, y:Float)
    {
        target.x = x;
        target.y = y;
    }

    //use this debug command to see their collider and interactable hitboxes
    private function visualDebug()
    {
        var col:FlxSprite = new FlxSprite().makeGraphic(Std.int(collision.width), Std.int(collision.height), 0x44FFCC00);
        col.x = collision.x; 
        col.y = collision.y;
        add(col);

        interactable.visible = true;
        interactable.alpha = 1.0;
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);
        interactable.x = collision.x - _interactableThickness;
        interactable.y = collision.y - _interactableThickness;
    }
}