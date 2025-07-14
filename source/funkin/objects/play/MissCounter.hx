package funkin.objects.play;

import forever.display.ForeverSprite;
import flixel.group.FlxGroup;
import flixel.FlxObject;
import uty.objects.UTText;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;

class MissCounter extends FlxTypedGroup<FlxObject>
{
    //objects
    public var heart:ForeverSprite;
    public var missNum:UTText;
    public var missText:UTText;

    //state
    public var fc:Bool = true;

    //variables
    public var maxMissWidth:Float;
    public var maxMissHeight:Float;
    public var centerPoint:FlxPoint;
    public var missString:String = "MISSED";

    //finals
    public final _missFont:String = "mars-needs-cunnilingus";

    public function new(?x:Float = 0, ?y:Float = 0)
    {
        super();
        loadSprite();
        loadText();
        add(heart);
        add(missNum);
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
        missNum = new UTText(0, 0, heart.width * .60, "");
        missNum.setFont(MARS, 32);
        missNum.setBorder();

        missText = new UTText(0, 0, heart.width * .80, "");
        missText.setFont(MARS, 16);
        missText.setBorder(2);
    }

    private function position(?x:Float = 0, y:Float = 0)
    {
        if(centerPoint == null) 
            centerPoint = new FlxPoint(x, y);

        heart.setPosition(centerPoint.x - (heart.width / 2), centerPoint.y - (heart.height / 2));
        missNum.setPosition(centerPoint.x - (missNum.width / 2), centerPoint.y - (missNum.height / 2) - 10);
        missText.setPosition(centerPoint.x - (missText.width / 2), centerPoint.y - (missNum.height / 2) + 40);
    }

    public function updateHUDPreset(data:Dynamic)
    {
        heart.alpha = data.sprite.alpha;
        heart.scale.set(data.sprite.scale, data.sprite.scale);
        missNum.alpha = data.number.alpha;
        missNum.scale.set(data.number.scale, data.number.scale);
        missNum.setBorder(data.number.border);
        missText.alpha = data.text.alpha;
        missText.scale.set(data.text.scale, data.text.scale);
        missText.setBorder(data.text.border);

        position();
        heart.x += data.sprite.xOffset;
        heart.y += data.sprite.yOffset;
        missNum.x += data.number.xOffset;
        missNum.y += data.number.yOffset;
        missText.x += data.text.xOffset;
        missText.y += data.text.yOffset;
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
            missNum.text = "";
            missText.text = "";
        }
        else
        {
            breakFC();
            missNum.text = "" + misses;
            missText.text = missString;
        }
    }

    public function breakFC()
    {
        if(fc)
        {
            fc = false;
            heart.animation.play("miss");
            missNum.visible = true;
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