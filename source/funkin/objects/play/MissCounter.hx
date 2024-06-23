package funkin.objects.play;

import forever.display.ForeverSprite;
import flixel.group.FlxGroup;
import flixel.FlxObject;
import flixel.text.FlxText;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;

class MissCounter extends FlxTypedGroup<FlxObject>
{
    //objects
    public var heart:ForeverSprite;
    public var missText:FlxText;

    //state
    public var fc:Bool = true;

    //variables
    public var maxMissWidth:Float;
    public var maxMissHeight:Float;
    public var centerPoint:FlxPoint;

    //finals
    public final _missFont:String = "mars-needs-cunnilingus";

    public function new(?x:Float = 0, ?y:Float = 0)
    {
        super();
        loadSprite();
        loadText();
        add(heart);
        add(missText);
        position(x, y);

        heart.visible = false;
    }

    private function loadSprite()
    {
        heart = new ForeverSprite();
        heart.loadGraphic(Paths.image('ui/undertale/fc'));
        heart.frames = Paths.getSparrowAtlas('ui/undertale/fc');
        heart.addAtlasAnim("fc", "fc", 24, false);
        heart.addAtlasAnim("miss", "miss", 0, false);

        heart.scale.set(0.80, 0.80);
    }

    private function loadText()
    {
        missText = new FlxText(0, 0, heart.width * .60, "");
        missText.setFormat(Paths.font(_missFont), 32, 0xFFFFFF, CENTER, OUTLINE, FlxColor.BLACK);
        missText.setBorderStyle(OUTLINE, FlxColor.BLACK, 4);
        missText.antialiasing = false;
    }

    private function position(?x:Float, y:Float)
    {
        if(x != null) centerPoint = new FlxPoint(x, y);

        heart.setPosition(centerPoint.x - (heart.width / 2), centerPoint.y - (heart.height / 2));
        missText.setPosition(centerPoint.x - (missText.width / 2), centerPoint.y - (missText.height / 2) - 10);
    }

    public function updateMisses(misses:Int)
    {
        if(!heart.visible) heart.visible = true;

        if(misses < 0)
        {
            heart.visible = false;
            return;
        }

        if(misses == 0)
        {
            missText.text = "";
        }
        else
        {
            breakFC();
            missText.text = "" + misses;
        }
    }

    public function breakFC()
    {
        if(fc)
        {
            fc = false;
            heart.animation.play("miss");
            missText.visible = true;
        }
    }

    public function heartPulse()
    {
        if(fc)
        {
            heart.animation.play("fc");
        }
    }
}