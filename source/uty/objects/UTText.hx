package uty.objects;

import flixel.text.FlxText;
import flixel.util.FlxColor;
import openfl.text.TextFormat;

enum abstract UTFont(String) from String to String
{
    var DEFAULT:String = "pixela-extreme";
    var PIXELA:String = "pixela-extreme";
    var MARS:String = "mars-needs-cunnilingus"; //lol
    var DOTUMCHE:String = "dotumche-pixel";
    var CRYPT:String = "crypt-of-tomorrow";
    var SANS:String = "comic-sans-undertale";
}

//a class that extends FlxText to make setup easier and more included for most of my purposes.
//this intentionally removes some control in order to streamline usage.
//if you need a less restricted FlxText then just use that instead.
class UTText extends FlxText
{
    public var format:TextFormat;

    public function new(?x:Int = 0, ?y:Int = 0, ?fieldWidth:Float = 0, ?text:String = '', ?size:Int = 38)
    {
        super(x, y, fieldWidth, text, size);
        setFont(PIXELA, size);
        antialiasing = false;
        updateHitbox();
    }

    public function setFont(font:UTFont = PIXELA, ?size:Int = 38, ?color:FlxColor = 0xFFFFFFFF, 
        ?align:FlxTextAlign = CENTER, ?spacing:Float = 1, ?leading:Int)
    {
        setFormat(Paths.font(font), size, color, align);

        if(spacing == null && leading == null)
            return;

        if(leading != null) 
            _defaultFormat.leading = leading;
        if(spacing != null) 
            _defaultFormat.letterSpacing = spacing;

        updateDefaultFormat();
    }

    public function setAlign(align:FlxTextAlign)
    {
        setFont(this.font, this.size, this.color, align, _defaultFormat.letterSpacing);
        updateHitbox();
    }

    public function setBorder(?thickness:Int = 4, ?color:FlxColor = 0xFF000000)
    {
        setBorderStyle(OUTLINE, color, thickness);
        updateHitbox();
    }


}