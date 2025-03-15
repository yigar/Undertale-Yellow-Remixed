package uty.objects;

import forever.display.ForeverSprite;
import funkin.states.PlayState;

typedef Bounds = {
    min:Float,
    max:Float
}

//a generic parent class for particles that spawn, move in a direction with gravity, and are destroyed when off screen.
class DirectionParticle extends ForeverSprite
{
    //this'll just make it easier to track the tweens, trust me

    public var moveX:Float = 0.0;
    public var moveY:Float = 0.0;
    public var gravity:Float = 0.15;
    public var animationName:String;
    public var xBounds:Bounds;
    public var yBounds:Bounds;
    public var enabled:Bool = true;
    public var dontDestroy:Bool = false; //for recycling

    public function new(x:Float, y:Float, spriteDir:String, ?animation:String, ?frameRate:Int = 0)
    {
        super(x, y);
        loadGraphic(Paths.image(spriteDir));
        if(animation != null) {
            frames = Paths.getSparrowAtlas(spriteDir);
            addAtlasAnim(animation, animation, frameRate, true);
            playAnim(animation);
            animationName = animation;
        }
        //presets
        setXBounds(-8.0, 8.0);
        setYBounds(-12.0, 3.0);
        //you need to call getRandomMomentum() manually
    }

    public function getRandomMomentum()
    {
        moveX = FlxG.random.float(xBounds.min, xBounds.max);
        moveY = FlxG.random.float(yBounds.min, yBounds.max);
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);
        if(enabled)
        {
            this.x += moveX;
            this.y += moveY;
            moveY += gravity;
        }

        checkOffscreen();
    }

    private function checkOffscreen()
    {
        //if(this.isOnScreen(PlayState.current.gameCamera))
        if(this.x < -100 || this.x > FlxG.width + PlayState.current.hudCamera.x + 100 || 
            this.y > FlxG.height + PlayState.current.hudCamera.y + 100) //if the shard is off-screen
        {
            if(dontDestroy) {
                if(enabled)
                    disable();
            }
            else {
                visible = false;
                trace('destroyed particle');
                this.destroy();
            }
        }
    }

    public function disable()
    {
        enabled = false;
        visible = false;
    }

    public function enable()
    {
        enabled = true;
        visible = true;
    }

    public inline function setXBounds(min:Float, max:Float) {
        xBounds = {min: min, max: max};
    }

    public inline function setYBounds(min:Float, max:Float) {
        yBounds = {min: min, max: max};
    }
}