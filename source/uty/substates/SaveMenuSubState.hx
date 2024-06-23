package uty.substates;
import uty.states.Overworld;
import flixel.FlxSubState;
import flixel.FlxSprite;
import uty.objects.DialogueBox;
import uty.components.DialogueParser;
import flixel.FlxCamera;
import uty.ui.Window;
import uty.components.StoryData;
import uty.components.PlayerData;

enum abstract SaveMenuState(String) to String{
    var CLOSE = "CLOSE";
    var MAIN = "MAIN";
} 

@:access(funkin.states.Overworld)
class SaveMenuSubState extends FlxSubState
{
    public var saveWindow:Window;

    public function new()
    {

    }
}