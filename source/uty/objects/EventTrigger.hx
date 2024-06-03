package uty.objects;

import flixel.FlxSprite;
import uty.components.Collision;
import forever.core.scripting.HScript;

class EventTrigger extends FlxSprite
{
    public var enabled:Bool = true;
    public var isButton:Bool = false; //if true, only activate on ACCEPT key press. if false, activate when colliding.
    public var disableAfterUses:Int = 1; //set to a negative number for infinite uses

    public var script:HScript;
    public var collision:Collision;

    public function new(x:Float, y:Float, width:Float, height:Float, script:String, ?isButton:Bool = false, ?uses:Int = 1)
    {
        super(x, y);
        makeGraphic(Std.int(width), Std.int(height), 0x4DFF7615);
        alpha = 0.0;
        collision = new Collision(x, y, width, height);

        this.script = new HScript(AssetHelper.getAsset('data/scripts/overworld/${script}', HSCRIPT));
        scriptSet();

        this.isButton = isButton;
        disableAfterUses = uses;
    }

    //the event trigger and the dialoguesubstate BOTH have a scriptSet() command. Might wanna modularize this, just keep that in mind
    private function scriptSet()
    {
        script.set("PlayState", funkin.states.PlayState);
        script.set("Overworld", uty.states.Overworld);
        script.set("OverworldCharacter", uty.objects.OverworldCharacter);
        script.set("DialogueSubState", uty.substates.DialogueSubState);
        script.set("DialogueGroup", uty.components.DialogueParser);
        script.set("PlaySong", funkin.states.PlayState.PlaySong);
    }

    public function callScript()
    {
        if(disableAfterUses == 0)
            enabled = false;
        if(enabled)
            script.call("start");
        disableAfterUses -= 1;
        trace(script);
    }

    public function checkOverlap(hitbox:FlxSprite):Bool
    {
        return collision.checkOverlap(hitbox);
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);
        collision.x = this.x;
        collision.y = this.y;
    }
}