package funkin.states;

import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.sound.FlxSound;
import flixel.util.FlxTimer;
import forever.core.scripting.*;
import forever.display.ForeverSprite;
import forever.display.RecycledSpriteGroup;
import funkin.components.ChartLoader;
import funkin.components.Timings;
import funkin.components.parsers.ForeverEvents as ChartEventOptions;
import funkin.objects.*;
import funkin.objects.StageBase;
import funkin.objects.play.Note;
import funkin.states.base.FNFState;
import funkin.states.editors.*;
import funkin.states.menus.*;
import funkin.substates.*;
import funkin.ui.ComboSprite;
import uty.components.PlayerData;
import uty.components.StoryData;
import funkin.components.StatsCalculator;
import uty.components.Opponents;
import uty.states.Overworld;
import uty.states.menus.MemoryLogMenu;
import uty.scripts.UTScript;
import funkin.ui.CerobaShield;
import funkin.objects.play.Ally;
import uty.components.SoundManager;
import uty.objects.UTText;

enum abstract GameplayMode(Int) to Int {
	var STORY = 0;
	var FREEPLAY = 1;
	var CHARTER = 2;
}

enum abstract MusicState(Int) to Int {
	var STOPPED = 0;
	var PLAYING = 1;
	var PAUSED = 2;
}

@:structInit class PlaySong {
	public var name:String;
	public var folder:String;
	public var difficulty:String;
}

class PlayState extends FNFState {
	/** Current (existing) instance of PlayState. **/
	public static var current:PlayState;

	public var songMeta:PlaySong = {name: "Test", folder: "test", difficulty: "normal"};
	public var playMode:GameplayMode = FREEPLAY;
	public var songState:Int = STOPPED;

	public var bg:ForeverSprite;
	public var playField:PlayField;

	public var shortcutMsg:UTText; //gives shortcut key feedback
	public var shortcutFadeTimer:FlxTimer;

	public var camLead:FlxObject;

	public var gameCamera:FlxCamera;
	public var hudCamera:FlxCamera;
	public var altCamera:FlxCamera;

	public var stage:StageBase;

	public var player:Character;
	public var enemy:Character;
	public var crowd:Character;

	public var inst:FlxSound;
	public var vocals:FlxSound;

	public var comboGroup:RecycledSpriteGroup<ComboSprite>;

	public var bumpEnabled:Bool = Settings.cameraZooms;
	public var hudBump:Bool = Settings.hudZooms;

	public var bumpIntensity:Float = 0.015;
	public var hudBumpIntensity:Float = 0.05;

	//custom data components
	public var opponentData:OpponentData = {name: "flowey", at: 1, df: 0, love: 0, killed: false};

	//custom live components
	public var invTimer:Float = 0.0;
	public var resetTimer:Float = 0.0; //this has to be separate from the invTimer, otherwise resetting could be abused for i-frames
	public var gameOvered:Bool = false;
	public var suicideClock:Float = 0.0; //for a fun little reset button effect
	//shield stuff
	public var shieldEnabled:Bool = false; //do not confuse these two; enabled activates the mechanic
	public var shieldCharged:Bool = false; //this determines if the shield can be used or not
	public var shieldPercent:Float = 0.0;
	public var absorbThisHit:Bool = false; //for the shield mechanic; allows for the hurt code to be intercepted
	public var ally:Ally;

	/**
	 * Constructs the Gameplay State
	 * @param songInfo 			Assigns a new song to the PlayState.
	**/
	public function new(songInfo:PlaySong, mode:GameplayMode):Void {
		super();
		this.songMeta = songInfo;

		playMode = mode;
	}

	@:dox(hide) override function create():Void {
		super.create();

		current = this;

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		if (Conductor.active != true) // false or null
			Conductor.active = true;

		scriptPack = initAllScriptsAt([
			AssetHelper.getPath("data/scripts/global"),
			AssetHelper.getPath('songs/${songMeta.folder}/scripts'),
		]);
		setPackVar('game', this);
		callFunPack("create", []);

		// -- PREPARE AUDIO -- //
		vocals = new FlxSound();

		var instTrack = null;
		var vocalTrack = null;

		// -- FIXES FOR LINUX -- //

		final audioFolder:String = 'songs/${songMeta.folder}/audio';
		for (i in Tools.listFiles(AssetHelper.getPath(audioFolder))) {
			var fileName:String = i.toLowerCase().replace("." + haxe.io.Path.extension(i), "");
			if (fileName == "inst")
				instTrack = AssetHelper.getAsset('${audioFolder}/${i}', SOUND);
			if (fileName == "vocals" || fileName == "voices")
				vocalTrack = AssetHelper.getAsset('${audioFolder}/${i}', SOUND);
		}

		if (instTrack != null) {
			inst = new FlxSound().loadEmbedded(instTrack);
			FlxG.sound.music = inst;
			inst.onComplete = () -> beginCutscene(true);
			FlxG.sound.music.looped = false;
		}
		if (vocalTrack != null) {
			vocals.loadEmbedded(vocalTrack);
			FlxG.sound.list.add(vocals);
			vocals.looped = false;
		}
		Timings.reset();

		Conductor.time = -(Conductor.crochet) * 2.0;
		FlxG.mouse.visible = false;

		// -- PREPARE CAMERAS -- //
		gameCamera = FlxG.camera;
		hudCamera = new FlxCamera();
		altCamera = new FlxCamera();

		hudCamera.bgColor = altCamera.bgColor = 0xFF000000;
		hudCamera.bgColor.alphaFloat = Tools.toFloatPercent(Settings.stageDim);
		altCamera.bgColor.alphaFloat = 0.0;

		FlxG.cameras.add(hudCamera, false);
		FlxG.cameras.add(altCamera, false);

		// -- PREPARE BACKGROUND -- //
		add(stage = new StageBase(Chart.current.gameInfo.stageBG));
		gameCamera.zoom = stage.cameraZoom;
		hudCamera.zoom = stage.hudZoom;

		// -- PREPARE CHARACTERS -- //
		add(crowd = new Character(stage.crowdPosition.x, stage.crowdPosition.y, Chart.current.gameInfo.chars[2], false)); //TEMP FIX: \/
		crowd.visible = false;
		add(player = new Character(stage.playerPosition.x, stage.playerPosition.y, Chart.current.gameInfo.chars[0], true)); player.visible = false;
		add(enemy = new Character(stage.enemyPosition.x, stage.enemyPosition.y, Chart.current.gameInfo.chars[1], false));
		//setting up enemy data here as well
		opponentData = Opponents.returnFromName(Chart.current.gameInfo.chars[1]);

		// -- SETUP CAMERA -- // (doing this AFTER characters to immediately set the camFollow to the enemy's sprite.)
		add(camLead = new FlxObject(0, 0, 1, 1));
		gameCamera.follow(camLead, LOCKON);

		// -- PREPARE USER INTERFACE -- //
		add(comboGroup = new RecycledSpriteGroup<ComboSprite>());
		add(playField = new PlayField());
		for (hud in playField.getHUD())
			hud.alpha = 1.0;

		playField.camera = hudCamera;
		if (Settings.fixedJudgements)
			comboGroup.camera = hudCamera;

		// custom: prepare function feedback //
		add(shortcutMsg = new UTText(10, 500, 0, "shortcut txt"));
		shortcutMsg.setFont(PIXELA, 24);
		shortcutMsg.setBorder(2);
		shortcutMsg.alpha = 0.0;

		shortcutMsg.camera = hudCamera;

		// -- PREPARE CHART AND NOTEFIELDS -- //
		Conductor.bpm = Chart.current.songInfo.beatsPerMinute;

		for (lane in playField.strumLines) {
			lane.onNoteHit.add(hitBehavior);
			lane.onNoteMiss.add(missBehavior);
			lane.onSustainTick.add(sustainTickBehavior);
			lane.onSustainMiss.add(sustainMissBehavior);
		}

		for (i in 0...4) // preload notesplashes
			playField.plrStrums.createSplash({time: 0.0, dir: 0, type: "default"}, true, true);

		#if DISCORD
		DiscordRPC.updatePresenceDetails('Playing: ${songMeta.name}', '');
		#end

		// cache combo and stuff
		var comboCache:ComboSprite = new ComboSprite();
		comboCache.loadSprite("sick-perfect", playField.skin);
		comboCache.alpha = 0.0000001;
		comboGroup.add(comboCache);
		new FlxTimer().start(0.3, function(tmr:FlxTimer):Void comboCache.kill());

		callFunPack("createPost", []);

		if (Chart.current != null && Chart.current.events[0] != null)
			processEvent(Chart.current.events[0].event);

		openfl.system.System.gc();

		// -- CUTSCENES -- //
		//beginCutscene(false);
	}

	public function beginCutscene(endingRound:Bool):Void {
		switch (songMeta.folder) {
			// case "song-folder": // in case you wanna hardcode
			default:
				final cutsceneEvent:CancellableEvent = new CancellableEvent();
				callFunPack(endingRound ? "ending" : "start" + "Cutscene", [cutsceneEvent]);
				if (cutsceneEvent.cancelled) return;

				final routineToFollow = endingRound ? endPlay : countdownRoutine;
				routineToFollow();
		}
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed);
		updateDebug(); //remove later

		invTimer -= elapsed;
		resetTimer -= elapsed;

		final updateEvt:CancellableEvent = new CancellableEvent();
		callFunPack("update", [elapsed, updateEvt]);
		if (updateEvt.cancelled) return;

		if (Conductor.time >= 0 && songState != PAUSED)
			startPlay();

		FlxG.camera.followLerp = FlxMath.bound(elapsed * 2.4 * stage.cameraSpeed * (FlxG.updateFramerate / 60.0), 0.0, 1.0);
		parseEventColumn(Chart.current.events, eventIndex, (e) -> processEvent(e.event), 0.0); // old rewrite type beat

		resetCheck(elapsed);

		//idk how to override this so i'm deleting this metadata for now
		if (FlxG.keys.justPressed.SEVEN) openChartEditor();
		if (Controls.PAUSE) openPauseMenu();

		//SHORTCUT FUNCTIONS
		shortcutKeyCheck();
	

		//DEBUG
		if(FlxG.keys.justPressed.F2)
			playField.updateHUDPreset();


		#if sys
		if (FlxG.keys.justPressed.SEVEN)
		{
			var dir = 'assets/funkin/songs/${songMeta.folder}-${songMeta.difficulty}.json';
			sys.io.File.saveContent(dir, ChartLoader.exportChart(Chart.current));
			trace("saved file to " + dir);
		}
			
		#end
		callFunPack("postUpdate", [elapsed]);

		//ceroba shield mechanic
		if(shieldEnabled) {
			cerobaShieldOnUpdate(elapsed);
		}
	}

	//cool function that manages the reset key.
	//
	function resetCheck(elapsed:Float)
	{
		if (Controls.RESET_HELD && Settings.resetButton)
		{
			if(resetTimer <= 0)
			{
				damagePlayer(-2 + Std.int(suicideClock * 5), true);
				resetTimer = 1.0;
			}
			resetTimer -= elapsed * (2 + (Math.pow(suicideClock * 2, 3)));
			suicideClock += elapsed;
		} 
		else
		{
			suicideClock = 0.0;
		}
	}

	override function draw():Void {
		callFunPack("preDraw", []);
		super.draw();
		callFunPack("draw", []);
	}

	override function destroy():Void {
		callFunPack("destroy", []);
		while (scriptPack.length != 0)
			scriptPack.pop().destroy();
		current = null;
		Timings.reset();
		super.destroy();
	}

	public function parseEventColumn(column:Array<Dynamic>, index:Int, fun:Dynamic->Void, ?delay:Float = 0.0):Void {
		while (index < column.length - 1) {
			if ((column[index].time - Conductor.time) > delay) break;
			if (fun != null) fun(column[index]);
			index++;
		}
	}

	public function hitBehavior(note:Note):Void {
		if (note.wasHit) return;

		final hitEvent:CancellableEvent = new CancellableEvent();
		callFunPack("hitBehavior", [note, hitEvent]);
		if (hitEvent.cancelled) return;

		final isEnemy:Bool = (note.parent == playField.enmStrums);
		var character:Character = isEnemy ? enemy : player;
		// TODO: a better system -Crow
		if (character.animationContext != 3) { // 3 means "special"
			character.playAnim(character.singingSteps[note.data.dir], true);
			character.holdTmr = 0.0;
		}
		if (vocals != null && vocals.playing)
			vocals.volume = 1.0;

		if (!note.parent.cpuControl) {
			var millisecondTiming:Float = Math.abs((note.data.time - Conductor.time) * 1000.0);
			var judgement:Judgement = Timings.judgeNote(millisecondTiming);
			Timings.totalMs += millisecondTiming;

			var params = Tools.getEnumParams(judgement);

			Timings.score += params[1];
			if (Timings.combo < 0)
				Timings.combo = 0;
			Timings.combo += 1;

			Timings.totalNotesHit += 1;
			Timings.accuracyWindow += Math.max(0, params[2]);
			Timings.increaseJudgeHits(params[0]);

			//gameplay behavior
			healPlayer();
			if(shieldEnabled)
				cerobaShieldOnHit();

			if (params[3] || note.splash)
				note.parent.createSplash(note.data);

			final chosenType:ComboPopType = FlxMath.roundDecimal(Timings.accuracy, 2) >= 100 ? PERFECT : NORMAL;
			displayJudgement(params[0], note.data.time < Conductor.time, chosenType);
			displayCombo(Timings.combo, chosenType);

			Timings.updateRank();
			playField.updateScore();
		}

		note.parent.invalidateNote(note);
		note.wasHit = true;

		callFunPack("postHitBehavior", []);
	}

	public function missBehavior(dir:Int, note:Note = null):Void {
		final missEvent:CancellableEvent = new CancellableEvent();
		callFunPack("missBehavior", [dir, note, missEvent]);
		if (missEvent.cancelled) return;

		if (note != null)
			note.parent.invalidateNote(note);
		if (vocals != null && vocals.playing)
			vocals.volume = 0.0;

		if (Timings.combo > 0)
			Timings.combo = 0;
		else
			Timings.combo--;
		Timings.score -= 250;

		Timings.misses += 1;

		//behavior
		if(!isInv())
		{
			//if the shield is enabled and that function returns false, it will not deal damage
			//this is because the shield gets broken instead
			if(!shieldEnabled || cerobaShieldOnMiss()) {
			gameCamera.shake(0.01, 0.2); //base this on the shield stuff
			damagePlayer();
			}
		}

		if (player.animationContext != 3)
			player.playAnim(player.singingSteps[dir] + "miss", true);

		if (missPopups) {
			displayJudgement("miss", true, MISS);
			displayCombo(Timings.combo, MISS);
		}

		Timings.updateRank();
		playField.updateScore();

		callFunPack("postMissBehavior", [dir]);
		deathCheck(player);
	}

	function deathCheck(char:Character):Bool {
		if (Timings.health > 0) return false;
		if(gameOvered) return true;

		gameOvered = true;

		Conductor.active = false;
		if (FlxG.sound.music != null) {
			FlxG.sound.music.stop();
			vocals.stop();
		}

		StoryUtil.addDeath(songMeta.name);

		final pos:FlxPoint = char.getScreenPosition();

		final gameOver:GameOverSubState = new GameOverSubState(pos.x, pos.y, char.gameOverData, char == player);
		gameOver.camera = hudCamera;
		playField.paused = true;
		songState = PAUSED;
		openSubState(gameOver);

		return true;
	}

	function isInv():Bool
	{
		return invTimer > 0.0;
	}

	public function sustainTickBehavior(note:Note) {
		final prefix = (note.isLate) ? 'miss' : '';
		final character:Character = (note.parent == playField.enmStrums) ? enemy : player;

		if (character.animationContext != 3) { // 3 means "special"
			character.playAnim(character.singingSteps[note.data.dir] + prefix, true);
			character.holdTmr = 0.0;
		}
	}

	public function sustainMissBehavior(note:Note) {
		damagePlayer();
	}

	public function healPlayer(?overrideHP:Int)
	{
		if(overrideHP != null)
		{
			Timings.health += overrideHP;
			return;
		}
		var hp = StatsCalculator.calculateRecoverHP(PlayerData.getActiveAT(), opponentData.df);
		Timings.subHealth += hp;
		//if subhealth has exceeded 1, move any "full" health points over to the actual health
		var floor = Math.floor(Timings.subHealth);
		Timings.health += floor;
		Timings.subHealth -= floor;

	}

	//set overrideAT to use a specific damage amount, otherwise the enemy's default one will be used
	public function damagePlayer(?overrideAT:Int, ?ignoreInv:Bool = false)
	{
		if(isInv() && !ignoreInv) return;

		var at = overrideAT ?? opponentData.at ?? 5;
		var damage:Int = StatsCalculator.calculateDamage(at, PlayerData.getActiveDF(), PlayerData.getActiveHP());
		Timings.health -= damage;
		FlxG.sound.play(AssetHelper.getAsset('audio/sfx/snd_hurt', SOUND));
		if(!ignoreInv)
			invTimer = Timings.inv;
		deathCheck(player);
	}

	//enables ceroba's shield. this is called when she's in the Ally slot.
	public function enableCerobaShield()
	{
		shieldEnabled = true;
		if(playField != null)
			playField.cerobaShield.visible = true;
	}

	public function cerobaShieldOnUpdate(elapsed:Float)
	{
		cerobaShieldChargeCheck();
		//visual stuff
		playField.cerobaShield.percent = shieldPercent;
	}

	function cerobaShieldOnHit()
	{
		var addChrg = CerobaShield.chargePerHit + Math.abs(CerobaShield.chargeComboBonus * Timings.combo);
		if(addChrg > CerobaShield.chargeCap)
			addChrg == CerobaShield.chargeCap;

		shieldPercent += addChrg;
		trace("SHIELD " + shieldPercent * 100);
	}

	function cerobaShieldOnMiss():Bool //returns if damage should be done
	{
		//lose some charge if not charged; absorb the hit if charged
		if(!shieldCharged) {
			shieldPercent -= CerobaShield.chargeLostOnMiss;
			if(shieldPercent < 0)
				shieldPercent = 0;
			return true;
		}
		else {
			breakCerobaShield();
			return false;
		}
	}

	function cerobaShieldChargeCheck()
	{
		if(shieldPercent >= 1.0 && !shieldCharged)
		{
			chargeCerobaShield();
		}
	}
	
	function chargeCerobaShield() 
	{
		shieldCharged = true;
		invTimer += CerobaShield.startupTime; //sort of like the yoshi shield parry in smash bros melee
		playField.cerobaShield.chargeShieldFX();
		SoundManager.playSound('snd_ceroba_trap', 0.7);
		SoundManager.playSound('snd_shop_purchase', 0.5, 0.5);
	}

	function breakCerobaShield() {
		//play sound, animation, set shit to zero, etc.
		shieldCharged = false;
		shieldPercent = 0.0;
		invTimer = CerobaShield.invTime;

		playField.cerobaShield.breakShieldFX();
		gameCamera.shake(0.03, 0.5);
		SoundManager.playSound('snd_mirrorbreak', 0.7);
		SoundManager.playSound('snd_mo_jacket_explosion', 0.7);
	}

	/** Enables the Golden Judgements & Combo Popups when having a perfect combo. **/
	public var perfectPopups:Bool = true;

	/** Enables the Red Miss Popups when missing notes. **/
	public var missPopups:Bool = true;

	/** Enables the timing sprites when hitting notes too early or late. **/
	public var timingPopups:Bool = false;

	private var lastJSpr:ComboSprite = null;

	public function displayJudgement(name:String, isLate:Bool = false, type:ComboPopType = NORMAL):Void {
		if (type == PERFECT && name == "sick" && perfectPopups)
			name = "sick-perfect";

		final placement:Float = FlxG.width * 0.55;
		final jSpr:ComboSprite = comboGroup.recycleLoop(ComboSprite).resetProps();
		var size:Float = PlayField.isPixel ? 6.0 : 0.7;

		jSpr.loadSprite('${name}0', playField.skin);
		jSpr.antialiasing = !PlayField.isPixel;
		jSpr.scale.set(size, size);
		jSpr.updateHitbox();

		if (!Settings.fixedJudgements) {
			jSpr.screenCenter(Y);
			jSpr.x = placement - 40;
			jSpr.y += 60;
		}
		else {
			// todo: better placements
			jSpr.setPosition(100, 200);
		}

		jSpr.timeScale = Conductor.rate;

		jSpr.acceleration.y = 550;
		jSpr.velocity.y = -FlxG.random.int(140, 175);
		jSpr.velocity.x = -FlxG.random.int(0, 10);

		// sick and miss don't have timings blehhhh
		if (timingPopups && (name != "sick-perfect" && name != "sick" && name != "miss")) {
			final timing:ComboSprite = comboGroup.recycleLoop(ComboSprite).resetProps();
			var size:Float = PlayField.isPixel ? 6.0 : 0.7;

			timing.loadSprite('${name}-${isLate ? "late" : "early"}0', playField.skin);
			timing.antialiasing = !PlayField.isPixel;
			timing.scale.set(size, size);
			timing.updateHitbox();

			// set positions and stuff
			timing.timeScale = jSpr.timeScale;
			timing.setPosition(jSpr.x + (isLate ? 50 : -15), jSpr.y);
			timing.acceleration.set(jSpr.acceleration.x, jSpr.acceleration.y);
			timing.velocity.set(jSpr.velocity.x, jSpr.velocity.y);

			timing.tween({alpha: 0}, 0.4, {
				onComplete: function(twn:FlxTween):Void {
					timing.kill();
					comboGroup.remove(timing, true);
				},
				startDelay: Conductor.crochet + (Conductor.crochet * 4.0) * 0.05
			});
		}

		jSpr.tween({alpha: 0}, 0.4, {
			onComplete: function(twn:FlxTween):Void {
				jSpr.kill();
				comboGroup.remove(jSpr, true);
			},
			startDelay: Conductor.crochet + (Conductor.crochet * 4.0) * 0.05
		});

		lastJSpr = jSpr;
	}

	public function displayCombo(combo:Int, type:ComboPopType = NORMAL):Void {
		final prefix:String = (type == PERFECT && perfectPopups) ? "gold" : "normal";
		final comboArr:Array<String> = Std.string(combo).split("");
		final xOff:Float = comboArr.length - 3;

		for (i in 0...comboArr.length) {
			var comboName:String = '${prefix}${comboArr[i]}0';
			if (comboArr[i] == "-" && type == MISS)
				comboName = '${prefix}minus';

			final comboX:Float = (lastJSpr.x + lastJSpr.width) + (43 * (i - xOff)) - 200;
			final cnSpr:ComboSprite = comboGroup.recycleLoop(ComboSprite).resetProps();
			final size:Float = PlayField.isPixel ? 6.0 : 0.5;
			cnSpr.loadSprite(comboName, playField.skin);
			cnSpr.antialiasing = !PlayField.isPixel;

			cnSpr.x = comboX;
			cnSpr.y = lastJSpr.y + 90;

			if (type == MISS)
				cnSpr.color = FlxColor.fromRGB(204, 66, 66);

			cnSpr.scale.set(size, size);
			cnSpr.updateHitbox();

			cnSpr.timeScale = Conductor.rate;
			cnSpr.acceleration.y = FlxG.random.int(200, 300);
			cnSpr.velocity.y = -FlxG.random.int(140, 160);
			cnSpr.velocity.x = FlxG.random.int(-5, 5);

			cnSpr.tween({alpha: 0}, 0.5, {
				onComplete: function(twn:FlxTween):Void {
					cnSpr.kill();
					comboGroup.remove(cnSpr, true);
				},
				startDelay: (Conductor.crochet * 4.0) * 0.08
			});
		}
	}

	override function onBeat(beat:Int):Void {
		playField.onBeat(beat);
		// let 'em do their thing!
		doDancersDance(beat);
		callFunPack("onBeat", [beat]);
	}

	override function onStep(step:Int):Void {
		callFunPack("onStep", [step]);
		resyncVocals();
	}

	public function resyncVocals():Void {
		if (vocals == null) return;
		
		if (vocals.playing)
			if (Math.abs(Conductor.time - (vocals.time / 1000.0)) > 15.0)
				vocals.time = FlxG.sound.music.time;
	}

	override function onBar(bar:Int):Void {
		callFunPack("onBar", [bar]);
		callFunPack("onSection", [bar]);
		callFunPack("onMeasure", [bar]);
	}

	function doDancersDance(beat:Int, ?forced:Bool = false):Void {
		var chars:Array<Character> = [player, enemy, crowd];
		for (character in chars) {
			if (character == null) continue;
			// 0 = IDLE | 1 = SING | 2 = MISS
			if (character.animationContext == 0 && beat % character.danceInterval == 0)
				character.dance(forced);
		}
	}

	override function openSubState(SubState:FlxSubState):Void {
		if (FlxG.sound.music != null && FlxG.sound.music.playing)
			FlxG.sound.music.pause();
		if (vocals != null && vocals.playing)
			vocals.pause();
		super.openSubState(SubState);
	}

	override function closeSubState():Void {
		playField.paused = false;
		if (FlxG.sound.music != null && FlxG.sound.music.playing)
			FlxG.sound.music.resume();
		if (vocals != null && vocals.playing) {
			vocals.resume();
			resyncVocals();
		}
		songState = PLAYING;
		#if DISCORD
		DiscordRPC.updatePresenceDetails('${songMeta.name}', '${playField.rpcText}');
		#end
		pauseTweens(false);
		super.closeSubState();
	}

	public function preloadEvent(which:ChartEventOptions):Void {
		switch (which) {
			case ChangeCharacter(who, toCharacter):
			/*
				var newChar:Character = new Character(0, 0);
				newChar.loadCharacter(toCharacter);
				newChar.alpha = 0.000001;
				characterGroup.add(newChar);
			 */
			case Scripted(name, script, args):
			// init hscript here.
			default:
				// do nothing
		}
	}

	var eventIndex:Int = 0;

	public function processEvent(which:ChartEventOptions):Void {
		switch (which) {
			case FocusCamera(who, noEasing):
				var character:Character = getCharacterFromID(who);
				var xPoint:Float = character.getMidpoint().x + character.cameraDisplace.x;
				var yPoint:Float = character.getMidpoint().y + character.cameraDisplace.y;

				if (camLead.x != xPoint) {
					camLead.setPosition(xPoint, yPoint);
					
				}

			case ChangeCharacter(who, toCharacter):
				getCharacterFromID(who).loadCharacter(toCharacter);
			case PlaySound(soundName, volume):
				FlxG.sound.play(AssetHelper.getAsset('audio/sfx/${soundName}'), volume);
			case Scripted(name, script, args):
			// init hscript here.
			default:
				// do nothing
		}
	}

	// -- HELPER FUNCTIONS -- //

	function openChartEditor():Void {
		#if DISCORD
		DiscordRPC.updatePresenceDetails('Charting: ${songMeta.name}');
		#end
		final charter:ChartEditor = new ChartEditor();
		charter.camera = altCamera;
		playField.paused = true;
		songState = PAUSED;
		openSubState(charter);
	}

	function openPauseMenu():Void {
		pauseTweens(true);
		#if DISCORD
		DiscordRPC.updatePresenceDetails('${songMeta.name} [PAUSED]', '${playField.rpcText}');
		#end
		final pause:PauseMenu = new PauseMenu(Chart.current.gameInfo.pauseData);
		pause.camera = altCamera;
		playField.paused = true;
		songState = PAUSED;
		openSubState(pause);
	}

	function pauseTweens(resume:Bool):Void {
		FlxTween.globalManager.forEach(function(t) t.active = !resume);
		FlxTimer.globalManager.forEach(function(t) t.active = !resume);
	}

	function startPlay():Void {
		if (FlxG.sound.music.playing && songState != PAUSED) return;
		final startPlayEvt:CancellableEvent = new CancellableEvent();
		callFunPack("startPlay", [startPlayEvt]);
		if (startPlayEvt.cancelled) return;

		if (FlxG.sound.music != null) {
			FlxG.sound.music.play();
			vocals.play();
		}

		songState = PLAYING;
	}

	function endPlay():Void {
		final endPlayEvt:CancellableEvent = new CancellableEvent();
		callFunPack("endPlay", [endPlayEvt]);
		if (endPlayEvt.cancelled) return;

		if (FlxG.sound.music != null) {
			FlxG.sound.music.stop();
			vocals.stop();
		}

		switch (playMode) {
			case STORY:
			{
				Conductor.init();
				//assign songs specific scripts later
				var script:UTScript = new UTScript(AssetHelper.getAsset('data/scripts/overworld/floweySongBeaten', HSCRIPT));
				script.set('room', 'testLevel');
				script.set('x', 0);
				script.set('y', 0);
				// ^ set these variables to their proper values in the script. 
				script.call("start");
				FlxG.switchState(new Overworld(script.get('room'), script.get('x'), script.get('y'), script.get('prepareOverworld')));
				//FOR NOW, THIS SCRIPT SETUP WORKS.
				//obviously should ideally make it more dynamic than this in the future
			} 
			#if FE_DEV
			case CHARTER:
				Conductor.init();
				openChartEditor();
			#end
			case _:
				Conductor.init(); 
				FlxG.switchState(new MemoryLogMenu());
		}
	}

	var countdownPosition:Int = 0;

	public function countdownRoutine():Void {
		final countdownEvt:CancellableEvent = new CancellableEvent();
		callFunPack("countdownRoutine", [countdownPosition, songState, countdownEvt]);
		if (countdownEvt.cancelled) return;

		if (songState != PLAYING) {
			Conductor.time = -(Conductor.crochet) * 4.0;
			for (hud in playField.getHUD())
				FlxTween.tween(hud, {alpha: 1.0}, (Conductor.crochet) * 2.0, {ease: FlxEase.sineIn});
		}

		final sounds:Array<String> = ['intro3', 'intro2', 'intro1', 'introGo'];

		new FlxTimer().start(Conductor.crochet, function(tmr:FlxTimer) {
			final sprCount = getCountdownSprite(countdownPosition);
			if (sprCount != null) {
				sprCount.screenCenter();
				sprCount.timeScale = Conductor.rate;
				sprCount.camera = hudCamera;
				if (PlayField.isPixel) {
					sprCount.antialiasing = false;
					sprCount.scale.set(6.0, 6.0);
					sprCount.updateHitbox();
				}
				add(sprCount);

				sprCount.stopTweens();
				sprCount.tween({alpha: 0, y: sprCount.y + 100}, Conductor.crochet, {
					ease: FlxEase.sineOut,
					onComplete: function(t) {
						sprCount.destroy();
					}
				});
			}

			FlxG.sound.play(AssetHelper.getAsset('audio/countdown/${playField.skin}/${sounds[countdownPosition]}', SOUND), 0.8);
			countdownPosition++;

			doDancersDance(tmr.loops);
			callFunPack("countdownProgress", [countdownPosition, songState]);
		}, 4);
	}

	inline function getCharacterFromID(id:Int):Character {
		return switch (id) {
			default: enemy;
			case 1: player;
			case 2: crowd;
		}
	}

	function getCountdownSprite(tick:Int):ForeverSprite {
		final sprites:Array<String> = ["prepare", "ready", "set", "go"];
		if (sprites[tick] != null && Tools.fileExists(AssetHelper.getPath('images/ui/${playField.skin}/${sprites[tick]}', IMAGE)))
			return new ForeverSprite(0, 0, 'images/ui/${playField.skin}/${sprites[tick]}', {"scale.x": 0.9, "scale.y": 0.9});
		return null;
	}

	function updateDebug()
	{
		if(FlxG.keys.pressed.O && shieldEnabled) {
			shieldPercent += 0.10;
		}
		if(FlxG.keys.justPressed.P && shieldEnabled) {
			breakCerobaShield();
		}
	}
	
	//checks all setting shortcut keys, calls their functions, displays feedback.
	function shortcutKeyCheck()
	{
		var feedbackMessage:String = "";

		//changes HUD preset
		if(FlxG.keys.justPressed.F1) {
			playField.incrementHUDPreset();
			feedbackMessage = "F1 - Change HUD (" + playField.getHUDPresetData().name + ")";
		}

		if(feedbackMessage.length > 0)
			displayShortcutFeedback(feedbackMessage, 2.5);
	}

	//gives feedback on shortcut keys, preventing confusion
	function displayShortcutFeedback(message:String, time:Float)
	{
		FlxTween.cancelTweensOf(shortcutMsg, ["alpha"]);
		shortcutMsg.alpha = 1.0;
		shortcutMsg.text = message;

		if(shortcutFadeTimer != null)
			shortcutFadeTimer.cancel();
		shortcutFadeTimer = new FlxTimer().start(time * 0.80, function(tmr:FlxTimer):Void{
			FlxTween.tween(shortcutMsg, {alpha: 0.0}, time * 0.20);
		});
		
	}
}
