package uty.components;
import funkin.components.parsers.*;

typedef DialogueFile =
{
    dialogueGroups:Array<DialogueGroup>
}

typedef DialogueGroup =
{
    name:String,
    parameters:DialogueParameters,
    dialogue:Array<DialogueLine>
}

typedef DialogueLine =
{
    character:String,
    emotion:String,
    font:String,
    string:String
}

//this is for storing multiple dialogue groups in the same file.
//when it comes to checking things and having dynamic & changing dialogue, 
//it would be a bit obnoxious and unorganized to have to open a different file every time
//each interactable should have one dialogue file attached
//and different dialogue should be within the file and called based on different conditions
//thus interactables themselves should ideally contain some extra info to help with this
//a "times read" counter could track how many times it was interacted with
//require a "default" parameter for failsafe purposes, and if there isn't one
//make the default dialogue the first one in the file
typedef DialogueParameters = 
{
    defaultDialogue:Bool, //false by default
    checkCount:Int,
    itemInInv:String
}

class DialogueParser
{
    //writing this to allow for a more complex and dynamic dialogue system/dialogue files.
    //this class should take dialogue jsons and return single dialogue groups or lines based on parameters.
    var json:DialogueFile;
    var diaGroups:Array<DialogueGroup>; //stores all dialogue group data in an array. maybe make a map?

    public function new(?jsonFile:String, ?folder:String = "")
    {
        diaGroups = new Array<DialogueGroup>();
        if(jsonFile != null)
        {
            updateDialogueJson(jsonFile, folder);
        }
    }

    private function addDialogueGroups()
    {
        if(Reflect.hasField(json, "dialogueGroups"))
        {
            diaGroups = json.dialogueGroups;
            
            for (i in 0...json.dialogueGroups.length)
            {
                diaGroups.push(json.dialogueGroups[i]);
            }
            
        }
        else
            trace("ERROR: dialogue json invalid, no groups detected. Add a dialogueGroups field.");
    }

    public function updateDialogueJson(jsonFile:String, ?folder:String = "")
    {
        json = cast(AssetHelper.parseAsset('funkin/data/dialogue/${folder}/${jsonFile}', JSON));
        addDialogueGroups();
    }

    public function getDialogueFromIndex(index:Int):DialogueGroup
    {
        if(index < diaGroups.length)
        {
            return diaGroups[index];
        }
        else
        {
            trace("error: index is larger than dialogue group size");
            return getDefaultDialogueGroup();
        }
            
    }

    public function getDefaultDialogueGroup():DialogueGroup
    {
        //checks each group in the dialogue groups array for a defaultDialogue var in the parameters field, set to true.
        for (group in diaGroups)
        {
            if(Reflect.hasField(group, "parameters"))
            {
                if(Reflect.hasField(group.parameters, "defaultDialogue") && group.parameters.defaultDialogue)
                {
                    return group;
                }
            }
            else
            {
                trace("warning: no parameters field");
            }
        }
        return diaGroups[0]; //return the first group by default
    }

    /* im too retarded to do this right now
    public function getDialogueFromParameter(parameters:DialogueParameters):DialogueGroup
    {
        for (group in dialogueGroups)
            {
                if(Reflect.hasField(group, "parameters"))
                {
                    if(group.parameters.defaultDialogue != )
                }
                else
                {
                    trace("warning: no parameters field");
                }
            }
            return dialogueGroups[0]; //return the first group by default
    }
    */

    public function getDialogueFromCheckCount(count:Int):DialogueGroup
    {
        //get the dialogue with the count number equal to count.
        //if there is none, get the highest count that doesn't go over this count.
        if(count < 0)
        {
            trace("ERROR: you can't have a negative count value.");
            return diaGroups[0];
        }

        var closestGroup:DialogueGroup = diaGroups[0];
        for (group in diaGroups)
            {
                if(Reflect.hasField(group, "parameters"))
                {
                    if(group.parameters.checkCount == count)
                    {
                        return group;
                    }
                    else if(group.parameters.checkCount - count <= 0 && //if this group's count is lower than var count
                        (group.parameters.checkCount - count > closestGroup.parameters.checkCount - count)) //and if it's bigger than the other check count
                    {
                        closestGroup = group; //set the closest group to this one, cuz this one is closer
                    }
                }
                else
                {
                    trace("warning: no parameters field");
                }
            }
            if(closestGroup != null) 
                return closestGroup;
            else 
                return getDefaultDialogueGroup();
    }

    public function getDialogueFromName(name:String):DialogueGroup
    {
        for (group in diaGroups)
            {
                if(Reflect.hasField(group, "name"))
                {
                    if(group.name ==  name)
                    {
                        return group;
                    }
                }
                else
                {
                    trace("warning: no parameters field");
                }
            }
            return getDefaultDialogueGroup();
    }

    private function resolveDialogueParameters()
    {
        //sets default values in the case of nulls

    }

}