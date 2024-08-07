package uty.components;

import flixel.FlxSprite;
import flixel.FlxObject;
import uty.objects.UTText;
import forever.display.ForeverSprite;
import forever.display.RecycledSpriteGroup;
import openfl.media.Sound;
import flixel.sound.FlxSound;
import flixel.system.FlxAssets;
import flixel.util.FlxColor;
import openfl.text.TextFormat;
import openfl.text.TextField;

/*
    a component for text that reads itself out over time.
    currently designed with the dialogue box in mind, but should be abstract enough to apply to other things, as well.
    functionalities: starting, skipping to the end, slowing on punctuation, alterable speed, text tone sounds.
    thanks to the poopshitters mod for reference code.
*/

class NarratedText extends UTText
{
    public var finalText:String = ""; //the text that will eventually be read out
    public var curLetterInt:Int = 0;
    public var curLetterString:String = " ";

    var delay:Float = 0.033; //not the setter
    var punctuationDelay:Float = 0.3; //delay for punctuation characters
    var clearDelay:Float = 0.02;

    var currentDelay:Float = 0.0; //how long to wait for the next letter. based off the previous letter.

    public var narrating:Bool = false;
    public var finished:Bool = false;
    public var allowContinue:Bool = true; //if true, you can press the confirm key to go to the next line if the narration is done
    public var allowSkip:Bool = true; //if false, you cannot fast read this line and must wait for it to read out. for important lines.
    public var automated:Bool = false; //if true, it will finish on a timer. use with dialogue interruptions, etc. and allowSkip = false
    public var length:Int = 0;

    var updateTimer:Float = 0;
    var lastSoundTimer:Float = 0; //tracks how long it was since the last text tone was played, for an audio tapering function

    var narrateSoundAsset:FlxSoundAsset;
    var narrateSound:FlxSound;

    //formats seem to be useful because you can apply them to specific portions of a text field.
    //if you wanted to make a single word red for example (genocides)
    //but i think I also have to use them for proper leading and spacing

    public final _ignoreCharacters:Array<String> = ["`", "~", "*", "(", ")", "-", "_", "=", "+", "{", "}", "[", "]", '"', "'", "\\", "\n", "\t", "|", "<", ">", "/", "^", " ", ""];
	public final _punctuationCharacters:Array<String> = [".", ",", "!", "?", ":", ";"];
    public final _defaultDelay:Float = 0.033; //set this one. the delay in undertale yellow is one letter per frame.

    /* general construction will probably look like this:
            var shid = new NarratedText(x, y, dialogueBox.width, "", "pixela-extreme");
            shid.setText({the text document});
            shid.setSound({whoever's voice tone from the document});
            shid.narrate();
    */

    public function new(x:Int, y:Int, width:Int, ?text:String = '', ?font:UTFont = PIXELA, ?size:Int = 38, ?color:FlxColor = FlxColor.WHITE)
    {
        super(x, y, width, text, size);
        //ORDER IS IMPORTANT
        setFont(font, size, color, LEFT);
        setText(text);
        
        antialiasing = false;
        scrollFactor.set();

        narrateSound = new FlxSound();
    }

    public function setText(text:String)
    {
        finalText = text;
        length = finalText.length;
    }

    public function narrate(?delayOverride:Float)
    {
        if(delayOverride != null)
            delay = delayOverride;
        else
            delay = _defaultDelay;

        narrating = true;
        finished = false;
    }

    public function setSound(sound:String)
    {
        //personal note: FlxSoundAsset is a dynamic "OneOfThree" that's typically an openFL sound.
        narrateSoundAsset = AssetHelper.getAsset('audio/dialogue/${sound}', SOUND);
        narrateSound.loadEmbedded(AssetHelper.getAsset('audio/dialogue/${sound}', SOUND));
    }

    private function returnVolumeFromDelay(?intensity:Float = 1.0):Float
    {
        //returns the volume of the text tone based on how cut-off the sound is
        //ideally prevents very obnoxious sounding text tones
        //set the intensity to reduce how much it reduces the sound by
        //all of this might be unnecessary though, i just wrote this because of my nitpicks with how the sound is turning out
        if(narrateSound != null)
        {
            var vol = ((lastSoundTimer * 1000) / narrateSound.length);
            vol = (1.0 - ((1.0 - vol) * intensity));
            if(vol > 1.0) 
                vol = 1.0;
            return vol;
        }
        else 
            return 1.0;
    }

    public function playSound()
    {
        FlxG.sound.play(narrateSoundAsset);
        lastSoundTimer = 0.0;
    }

    public function addCurrentLetter():String
    {
        var nextLetter:String = finalText.charAt(curLetterInt);
        text += nextLetter;
        curLetterString = nextLetter; //this is mainly for talking animations in the dialogue box

        if(!_punctuationCharacters.contains(nextLetter) && !_ignoreCharacters.contains(nextLetter))
            playSound();

        if(curLetterInt >= length) //if this is the last letter
        {
            curLetterInt = 0;
            finishNarration();
        }
        else
            curLetterInt++;

        return nextLetter;
    }

    override public function update(elapsed:Float)
    {
        if(narrating)
        {
            updateTimer += elapsed;
            lastSoundTimer += elapsed; //however big this gets doesn't really matter as long as we set it back to zero
            if(updateTimer >= currentDelay)
            {
                var addedLetter:String = addCurrentLetter();
                setNextDelayFromLetter(addedLetter);
                updateTimer = 0;
            }
        }
    }

    function setNextDelayFromLetter(letter:String):String
    {
        if(_ignoreCharacters.contains(letter))
        {
            currentDelay = delay;
            return "IGNORE";
        }
        else if(_punctuationCharacters.contains(letter))
        {
            currentDelay = punctuationDelay;
            return "PUNCTUATION";
        }
        else
        {
            currentDelay = delay;
            return "NORMAL";
        }
    }

    public function finishNarration()
    {
        narrating = false;
        finished = true;
        text = finalText;
        allowContinue = true;
    }

    public function skipLine()
    {
        curLetterInt = 0;
        finishNarration();
    }

    public function autoNewline()
    {
        //auto-inserts line breaks so the text doesn't wrap weird when narrating and i don't have to manually type \n every time
        //this needs to happen after the portrait sprite/font size are updated
        this.visible = false;
        this.text = finalText;
        
        var lineLengths:Array<Int> = new Array<Int>();
        while(this.textField.getLineLength(lineLengths.length) > 0) //getLineLength will be 0 on an empty or nonexistent line
        {
            lineLengths.push(this.textField.getLineLength(lineLengths.length));
        }

        //now add \n to the text based on the line lengths
        var addLength:Int = 0;
        for(i in 0...lineLengths.length - 1) //i is the line index
        {
            addLength += lineLengths[i];
            finalText = finalText.substring(0, addLength) + "\n" + finalText.substring(addLength);
            addLength += 1; //accounting for the \n adding an extra character
        }

        this.text = "";
        this.visible = true;
    }

    public function pause()
    {
        narrating = false;
        allowContinue = false;
        allowSkip = false;
    }

    public function resume()
    {
        if(!finished)
        {
            narrating = true;
            allowSkip = true; //maybe need to change this, probably fine for now
        }
        else
        {
            allowContinue = true;
        }
    }

}