package uty.objects;

import uty.states.Overworld;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.group.FlxSpriteGroup;
import forever.display.ForeverSprite;
import flixel.math.FlxMath;

//private var controls(get, never):Controls;
//private function get_controls() return Controls.instance;
//UI controls should be the same as overworld controls

//thank you poopshitters

/*
    the player class. extends the overworldcharacter class.
    will probably contain more independent functionality later
    but its main distinction right now is the playerhitbox and having its controller hooked up to user input.
*/

class Player extends OverworldCharacter
{
    public var lockMoveInput:Bool = false;

    public function new(characterName:String = "clover", x:Float, y:Float, facing:String = "down", pixelRatio:Int = 3)
    {
        super(characterName, x, y, facing);
    }
}

class PlayerHitbox extends FlxSprite
{
    var player:Player;
    var playerOffset:Array<Float> = [0, 0];
    public var prevPosition:FlxPoint;

    public function new(player:Player)
    {
        super();
        alpha = 0.4;
        this.player = player;
        var halfHeight = Std.int(player.height / 2);
        makeGraphic(Std.int(player.width), halfHeight, 0x3800FF00);
        playerOffset = [0, halfHeight];

        prevPosition = new FlxPoint(x, y);
    }

    override function update(elapsed:Float)
    {
        //this is already run in the overworld update()
        //updatePosition();
    }

    public function updatePosition()
    {
        prevPosition.set(x, y);

        x = player.x + playerOffset[0];
        y = player.y + playerOffset[1];
    }
}