package uty.states;

//we're just gonna try to get the overworld working at least
import flixel.math.FlxPoint;
import uty.objects.*;
import uty.objects.Player;
import flixel.tile.FlxTilemap;
import flixel.FlxCamera;
import flixel.math.FlxRect;
import flixel.FlxObject;
import flixel.util.typeLimit.OneOfTwo;
import funkin.states.base.FNFState;
import forever.display.ForeverSprite;
import flixel.tweens.FlxTween;
import uty.components.RoomParser;
import uty.components.DialogueParser;
import uty.objects.Interactable;
import uty.substates.DialogueSubState;
import uty.substates.OverworldMenuSubState;
import uty.substates.SoulTransitionSubState;
import flixel.system.ui.FlxSoundTray;
import uty.objects.OverworldCharacter;
import flixel.group.FlxGroup;
import flixel.util.FlxSort;
import funkin.states.PlayState;
import uty.components.PlayerData;
import uty.components.StoryData;
import uty.components.Inventory;
import uty.components.SoundManager;
import flixel.tile.FlxTilemap;
import flixel.FlxBasic;
import haxe.ds.StringMap;

//parse the json from the ogmo export using AssetHelper.parseAsset ?

class Overworld extends FNFState
{
    //hurm... they call it "overworld" even though it's in the underground... le ironic isn't it?
    public static var current:Overworld;

    public var curRoomName:String = "testLevel";
    var spawnX:Int;
    var spawnY:Int;
    public var room:TiledRoom;
    public var weather:Weather;
    public var player:Player;
    public var playerController:CharacterController;
    public var playerHitbox:PlayerHitbox;

    public var camGame:FlxCamera;
    public var camHUD:FlxCamera; //for dialogue, menus, transition screens, etc.
    public var camPoint:FlxObject;
    public var camBounds:FlxRect;
    public var camPlayerLock:Bool = true;
    public var camOffset:FlxPoint;
    //i'm just gonna make dialogue a single object in this state. 
    //there can only be one so it's probably better to reuse this object rather than spawn them spontaneously in other classes.
    public var dialogueBox:DialogueBox;
    public var dialogueParser:DialogueParser;
    //mainly for NPC parsing, i don't want NPCs in the room object but it makes sense to store them in the room file.
    public var roomParser:RoomParser;
    public var npcs:FlxTypedGroup<NPC>;
    public var npcControllers:StringMap<CharacterController>;
    public var followers:FlxTypedGroup<Follower>;
    public var followerControllers:Array<CharacterController>;
    public var foregroundDecals:Array<FlxSprite>;
    public var foregroundTiles:FlxTilemap;
    //for object draw order organization
    public var visMngr:OverworldVisualManager;
    //audio
    public var soundMngr:SoundManager;

    //just to save some constants to reduce the math in update()
    var centerWidth = FlxG.width / 2;
    var centerHeight = FlxG.height / 2;

    var roomTransitionTime:Float = 0.7;
    var loadCallback:Void->Void;

    public static var pixelRatio:Int = 3; //scale all non-funkin state sprites by this value

    public var isPlayerInLoadingZone:Bool = true; //for various loading zone features
    //such as not triggering a loading zone when spawning within one, and only triggering the transition once

    public function new(?room:String, ?x:Int, ?y:Int, ?callback:Void->Void)
    {
        super();
        curRoomName = room ?? StoryData.getActiveData().playerSave.room;
        spawnX = x ?? StoryData.getActiveData().playerSave.posX;
        spawnY = y ?? StoryData.getActiveData().playerSave.posY;
        setLoadCallback(callback);

        persistentUpdate = true; //this should allow dialogue and stuff to NOT pause the game
    }

    override function create()
    {
        super.create();

        //game camera
        camGame = new FlxCamera();
        camPoint = new FlxObject(0, 0);
        camOffset = new FlxPoint(0, 0);
        FlxG.cameras.reset(camGame);
        FlxG.cameras.setDefaultDrawTarget(camGame, true);
        //UI camera
        camHUD = new FlxCamera();
        camHUD.bgColor.alphaFloat = 0.0; //so we're not looking at a black screen
        FlxG.cameras.add(camHUD, false); //UI elements will need to be manually assigned to this camera with { object.cameras = [camHUD] }

        dialogueParser = new DialogueParser();
        soundMngr = new SoundManager();

        load(curRoomName, spawnX, spawnY);

        current = this;
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        controlInputCall(); //checks for inputs
        debugInputCall();

        triggersCheck(); //interactables only need to be checked when ACCEPT is pressed; triggers do need to be checked constantly.

        playerHitbox.updatePosition(); //move the hitbox with the player
        playerCollisionCheck();

        playerController.update(elapsed); //update AFTER the control call so the scripted stuff can override controls
        npcControllerUpdate(elapsed);
        followerControllerUpdate(elapsed);

        if(camPlayerLock)
            camPoint.setPosition(player.bottomCenter.x + camOffset.x, player.bottomCenter.y + camOffset.y);
        camGame.updateFollow();

        //debug
        //trace('clover position: x${player.x} y${player.y}');

        visMngr.sortSprites();
    }

    public function playerCollisionCheck()
    {
        //REGULAR COLLISION//
        if(room.collisionGrid.overlaps(playerHitbox, false, camGame))
        {
            playerController.previousPosition();
        }

        //NPC COLLISION//
        npcs.forEach(function(n:NPC)
        {
            if(n.collision.enableCollide && n.collision.checkOverlap(playerHitbox))
            {
                playerController.previousPosition();
            }
        });

        //LOADING ZONES//

        //for every loading zone in loading zones
        //if player's overlapping it, get that zone's data, transition, and warp to the next room

        var isCol:Bool = false;
        room.loadingZones.forEach(function(zone:LoadingZone)
        {
            if(zone.collision.checkOverlap(playerHitbox))
            {
                isCol = true;
                //this only gets triggered once. is NOT called unless the player wasn't in a loading zone before.
                if(!isPlayerInLoadingZone)
                {
                    isPlayerInLoadingZone = true;
                    nextRoomTransition(zone.toRoom, zone.toX, zone.toY);
                }
            }
        });
        //will set this var to false if no collision happened
        isPlayerInLoadingZone = isCol;

        //SAVE POINT//
        if(room.savePoint != null && room.savePoint.collision.checkOverlap(playerHitbox))
        {
            playerController.previousPosition();
        }
    }

    function load(roomName:String, playerX:Float, playerY:Float)
    {
        curRoomName = roomName;

        roomParser = new RoomParser(curRoomName);
        visMngr = new OverworldVisualManager();
        npcs = new FlxTypedGroup<NPC>();
        followers = new FlxTypedGroup<Follower>();

        loadSound(roomParser.getRoomValues().music, roomParser.getRoomValues().ambience);
        //note that players and npcs are add()ed to the object sorter group and not directly to the scene
        loadPlayer(playerX, playerY);
        loadRoom(curRoomName);
        loadNPCs(curRoomName);
        loadFollowers();
        loadRoomVisuals();
        //now we add the sorter
        this.add(visMngr);

        setCameraBounds(0, 0);
        camGame.follow(camPoint);
        camPoint.setPosition(player.x + camOffset.x, player.y + camOffset.y);

        loadCallback();
        setLoadCallback(null); //makes this callback happen only once.
    }

    function loadRoomVisuals()
    {
        if(visMngr == null)
            visMngr = new OverworldVisualManager();
        visMngr.addBackgroundObjects(room.background.members);
        visMngr.addTilemaps(room.tilemaps.members);
        visMngr.addForegroundObjects(room.foregroundDecals.members);
        visMngr.addForegroundObject(room.foregroundTilemap);
        //weather stuff
        visMngr.loadWeather(roomParser.getRoomValues().weather ?? "");

        //for(i in room.decals)
            //this.add(i);
        trace(room.decals);

        if(room.savePoint != null)
            visMngr.addSprite(room.savePoint);
        visMngr.addSprite(player);
        for (n in npcs.members)
            visMngr.addSprite(n);
        for (f in followers.members)
            visMngr.addSprite(f);
        visMngr.addSprites(room.decals.members);
        //reminder: the problem is not here, check tiledroom

        //visMngr.sortSprites();
        add(visMngr);
        add(room);
        trace("VIS MNGR SPRITE LENGTH: " + visMngr.owSprites.members.length);
    }

    function loadRoom(roomName:String)
    {
        room = new TiledRoom(roomName);
    }

    function loadSound(music:String, ambience:String)
    {
        soundMngr.updateMusic(music ?? "none");
        soundMngr.updateAmbience(ambience ?? "none");
        soundMngr.setMusicVolume(1.0);
        soundMngr.setAmbienceVolume(1.0);
    }

    function loadPlayer(x:Float, y:Float)
    {
        if(!roomParser.roomFileExists(curRoomName))
        {
            x = 480;
            y = 540;
        }
        player = new Player("clover", x, y, 1);

        playerController = new CharacterController(player);

        playerHitbox = new PlayerHitbox(player);
        add(playerHitbox);
 
    }

    function loadNPCs(roomName:String)
    {
        var npcsData:Array<EntityData> = roomParser.getEntitiesByName("NPC");
        for(i in npcsData)
        {
            var newNPC:NPC = new NPC(
                i.values.characterName,
                i.x * 3 + i.width * 1.5,
                i.y * 3 + i.height * 1.5,
                i.values.facing,
                i.values.dialogue
            );
            newNPC.x -= (newNPC.width * 0.5);
            newNPC.y -= (newNPC.height * 0.5);
            newNPC.playSpecialAnimation(i.values.animation ?? "");
            npcs.add(newNPC);
        }

        npcControllers = new StringMap<CharacterController>();
    }

    function loadFollowers()
    {
        //this needs to be based off of the player's save file.
        //for now though, i'll just force it in.
        //REPLACE THIS SHIT LATER
        var followerSave:Array<String> = StoryData.getActiveData().followers;

        for(i in followerSave)
        {
            var follower:Follower = new Follower(
                i,
                player.x,
                player.y,
                Direction.DOWN,
                "cerobaFollower"
            );
            followers.add(follower);
        }

        followerControllers = new Array<CharacterController>();
        for (f in followers)
            followerControllers.push(new CharacterController(f));
    }

    public function setLoadCallback(func:Void->Void)
    {
        if(func != null)
            loadCallback = func;
        else
            loadCallback = function() {};
    }

    public function addNPCController(name:String)
    {
        for(n in npcs)
        {
            if(n.characterName == name) {
                npcControllers.set(name, new CharacterController(n));
                return;
            }
        }
    }

    public function addNPCScriptInput(name:String, direction:String, run:Bool, time:Float)
    {
        if(npcControllers.get(name) != null)
            npcControllers.get(name).addScriptInput(direction, run, time);
    }

    function setCameraBounds(?expandX:Float = 0, ?expandY:Float = 0)
    {
        //sets the rectangle bounds at which the camera will stop following clover
        //making expand positive will allow the camera to extend out of the room's range
        //making expand negative will stop the camera before the end side of the room
        camBounds = new FlxRect(
            room.roomBounds.left - expandX,
            room.roomBounds.top - expandY,
            room.roomBounds.width + expandX,
            room.roomBounds.height + expandY);

        //center the camera in small rooms
        if(camBounds.width < FlxG.width)
        {
            camBounds.left = camBounds.left + (camBounds.width * 0.5);
            camBounds.width = FlxG.width * 0.5;
        }
        if(camBounds.height < FlxG.height)
        {
            camBounds.top = camBounds.top + (camBounds.height * 0.5);
            camBounds.height = FlxG.height * 0.5;
        }
        //trace("camera bounds are: " + camBounds.left + ", " + camBounds.top + " | " + camBounds.right + ", " + camBounds.bottom);

        camGame.setScrollBoundsRect(camBounds.left, camBounds.top, camBounds.width, camBounds.height);
    }

    function controlInputCall()
    {
        //an update() function. poopshitters checked for input in the player object in order to move it but I think i should do that here.
        //i think this is necessary to prevent janky collision, and is cleaner anyways.

        /* ----------------------------------------------------
        ---                    MOVEMENT                     ---
        -----------------------------------------------------*/
        var hor:String = Direction.NONE;
        var ver:String = Direction.NONE;

        if(!player.lockMoveInput)
        {
            if (Controls.UI_UP && !Controls.UI_DOWN) //up
                ver = Direction.UP;
            if (Controls.UI_DOWN && !Controls.UI_UP) //down
                ver = Direction.DOWN;
            if (Controls.UI_LEFT && !Controls.UI_RIGHT) //left
                hor = Direction.LEFT;
            if (Controls.UI_RIGHT && !Controls.UI_LEFT) //right
                hor = Direction.RIGHT;
        }

        playerController.setMoving(hor, ver);
        playerController.setRunning(Controls.UT_CANCEL); //checks if we're running based on the run key being held

        /* ----------------------------------------------------
        ---                   ACTION KEYS                   ---
        -----------------------------------------------------*/

        if(!player.lockActionInput)
        {
            if(Controls.UT_ACCEPT_P)
            {
                interactablesCheck();
            }
            if(Controls.UT_MENU_P)
            {
                setLockAllInput(true);
                final menuSubstate:OverworldMenuSubState = new OverworldMenuSubState(camHUD);
                openSubState(menuSubstate);
            }
        }
    }

    private function debugInputCall()
    {
        if(FlxG.keys.justPressed.SEVEN)
        {
            var song:PlaySong = {
                name: "Martlet",
                folder: "martlet",
                difficulty: "hard"
            };
            initializeSongTransition(song);
        }

        if(FlxG.keys.justPressed.EIGHT)
            {
                var song:PlaySong = {
                    name: "Flowey",
                    folder: "flowey",
                    difficulty: "hard"
                };
                initializeSongTransition(song);
            }
        
        if(FlxG.keys.justPressed.NINE)
        {

        }


        //save stuff

        //subtract a level
        if(FlxG.keys.justPressed.O)
        {
            StoryUtil.setLV(-1, true);
            FlxG.sound.play(AssetHelper.getAsset('audio/sfx/snd_love_increased', SOUND));
        }
        //add a level
        if(FlxG.keys.justPressed.P)
        {
            StoryUtil.setLV(1, true);
            FlxG.sound.play(AssetHelper.getAsset('audio/sfx/snd_love_increased', SOUND));
        }

        if(FlxG.keys.justPressed.T)
        {
            var newSave:StorySave = StoryData.getActiveData();
            Inventory.addItemFromFile('CandyCorn');
            StoryData.setActiveData(newSave);
            FlxG.sound.play(AssetHelper.getAsset('audio/sfx/snd_battle_item_equip', SOUND));
        }

        if(FlxG.keys.justPressed.M)
        {
            //var npcCtrl:CharacterController = new CharacterController(npcs[0]);
            playerController.addScriptInput("right", false, 1.0);
            playerController.addScriptInput("down", false, 1.0);
        }

        /*
        if(FlxG.keys.justPressed.SPACE)
        {
            StoryData.saveData();
            FlxG.sound.play(AssetHelper.getAsset('audio/sfx/snd_savedgame', SOUND));
        }
        */
    }

    public function triggersCheck()
    {
        room.triggers.forEach(function(t:EventTrigger)
        {
            if(t.enabled && t.checkOverlap(playerHitbox)) //if the trigger is active and you're inside of it
            {
                if(!t.isButton || Controls.UT_ACCEPT_P) //if it's not a button, or if it is, you're pressing ACCEPT
                {
                    t.callScript();
                    return;
                }
                //otherwise, this is a button trigger, and you're not pressing ACCEPT
            }
        });
    }

    public function openDialogue(dialogue:String, ?folder:String, ?checkCount:Int = 0, ?name:String)
    {
        trace('dialogue opned');
        setLockAllInput(true);
        dialogueParser.updateDialogueJson(dialogue, folder ?? "");
        var diaGrp:DialogueGroup;
        if(name != null)
            diaGrp = dialogueParser.getDialogueFromName(name);
        else    
            diaGrp = dialogueParser.getDialogueFromCheckCount(checkCount);
        final dialogueSubstate:DialogueSubState = new DialogueSubState(diaGrp, camHUD);
        openSubState(dialogueSubstate);
    }

    public function tweenCameraOffset(x:Int, y:Int, time:Float)
    {
        FlxTween.cancelTweensOf(camOffset);
        FlxTween.tween(camOffset, {x: x, y: y}, time);
    }

    public function interactablesCheck()
    {
        //checks all interactables in the room, on npcs, and all relevant objects.

        //check for any regular interactables nearby
        room.interactables.forEach(function(i:Interactable)
        {
            if(i.collision.checkOverlap(playerHitbox))
            {
                setLockAllInput(true);
                openDialogue(i.dialogueJson, i.checkCount);
                //increment AFTER we retrieve the dialogue
                i.checkIncrement();
                return;
            }
        });

        if(room.savePoint != null && room.savePoint.interactable.collision.checkOverlap(playerHitbox))
        {
            setLockAllInput(true);
            room.savePoint.startDialogue();
        }

        //check the NPCs too
        //i know this is shitty copied code... IDGAF!!!!!!
        //add a function where npcs turn to you when talking to them
        npcs.forEach(function(n:NPC)
        {
            if(n.interactable.collision.checkOverlap(playerHitbox) && n.interactable.areClicksReached(1))
            {
                setLockAllInput(true);
                dialogueParser.updateDialogueJson(n.interactable.dialogueJson);

                var diaGrp:DialogueGroup = dialogueParser.getDialogueFromCheckCount(n.interactable.checkCount);
                //increment AFTER we retrieve the dialogue
                n.interactable.checkIncrement();

                final dialogueSubstate:DialogueSubState = new DialogueSubState(diaGrp, camHUD);
                openSubState(dialogueSubstate);
                return;
            }
        });

        followers.forEach(function(f:Follower)
            {
                if(f.interactable.collision.checkOverlap(playerHitbox) && f.interactable.areClicksReached(1))
                {
                    setLockAllInput(true);
                    dialogueParser.updateDialogueJson(f.interactable.dialogueJson);
    
                    var diaGrp:DialogueGroup = dialogueParser.getDialogueFromCheckCount(f.interactable.checkCount);
                    //increment AFTER we retrieve the dialogue
                    f.interactable.checkIncrement();
    
                    final dialogueSubstate:DialogueSubState = new DialogueSubState(diaGrp, camHUD);
                    openSubState(dialogueSubstate);
                    return;
                }
            });
    }

    public function npcControllerUpdate(elapsed:Float)
    {
        for(key in npcControllers.keys())
        {
            npcControllers.get(key).update(elapsed);
        }
    }

    public function followerControllerUpdate(elapsed:Float)
    {
        //remember to go off of the bottom-center coords.
        for(i in 0...followers.members.length)
        {
            if(i == 0)
            {
                followers.members[i].updateTargetCoords(player.bottomCenter.x, player.bottomCenter.y);
            }
            else
            {
                followers.members[i].updateTargetCoords(followers.members[i-1].bottomCenter.x, followers.members[i-1].bottomCenter.y);
            }
        }
        for(i in 0...followerControllers.length)
        {
            followerControllers[i].update(elapsed);
            followerControllers[i].setMovingFromPoint(followers.members[i].calculateMoveInput());
            followerControllers[i].setRunning(followers.members[i].isRunningDistance());
        }
    }

    //simply sorting by sprite Y doesn't really work when there's sprites of different sizes
    //im sorting based on the collision boxes here
    inline function sortOverworldCharacters(order:Int, a:OverworldCharacter, b:OverworldCharacter):Int
    {
        return Std.int((a.collision.y + a.collision.height) - (b.collision.y + b.collision.height));
    }

    public function nextRoomTransition(roomName:String, playerX:Float, playerY:Float)
    {
        var blackScreen:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
        blackScreen.cameras = [camHUD];
        blackScreen.alpha = 0.0;
        add(blackScreen);

        FlxTween.tween(blackScreen, {alpha: 1.0}, roomTransitionTime / 2, {
            onComplete: function(twn:FlxTween)
                {
                    roomCleanup();
                    load(roomName, playerX, playerY);
                    FlxTween.tween(blackScreen, {alpha: 0.0}, roomTransitionTime / 2);
                }
        });
    }

    public function roomCleanup()
    {
        //destroys stuff and resets groups for the next room
        room.destroy();

        var i:Int = 0;
		while (i != visMngr.members.length) {
			visMngr.members[i].destroy();
			i++;
		}

        visMngr.clear();
        npcs.clear();
        visMngr.destroy();
        npcs.destroy();
    }

    override function closeSubState():Void
    {
        //for allowing movement after dialogue boxes for now; may need to change
        if(player != null)
        {
            setLockAllInput(false);
        }
        super.closeSubState();
    }

    public function getNPCFromName(name:String):NPC
    {
        for(n in npcs)
        {
            if(n.name == name)
                return n;
        }
        return null;
    }

    public function setLockAllInput(locked:Bool = true)
    {
        setLockMoveInput(locked);
        setLockActionInput(locked);
    }

    public function setLockMoveInput(locked:Bool = true)
    {
        player.lockMoveInput = locked;
    }

    public function setLockActionInput(locked:Bool = true)
    {
        player.lockActionInput = locked;
    }

    public function initializeSongTransition(song:PlaySong)
    {
        setLockAllInput(true);
        //bigass fuckin bandaid
        var black:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        black.camera = camHUD;
        add(black);

        var playerCenterScreenPoint:FlxPoint = new FlxPoint(
            player.x + (player.width / 2) - camGame.scroll.x,
            player.y + (player.height / 2) - camGame.scroll.y);

        final soulSubstate:SoulTransitionSubState = new SoulTransitionSubState(song, 
            playerCenterScreenPoint.x, playerCenterScreenPoint.y);
        soulSubstate.camera = camHUD;
        openSubState(soulSubstate);
    }

    public function warp(room:String, x:Int, y:Int)
    {
        roomCleanup();
        load(room, x, y);
        FlxG.sound.play(AssetHelper.getAsset('audio/sfx/snd_flowey_glitch_yellow', SOUND));
    }
}

//might use later for better organization because this is becoming spaghetti code with all these added room layers
//my whole system for layering right now is pretty stupid, searching by name for "foreground" and "background"
//ogmo (or perhaps my brain) is unfortunately a bit too primitive to easily replicate UTY's detailed artistic overworld
class OverworldVisualManager extends FlxTypedGroup<FlxBasic>
{
    //so this order: background tiles/decals, tiles (in layer order), sprites, foreground tiles/decals

    //only visible sprite objects should go here
    public var room:TiledRoom;
    public var owSprites:FlxTypedGroup<OverworldSprite>;
    public var owTilemaps:FlxTypedGroup<OverworldTilemap>;
    public var weather:Weather;
    //to prevent a ton of unnecessary array sorting each frame, probably best to separate into layers
    public var background:FlxTypedGroup<Dynamic>;
    public var foreground:FlxTypedGroup<Dynamic>;

    public function new()
    {
        super();
        owSprites = new FlxTypedGroup<OverworldSprite>();
        owTilemaps = new FlxTypedGroup<OverworldTilemap>();
        background = new FlxTypedGroup<Dynamic>();
        weather = new Weather();
        foreground = new FlxTypedGroup<Dynamic>();
        //this is the layer order:
        this.add(background);
        this.add(owTilemaps);
        this.add(owSprites);
        this.add(weather);
        this.add(foreground);
    }

    public function addSprite(sprite:OverworldSprite)
    {
        owSprites.add(sprite);
    }

    //NOTE: giving an Array<Parent> type an Array<Child> DOES NOT REGISTER the child class
    //don't use this except for locally and for actual non-child overworldsprites for now
    public function addSprites(sprites:Array<OverworldSprite>)
    {
        if(sprites == null) return;
        for(i in 0...sprites.length)
            addSprite(sprites[i]);
    }

    public function sortSprites():FlxTypedGroup<OverworldSprite>
    {
        owSprites.members.sort((a:OverworldSprite, b:OverworldSprite) -> 
            FlxSort.byValues(FlxSort.ASCENDING, (a.worldHeight), (b.worldHeight)));

        return owSprites;
    }

    public function loadWeather(wthr:String)
    {
        if(wthr == null)
            wthr = "";
        wthr = wthr.toLowerCase();
        if(weather == null)
            weather = new Weather();

        switch (wthr)
        {
            case "snow", "snowy", "snowing":
            {
                weather.snowIntensity = 3.0;
            }
            case "fog", "foggy":
            {
                weather.createFog();
            }
            default:
            {
                weather.clearWeather();
            }
        }
    }

    public function addTilemap(tilemap:OverworldTilemap)
    {
        owTilemaps.add(tilemap);
    }

    public function addTilemaps(tilemaps:Array<OverworldTilemap>)
    {
        if(tilemaps == null) return;
        for(i in 0...tilemaps.length)
            addTilemap(tilemaps[i]);
    }

    //most likely an unnecessary function; just use what the parser gives
    public function sortTilemaps():FlxTypedGroup<OverworldTilemap>
    {
        owTilemaps.members.sort((a:OverworldTilemap, b:OverworldTilemap) -> 
        FlxSort.byValues(FlxSort.ASCENDING, (a.drawHeight), (b.drawHeight)));

        return owTilemaps;
    }

    //NOTE: these functions use dynamic to get fields from both Tilemaps and Sprites
    //fix later, probably an unstable solution long-term

    public function addBackgroundObject(obj:Dynamic)
    {
        background.add(obj);
    }

    public function addBackgroundObjects(objs:Array<Dynamic>)
    {
        for(i in 0...objs.length)
            addBackgroundObject(objs[i]);
    }

    public function sortBackground():FlxTypedGroup<Dynamic>
    {
        background.members.sort((a:Dynamic, b:Dynamic) -> 
            FlxSort.byValues(FlxSort.ASCENDING, (a.drawHeight), (b.drawHeight)));

        return background;
    }

    public function addForegroundObject(obj:Dynamic)
    {
        foreground.add(obj);
    }

    public function addForegroundObjects(objs:Array<Dynamic>)
    {
        for(i in 0...objs.length)
            addForegroundObject(objs[i]);
    }

    public function sortForeground():FlxTypedGroup<Dynamic>
    {
        foreground.members.sort((a:Dynamic, b:Dynamic) -> 
            FlxSort.byValues(FlxSort.ASCENDING, (a.drawHeight), (b.drawHeight)));

        return foreground;
    }

    /* OLD CODE
    public function sortSprites():FlxTypedGroup<OverworldSprite>
    {
        var tempArray:Array<OverworldSprite> = owSprites.members;
        var transferArray:Array<OverworldSprite> = new Array<OverworldSprite>();
        var finalArray:Array<OverworldSprite> = new Array<OverworldSprite>();

        //stores the draw heights into an array for optimization
        var drawHeightArray:Array<Int> = new Array<Int>(); 
        for (sprite in owSprites.members)
        {
            //only add if it's not added already
            if(!drawHeightArray.contains(sprite.drawHeight))
                drawHeightArray.push(sprite.drawHeight);
        }
        //lowest first; this becomes a list of all UNIQUE height values from least to greatest
        drawHeightArray.sort((Order, a:Int, b:Int) -> FlxSort.byValues(FlxSort.ASCENDING, a, b));

        while(drawHeightArray.length > 0) //run this until everything is sorted
        {
            //adds all sprites with the lowest draw priority to an array
            for(i in 0...tempArray.length)
            {
                if(tempArray[i].drawHeight == drawHeightArray[0]) //if this sprite's drawheight = the lowest listed draw height
                {
                    transferArray.append(tempArray.splice(i, 1));
                    i -= 1; //optimizing to prevent unnecessary recursion
                }
            }
            //subsort by world height
            if(transferArray.length > 1)
                transferArray.sort((Order, a:OverworldSprite, b:OverworldSprite) -> 
                FlxSort.byValues(FlxSort.ASCENDING, (a.worldHeight), (b.worldHeight)));

            //add these lowest sprites to the final array and shorten the drawheightarray to the next lowest
            for(s in transferArray.members)
                finalArray.push(s);
            transferArray.clear();
            drawHeightArray.splice(0, 1);
        }

        owSprites.clear();
        for (i in 0...finalArray.length)
            owSprites.push(finalArray[i]);
        return owSprites;
    }
    */
}
