package flixel.system.ui;

#if FLX_SOUND_SYSTEM
import flixel.FlxG;
import flixel.system.FlxAssets;
import flixel.util.FlxColor;
import openfl.Lib;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
#if flash
import openfl.text.AntiAliasType;
import openfl.text.GridFitType;
#end

/**
 * The flixel sound tray, the little volume meter that pops down sometimes.
 * Accessed via `FlxG.game.soundTray` or `FlxG.sound.soundTray`.
 */
class FlxSoundTray extends Sprite
{
	/**
	 * Because reading any data from DisplayObject is insanely expensive in hxcpp, keep track of whether we need to update it or not.
	 */
	public var active:Bool;

	/**
	 * Helps us auto-hide the sound tray after a volume change.
	 */
	var _timer:Float;

	/**
	 * Helps display the volume bars on the sound tray.
	 */
	var _bars:Array<Bitmap>;

	/**
	 * How wide the fuqing health bar  is.
	 */
	var _width:Int = 120;

    var _height:Int = 16;

    var _outlineThickness:Int = 2;

	var _defaultScale:Float = 2.0;

	/**Whether or not changing the volume should make noise.**/
	public var silent:Bool = false;

	/**
	 * Sets up the "sound tray", the little volume meter that pops down sometimes.
	 */
	@:keep
	public function new()
	{
		super();

		visible = false;
		scaleX = _defaultScale;
		scaleY = _defaultScale;
		var tmp:Bitmap = new Bitmap(new BitmapData(_width + (_outlineThickness*2), _height + (_outlineThickness*2), true, 0xFF000000));
		screenCenter();
		addChild(tmp);

        //red background
        tmp = new Bitmap(new BitmapData(_width, _height, true, 0xFFBF0000));
        tmp.x += _outlineThickness;
        tmp.y += _outlineThickness;
        addChild(tmp);

		var text:TextField = new TextField();
		text.width = tmp.width;
		text.height = tmp.height;
		text.multiline = true;
		text.wordWrap = true;
		text.selectable = false;

		#if flash
		text.embedFonts = true;
		text.antiAliasType = AntiAliasType.NORMAL;
		text.gridFitType = GridFitType.PIXEL;
		#else
		#end
		var dtf:TextFormat = new TextFormat("assets/funkin/fonts/mars-needs-cunnilingus.ttf", 10, 0xffffff);
		dtf.align = TextFormatAlign.CENTER;
		text.defaultTextFormat = dtf;
		addChild(text);
		text.text = "VOLUME";
		text.y = 16;

		var bx:Int = _outlineThickness;
		var by:Int = _outlineThickness;
		_bars = new Array();

        var tenth = Std.int(_width / 10);

		for (i in 0...10)
		{
			tmp = new Bitmap(new BitmapData(tenth, _height, false, FlxColor.YELLOW));
			tmp.x = bx;
			tmp.y = by;
			addChild(tmp);
			_bars.push(tmp);
			bx += tenth;
		}

		y = -height;
		visible = false;
	}

	/**
	 * This function updates the soundtray object.
	 */
	public function update(MS:Float):Void
	{
		// Animate sound tray thing
		if (_timer > 0)
		{
			_timer -= (MS / 1000);
		}
		else if (y > -height)
		{
			y -= (MS / 1000) * height * 0.5;

			if (y <= -height)
			{
				visible = false;
				active = false;

				// Save sound preferences
				FlxG.save.bind('Settings', "yigar/UTYRemixed/forever");
				if (FlxG.save.isBound)
				{
					FlxG.save.data.mute = FlxG.sound.muted;
					FlxG.save.data.volume = FlxG.sound.volume;
					FlxG.save.flush();
					trace('sound settings saved.');
				}
			}
		}
	}

	/**
	 * Makes the little volume tray slide out.
	 *
	 * @param	up Whether the volume is increasing.
	 */
	public function show(up:Bool = false):Void
	{
		if (!silent)
		{
			var sound = AssetHelper.getAsset("audio/sfx/snd_mainmenu_select", SOUND);
			if (sound != null)
				FlxG.sound.load(sound).play();
		}

		_timer = 1;
		y = 0;
		visible = true;
		active = true;
		var globalVolume:Int = Math.round(FlxG.sound.volume * 10);

		if (FlxG.sound.muted)
		{
			globalVolume = 0;
		}

		for (i in 0..._bars.length)
		{
			if (i < globalVolume)
			{
				_bars[i].alpha = 1.0;
			}
			else
			{
				_bars[i].alpha = 0.0;
			}
		}
	}

	public function screenCenter():Void
	{
		scaleX = _defaultScale;
		scaleY = _defaultScale;

		x = (0.5 * (Lib.current.stage.stageWidth - _width * _defaultScale) - FlxG.game.x);
	}
}
#end