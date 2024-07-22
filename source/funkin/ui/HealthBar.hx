package funkin.ui;

import flixel.FlxCamera;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxPoint;
import forever.display.ForeverSprite;
import haxe.ds.Vector;
import flixel.ui.FlxBar;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import uty.components.PlayerData;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.math.FlxPoint;
import flixel.FlxObject;
import funkin.components.Timings;
import uty.objects.UTText;

class HealthBar extends FlxSpriteGroup
{
    //yeah yeah i know FlxBar is cringe or whatever and there's a progress bar class 
    //but i need dynamic bar width and not a lot of fancy visual stuff, sorry!
    public var bar:FlxBar;
    public var border:FlxSprite;
    public var hpText:UTText;
    public var loveText:UTText;
    public var hpSprite:FlxSprite;

    public var lvData:Dynamic;

    public var compactMode:Bool = false;
    public var barThickness:Int = 32;
    public var borderThickness:Int = 5;
    public final minLength:Int = 120;
    public final maxLength:Int = 500;

    public final _font:String = "mars-needs-cunnilingus";

    public function new(x:Float, y:Float, love:Int = 1)
    {
        super(x, y);
        
        //just for the sake of being dynamic here, i know i could just write 20 and 99 but that ain't good code, now is it?
        var lv1Data:Dynamic = PlayerData.loveValues.get(1);
        var lv20Data:Dynamic = PlayerData.loveValues.get(20);

        var barLength:Int = Std.int(FlxMath.lerp(minLength, maxLength, (Timings.maxHealth - lv1Data[0]) / (lv20Data[0] - lv1Data[0])));

        //bar should be minLength at LV 1, maxLength at LV 20, and interped in between if any other level.
        bar = new FlxBar(0, 0, RIGHT_TO_LEFT, barLength,
            Std.int(compactMode ? barThickness / 2 : barThickness));
        bar.createFilledBar(FlxColor.RED, FlxColor.YELLOW);
        //suck my cock FlxBar. fuck you. i hate you
        //why in mother fuck would you IGNORE float inputs instead of compile erroring or just converting them

        border = new FlxSprite().makeGraphic(Std.int(bar.width + (borderThickness * 2)), Std.int(bar.height + (borderThickness * 2)), FlxColor.BLACK);

        loveText = new UTText();
        loveText.setFont(MARS, 24);
        loveText.setBorder();
        loveText.text = "LV " + love;
        loveText.updateHitbox();

        hpText = new UTText();
        hpText.setFont(MARS, 30);
        hpText.setBorder();

        hpSprite = new FlxSprite();
        hpSprite.loadGraphic(Paths.image('ui/undertale/hp'));
        hpSprite.antialiasing = false;
        
        add(border);
        add(bar);
        add(hpSprite);
        add(loveText);
        add(hpText);

        updateBar(Timings.health);
        position(x, y);
    }

    public function position(x:Float, y:Float)
    {
        bar.setPosition(x - (bar.width / 2), y - (bar.height / 2));
        border.setPosition(bar.x - borderThickness, bar.y - borderThickness);
        hpText.setPosition(x - (hpText.width / 2), y + (border.height) - hpText.height + 30);
        loveText.setPosition(hpText.x - loveText.width - 40, y + (border.height) - loveText.height + 30);
        hpSprite.setPosition(hpText.x + hpText.width + 32, y + (border.height) - hpSprite.height + 30);
    }

    public function updateBar(playerHealth:Int)
    {
        hpText.text = '${playerHealth} / ${Timings.maxHealth}';
        hpText.updateHitbox();

        bar.percent = (playerHealth / Timings.maxHealth * 100);
    }
}