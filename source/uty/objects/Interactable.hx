package uty.objects;

import flixel.FlxSprite;
import uty.components.Collision;

/*
    an object with a hitbox and attached dialogue file.
    the overworld state checks if the player is standing in one when they press the ACCEPT key
    if so, a dialogue box is instantiated
    also allows for double-clicking. this feature is used on follower characters for convenience.
    can be spawned dynamically in Ogmo level files, but also are frequently attached to other game objects.
*/

class Interactable extends FlxSprite
{
    public var collision:Collision;
    public var dialogueJson:String; //stores the dialogue file dir to be parsed
    public var checkCount:Int = 0; //how many times the interactable has been interacted with. used for progressing dialogue.

    //multiple click stuff for follower class
    public var clicks:Int = 0;
    public var clickRequirement:Int = 1;
    private var clickDecrementTime:Float = 0.4;
    private var clickCountdown:Float = 0.0;

    public function new(x:Float, y:Float, width:Float, height:Float, dialogueName:String)
    {
        super(x, y);
        makeGraphic(Std.int(width), Std.int(height), 0x4D15C1FF);
        alpha = 0.0;
        collision = new Collision(x, y, width, height);
        updateDialogue(dialogueName);
        clickCountdown = clickDecrementTime;
    }

    public function updateDialogue(dialogueName:String)
    {
        dialogueJson = dialogueName;
    }

    public function checkIncrement()
    {
        checkCount++;
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);
        collision.x = this.x;
        collision.y = this.y;

        //remove clicks for every [clickDecrementTime] seconds elapsed, until at 0
        if(clicks > 0)
        {
            clickCountdown -= elapsed;
            if(clickCountdown <= 0.0)
            {
                clicks -= 1;
                clickCountdown = clickDecrementTime;
            }
        }
    }

    //checks if enough clicks have been reached to allow
    public function areClicksReached(?addClicks:Int = 0):Bool
    {
        clicks += addClicks;
        return clicks >= clickRequirement;
    }

    public function resetClicks()
    {
        clicks = 0;
        clickCountdown = clickDecrementTime;
    }
}