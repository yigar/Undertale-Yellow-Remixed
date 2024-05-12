package uty.components;

import haxe.ds.StringMap;

@:structInit class GameSave
{
    public var love:Int = 1;

    public var room:String;
    public var xPos:Float;
    public var yPos:Float;

    public var followers:Array<String>;
}