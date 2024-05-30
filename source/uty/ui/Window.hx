package uty.ui;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;

class Window extends FlxSpriteGroup
{
    //this is gonna be quick and shitty for now

    public var border:FlxSprite;
    public var center:FlxSprite;

    public var borderClr:FlxColor = FlxColor.WHITE;
    public var centerClr:FlxColor = FlxColor.BLACK;

    public function new(x:Int, y:Int, width:Int, height:Int, ?borderThickness:Int = 5)
    {
        super(x, y);

        border = new FlxSprite().makeGraphic(width, height, borderClr);
        center = new FlxSprite().makeGraphic(width - (borderThickness * 2), height - (borderThickness * 2), centerClr);
        center.x += borderThickness;
        center.y += borderThickness;

        border.antialiasing = false;
        center.antialiasing = false;

        add(border);
        add(center);
    }
}