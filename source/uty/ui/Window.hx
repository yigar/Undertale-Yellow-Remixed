package uty.ui;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import uty.objects.UTText;
import flixel.math.FlxMath;

enum MenuOption {
    MenuOption(text:String, call:Void->Void, enabled:Bool);
}

class Window extends FlxSpriteGroup
{
    //this is gonna be quick and shitty for now

    public var border:FlxSprite;
    public var center:FlxSprite;

    public var borderClr:FlxColor = FlxColor.WHITE;
    public var centerClr:FlxColor = FlxColor.BLACK;

    public var menu:WindowMenu;
    public var textItems:Array<UTText> = [];
    public var sub:Window;



    public function new(x:Int, y:Int, width:Int, height:Int, ?borderThickness:Int = 8)
    {
        super(x, y);
        createBox(width, height, borderThickness);
    }

    public function createBox(width:Int, height:Int, ?borderThickness:Int = 8)
    {
        border = new FlxSprite().makeGraphic(width, height, borderClr);
        center = new FlxSprite().makeGraphic(width - (borderThickness * 2), height - (borderThickness * 2), centerClr);
        center.x += borderThickness;
        center.y += borderThickness;

        border.antialiasing = false;
        center.antialiasing = false;

        add(border);
        add(center);
    }

    public function setTransparent(tp:Bool = true)
    {
        border.alpha = tp ? 0.0 : 1.0;
        center.alpha = tp ? 0.0 : 1.0;
    }

    public function controlSubMenu(?b:Bool)
    {
        if(menu != null && sub != null && sub.menu != null)
        {
            menu.toggleControl(!b);
            sub.menu.toggleControl(b);
        }
    }

    public function addSubWindow(x:Int, y:Int, width:Int, height:Int, ?borderThickness:Int)
    {
        sub = new Window(x, y, width, height, borderThickness);
        this.add(sub);
    }

    public function createMenu(x:Float, y:Float, items:Array<MenuOption>, ?perRow:Int = 1, ?rowSpacing:Int, ?columnSpacing:Int)
    {
        menu = new WindowMenu(x, y, items, perRow, rowSpacing, columnSpacing);
        this.add(menu);
    }

    public function addText(x:Float, y:Float, fieldWidth:Float = 0, text:String = "", ?font:UTFont = PIXELA, 
        ?size:Int= 38, ?border:Bool = true, ?spacing:Float = 1, ?leading:Int, ?color:FlxColor = 0xFFFFFFFF)
    {
        var text:UTText = new UTText(Std.int(x), Std.int(y), fieldWidth, text);
        text.setFont(font, size, color, CENTER, spacing, leading);
        if(border)
            text.setBorder();
        textItems.push(text);
        this.add(text);
    }

    //checks the control inputs of this menu and any sub-menus
    public function controlCheck()
    {
        if(menu != null)
            menu.controlCheck();
        if(sub != null)
            sub.controlCheck();
    }
}

class WindowMenu extends FlxSpriteGroup
{
    public var soul:FlxSprite;
    public var list:Array<UTText> = [];
    public var funcMap:Array<Void->Void> = [];
    public var enabledList:Array<Bool> = [];

    //private; i don't want this being changed directly
    private var controlEnabled:Bool = true;

    public var selection:Int = 0;
    public var perRow:Int = 1;
    private var rowSpacing:Int = 50;
    private var columnSpacing:Int = 50;

    public function new(x:Float, y:Float, items:Array<MenuOption>, ?perRow:Int, ?rowSpacing:Int, ?columnSpacing:Int)
    {
        super();

        this.perRow = perRow;
        if(this.perRow < 1) perRow = 1;

        if(rowSpacing != null) 
            this.rowSpacing = rowSpacing;
        if(columnSpacing != null) 
            this.columnSpacing = columnSpacing;
 
        //text setup
        for(i in 0...items.length)
        {
            var item:UTText = new UTText(
                Std.int(x + ((i % perRow) * columnSpacing)), 
                Std.int(y + (Math.floor(i / perRow) * rowSpacing)), 0,
                items[i].getParameters()[0]);
            item.setFont(PIXELA, 38, items[i].getParameters()[2] ? 0xFFFFFFFF : 0xFF888888);
            item.setBorder();
            //center stuff later
            list.push(item);
            enabledList.push(items[i].getParameters()[2]);
            add(item);
            funcMap.push(items[i].getParameters()[1]);
        }
        //soul setup
        soul = new FlxSprite();
        soul.loadGraphic(AssetHelper.getAsset('images/ui/soul', IMAGE));
        soul.setGraphicSize(Std.int(soul.width * 3));
        soul.updateHitbox();
        soul.antialiasing = false;
        add(soul);

        updateSelection(0, false);
        toggleControl(true);
    }

    public function controlCheck()
    {
        if(!controlEnabled) return;

        if (Controls.UI_UP_P && !Controls.UI_DOWN_P) //up
            selectFromDirection("up");
        if (Controls.UI_DOWN_P && !Controls.UI_UP_P) //down
            selectFromDirection("down");
        if (Controls.UI_LEFT_P && !Controls.UI_RIGHT_P) //left
            selectFromDirection("left");
        if (Controls.UI_RIGHT_P && !Controls.UI_LEFT_P) //right
            selectFromDirection("right");

        if (Controls.UT_ACCEPT_P)
        {

        }
    }

    public function callSelectedFunction():Bool
    {
        if(funcMap[selection] != null) 
        {
            if(enabledList[selection])
            {
                FlxG.sound.play(AssetHelper.getAsset('audio/sfx/snd_confirm', SOUND));
                funcMap[selection]();
                return true;
            }
            else
            {
                FlxG.sound.play(AssetHelper.getAsset('audio/sfx/snd_fail', SOUND));
                return false;
            }
        }
        return false;
    }

    public function updateSelection(select:Int, ?sound:Bool = true)
    {
        if(!controlEnabled) return;
        if(select < 0 || select >= list.length) select = 0; //failsafe; any invalid number will result in 0

        selection = select;

        soul.x = list[select].x - (soul.width) - 10;
        soul.y = list[select].y + (list[select].height * 0.5) - (soul.height * 0.5);
        if(sound) //lazy band-aid for sub-menus
            FlxG.sound.play(AssetHelper.getAsset('audio/sfx/snd_mainmenu_select', SOUND));
    }

    public function selectFromDirection(direction:String)
    {
        var newSel:Int = selection;
        var selRowIndex:Int = Math.floor(selection / perRow);
        var selColIndex:Int = selection % perRow;

        //poopy switch case
        switch (direction)
        {
            case "left":
            {
                if(perRow == 1) return;

                newSel -= 1;
                if(selRowIndex != Math.floor(newSel / perRow)) //if we otherwise would go to the next row
                    newSel = (perRow * selRowIndex) + perRow - 1; //go to the right-most column in this row
            }
            case "right":
            {
                if(perRow == 1) return;

                newSel += 1;
                if(selRowIndex != Math.floor(newSel / perRow))
                    newSel = perRow * selRowIndex; //go to the left-most column in this row
            }
            case "down":
            {
                newSel += perRow;
                if(newSel >= list.length)
                {
                    newSel = selColIndex; //go to the top-most row in this column
                }
            }
            case "up":
            {
                newSel -= perRow;
                if(newSel < 0)
                {
                    newSel = (list.length - perRow) + selColIndex; //go to the bottom-most row in this column
                }
            }
        }

        updateSelection(newSel);
    }

    public function centerOptions()
    {
        for(item in list)
        {
            item.updateHitbox();
            item.x -= (item.width * 0.5);
        }
        updateSelection(selection, false); //repositions the soul
    }

    public function toggleControl(?on:Bool)
    {
        controlEnabled = on ?? !controlEnabled;
        soul.visible = controlEnabled;
    }

    public function isControlEnabled():Bool
    {
        return controlEnabled;
    }
}