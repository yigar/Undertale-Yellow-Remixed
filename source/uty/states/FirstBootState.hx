package uty.states;

import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxSpriteGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import forever.display.ForeverSprite;
import funkin.states.base.FNFState;
import funkin.states.menus.TitleScreen;
import uty.objects.UTText;
import uty.states.menus.SaveFileMenu;
import uty.ui.SpriteScrollOption;
import flixel.FlxSprite;
import flixel.input.FlxInput;
import flixel.input.keyboard.FlxKey;
import forever.ControlsManager;


enum abstract MenuState(Int) to Int{
    var OVERWORLD = 0;
    var FUNKIN = 1;
    var CONFIRM = 2;
}

//will only load on a fresh install of the game.
//full disclosure: this is coded pretty fucking badly, so adding more to this state might be annoying
//but that's probably okay because this state is meant to be very brief
class FirstBootState extends FNFState
{
    public var owOption:SpriteScrollOption;
    public var fnfOption:SpriteScrollOption;
    public var header:UTText;
    public var footer:UTText;

    var owChoice:Int;
    var fnfChoice:Int;
    public var state:MenuState;

    public var bg:FlxSprite;
    public var black:FlxSprite;

    public var ctrlEnabled:Bool = true;

    override function create()
    {
        //if this isn't the first time opening the game, skip this and immediately go to title
        FlxG.save.bind('meta', 'yigar/UTYRemixed');
        if (FlxG.save.data.firstBoot == false)
        {
            proceedToTitle();
            return;
        }

        state = FirstBootState.MenuState.OVERWORLD;

        add(bg = new FlxSprite().makeSolid(FlxG.width, FlxG.height, 0xFF000000));
        
        header = new UTText(0, 0, 0, '');
        footer = new UTText(0, 0, 0, '');
        footer.setFont(PIXELA, 20, 0xFF666666);
        add(header);
        add(footer);

        owOption = new SpriteScrollOption(0, 0, 'images/menu/firstBoot/overworld');
        owOption.addAtlasAnims(['WASD', 'arrows']);
        owOption.addOptionArray(['WASD Movement', 'Classic']);
        add(owOption);

        fnfOption = new SpriteScrollOption(0, 0, 'images/menu/firstBoot/funkin');
        fnfOption.addAtlasAnims(['one-handed_left', 'one-handed_right', 'two-handed']);
        fnfOption.addOptionArray(['Left Hand', 'Right Hand', 'Two Hands']);
        add(fnfOption);

        owOption.visible = false;
        fnfOption.visible = false;
        
        //last    
        add(black = new FlxSprite().makeSolid(FlxG.width, FlxG.height, 0xFF000000));

        //sorta janky roundabout way of doing a fade-in without reusing code
        state = FUNKIN;
        optionFadeOut(true);
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if(ctrlEnabled)
            controlCheck();
    }

    public function controlCheck()
    {
        //best to hard-code the key presses in this state
        var selInput:Int = 0;
        if(FlxG.keys.justPressed.A || FlxG.keys.justPressed.LEFT)
        {
            selInput += -1;
        }
        if(FlxG.keys.justPressed.D || FlxG.keys.justPressed.RIGHT)
        {
            selInput += 1;
        }
        if(selInput != 0)
        {
            FlxG.sound.play(AssetHelper.getAsset('audio/sfx/snd_mainmenu_select', SOUND));
            //switch-case is cringe but i dont care
            switch (state)
            {
                case OVERWORLD:{
                    owOption.addToSelection(-1);
                    owOption.position(Std.int(FlxG.width * 0.5), Std.int(FlxG.height * 0.5), true);
                }
                case FUNKIN:{
                    fnfOption.addToSelection(-1);
                    fnfOption.position(Std.int(FlxG.width * 0.5), Std.int(FlxG.height * 0.5), true);
                }
                case CONFIRM: {}
            }
        }

        //confirm
        if(FlxG.keys.justPressed.Z || FlxG.keys.justPressed.J || FlxG.keys.justPressed.ENTER)
        {
            FlxG.sound.play(AssetHelper.getAsset('audio/sfx/snd_confirm', SOUND));
            switch(state)
            {
                case OVERWORLD:{
                    owChoice = owOption.getSelectionNum();
                    optionFadeOut();
                }
                case FUNKIN:{
                    fnfChoice = fnfOption.getSelectionNum();
                    optionFadeOut();
                }
                case CONFIRM: {}
            }
        }
        //back
        if(FlxG.keys.justPressed.X || FlxG.keys.justPressed.K || FlxG.keys.justPressed.BACKSPACE)
        {
            switch(state)
            {
                case OVERWORLD: {}
                case FUNKIN:{
                    optionFadeOut(true);
                }
                case CONFIRM: {}
            }
        }
    }

    public function owOptionFunc()
    {
        state = FirstBootState.MenuState.OVERWORLD;

        header.text = "Choose a control preset for\nexploring the Underground.";
        footer.text = "Scroll with A and D keys, and confirm with ENTER.";
        header.updateHitbox();
        footer.updateHitbox();

        header.setPosition(Std.int((FlxG.width * 0.5) - (header.width * 0.5)), 70);
        footer.setPosition(Std.int((FlxG.width * 0.5) - (footer.width * 0.5)), FlxG.height - 100);
        owOption.position(Std.int(FlxG.width * 0.5), Std.int(FlxG.height * 0.5), true);
        owOption.visible = true;
        fnfOption.visible = false;

        optionFadeIn();
    }

    public function fnfOptionFunc()
    {
        state = FirstBootState.MenuState.FUNKIN;

        header.text = "Choose a control preset for hitting notes.";
        footer.text = "Don't worry. Controls can be customized later.";
        header.updateHitbox();
        footer.updateHitbox();

        header.setPosition(Std.int((FlxG.width * 0.5) - (header.width * 0.5)), 70);
        footer.setPosition(Std.int((FlxG.width * 0.5) - (footer.width * 0.5)), FlxG.height - 100);
        fnfOption.position(Std.int(FlxG.width * 0.5), Std.int(FlxG.height * 0.5), true);
        fnfOption.visible = true;
        owOption.visible = false;

        optionFadeIn();
    }

    function funcFromState(back:Bool = false)
    {
        var newSt = state + (back ? -1 : 1);
        if(newSt < 0) return;

        switch (newSt)
        {
            case OVERWORLD:
                owOptionFunc();
            case FUNKIN:
                fnfOptionFunc();
            case CONFIRM:
                updateSettingsAndContinue();
        }
    }

    function optionFadeOut(back:Bool = false)
    {
        ctrlEnabled = false;
        black.alpha = 0.0;
        FlxTween.tween(black, {alpha: 1.0}, 0.5, {onComplete: function(twn){
            funcFromState(back);
        }});
    }

    function optionFadeIn()
    {
        FlxTween.tween(black, {alpha: 0.0}, 0.5, {onComplete: function(twn){
            ctrlEnabled = true;
        }});
    }

    function updateSettingsAndContinue()
    {
        switch (owChoice)
        {
            case 0:
                Controls.current.setControlsFromMap(ControlPresets.owPreset_wasd);
            case 1:
                Controls.current.setControlsFromMap(ControlPresets.owPreset_arrow);
        }

        switch (fnfChoice)
        {
            case 0:
                Controls.current.setControlsFromMap(ControlPresets.fnfPreset_left);
            case 1:
                Controls.current.setControlsFromMap(ControlPresets.fnfPreset_right);
            case 2:
                Controls.current.setControlsFromMap(ControlPresets.fnfPreset_twohand);
        }
        Controls.current.flushControls();
        proceedToTitle();
    }

    function proceedToTitle()
    {
        FlxG.switchState(new TitleScreen());
    }
}

class ControlPresets
{
    public static final owPreset_arrow:Map<String, Array<FlxKey>> = [
		"ui_left" => [LEFT],
		"ui_down" => [DOWN],
		"ui_up" => [UP],
		"ui_right" => [RIGHT],
		//
		"ut_accept" => [Z],
		"ut_cancel" => [X],
		"ut_menu" => [C],
	];

    public static final owPreset_wasd:Map<String, Array<FlxKey>> = [
		"ui_left" => [A],
		"ui_down" => [S],
		"ui_up" => [W],
		"ui_right" => [D],
		//
		"ut_accept" => [J],
		"ut_cancel" => [K],
		"ut_menu" => [L],
	];

    public static final fnfPreset_left:Map<String, Array<FlxKey>> = [
		"left" => [A],
		"down" => [S],
		"up" => [W],
		"right" => [D],
	];

    public static final fnfPreset_right:Map<String, Array<FlxKey>> = [
		"left" => [LEFT],
		"down" => [DOWN],
		"up" => [UP],
		"right" => [RIGHT],
	];

    public static final fnfPreset_twohand:Map<String, Array<FlxKey>> = [
		"left" => [A],
		"down" => [S],
		"up" => [K],
		"right" => [L],
	];
}