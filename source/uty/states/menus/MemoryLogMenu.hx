package uty.states.menus;

import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.sound.FlxSound;
import flixel.util.FlxColor;
import forever.display.ForeverSprite;
import forever.display.ForeverText;
import funkin.components.ChartLoader;
import funkin.components.Difficulty;
import funkin.components.Highscore;
import funkin.states.base.BaseMenuState;
import flixel.FlxSprite;
import uty.ui.ScrollSelectionList;
import uty.ui.SpriteScrollOption;
import uty.ui.Window;
import flixel.math.FlxMath;
import uty.objects.DialogueObject;
import uty.components.DialogueParser;

typedef CharacterOption = {
    name:String, //the display name of the character.
    icon:String, //the icon sprite to use.
    artData:String, //data object for sprite display shit
    dialogue:String, //name of the dialogue file to look for.
    songs:Array<String>, //the songs belonging to this character. this state checks if they're unlocked.
    secret:Bool //if this character is secret, they will not be added to the list at all when locked.
    //note: maybe create a 'funkinsave' object like the 'storysave' one
}

enum abstract MemoryMenuState(Int) to Int{
    var MAIN = 0;
    var SUB = 1;
    var SONG = 2;
    var INFO = 3;
}

//this is basically freeplay plus a gallery.

//note: create a sub-menu with individual songs for each character, displaying art and rank.

class MemoryLogMenu extends BaseMenuState
{
    public var bg:FlxSprite;
    public var characterList:ScrollSelectionList;
    public var title:ForeverSprite;
    public var star:ForeverSprite;
    public var optBattle:ForeverSprite;
    public var optInfo:ForeverSprite;
    public var window:Window;
    public var spBubble:ForeverSprite;

    public var floweyEmerge:ForeverSprite;
    public var flowey:FlxSpriteGroup;
    public var floweyHead:ForeverSprite;
    public var floweyStem:ForeverSprite;

    public var diaBubble:DialogueObject;

    public var charListData:Array<CharacterOption>;
    public var artDisplay:ArtDisplay;

    public var menuState:MemoryMenuState = MAIN;
    public var boxOptSel:Int = 0;
    private var parser:DialogueParser;

    public final spriteDir:String = 'images/menu/memory/';

    public final fullData:Array<CharacterOption> = [
        {
            name: "Flowey",
            icon: "flowey",
            artData: "flowey",
            dialogue: "flowey",
            songs: ["Flowey"],
            secret: false
        },
        {
            name: "Martlet",
            icon: "martlet",
            artData: "martlet",
            dialogue: "martlet",
            songs: ["Martlet"],
            secret: false
        }
    ];

    override function create()
    {
        charListData = new Array<CharacterOption>();
        parser = new DialogueParser();

        add(bg = new FlxSprite().makeSolid(FlxG.width, FlxG.height, 0xFF000000));

        characterList = new ScrollSelectionList(30, 180);
        add(characterList);

        setupSprites();

        artDisplay = new ArtDisplay(Std.int(window.center.x), Std.int(window.center.y), 
            Std.int(window.center.width), Std.int(window.center.height));
        add(artDisplay);

        //adds characters to characterList
        for (i in 0...fullData.length)
        {
            if(true) //check for unlocked in save later
            {
                characterList.addOption(fullData[i].name, '${spriteDir}icons/${fullData[i].icon}');
                charListData.push(fullData[i]);
            }
            else if(true) //check for if it's NOT secret
            {
                characterList.addOption('?????', '${spriteDir}icons/empty');
                charListData.push(fullData[i]);
            }
        }

        loadArt(charListData[characterList.changeSelection(0)].artData); //updates stuff

        add(spBubble);
    }

    private function setupSprites()
    {
        title = new ForeverSprite(0, 0, '${spriteDir}memLogTitle');
        title.frames = AssetHelper.getAsset('${spriteDir}memLogTitle', ATLAS);
        title.addAtlasAnim('boil', 'boil', 4, true);
        title.animation.play('boil');
        title.antialiasing = false;
        title.scale.set(3.0, 3.0);
        title.updateHitbox();

        star = new ForeverSprite(0, 0, '${spriteDir}saveStar');
        star.frames = AssetHelper.getAsset('${spriteDir}saveStar', ATLAS);
        star.addAtlasAnim('anim', 'anim', 8, true);
        star.animation.play('anim');
        star.antialiasing = false;
        star.scale.set(3.0, 3.0);
        star.updateHitbox();

        window = new Window(300, 140, 608, 458, 4);

        optBattle = new ForeverSprite(0, 0, '${spriteDir}option_battle');
        optBattle.frames = AssetHelper.getAsset('${spriteDir}option_battle', ATLAS);
        optBattle.addAtlasAnim('deselect', 'deselect', 0, true);
        optBattle.addAtlasAnim('select', 'select', 0, true);
        optBattle.animation.play('deselect');
        optBattle.antialiasing = false;
        optBattle.scale.set(3.0, 3.0);
        optBattle.updateHitbox();

        optInfo = new ForeverSprite(0, 0, '${spriteDir}option_info');
        optInfo.frames = AssetHelper.getAsset('${spriteDir}option_info', ATLAS);
        optInfo.addAtlasAnim('deselect', 'deselect', 0, true);
        optInfo.addAtlasAnim('select', 'select', 0, true);
        optInfo.animation.play('deselect');
        optInfo.antialiasing = false;
        optInfo.scale.set(3.0, 3.0);
        optInfo.updateHitbox();

        floweyEmerge = new ForeverSprite(0, 0, '${spriteDir}floweyEmerge');
        floweyEmerge.frames = AssetHelper.getAsset('${spriteDir}floweyEmerge', ATLAS);
        floweyEmerge.addAtlasAnim('emerge', 'emerge', 8, false);
        floweyEmerge.animation.play('emerge');
        floweyEmerge.antialiasing = false;
        floweyEmerge.scale.set(3.0, 3.0);
        floweyEmerge.updateHitbox();

        floweyHead = new ForeverSprite(0, 0, '${spriteDir}flowey_head');
        floweyHead.frames = AssetHelper.getAsset('${spriteDir}flowey_head', ATLAS);
        floweyHead.antialiasing = false;
        floweyHead.scale.set(3.0, 3.0);
        floweyHead.updateHitbox();

        floweyStem = new ForeverSprite(0, 0, '${spriteDir}flowey_body');
        floweyStem.frames = AssetHelper.getAsset('${spriteDir}flowey_body', ATLAS);
        floweyStem.addAtlasAnim('sway', 'sway', 4, true);
        floweyStem.antialiasing = false;
        floweyStem.scale.set(3.0, 3.0);
        floweyStem.updateHitbox();

        spBubble = new ForeverSprite(0, 0, '${spriteDir}spBubble');
        spBubble.antialiasing = false;
        spBubble.scale.set(3.0, 3.0);
        spBubble.updateHitbox();

        add(star);
        add(title);
        add(window);
        add(optBattle);
        add(optInfo);
        add(floweyEmerge);
        add(floweyHead);
        add(floweyStem);

        floweyHead.visible = false;
        floweyStem.visible = false;
        spBubble.visible = false;
        floweyEmerge.setPosition(0, 400);
        floweyHead.setPosition(30, 433);
        floweyStem.setPosition(24, 595);
        //replaces flowey's animation sprite with the other two separate ones
        floweyEmerge.animation.finishCallback = function(name:String){
            floweyHead.visible = true;
            floweyStem.visible = true;
            floweyEmerge.visible = false;
            floweyStem.animation.play('sway');
        }
        //moves flowey's head a bit with each frame
        floweyStem.animation.callback = function(name:String, frameNumber:Int, frameIndex:Int){
            if(name == 'sway')
            {
                //on frames 4, 5, 6, and 1 it moves negative, otherwise it moves positive.
                //keeping 0-based numbering in mind
                var move:Int = 3;
                var negFrames:Array<Int> = [0, 3, 4, 5];
                if (negFrames.contains(frameNumber))
                    move = -move;
                //on odd frames flowey's head moves vertically, on even frames it moves laterally.
                if(FlxMath.isOdd(frameNumber))
                    floweyHead.x += move;
                else
                    floweyHead.y += move;
            }
        }
        optBattle.setPosition(window.x, 600);
        optInfo.setPosition(window.x + window.width - optInfo.width, 600);
        title.setPosition(160, 25);
        spBubble.setPosition(270, 500);
    }

    private function setDialogue(file:String, diaName:String, ?locked:Bool)
    {
        var diaGrp:DialogueGroup;
        parser.updateDialogueJson(file, 'memory');
        diaGrp = parser.getDialogueFromName(diaName);

        var sprGrp:FlxSpriteGroup = new FlxSpriteGroup(0, 0);
        sprGrp.setPosition(spBubble.x, spBubble.y);
        spBubble.setPosition(0, 0);
        sprGrp.add(spBubble);

        if(diaBubble == null)
            diaBubble = new DialogueObject(Std.int(spBubble.x), Std.int(spBubble.y), diaGrp, floweyHead, sprGrp);
        else
            diaBubble.setDialogueGroup(diaGrp);

        diaBubble.controlCharPos = false;
        diaBubble.defaultFontSetup(DOTUMCHE, 28, FlxColor.BLACK, LEFT, 2.0, 12);
        diaBubble.setTextOffset(60, 30);
        diaBubble.narratedText.fieldWidth = spBubble.width - 90;
        add(diaBubble);
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        controlCheck();
    }

    public function controlCheck()
    {
        if(Controls.UI_DOWN_P)
        {
            FlxG.sound.play(AssetHelper.getAsset('audio/sfx/snd_mainmenu_select', SOUND));
            loadArt(charListData[characterList.addToSelection(1)].artData);
        }
        if(Controls.UI_UP_P)
        {
            FlxG.sound.play(AssetHelper.getAsset('audio/sfx/snd_mainmenu_select', SOUND));
            loadArt(charListData[characterList.addToSelection(-1)].artData);
        }
        if(Controls.UI_RIGHT_P)
        {
            switch (menuState)
            {
                case MAIN: //switch the art
                {
                    var n = artDisplay.selection;
                    if(artDisplay != null)
                        artDisplay.addToSelection(1);
                    if(n != artDisplay.selection)
                        FlxG.sound.play(AssetHelper.getAsset('audio/sfx/snd_mainmenu_select', SOUND));
                }
                case SUB: //switch the option select
                {
                    FlxG.sound.play(AssetHelper.getAsset('audio/sfx/snd_mainmenu_select', SOUND));
                    addOptionSelect(1);
                }
                case SONG: {}
                case INFO: {}
            }
        }
        if(Controls.UI_LEFT_P)
        {
            switch (menuState)
            {
                case MAIN: //switch the art
                {
                    var n = artDisplay.selection;
                    if(artDisplay != null)
                        artDisplay.addToSelection(-1);
                    if(n != artDisplay.selection)
                        FlxG.sound.play(AssetHelper.getAsset('audio/sfx/snd_mainmenu_select', SOUND));
                }
                case SUB: //switch the option select
                {
                    FlxG.sound.play(AssetHelper.getAsset('audio/sfx/snd_mainmenu_select', SOUND));
                    addOptionSelect(-1);
                }
                case SONG: {}
                case INFO: {}
            }
        }

        if(Controls.UT_ACCEPT_P)
        {
            switch (menuState)
            {
                case MAIN:
                {
                    menuState = SUB;
                    boxOptSel = 0;
                    addOptionSelect(0);
                    FlxG.sound.play(Paths.sound('snd_confirm'));
                }
                case SUB: 
                {
                    FlxG.sound.play(Paths.sound('snd_confirm'));
                    if(boxOptSel == 0)
                    {

                    }
                    else if(boxOptSel == 1)
                    {
                        menuState = INFO;
                        setDialogue(charListData[characterList.selection].dialogue, artDisplay.returnDialogueNameFromSel());
                        diaBubble.skipLine();
                        diaBubble.nextDialogueLine();
                        diaBubble.visible = true;
                        spBubble.visible = true;
                    }
                }
                case SONG: 
                {

                }
                case INFO: 
                {
                    diaBubble.nextDialogueLine();
                    if(diaBubble.dialogueCompleted)
                    {
                        trace('closing dialogue');
                        menuState = MAIN;
                        optBattle.playAnim('deselect');
                        optInfo.playAnim('deselect');
                        diaBubble.visible = false;
                        spBubble.visible = false;
                        floweyHead.animation.play('default');
                    }
                }
            }
        }
        if(Controls.UT_CANCEL_P)
        {
            switch (menuState)
            {
                case MAIN:
                {
                    FlxG.switchState(new SaveFileMenu());
                }
                case SUB:
                {
                    menuState = MAIN;
                    optBattle.playAnim('deselect');
                    optInfo.playAnim('deselect');
                }
                case SONG: {}
                case INFO: 
                {
                    diaBubble.skipLine();
                }
            }
        }
    }

    public function loadArt(dataName:String, ?folder:String)
    {
        artDisplay.clearArray();

        var data = AssetHelper.parseAsset('data/memory/${folder != null ? (folder + "/") : ''}${dataName}', YAML);
        if(Reflect.hasField(data, 'folder') && Reflect.hasField(data, 'art'))
        {
            for(i in 0...data.art.length)
            {
                artDisplay.addSprite(
                    data.art[i].file,
                    data.folder,
                    data.art[i].animated ?? false,
                    data.art[i].frameRate ?? 0,
                    data.art[i].resize ?? 1.0,
                    data.art[i].antialiasing ?? true);
                artDisplay.addDialogueName(data.art[i].dialogueName);
            }
        }
        artDisplay.updateSelection(0);
    }

    public function addOptionSelect(sel:Int)
    {
        //not bothering with fucking coding an entire dynamic menu system for two buttons right now, sorry.
        boxOptSel += sel;
        if(boxOptSel > 1) boxOptSel = 0;
        if(boxOptSel < 0) boxOptSel = 1;

        optBattle.playAnim((boxOptSel == 0 ? 'select' : 'deselect'));
        optInfo.playAnim((boxOptSel == 1 ? 'select' : 'deselect'));
    }
}

class ArtDisplay extends SpriteScrollOption
{
    //images could use information like resize, animation data, and when to unlock in a yaml file.
    public var spriteList:Array<ForeverSprite>;
    public var dialogueList:Array<String>;
    public var windowWidth:Int;
    public var windowHeight:Int;

    public function new(x:Int = 0, y:Int = 0, winWidth:Int = 600, winHeight:Int = 450)
    {
        super(x, y);
        displayArrows(false);

        windowWidth = winWidth;
        windowHeight = winHeight;

        spriteList = new Array<ForeverSprite>();
        dialogueList = new Array<String>();
    }

    public function addSprite(file:String, folder:String, animated:Bool, frameRate:Int = 0, resize:Float = 1.0, aa:Bool = true)
    {
        var path = 'images/menu/memory/art/${folder}/${file}';
        var spr:ForeverSprite = new ForeverSprite(0, 0, path);
        if(animated)
        {
            spr.frames = AssetHelper.getAsset(path, ATLAS);
            spr.addAtlasAnim('anim', 'anim', frameRate, true); //NOTE: name the animation 'anim' in the .xml
            spr.playAnim('anim');
        }

        spr.scale.set(resize ?? 1.0, resize ?? 1.0);
        spr.updateHitbox();
        spr.antialiasing = aa;

        spriteList.push(spr);
        add(spr);
        spr.visible = true;
        
        spr.x = this.x + (windowWidth * 0.5) - (spr.width * 0.5);
        spr.y = this.y + (windowHeight * 0.5) - (spr.height * 0.5);
    }

    public inline function addDialogueName(dia:String)
    {
        dialogueList.push(dia);
    }

    public inline function returnDialogueNameFromSel():String
    {
        return dialogueList[selection];
    }

    override function updateSelection(sel:Int)
    {
        selection = sel;
        if(spriteList.length == 0) 
            return;
        if(selection < 0) 
            selection = 0;
        if(selection > spriteList.length - 1) 
            selection = spriteList.length - 1;

        setSpriteFromSel();
    }

    public function setSpriteFromSel()
    {
        for(i in 0...spriteList.length)
        {
            spriteList[i].visible = (i == selection);
        }
    }
    
    public function clearArray()
    {
        for(spr in spriteList)
        {
            spr.destroy();
        }
        spriteList = new Array<ForeverSprite>();
        dialogueList = new Array<String>();
    }
}