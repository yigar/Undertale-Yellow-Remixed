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

    public var barThickness:Int = 32;
    public var barLength:Int;
    public var borderThickness:Int = 5;
    public final minLength:Int = 120;
    public final maxLength:Int = 500;

    public var centerPoint:FlxPoint;

    public final _font:String = "mars-needs-cunnilingus";
    public var dividerString:String = " / ";

    public function new(x:Float, y:Float, love:Int = 1)
    {
        super(x, y);
        
        //just for the sake of being dynamic here, i know i could just write 20 and 99 but that ain't good code, now is it?
        var lv1Data:Dynamic = PlayerData.loveValues.get(1);
        var lv20Data:Dynamic = PlayerData.loveValues.get(20);

        barLength = Std.int(FlxMath.lerp(minLength, maxLength, (Timings.maxHealth - lv1Data[0]) / (lv20Data[0] - lv1Data[0])));

        //bar should be minLength at LV 1, maxLength at LV 20, and interped in between if any other level.
        createBar(barLength, barThickness, FlxColor.YELLOW, FlxColor.RED, borderThickness);

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

    private function createBar(length:Int, thickness:Int, fill:FlxColor, empty:FlxColor, bord:Int)
    {
        bar = new FlxBar(0, 0, LEFT_TO_RIGHT, length, barThickness);
        bar.createFilledBar(empty, fill);

        border = new FlxSprite().makeGraphic(Std.int(bar.width + (bord * 2)), Std.int(bar.height + (bord * 2)), FlxColor.BLACK);
        if(bord <= 0)
            border = new FlxSprite().makeGraphic(0,0, FlxColor.BLACK);
    }

    public function position(?x:Float = 0, y:Float = 0)
    {
        if(centerPoint == null) 
            centerPoint = new FlxPoint(x, y);

        bar.setPosition(centerPoint.x - (bar.width / 2), centerPoint.y - (bar.height / 2));
        border.setPosition(bar.x - borderThickness, bar.y - borderThickness);
        hpText.setPosition(centerPoint.x - (hpText.width / 2), centerPoint.y + (border.height) - hpText.height + 30);
        loveText.setPosition(hpText.x - loveText.width - 40, centerPoint.y + (border.height) - loveText.height + 30);
        hpSprite.setPosition(hpText.x + hpText.width + 32, centerPoint.y + (border.height) - hpSprite.height + 30);
    }

    public function updateBar(playerHealth:Int)
    {
        hpText.text = playerHealth + dividerString + Timings.maxHealth;
        hpText.updateHitbox();

        bar.percent = (playerHealth / Timings.maxHealth * 100);
    }

    public function updateHUDPreset(data:Dynamic)
    {
        dividerString = data.hpText.divider;
        bar.alpha = data.bar.alpha;
        bar.scale.set(data.bar.lengthMult, data.bar.thickMult);
        bar.updateHitbox();

        border.visible = (data.bar.border > 0);
        
        hpText.alpha = data.hpText.alpha;
        hpText.scale.set(data.hpText.scale, data.hpText.scale);
        hpText.setBorder(data.hpText.border);
        hpSprite.alpha = data.hpSprite.alpha;
        hpSprite.scale.set(data.hpSprite.scale, data.hpSprite.scale);
        loveText.alpha = data.loveText.alpha;
        loveText.scale.set(data.loveText.scale, data.loveText.scale);
        loveText.setBorder(data.loveText.border);

        position();
        bar.x += data.bar.xOffset;
        bar.y += data.bar.yOffset;
        border.x += data.bar.xOffset;
        border.y += data.bar.yOffset;
        hpText.x += data.hpText.xOffset;
        hpText.y += data.hpText.yOffset;
        hpSprite.x += data.hpSprite.xOffset;
        hpSprite.y += data.hpSprite.yOffset;
        loveText.x += data.loveText.xOffset;
        loveText.y += data.loveText.yOffset;
        updateHitboxes();
    }

    private inline function updateHitboxes(){
        hpText.updateHitbox();
        hpSprite.updateHitbox();
        loveText.updateHitbox();
        bar.updateHitbox();
    }
}