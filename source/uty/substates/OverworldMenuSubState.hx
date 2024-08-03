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
import uty.components.Inventory;

enum abstract MenuState(String) to String{
    var CLOSE = "CLOSE";
    var MAIN = "MAIN";
    var ITEM = "ITEM";
    var STATS = "STATS";
    var MAIL = "MAIL";
    var SUBITEM = "SUBITEM";
} 


@:access(funkin.states.Overworld)
class OverworldMenuSubState extends FlxSubState
{
    public var cloverWindow:Window;
    public var optionWindow:Window;

    //when this var gets to -1, the state closes.
    //every int beyond zero represents another sub-menu open
    public var menuState:String = MAIN;

    public function new(camera:FlxCamera)
    {
        super();
        createCloverWindow();
        createOptionWindow();
        /*
        subWindow = new Window(0, 0, 0, 0);
        subItemWindow = new Window(0, 0, 0, 0);
        add(subWindow);
        add(subItemWindow);
        */
        
        cameraSetup(camera);
        FlxG.sound.play(AssetHelper.getAsset('audio/sfx/snd_mainmenu_select', SOUND));
    }

    function createCloverWindow()
    {
        var love = StoryData.getActiveData().playerSave.love;
        var health = StoryData.getActiveData().playerSave.health;
        var maxHP = PlayerData.getActiveHP();
        var gold = StoryData.getActiveData().playerSave.gold;

        cloverWindow = new Window(50, 75, 210, 160);
        add(cloverWindow);
        cloverWindow.addText(20, 15, "Clover");
        cloverWindow.addText(20, 70, 'LV ${love}', "mars-needs-cunnilingus", 15);
        cloverWindow.addText(20, 95, 'HP ${health}/${maxHP}', "mars-needs-cunnilingus", 15);
        cloverWindow.addText(20, 120, 'G   ${gold}', "mars-needs-cunnilingus", 15);
    }

    function createOptionWindow()
    {
        optionWindow = new Window(50, 250, 210, 240);
        add(optionWindow);
        optionWindow.createMenu(75, 30, [
            MenuOption("ITEM", openItemMenu, StoryData.getActiveData().playerSave.inventory.food.length > 0),
            MenuOption("STATS", openStatsMenu, true),
            MenuOption("MAIL", openStatsMenu, false)
        ], 1, 60, 50);
    }

    function createSubWindow(state:String)
    {
        switch (state)
        {
            case ITEM:
                openItemMenu();
            case STATS:
                openStatsMenu();
            case MAIL:
                openStatsMenu();

        }
    }

    function cameraSetup(camera:FlxCamera)
    {
        cloverWindow.cameras = [camera];
        optionWindow.cameras = [camera];
    }

    public function openItemMenu()
    {
        menuState = ITEM;
        optionWindow.addSubWindow(230, -175, 500, 500);
        //create menu from items later; temp one for now
        var itemGrab:Array<String> = [
            StoryData.getActiveData().playerSave.inventory.food[0].name ?? "null",
            StoryData.getActiveData().playerSave.inventory.food[1].name ?? "null",
            StoryData.getActiveData().playerSave.inventory.food[2].name ?? "null"
        ];
        optionWindow.sub.createMenu(75, 45, [
            MenuOption(itemGrab[0], openSubItemState, true),
            MenuOption(itemGrab[1], openSubItemState, true),
            MenuOption(itemGrab[2], openSubItemState, true)
        ], 1, 60, 50);


        optionWindow.sub.addSubWindow(0, 400, 500, 100);
        optionWindow.sub.sub.setTransparent(true);
        optionWindow.sub.sub.createMenu(115, 30, [
            MenuOption("USE", openSubItemState, true),
            MenuOption("INFO", openSubItemState, true),
            MenuOption("DROP", openSubItemState, true)
        ], 3, 50, 140);
        optionWindow.sub.sub.menu.centerOptions();
        optionWindow.sub.sub.menu.toggleControl(false);

        openSubMenuGeneric();
    }

    public function openStatsMenu()
    {
        menuState = STATS;
        optionWindow.addSubWindow(230, -175, 500, 600);
        //stats retrieval
        var love = StoryData.getActiveData().playerSave.love;
        var health = StoryData.getActiveData().playerSave.health;
        var maxHP = PlayerData.getActiveHP();

        var wpn:Item = StoryData.getActiveData().playerSave.inventory.weapon;
        var arm:Item = StoryData.getActiveData().playerSave.inventory.armor;
        var ammo:Item = StoryData.getActiveData().playerSave.inventory.ammo;
        var acce:Item = StoryData.getActiveData().playerSave.inventory.acce;
        //base at and df include the hat and gun
        var baseAT = PlayerData.loveToAT(love) + wpn.stats.at;
        var addAT = ammo.stats.at;
        var baseDF = PlayerData.loveToDF(love) + arm.stats.df;
        var addDF = acce.stats.df;

        var gold = StoryData.getActiveData().playerSave.gold;

        //player basics
        optionWindow.sub.addText(45, 60, "\"Clover\"");
        optionWindow.sub.addText(325, 60, 'LV ${love}');
        optionWindow.sub.addText(45, 120, 'HP ${health} / ${maxHP}');
        //AT, DF, EXP
        optionWindow.sub.addText(45, 195, 'AT ${baseAT}(${addAT})');
        optionWindow.sub.addText(45, 240, 'DF ${baseDF}(${addDF})');
        optionWindow.sub.addText(260, 195, "EXP -");
        optionWindow.sub.addText(260, 240, "NEXT -");
        //equipment
        optionWindow.sub.addText(45, 300, 'WEAPON: ${wpn.name}');
        optionWindow.sub.addText(45, 345, 'ARMOR: ${arm.name}');
        optionWindow.sub.addText(45, 405, 'AMMO: ${ammo.name}');
        optionWindow.sub.addText(45, 450, 'ACCE: ${acce.name}');
        //ya g's
        optionWindow.sub.addText(45, 510, 'GOLD: ${gold}');

        openSubMenuGeneric();
    }

    function openSubMenuGeneric()
    {
        optionWindow.sub.visible = true;
        optionWindow.controlSubMenu(true);
        optionWindow.menu.toggleControl(false);
    }

    function closeSubMenuGeneric()
    {
        optionWindow.sub.visible = false;
        optionWindow.controlSubMenu(false);
        optionWindow.menu.toggleControl(true);
        menuState = MAIN;
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);
        optionWindow.controlCheck();

        if (Controls.UT_ACCEPT_P)
        {
            confirmPress();
        }

        if(Controls.UT_CANCEL_P)
        {
            cancelPress();
        }
    }

    public function cancelPress()
    {
        FlxG.sound.play(AssetHelper.getAsset('audio/sfx/snd_mainmenu_select', SOUND));
        switch (menuState)
        {
            case MAIN:
            {
                close();
            }
            case ITEM, STATS, MAIL:
            {
                closeSubMenuGeneric();
            }
            case SUBITEM:
            {
                closeSubItemState();
            }
        }
    }

    public function confirmPress()
    {
        switch (menuState)
        {
            case MAIN:
            {
                optionWindow.menu.callSelectedFunction();
            }
            case ITEM, MAIL:
            {
                optionWindow.sub.menu.callSelectedFunction();
            }
            case SUBITEM:
            {
                //closeSubItemState();
            }
        }
    }

    public function openSubItemState()
    {
        optionWindow.sub.controlSubMenu(true);
        menuState = SUBITEM;
    }

    public function closeSubItemState()
    {
        optionWindow.sub.controlSubMenu(false);
        menuState = ITEM;
    }

    override function close()
    {
        cloverWindow.destroy();
        optionWindow.destroy();
        super.close();
        //FlxG.state.closeSubState();
    }
}