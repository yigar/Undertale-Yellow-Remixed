package uty.components;

import haxe.ds.StringMap;
import flixel.FlxG;
import uty.components.PlayerData;
import flixel.util.FlxTimer;

typedef StorySave =
{
    playerSave:PlayerSave,
    followers:Array<String>,
    songs:StringMap<StorySongSave>,
    secondsPlayed:Int,
    savePointName:String,
    flags:StoryFlags
}

//NOTE: STORY UNLOCK SHOULD BE DIFFERENT FROM FREEPLAY UNLOCK
//i.e. warp unlocks should not be based on the same system as memory unlocks
typedef StorySongSave = 
{
    played:Bool,
    beaten:Bool,
    deaths:Int
}

//stores string flags for marking various events happening in the game.
//this is the main way the story is "progressed"
//completed songs, spawnable items, characters being killed, etc.
typedef StoryFlags = 
{
    main:Array<String>,
    geno:Array<String>
}

class StoryData
{
    //THIS DISTINCTION IS IMPORTANT FOR PREVENTING AUTO-SAVING
    private static var storySave:StorySave; //this one gets shared to the FlxSave: the saved game progress.
    public static var activeData:StorySave; //this one does NOT get bound to Flxsave: the current unsaved progress.

    public static var gameClock:FlxTimer;

    public static function returnDefault():StorySave
    {
        //need to get a way of retrieving the song list later on, and generally organizing songs.

        var dummySave:StorySave = {
            playerSave: PlayerData.returnDefault(),
            followers: [],
            songs: new StringMap<StorySongSave>(),
            secondsPlayed: 0,
            savePointName: "Save Point",
            flags: {
                main: new Array<String>(),
                geno: new Array<String>()
            }
        };
        return dummySave;
    }

    //laudry function creates a copy of an object, divorcing it from other variables.
    //it also null-safeties in the case of a corrupted/outdated save file.
    public static function launderData(save:StorySave):StorySave
    {
        var def = returnDefault();
        var newSave = {
            playerSave: PlayerData.launderData(save.playerSave),
            followers: save.followers ?? def.followers,
            songs: save.songs ?? def.songs,
            secondsPlayed: save.secondsPlayed ?? def.secondsPlayed,
            savePointName: save.savePointName ?? def.savePointName,
            flags: save.flags ?? def.flags
        };
        return newSave;
    }

    //updates the active game data with the provided storySave object.
    public static function setActiveData(data:StorySave):Void
    {
        activeData = data;
    }

    //returns the active data variable that reflects immediate game status
    public static function getActiveData():StorySave
    {
        if (activeData == null) return returnDefault();
        return launderData(activeData);
    }

    //returns the story save variable that's bound to the save file
    public static function getSaveData():StorySave
    {
        return launderData(storySave) ?? returnDefault();
    }

    //overwrites the save data with the active game data.
    //this SHOULD be kept a separate function from updating the active data because I don't want the two to get confused
    public static function saveData():Void
    {
        storySave = launderData(activeData);
        _setSave(storySave);
    }

    //loads the save file and sets the active game data equal to it.
    public static function loadData()
    {
        storySave = _getSave();
        activeData = launderData(storySave);
    }

    @:dox(hide)
    private static inline function _getSave():StorySave
    {
        FlxG.save.bind('utyRemixed', 'yigar/UTYRemixed/uty');
        if(FlxG.save.isBound && FlxG.save.data.storySave != null)
        {
            return FlxG.save.data.storySave;
        }
        else return returnDefault();
    }

    private static function _setSave(save:StorySave):Void
    {
        FlxG.save.bind('utyRemixed', 'yigar/UTYRemixed/uty');
        if(FlxG.save.isBound)
        {
            FlxG.save.data.storySave = save;
            FlxG.save.flush();
            trace("GAME SAVED");
        }
    }
}

class StoryUtil
{
    //utility class for setting some values quickly
    public static var songFlags:StringMap<String> = [
        "Budding Friendship" => "FloweySongBeaten",
        "Martlet" => "MartletSongBeaten"
    ];

    public static function restoreHP(heal:Int, ?overheal:Bool = false)
    {
        var dum:StorySave = StoryData.getActiveData();
        var maxHP = PlayerData.loveToHP(dum.playerSave.love);
        if(dum.playerSave.health + heal < maxHP || overheal)
        {
            dum.playerSave.health += heal;
        }
        else
        {
            dum.playerSave.health = maxHP;
        }
        StoryData.setActiveData(dum);
    }

    public static function setLV(lv:Int, ?add:Bool = false)
    {
        var dum:StorySave = StoryData.getActiveData();
        dum.playerSave.love = (add ? dum.playerSave.love + lv : lv);
        if(dum.playerSave.love > 20) dum.playerSave.love = 20;
        else if(dum.playerSave.love < 1) dum.playerSave.love = 1;
        StoryData.setActiveData(dum);
    }

    //keep in mind that the player's spawn and save point aren't necessarily the same
    //this can set the player's spawn somewhere else without updating the save point display location
    public static function setSpawn(room:String, x:Int, y:Int)
    {
        var dum:StorySave = StoryData.getActiveData();
        dum.playerSave.room = room;
        dum.playerSave.posX = x;
        dum.playerSave.posY = y;
        StoryData.setActiveData(dum);
        trace('spawn set to: x${x} y${y}');
    }

    public static function updateSavePoint(name:String, room:String, x:Int, y:Int)
    {
        var dum:StorySave = StoryData.getActiveData();
        dum.savePointName = name;
        dum.playerSave.room = room;
        dum.playerSave.posX = x;
        dum.playerSave.posY = y;
        StoryData.setActiveData(dum);
        trace('spawn set to: x${x} y${y}');
    }

    //adds one to the death count for a particular song
    public static function addDeath(song:String)
    {
        var d = getDeaths(song);
        d += 1;
        _setStorySong(song, {deaths: d});
    }

    public static function getDeaths(song:String):Int
    {
        var d = null;
        d = _getStorySong(song).deaths;
        if(d == null) d = 0;
        return d;
    }

    public static function addFollower(follower:String)
    {
        var dum:StorySave = StoryData.getActiveData();
        dum.followers.push(follower);
        StoryData.setActiveData(dum);
    }

    public static function startClock()
    {
        StoryData.gameClock = new FlxTimer().start(1.0, function(tmr:FlxTimer){
            addToClock(1);
        }, 0);
    }

    public static function stopClock()
    {
        if(StoryData.gameClock != null)
            StoryData.gameClock.cancel();
    }

    public static function addToClock(seconds:Int)
    {
        var dum:StorySave = StoryData.getActiveData();
        dum.secondsPlayed += seconds;
        StoryData.setActiveData(dum);
    }

    public static function getActiveTimeString():String
    {
        var dum:StorySave = StoryData.getActiveData();
        var totalSecs:Int = dum.secondsPlayed ?? 0;
        var h:Int = Math.floor(totalSecs / 3600);
        var m:Int = Math.floor(totalSecs / 60) - h;
        var mStr:String = (m < 10 ? '0' : '') + m;
        return '${h}:${mStr}';
    }

    public static function getPlayedStory(song:String):Bool
    {
        var ss:StorySongSave = _getStorySong(song);
        return ss.played;
    }

    public static function getBeatenStory(song:String):Bool
    {
        var ss:StorySongSave = _getStorySong(song);
        return ss.beaten;
    }

    public static function getFlagFromSong(song:String)
    {
        return songFlags.get(song);
    }

    private static function _getStorySong(song:String):StorySongSave
    {
        return StoryData.getActiveData().songs.get(song);
    }

    private static function _setStorySong(song:String, values:Dynamic)
    {
        var save:StorySave = StoryData.getActiveData();
        var oldSS:StorySongSave = _getStorySong(song);
        var newSS:StorySongSave = {
            played: values.played ?? oldSS.played,
            beaten: values.beaten ?? oldSS.beaten,
            deaths: values.deaths ?? oldSS.deaths,
        }
        save.songs.set(song, newSS);
        StoryData.setActiveData(save);
    }

}

//this could be moved to the storyUtil class, but im leaving it separate for now
class StoryProgress
{
    public static function flag(flag:String)
    {
        flag = flag.toLowerCase(); //doing this to remove problems with inconsistent casing (pascal, camel, etc.)
        var flags = _getActiveFlags();
        if(!flags.main.contains(flag))
            flags.main.push(flag);
    }

    //if the flag has been set using the flag() command, returns true.
    public static function checkFlag(flag:String):Bool
    {
        flag = flag.toLowerCase();
        var flags = _getActiveFlags();
        trace("flags: " + flags);
        return flags.main.contains(flag);
    }

    //check if all flags in an array are set. setting 'or' to true will check for one instead of all.
    public static function checkFlagArray(ary:Array<String>, ?or:Bool = false):Bool
    {
        var trueCount:Int = 0;
        for(i in 0...ary.length)
        {
            if(checkFlag(ary[i]))
                trueCount++;
        }
        
        if((or && trueCount > 0) || (trueCount >= ary.length))
        {
            return true;
        }
        else return false;
    }

    private static function _getActiveFlags():StoryFlags
    {
        var data:StorySave = StoryData.getActiveData();
        return data.flags;
    }
}