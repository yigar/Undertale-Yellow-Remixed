package uty.substates;
import uty.states.Overworld;
import flixel.FlxSubState;
import flixel.FlxSprite;
import uty.objects.DialogueBox;
import uty.components.DialogueParser;
import flixel.FlxCamera;
import uty.ui.Window;

@:access(funkin.states.Overworld)
class OverworldMenuSubState extends FlxSubState
{
    public var cloverWindow:Window;
    public var optionWindow:Window;
    public var subWindow:Window;

    public function new(camera:FlxCamera)
    {
        super();
        createCloverWindow();
        createOptionWindow();
        subWindow = new Window(0, 0, 0, 0);
        add(subWindow);
        addAllToCamera(camera);
    }

    function createCloverWindow()
    {
        cloverWindow = new Window(50, 75, 210, 160);
        add(cloverWindow);
        cloverWindow.addText(20, 15, "Clover");
        cloverWindow.addText(20, 70, "LV 1", "mars-needs-cunnilingus", 15);
        cloverWindow.addText(20, 95, "HP 20/20", "mars-needs-cunnilingus", 15);
        cloverWindow.addText(20, 120, "G   0", "mars-needs-cunnilingus", 15);
    }

    function createOptionWindow()
    {
        optionWindow = new Window(50, 250, 210, 240);
        add(optionWindow);
        optionWindow.createMenu(75, 30, [
            MenuOption("ITEM", openStatsMenu),
            MenuOption("STATS", openStatsMenu),
            MenuOption("MAIL", openStatsMenu)
        ], 1, 60, 50);
    }

    function addAllToCamera(camera:FlxCamera)
    {
        cloverWindow.cameras = [camera];
        optionWindow.cameras = [camera];
        subWindow.cameras = [camera];
    }

    function openMenuGeneric()
    {
        subWindow.visible = false;
        //if(subWindow.menu != null) subWindow.menu.controlEnabled = true;
        optionWindow.menu.controlEnabled = false;
    }

    function closeMenuGeneric()
    {
        subWindow.visible = false;
        if(subWindow.menu != null) subWindow.menu.controlEnabled = false;
        optionWindow.menu.controlEnabled = true;
    }

    public function openItemMenu()
    {
        subWindow = new Window(280, 75, 500, 500);
    }

    public function openStatsMenu()
    {
        subWindow = new Window(280, 75, 500, 600);
        //player basics
        subWindow.addText(45, 60, "\"Clover\"");
        subWindow.addText(325, 60, "LV 1");
        subWindow.addText(45, 120, "HP 20 / 20");
        //AT, DF, EXP
        subWindow.addText(45, 195, "AT 10(0)");
        subWindow.addText(45, 240, "DF 10(0)");
        subWindow.addText(260, 195, "EXP 0");
        subWindow.addText(260, 240, "NEXT 10");
        //equipment
        subWindow.addText(45, 300, "WEAPON: Toy Gun");
        subWindow.addText(45, 345, "ARMOR: Worn Hat");
        subWindow.addText(45, 405, "AMMO: Rubber Ammo");
        subWindow.addText(45, 450, "ACCE: Patch");
        //ya g's
        subWindow.addText(45, 510, "GOLD: 0");

        openMenuGeneric();
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);
        optionWindow.menu.controlCheck();

        if(Controls.UT_CANCEL_P)
        {
            close();
        }
    }

    override function close()
    {
        cloverWindow.destroy();
        optionWindow.destroy();
        subWindow.destroy();
        super.close();
        //FlxG.state.closeSubState();
    }
}