package uty.components;

import flixel.math.FlxMath;
import haxe.ds.StringMap;

enum LOVEData{
    LOVEData(hp:Int, atk:Int, def:Int);
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




}