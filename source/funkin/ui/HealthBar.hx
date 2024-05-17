package funkin.ui;

import flixel.FlxCamera;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxPoint;
import forever.display.ForeverSprite;
import haxe.ds.Vector;
import flixel.text.FlxText;
import flixel.ui.FlxBar;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import uty.components.PlayerData;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.math.FlxPoint;
import flixel.FlxObject;

class HealthBar extends FlxSpriteGroup
{
    //yeah yeah i know FlxBar is cringe or whatever and there's a progress bar class 
    //but i need dynamic bar width and not a lot of fancy visual stuff, sorry!
    public var bar:FlxBar;
    public var border:FlxSprite;
    public var hpText:FlxText;
    public var loveText:FlxText;
    public var hpSprite:FlxSprite;

    public var lvData:Dynamic;

    public var compactMode:Bool = false;
    public var barThickness:Int = 32;
    public var borderThickness:Int = 5;
    public final minLength:Int = 200;
    public final maxLength:Int = 720;

    public final _font:String = "mars-needs-cunnilingus";

    public function new(x:Float, y:Float, love:Int = 1)
    {
        super(x, y);

        lvData = PlayerData.loveValues.get(love);
        //just for the sake of being dynamic here, i know i could just write 20 and 99 but that ain't good code, now is it?
        var lv1Data:Dynamic = PlayerData.loveValues.get(1);
        var lv20Data:Dynamic = PlayerData.loveValues.get(20);

        trace("LV: " + lvData[0] + "LV1: " + lv1Data[0] + "LV20: " + lv20Data[0]);
        var barLength = FlxMath.lerp(minLength, maxLength, (lvData[0] - lv1Data[0]) / (lv20Data[0] - lv1Data[0]));

        //bar should be minLength at LV 1, maxLength at LV 20, and interped in between if any other level.
        bar = new FlxBar(0, 0, RIGHT_TO_LEFT, barLength, 
            compactMode ? barThickness /2 : barThickness);
        bar.createFilledBar(0x660000, 0xFFFF00, false, FlxColor.BLACK);

        border = new FlxSprite().makeGraphic(Std.int(bar.width + (borderThickness * 2)), Std.int(bar.height + (borderThickness * 2)), FlxColor.BLACK);

        loveText = new FlxText(0, 0, 18, "");
        loveText.setFormat(Paths.font(_font), 18, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        loveText.setBorderStyle(OUTLINE, FlxColor.BLACK, 4);
        loveText.antialiasing = false;

        hpText = new FlxText(0, 0, 24, "");
        hpText.setFormat(Paths.font(_font), 24, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        hpText.setBorderStyle(OUTLINE, FlxColor.BLACK, 4);
        hpText.antialiasing = false;

        hpSprite = new FlxSprite();
        hpSprite.loadGraphic(Paths.image('ui/undertale/hp'));
        hpSprite.antialiasing = false;
        
        add(border);
        add(bar);
        add(hpSprite);
        add(loveText);
        add(hpText);

        position(x, y);
    }

    public function position(x:Float, y:Float)
    {
        bar.setPosition(x - (bar.width / 2), y - (bar.height / 2));
        border.setPosition(bar.x - borderThickness, bar.y - borderThickness);
        hpText.setPosition(x, y - bar.height - 10);
        loveText.setPosition(hpText.x - 200, hpText.y);
        hpSprite.setPosition(hpText.x + hpText.width + 50, hpText.y);
    }

    public function updateBar(playerHealth:Int)
    {
        hpText.text = '${playerHealth}  /  ${lvData[0]}';

        bar.percent = (playerHealth / lvData[0]);
        bar.updateBar();
    }
}