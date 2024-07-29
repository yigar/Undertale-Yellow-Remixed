package uty.objects;

import uty.objects.DialogueObject;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import forever.display.ForeverSprite;
import uty.components.NarratedText;
import openfl.text.TextFormat;
import uty.components.DialogueParser;
import uty.ui.Window;
import uty.objects.UTText;

class DialogueBox extends DialogueObject
{
    public var curCharacter:String = "NONE";
    public var portraitVisible:Bool = true;

    private final _portraitScale:Int = 3; //i believe these get resized a little bit bigger than other sprites
    public final _boxWidth:Int = 860;
    public final _boxHeight:Int = 225;
    public final _verticalOffset:Int = 30; //how far from the top/bottom of the screen this thing is by default

    public function new(x:Int, y:Int, dialogueGroup:DialogueGroup)
    {
        defaultSetup();

        var window:Window = new Window(0, 0, _boxWidth, _boxHeight);

        var portrait = new ForeverSprite();
        portrait.antialiasing = false;

        narratedText = new NarratedText(100, 30, _boxWidth - 200, "", _defaultFont, _defaultFontSize);
        super(x, y, dialogueGroup, portrait, window);

        setBoxOffset(0, 0);
        setCharOffset(40, Std.int((window.height * 0.5) - (portrait.height * 0.5)));
        setTextOffset(Std.int(100 + portrait.width), 20);
    }

    private function defaultSetup()
    {
        _defaultFont = PIXELA;
        _defaultFontSize = 38;
        _defaultAlign = LEFT;
        _defaultLetterSpacing = 3.0;
        _defaultLeading = 10;
        _defaultSound = "default";
    }

    override function updateCharSprite(?char:String = "NONE", ?anim:String = "default", ?frameRate:Int = 4)
    {
        if(char == null) char = "NONE";
        if(char != "NONE" && char == curCharacter)
        {
            super.updateCharSprite(char, anim, frameRate);
        }
        else if(
            !portraitVisible ||
            char == "NONE" || 
            char == "EMPTY" ||
            char == "none" || 
            char == "empty") //if there's no character
        {
            emptyCharSprite();
            updateTextWidth();
            curCharacter = "NONE";
        }
        else
        {
            setPortrait(char);
            updateTextWidth();
            super.updateCharSprite(char, anim, frameRate);
        }
    }

    public function emptyCharSprite()
    {
        charSprite.destroy();
        charSprite = new ForeverSprite();
        charSprite.createEmpty();
    }

    public function setPortrait(char:String)
    {
        charSprite.destroy();

        charSprite = new ForeverSprite();
        charSprite.loadGraphic(AssetHelper.getAsset('images/dialogue/portraits/${char}'), IMAGE);
        charSprite.frames = (AssetHelper.getAsset('images/dialogue/portraits/${char}', ATLAS_SPARROW));
        charSprite.setGraphicSize(Std.int(charSprite.width * _portraitScale));
        charSprite.updateHitbox();
        charSprite.antialiasing = false;
        setCharOffset(40, Std.int((boxSprites.height * 0.5) - (charSprite.height * 0.5)));
        add(charSprite);

        charSprite.visible = portraitVisible;
        curCharacter = char;
    }

    public function updateTextWidth()
    {
        setTextOffset(Std.int(100 + charSprite.width), 20);
        narratedText.fieldWidth = (_boxWidth - 200 - charSprite.width);
    }

    public function presetScreenPos(pos:String)
    {
        var newX = Std.int((FlxG.width / 2) - (boxSprites.width / 2));
        var newY;
        if(pos == "bottom" || pos == "BOTTOM")
            newY = Std.int(FlxG.height - (boxSprites.height) - _verticalOffset);
        else if(pos == "top" || pos == "TOP")
            newY = _verticalOffset;
        else
            newY = 0;

        setScreenPosition(newX, newY);
    }

    public inline function togglePortrait(?toggle:Bool)
    {
        portraitVisible = toggle ?? !portraitVisible;
        charSprite.visible = false;
    }
    
}
