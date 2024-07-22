package uty.objects;

import flixel.group.FlxGroup;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import forever.display.ForeverSprite;
import uty.components.NarratedText;
import openfl.text.TextFormat;
import uty.components.DialogueParser;
import uty.ui.Window;
import uty.objects.UTText;

/*
    dialogue box for use in the overworld state.
    controls a narratedText object and feeds it lines of dialogue from a specific dialogue group.
    also has an optional portrait sprite with animated emotions and speech.
*/

class DialogueBox extends FlxTypedGroup<FlxObject>
{
    //visual assets
    public var boxBackground:FlxSprite;
    public var boxBorder:FlxSprite;
    public var window:Window;
    var borderThickness:Int = 9;
    public var portrait:ForeverSprite;
    public var narratedText:NarratedText;

    var dialogueParser:DialogueParser;
    var dialogueGroup:DialogueGroup;
    var currentLineData:DialogueLine; //for storing the current line's dialogue info
    var currentLine:Int = -1;
    var currentCharacter:String = "NONE"; //for tracking when to update the sprite (character as in like a person, not a letter lol)

    public var dialogueCompleted:Bool = false;
    var portraitVisible = true;

    public var defaultX:Int;
    public var defaultY:Int;

    //finals for formatting & shit
    private final _defaultTextFormat:TextFormat;
    private final _defaultFont:String = "pixela-extreme";
    private final _defaultFontSize:Int = 38;
    private final _defaultLetterSpacing:Float = 3.0;
    private final _defaultLeading:Int = 10;
    private final _defaultSound:String = "default";
    private final _portraitScale:Int = 3; //i believe these get resized a little bit bigger than other sprites
    public final _boxWidth:Int = 860;
    public final _boxHeight:Int = 225;
    public final _verticalOffset:Int = 30; //how far from the top/bottom of the screen this thing is by default

    //we're going to start a dialogue......
    public function new(x:Int, y:Int, dialogueGroup:DialogueGroup)
    {
        super();

        //stuff to help with the font format looking accurate to undertale
        _defaultTextFormat = new TextFormat(
            AssetHelper.getAsset(_defaultFont, FONT), 
            _defaultFontSize, 
            0xFFFFFFFF
        );
        _defaultTextFormat.leading = _defaultLeading;
        _defaultTextFormat.letterSpacing = _defaultLetterSpacing;
        _defaultTextFormat.bullet = true;

        window = new Window(0, 0, _boxWidth, _boxHeight, borderThickness);

        //remember to convert the portrait sprites to xml
        portrait = new ForeverSprite();
        portrait.antialiasing = false;
        
        narratedText = new NarratedText(100, 30, _boxWidth - 200, "", _defaultFont, _defaultFontSize);
        narratedText.setFont(PIXELA, _defaultFontSize, FlxColor.WHITE, LEFT, _defaultLetterSpacing);
        add(window);
        add(portrait);
        add(narratedText);

        setScreenPosition(x, y);

        //information like character icon sprite, voice tone, font, and the dialogue itself are read from these files
        //though font is really only relevant with sans and papyrus, who aren't in this game, so...
        //probably a good thing to add if the field exists, otherwise just make it pixela extreme.

        this.dialogueGroup = dialogueGroup;

        //dialogueGroup = cast(AssetHelper.parseAsset('funkin/data/dialogue/${folder}/${dialogueFile}', JSON));

        setDefaultNarrateTextFormat();
    }

    public function setDefaultNarrateTextFormat()
    {
        var defaultFormat:TextFormat = _defaultTextFormat;

        narratedText.textField.defaultTextFormat = defaultFormat;
        //narratedText.addFormat(_defaultTextFormat);
    }

    public function presetScreenPos(pos:String)
    {
        var newX = Std.int((FlxG.width / 2) - (window.width / 2));
        var newY;
        if(pos == "bottom" || pos == "BOTTOM")
            newY = Std.int(FlxG.height - (window.height) - _verticalOffset);
        else if(pos == "top" || pos == "TOP")
            newY = _verticalOffset;
        else
            newY = 0;

        setScreenPosition(newX, newY);
    }

    public function setScreenPosition(x:Int, y:Int)
    {
        defaultX = x;
        defaultY = y;
        updateScreenPosition();
    }

    public function updateScreenPosition()
    {
        window.setPosition(defaultX, defaultY);

        portrait.setPosition(
            Std.int(window.x + 40),
            Std.int(window.y + (window.height / 2) - (portrait.height / 2)));

        narratedText.x = window.x + 100 + portrait.width;
        narratedText.y = window.y + 20;
        //this should make it so the text always breaks 100 pixels before the end of the dialogue box
        narratedText.fieldWidth = (window.x + window.width - narratedText.x - 50); 
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);
        //not efficient to do this every frame rather than every letter but should work for now
        talkAnimationCheck(narratedText.curLetterString);
        //if all the lines are done reading, we're ready to destroy this
        if(currentLine >= dialogueGroup.dialogue.length - 1 && narratedText.narrating == false) 
            {
                dialogueCompleted = true;
            }
    }

    public function nextDialogueLine()
    {
        //update what line we're on, first line is 0
        currentLine += 1;

        //clear current dialogue
        narratedText.text = "";
        
        if(Reflect.hasField(dialogueGroup, "dialogue")) //if this dialogueGroup is a valid dialogue json
        {
            if(currentLine < dialogueGroup.dialogue.length) //if we're not past the last dialogue line
            {
                //use the json info to set up the next narration and portrait sprite
                currentLineData = cast dialogueGroup.dialogue[currentLine];
                trace('CURRENT LINE DATA: $currentLineData');

                //CHARACTER SPRITE + SOUND SETUP
                if(currentLineData.character != null) //character dialogue
                {
                    narratedText.setSound(currentLineData.character);
                    updatePortrait(currentLineData.character, currentLineData.emotion);
                }
                else //regular non-character narration
                {
                    narratedText.setSound(_defaultSound);
                    updatePortrait("NONE");
                }

                //FONT SET
                if(currentLineData.font != null)
                {
                    narratedText.setFont(currentLineData.font, _defaultFontSize, FlxColor.WHITE, LEFT, _defaultLetterSpacing);
                }
                else 
                    narratedText.setFont(_defaultFont, _defaultFontSize, FlxColor.WHITE, LEFT, _defaultLetterSpacing);

                //SCREEN AND SPRITE POSITIONING
                updateScreenPosition();

                //TEXT SET
                if(currentLineData.string != null)
                    narratedText.setText(currentLineData.string);

                //IMPORTANT: this function needs to be called AFTER screenPosition stuff and font/sprite update
                //otherwise the newline is based on the dialogue line BEFORE this one
                narratedText.autoNewline();
                //should be all set up to start narrating now
                narratedText.narrate();
            }
            else //we're done with the last line and need to close the box now
            {
                //this flags this textbox to be destroyed
                dialogueCompleted = true;
            }
        }
    }

    public function updatePortrait(?character:String = "NONE", ?emotion:String = "default")
    {
        if(character != "NONE" && character == currentCharacter) //if the new character is the same as the current, no need to update the character
        {
            //just update animation stuff instead
            updateEmotion(emotion);
        }
        else if(
            portraitVisible ||
            character == null || 
            character == "NONE" || 
            character == "EMPTY" ||
            character == "none" || 
            character == "empty") //if there's no character
        {
            portrait.destroy();

            portrait = new ForeverSprite();
            currentCharacter = "NONE";
        }
        else //if the new character is different
        {
            trace(character);
            portrait.destroy();

            portrait = new ForeverSprite();
            portrait.loadGraphic(AssetHelper.getAsset('images/dialogue/portraits/${character}'), IMAGE);
            portrait.frames = (AssetHelper.getAsset('images/dialogue/portraits/${character}', ATLAS_SPARROW));
            portrait.setGraphicSize(Std.int(portrait.width * _portraitScale));
            portrait.updateHitbox();
            portrait.antialiasing = false;
            portrait.setPosition(
                Std.int(window.x + 40),
                Std.int(window.y + (window.height / 2)));
            add(portrait);
            portrait.visible = portraitVisible;
            currentCharacter = character;

            updateEmotion(emotion);
        }
    }

    public function updateEmotion(?emotion:String = "default")
    {
        if(currentCharacter != null && currentCharacter != "NONE") //if this is an actual character
        {
            if(portrait.animation.exists(emotion)) //if this animation has already been added to the sprite
            {
                if(portrait.animation.name != emotion) // and if the current animation isn't the same as this one
                {
                    portrait.animation.play(emotion); //play the loaded animation
                }
                else //if it's the same animation anyways
                {
                    return;
                }
                    
            }
            else //if the animation has not been added yet
            {
                portrait.addAtlasAnim(emotion, emotion, 4, true);
                //failsafe: if it failed to add the animation, try to set it to "default" (most xmls have a "default" animation)
                if(!portrait.animation.exists(emotion))
                {
                    portrait.addAtlasAnim("default", "default", 4, true);
                    //extra failsafe: look for "smile" instead
                    if(!portrait.animation.exists("default"))
                    {
                        portrait.addAtlasAnim("smile", "smile", 4, true);
                        portrait.animation.play("smile");
                        //if this STILL fails, then fix your fucking shit
                    }
                    else
                    {
                        portrait.animation.play("default");
                    }
                }
                else
                {
                    portrait.animation.play(emotion);
                }
            }
        }
    }

    public function talkAnimationCheck(letter:String)
    {
        //plays the animation when narrateText's current letter is non-punctuation.
        //if the current letter is punctuation, like an ellipsis or a comma, the portrait will 
        //set to its closed mouth frame and pause.
        if(!portrait.exists || portrait == null || (portrait.animation.getNameList().length <= 0))
        {
            return;
        }

        if(narratedText.narrating && !narratedText._punctuationCharacters.contains(letter)) //if narrating, and this letter is a letter
        {
            if(portrait.animation.paused)
            {
                portrait.animation.resume();
                portrait.animation.curAnim.curFrame = 1; //mfw bandaid
            }
        }
        else //either the narration stopped, or we're in punctuation chars
        {
            if(!portrait.animation.paused)
            {
                //pauses talking and closes the mouth. be sure the closed mouth sprite actually IS on frame 0 though.
                portrait.animation.pause();
                portrait.animation.curAnim.curFrame = 0;
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

    public function togglePortrait(?toggle:Bool)
    {
        portraitVisible = toggle ?? !portraitVisible;
        portrait.visible = false;
    }
}