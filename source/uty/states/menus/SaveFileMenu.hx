package uty.states.menus;

import funkin.states.base.FNFState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.text.FlxText;
import forever.display.ForeverSprite;
import uty.components.StoryData;
import uty.components.SoundManager;
import uty.ui.Window;

//do different stuff if the save file is clear.
class SaveFileMenu extends FNFState
{
    //naming it "displayData" to differentiate it from actual StoryData.getActiveData()
    //this is mainly to be used for updating the visuals.
    var displayData:StorySave;

    var window:Window;
    var art:FlxSprite;
    var sndMngr:SoundManager;

    //in order to track game progress and what sprites/music to use, a more complex game progress system needs to be implemented first
    //this may be a waste of time for the demo or is at the very least something that should be done last
    //for now, use placeholder sprites and music

    override function create()
    {
        super.create();

        displayData = StoryData.getActiveData();

        art = new FlxSprite();
        loadSaveSprite('ruins');

        window = new Window(200, 70, 540, 270);
        window.setTransparent();
        add(window);

        window.addText(0, 0, 0, 'Clover         LV${displayData.playerSave.love}         ${StoryUtil.getActiveTimeString()}', PIXELA, 38, true, 3);
        window.addText(0, 60, 0, displayData.savePointName, PIXELA, 38, true, 3);
        window.createMenu(60, 150, [
            MenuOption("Continue", loadOverworld),
            MenuOption("Reset", loadOverworld),
            MenuOption("Memory Log", loadMemLog),
            MenuOption("Options", loadOverworld)
        ], 2, 60, 270);

        sndMngr = new SoundManager();
        sndMngr.updateMusic('menu_start');
    }

    function loadSaveSprite(zone:String)
    {
        art.loadGraphic(AssetHelper.getAsset('images/menu/saveFile/save_${zone}', IMAGE));
        art.antialiasing = false;
        art.setGraphicSize(Std.int(art.width * 3));
        art.updateHitbox();

        art.x = (FlxG.width * 0.5) - (art.width * 0.5);
        art.y = (FlxG.height) - (art.height) - 50;
        add(art);
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        window.controlCheck();

        if (Controls.UT_ACCEPT_P)
        {
            confirmPress();
        }
    }

    private function confirmPress()
    {
        window.menu.callSelectedFunction();
    }

    private function loadOverworld()
    {
        FlxTransitionableState.skipNextTransOut = true;
        FlxG.switchState(new Overworld());
    }

    private function loadMemLog()
    {
        FlxTransitionableState.skipNextTransOut = true;
        FlxG.switchState(new MemoryLogMenu());
    }
}