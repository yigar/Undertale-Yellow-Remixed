package funkin.substates;

import flixel.sound.FlxSound;
import funkin.states.PlayState;
import flixel.FlxSubState;
import flixel.util.FlxTimer;
import uty.objects.UTText;
import flixel.tweens.FlxTween;

import funkin.states.menus.StoryMenu;
import funkin.states.menus.FreeplayMenu;

import funkin.objects.Character;

import openfl.media.Sound;

import forever.display.ForeverSprite;

import uty.objects.DialogueBox;
import uty.components.DialogueParser;
import uty.components.SoundManager;
import uty.states.Overworld;
import uty.components.StoryData;
import uty.objects.DirectionParticle;

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
    public var enter:ForeverSprite;
    public var back:ForeverSprite;
    public var enterTxt:UTText;
    public var backTxt:UTText;

    public var diaBox:DialogueBox;
    public var sndMngr:SoundManager;

    public var textTimer:Float = 1.0;
    public var timerActive:Bool = false;

    public function new(?x:Float = 0, ?y:Float = 0, screenData:GameOverData, isPlayer:Bool = true):Void {
        super();

        sndMngr = new SoundManager();

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

        enter = new ForeverSprite();
        enter.loadGraphic(Paths.image('gameOver/enter'));
        enter.antialiasing = false;
        enter.scale.set(3.0, 3.0);
        enter.updateHitbox();
        add(enter);
        enter.alpha = 0.0;

        back = new ForeverSprite();
        back.loadGraphic(Paths.image('gameOver/backspace'));
        back.antialiasing = false;
        back.scale.set(3.0, 3.0);
        back.updateHitbox();
        add(back);
        back.alpha = 0.0;

        enterTxt = new UTText(0, 0, 0, "Retry");
        enterTxt.setFont();
        enterTxt.updateHitbox();
        add(enterTxt);
        enterTxt.alpha = 0.0;

        backTxt = new UTText(0, 0, 0, "Back to Save");
        backTxt.setFont();
        backTxt.updateHitbox();
        add(backTxt);
        backTxt.alpha = 0.0;

        soul.setPosition(FlxG.width * 0.5 - (soul.width * 0.5), FlxG.height - 200);
        gameOverText.setPosition(FlxG.width * 0.5 - (gameOverText.width * 0.5), 80);
        enter.setPosition(FlxG.width * 0.30 - (enter.width * 0.5), FlxG.height - enter.height - 50);
        back.setPosition(FlxG.width * 0.70 - (back.width * 0.5), FlxG.height - back.height - 50);
        enterTxt.setPosition(enter.x + (enter.width * 0.5) - (enterTxt.width * 0.5), enter.y - 50);
        backTxt.setPosition(back.x + (back.width * 0.5) - (backTxt.width * 0.5), back.y - 50);

        setupDialogue();

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
                    timerActive = true;
                });
            });
        });
    }

    private function setupDialogue()
    {
        //name the dialogue files based on the songs.
        var parser:DialogueParser = new DialogueParser(PlayState.current.songMeta.name, "gameOver/");
        var diaGrp:DialogueGroup = parser.getDialogueFromParameter("deathCount", StoryUtil.getDeaths(PlayState.current.songMeta.name), true);
        diaBox = new DialogueBox(0, 0, diaGrp);
        add(diaBox);
        diaBox.setScreenPosition(50, 450);
        diaBox.boxSprites.visible = false;
        diaBox.togglePortrait(false);
    }

    var leaving:Bool = false;

    override function update(elapsed:Float) {
        super.update(elapsed);

        if(diaBox != null && !leaving && diaBox.visible)
        {
            if(timerActive)
            {
                textTimer -= elapsed;
                if(textTimer <= 0)
                {
                    diaBox.skipLine();
                    diaBox.nextDialogueLine();
                    textTimer = 2.0;
                    timerActive = false;

                    if(diaBox.dialogueCompleted)
                    {
                        diaBox.visible = false;
                        tweenInControls();
                    }
                }
            }
            else
            {
                if(diaBox.narratedText.finished)
                    timerActive = true;
            }
        }

        if ((Controls.BACK || Controls.ACCEPT) && !leaving) {
            leaving = true;
            diaBox.visible = false;
            diaBox.pause();

            sndMngr.tweenMusicVolume(0.0, 1.0);
            FlxG.sound.play(Paths.sound('snd_confirm'));

            if (Controls.BACK) {
                back.color = 0xFFFFFF00;
                camera.fade(FlxColor.BLACK, 1.0, false, () -> {
                    FlxG.switchState(new Overworld());
                });
            }
            else {
                enter.color = 0xFFFFFF00;
                camera.fade(FlxColor.BLACK, 1.0, false, () -> {
                    FlxG.switchState(new PlayState(PlayState.current.songMeta, PlayState.current.playMode));
                });
            }
        }
        
    }

    function tweenInControls(time:Float = 0.8)
    {
        enter.tween({alpha: 1.0}, time);
        back.tween({alpha: 1.0}, time);
        FlxTween.tween(enterTxt, {alpha: 1.0}, time);
        FlxTween.tween(backTxt, {alpha: 1.0}, time);
    }

    function startMusicLoop(vol:Float = 1.0):Void {
        sndMngr.updateMusic(data.loopMusic);
    }
}

class SoulShard extends DirectionParticle
{
    //this'll just make it easier to track the tweens, trust me

    public function new(x:Int, y:Int, character:String = 'clover')
    {
        super(x, y, 'gameOver/soulShard_${character}', 'shatter', 4);
        antialiasing = false;
        scale.set(1.5, 1.5);
        updateHitbox();

        setXBounds(8.0, 8.0);
        setYBounds(-12.0, 3.0);
        getRandomMomentum();
    }
}