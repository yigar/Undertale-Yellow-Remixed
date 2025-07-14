package funkin.objects.play;

import forever.display.ForeverSprite;
import flixel.group.FlxGroup;
import flixel.FlxObject;
import uty.objects.UTText;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;

class GradeSprite extends FlxTypedGroup<FlxObject>
{
    //objects
    public var letter:ForeverSprite;
    public var sign:ForeverSprite;
    public var accText:UTText;

    //state
    public var fc:Bool = true;

    //variables
    public var centerPoint:FlxPoint;

    //finals
    public final _validLetters:Array<String> = ["s", "a", "b", "c", "d"];
    public final _validsigns:Array<String> = ["+", "-"];

    public function new(?x:Float = 0, ?y:Float = 0)
    {
        super();
        loadSprite();
        loadText();
        updateHitboxes();
        add(letter);
        add(sign);
        add(accText);
        position(x, y);

        toggleVisible(false);
    }

    private function loadSprite()
    {
        letter = new ForeverSprite();
        letter.loadGraphic(Paths.image('ui/undertale/grade'));
        letter.frames = Paths.getSparrowAtlas('ui/undertale/grade');
        letter.addAtlasAnim("s", "s", 0, false);
        letter.addAtlasAnim("a", "a", 0, false);
        letter.addAtlasAnim("b", "b", 0, false);
        letter.addAtlasAnim("c", "c", 0, false);
        letter.addAtlasAnim("d", "d", 0, false);

        sign = new ForeverSprite();
        sign.loadGraphic(Paths.image('ui/undertale/grade'));
        sign.frames = Paths.getSparrowAtlas('ui/undertale/grade');
        sign.addAtlasAnim("plus", "plus", 0, false);
        sign.addAtlasAnim("minus", "minus", 0, false);
    }

    private function loadText()
    {
        accText = new UTText(0, 0, 0, "");
        accText.setFont(MARS, 20);
        accText.setBorder();
    }

    private function position(?x:Float = 0, y:Float = 0)
    {
        if(centerPoint == null) 
            centerPoint = new FlxPoint(x, y);

        letter.setPosition(centerPoint.x - (letter.width / 2), centerPoint.y - (letter.height / 2));
        sign.setPosition(letter.x + letter.width + 25, letter.y + 10);
        accText.setPosition(centerPoint.x - (letter.width / 2), centerPoint.y + (letter.height));
    }

    private function updateAccPosition()
    {
        accText.updateHitbox();
        accText.setPosition(centerPoint.x - (letter.width / 2), centerPoint.y + (letter.height));
    }

    public function updateGrade(accuracy:Float, rank:String)
    {
        accText.text = accuracy + "%";

        //immediate n/a check
        if(rank == "N/A" || rank == "" || rank == " ")
        {
            toggleVisible(false);
            return;
        }

        toggleVisible(true);

        var ltr:String = rank.charAt(0);
        if(_validLetters.contains(ltr.toLowerCase()) || _validLetters.contains(ltr.toUpperCase()))
        {
            letter.animation.play(ltr.toLowerCase());
        }
        else
        {
            //invalid rank
            toggleVisible(false);
            return;
        }

        var op:String = rank.charAt(1);
        switch(op)
        {
            case "+":
            {
                sign.visible = true;
                sign.animation.play("plus");
            }
                
            case "-":
            {
                sign.visible = true;
                sign.animation.play("minus");
            }
            default:
                sign.visible = false;
        }
    }

    public function toggleVisible(vis:Bool)
    {
        letter.visible = vis;
        sign.visible = vis;
        accText.visible = vis;
    }

    public function updateHUDPreset(data:Dynamic)
    {
        //trace('BEFORE: ${letter.width}');
        letter.alpha = data.letter.alpha;
        letter.scale.set(data.letter.scale, data.letter.scale);
        sign.alpha = data.sign.alpha;
        sign.scale.set(data.sign.scale, data.sign.scale);
        accText.alpha = data.accuracy.alpha;
        accText.scale.set(data.accuracy.scale, data.accuracy.scale);
        accText.setBorder(data.accuracy.border);

        //trace('AFTER: ${letter.width}');

        position();
        letter.x += data.letter.xOffset;
        letter.y += data.letter.yOffset;
        sign.x += data.sign.xOffset;
        sign.y += data.sign.yOffset;
        accText.x += data.accuracy.xOffset;
        accText.y += data.accuracy.yOffset;
        //updateHitboxes();
    }

    private inline function updateHitboxes() {
        letter.updateHitbox();
        sign.updateHitbox();
        accText.updateHitbox();
    }
}