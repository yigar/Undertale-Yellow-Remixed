package uty.states;

//we're just gonna try to get the overworld working at least
import flixel.math.FlxPoint;
import uty.objects.*;
import uty.objects.Player;
import flixel.tile.FlxTilemap;
import flixel.FlxCamera;
import flixel.math.FlxRect;
import flixel.FlxObject;
import funkin.states.base.FNFState;
import forever.display.ForeverSprite;
import flixel.tweens.FlxTween;
import uty.components.RoomParser;
import uty.components.DialogueParser;
import uty.objects.Interactable;
import uty.substates.DialogueSubState;
import uty.substates.SoulTransitionSubState;
import flixel.system.ui.FlxSoundTray;
import uty.objects.OverworldCharacter;
import flixel.group.FlxGroup;
import flixel.util.FlxSort;
import funkin.states.PlayState;
import uty.components.PlayerData;

//parse the json from the ogmo export using AssetHelper.parseAsset ?

class Overworld extends FNFState
{
    public var curRoomName:String = "testLevel4";
    public var room:TiledRoom;
    public var player:Player;
    public var playerController:CharacterController;
    public var playerHitbox:PlayerHitbox;

    public var camGame:FlxCamera;
    public var camHUD:FlxCamera; //for dialogue, menus, transition screens, etc.
    public var camPoint:FlxObject;
    public var camBounds:FlxRect;
    //i'm just gonna make dialogue a single object in this state. 
    //there can only be one so it's probably better to reuse this object rather than spawn them spontaneously in other classes.
    public var dialogueBox:DialogueBox;
    public var dialogueParser:DialogueParser;
    //mainly for NPC parsing, i don't want NPCs in the room object but it makes sense to store them in the room file.
    public var roomParser:RoomParser;
    public var npcs:FlxTypedGroup<NPC>;
    public var followers:FlxTypedGroup<Follower>;
    public var followerController:CharacterController;
    public var foreground:Array<FlxSprite>;
    //for object draw order organization
    public var objectSorterGroup:FlxTypedGroup<FlxObject>;

    //just to save some constants to reduce the math in update()
    var centerWidth = FlxG.width / 2;
    var centerHeight = FlxG.height / 2;

    var roomTransitionTime:Float = 0.7;

    public static var pixelRatio:Int = 3; //scale all non-funkin state sprites by this value

    override function create()
    {
        super.create();

        //game camera
        camGame = new FlxCamera();
        camPoint = new FlxObject(0, 0);
        FlxG.cameras.reset(camGame);
        FlxG.cameras.setDefaultDrawTarget(camGame, true);
        //UI camera
        camHUD = new FlxCamera();
        camHUD.bgColor.alphaFloat = 0.0; //so we're not looking at a black screen
        FlxG.cameras.add(camHUD, false); //UI elements will need to be manually assigned to this camera with { object.cameras = [camHUD] }

        dialogueParser = new DialogueParser();
        
        
        //note: apparently you can just zoom the camera instead of resizing all the pixel sprites
        //maybe this is more efficient but the problem is you probably can't ever go above the pixel ratio in this state, idk though.

        load(curRoomName, 800, 300);
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        controlInputCall(); //checks for inputs
        debugInputCall();

        playerHitbox.updatePosition(); //move the hitbox with the player
        playerCollisionCheck();

        playerController.update();
        followerControllerUpdate();

        camGame.updateFollow();

        //debug
        //trace('clover position: x${player.x} y${player.y}');

        objectSorterGroup.sort((Order, a:FlxObject, b:FlxObject) -> FlxSort.byValues(FlxSort.ASCENDING, (a.y + a.height), (b.y + b.height)));
    }

    public function playerCollisionCheck()
    {
        //REGULAR COLLISION//
        if(room.collisionGrid.overlaps(playerHitbox, false, camGame))
        {
            //i wrote all this code to prevent "sticky walls" (diagonal into a wall wouldn't fully stop you)
            //but it's not working so i'm scrapping it for now
            playerController.previousPosition();

            /*
            var spr:FlxSprite = new FlxSprite(playerHitbox.prevPosition.x, playerHitbox.prevPosition.y);
            spr.makeGraphic(Std.int(playerHitbox.width), Std.int(playerHitbox.height), 0x34FE2424);

            //if the sprite overlaps on the X axis, roll back the X
            spr.x = playerHitbox.x;
            if(room.collisionGrid.overlaps(spr, false, camGame))
            {
                playerController.previousPosition(true, false);
            }
            spr.x = playerHitbox.prevPosition.x;

            //same with Y
            spr.y = playerHitbox.y;
            if(room.collisionGrid.overlaps(spr, false, camGame))
            {
                playerController.previousPosition(false, true);
            }
            */
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
        room.loadingZones.forEach(function(zone:LoadingZone)
        {
            if(zone.collision.checkOverlap(playerHitbox))
            {
                //go to the next room
                nextRoomTransition(zone.toRoom, zone.toX, zone.toY);
            }
        });
    }

    function load(roomName:String, playerX:Int, playerY:Int)
    {
        curRoomName = roomName;

        roomParser = new RoomParser(curRoomName);
        objectSorterGroup = new FlxTypedGroup<FlxObject>();
        npcs = new FlxTypedGroup<NPC>();
        followers = new FlxTypedGroup<Follower>();

        loadRoom(curRoomName);
        //note that players and npcs are add()ed to the object sorter group and not directly to the scene
        loadPlayer(playerX, playerY);
        loadNPCs(curRoomName);
        loadFollowers();
        //now we add the sorter
        add(objectSorterGroup);

        loadForeground();
        setCameraBounds(0, 0);
        camGame.follow(player);
    }

    function loadRoom(roomName:String)
    {
        room = new TiledRoom(roomName, "darkRuins_sheet");
        add(room);
    }

    function loadForeground()
    {
        foreground = roomParser.loadDecalLayer(roomParser.getDecalLayerByName("Foreground"));

        for(decal in foreground)
        {
            add(decal);
        }
    }

    function loadPlayer(x:Int, y:Int)
    {
        player = new Player("clover", x, y, 1);
        objectSorterGroup.add(player);

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
                i.x * 3,
                i.y * 3,
                i.values.facing,
                i.values.dialogue
            );
            npcs.add(newNPC);
            objectSorterGroup.add(newNPC);
        }
    }

    function loadFollowers()
    {
        //this needs to be based off of the player's save file.
        //for now though, i'll just force it in.
        //REPLACE THIS SHIT LATER
        var followerSave:Array<String> = new Array<String>();
        followerSave.push("ceroba");

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
            objectSorterGroup.add(follower);
        }

        followerController = new CharacterController(followers.members[0]);
    }

    function initialSorterAdd()
    {
        //should probably just add objects to the sorter instead of directly to the scene, then add the sorter
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
        trace("camera bounds are: " + camBounds.left + ", " + camBounds.top + " | " + camBounds.right + ", " + camBounds.bottom);

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

        if(Controls.UT_ACCEPT_P)
        {
            interactablesCheck();
        }
    }

    private function debugInputCall()
    {
        if(FlxG.keys.justPressed.SEVEN)
        {

            var tempSave:PlayerSave = {
                love: 1,
                health: 20,
                room: "testLevel4",
                posX: 200,
                posY: 200
            };


            PlayerData.savePlayerData(tempSave);
            var song:PlaySong = {
                name: "Martlet",
                folder: "martlet",
                difficulty: "hard"
            };
            initializeSongTransition(song);
        }
    }

    public function interactablesCheck()
    {
        //checks all interactables in the room, on npcs, and all relevant objects.

        //check for any regular interactables nearby
        room.interactables.forEach(function(i:Interactable)
        {
            if(i.collision.checkOverlap(playerHitbox))
            {
                player.lockMoveInput = true;
                dialogueParser.updateDialogueJson(i.dialogueJson);

                var diaGrp:DialogueGroup = dialogueParser.getDialogueFromCheckCount(i.checkCount);
                //increment AFTER we retrieve the dialogue
                i.checkIncrement();

                final dialogueSubstate:DialogueSubState = new DialogueSubState(diaGrp, camHUD);
                openSubState(dialogueSubstate);
                return;
            }
        });

        //check the NPCs too
        //i know this is shitty copied code... IDGAF!!!!!!
        //add a function where npcs turn to you when talking to them
        npcs.forEach(function(n:NPC)
        {
            if(n.interactable.collision.checkOverlap(playerHitbox) && n.interactable.areClicksReached(1))
            {
                player.lockMoveInput = true;
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
                    player.lockMoveInput = true;
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

    public function followerControllerUpdate()
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
        followerController.update();
        followerController.setMovingFromPoint(followers.members[0].calculateMoveInput());
        followerController.setRunning(followers.members[0].isRunningDistance());
    }

    //simply sorting by sprite Y doesn't really work when there's sprites of different sizes
    //im sorting based on the collision boxes here
    inline function sortOverworldCharacters(order:Int, a:OverworldCharacter, b:OverworldCharacter):Int
    {
        return Std.int((a.collision.y + a.collision.height) - (b.collision.y + b.collision.height));
    }

    public function nextRoomTransition(roomName:String, playerX:Int, playerY:Int)
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
		while (i != objectSorterGroup.members.length) {
			objectSorterGroup.members[i].destroy();
			i++;
		}

        objectSorterGroup.clear();
        npcs.clear();
        objectSorterGroup.destroy();
        npcs.destroy();
    }

    override function closeSubState():Void
    {
        //for allowing movement after dialogue boxes for now; may need to change
        if(player != null)    
            player.lockMoveInput = false;
        super.closeSubState();
    }

    public function setLockMoveInput(locked:Bool = true)
    {
        player.lockMoveInput = locked;
    }

    public function initializeSongTransition(song:PlaySong)
    {
        //bigass fuckin bandaid
        var black:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        black.camera = camHUD;
        add(black);

        var playerCenterScreenPoint:FlxPoint = new FlxPoint(
            player.x + (player.width / 2) + FlxG.camera.x,
            player.y + (player.height / 2) + FlxG.camera.y);

        final soulSubstate:SoulTransitionSubState = new SoulTransitionSubState(song, 
            playerCenterScreenPoint.x, playerCenterScreenPoint.y);
        soulSubstate.camera = camHUD;
        openSubState(soulSubstate);
    }
}
