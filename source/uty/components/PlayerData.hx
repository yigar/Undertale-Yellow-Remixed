package uty.components;

import openfl.display.IBitmapDrawable;
import openfl.utils.IAssetCache;
import flixel.math.FlxMath;
import haxe.ds.StringMap;
import flixel.FlxG;
import uty.components.Inventory;
import uty.components.StoryData;

enum LOVEData{
    LOVEData(hp:Int, at:Int, df:Int);
}

//data to save about the player's game state.
typedef PlayerSave = 
{
    love:Int,
    health:Int,
    room:String,
    posX:Int,
    posY:Int,
    inventory:InventoryItems,
    gold:Int
}

/*
    enemies do one extra damage every 21, 30, 40, etc. hp
*/

//tracks the player's game data 
class PlayerData
{
    public static final loveValues:Map<Int, LOVEData> = [
        1 => LOVEData(20, 0, 0),
        2 => LOVEData(24, 2, 0),
        3 => LOVEData(28, 4, 0),
        4 => LOVEData(32, 6, 0),
        5 => LOVEData(36, 8, 1),
        6 => LOVEData(40, 10, 1),
        7 => LOVEData(44, 12, 1),
        8 => LOVEData(48, 14, 1),
        9 => LOVEData(52, 16, 2),
        10 => LOVEData(56, 18, 2),
        11 => LOVEData(60, 20, 2),
        12 => LOVEData(64, 22, 2),
        13 => LOVEData(68, 24, 3),
        14 => LOVEData(72, 26, 3),
        15 => LOVEData(76, 28, 3),
        16 => LOVEData(80, 30, 3),
        17 => LOVEData(84, 32, 4),
        18 => LOVEData(88, 34, 4),
        19 => LOVEData(92, 36, 4),
        20 => LOVEData(99, 38, 4)
    ];

    public static function returnDefault():PlayerSave
    {
        var dummySave:PlayerSave = {
            love: 1,
            health: 20,
            room: "testLevel",
            posX: 200,
            posY: 200,
            inventory: Inventory.returnDefault(),
            gold: 0
        };
        return dummySave;
    }

    //returns a new variable and null-safeties it.
    public static function launderData(save:PlayerSave):PlayerSave
    {
        var def = returnDefault();
        var newSave:PlayerSave = {
            love: save.love ?? def.love,
            health: save.health ?? def.health,
            room: save.room ?? def.room,
            posX: save.posX ?? def.posX,
            posY: save.posY ?? def.posY,
            inventory: Inventory.launderData(save.inventory),
            gold: save.gold ?? def.gold
        };
        return newSave;
    }

    public static function getActiveLOVE():Int
    {
        return StoryData.getActiveData().playerSave.love;
    }

    public static function getActiveHP():Int
    {
        return loveToHP(getActiveLOVE());
    }

    public static function getActiveAT():Int
    {
        var at:Int = 0;
        at += loveToAT(getActiveLOVE());
        at += Inventory.getActiveAT();
        return at;
    }

    public static function getActiveDF():Int
    {
        var df:Int = 0;
        df += loveToDF(getActiveLOVE());
        df += Inventory.getActiveDF();
        return df;
    }

    //maybe it's fucking stupid to use this over and over instead of just storing the values, change later perhaps?
    public static function loveToHP(love:Int):Int
    {
        return _getLV(love)[0];
    }

    public static function loveToAT(love:Int):Int
    {
        return _getLV(love)[1];
    }

    public static function loveToDF(love:Int):Int
    {
        return _getLV(love)[2];
    }

    private static function _getLV(love:Int):Dynamic
    {
        return loveValues.get(love);
    }

}