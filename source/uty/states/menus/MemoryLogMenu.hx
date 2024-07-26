package uty.states.menus;

import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.sound.FlxSound;
import flixel.util.FlxColor;
import forever.display.ForeverSprite;
import forever.display.ForeverText;
import funkin.components.ChartLoader;
import funkin.components.Difficulty;
import funkin.components.Highscore;
import funkin.states.base.BaseMenuState;
import flixel.FlxSprite;
import uty.ui.ScrollSelectionList;

//this is basically freeplay plus a gallery.

//note: create a sub-menu with individual songs for each character, displaying art and rank.

class MemoryLogMenu extends BaseMenuState
{
    public var bg:FlxSprite;
    public var characterList:ScrollSelectionList;

    override function create()
    {
        add(bg = new FlxSprite().makeSolid(FlxG.width, FlxG.height, 0xFF000000));

        characterList = new ScrollSelectionList(200, 400);
        add(characterList);

        for(i in 0...10)
        {
            characterList.addOption('test${i}', 'images/menu/memory/icons/ceroba');
        }
        characterList.changeSelection(0); //updates stuff
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        controlCheck();
    }

    public function controlCheck()
    {
        if(Controls.UI_DOWN_P)
            characterList.addSelection(1);
        if(Controls.UI_UP_P)
            characterList.addSelection(-1);
    }


}
