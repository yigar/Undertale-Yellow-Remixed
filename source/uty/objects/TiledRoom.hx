package uty.objects;

import flixel.tile.FlxTilemap;
import flixel.math.FlxRect;
import flixel.group.FlxGroup;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import uty.components.RoomParser;
import uty.objects.LoadingZone;
import uty.objects.Interactable;
import uty.objects.EventTrigger;
import uty.components.Collision;

/*
    stores tilemap info from room files.
    try to limit this to just the grid stuff. i.e. the tilemaps, collision grid, and maybe other game objects like interactables on signs.
    probably best for some stuff like backgrounds, NPCs, etc. to go in the overworld state, somewhere organized
*/
class TiledRoom extends FlxTypedGroup<FlxObject>
{
    var parser:RoomParser;

    //all map visuals
    public var black:FlxSprite;
    public var background:Array<FlxSprite>; //drawn the lowest, fractional scroll factor
    public var tilemaps:FlxTypedGroup<FlxTilemap>;
    public var decals:Array<FlxSprite>; //regular decals with the same scroll factor as the tilemap

    //collision
    public var collisionGrid:FlxTilemap;

    //entities
    public var loadingZones:FlxTypedGroup<LoadingZone>;
    public var interactables:FlxTypedGroup<Interactable>;
    public var triggers:FlxTypedGroup<EventTrigger>;

    //the boundaries of the room
    public var roomBounds:FlxRect;

    public function new(roomName:String, tilesheet:String)
    {
        super();
        load(roomName, tilesheet);
    }

    public function load(roomName:String, tilesheet:String)
    {
        parser = new RoomParser(roomName);

        //add the collision grid before the sprites, i think black needs it to prevent null exception
        collisionGrid = parser.loadGridLayer("collision");
        add(collisionGrid);
        roomBounds = collisionGrid.getBounds();

        //sprite/tilemap setup
        black = new FlxSprite().makeGraphic(Std.int(roomBounds.width), Std.int(roomBounds.height), 0xFF000000);
        tilemaps = parser.loadAllTilemapLayers(tilesheet);
        background = parser.loadDecalLayer(parser.getDecalLayerByName("Background"));
        decals = parser.loadDecalLayer(parser.getDecalLayerByName("Decals"));

        //add the black backdrop
        add(black);
        //then the background stuff
        for(decal in background)
        {
            add(decal);
        }
        //then the tilemap
        for(map in tilemaps.members)
        {
            add(map);
        }
        //then any decals on the map
        for(decal in decals)
        {
            add(decal);
        }
        
        //loads all loading zones/doorways
        loadingZones = new FlxTypedGroup<LoadingZone>();
        var loadZoneData:Array<EntityData> = parser.getEntitiesByName("LoadingZone");
        for (loadZone in loadZoneData)
        {
            var newZone:LoadingZone = new LoadingZone(
                loadZone.x * 3, //this is for pixel scale shit
                loadZone.y * 3,
                loadZone.width * 3,
                loadZone.height * 3,
                loadZone.values.toRoom,
                loadZone.values.toX,
                loadZone.values.toY
            );
            loadingZones.add(newZone);
            add(newZone);
        }
        //loads all interactables (stuff you can check)
        interactables = new FlxTypedGroup<Interactable>();
        var interactablesData:Array<EntityData> = parser.getEntitiesByName("Interactable");
        for(i in interactablesData)
        {
            var newInter:Interactable = new Interactable(
                i.x * 3,
                i.y * 3,
                i.width * 3,
                i.height * 3,
                i.values.dialogue
            );
            interactables.add(newInter);
            add(newInter);
        }

        //loads all event triggers
        triggers = new FlxTypedGroup<EventTrigger>();
        var triggerData:Array<EntityData> = parser.getEntitiesByName("EventTrigger");
        for(t in triggerData)
        {
            var newTrig:EventTrigger = new EventTrigger(
                t.x * 3,
                t.y * 3,
                t.width * 3,
                t.height * 3,
                t.values.script,
                t.values.isButton,
                t.values.useCount
            );
            triggers.add(newTrig);
            add(newTrig);
        }
    }

    override public function destroy()
    {
        super.destroy();
    }
}