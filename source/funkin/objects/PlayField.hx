package funkin.objects;

import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.math.FlxMath;

import forever.display.ForeverText;
import forever.display.RecycledSpriteGroup;

import funkin.components.ChartLoader;
import funkin.components.Timings;
import funkin.components.parsers.ChartFormat.NoteData;
import funkin.objects.play.*;
import funkin.states.PlayState;
import funkin.ui.HealthBar;
import funkin.ui.HealthIcon;

import haxe.ds.Vector;

import uty.components.StoryData;

/**
 * Play Field contains basic objects to handle gameplay
 * Note Fields, Notes, etc.
**/
class PlayField extends FlxGroup {
	private var play(get, never):PlayState;
	public var skin(get, never):String;
	public static var isPixel(get, never):Bool;

	// -- PLAY NODES -- //

	public var plrStrums:StrumLine;
	public var enmStrums:StrumLine;
	public var noteGroup:FlxTypedSpriteGroup<Note>;
	public var strumLines:Array<StrumLine> = [];

	public var paused:Bool = false;
	public var noteList:Vector<NoteData>;
	public var curNote:Int = 0;

	// -- UI NODES -- //

	public var centerMark:ForeverText;

	public var healthBar:HealthBar;
	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;

	public var rpcText:String;

	public var missCount:MissCounter;
	public var gradeSprite:GradeSprite;

	public var splashGroup:RecycledSpriteGroup<NoteSplash>;

	public function new():Void {
		super();

		final strumY:Float = Settings.downScroll ? FlxG.height - 150 : 50;
		final speed:Float = Chart.current.gameInfo.noteSpeed;

		add(enmStrums = new StrumLine(this, 100, strumY, speed, skin, true));
		add(plrStrums = new StrumLine(this, FlxG.width - 480, strumY, speed, skin, false));

		//QUICK FIX
		enmStrums.visible = false;

		if (Settings.centerStrums) {
			enmStrums.visible = false;
			plrStrums.x = (FlxG.width - plrStrums.width) * 0.5;
		}

		add(noteGroup = new FlxTypedSpriteGroup<Note>());
		add(splashGroup = new RecycledSpriteGroup<NoteSplash>());

		final hbY:Float = Settings.downScroll ? FlxG.height * 0.1 : FlxG.height * 0.875;

        var hbPath:String = 'images/ui/${skin}/healthBar';
        if (!Tools.fileExists(AssetHelper.getPath(hbPath, IMAGE)))
            hbPath = hbPath.replace(skin, "normal");

		add(healthBar = new HealthBar(FlxG.width / 2, FlxG.height - 100, StoryData.getActiveData().playerSave.love));

		add(iconP1 = new HealthIcon(PlayState.current?.player?.icon ?? "face", true));
		add(iconP2 = new HealthIcon(PlayState.current?.enemy?.icon ?? "face", false));
		for (i in [iconP1, iconP2]) i.y = healthBar.y - (i.height * 0.5);
		
		iconP1.x = FlxG.width - 150 - (iconP1.width * 0.50);
		iconP2.x = 150 - (iconP2.width * 0.50);

		// [${play.songMeta.difficulty.toUpperCase()}] -'
		centerMark = new ForeverText(0, (Settings.downScroll ? FlxG.height - 40 : 15), 0, '- ${play.songMeta.name} -', 20);
		centerMark.alignment = CENTER;
		centerMark.borderSize = 2.0;
		centerMark.screenCenter(X);
		add(centerMark);

		missCount = new MissCounter(Settings.centerStrums ? FlxG.width - 100 : plrStrums.x - 70, 110);
		add(missCount);

		gradeSprite = new GradeSprite(50, 70);
		add(gradeSprite);

		updateScore();

		noteList = new Vector<NoteData>(Chart.current.notes.length);

		// allocate notes before beginning
		var i:Int = 0;
		while (i < Math.floor(Chart.current.notes.length / 16)) {
			var oi = new Note();
			noteGroup.add(oi);
			oi.kill();
			i++;
		}

		// I know this is dumb as shit and I should just make a group but I don't wanna lol
		forEachOfType(StrumLine, function(n:StrumLine) strumLines.push(n));
		// also arrays are just easier to iterate !!!

		for (i in 0...Chart.current.notes.length)
			noteList[i] = Chart.current.notes[i];
	}

	override function destroy():Void {
		for (strumLine in strumLines)
			strumLine.destroy();
		noteGroup.destroy();
		splashGroup.destroy();
		super.destroy();
	}

	override function update(elapsed:Float):Void {
		healthBar.updateBar(Timings.health);

		while (!paused && noteGroup != null && noteList.length != 0 && curNote != noteList.length) {
			var unspawnNote:NoteData = noteList[curNote];
			if (unspawnNote == null) {
				curNote++; // skip
				break;
			}
			var strum:StrumLine = strumLines[unspawnNote.lane];
			if (strum == null) {
				curNote++; // skip
				break;
			}
			final timeDifference:Float = (unspawnNote.time - Conductor.time) - Settings.noteOffset;
			if (timeDifference > 1.5 / (strum.members[unspawnNote.dir].speed / Conductor.rate)) // 1500 / (scrollSpeed / rate)
				break;

			var epicNote:Note = noteGroup.recycle(Note);
			epicNote.parent = strumLines[unspawnNote.lane];
			epicNote.appendData(unspawnNote);
			noteGroup.add(epicNote);

			curNote++;
		}

		super.update(elapsed);
	}

	public var divider:String = " • ";

	public dynamic function updateScore():Void {

		missCount.updateMisses(Timings.rank == "N/A" ? -1 : Timings.comboBreaks);
		gradeSprite.updateGrade(FlxMath.roundDecimal(Timings.accuracy, 1), Timings.rank);

		rpcText = 'Rank: ${Timings.rank} (${Timings.accuracy}%${Timings.comboBreaks <= 0 ? " | FC" : ""})';

		#if DISCORD
		if (play != null)
			DiscordRPC.updatePresence('Playing: ${play.songMeta.name}', '${rpcText}');
		#end
	}

	public function onBeat(beat:Int):Void 
	{
		for (icon in [iconP1, iconP2])
			icon.doBump(beat);

		if(beat % 4 == 0)
			missCount.heartPulse();
	}

	// -- GETTERS & SETTERS, DO NOT MESS WITH THESE -- //
	//welp i'm afraid i have to

	public inline function getHUD():Array<FlxSprite> return [
		healthBar,
		iconP1, 
		iconP2, 
		centerMark];

	inline function get_play():PlayState return PlayState.current;
	inline function get_skin():String return Chart.current.gameInfo.skin ?? "normal";
	static inline function get_isPixel():Bool return Chart.current.gameInfo.skin == "pixel" || Chart.current.gameInfo.skin.endsWith("-pixel") ?? false;
}
