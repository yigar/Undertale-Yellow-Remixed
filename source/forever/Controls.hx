package forever;

@:build(forever.macros.ControlsMacro.build())
/**
 * Controls Class, stores key shortcuts
 *
 * If you want to add new keys, or modify the backend,
 * please go into `ControlsManager`
**/
class Controls {
	/** The global instance of the Base Controls class. **/
	public static var current:ControlsManager;

	/**
	 * to have a shortcut to your key, simply create a function here for it
	 * to access your shortcut, use the expression `Controls.YOURCONTROL`
	**/
	// -- COMMON ACTIONS -- //
	@:justPressed(accept) function ACCEPT() {}

	@:justPressed(back) function BACK() {}

	@:justPressed(pause) function PAUSE() {}

	@:justPressed(reset) function RESET() {}

	@:pressed(reset) function RESET_HELD() {}

	// -- SINGLE PRESS -- //

	@:justPressed(left) function LEFT_P() {}

	@:justPressed(down) function DOWN_P() {}

	@:justPressed(up) function UP_P() {}

	@:justPressed(right) function RIGHT_P() {}

	@:justPressed(ui_left) function UI_LEFT_P() {}

	@:justPressed(ui_down) function UI_DOWN_P() {}

	@:justPressed(ui_up) function UI_UP_P() {}

	@:justPressed(ui_right) function UI_RIGHT_P() {}

	@:justPressed(ut_accept) function UT_ACCEPT_P() {}

	@:justPressed(ut_cancel) function UT_CANCEL_P() {}

	@:justPressed(ut_menu) function UT_MENU_P() {}

	// -- HOLDING -- //

	@:pressed(left) function LEFT() {}

	@:pressed(down) function DOWN() {}

	@:pressed(up) function UP() {}

	@:pressed(right) function RIGHT() {}

	@:pressed(ui_left) function UI_LEFT() {}

	@:pressed(ui_down) function UI_DOWN() {}

	@:pressed(ui_up) function UI_UP() {}

	@:pressed(ui_right) function UI_RIGHT() {}

	@:pressed(ut_accept) function UT_ACCEPT() {}

	@:pressed(ut_cancel) function UT_CANCEL() {}

	@:pressed(ut_menu) function UT_MENU() {}
}
