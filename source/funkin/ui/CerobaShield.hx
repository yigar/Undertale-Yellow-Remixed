package funkin.ui;

import uty.objects.DirectionParticle;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import forever.display.ForeverSprite;
import flixel.math.FlxMath;
import flixel.ui.FlxBar;

class CerobaShield extends FlxTypedSpriteGroup<FlxSprite>
{
    //sprites
    public var shield:ForeverSprite;
    public var fill:FlxBar;
    public var shards:Array<CerobaShieldShard>;
    //tweens
    public var chargeTween:FlxTween;
    public var breakTween:FlxTween;
    //variables
    public var percent:Float = 0.0;
    public var charged:Bool = false;
    public var shieldActive:Bool = true;
    public var shieldUpTime:Float = 0.0; //tracks how long the shield has been up
    public var shieldDownTime:Float = 0.0; //tracks how long the shield has been down
    //constants
    public static final startupTime:Float = 0.6;
    public static final invTime:Float = 3.0;
    public final chargeRotateTweenTime:Float = 0.3;
    public static final spriteDir:String = "images/ui/undertale/shield/cerobaShield";
    public static final downScale:Float = 1.4;
    public static final upScale:Float = 1.1;
    public static final chargePerSecond:Float = 0.00; //the charge that accumulates over time
    public static final chargePerHit:Float = 0.01; //the charge per note hit
    public static final chargeComboBonus:Float = 0.0004;
    public static final chargeCap:Float = 0.03; //cap out the charge rate at this
    public static final chargeLostOnMiss:Float = 0.40;

    public function new(x:Float, y:Float)
    {
        super(x, y);

        shield = new ForeverSprite(0, 0, spriteDir);
        shield.frames =  AssetHelper.getAsset(spriteDir, ATLAS);
        shield.addAtlasAnim('still', 'shield_still', 1, true);
        shield.addAtlasAnim('charged', 'shield_anim', 60, false);

        fill = new FlxBar(shield.width * 0.1, shield.height * 0.1, BOTTOM_TO_TOP,
            Std.int((shield.width * 0.80) - 2), Std.int((shield.height * 0.80) - 2));
        fill.createFilledBar(0x00000000, 0x77FFFFFF);
        /*
        fill = new ForeverSprite(shield.width * 0.1, shield.height * 0.1);
        fill.makeGraphic(Std.int((shield.width * 0.80) - 2), Std.int((shield.height * 0.80) - 2), FlxColor.WHITE);
        */

        add(fill);
        add(shield);

        shards = new Array<CerobaShieldShard>();
        for(i in 1...9)
        {
            var shard = new CerobaShieldShard(i);
            shard.disable();
            add(shard);
            shards.push(shard);
        }

        setToUncharged();
        shieldBreakTween();
        shield.animation.play('still');
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if(!charged)
        {
            fill.percent = this.percent * 100;
        }
        else
        {
            fill.percent = 100;
        }
    }

    //NOTE: this is different from the behavior of breaking the shield. mainly use this on instantiation.
    private function setToUncharged()
    {
        if(charged)
            shieldDownTime = 0;

        charged = false;
    }

    private function setToCharged()
    {
        //reset the timer if it's not charged
        if(!charged)
            shieldUpTime = 0;

        charged = true;
    }

    public function chargeShieldFX()
    {
        setToCharged();
        shieldChargeTween();
        shield.animation.play('charged');
    }

    public function breakShieldFX()
    {
        setToUncharged();
        scatterShards();
        shieldBreakTween();
        shield.animation.play('still');
    }

    public function shieldChargeTween()
    {
        chargeTween = FlxTween.num(0, 45, chargeRotateTweenTime, {
            ease: FlxEase.elasticOut
        }, function(n) 
        {
            var nPercent = n * 0.0225; //for 0-1 calculations
            var scl:Float = FlxMath.lerp(downScale, upScale, nPercent);

            shield.angle = n;
            shield.alpha = 0.6 + (nPercent * 0.4); //roughly 1/45, multiplication for optimization
            shield.scale.set(scl, scl);
            shield.color = FlxColor.interpolate(0xBBBBBB, 0xFFFFFF, nPercent);

            fill.angle = n;
            fill.alpha = 0.4 + (nPercent * 0.2);
            fill.scale.set(scl, scl);
        });
    }

    public function shieldBreakTween()
    {
        //for now im just making this immediate
        shield.color = 0xBBBBBB;
        shield.alpha = 0.6;
        shield.angle = 0;
        shield.scale.set(downScale, downScale);

        fill.alpha = 0.4;
        fill.angle = 0;
        fill.scale.set(downScale, downScale);
    }

    public function scatterShards()
    {
        for(i in 0...shards.length)
        {
            shards[i].resetPosition(this.x, this.y);
            shards[i].enable();
            shards[i].getRandomMomentum();
        }
    }

    function shieldChargeTweenFunc(twn:FlxTween):Void
    {

    }

}

class CerobaShieldShard extends DirectionParticle
{
    //complicated enough to warrant a child class
    public var dir:String = 'ui/undertale/shield/shards/shard';
    public var type:Int = 0;

    public final frameRate:Int = 20;
    public final shardOffsetMap: Map<Int, Array<Float>> = 
    [
        0 => [0, 0], //default
        1 => [17, -10],
        2 => [56, -9],
        3 => [-7, 12],
        4 => [-1, -1],
        5 => [72, -5],
        6 => [59, 12],
        7 => [94, 12],
        8 => [12, 65],
        9 => [46, 64]
    ];

    public function new(type:Int = 1)
    {
        this.type = type;
        var offX:Float = shardOffsetMap[type][0];
        var offY:Float = shardOffsetMap[type][1];
        super(offX, offY, dir + type, 'anim', frameRate);
        dontDestroy = true;
        setXBounds(-25.0, 10.0);
        setYBounds(-20.0, 2.0);
        gravity = 0.25;
        getRandomMomentum();
    }

    public function resetPosition(?x:Float = 0, ?y:Float = 0)
    {
        this.x = shardOffsetMap[type][0] + x;
        this.y = shardOffsetMap[type][1] + y;
        animation.frameIndex = 0;
        animation.play('anim');
    }

    //
    override function disable()
    {
        super.disable();
        //trace('DISABLED ${type}');
    }
}