package uty.objects;

import uty.states.Overworld;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.group.FlxSpriteGroup;
import forever.display.ForeverSprite;
import flixel.math.FlxMath;
import uty.components.Collision;

class NPC extends OverworldCharacter
{
    //npc objects in the overworld.
    //these should be built off of the interactable class by either extending it or having an interactable object in it
    //npcs must be capable of being talked to (having an interactable object attached to their sprite, with dialogue attached to that)
    //they should have animations that can be played while their dialogue box is open
    //they should maybe have a capacity to walk and have animations controlled by cutscene events
    //they should have colliders
    //and in regards to followers, that can be an extension of this class
    //ideally npcs are spawned by the ogmo level either directly or through an event object

    //you probably need to add npcs to an array or a map
    //and access remotely with events
    
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