package uty.ui;

//import uty.ui.Window;
import flixel.math.FlxPoint;

class SaveMenu extends Window
{
    public function new(name:String, spawnPoint:FlxPoint)
    {
        super(150, 240, 660, 240);
        addText(60, 45, "Clover    LV 1    0:00");
        addText(60, 110, name);

        createMenu(90, 180, [
            MenuOption("Save", saveFunction),
            MenuOption("Warp", saveFunction),
            MenuOption("Remember", saveFunction),
            MenuOption("Return", saveFunction)
        ], 2, 200, 60);

    }

    public function saveFunction()
    {

    }
}