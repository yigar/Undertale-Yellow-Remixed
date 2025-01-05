package uty.ui;
import flixel.group.FlxSpriteGroup;
import flixel.addons.display.FlxPieDial;
import uty.objects.UTText;
import flixel.util.FlxColor;

class OverworldQuit extends FlxSpriteGroup
{
    public var text:UTText;
    public var dial:FlxPieDial;
    public var dialBG:FlxPieDial;

    public function new()
    {
        super();

        text = new UTText(5, 5, 0, 'QUITTING', 18);
        text.setFont(MARS, 18);
        text.setBorder(3);

        dial = new FlxPieDial(162, 7, 12, FlxColor.WHITE, 60);
        dial.amount = 0.0;

        add(text);
        add(dial);
        
        //alpha = 1.0;
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);

        //this pie dial is fucking retarded, it randomly flickers to full/empty around 0 and there's no fix
        if(dial.amount <= 0) {
            dial.visible = false;
            alpha -= (2 * elapsed);
        }
        else {
            dial.visible = true;
            alpha += (5 * elapsed);
        }

        if(alpha > 1) alpha = 1.0;
        else if(alpha < 0) alpha = 0.0;
    }
    
}
