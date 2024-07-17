package uty.components;

import flixel.math.FlxMath;
import haxe.ds.StringMap;

//data for opponents, like the exp they're worth and if they were spared or killed, should possibly go here

//data structure for specific opponents in-game. affects gameplay.
@:structInit class OpponentData {

    public var name:String = "flowey";
    //attack. determines how much damage you take when missing a note.
    public var at:Int = 1;
    //defense. determines how much your health regeneration is inhibited.
    public var df:Int = 0;
    //exp. due to the limited number of battles in the game, killed opponents will simply give entire levels
    public var love:Int = 0;
    //for save/storage reasons i guess. whether or not the enemy was killed.
    public var killed:Bool = false;
}

//contains static data and functions pertaining to opponents
//might want to store enemy information here. storing these in uncompiled data files would allow cheating
class Opponents
{
    public static var opponentList:Array<OpponentData> = 
    [
        {name: "flowey", at: 1, df: 0, love: 0, killed: false},
        {name: "martlet", at: 5, df: 10, love: 0, killed: false}
    ];

    public static function returnFromName(name:String):OpponentData
    {
        for(o in opponentList)
        {
            if(o.name.toLowerCase() == name.toLowerCase())
                return o;
        }
        //dummy
        return {name: "flowey", at: 1, df: 0, love: 0, killed: false};
    }
}