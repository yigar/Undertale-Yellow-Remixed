package uty.substates;
import uty.states.Overworld;
import flixel.FlxSubState;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import uty.objects.DialogueBox;
import uty.components.DialogueParser;
import flixel.FlxCamera;
import uty.ui.Window;
import uty.components.StoryData;
import uty.components.PlayerData;
import uty.objects.SavePoint;

enum abstract SaveMenuState(String) to String{
    var CLOSE = "CLOSE";
    var MAIN = "MAIN";
    var SAVED = "SAVED"; //pre-close "file saved" state
} 

@:access(funkin.states.Overworld)
class SaveMenuSubState extends FlxSubState
{
    public var saveWindow:Window;
    public var savePoint:SavePoint; //for data retrieval
    public var saveData:StorySave;

    public var menuState:String = MAIN;

    public function new(savePoint:SavePoint, camera:FlxCamera)
    {
        super();
        fetchSave();
        this.savePoint = savePoint;

        StoryUtil.restoreHP(99); //heal clover when he interacts with the save point.

        saveWindow = new Window(150, 240, 660, 240);
        add(saveWindow);
        saveWindow.cameras = [camera];

        saveWindow.addText(60, 45, 'Clover          LV ${saveData.playerSave.love}           0:00');
        saveWindow.addText(60, 110, savePoint.name);

        saveWindow.createMenu(90, 180, [
            MenuOption("Save", saveFunction),
            MenuOption("Warp", saveFunction),
            MenuOption("Remember", saveFunction),
            MenuOption("Return", close)
        ], 2, 60, 200);

        trace('created save menu successfully');
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);
        saveWindow.controlCheck();

        if (Controls.UT_ACCEPT_P)
        {
            confirmPress();
        }

        if(Controls.UT_CANCEL_P)
        {
            cancelPress();
        }
    }

    function fetchSave()
    {
        saveData = StoryData.getActiveData();
    }

    private function saveFunction()
    {
        //technical
        menuState = SAVED;

        StoryUtil.updateSavePoint(savePoint.name, Overworld.current.curRoomName, 
            Std.int(savePoint.spawnPoint.x), Std.int(savePoint.spawnPoint.y));

        StoryData.saveData();
        saveWindow.menu.toggleControl(false);
        StoryUtil.restoreHP(99); //again, just in case

        //cosmetic
        FlxG.sound.play(AssetHelper.getAsset('audio/sfx/snd_savedgame', SOUND));
        saveWindow.addText(60, 160, "File saved.");
        saveWindow.color = FlxColor.YELLOW; //lazy lol
        saveWindow.menu.visible = false;
    }

    private function cancelPress()
    {
        close();
    }

    private function confirmPress()
    {
        switch (menuState)
        {
            case SAVED:
            {
                close();
            }
            case MAIN:
            {
                saveWindow.menu.callSelectedFunction();
            }
        }
    }

    override function close()
    {
        saveWindow.destroy();
        super.close();
    }
}