package uty.components;

import haxe.ds.StringMap;
import uty.components.PlayerData;
import flixel.FlxG;

@:structInit class StorySave
{
    public var playerSave:PlayerSave;

    public var followers:Array<String>;

    public var killedCharacters:Array<String>;
}

class StoryData
{
    public static var activeSave:StorySave;
}