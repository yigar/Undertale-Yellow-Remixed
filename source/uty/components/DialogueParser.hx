package uty.components;
import funkin.components.parsers.*;
import flixel.math.FlxMath;

/*
    a dialogue parser for dialogue files.
    dialogue files can store multiple dialogue groups, with attached parameters to judge when to call them.
    a dialogue group stores multiple dialogue lines.
    a dialogue line contains the dialogue string, 
    and other info like the character name (determines what portrait sprite & text sound to use) and their emotion.
    dialogue files are most commonly assigned to containers in Interactables and scripts (getting there).
*/

typedef DialogueFile =
{
    dialogueGroups:Array<DialogueGroup>
}

typedef DialogueGroup =
{
    name:String,
    parameters:DialogueParameters,
    dialogue:Array<DialogueLine>,
    ?callback:{script:String, func:String, args:Array<Dynamic>}
}

typedef DialogueLine =
{
    character:String,
    emotion:String,
    font:String,
    string:String
}

typedef DialogueParameters = 
{
    defaultDialogue:Bool, //false by default
    ?checkCount:Int,
    ?itemInInv:String,
    ?deathCount:Int
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
        if(folder != null && folder != "") 
            folder += "/";
        json = cast(AssetHelper.parseAsset('data/dialogue/${folder}${jsonFile}', JSON));
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

    public function getDialogueFromParameters(parameters:DialogueParameters):DialogueGroup
    {
        for (group in diaGroups)
        {
            if(Reflect.hasField(group, "parameters"))
            {
                if(group.parameters == parameters)
                {
                    return group;
                }
            }
            else
            {
                trace("warning: no parameters field (DialogueParser line 125)");
            }
        }
        return getDefaultDialogueGroup(); //return the first group by default
    }

    //allows you to grab a dialogue group using one parameter type and its value at a time.
    //you can also check for the parameter closest to the given value, if the given value is a number.
    //i.e. things like death counts
    public function getDialogueFromParameter(paramName:String, value:Dynamic, ?getClosest:Bool = false):DialogueGroup
    {
        var closest:Float = FlxMath.MAX_VALUE_FLOAT;
        var canCompare:Bool = false;
        var storedReturnGroup:DialogueGroup = getDefaultDialogueGroup();
        if(getClosest && (Std.isOfType(value, Int) || Std.isOfType(value, Float)))
        {
            canCompare = true;
        }

        for(group in diaGroups)
        {
            if(Reflect.hasField(group, "parameters") && Reflect.hasField(group.parameters, paramName))
            {
                if(value != null)
                {
                    var paramVal = Reflect.field(group.parameters, paramName);
                    if(paramVal == value)
                        return group;
                    //this will only run if the value type is an int/float
                    if(canCompare)
                    {
                        //if closest is empty, or if this parameter's num value is closer to the target than closest
                        if(((Std.isOfType(paramVal, Int) || Std.isOfType(paramVal, Float)) &&
                            Math.abs(paramVal - value) > Math.abs (closest - value)))
                        {
                            closest = value;
                            storedReturnGroup = group;
                        }
                    }
                }
                    
            }
        }
        return storedReturnGroup;
    }

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
                    //trace(group.name + " VS " + name);
                    if(group.name.toLowerCase() ==  name.toLowerCase())
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