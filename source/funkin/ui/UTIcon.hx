package funkin.ui;

import flixel.graphics.FlxGraphic;
import flixel.math.FlxMath;
import forever.display.ForeverSprite;
import funkin.states.PlayState;
import haxe.ds.IntMap;
import funkin.components.Timings;

class UTIcon extends ChildSprite {
	public var initialWidth:Float = 0.0;
	public var initialHeight:Float = 0.0;

	public var isPlayer:Bool = false;
	public var character(default, set):String;

	// -- CUSTOMIZATION -- //
	public var autoPosition:Bool = false;
	public var autoBop:Bool = true;
	public var comboReq:Int = 50; //enemy's losing anim will play once combo is this big
	public var lowHealthPercent:Float = 20; //player's losing anim will play below this %
	public var resize:Float = 3.0;

	public function new(character:String = "clover", isPlayer:Bool = false, parent:FlxSprite = null):Void {
		super();

		this.isPlayer = isPlayer;
		this.character = character;
		if (parent != null) {
			this.parent = parent;
			this.autoPosition = false;
		}
	}

	function set_character(newChar:String):String {
		var char:String = newChar;
		if (!Tools.fileExists(AssetHelper.getPath('images/icons/${char}', IMAGE)))
			char = "clover";

		if (character != char) {
			var file:FlxGraphic = AssetHelper.getAsset('images/icons/${char}', IMAGE);
			var frm = AssetHelper.getAsset('images/icons/${char}', ATLAS);

			loadGraphic(file);
			if(frm != null)
			{
				this.frames = frm;
				animation.addByPrefix('transition', 'transition', 4, true); //for getting its frame length
				animation.addByPrefix('default', 'transition', 4, true);
				animation.appendByPrefix('default', 'default');
				animation.addByPrefix('lose', 'transition', 4, true);
				animation.appendByPrefix('lose', 'lose');
				animation.play('default');
				animation.curAnim.loopPoint = animation.getByName('transition').numFrames;
			}
				
			initialWidth = width;
			initialHeight = height;

			antialiasing = false; //!char.endsWith("-pixel");
			character = char;
		}

		return char;
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed);

		var hp:HealthBar = PlayState.current != null ? PlayState.current.playField.healthBar : null;
		if (hp == null) return;

		if (autoPosition == true) {
			var iconOffset:Int = 25;
			if (!isPlayer) iconOffset = cast(width - iconOffset);
			x = (hp.bar.x + (hp.bar.width * (1 - hp.bar.percent / 100))) - iconOffset;
		}

		if (autoBop == true && scale.x != resize) {
			final weight:Float = 1.0 - 1.0 / Math.exp(5.0 * elapsed);
			scale.set(FlxMath.lerp(scale.x, resize, weight), FlxMath.lerp(scale.y, resize, weight));
			// updateHitbox();
			offset.y = 0;
		}

		updateAnim(hp.bar.percent, Timings.combo);
	}

	public function updateAnim(hpPercent:Float, combo:Int)
	{
		if(isPlayer)
		{
			if(hpPercent < lowHealthPercent)
				transAnim('lose');
			else
				transAnim('default');
		}
		else
		{
			if(hpPercent >= 100 && combo >= comboReq)
				transAnim('lose');
			else
				transAnim('default');
		}
	}

	public function transAnim(anim:String)
	{
		if(animation.name == anim)
			return;
		else {
			animation.play(anim);
			animation.curAnim.loopPoint = animation.getByName('transition').numFrames;
		}
	}

	public dynamic function doBump(beat:Int):Void {
		if (autoBop != true) return;
		scale.set(1.08 * resize, 1.08 * resize);
		// updateHitbox();
	}
}
