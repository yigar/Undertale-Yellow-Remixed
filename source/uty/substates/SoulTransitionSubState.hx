package uty.substates;

import funkin.states.menus.FreeplayMenu;
import funkin.states.PlayState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.sound.FlxSound;
import forever.display.ForeverSprite;
import flixel.FlxSubState;
import flixel.tweens.FlxEase;
import funkin.components.ChartLoader;

class SoulTransitionSubState extends FlxSubState
{
    //create the soul and flicker effect to go from the overworld into the playstate
    public var song:PlaySong;

    public var soul:ForeverSprite;
    public var black:ForeverSprite;

    public var soulStartX:Float;
    public var soulStartY:Float;
    public var soulEndX:Float;
    public var soulEndY:Float;

    //independents
    public var flickerTime:Float = 0.1; //time for EACH flicker
    public var flickerCount:Int = 3; //amount of flickers before the soul moves
    public var soulTweenTime:Float = 0.4;
    //trackers
    public var flickerTracker:Int = 0;
    public var flickerClock:Float = 0.0;

    public var dark:Bool = true;
    public var flickering:Bool = false;

    public var soulTween:FlxTween;

    private var _pixelScaleRatio:Float = 3.0;

    public function new(song:PlaySong, soulX:Float, soulY:Float)
    {
        super();

        black = new ForeverSprite();
        black.graphic = black.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK).graphic;
        add(black);

        soul = new ForeverSprite(soulX, soulY);
        soul.loadGraphic(AssetHelper.getAsset("images/ui/soul", IMAGE));
        soul.setGraphicSize(Std.int(soul.width * _pixelScaleRatio));
        soul.updateHitbox();
        soul.antialiasing = false;
        soul.visible = false;
        add(soul);

        flickering = true;

        setSoulEndPosition();

        this.song = song;
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        flickerClock -= elapsed;
        if(flickerClock <= 0 && flickering)
        {
            flicker();
            flickerClock = (flickerTime / 2);
        }
    }

    private function flicker()
    {
        //flickerCount has been met; start the into-battle transition
        if(flickerTracker >= flickerCount)
        {
            intoBattleTransition();
            return;
        }
        //flip stuff
        soul.visible = !soul.visible;
        //black.visible = !black.visible;
        dark = !dark;

        //do this stuff when the screen goes dark
        if(dark)
        {
            //play sound
            
        }
        //do this stuff when the lights go back on
        else
        {
            FlxG.sound.play(Paths.sound("snd_switch"));
            flickerTracker++;
        }
    }

    private function setSoulEndPosition()
    {
        //the soul has to go to the icon sprite in battle, and this position is different depending on downscroll
        if(Settings.downScroll)
        {
            soulEndX = 850;
            soulEndY = 100;
        }
        else
        {
            soulEndX = 850;
            soulEndY = 600;
        }
    }

    private function intoBattleTransition()
    {
        flickering = false;
        //FlxG.sound.play(Paths.sound("snd_switch"));
        FlxG.sound.play(Paths.sound("snd_soul_battle_start"));

        soul.tween({x: soulEndX, y: soulEndY}, soulTweenTime, {
            ease: FlxEase.linear,
            onComplete: tweenBlackOut});
        /*
        soulTween = FlxTween.tween(soul, {x: soulEndX, y: soulEndY}, soulTweenTime,
            {
                onComplete: tweenBlackOut
            });
        */
    }

    private function tweenBlackOut(twn:FlxTween)
    {
        soul.visible = false;

        FlxTransitionableState.skipNextTransOut = true;

        trace("CHART: " + Chart.current + "\nSONG: " + song);

        Chart.current = ChartLoader.load(song.folder, song.difficulty);
        FlxG.switchState(new PlayState(song));
        
        //FlxG.switchState(new FreeplayMenu());

        black.tween({alpha: 0.0}, 0.5, {onComplete: closeStuff});
    }

    private function closeStuff(twn:FlxTween)
    {
        close();
    }

    override function close()
    {
        super.close();
    }
}