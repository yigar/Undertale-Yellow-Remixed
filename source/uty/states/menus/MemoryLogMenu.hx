package uty.states.menus;

import yaml.util.Strings;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.sound.FlxSound;
import flixel.util.FlxColor;
import forever.display.ForeverSprite;
import forever.display.ForeverText;
import funkin.components.ChartLoader;
import funkin.components.Difficulty;
import funkin.components.FunkinData;
import funkin.states.base.BaseMenuState;
import flixel.FlxSprite;
import uty.ui.ScrollSelectionList;
import uty.ui.SpriteScrollOption;
import uty.ui.Window;
import uty.components.StoryData;
import uty.objects.UTText;
import yaml.Yaml;
import flixel.math.FlxMath;
import uty.objects.DialogueObject;
import uty.components.DialogueParser;
import flixel.addons.display.FlxBackdrop;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxRect;

typedef CharacterOption = {
    name:String, //the display name of the character.
    icon:String, //the icon sprite to use.
    artData:String, //data object for sprite display shit
    dialogue:String, //name of the dialogue file to look for.
    songs:Array<String>, //the songs belonging to this character. this state checks if they're unlocked.
    unlock:Array<String>, //unlock flags
    secret:Bool //if this character is secret, they will not be added to the list at all when locked.
    //note: maybe create a 'funkinsave' object like the 'storysave' one
}

typedef SongData = {
    name:String, //the song's display name
    song:String, //the file directory of the song
    iconP:String, //the player icon
    iconO:String, //the opponent icon
    background:String, //the scrolling banner theme to use
    unlock:Array<String>, //the unlock criteria for this song, stored in flags
    unlockDesc:String //a hint telling the player how to unlock the locked song.
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
    public var songMenu:SongSelectSubMenu;

    public var menuState:MemoryMenuState = MAIN;
    public var boxOptSel:Int = 0;
    private var parser:DialogueParser;

    public final spriteDir:String = 'images/menu/memory/';

    //maybe make this files like the other 2 data types
    public var fullData:Array<CharacterOption>;

    public final lockedSongData:CharacterOption = {
        name: "?????",
        icon: "empty",
        artData: "locked",
        dialogue: "locked",
        songs: [],
        unlock: [],
        secret: false
    }

    override function create()
    {
        fullData = AssetHelper.parseAsset('data/memory/memory', YAML).characters;
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
            if(StoryProgress.checkFlagArray(fullData[i].unlock)) //check for unlocked in save later
            {
                characterList.addOption(fullData[i].name, '${spriteDir}icons/${fullData[i].icon}');
                charListData.push(fullData[i]);
            }
            else if(fullData[i].secret) //check for if it's NOT secret
            {
                characterList.addOption('?????', '${spriteDir}icons/empty');
                var lData:CharacterOption = lockedSongData;
                lData.unlock = fullData[i].unlock;
                lData.dialogue = fullData[i].dialogue;
                charListData.push(lData);
            }
            //otherwise it's secret and not added to the list at all
        }

        //now that the data is loaded...
        songMenu = new SongSelectSubMenu();
        songMenu.visible = false;
        songMenu.setSongsData(charListData[0].songs, charListData[0].name);
        songMenu.setupSprites();
        add(songMenu);

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
        menuControlCheck();
    }

    public function menuControlCheck()
    {
        var vDir = (Controls.UI_DOWN_P ? 1 : 0) - (Controls.UI_UP_P ? 1 : 0);
        var hDir = (Controls.UI_RIGHT_P ? 1 : 0) - (Controls.UI_LEFT_P ? 1 : 0);

        //save some energy if no input was given
        if(vDir == 0 && hDir == 0 && !Controls.UT_ACCEPT_P && !Controls.UT_CANCEL_P)
            return;

        switch (menuState)
        {
            case MAIN: //all MAIN menu actions
            {
                if(vDir != 0) //up|down
                {
                    FlxG.sound.play(AssetHelper.getAsset('audio/sfx/snd_mainmenu_select', SOUND));
                    loadArt(charListData[characterList.addToSelection(vDir)].artData);
                }
                if(hDir != 0) //left|right
                {
                    var n = artDisplay.selection;
                    if(artDisplay != null)
                        artDisplay.addToSelection(hDir);
                    if(n != artDisplay.selection)
                        FlxG.sound.play(AssetHelper.getAsset('audio/sfx/snd_mainmenu_select', SOUND));
                }
                if(Controls.UT_ACCEPT_P)
                {
                    menuState = SUB;
                    boxOptSel = 0;
                    addOptionSelect(0);
                    FlxG.sound.play(Paths.sound('snd_confirm'));
                }
                if(Controls.UT_CANCEL_P)
                {
                    FlxG.switchState(new SaveFileMenu());
                }
            }
            case SUB: //all SUB menu actions
            {
                if(hDir != 0)
                {
                    FlxG.sound.play(AssetHelper.getAsset('audio/sfx/snd_mainmenu_select', SOUND));
                    addOptionSelect(hDir);
                }
                if(Controls.UT_ACCEPT_P)
                {
                    FlxG.sound.play(Paths.sound('snd_confirm'));
                    if(boxOptSel == 0) //song state
                    {
                        menuState = SONG;
                        //update
                        openSongSubMenu(charListData[characterList.selection].name);
                    }
                    else if(boxOptSel == 1) //info state
                    {
                        menuState = INFO;
                        setDialogue(charListData[characterList.selection].dialogue, artDisplay.returnDialogueNameFromSel());
                        diaBubble.nextDialogueLine();
                        diaBubble.visible = true;
                        spBubble.visible = true;
                    }
                }
                if(Controls.UT_CANCEL_P)
                {
                    menuState = MAIN;
                    optBattle.playAnim('deselect');
                    optInfo.playAnim('deselect');
                }
            }
            case SONG:
            {
                songMenu.vSel += vDir;
                if(songMenu.vSel < 0)
                    songMenu.vSel = 1;
                if(songMenu.vSel > 1)
                    songMenu.vSel = 0;

                if(vDir != 0 || hDir != 0) {
                    FlxG.sound.play(AssetHelper.getAsset('audio/sfx/snd_mainmenu_select', SOUND));
                    songMenu.start.animation.play(songMenu.vSel == 1 ? 'select' : 'deselect');
                    songMenu.artBackground.setTextColor(songMenu.vSel == 0 ? FlxColor.YELLOW : FlxColor.WHITE);
                }
        
                switch (songMenu.vSel)
                {
                    case 0:
                    {
                        if(hDir != 0) {
                            songMenu.updateSong(songMenu.artBackground.selection + hDir);
                        }
                    }
                    case 1:
                    {
                        if(Controls.UT_ACCEPT_P) {
                            //load song
                        }
                    }
                }
        
                if(Controls.UT_CANCEL_P)
                {
                    //close menu
                    menuState = SUB;
                    songMenu.close();
                }
            }
            case INFO:
            {
                if(Controls.UT_ACCEPT_P)
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
                if(Controls.UT_CANCEL_P)
                {
                    diaBubble.skipLine();
                }
            }
        }
    }

    public function loadArt(dataName:String, ?folder:String)
    {
        artDisplay.clearArray();

        var data = AssetHelper.parseAsset('data/memory/art/${folder != null ? (folder + "/") : ''}${dataName}', YAML);
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

    public function openSongSubMenu(character:String)
    {
        //uses name string to make the function more versatile than relying on whatever is selected right now
        //not very efficient but WHATEVER......
        for(i in 0...charListData.length)
        {
            if(charListData[i].name == character && charListData[i].songs.length > 0)
            {
                var songs = charListData[i].songs;

                songMenu.setSongsData(songs, character);
                songMenu.open();
            }
        }
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

class SongSelectSubMenu extends FlxSpriteGroup
{
    //visual stuff
    public var shade:FlxSprite;
    public var window:Window;
    public var title:UTText;
    public var artBackground:SpriteScrollOption;
    public var iconOpp:ForeverSprite;
    public var iconPlayer:ForeverSprite;
    public var start:ForeverSprite;
    public var bgRect:FlxRect;
    //required data
    public var songData:Array<SongData>;
    public var folder:String;
    //vars
    public final xOff:Int = 160;
    public final yOff:Int = 120;
    public var vSel:Int = 0;
    public var scrollX:Float = 0;

    public function new()
    {
        super(xOff, yOff);
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);
        scrollBackground(elapsed);
    }

    //have a load sprite function; repeat as necessary when changing the song
    //create a data structure thing for this
    //do clipping window shenanigans with the scroll sprite

    public function setupSprites()
    {
        shade = new FlxSprite(-xOff, -yOff).makeGraphic(FlxG.width, FlxG.height, 0x66000000);
        add(shade);
        //the box
        window = new Window(0, 0, 640, 480);
        //the scrolling art
        artBackground = new SpriteScrollOption(10, 60, 'images/menu/memory/strip', false, 3.0);
        artBackground.arrowsByText = true;

        //sets up the anim/text stuff for this character's songs
        var bgList:Array<String> = new Array<String>();
        var optList:Array<String> = new Array<String>();
        if(songData != null)
        {
            for(i in 0...songData.length)
            {
                if(!bgList.contains(songData[i].background))
                    bgList.push(songData[i].background);
                optList.push(songData[i].name);
            }
        }
        artBackground.addAtlasAnims(bgList);
        artBackground.addOptionArray(optList);
        artBackground.updateSelection(0);
        //for first select
        artBackground.setTextColor(FlxColor.YELLOW);
        artBackground.position(20, 120);
        artBackground.positionText(Std.int(window.width * 0.5), Std.int(yOff + artBackground.sprite.y + 50), true);
        artBackground.positionArrows();

        //icons
        if(songData != null && songData.length > 0)
            setIcons(songData[0].iconO ?? "flowey", songData[0].iconP ?? "clover");
        else {
            setIcons();
        }
            
        start = new ForeverSprite(280, 405, 'images/menu/memory/start');
        start.frames = AssetHelper.getAsset('images/menu/memory/start', ATLAS);
        start.animation.addByPrefix('deselect', 'deselect', 4, true);
        start.animation.addByPrefix('select', 'select', 4, true);
        start.animation.play('deselect');
        start.scale.set(3, 3);
        start.antialiasing = false;

        add(window);
        add(artBackground);
        add(iconOpp);
        add(iconPlayer);
        add(start);

        //clipping rectangle setup
        bgRect = new FlxRect(scrollX, 0, 200, artBackground.sprite.height);
        artBackground.sprite.clipRect = bgRect;
    }

    //icons arent updating, fix that
    public function setIcons(iconO:String = "flowey", iconP:String = "clover")
    {
        iconOpp = new ForeverSprite(100, 190);
        var file1:FlxGraphic = AssetHelper.getAsset('images/icons/${iconO}', IMAGE);
        var frm1 = AssetHelper.getAsset('images/icons/${iconO}', ATLAS);
        iconOpp.loadGraphic(file1);
        iconOpp.frames = frm1;
        iconOpp.animation.addByPrefix('default', 'default', 4, true);
        iconOpp.animation.play('default');
        iconOpp.scale.set(3.0, 3.0);
        iconOpp.antialiasing = false;

        iconPlayer = new ForeverSprite(500, iconOpp.y);
        var file2:FlxGraphic = AssetHelper.getAsset('images/icons/${iconP}', IMAGE);
        var frm2 = AssetHelper.getAsset('images/icons/${iconP}', ATLAS);
        iconPlayer.loadGraphic(file2);
        iconPlayer.frames = frm2;
        iconPlayer.animation.addByPrefix('default', 'default', 4, true);
        iconPlayer.animation.play('default');
        iconPlayer.scale.set(3.0, 3.0);
        iconPlayer.antialiasing = false;
    }

    public function updateSong(index:Int)
    {
        if(songData == null)
            return;
        if(index < 0)
            index = songData.length - 1;
        if(index > songData.length - 1)
            index = 0;
        setIcons(songData[index].iconO, songData[index].iconP);
        artBackground.updateSelection(index);
        artBackground.positionText(Std.int(xOff + window.width * 0.5), Std.int(yOff + artBackground.sprite.y + 50), true);
        artBackground.positionArrows();
    }

    public function setSongsData(songs:Array<String>, ?folder:String):Array<SongData> {
        songData = getSongsData(songs, folder);
        return songData;
    }

    public function getSongsData(songs:Array<String>, ?folder:String):Array<SongData>
    {
        this.folder = folder ?? "";
        var songDaters:Array<SongData> = new Array<SongData>();
        for(song in songs)
        {
            var data = AssetHelper.parseAsset('data/memory/songs/${folder != null ? (folder + "/") : ''}${song}', YAML);
            if(data != null && Reflect.hasField(data, 'song')) //just being sure it's the right type
            {
                //convert dynamic to SongData
                var songData:SongData = {
                    name: data.name ?? "N/A",
                    song: data.song ?? "budding_friendship",
                    iconP: data.iconP ?? "clover",
                    iconO: data.iconO ?? "flowey",
                    background: data.background ?? "ruins",
                    unlock: data.unlock ?? [],
                    unlockDesc: data.unlockDesc ?? "NO DESC"
                };
                songDaters.push(songData);
            }
        }
        return songDaters;
    }

    public function scrollBackground(elapsed:Float)
    {
        //movement is integerized, preventing jittering
        scrollX += 10 * elapsed;
        if(scrollX > 200) {
            scrollX = 0;
        }
        bgRect.x = Std.int(scrollX);
        artBackground.sprite.clipRect = bgRect;
        //move the sprite back into place to compensate
        var backMove = Std.int((20 + xOff) - (scrollX * 3));
        artBackground.sprite.x = backMove - (backMove % 3);
    }

    public function open()
    {
        visible = true;
    }

    public function close()
    {
        visible = false;
    }
}