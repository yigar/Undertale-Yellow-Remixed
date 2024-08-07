package forever;

import flixel.FlxG;
import flixel.input.FlxInput;
import flixel.input.keyboard.FlxKey;
import forever.Settings;

/**
 * Handles the base of the controls class, has helper functions to detect
 * whether a key has been just pressed, is being held, or was released.
**/
class ControlsManager {
	/**
	 * Default Contorls, used when booting the game for the first time
	 * or resetting your key settings
	**/
	public static final defaultControls:Map<String, Array<FlxKey>> = [
		"left" => [A],
		"down" => [S],
		"up" => [W],
		"right" => [D],
		//
		"ui_left" => [A],
		"ui_down" => [S],
		"ui_up" => [W],
		"ui_right" => [D],
		//
		"accept" => [ENTER, SPACE],
		"back" => [BACKSPACE, ESCAPE],
		"pause" => [ENTER, ESCAPE],
		"reset" => [R],
		//
		"ut_accept" => [J],
		"ut_cancel" => [K],
		"ut_menu" => [L],
	];

	/** Your own Custom Controls. **/
	//i'm presuming this is NOT for mods. this just stores the player's set controls.
	public var myControls:Map<String, Array<FlxKey>> = [];

	/**
	 * Ordered Array with the order of which the control options should appear in the menu.
	 *
	 * Arrays of a single item are treated as a category,
	 * items with blank names don't get added in the menu.
	**/
	public var keyOrder:Array<Array<String>> = [
        ["NOTES"],
		["left", "down", "up", "right"],
		["USER INTERFACE"],
		["ui_left", "ui_down", "ui_up", "ui_right", "accept", "back", "pause"],
		["DEBUG"],
		["reset"],
    ];

	/** Indicator set if you are playing with a controller. **/
	public var gamepadMode:Bool = false;

	/** Creates a new instance of the Controls Base Class. **/
	public function new():Void {
		myControls = cloneControlsMap();
		gamepadMode = false;
	}

	public function setControlsFromMap(newCtrls:Map<String, Array<FlxKey>>):Map<String, Array<FlxKey>>
	{
		for (key => value in newCtrls)
			myControls[key] = value.copy();
		return myControls;
	}

	/** Checks if a Control Key is held. **/
	public inline function pressed(act:String):Bool
		return keyChecker(act, PRESSED);

	/** Checks if a Control Key is released. **/
	public inline function released(act:String):Bool
		return keyChecker(act, RELEASED);

	/** Checks if a Control Key has just been pressed. **/
	public inline function justPressed(act:String):Bool
		return keyChecker(act, JUST_PRESSED);

	/** Checks if a Control Key has just been released. **/
	public inline function justReleased(act:String):Bool
		return keyChecker(act, JUST_RELEASED);

	// -- HELPERS -- //

	@:dox(hide) @:noCompletion private function keyChecker(act:String, state:FlxInputState):Bool {
		for (key in myControls.get(act))
			if (FlxG.keys.checkStatus(key, state))
				return true;
		return false;
	}

	@:dox(hide) @:noCompletion private static function cloneControlsMap():Map<String, Array<FlxKey>> {
		var newMap:Map<String, Array<FlxKey>> = [];
		for (key => value in defaultControls)
			newMap[key] = value.copy();
		return newMap;
	}

	@:dox(hide) public static inline function getKeyFromAction(action:String, id:Int = 0):FlxKey {
		var key:Int = -1;
		for (name => keysArray in Controls.current.myControls) {
			if (action == name && keysArray != null)
				key = keysArray[id];
		}
		return key;
	}

	@:dox(hide) public static inline function getActionFromKey(key:FlxKey):String {
		var action:String = null;
		for (name => keysArray in Controls.current.myControls) {
			for (k in keysArray)
				if (k == key)
					action = name;
		}
		return action;
	}

	@:dox(hide) public inline function flushControls() {
		Settings.savedControls = Controls.current.myControls;
		Settings.flush();
	}

	//public inline function loadControlsFromSave()
}
