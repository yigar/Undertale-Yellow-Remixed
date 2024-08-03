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
import flixel.util.FlxTimer;

enum abstract SaveMenuState(String) to String{
    var CLOSE = "CLOSE";
    var MAIN = "MAIN";
    var SAVED = "SAVED"; //pre-close "file saved" state
    var WARP = "WARP";
} 

typedef WarpData = {
    name:String,
    room:String,
    posX:Int,
    posY:Int,
    unlock:String
}

@:access(funkin.states.Overworld)
class SaveMenuSubState extends FlxSubState
{
    public var saveWindow:Window;
    public var savePoint:SavePoint; //for data retrieval
    public var saveData:StorySave;

    public static final warpList:Array<WarpData> = [
        {
            name: "Dark Ruins",
            room: "darkRuins_2",
            posX: 400,
            posY: 400,
            unlock: "FloweySongBeaten"
        },
        {
            name: "Snowdin Outskirts",
            room: "snowdin_1",
            posX: 400,
            posY: 400,
            unlock: "FloweySongBeaten"
        }
    ];

    public var unlockedWarps:Array<WarpData>;

    public var menuState:String = MAIN;

    public function new(savePoint:SavePoint, camera:FlxCamera)
    {
        super();
        fetchSave();
        updateUnlockedWarps();
        this.savePoint = savePoint;

        StoryUtil.restoreHP(99); //heal clover when he interacts with the save point.

        saveWindow = new Window(150, 200, 660, 320);
        add(saveWindow);
        saveWindow.cameras = [camera];

        saveWindow.addText(60, 45, 'Clover          LV ${saveData.playerSave.love}           ${StoryUtil.getActiveTimeString()}');
        saveWindow.addText(60, 110, savePoint.name);

        saveWindow.createMenu(90, 180, [
            MenuOption("Save", saveFunction, true),
            MenuOption("Warp", openWarpMenu, (unlockedWarps.length > 0)),
            MenuOption("Memory Log", saveFunction, true),
            MenuOption("Return", close, true)
        ], 2, 60, 300);
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

    private function openWarpMenu()
    {
        menuState = WARP;

        updateUnlockedWarps();
        var optArr:Array<MenuOption> = new Array<MenuOption>();
        for (i in 0...unlockedWarps.length) {
            optArr.push(MenuOption(unlockedWarps[i].name, warpFunction,
                (unlockedWarps[i].room != Overworld.current.curRoomName)));
        }

        saveWindow.addSubWindow(80, -100, 500, 520);
        saveWindow.sub.createMenu(60, 50, optArr, 1, 60, 50);
        saveWindow.sub.visible = true;
        saveWindow.controlSubMenu(true);

        //create a sub-menu listing the warps.
        //gray out the current one.
    }

    private function warpFunction()
    {
        var sel:Int = saveWindow.sub.menu.selection;
        new FlxTimer().start(0.5, function(tmr:FlxTimer){
            Overworld.current.warp(unlockedWarps[sel].room, unlockedWarps[sel].posX, unlockedWarps[sel].posY);
        });
        close();
    }

    private function updateUnlockedWarps():Array<WarpData>
    {
        unlockedWarps = new Array<WarpData>();
        for(i in 0...warpList.length)
            {
                if(StoryProgress.checkFlag(warpList[i].unlock)) //checks if a flag named the same as the unlock var has been unlocked
                    unlockedWarps.push(warpList[i]);
            }
        return unlockedWarps;
    }

    private function cancelPress()
    {
        switch (menuState)
        {
            case SAVED, MAIN: {
                close();
            }
            case WARP: {
                saveWindow.sub.visible = false;
                saveWindow.controlSubMenu(false);
                saveWindow.menu.toggleControl(true);
                menuState = MAIN;
            }
        }
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
            case WARP:
            {
                saveWindow.sub.menu.callSelectedFunction();
            }
        }
    }

    override function close()
    {
        saveWindow.destroy();
        super.close();
    }
}