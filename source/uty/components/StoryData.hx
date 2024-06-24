package uty.components;

import haxe.ds.StringMap;
import flixel.FlxG;
import uty.components.PlayerData;

typedef StorySave =
{
    playerSave:PlayerSave,
    followers:Array<String>,
    killedCharacters:Array<String>
}

class StoryData
{
    //THIS DISTINCTION IS IMPORTANT FOR PREVENTING AUTO-SAVING
    private static var storySave:StorySave; //this one gets shared to the FlxSave: the saved game progress.
    public static var activeData:StorySave; //this one does NOT get bound to Flxsave: the current unsaved progress.

    public static function returnDefault():StorySave
    {
        var dummySave:StorySave = {
            playerSave: PlayerData.returnDefault(),
            followers: [],
            killedCharacters: []
        };
        return dummySave;
    }

    //writing these functions to separate storySave from activeData.
    //simply setting them equal to each other doesn't work, it makes them the same object.
    //this is probably a really dumbass solution. dont ask. i'm not a good programmer -yigar
    public static function launderData(save:StorySave):StorySave
    {
        var newSave = {
            playerSave: PlayerData.launderData(save.playerSave),
            followers: save.followers,
            killedCharacters: save.killedCharacters
        };
        return newSave;
    }

    //updates the active game data with the provided storySave object.
    public static function setActiveData(data:StorySave):Void
    {
        activeData = data;
        trace('ACTIVE LV: ${activeData.playerSave.love}');
        trace('STORY LV: ${storySave.playerSave.love}');
        trace('DUMMY LV: ${returnDefault().playerSave.love}');
    }

    //returns the active data variable that reflects immediate game status
    public static function getActiveData():StorySave
    {
        if (activeData == null) return returnDefault();
        return launderData(activeData);
    }

    //returns the story save variable that's bound to the save file
    public static function getSaveData():StorySave
    {
        return launderData(storySave) ?? returnDefault();
    }

    //overwrites the save data with the active game data.
    //this SHOULD be kept a separate function from updating the active data because I don't want the two to get confused
    public static function saveData():Void
    {
        storySave = launderData(activeData);
        _setSave(storySave);
    }

    //loads the save file and sets the active game data equal to it.
    public static function loadData()
    {
        storySave = _getSave();
        activeData = launderData(storySave);
    }

    @:dox(hide)
    private static inline function _getSave():StorySave
    {
        FlxG.save.bind('utyRemixed', 'yigar/UTYRemixed/uty');
        if(FlxG.save.isBound && FlxG.save.data.storySave != null)
        {
            return FlxG.save.data.storySave;
        }
        else return returnDefault();
    }

    private static function _setSave(save:StorySave):Void
    {
        FlxG.save.bind('utyRemixed', 'yigar/UTYRemixed/uty');
        if(FlxG.save.isBound)
        {
            FlxG.save.data.storySave = save;
            FlxG.save.flush();
            trace("GAME SAVED");
        }
    }
}

class StoryUtil
{
    //utility class for setting some values quickly

    public static function restoreHP(heal:Int, ?overheal:Bool = false)
    {
        var dum:StorySave = StoryData.getActiveData();
        var maxHP = PlayerData.loveToHP(dum.playerSave.love);
        if(dum.playerSave.health + heal < maxHP || overheal)
        {
            dum.playerSave.health += heal;
        }
        else
        {
            dum.playerSave.health = maxHP;
        }
        StoryData.setActiveData(dum);
    }

    public static function setLV(lv:Int, ?add:Bool = false)
    {
        var dum:StorySave = StoryData.getActiveData();
        dum.playerSave.love = (add ? dum.playerSave.love + lv : lv);
    }

    public static function setSpawn(room:String, x:Int, y:Int)
    {
        var dum:StorySave = StoryData.getActiveData();
        dum.playerSave.room = room;
        dum.playerSave.posX = x;
        dum.playerSave.posY = y;
        StoryData.setActiveData(dum);
        trace('spawn set to: x${x} y${y}');
    }
}