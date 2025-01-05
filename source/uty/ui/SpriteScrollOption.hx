package uty.ui;

import flixel.group.FlxSpriteGroup.FlxSpriteGroup;
import forever.display.ForeverSprite;
import uty.objects.UTText;

//a UI object that displays a sprite, text, and tracks a selection
//for use in firstboot menu/options menu and major story choices
class SpriteScrollOption extends FlxSpriteGroup
{
    public var sprite:ForeverSprite;
    public var text:UTText;
    public var arrowL:ForeverSprite;
    public var arrowR:ForeverSprite;

    public var textOnTop:Bool = false;
    public var arrowsByText:Bool = false; //wraps the arrows around the text if true, instead of the sprite

    private var options:Array<String>;
    public var selection:Int = 0;

    public function new(?x:Int = 0, ?y:Int = 0, ?graphic:String, ?textOnTop:Bool = false, ?resize:Float)
    {
        super(x, y);
        options = new Array<String>();
        this.textOnTop = textOnTop;

        sprite = new ForeverSprite(x, y, graphic);
        if(graphic != null)
            setAtlas(graphic);

        sprite.antialiasing = false;
        if(resize != null)
            sprite.scale.set(resize, resize);
        sprite.updateHitbox();

        text = new UTText(0, 0, 0, "");

        arrowL = new ForeverSprite(0, 0, 'images/menu/selArrowL');
        arrowR = new ForeverSprite(0, 0, 'images/menu/selArrowR');
        arrowL.scale.set(3.0, 3.0);
        arrowR.scale.set(3.0, 3.0);
        arrowL.updateHitbox();
        arrowR.updateHitbox();
        arrowL.antialiasing = false;
        arrowR.antialiasing = false;

        add(sprite);
        add(text);
        add(arrowL);
        add(arrowR);
    }

    public function position(x:Int = 0, y:Int = 0, ?center:Bool = false)
    {
        sprite.updateHitbox();
        sprite.x = x - (center ? Std.int(sprite.width * 0.5) : 0);
        sprite.y = y - (center ? Std.int(sprite.height * 0.5) : 0);

        //shitty line of code, but this basically centers the text, above or below the sprite depending on the var
        positionText(Std.int(sprite.x + (sprite.width * 0.5) - (text.width * 0.5)), //x
            Std.int(textOnTop ? sprite.y - 30 : sprite.y + sprite.height + 30)); //y

        positionArrows();
    }

    //breaking the position function up for customizability like in the memorylogmenu
    public function positionText(x:Int = 0, y:Int = 0, ?center:Bool = false)
    {
        text.x = x - (center ? text.width * 0.5 : 0);
        text.y = y;
        text.updateHitbox();
    }

    public function positionArrows()
    {
        var obj = (arrowsByText ? text : sprite);
        var poopY = obj.y + Std.int((obj.height * 0.5) - (arrowL.height * 0.5));
        arrowL.setPosition(obj.x - 30 - arrowL.width, poopY);
        arrowR.setPosition(obj.x + Std.int(obj.width) + 30, poopY);
    }

    public function setAtlas(atlas:String)
    {
        sprite.frames = AssetHelper.getAsset(atlas, ATLAS);
    }

    public function addOptionArray(ary:Array<String>)
    {
        for(i in 0...ary.length)
        {
            options.push(ary[i]);
        }
        //update the text so it's not blank before choosing something
        text.text = options[selection];
    }

    public function displayArrows(yes:Bool = true){
        arrowL.visible = yes;
        arrowR.visible = yes;
    }

    public function displayText(yes:Bool = true){
        text.visible = yes;
    }

    public function addAtlasAnims(names:Array<String>)
    {
        for(i in 0...names.length)
        {
            sprite.addAtlasAnim('option${i}', names[i], 0, false);
        }
        
        sprite.playAnim('option${selection}');
        sprite.updateHitbox();
    }

    public function setTextColor(color:FlxColor = FlxColor.WHITE)
    {
        arrowL.color = color;
        arrowR.color = color;
        text.color = color;
    }

    public function addToSelection(add:Int){
        updateSelection(selection + add);
    }

    public function updateSelection(sel:Int)
    {
        selection = sel;
        if(options.length == 0) 
            return;
        if(selection < 0) 
            selection = options.length - 1;
        if(selection > options.length - 1) 
            selection = 0;

        sprite.playAnim('option${selection}');
        sprite.updateHitbox();
        text.text = options[selection];
        text.updateHitbox();
    }

    public function getSelectionNum():Int
    {
        return selection;
    }
}