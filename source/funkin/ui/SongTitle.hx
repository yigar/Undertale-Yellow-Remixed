package funkin.ui;

import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.group.FlxGroup;
import uty.objects.UTText;
import flixel.math.FlxRect;
import forever.display.ForeverSprite;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.math.FlxPoint;
import flixel.util.FlxTimer;

class SongTitle extends FlxSpriteGroup
{
	public var name:String = "N/A";
    public var text:UTText;
	public var icon:ForeverSprite;
	public var bar:ForeverSprite;
    public var texture:String;
    public var centerPoint:FlxPoint;

    public var displayTime:Float = 5.0; //how long to show the stuff before hiding it

	public function new(?x:Int = 0, ?y:Int = 0, ?name:String, ?texture:String)
	{
		super();
		if(name != null)
			this.name = name;
		if(texture != null)
			this.texture = texture;

		icon = new ForeverSprite(x, y);
        icon.loadGraphic(Paths.image('ui/undertale/songIcon'));
        icon.antialiasing = false;
        icon.setGraphicSize(Std.int(icon.width * 3));
        icon.updateHitbox();

        centerPoint = new FlxPoint(icon.x + (icon.width * 0.5), icon.y + (icon.height * 0.5));

		bar = new ForeverSprite(centerPoint.x, y);
        bar.loadGraphic(Paths.image('ui/undertale/songBar'));
        bar.antialiasing = false;
        bar.setGraphicSize(Std.int(bar.width * 3));
        bar.updateHitbox();
        bar.y = centerPoint.y - (bar.height * 0.5);

        text = new UTText(x, y, 0, name, 20);
        //text.setFont(MARS, 20);
        text.setBorder(2);
        text.x = icon.x + (icon.width);
        text.y = icon.y + (icon.height * 0.5) - (text.height * 0.5);

        add(bar);
        add(icon);
        add(text);

        //setup
        hide();
        showAnim();
        new FlxTimer().start(displayTime, hideAnim);
	}

    public function hide()
    {
        icon.alpha = 0.0;
        bar.alpha = 0.0;
        text.alpha = 0.0;
    }

    public function showAnim()
    {
        icon.tween({alpha: 1.0}, 0.5, {
            onComplete: function(twn:FlxTween):Void {
                bar.alpha = 0.0;
                tweenBar(false, 1.5);
                text.alpha = 1.0;
                tweenLetters(false, 1.5);
            }
        });
    }

    public function hideAnim(tmr:FlxTimer)
    {
        icon.tween({alpha: 0.0}, 1.5);
        bar.tween({alpha: 0.0}, 1.5);
        tweenLetters(true, 0.8);
    }

    public function tweenBar(out:Bool = false, ?duration:Float = 1.5)
    {
        //just for measurement
        text.text = name;
        var fullLength = text.width + 50;
        var curLength = out ? fullLength : 0;
        var targetLength = out ? 0 : fullLength;

        FlxTween.num(curLength, targetLength, duration, {
            ease:FlxEase.cubeOut
        },
        function(num) {
            bar.alpha = Math.pow(num / fullLength, 0.5);
            bar.x = centerPoint.x - bar.width + num;
            var rect:FlxRect = new FlxRect(Std.int((centerPoint.x - bar.x) * 0.33), 0, Std.int(bar.width * 0.34), 16);
            bar.clipRect = rect;
        });
    }

    public function tweenLetters(out:Bool = false, ?duration:Float = 1.5)
    {
        text.text = out ? name : "";
        var curLength:Int = text.text.length;
        var targetLength:Int = out ? 0 : name.length;

        //sets the string's characters based on the tween
        FlxTween.num(curLength, targetLength, duration, {
            ease:FlxEase.sineOut
        },
        function(num) {
            text.text = name.substring(0, Math.floor(num));
        });
    }
}
