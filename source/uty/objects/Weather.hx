package uty.objects;

import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup;
import flixel.addons.display.FlxBackdrop;
import flixel.FlxSprite;
import uty.states.Overworld;

class Weather extends FlxSpriteGroup
{
    public var fog:FlxBackdrop;

    public var snowflakes:FlxTypedSpriteGroup<Snowflake>;
    public var snowIntensity:Float = 0.0;
    private var sfRecycle:Array<Snowflake>;

    private var flakeClock:Float = 1.0;

    public function new()
    {
        super();
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);
        sfRecycle = new Array<Snowflake>();

        flakeClock -= elapsed * snowIntensity; //the clock will never reach 0 if the intensity is <= 0
        while(flakeClock <= 0)
        {
            spawnSnowflake();
            flakeClock += 1;
        }
    }

    public function clearWeather()
    {
        if(fog != null)
            fog.visible = false;
        snowIntensity = 0.0;
    }

    public function createFog(alpha:Float = 0.3)
    {
        if(fog != null) //prevents multiple fogs from being spawned
        {
            fog.visible = true;
            return;
        }
        fog = new FlxBackdrop(Paths.image('overworld/effects/fog'));
        fog.velocity.set(-50, -50);
		fog.antialiasing = false;
		fog.alpha = alpha;
        fog.scale.set(3.0, 3.0);
        fog.updateHitbox();
        add(fog);
    }

    public function spawnSnowflake(offscreen:Bool = true)
    {
        cleanupSnow(Overworld.current.room.roomBounds.bottom + 50);
        //if there's a snowflake in the recycle bin, recycle it and return.
        if(snowflakes != null && sfRecycle.length > 0)
        {
            trace('recycling snowflake');
            sfRecycle[0].y = Overworld.current.camGame.y - 50;
            sfRecycle[0].setActive(true);
            sfRecycle.shift();
            return;
        }

        trace('spawning snowflake');
        var rand = FlxG.random.int(-1, 2); //give a little preference to smaller flakes
        var sf:Snowflake = new Snowflake(rand);

        sf.x = FlxG.random.float(0, Overworld.current.room.roomBounds.right);
        if(offscreen){
            sf.y = Overworld.current.camGame.y - 50;
        }
        else {
            sf.y = FlxG.random.float(-50, Overworld.current.room.roomBounds.bottom);
        }

        if(snowflakes == null){
            snowflakes = new FlxTypedSpriteGroup<Snowflake>();
            add(snowflakes);
        }    
        snowflakes.add(sf);
    }

    function cleanupSnow(maxY:Float)
    {
        if(snowflakes != null)
        {
            for(s in snowflakes)
            {
                if (s.y > maxY)
                {
                    s.setActive(false);
                    sfRecycle.push(s);
                }
            }
        }
    }
}

class Snowflake extends FlxSprite
{
    public var paused:Bool = false; //to conserve calculations.
    public var rotation:Float; //degrees per second
    public var fallSpeed:Float; //pixels per second
    public var horSpeed:Float;

    private final dir:String = "overworld/effects/";
    private var variant:Int;

    public function new(variant:Int)
    {
        super();

        if(variant > 2) variant = 2;
        if(variant < 0) variant = 0;
        this.variant = variant;
        this.loadGraphic(Paths.image('${dir}snowflake${variant}'));
        this.scale.set(3.0, 3.0);
        this.updateHitbox();
        this.antialiasing = false;

        randomizeVars();
    }

    public function randomizeVars()
    {
        rotation = FlxG.random.float(65, 100);
        rotation = (FlxG.random.bool() ? rotation : -rotation);

        fallSpeed = FlxG.random.float(20, 100 * ((variant * 0.5) + 1)); //big snowflakes are more likely to fall faster

        horSpeed = FlxG.random.float(5, 8);
        horSpeed = (FlxG.random.bool() ? horSpeed : -horSpeed);

        alpha = FlxG.random.float(.30, .60);
        alpha += variant * 0.15; //big snowflakes are more opaque
    }

    public function setActive(active:Bool)
    {
        paused = active;
        visible = active;
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if(active) //the snowflake will not be rotating while it's disabled
        {
            angle += rotation * elapsed;
            y += fallSpeed * elapsed;
        }
    }
}