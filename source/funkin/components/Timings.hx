package funkin.components;

import flixel.math.FlxMath;
import haxe.ds.StringMap;
import uty.components.StoryData;
import uty.components.PlayerData;

/**
	typedef Judgement = {
	var name:String;
	var score:Int;
	var accuracy:Float;
	var splash:Bool;
	}
**/
enum Judgement {
	Judgement(name:String, score:Int, accuracy:Float, splash:Bool);
}

enum Rank {
	Rank(name:String, accuracy:Float, ?requiredMisses:Int);
}

class Timings {
	public static final rankings:Array<Rank> = [
		Rank("S", 97, 0),
		Rank("A+", 97),
		Rank("A", 93),
		Rank("A-", 90),
		Rank("B+", 87),
		Rank("B", 83),
		Rank("B-", 80),
		Rank("C+", 77),
		Rank("C", 73),
		Rank("C-", 70),
		Rank("D", 0),
	];

	public static final judgements:Array<Judgement> = [
		Judgement("sick", 350, 100, true),
		Judgement("good", 150, 80, false),
		Judgement("bad", 0, 45, false),
		Judgement("shit", -150, 0, false)
	];

	public static final timings:Array<Float> = [33.33, 91.67, 133.33, 166.67];

	public static var score:Int = 0;
	public static var health(default, set):Int = 20;
	public static var maxHealth:Int = 20;

	public static var inv:Float = 1.0;

	public static var totalNotesHit:Int = 0;
	public static var accuracyWindow:Float = 0.0;

	public static var averageMs(get, never):Float;
	public static var accuracy(get, never):Float;
	public static var totalMs:Float = 0.0;

	public static var misses(get, set):Int; // real misses.
	public static var comboBreaks(get, never):Int;
	public static var combo:Int = 0;

	public static var rank:String = "N/A";

	public static var judgementsHit:StringMap<Int> = new StringMap<Int>();

	public static function reset():Void {
		judgementsHit.clear();
		for (judgement in judgements)
			judgementsHit.set(judgement.getParameters()[0], 0);
		judgementsHit.set("miss", 0);

		score = combo = totalNotesHit = 0;
		accuracyWindow = totalMs = 0.0;

		maxHealth = PlayerData.loveToHP(StoryData.getActiveData().playerSave.love);
		health = maxHealth;
		rank = "N/A";
	}

	public static function judgeNote(timeStamp:Float):Judgement {
		var judgement:Judgement = judgements.last();
		for (i in 0...timings.length) {
			if (timeStamp > timings[i])
				continue;
			else if (timings[i] != Math.NaN) {
				judgement = judgements[i];
				break;
			}
		}
		return judgement;
	}

	public static function updateRank():Void {
		for (i in 0...rankings.length) {
			var eRank:Array<Dynamic> = Tools.getEnumParams(rankings[i]);
			if (eRank[1] <= accuracy) {
				//if there is no miss requirement, or if there is, you have less misses than it
				if(eRank.length >= 3 && eRank[2] != null)
				{
					if(eRank[2] >= comboBreaks)
					{
						rank = eRank[0];
						break;
					}
				}
				else
				{
					rank = eRank[0];
					break;
				}
			}
		}
	}

	public static function increaseJudgeHits(name:String, increment:Int = 1):Void {
		if (judgementsHit.exists(name))
			judgementsHit.set(name, judgementsHit.get(name) + increment);
		else
			trace('[Timings:increaseJudgeHits]: there\'s no judgement going by the name of "${name}"...');
	}

	// -- GETTERS & SETTERS, DO NOT MESS WITH THESE -- //

	@:dox(hide) @:noCompletion static inline function get_misses():Int
		return judgementsHit.exists("miss") ? judgementsHit.get("miss") : 0;

	@:dox(hide) @:noCompletion static inline function set_misses(v:Int):Int {
		judgementsHit.set("miss", v);
		return v;
	}

	@:dox(hide) static inline function get_accuracy():Float
		return accuracyWindow == 0.0 ? 0.00 : Math.abs(accuracyWindow / (totalNotesHit + misses));

	@:dox(hide) static inline function get_averageMs():Float
		return totalMs / totalNotesHit;

	@:dox(hide) static inline function get_comboBreaks():Int {
		final worst = judgements.last().getParameters()[0];
		var shits:Int = judgementsHit.exists(worst) ? judgementsHit.get(worst) : 0;
		return misses + shits;
	}

	@:dox(hide) static inline function set_health(v:Int):Int
		return health = Std.int(FlxMath.bound(v, 0, maxHealth));
}
