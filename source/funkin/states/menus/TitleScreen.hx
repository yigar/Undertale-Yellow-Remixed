package funkin.states.menus;

import yaml.util.Utf8;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxSpriteGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import forever.display.ForeverSprite;
import funkin.states.base.FNFState;
import funkin.ui.Alphabet;
import uty.objects.UTText;
import uty.states.menus.SaveFileMenu;

@:structInit class IntroTextSection {
	public var exec:String; // TODO: make this a void but let YAML still use it as string
	@:optional public var beat:Int;
	@:optional public var text:String;
	@:optional public var force:Bool;
	@:optional public var step:Int;
}

class TitleScreen extends FNFState {
	public var bg:FlxSprite;
	//pixel
	public var pixUT:ForeverSprite;
	public var pixYel:ForeverSprite;
	public var pixRemix:ForeverSprite;
	//flash
	public var sprUTY:ForeverSprite;
	public var sprRemixBG:ForeverSprite;
	public var sprRemixText:ForeverSprite;
	public var sprVine:ForeverSprite;

	public var enterTxt:UTText;

	public final spriteDir:String = 'images/menu/title/';

	public final logoMaxScale:Float = 1.00;
	public final logoMinScale:Float = 0.95;

	// -- BEHAVIOR FIELDS -- //
	public static var seenIntro:Bool = false;

	var transitioning:Bool = false;

	//a lot of shit was deleted because the custom title screen is too fundamentally different
	override function create():Void {
		super.create();

		#if DISCORD
		DiscordRPC.updatePresenceDetails("In the Menus", "TITLE SCREEN");
		#end

		FlxTransitionableState.skipNextTransIn = true;
		FlxTransitionableState.skipNextTransOut = true;

		add(bg = new FlxSprite().makeSolid(FlxG.width, FlxG.height, 0xFF000000));

		new flixel.util.FlxTimer().start(0.05, function(tmr) {
			Conductor.active = false;
		});

		loadTitleObjects();
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed);

			if (Controls.ACCEPT || FlxG.keys.justPressed.Z || FlxG.keys.justPressed.J || FlxG.keys.justPressed.ENTER) {
				FlxG.switchState(new SaveFileMenu());
			}
		}

	function loadTitleObjects()
	{
		pixUT = new ForeverSprite(0, 0, '${spriteDir}logoPixel_ut');
		pixUT.antialiasing = false;
		pixUT.scale.set(8.0, 8.0);
		pixUT.updateHitbox();

		pixYel = new ForeverSprite(0, 0, '${spriteDir}logoPixel_yellow');
		pixYel.antialiasing = false;
		pixYel.scale.set(8.0, 8.0);
		pixYel.updateHitbox();

		pixRemix = new ForeverSprite(0, 0, '${spriteDir}logoPixel_remixed');
		pixRemix.antialiasing = false;
		pixRemix.scale.set(3.0, 3.0);
		pixRemix.updateHitbox();
		
		sprUTY = new ForeverSprite(0, 0, '${spriteDir}logo_uty');
		sprUTY.updateHitbox();

		sprRemixBG = new ForeverSprite(0, 0, '${spriteDir}logo_remixedBG');
		sprRemixBG.updateHitbox();

		sprRemixText = new ForeverSprite(0, 0, '${spriteDir}logo_remixed');
		sprRemixText.updateHitbox();

		sprVine = new ForeverSprite(0, 0, '${spriteDir}logo_vine');
		sprVine.updateHitbox();
		//QUICK FIX
		sprVine.visible = false;

		for (spr in [pixUT, pixYel, pixRemix, sprUTY, sprRemixBG, sprRemixText, sprVine])
			spr.alpha = 0.0;

		add(pixUT);
		add(pixYel);
		add(pixRemix);
		add(sprUTY);
		add(sprRemixBG);
		add(sprRemixText);
		add(sprVine);

		var midX = Std.int(FlxG.width * 0.5);
		var midY = Std.int(FlxG.height * 0.5);

		pixUT.setPosition(midX - Std.int(pixUT.width * 0.5), Std.int(FlxG.height * 0.35));
		pixYel.setPosition(midX - Std.int(pixYel.width * 0.5), pixUT.y + pixUT.height + 20);
		pixRemix.setPosition(midX - Std.int(pixRemix.width * 0.5), Std.int(FlxG.height * 0.55));

		sprUTY.setPosition(midX - Std.int(sprUTY.width * 0.5), Std.int(FlxG.height * 0.10));
		sprRemixBG.setPosition(midX - Std.int(sprRemixBG.width * 0.5), Std.int(FlxG.height * 0.55));
		sprRemixText.setPosition(sprRemixBG.x, sprRemixBG.y);
		sprVine.setPosition(midX - Std.int(sprVine.width * 0.5), Std.int(FlxG.height * 0.50));

		//enter text at the end
		enterTxt = new UTText(midX, FlxG.height - 80, 0, "[ Press Z, J, or ENTER ]");
		enterTxt.setFont(PIXELA, 38, 0xFF5B5B5B, CENTER, 3);
		enterTxt.x = midX - Std.int(enterTxt.width * 0.5);
		enterTxt.alpha = 0.0;
		add(enterTxt);

		new flixel.util.FlxTimer().start(0.5, function(tmr:FlxTimer){titleSequence();});
	}

	function titleSequence()
	{
		//"UNDERTALE" appears
		spritesAppearWithSound([pixUT], 'snd_intronoise');
		//"YELLOW" appears
		new flixel.util.FlxTimer().start(1.5, function(tmr:FlxTimer){
			spritesAppearWithSound([pixYel], 'snd_intronoise');
			//aforementioned sprites tween upwards
			new flixel.util.FlxTimer().start(1.0, function(tmr:FlxTimer){
				pixUT.tween({y: pixUT.y - 50}, 1.5, {ease: FlxEase.sineInOut});
				pixYel.tween({y: pixYel.y - 50}, 1.7, {ease: FlxEase.sineInOut});
				//"REMIXED" appears
				new flixel.util.FlxTimer().start(2.0, function(tmr:FlxTimer){
					spritesAppearWithSound([pixRemix], 'snd_switch');
					//pixel variants of sprites are hidden, the flash versions appear with a bump effect
					new flixel.util.FlxTimer().start(1.5, function(tmr:FlxTimer){
						pixUT.visible = false;
						pixYel.visible = false;
						pixRemix.visible = false;
						FlxG.camera.flash(0x8CFFFFFF, 0.3);
						spritesAppearWithSound([sprUTY, sprRemixBG, sprRemixText, sprVine], 'snd_undertale_flash');
						tweenLogoScale(logoMaxScale, logoMinScale, 1.0);
						//display the "press enter" text
						new FlxTimer().start(2.0, function(tmr:FlxTimer){
						enterTxt.alpha = 1.0;
						});
					});
				});
			});
		});
	}

	//quick time-saving function
	function spritesAppearWithSound(ary:Array<ForeverSprite>, sound:String)
	{
		for(spr in ary)
			spr.alpha = 1.0;
		FlxG.sound.play(AssetHelper.getAsset('audio/sfx/${sound}', SOUND));
	}

	function tweenLogoScale(start:Float, end:Float, time:Float)
	{
		sprUTY.scale.set(start, start);
		sprRemixBG.scale.set(start, start);
		sprRemixText.scale.set(start, start);
		sprVine.scale.set(start, start);

		sprUTY.updateHitbox();
		sprRemixBG.updateHitbox();
		sprRemixText.updateHitbox();
		sprVine.updateHitbox();

		FlxTween.tween(sprUTY.scale, {x: logoMinScale, y: logoMinScale}, time, {ease: FlxEase.expoOut});
		FlxTween.tween(sprRemixBG.scale, {x: logoMinScale, y: logoMinScale}, time, {ease: FlxEase.expoOut});
		FlxTween.tween(sprRemixText.scale, {x: logoMinScale, y: logoMinScale}, time, {ease: FlxEase.expoOut});
		FlxTween.tween(sprVine.scale, {x: logoMinScale, y: logoMinScale}, time, {ease: FlxEase.expoOut});
	}

	override function onBeat(beat:Int):Void {

	}

	override function onStep(step:Int):Void {
	}
}
