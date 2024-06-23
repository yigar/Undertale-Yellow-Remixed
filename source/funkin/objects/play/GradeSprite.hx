package funkin.objects.play;

import forever.display.ForeverSprite;
import flixel.group.FlxGroup;
import flixel.FlxObject;
import flixel.text.FlxText;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;

class GradeSprite extends FlxTypedGroup<FlxObject>
{
    //objects
    public var letter:ForeverSprite;
    public var sign:ForeverSprite;
    public var accText:FlxText;

    //state
    public var fc:Bool = true;

    //variables
    public var centerPoint:FlxPoint;

    //finals
    public final _accFont:String = "mars-needs-cunnilingus";
    public final _validLetters:Array<String> = ["s", "a", "b", "c", "d"];
    public final _validsigns:Array<String> = ["+", "-"];

    public function new(?x:Float = 0, ?y:Float = 0)
    {
        super();
        loadSprite();
        loadText();
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

        letter.scale.set(0.80, 0.80);
        sign.scale.set(0.80, 0.80);
    }

    private function loadText()
    {
        accText = new FlxText(0, 0, 0, "");
        accText.setFormat(Paths.font(_accFont), 24, 0xFFFFFF, CENTER, OUTLINE, FlxColor.BLACK);
        accText.setBorderStyle(OUTLINE, FlxColor.BLACK, 4);
        accText.antialiasing = false;
    }

    private function position(?x:Float, y:Float)
    {
        if(x != null) centerPoint = new FlxPoint(x, y);

        letter.setPosition(centerPoint.x - (letter.width / 2), centerPoint.y - (letter.height / 2));
        sign.setPosition(letter.x + letter.width + 25, letter.y + 10);
        accText.setPosition(centerPoint.x - (accText.width / 2) + 130, centerPoint.y);
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
}