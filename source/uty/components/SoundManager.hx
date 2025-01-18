package uty.components;

import flixel.FlxG;
import flixel.sound.FlxSound;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;

class SoundManager
{
    var music:FlxSound;
    var ambience:FlxSound;

    public var lastMus:String = "";
    public var lastAmb:String = "";

    final musicFolder:String = 'audio/bgm';

    public function new()
    {
        music = new FlxSound();
        ambience = new FlxSound();
    }

    public function updateMusic(mus:String, ?loop:Bool = true)
    {
        if(mus == lastMus) return;
        if(mus == "none")
        {
            stopMusic();
            return;
        }

        var musTrack = null;
        musTrack = AssetHelper.getAsset('${musicFolder}/${mus}', SOUND);

        if(musTrack != null)
        {
            trace('updating music: ${mus}');
            lastMus = mus;
            music = new FlxSound().loadEmbedded(musTrack);
            FlxG.sound.music = music;
            FlxG.sound.music.looped = loop;
            FlxG.sound.music.play();
        }
        else
        {
            trace('error: music track could not be found.');
        }
		
    }

    public function updateAmbience(amb:String, ?loop:Bool = true)
    {
        if(amb == lastAmb) return;
        if(amb == "none")
        {
            stopAmbience();
            return;
        }

        var ambTrack = null;
        ambTrack = AssetHelper.getAsset('${musicFolder}/${amb}', SOUND);

        if(ambTrack != null)
        {
            lastAmb = amb;
            ambience = new FlxSound().loadEmbedded(ambTrack);
            FlxG.sound.list.add(ambience);
            ambience.looped = loop;
            ambience.resume();
        }
    }

    public function setMusicVolume(vol:Float)
    {
        music.volume = vol;
    }

    public function setAmbienceVolume(vol:Float)
    {
        ambience.volume = vol;
    }

    public function tweenMusicVolume(vol:Float, time:Float)
    {
        FlxTween.tween(music, {volume: vol}, time);
    }

    public function fadeInMusic(time:Float)
    {
        setMusicVolume(0.0);
        tweenMusicVolume(1.0, time);
    }

    public function fadeOutMusic(time:Float)
    {
        setMusicVolume(1.0);
        tweenMusicVolume(0.0, time);
    }

    public function tweenAmbienceVolume(vol:Float, time:Float)
    {
        FlxTween.tween(ambience, {volume: vol}, time);
    }

    public function fadeInAmbience(time:Float)
    {
        setAmbienceVolume(0.0);
        tweenAmbienceVolume(1.0, time);
    }

    public function fadeOutAmbience(time:Float)
    {
        setAmbienceVolume(1.0);
        tweenAmbienceVolume(0.0, time);
    }

    public function stopMusic()
    {
        trace('stopping music');
        lastMus = "none";
        music = new FlxSound();
        if(FlxG.sound.music != null)
            FlxG.sound.music.stop();
    }

    public function stopAmbience()
    {
        lastAmb = "none";
        if(ambience != null)
            ambience.stop();
    }

    public static function playSound(sound:String, ?vol:Float = 1.0, ?delay:Float = 0.0)
    {
        new FlxTimer().start(delay, function(tmr:FlxTimer){
            FlxG.sound.play(AssetHelper.getAsset('audio/sfx/${sound}', SOUND), vol);
        });
    }
}