package uty.substates;

import uty.states.Overworld;
import flixel.FlxSubState;
import flixel.FlxSprite;
import uty.objects.DialogueBox;
import uty.components.DialogueParser;
import flixel.FlxCamera;
import uty.scripts.UTScript;

@:access(funkin.states.Overworld)
class DialogueSubState extends FlxSubState
{
    //this is meant to freeze your other controls until the dialogue box closes
    var dialogueBox:DialogueBox;

    //script callbacks
    public var script:UTScript;
    public var callbackFunc:String;
    public var args:Array<Dynamic>;

    //okay problem with the substate
    //it freezes everything else in the scene
    //we probably DO in fact have to move some of this functionality either to the dialogue box or to another object controlling it
    //nvm just change the parent state updating


    public function new(dialogueGroup:DialogueGroup, camHUD:FlxCamera):Void
    {
        super();

        //so the overworld state needs to get the dialogue info from the interactable/eventTrigger/whatever
        //open this state
        //give the data here
        //and this gives that data to the dialogue box to initialize it
        //and check for controls in here to manipulate it.

        dialogueBox = new DialogueBox(0, 0, dialogueGroup);
        dialogueBox.cameras = [camHUD];
        add(dialogueBox);
        //pos
        dialogueBox.presetScreenPos("BOTTOM");
        //disable overworld input (IN THE OVERWORLD STATE)
        dialogueBox.nextDialogueLine();
        
        enableParentStateUpdate();

        //if the dialogue has a scripted callback, set it up
        if(Reflect.hasField(dialogueGroup, "callback"))
        {
            setScriptCallback(dialogueGroup.callback.script, dialogueGroup.callback.func, dialogueGroup.callback.args);
        }

        //if the dialogue is invalid or empty, close immediately. 
        //done after the script set in case it's an empty dialogue w/ a script attached
        if(dialogueGroup == null || !Reflect.hasField(dialogueGroup, "dialogue") || 
            dialogueGroup.dialogue.length <= 0 || dialogueGroup.dialogue == [])
        {
            trace('dialogue is empty; closing');
            dialogueBox.visible = false;
            dialogueBox.dialogueCompleted = true;
            closeDialogue();
        }
    }
    
    public function setScriptCallback(script:String, func:String, ?args:Array<Dynamic>)
    {
        this.script = new UTScript(AssetHelper.getAsset('data/scripts/overworld/${script}', HSCRIPT));
        scriptSet();
        callbackFunc = func;
        this.args = args;
    }

    //the event trigger and the dialoguesubstate BOTH have a scriptSet() command. Might wanna modularize this, just keep that in mind
    private function scriptSet()
    {
        script.preset();

        script.set("currentDiaSubState", this);
    }

    public function closeDialogue()
    {
        if(script != null && callbackFunc != null)
        {
            script.call(callbackFunc, args);
        }
        close();
    }

    public function enableParentStateUpdate()
    {
        if(_parentState != null)
        {
            _parentState.persistentUpdate = true;
        }
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);
        controls();
    }

    private function controls()
    {
        //confirm key: move on to the next line
        if(Controls.UT_ACCEPT_P)
        {
            if(dialogueBox.dialogueCompleted)
            {
                closeDialogue();
            }
            else //if not currently reading, and we can continue
            {
                dialogueBox.nextDialogueLine();
            }
        }
        //cancel key: skip narration
        if(Controls.UT_CANCEL_P)
        {
            if(dialogueBox.narratedText.narrating && dialogueBox.narratedText.allowSkip) //if currently reading, and we can skip
            {
                dialogueBox.skipLine();
            }
        }
    }

    override function close()
    {
        trace("closing dialogue substate...");
        dialogueBox.destroy();
        super.close();
        //FlxG.state.closeSubState();
    }



}