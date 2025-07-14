package funkin.objects;

import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;

import forever.display.ForeverText;
import forever.display.RecycledSpriteGroup;

import funkin.components.ChartLoader;
import funkin.components.Timings;
import funkin.components.parsers.ChartFormat.NoteData;
import funkin.objects.play.*;
import funkin.states.PlayState;
import funkin.ui.HealthBar;
import funkin.ui.UTIcon;
import funkin.ui.CerobaShield;
import funkin.ui.SongTitle;

import haxe.ds.Vector;

import uty.components.StoryData;
import uty.objects.UTText;

/**
 * Play Field contains basic objects to handle gameplay
 * Note Fields, Notes, etc.
**/

//lets the player choose a preferred HUD layout preset
//to some extent this should be hard-coded and not whatever's in the folder.
enum abstract HUDPreset(String)from String to String{
	var DEFAULT:String = "default";
	var MINIMAL:String = "minimal";
	var OFF:String = "off";
}

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

	public var songTitle:SongTitle;

	public var healthBar:HealthBar;
	public var iconP1:UTIcon;
	public var iconP2:UTIcon;
	public var iconStartY:Int;

	public var cerobaShield:CerobaShield;

	public var rpcText:String;

	public var missCount:MissCounter;
	public var gradeSprite:GradeSprite;

	public var splashGroup:RecycledSpriteGroup<NoteSplash>;

	//HUD PRESETS
	//in case of exclusive boss huds, the list of hud presets for normal songs is hardcoded here.
	public final baseHudPresets:Array<HUDPreset> = [DEFAULT, MINIMAL, OFF];
	public var curHudPreset:Int = 0; //for looping
	public var hudPresetData:Array<Dynamic>;

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

		add(iconP1 = new UTIcon(PlayState.current?.player?.icon ?? "face", true));
		add(iconP2 = new UTIcon(PlayState.current?.enemy?.icon ?? "face", false));
		iconP2.lowHealthFlash = false;

		for (i in [iconP1, iconP2]) i.y = healthBar.y - (i.height * 0.5);
		
		centerIconX();

		iconStartY = Std.int(iconP1.y);

		//ceroba shield, deactivate 
		add(cerobaShield = new CerobaShield(0, 0));

		cerobaShield.x = iconP1.x - (iconP1.width);
		cerobaShield.y = iconP1.y - (iconP1.height);

		//hide the shield if it's not active for this song.
		//does not affect the mechanics; shield mechanics are in the playstate and cerobashield object
		if(!PlayState.current.shieldEnabled) {
			cerobaShield.visible = false;
		}

		// [${play.songMeta.difficulty.toUpperCase()}] -'
		//improve this song display later
		var songString:String = play.songMeta.name.toUpperCase();
		songTitle = new SongTitle(6, 6, songString);
		add(songTitle);

		missCount = new MissCounter(Settings.centerStrums ? FlxG.width - 100 : plrStrums.x - 100, 90);
		add(missCount);

		gradeSprite = new GradeSprite(50, 70);
		add(gradeSprite);

		updateScore();

		//all the hud stuff is done; now update it from the preset settings
		initializeHUDPresetData();
		updateHUDPreset();

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

	private function centerIconX(?gap:Int = 150)
	{
		iconP1.x = FlxG.width - gap - (iconP1.width * 0.50);
		iconP2.x = gap - (iconP2.width * 0.50);
	}

	public dynamic function updateScore():Void {

		missCount.updateMisses(Timings.rank == "N/A" ? -1 : Timings.comboBreaks);
		gradeSprite.updateGrade(FlxMath.roundDecimal(Timings.accuracy, 1), Timings.rank);

		rpcText = 'Rank: ${Timings.rank} (${Timings.accuracy}%${Timings.comboBreaks <= 0 ? " | FC" : ""})';

		#if DISCORD
		if (play != null)
			DiscordRPC.updatePresence('Playing: ${play.songMeta.name}', '${rpcText}');
		#end
	}

	private function initializeHUDPresetData()
	{
		hudPresetData = new Array<Dynamic>();
		//retrieves hud presets defined in baseHudPresets, pushes to the data array
		for(i in 0...baseHudPresets.length)
		{
			var data = AssetHelper.parseAsset('data/ui/hud/${baseHudPresets[i]}', YAML);
			hudPresetData.push(data);
		}
		//add null checks on initialization
	}

	public function incrementHUDPreset()
	{
		curHudPreset++;
		if(curHudPreset >= baseHudPresets.length)
			curHudPreset = 0;

		updateHUDPreset();
	}

	public function updateHUDPreset()
	{
		//trace('PRESET: ${hudPresetData[curHudPreset].hud.name}');
		gradeSprite.updateHUDPreset(hudPresetData[curHudPreset].hud.grade);
		healthBar.updateHUDPreset(hudPresetData[curHudPreset].hud.healthbar);
		missCount.updateHUDPreset(hudPresetData[curHudPreset].hud.misses);
		updateHUDPresetIcons(hudPresetData[curHudPreset].hud.icons);
		//save the current HUD preset in the settings
		Settings.hudPreset = baseHudPresets[curHudPreset];
		Settings.flush();
	}

	private function updateHUDPresetIcons(data:Dynamic)
	{
		iconP1.visible = data.iconP1.visible;
		iconP1.scale.set(data.iconP1.scale, data.iconP1.scale);
		iconP2.visible = data.iconP2.visible;
		iconP2.scale.set(data.iconP2.scale, data.iconP2.scale);
		
		iconP1.updateHitbox();
		iconP2.updateHitbox();

		centerIconX(data.gap);

		iconP1.x += data.iconP1.xOffset;
		iconP2.x += data.iconP2.xOffset;
		iconP1.y = iconStartY + data.iconP1.yOffset;
		iconP2.y = iconStartY + data.iconP2.yOffset;
		iconP1.updateHitbox();
		iconP2.updateHitbox();
	}

	public function onBeat(beat:Int):Void 
	{
		for (icon in [iconP1, iconP2])
		{
			icon.doBump(beat);
			icon.dangerFlash(beat);
		}

		if(beat % 4 == 0)
			missCount.heartPulse();
	}

	// -- GETTERS & SETTERS, DO NOT MESS WITH THESE -- //
	//welp i'm afraid i have to

	public inline function getHUD():Array<FlxSprite> return [
		healthBar,
		iconP1, 
		iconP2, 
		songTitle];

	public inline function getHUDPresetData():Dynamic 
		return hudPresetData[curHudPreset].hud;

	inline function get_play():PlayState return PlayState.current;
	inline function get_skin():String return Chart.current.gameInfo.skin ?? "normal";
	static inline function get_isPixel():Bool return Chart.current.gameInfo.skin == "pixel" || Chart.current.gameInfo.skin.endsWith("-pixel") ?? false;
}