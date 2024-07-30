package uty.objects;

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
import flixel.text.FlxText;
import flixel.util.FlxColor;

/*
    dialogue box for use in the overworld state.
    controls a narratedText object and feeds it lines of dialogue from a specific dialogue group.
    also has an optional portrait sprite with animated emotions and speech.
*/

class DialogueObject extends FlxTypedGroup<FlxObject>
{
    //visual assets
    public var boxSprites:FlxSpriteGroup; //the sprite(s) comprising the box/background behind the text.
    public var charSprite:ForeverSprite; //the sprite to manipulate emotion animations for.
    public var narratedText:NarratedText; //the text object to display.

    public var defaultX:Int;
    public var defaultY:Int;
    public var boxOffset:FlxPoint;
    public var charOffset:FlxPoint;
    public var textOffset:FlxPoint;

    //data
    var dialogueGroup:DialogueGroup;
    var curLineData:DialogueLine; //for storing the current line's dialogue info
    var curDiaLine:Int = -1;

    public var dialogueCompleted:Bool = false;
    public var controlBoxPos:Bool = true; //if false, box position will not be updated unless forced
    public var controlCharPos:Bool = true; //if false, char sprite position will not be updated unless forced

    //some vars for customizing the text formatting of child classes, in case you want that consistent.
    private var _defaultFont:UTFont = PIXELA;
    private var _defaultFontSize:Int = 38;
    private var _defaultColor:FlxColor;
    private var _defaultAlign:FlxTextAlign = LEFT;
    private var _defaultLetterSpacing:Float = 3.0;
    private var _defaultLeading:Int = 10;
    private var _defaultSound:String = "default";

    //we're going to start a dialogue......
    public function new(x:Int, y:Int, dialogueGroup:DialogueGroup, ?charSpr:ForeverSprite, ?boxGrp:FlxSpriteGroup)
    {
        super();

        addBoxSprites(boxGrp);
        addCharSprite(charSpr);

        //in case you wanna set it up differently in a child
        if(narratedText == null)
            narratedText = new NarratedText(0, 0, 0, "");
        narratedText.setFont(PIXELA); //temporary; manually set this yourself in the child class
        add(narratedText);

        setCharOffset(0, 0);
        setBoxOffset(0, 0);
        setTextOffset(0, 0);
        //i don't wanna update shit just yet
        defaultX = x;
        defaultY = y;

        //information like character icon sprite, voice tone, font, and the dialogue itself are read from these files
        //though font is really only relevant with sans and papyrus, who aren't in this game, so...
        //probably a good thing to add if the field exists, otherwise just make it pixela extreme.

        this.dialogueGroup = dialogueGroup;
    }

    public function resetDialogue()
    {
        curDiaLine = -1;
        dialogueCompleted = false;
    }

    public function setDialogueGroup(diaGrp:DialogueGroup)
    {
        resetDialogue();
        this.dialogueGroup = diaGrp;
    }

    public function defaultFontSetup(font:UTFont = PIXELA, size:Int = 38, color:FlxColor = FlxColor.WHITE,
        align:FlxTextAlign = LEFT, spacing:Float = 3.0, leading:Int = 10)
    {
        _defaultFont = font;
        _defaultFontSize = size;
        _defaultColor = color;
        _defaultAlign = align;
        _defaultLetterSpacing = spacing;
        _defaultLeading = leading;
        _defaultSound = "default";
    }

    //you have to set the sprite up in whatever child object or external state
    //this is so this object can manipulate regular sprites, like characters' heads
    public function addCharSprite(spr:ForeverSprite)
    {
        if(spr != null)
        {
            charSprite = spr;
            charSprite.antialiasing = false;
            add(charSprite);
        }
        else
            charSprite = new ForeverSprite();
    }

    public function addBoxSprites(grp:FlxSpriteGroup)
    {
        if(grp != null)
            {
                boxSprites = grp;
                add(boxSprites);
            }
            else
                boxSprites = new FlxSpriteGroup();
    }

    public inline function setCharOffset(x:Int, y:Int) {
        charOffset = new FlxPoint(x,y);
    }

    public inline function setBoxOffset(x:Int, y:Int) {
        boxOffset = new FlxPoint(x,y);
    }

    public inline function setTextOffset(x:Int, y:Int) {
        textOffset = new FlxPoint(x,y);
    }

    public function setScreenPosition(x:Int, y:Int)
    {
        defaultX = x;
        defaultY = y;
        updateScreenPosition();
    }

    public function updateScreenPosition(?txt:Bool = true, ?box:Bool, ?char:Bool)
    {
        if(txt && narratedText != null){
            narratedText.x = Std.int(defaultX + textOffset.x ?? 0);
            narratedText.y = Std.int(defaultY + textOffset.y ?? 0);
        }
        if((box ?? controlBoxPos) && boxSprites != null){
            boxSprites.x = Std.int(defaultX + boxOffset.x ?? 0);
            boxSprites.y = Std.int(defaultY + boxOffset.y ?? 0);
        }
        if((char ?? controlCharPos) && charSprite != null){
            charSprite.x = Std.int(defaultX + charOffset.x ?? 0);
            charSprite.y = Std.int(defaultY + charOffset.y ?? 0);
        }
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);
        //not efficient to do this every frame rather than every letter but should work for now
        talkAnimationCheck(narratedText.curLetterString);
        //if all the lines are done reading, we're ready to destroy this
        if(curDiaLine >= dialogueGroup.dialogue.length - 1 && narratedText.finished) 
        {
            dialogueCompleted = true;
        }
    }

    public function nextDialogueLine(?force:Bool = false)
    {
        if(!(force || (!narratedText.narrating && narratedText.allowContinue)))
            return;

        //update what line we're on, first line is 0
        curDiaLine += 1;
        //clear current dialogue
        narratedText.text = "";
        
        if(Reflect.hasField(dialogueGroup, "dialogue")) //if this dialogueGroup is a valid dialogue json
        {
            if(curDiaLine < dialogueGroup.dialogue.length) //if we're not past the last dialogue line
            {
                //use the json info to set up the next narration and portrait sprite
                curLineData = cast dialogueGroup.dialogue[curDiaLine];

                //CHARACTER SPRITE + SOUND SETUP
                narratedText.setSound(curLineData.character ?? _defaultSound);
                updateCharSprite(curLineData.character, curLineData.emotion, 3);

                //FONT SET
                narratedText.setFont(curLineData.font ?? _defaultFont, _defaultFontSize, 
                    _defaultColor, _defaultAlign, _defaultLetterSpacing, _defaultLeading);

                //SCREEN AND SPRITE POSITIONING
                updateScreenPosition();

                //TEXT SET
                if(curLineData.string != null)
                    narratedText.setText(curLineData.string);

                //IMPORTANT: this function needs to be called AFTER screenPosition stuff and font/sprite update
                //otherwise the newline is based on the dialogue line BEFORE this one
                narratedText.autoNewline();
                //should be all set up to start narrating now
                narratedText.narrate();
            }
            else //we're done with the last line and need to close the box now
            {
                dialogueCompleted = true; //this flags this textbox to be destroyed
                //shouldn't this close out of stuff? maybe just do that in the state i guess
            }
        }
    }

    //this is meant to be overrided for children that replace the sprite
    public function updateCharSprite(?char:String = "NONE", ?anim:String = "default", ?frameRate:Int = 3)
    {
        updateCharAnim(anim ?? "default", frameRate);
    }

    public function updateCharAnim(?anim:String = "default", ?frameRate:Int = 3)
    {
        if(charSprite != null)
        {
            if(charSprite.animation.exists(anim)) //if this animation has already been added to the sprite
            {
                if(charSprite.animation.name != anim) // re-play prevention
                {
                    charSprite.animation.play(anim);
                }
                else
                    return;
            }
            else //if the animation has not been added yet
            {
                charSprite.addAtlasAnim(anim, anim, frameRate, true);

                //failsafes. if anim is invalid, instead attempt to play a default one.
                if(!charSprite.animation.exists(anim))
                {
                    charSprite.addAtlasAnim("default", "default", frameRate, true);
                    if(!charSprite.animation.exists("default"))
                    {
                        charSprite.addAtlasAnim("smile", "smile", frameRate, true);
                        charSprite.animation.play("smile");
                        //if this STILL fails, then maybe fix your .xml file dumbass?
                    }
                    else
                    {
                        charSprite.animation.play("default");
                    }
                }
                else
                {
                    charSprite.animation.play(anim);
                }
            }
        }
        else
            trace("ERROR: cannot update character animation while char is null.");
    }

    public function talkAnimationCheck(letter:String)
    {
        //plays the animation when narrateText's current letter is non-punctuation.
        //if the current letter is punctuation, like an ellipsis or a comma, the portrait will 
        //set to its closed mouth frame and pause.
        if(!charSprite.exists || charSprite == null || (charSprite.animation.getNameList().length <= 0))
        {
            return;
        }

        if(narratedText.narrating && !narratedText._punctuationCharacters.contains(letter)) //if narrating, and this letter is a letter
        {
            if(charSprite.animation.paused)
            {
                charSprite.animation.resume();
                charSprite.animation.curAnim.curFrame = 1; //set to mouth open frame immediately
            }
        }
        else //either the narration stopped, or we're in punctuation chars
        {
            if(!charSprite.animation.paused)
            {
                //pauses talking and closes the mouth. be sure the closed mouth sprite actually IS on frame 0 though.
                charSprite.animation.pause();
                charSprite.animation.curAnim.curFrame = 0;
            }
        }
    }

    public function skipLine()
    {
        narratedText.skipLine();
    }

    public function pause()
    {
        narratedText.pause();
    }

    public function resume()
    {
        narratedText.resume();
    }
}