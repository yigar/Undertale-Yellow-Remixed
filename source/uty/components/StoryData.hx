package uty.components;

import haxe.ds.StringMap;
import flixel.FlxG;
import uty.components.PlayerData;

class StorySave
{
    public var playerSave:PlayerSave;

    public var followers:Array<String> = [];

    public var killedCharacters:Array<String> = [];

    public function new():Void 
    {
        playerSave = PlayerData.playerSave;
    }
}

class StoryData
{
    private static final dummySave:StorySave = new StorySave();

    //THIS DISTINCTION IS IMPORTANT FOR PREVENTING AUTO-SAVING
    private static var storySave:StorySave = dummySave; //this one gets shared to the FlxSave: the saved game progress.
    public static var activeData:StorySave = dummySave; //this one does NOT get bound to Flxsave: the current unsaved progress.

    //updates the active game data with the provided storySave object.
    public static function setActiveData(data:StorySave):Void
    {
        activeData = data;
    }

    //returns the active data variable that reflects immediate game status
    public static function getActiveData():StorySave
    {
        return activeData;
    }

    //returns the story save variable that's bound to the save file
    public static function getSaveData():StorySave
    {
        return storySave;
    }

    //overwrites the save data with the active game data.
    //this SHOULD be kept a separate function from updating the active data because I don't want the two to get confused
    public static function saveData():Void
    {
        storySave = activeData;
        _setSave(storySave);
    }

    //loads the save file and sets the active game data equal to it.
    public static function loadData()
    {
        storySave = _getSave();
        activeData = storySave;
    }

    @:dox(hide)
    private static inline function _getSave():StorySave
    {
        FlxG.save.bind('utyRemixed', 'yigar/UTYRemixed/uty');
        if(FlxG.save.isBound && FlxG.save.data.storySave != null)
        {
            return FlxG.save.data.storySave;
        }
        else return dummySave;
    }

    private static function _setSave(save:StorySave):Void
    {
        FlxG.save.bind('utyRemixed', 'yigar/UTYRemixed/uty');
        if(FlxG.save.isBound)
        {
            FlxG.save.data.storySave = save;
            FlxG.save.flush();
        }
    }
}