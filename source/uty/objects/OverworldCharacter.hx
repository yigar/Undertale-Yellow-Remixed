package uty.objects;

import haxe.atomic.AtomicBool;
import uty.states.Overworld;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.group.FlxSpriteGroup;
import forever.display.ForeverSprite;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import uty.components.Collision;

enum abstract Direction(String) to String{
    var NONE = "none";
    var UP = "up";
    var DOWN = "down";
    var LEFT = "left";
    var RIGHT = "right";
}

//some basic actions
enum abstract Action(String) to String{
    var IDLE = "idle";
    var WALK = "walk";
    var RUN = "run";
    var TALK = "talk";
}

/*
    a generic dynamic class for overworld characters.
    players and NPCs both extend this class for its movement, collision, and sprite/animation functionalities.
*/

class OverworldCharacter extends OverworldSprite
{
    //sprite
    public var characterName:String = "clover";

    public var facingDirection:String = DOWN;
    public var playingSpecialAnim:Bool = false;
    public var specialAnimTimer:FlxTimer;

    private final _defaultDataDirectory:String = "data/characters/overworld/";
    private final _defaultSpriteDirectory:String = "images/overworld/characters/";
    //collision box for all character types. disabled by default. defined in the yaml file.
    public var collision:Collision;

    public function new(charName:String = "clover", x:Float, y:Float, facing:String = "down")
    {
        super(x, y);
        characterName = charName;
        name = charName;
        facingDirection = facing;

        //sprite stuff
        loadCharacterSprite(charName);
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);
        //bottom-centers the box. offset values can adjust this if the sprite size is a bit weird.
        collision.x = sprite.x + (sprite.width / 2) - (collision.width / 2) + collision.hbOffset.x;
        collision.y = sprite.y + (sprite.height - collision.height) + collision.hbOffset.y;
    }

    public function loadCharacterSprite(char:String):OverworldCharacter
    {
        this.characterName = char;
        //i'm assuming all the impl code in character.hx was done by crow
        //for psych engine import + cross compatability
        //i'll just use the yaml stuff for now
        var data = AssetHelper.parseAsset(_defaultDataDirectory + characterName, YAML);
        if (data == null) {
            trace('OW Character ${characterName} could not be parsed due to a inexistent file, Please provide a file called "${characterName}.yaml" in the "data/characters directory.');
            return this;
        }

        loadSprite(_defaultSpriteDirectory + data.spritesheet, true);
        //add animations
        var animations:Array<Dynamic> = data.animations ?? [];
        if (animations.length > 0) {
            for (i in animations) 
            {
                sprite.addAtlasAnim(i.name, i.prefix, i.fps ?? 12, i.loop ?? false, cast(i.indices ?? []));
            }
        }
        else
            sprite.addAtlasAnim("idle_down", "default_walk_down", 0, false, [0]);

        var hitbox:Dynamic = data.hitbox ?? {x: 0, y: 0, width: 0, height: 0};
        collision = new Collision(0, 0, hitbox.width, hitbox.height, hitbox.offsetX, hitbox.offsetY);
        collision.enableCollide = false;
        //bottom-centers the collision box
        collision.x = (this.width / 2) - (collision.width / 2);
        collision.y = (this.height - collision.height);

        return this;
    }

    public function playBasicAnimation(action:String = "idle", ?direction:String = "down", ?modifier:String = "")
    {
        //do not override a special animation
        if(playingSpecialAnim) 
            return;
        if(modifier != "") 
            modifier += "_";
        updateAnim(modifier + action + "_" + direction);
    }

    public function playSpecialAnimation(anim:String, ?cancelTime:Float = 0.0, ?cancelOnEnd:Bool = false)
    {
        if(updateAnim(anim))
        {
            playingSpecialAnim = true;
            if(cancelTime > 0.0)
            {
                specialAnimTimer = new FlxTimer().start(cancelTime, function(tmr:FlxTimer){ cancelSpecialAnimation(); });
            }
            else if(cancelOnEnd)
            {
                animation.finishCallback = function(name:String) {
                    if(name == anim) cancelSpecialAnimation();
                }
            }
        }
    }

    public function cancelSpecialAnimation()
    {
        playingSpecialAnim = false;
    }

    public function updateAnim(anim:String):Bool
    {
        //takes care of attempting to play a playing animation issue.
        //returns true if the animation was successfully changed.
        if(sprite.animation.exists(anim) && sprite.animation.name != anim)
        {
            if(sprite.animation.name != anim)
            {
                sprite.animation.play(anim);
                return true;
                //trace('playing animation ${anim} on character ${characterName}');
            }
            else
            {
                return false;
                //trace('note: animation ${anim} on character ${characterName} is already being played.');
            }
        }
        else
        {
            return false;
            //trace('ERROR: animation does not exist.');
        }
    }

    public function updateDirection(direction:String)
    {
        facingDirection = direction;
    }
}

/*
    a controller that's similarly dynamic and multipurpose.
    used to move overworldcharacters (and children) and manipulate their animations.
    examples: player input to control Player.hx, followers constantly tracking the player, NPCs controlled during a cutscene
    you get the idea
*/

enum ScriptInput {
    ScriptInput(direction:String, running:Bool, time:Float);
}

class CharacterController
{
    public var character:OverworldCharacter; //the character to be controlled

    public static var walkSpeed:Float = 4.5;
    public static var runSpeed:Float = 7.5;
    public var movingX:Int = 0; //1: right, -1: left
    public var movingY:Int = 0; //1: down, -1: up
    public var isMoving:Bool = false;
    public var isRunning:Bool = false;
    //the axes should be checked for collision separately
    public var prevPosition:FlxPoint; 

    public var scriptInputList:Array<ScriptInput>;
    
    private final _diagonal = 0.707; //diagonal movement speed for characters: [(sqrt 2) / 2]

    public function new(char:OverworldCharacter)
    {
        character = char;
        prevPosition = new FlxPoint(character.x, character.y);

        scriptInputList = new Array<ScriptInput>();
    }

    public function update(elapsed:Float)
    {
        if(scriptInputList.length > 0)
        {
            var leadInput = scriptInputList[0].getParameters();
            setMoving(leadInput[0], leadInput[0]);
            setRunning(leadInput[1]);
            //timer function
            scriptInputList[0] = ScriptInput(leadInput[0], leadInput[1], leadInput[2] - elapsed);
            if(leadInput[2] - elapsed <= 0.0)
            {
                scriptInputList.shift();
            }
        }
        //controller will move check constantly based on values
        move();
        updateFacingDirection();
        updateMoveAnimation();

        /*
        trace('DIRECTION: ${character.facingDirection} | 
        MOVING: ${isMoving} | 
        RUNNING: ${isRunning}');
        */
    }

    public function move()
    {
        //move character based on moving vars
        prevPosition.set(character.x, character.y);

        var moveAmount = (isRunning ? runSpeed : walkSpeed); //move by the run speed if we're running
        if(movingX != 0 && movingY != 0) //if moving diagonally
            moveAmount *= _diagonal;
        //move sprite according to move direction
        //maybe it's inefficient to do all this multiplication shit each frame, but whatever. i want smooth movement
        var moveX = moveAmount * movingX;
        var moveY = moveAmount * movingY;
        character.x += moveX;
        character.y += moveY;
    }

    public function setMoving(horizontal:String = NONE, vertical:String = NONE)
    {
        switch (horizontal)
        {
            case LEFT:
                movingX = -1;
            case RIGHT:
                movingX = 1;
            default:
                movingX = 0;
        }

        switch (vertical)
        {
            case UP:
                movingY = -1;
            case DOWN:
                movingY = 1;
            default:
                movingY = 0;
        }

        //checks if we're currently moving based on these inputs
        isMoving = !(movingX == 0 && movingY == 0); 
    }

    public function setMovingFromInt(horizontal:Int = 0, vertical:Int = 0)
    {
        movingX = horizontal == 0 ? horizontal : FlxMath.signOf(horizontal);
        movingY = vertical == 0 ? vertical : FlxMath.signOf(vertical);

        //checks if we're currently moving based on these inputs
        isMoving = !(movingX == 0 && movingY == 0); 
    }

    public function setMovingFromPoint(point:FlxPoint)
    {
        setMovingFromInt(Std.int(point.x), Std.int(point.y));
    }

    public function setRunning(running:Bool)
    {
        isRunning = running;
    }

    public function previousPosition(?x:Bool = true, ?y:Bool = true)
    {
        if(x)
            character.x = prevPosition.x;
        if(y)
            character.y = prevPosition.y;
    }

    public function updateFacingDirection()
    {
        //diagonal inputs get outright ignored here

        if(movingX != 0 && movingY == 0) //horizontal
        {
            if(movingX == -1) character.facingDirection = LEFT;
            if(movingX == 1) character.facingDirection = RIGHT;
        }
        else if(movingX == 0 && movingY != 0) //vertical
        {
            if(movingY == -1) character.facingDirection = UP;
            if(movingY == 1) character.facingDirection = DOWN;
        }
    }

    public function updateMoveAnimation()
    {
        var action = IDLE;
        if(isMoving)
            action = (isRunning ? RUN : WALK);

        character.playBasicAnimation(action, character.facingDirection);
    }

    public function addScriptInput(direction:String, running:Bool, time:Float)
    {
        scriptInputList.push(ScriptInput(direction, running, time));
    }
}