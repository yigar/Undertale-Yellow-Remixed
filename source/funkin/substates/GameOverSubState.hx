package funkin.substates;

import flixel.sound.FlxSound;
import funkin.states.PlayState;
import flixel.FlxSubState;
import flixel.util.FlxTimer;

import funkin.states.menus.StoryMenu;
import funkin.states.menus.FreeplayMenu;

import funkin.objects.Character;

import openfl.media.Sound;

import forever.display.ForeverSprite;

@:structInit class GameOverData {
    /** Character that died. This alters the soul that appears (in case monsters become playable characters... wink wink) **/
    public var character:String = "clover";
    /** Plays during the game over screen. **/
    public var loopMusic:String = "justice";
    //i don't think the game over confirm sound and death sound are necessary to customize, so i'm removing them
}

class GameOverSubState extends FlxSubState {
    public var character:Character;
    public var data:GameOverData;

    public var soul:ForeverSprite;
    public var gameOverText:ForeverSprite;

    public function new(?x:Float = 0, ?y:Float = 0, screenData:GameOverData, isPlayer:Bool = true):Void {
        super();

        if (FlxG.sound.music != null)
            FlxG.sound.music.stop();

        Conductor.active = false;
        Conductor.time = 0.0;

        this.data = screenData;

        // checking both the music and sound paths lol -Crow
        /*
        var confirmPath:Sound = Paths.music(screenData.confirmSound);
        if (confirmPath == null) Paths.sound(screenData.confirmSound);

        confirmSound = new FlxSound().loadEmbedded(confirmPath);
        confirmSound.persist = true;
        */

        final bg = new FlxSprite().makeSolid(FlxG.width, FlxG.height, 0xFF000000);
		bg.antialiasing = false;
		add(bg);

        soul = new ForeverSprite();
        soul.loadGraphic(Paths.image('gameOver/soul_${data.character}'));
        soul.frames = Paths.getSparrowAtlas('gameOver/soul_${data.character}');
        soul.addAtlasAnim("normal", "normal", 0, false);
        soul.addAtlasAnim("broken", "broken", 0, false);
        soul.playAnim('normal');
        soul.antialiasing = false;
        soul.scale.set(1.5, 1.5);
        soul.updateHitbox();
        add(soul);

        gameOverText = new ForeverSprite();
        gameOverText.loadGraphic(Paths.image('gameOver/gameOver'));
        gameOverText.antialiasing = false;
        gameOverText.scale.set(1.5, 1.5);
        gameOverText.updateHitbox();
        add(gameOverText);
        gameOverText.alpha = 0.0;

        soul.setPosition(FlxG.width * 0.5 - (soul.width * 0.5), FlxG.height - 200);
        gameOverText.setPosition(FlxG.width * 0.5 - (gameOverText.width * 0.5), 80);

        soulAnimSequence();

        //Conductor.active = true;
    }

    private function soulAnimSequence()
    {
        new FlxTimer().start(0.8, function(tmr:FlxTimer){
            soul.playAnim('broken');
            FlxG.sound.play(Paths.sound('snd_soul_gameover_hit'));
            new FlxTimer().start(1.2, function(tmr:FlxTimer){
                soul.visible = false;
                //shards
                for(i in 0...5)
                {
                    add(new SoulShard(Std.int(soul.x + (soul.width * 0.5)), Std.int(soul.y + (soul.height * 0.5)), data.character));
                }
                FlxG.sound.play(Paths.sound('snd_soul_gameover_hit_break'));
                new FlxTimer().start(2.0, function(tmr:FlxTimer){
                    gameOverText.tween({alpha: 1.0}, 0.8);
                    startMusicLoop();
                });
            });
        });
    }

    var leaving:Bool = false;
    var confirmSound:FlxSound;

    override function update(elapsed:Float) {
        super.update(elapsed);

        /*
        if (Controls.BACK || Controls.ACCEPT) {
            leaving = true;

            if (Controls.BACK) {
                if (FlxG.sound.music != null) FlxG.sound.music.stop();
                FlxG.switchState(new FreeplayMenu());
            }
            else {
                confirmSound.play(true, 0.0);
                camera.fade(FlxColor.BLACK, 1.5, false, () -> {
                    FlxG.switchState(new PlayState(PlayState.current.songMeta));
                });
            }
        }
        */
    }

    function startMusicLoop(vol:Float = 1.0):Void {
        FlxG.sound.playMusic(Paths.music(data.loopMusic), vol, true);
        if (vol != 1.0 && !leaving) FlxG.sound.music.fadeIn(vol, 1.0, 4.0);
    }
}

class SoulShard extends ForeverSprite
{
    //this'll just make it easier to track the tweens, trust me

    public var moveX:Float = 0.0;
    public var moveY:Float = 0.0;
    private final gravity:Float = 0.15;

    public function new(x:Int, y:Int, character:String = 'clover')
    {
        super(x, y);
        loadGraphic(Paths.image('gameOver/soulShard_${character}'));
        frames = Paths.getSparrowAtlas('gameOver/soulShard_${character}');
        addAtlasAnim("shatter", "shatter", 6, true);
        playAnim('shatter');
        antialiasing = false;
        scale.set(1.5, 1.5);
        updateHitbox();

        getRandomMomentum();
    }

    private function getRandomMomentum()
    {
        moveX = FlxG.random.float(-8.0, 8.0);
        moveY = FlxG.random.float(-12.0, 3.0);
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);
        this.x += moveX;
        this.y += moveY;
        moveY += gravity;

        if(this.x < -100 || this.x > FlxG.width + 100 || this.y > FlxG.height + 100) //if the shard is off-screen
        {
            visible = false;
            this.destroy();
        }
    }
}