package uty.objects;

import flixel.tile.FlxTilemap;

//basically just a custom tilemap class made to work with the draw order process stuff that i need it to.
//can add other functions later if needed
class OverworldTilemap extends FlxTilemap
{
    public var worldHeight:Float = 0.0;
    public var drawHeight:Int = 0; //a value assigned in Ogmo that determines draw order independent of height. prioritize over worldHeight.

    public function new()
    {
        super();
    }

    public function setDrawHeight(h:Int = 0){
        drawHeight = h;
    }

}