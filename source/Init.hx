package;

import flixel.FlxG;
import flixel.FlxState;
import flixel.addons.transition.FlxTransitionSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.ui.FlxSoundTray;
import haxe.ds.StringMap;
import uty.components.StoryData;
import forever.Controls;
import flixel.input.keyboard.FlxKey;

/**
 * This is the initialization class, it simply modifies and initializes a few important variables
 * add anything in here for the game to initialize before beginning
**/
class Init extends FlxState {
	override function create():Void {
		super.create();

		setupDefaults();
		setupTransition();
		precacheAssets();

		FlxG.save.bind('Settings', "yigar/UTYRemixed/forever");
		if (FlxG.save.data != null)
		{
			FlxG.sound.muted = FlxG.save.data.mute ?? false;
			FlxG.sound.volume = FlxG.save.data.volume ?? 1.0;
			//retrieve saved controls
			var m:Map<String, Array<FlxKey>> = FlxG.save.data.savedControls;
			if(m != null)
				Controls.current.setControlsFromMap(m);
		}

		//the meta save file is a necessary file for the context of undertale.
		//this will store variables and actions of things that cannot be reversed.
		//in this case it's just checking if this is the first time we've opened the game.
		FlxG.save.bind('meta', 'yigar/UTYRemixed');
		if (FlxG.save.data.firstBoot == null) 
			FlxG.save.data.firstBoot = true;
		//this is set to false when completing the firstBootState.

		FlxG.save.flush();

		//rebinding to the story save file is handled in the StoryData class, so it shouldn't be much of a concern.
		FlxG.save.bind('utyRemixed', 'yigar/UTYRemixed/uty');
		if(FlxG.save.data != null)
		{
			StoryData.loadData();
		}

		// -- CUSTOM SPLASH SCREEN -- //

		/*
		final graph:FlxGraphic = Paths.image("ui/splash/clover");

		final clover:FlxSprite = new FlxSprite().loadGraphic(graph, true, graph.width, graph.height);
		clover.animation.add("wink", [0, 1, 2, 3, 4, 5, 6, 7, 8], 24, false);
		clover.animation.curAnim.curFrame = 0;
		clover.alpha = 0.0;
		add(clover);

		clover.animation.finishCallback = function(a:String):Void
			FlxG.switchState(Type.createInstance(Main.initialState, []));
		*/

		FlxG.switchState(Type.createInstance(Main.initialState, []));
	}

	function precacheAssets():Void {
		final cacheGraphics:StringMap<flixel.graphics.FlxGraphic> = [
			"boldAlphabet" => AssetHelper.getGraphic(AssetHelper.getPath("images/ui/letters/bold", IMAGE), "boldAlphabet")
		];

		final cacheSounds:StringMap<openfl.media.Sound> = [
			"scrollMenu" => AssetHelper.getSound(AssetHelper.getPath("audio/sfx/scrollMenu", SOUND), "scrollMenu"),
			"cancelMenu" => AssetHelper.getSound(AssetHelper.getPath("audio/sfx/cancelMenu", SOUND), "cancelMenu"),
			"confirmMenu" => AssetHelper.getSound(AssetHelper.getPath("audio/sfx/confirmMenu", SOUND), "confirmMenu"),
			"breakfast" => AssetHelper.getSound(AssetHelper.getPath("audio/bgm/breakfast", SOUND), "breakfast"),
			"snd_mainmenu_select" => AssetHelper.getSound(AssetHelper.getPath("audio/sfx/snd_mainmenu_select", SOUND), "snd_mainmenu_select"),
			"snd_confirm" => AssetHelper.getSound(AssetHelper.getPath("audio/sfx/snd_confirm", SOUND), "snd_confirm"),
		];

		FlxTransitionableState.skipNextTransIn = true;

		for (k => v in cacheGraphics) AssetHelper.excludedGraphics.set(k, v);
		for (k => v in cacheSounds) AssetHelper.excludedSounds.set(k, v);
	}

	function setupDefaults():Void {
		FlxG.fixedTimestep = false;
		FlxG.mouse.useSystemCursor = true;
		FlxG.game.focusLostFramerate = 10;
		FlxG.mouse.visible = false;

		forever.Settings.load();
		// FlxGraphic.defaultPersist = true;
		flixel.FlxSprite.defaultAntialiasing = forever.Settings.globalAntialias;
		forever.Controls.current = new forever.ControlsManager();

		#if DISCORD forever.core.DiscordWrapper.initialize("1325211048801992715"); #end
		#if MODS
		forever.core.Mods.initialize();
		if (FlxG.save.data.currentMod != null)
			forever.core.Mods.loadMod(FlxG.save.data.currentMod);
		#end
	}

	function setupTransition():Void {
		var graphic:FlxGraphic = FlxGraphic.fromClass(GraphicTransTileDiamond);
		graphic.destroyOnNoUse = false;
		graphic.persist = true;

		final transition:TransitionTileData = {
			asset: graphic,
			width: 32,
			height: 32,
			frameRate: 24
		};
		final transitionArea:FlxRect = FlxRect.get(-200, -200, FlxG.width * 2.0, FlxG.height * 2.0);

		FlxTransitionableState.defaultTransIn = new TransitionData(FADE, 0xFF000000, 0.4, FlxPoint.get(0, 0), transition, transitionArea);
		FlxTransitionableState.defaultTransOut = new TransitionData(FADE, 0xFF000000, 0.4, FlxPoint.get(0, 0), transition, transitionArea);
	}
}
