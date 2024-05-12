package uty.substates;

import uty.states.Overworld;
import flixel.FlxSubState;
import flixel.FlxSprite;
import uty.objects.DialogueBox;
import uty.components.DialogueParser;
import flixel.FlxCamera;

class DialogueSubState extends FlxSubState
{
    //this is meant to freeze your other controls until the dialogue box closes
    var dialogueBox:DialogueBox;

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
        dialogueBox.setScreenPosition("BOTTOM");
        //disable overworld input (IN THE OVERWORLD STATE)
        dialogueBox.nextDialogueLine();
        
        enableParentStateUpdate();
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
                close();
            }
            else if(!dialogueBox.narratedText.narrating && dialogueBox.narratedText.allowContinue) //if not currently reading, and we can continue
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
        dialogueBox.destroy();
        super.close();
        //FlxG.state.closeSubState();
    }



}