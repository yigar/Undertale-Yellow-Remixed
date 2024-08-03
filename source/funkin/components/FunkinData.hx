package funkin.components;

import haxe.ds.StringMap;
import flixel.FlxG;
import flixel.util.FlxTimer;
import funkin.components.Timings;

//manages save binds and saves stuff to the funkin save file, particularly high scores and unlocked songs.


typedef FunkinSave = {
    songSaves:StringMap<SongSave>
}

typedef SongSave = 
{
    played:Bool,
    beaten:Bool,
    highscore:HighscoreSave
}

@:structInit class HighscoreSave {
    public var score:Int = 0;
    public var misses:Int = 0;
    public var accuracy:Float = 0.00;
    public var rank:String = "N/A";
}

class FunkinData
{
    private static var funkinSave:FunkinSave; //i'll leave this as one variable that autosaves

    public static function returnDefault():FunkinSave
    {
        var dummySave:FunkinSave =  
        {
            songSaves: new StringMap<SongSave>()
        };
        return dummySave;
    }

    public static function setData(data:FunkinSave):Void {
        funkinSave = data;
    }

    //returns the active data variable that reflects immediate game status
    public static function getData():FunkinSave {
        if (funkinSave == null) return returnDefault();
        return funkinSave;
    }

    public static function saveData():Void
    {
        _setSave(funkinSave);
    }

    public static function loadData()
    {
        funkinSave = _getSave();
    }

    @:dox(hide)
    private static inline function _getSave():FunkinSave
    {
        FlxG.save.bind('fnf', 'yigar/UTYRemixed/forever');
        if(FlxG.save.isBound && FlxG.save.data.funkinSave != null)
        {
            return FlxG.save.data.funkinSave;
        }
        else return returnDefault();
    }

    private static function _setSave(save:FunkinSave):Void
    {
        FlxG.save.bind('fnf', 'yigar/UTYRemixed/forever');
        if(FlxG.save.isBound)
        {
            FlxG.save.data.funkinSave = save;
            FlxG.save.flush();
            trace("FNF DATA SAVED");
        }
    }
}

class FunkinUtil
{
    public static function setPlayed(song:String)
    {
        _setSong(song, {played: true});
    }

    public static function setBeaten(song:String)
    {
        _setSong(song, {played: true, beaten: true});
    }

    public static function setHighscore(song:String, hiScore:HighscoreSave)
    {
        //because of how S rank works, i'll just save the highest of each independent score metric.
        //you could get 97%+ accuracy on one run and a FC on another, and it will display those
        //but you will not get that perfect S unless you achieve both at once.
        var oldScore:HighscoreSave = _getSong(song).highscore;
        var newScore:HighscoreSave = {
            score: Std.int(Math.max(hiScore.score, oldScore.score)),
            misses: Std.int(Math.min(hiScore.misses, oldScore.misses)),
            accuracy: Math.max(hiScore.accuracy, oldScore.accuracy),
            rank: Timings.returnHigherRank(hiScore.rank, oldScore.rank)
        };
        _setSong(song, {highscore: newScore});
    }

    public static function getPlayed(song:String):Bool{
        return _getSong(song).played;
    }

    public static function getBeaten(song:String):Bool{
        return _getSong(song).beaten;
    }

    public static function getHighscore(song:String):HighscoreSave{
        return _getSong(song).highscore;
    }

    private static function _setSong(song:String, values:Dynamic)
    {
        var funk:FunkinSave = FunkinData.getData();
        var oldSS:SongSave = funk.songSaves.get(song);
        var newSS:SongSave = {
            played: values.played ?? oldSS.played,
            beaten: values.beaten ?? oldSS.beaten,
            highscore: values.highscore ?? oldSS.highscore,
        }
        funk.songSaves.set(song, newSS);
        FunkinData.setData(funk);
    }

    private static function _getSong(song:String):SongSave
    {
        return FunkinData.getData().songSaves.get(song);
    }
}