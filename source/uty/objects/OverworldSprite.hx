package uty.objects;

import uty.states.Overworld;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.group.FlxSpriteGroup;
import forever.display.ForeverSprite;
import flixel.math.FlxMath;
import flixel.util.FlxColor;

enum abstract DrawLayer(Int) to Int{
    var FOREGROUND = 1;
    var DEFAULT = 0;
    var BACKGROUND = -1;
}

//sprites with basic discernable variables needed for the overworld, particularly height
class OverworldSprite extends FlxSpriteGroup
{
    public var name:String = "NewSprite"; //for identification
    public var sprite:ForeverSprite;

    public var worldHeight:Float; //determines draw order. do not change this.
    public var elevation:Float; //affects the height. a higher elevation means the sprite will draw later relative to others at the same y pos.
    public var drawHeight:Int; //a value assigned in Ogmo that determines draw order independent of height. prioritize over worldHeight.
    public var layer:Int; //if FOREGROUND: always draw on top. if BACKGROUND: always draw before everything else.

    public var bottomCenter:FlxPoint; //this is the object/character's "feet": used for pathfinding and other stuff.

    private final _pixelRatio:Int = 3;

    public function new(x:Float, y:Float, ?elevation:Float = 0.0, ?layer:Int = DEFAULT, ?drawHeight:Int = 0, ?name:String = "NewSprite")
    {
        super(x, y);
        sprite = new ForeverSprite(0, 0);

        worldHeight = this.y; //temporary
        this.name = name;
        this.elevation = elevation;
        this.layer = layer;
        this.drawHeight = drawHeight;
        bottomCenter = new FlxPoint();
    }

    public function loadSprite(spr:String, ?animated:Bool = false):OverworldSprite
    {
        trace("loading overworld sprite");
        //get da sprite
        sprite.loadGraphic(AssetHelper.getAsset(spr, IMAGE));
        if(animated)
            sprite.frames = AssetHelper.getAsset(spr, ATLAS);

        sprite.antialiasing = false;
        sprite.setGraphicSize(Std.int(sprite.width * _pixelRatio));
        sprite.updateHitbox();
        this.add(sprite);

        return this;
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        bottomCenter.x = this.x + (sprite.width / 2);
        bottomCenter.y = this.y + sprite.height;

        worldHeight = bottomCenter.y + elevation;
    }
}