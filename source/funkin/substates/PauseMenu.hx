package funkin.substates;

import uty.ui.Window;
import flixel.group.FlxSpriteGroup;
import flixel.FlxSubState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.sound.FlxSound;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.util.FlxGradient;
import forever.display.ForeverText;
import funkin.states.PlayState;
import funkin.states.menus.*;
import funkin.ui.Alphabet;
import forever.display.ForeverSprite;
import lime.app.Future;
import lime.app.Promise;
import flixel.addons.display.FlxBackdrop;
import flixel.math.FlxPoint;
import uty.ui.Window;

using flixel.util.FlxStringUtil;

private enum PauseButton {
	PauseButton(name:String, call:Void->Void);
}

@:access(funkin.states.PlayState)
class PauseMenu extends FlxSubState {
	var pauseLists:Map<String, Array<PauseButton>> = [];
	var pauseGroup:FlxTypedGroup<PauseOption>;
	var pauseItems:Array<PauseButton> = [];
	var art:ForeverSprite;
	var pauseLetters:FlxTypedSpriteGroup<PauseLetter>;
	final _letters:Array<Dynamic> = [
		["p", 0, 0], 
		["a", 70, -5], 
		["u", 150, -12], 
		["s", 240, -15], 
		["e", 345, -25], 
		["d", 470, -30]
	];

	var bg:FlxTypedSpriteGroup<FlxBackdrop>;
	var bgFront:FlxBackdrop;
	var bgBack:FlxBackdrop;
	var optionShadow:FlxSprite;
	var pauseInfo:PauseDescription;
	var curSel:Int = 0;
	var closing:Bool = true;

	var optionSpacingPercent:Float = 0.94;

	public var pauseMusic:FlxSound;
	public var future:Future<FlxSound>;

	public function new():Void {
		super();

		pauseLists.set("default", [
			PauseButton('resume', resumeSong),
			PauseButton('restart', function():Void {
				closing = true;
				abruptOptionSelect();
				FlxG.switchState(new PlayState(PlayState.current.songMeta));
			}),
			PauseButton('options', function():Void {
				abruptOptionSelect();
				FlxG.switchState(new OptionsMenu(PlayState.current.songMeta));
			}),
			PauseButton('quit', function():Void {
				closing = true;
				if (pauseMusic != null) pauseMusic.stop();
				if (FlxG.sound.music != null) FlxG.sound.music.stop();
				FlxG.switchState(new FreeplayMenu());
			})
		]);

		bg = new FlxTypedSpriteGroup<FlxBackdrop>();
		bg.alpha = 0.0;
		add(bg);

		bgBack = new FlxBackdrop(Paths.image('pause/tile'));
        //bgBack.cameras = [FlxG.camera];
        bgBack.velocity.set(-25, -15);
		bgBack.antialiasing = false;
		bgBack.alpha = 0.4;

		bgFront = new FlxBackdrop(Paths.image('pause/tile'));
        //bgFront.cameras = [FlxG.camera];
        bgFront.velocity.set(50, 30);
		bgFront.antialiasing = false;
		bgFront.alpha = 0.6;

        bg.add(bgBack);
		bg.add(bgFront);

		art = new ForeverSprite();
		art.loadGraphic(Paths.image('pause/art/flowey')); //temporary for now, need a way to load multiple in one song
		art.scale.set(0.8, 0.8);
		art.updateHitbox();
		art.x = 0 - art.width;
		art.y = (FlxG.height * 0.5) - (art.height * 0.5);
		art.alpha = 0.0;
		add(art);

		optionShadow = FlxGradient.createGradientFlxSprite(Std.int(FlxG.width), Std.int(FlxG.height * 0.25), [0x0, FlxColor.BLACK]);
		optionShadow.alpha = 1.0;
		optionShadow.y = FlxG.height - optionShadow.height;
		add(optionShadow);

		add(pauseGroup = new FlxTypedGroup<PauseOption>());
		add(pauseLetters = new FlxTypedSpriteGroup<PauseLetter>(FlxG.width, 40));

		pauseInfo = new PauseDescription(FlxG.width, 250, 'flowey');
		pauseInfo.alpha = 0.0;
		add(pauseInfo);

		reloadMenu(pauseLists.get("default"));
		updateSelection();

		tweenInItems();

		// so in the original game the sound just plays when you trigger the menu so...
		FlxG.sound.play(AssetHelper.getAsset('audio/sfx/snd_mainmenu_select', SOUND));

		future = new Future<FlxSound>(function():FlxSound {
			pauseMusic = new FlxSound();
			@:privateAccess if (pauseMusic._sound == null)
				pauseMusic.loadEmbedded(Paths.music("floweynew_yellow"));

			pauseMusic.volume = 0;
			pauseMusic.play(true, FlxG.random.int(0, Std.int(pauseMusic.length * 0.5)));
			pauseMusic.looped = true;
			FlxG.sound.defaultMusicGroup.add(pauseMusic);

			return pauseMusic;
		}, true);
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed);

		if (pauseMusic != null && pauseMusic.playing && pauseMusic.volume < 0.5)
			pauseMusic.volume += 0.01 * elapsed;

		if (!closing) {
			final callback = pauseItems[curSel].getParameters()[1];
			if (callback != null && Controls.ACCEPT)
			{
				FlxG.sound.play(AssetHelper.getAsset('audio/sfx/snd_confirm', SOUND));
				callback();
			}
			
			if (Controls.BACK)
				resumeSong();

			if (pauseGroup.members.length > 1)
				if (Controls.LEFT_P || Controls.RIGHT_P)
					updateSelection(Controls.LEFT_P ? -1 : 1);
		}

		//DEBUG
		/*
		if(FlxG.keys.pressed.LEFT)
			this.camera.x -= 5;
		if(FlxG.keys.pressed.RIGHT)
			this.camera.x += 5;
		if(FlxG.keys.pressed.UP)
			this.camera.y -= 5;
		if(FlxG.keys.pressed.DOWN)
			this.camera.y += 5;
		*/
	}

	function abruptOptionSelect(?sound:String)
	{
		if (pauseMusic != null) pauseMusic.stop();

		if(sound != null)
			FlxG.sound.play(AssetHelper.getAsset('audio/sfx/$sound', SOUND));
	}

	function tweenInItems()
	{
		//pause letters
		for (i in 0...pauseLetters.members.length)
		{
			FlxTween.tween(pauseLetters.members[i], {
				x: 300 + _letters[i][1], 
				y: 40 + _letters[i][2]
			}, 0.5 + (0.07 * i), {
				ease: FlxEase.elasticOut
			});
		}

		//pause art
		art.tween({x: 0, alpha: 1.0}, 0.5, {ease: FlxEase.expoOut});

		//option gradient backdrop
		FlxTween.tween(optionShadow, {y: FlxG.height - optionShadow.height}, 0.5, {
			ease: FlxEase.expoOut
		});

		//tiled background
		FlxTween.tween(bg, {alpha: 0.5}, 0.5, {
			ease: FlxEase.expoIn,
			onComplete: function(twn:FlxTween) {
				closing = false;
				updateSelection(0);
			}
		});

		//info
		pauseInfo.tweenElements(true);
		FlxTween.tween(pauseInfo, {alpha: 1.0}, 0.5, {ease: FlxEase.expoOut});
	}

	function tweenOutItems()
	{
		//options
		for (i in 0...pauseGroup.members.length)
			FlxTween.tween(pauseGroup.members[i], {alpha: 0, y: (i == curSel ? pauseGroup.members[i].y : FlxG.height)},
			0.25, 
			{ease: (i == curSel ? FlxEase.expoIn : FlxEase.expoOut)});

		//pause art
		art.tween({x: -art.width, alpha: 0.0}, 0.5, {ease: FlxEase.expoOut});

		//any text stuff
		forEachOfType(ForeverText, function(text:ForeverText):Void {
			FlxTween.tween(text, {alpha: 0}, 0.05, {ease: FlxEase.expoIn});
		});

		//option gradient backdrop
		FlxTween.tween(optionShadow, {y: FlxG.height}, 0.5, {
			ease: FlxEase.expoOut
		});

		//pause letters
		for (i in 0...pauseLetters.members.length)
		{
			FlxTween.tween(pauseLetters.members[i], {
				y: -pauseLetters.members[i].height,
				alpha: 0.0
			}, 0.3 + (0.05 * i), {
				ease: FlxEase.elasticOut
			});
		}

		//background
		FlxTween.tween(bg, {alpha: 0}, 0.5, {
			ease: FlxEase.expoIn,
			onComplete: function(twn:FlxTween) FlxG.state.closeSubState()
		});

		//info
		pauseInfo.tweenElements(false);
		FlxTween.tween(pauseInfo, {alpha: 0.0}, 0.5, {ease: FlxEase.expoOut});
	}

	function resumeSong():Void {
		closing = true;
		if (pauseMusic != null) pauseMusic.stop();
		tweenOutItems();
	}

	function updateSelection(newSel:Int = 0):Void {
		curSel = FlxMath.wrap(curSel + newSel, 0, pauseGroup.members.length - 1);

		if (newSel != 0)
			FlxG.sound.play(AssetHelper.getAsset('audio/sfx/snd_mainmenu_select', SOUND));

		for (i in 0...pauseGroup.members.length) {
			final option:PauseOption = pauseGroup.members[i];
			option.toggleSelect(i == curSel);
		}
	}

	function reloadMenu(list:Array<PauseButton>):Void {
		while (pauseGroup.members.length != 0)
			pauseGroup.members.pop().destroy();

		for (i in 0...list.length) {
			final option:PauseOption = new PauseOption(0, 0, list[i].getParameters()[0]);
			var newX:Int = Std.int(FlxMath.lerp(FlxG.width * (1 - optionSpacingPercent), (FlxG.width * optionSpacingPercent) - option.sprite.width,
				list.length <= 1 ? 0.5 : (i / (list.length - 1))));
			var newY:Int = Std.int(FlxG.height - option.sprite.height - 10);
			option.updateDefaultPosition(newX, newY);
			option.setPosition(newX, FlxG.height);
			option.alpha = 1.0;
			pauseGroup.add(option);
		}

		//letters stuff
		while (pauseLetters.members.length != 0)
			pauseLetters.members.pop().destroy();

		for (i in 0..._letters.length)
		{
			final let:PauseLetter = new PauseLetter(0, 0, _letters[i][0]);
			let.scale.set(0.67, 0.67);
			let.updateHitbox();
			pauseLetters.add(let);
		}
		
		pauseItems = list;
	}
}

class PauseOption extends FlxSpriteGroup
{
	public var sprite:FlxSprite;
	public var highlight:FlxSprite;

	public var hiliHeight:Int = 100;
	public var optionNumber:Int;
	private var lastDeselectPos:FlxPoint;
	public var selected:Bool = false;

	public function new(x:Float, y:Float, image:String)
	{
		//acceptable inputs for image: resume, retry, exit
		super(x, y);

		sprite = new FlxSprite(0, 0);
		sprite.loadGraphic(Paths.image('pause/$image'));
		sprite.frames = Paths.getSparrowAtlas('pause/$image');

		sprite.animation.addByPrefix('default', 'default', 0, true);
		sprite.animation.addByPrefix('selected', 'selected', 0, true);
		sprite.animation.play('default');

		sprite.antialiasing = false;
		sprite.scale.set(0.6, 0.6);
		sprite.updateHitbox();
		add(sprite);
		
		highlight = FlxGradient.createGradientFlxSprite(Std.int(sprite.width), hiliHeight, [0x0, 0xFFFFFF00]);
		highlight.alpha = 0.8;
		highlight.x = sprite.x;
		highlight.y = highlight.y;
		add(highlight);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}

	public function updatePosition(x:Int, y:Int)
	{
		setPosition(x, y);
		if(!selected)
			updateDefaultPosition(Std.int(sprite.x), Std.int(sprite.y));
	}

	public function updateDefaultPosition(x:Int, y:Int)
	{
		lastDeselectPos = new FlxPoint(x, y);
	}

	public function toggleSelect(isSelected:Bool = false)
	{
		selected = isSelected;
		if(selected)
		{
			sprite.animation.play('selected');
		}
		else
		{
			sprite.animation.play('default');
		}
		selectTween(selected);
	}

	function selectTween(selected:Bool)
	{
		FlxTween.cancelTweensOf(this);
		FlxTween.cancelTweensOf(highlight);
		var twnTime:Float = 0.4;
		FlxTween.tween(this, {y: lastDeselectPos.y + (selected ? -50 : 0)}, twnTime, {
			ease: FlxEase.expoOut
		});
		
		FlxTween.tween(highlight, {y: (selected ? FlxG.height - hiliHeight : FlxG.height)}, twnTime, {
			ease: FlxEase.expoOut
		});
	}
}

class PauseLetter extends FlxSprite
{
	//just to save some hassle and extra code with the PAUSED sprites
	//imported from spazkid's tirade mod

	var sineWavePos:Float = 0;
	var sineStrength:Float = 0.05;
	var sineSpeed:Float = 1.0;

	public var hover:Bool = true;

	public function new(x:Int, y:Int, character:String)
	{
		super(x, y);

		this.loadGraphic(Paths.image('pause/$character'));
		//roughly +- pi randomization
		sineWavePos += FlxG.random.float(-3, 3);
		//randomization in the animations
		sineSpeed = FlxG.random.float(0.95, 1.05);
		sineStrength = FlxG.random.float(0.03, 0.07);
	}

	override function update(elapsed:Float)
	{
		//im not sure but i think elapsed is the number of milis since the last frame update
		//so sineWavePos should increase by 1 every second (but fractionally each frame)
		if(hover)
		{
			sineWavePos += (elapsed / 1);
			this.y += (Math.sin(sineWavePos * sineSpeed) * sineStrength);
		}
		
	}
}

class PauseDescription extends FlxSpriteGroup
{
	public var box:Window;
	public var title:FlxText;
	public var titleColor:FlxColor;
	public var stats:FlxText;
	public var desc:FlxText;

	private final _defaultFont:String = 'pixela-extreme';

	public function new(x:Int, y:Int, pauseData:String)
	{
		super(x, y);

		box = new Window(0, 0, 420, 320);
		add(box);

		title = new FlxText(0, 0, box.width - 40);
		stats = new FlxText(0, 0, box.width - 40);
		desc = new FlxText(0, 0, box.width - 40);

		updateInfo(pauseData);

		title.setFormat(AssetHelper.getAsset(_defaultFont, FONT), 64, titleColor, LEFT);
		stats.setFormat(AssetHelper.getAsset("mars-needs-cunnilingus", FONT), 18, FlxColor.WHITE, LEFT);
		desc.setFormat(AssetHelper.getAsset(_defaultFont, FONT), 32, FlxColor.WHITE, LEFT);

		title.updateHitbox();
		stats.updateHitbox();
		desc.updateHitbox();

		positionElements(x, y);

		add(title);
		add(stats);
		add(desc);
	}

	public function updateInfo(pauseData:String, ?folder:String)
	{
		var data = AssetHelper.parseAsset('data/pause/${folder != null ? (folder + "/") : ''}${pauseData}', YAML);
		if(data != null)
		{
			title.text = data.title;
			stats.text = "AT 1 DF 0"; //fix this later
			desc.text = data.description;
			titleColor = FlxColor.fromInt(data.titleColor);
		}
		else //dummy
		{
			title.text = "N/A";
			stats.text = "AT - DF -";
			desc.text = "No data object provided";
			titleColor = 0xAAAAAAAA;
		}
	}

	public function positionElements(x:Int, y:Int)
	{
		box.setPosition(x, y);

		title.x = x + 20;
		stats.x = x + 20;
		desc.x = x + 20;

		title.y = 0;
		stats.y = title.y + title.height;
		desc.y = stats.y + stats.height + 10;
	}

	public function tweenElements(tweenIn:Bool)
	{
		var shit:Array<FlxSprite> = new Array<FlxSprite>();
		shit.push(box);
		shit.push(title);
		shit.push(stats);
		shit.push(desc);

		tweenIn ? twnIn(this.members) : twnOut(this.members);
	}

	private function twnIn(objArr:Array<FlxSprite>)
	{
		for(i in 0...objArr.length)
		{
			FlxTween.cancelTweensOf(objArr[i]);
			FlxTween.tween(objArr[i], {x: (i == 0 ? 500 : 520)}, 0.5 + (0.1 * i), {
				ease: FlxEase.expoOut
			});
		}
	}

	private function twnOut(objArr:Array<FlxSprite>)
	{
		for(i in 0...objArr.length)
		{
			FlxTween.cancelTweensOf(objArr[i]);
			FlxTween.tween(objArr[i], {x: FlxG.width + (i == 0 ? 0 : 20)}, 0.5 + (0.1 * i), {
				ease: FlxEase.expoOut
			});
		}
	}

}
