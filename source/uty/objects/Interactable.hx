package uty.objects;

import flixel.FlxSprite;
import uty.components.Collision;

class Interactable extends FlxSprite
{
    //generic class for things you can walk up to, press the confirm key, and show a dialogue box while you're in its bounds.
    //NPCs will probably inherit this class or have one of these in them.
    public var collision:Collision;
    public var dialogueJson:String; 
    //will store the filename of the dialogue json.
    //currently the overworld state retrieves the file with the dialogue parser, using this value
    public var checkCount:Int = 0; 
    //how many times the interactable has been interacted with. for dynamic dialogue.

    //this clicks stuff basically allows for interactables to only be called after double-checking them
    //something i want for follower NPCs. their interactable box will still be enabled so you can talk to them, but prevents accidental checking
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

    //make a function to invoke a textbox?
}