package uty.components;

import openfl.utils.IAssetCache;
import flixel.math.FlxMath;
import haxe.ds.StringMap;
import flixel.FlxG;

enum LOVEData{
    LOVEData(hp:Int, atk:Int, def:Int);
}

//data to save about the player's game state.
@:structInit class PlayerSave {
    public var love:Int;
    public var health:Int;
    public var room:String;
    public var posX:Int;
    public var posY:Int;
}

/*
    enemies do one extra damage every 21, 30, 40, etc. hp
*/

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

    private static final dummySave:PlayerSave = {
        love: 1,
        health: 20,
        room: "testLevel4",
        posX: 200,
        posY: 200
    };

    public static var activeSave:PlayerSave = dummySave;

    public static function loveToHP(love:Int):Int
    {
        return _getLV(love)[0];
    }

    public static function loveToAtk(love:Int):Int
    {
        return _getLV(love)[1];
    }

    public static function loveToDef(love:Int):Int
    {
        return _getLV(love)[2];
    }

    private static function _getLV(love:Int):Dynamic
    {
        return loveValues.get(love);
    }


    /*
     * SAVING STUFF
     */

    public static function savePlayerData(data:PlayerSave):Void
    {
        _setSave(data);
    }

    public static function getPlayerData():PlayerSave
    {
        return _getSave();
    }

    @:dox(hide)
    private static inline function _getSave():PlayerSave
    {
        return activeSave ?? dummySave;
    }

    private static function _setSave(save:PlayerSave):Void
    {
        activeSave = save;
    }




}