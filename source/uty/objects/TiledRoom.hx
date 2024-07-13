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
import uty.objects.SavePoint;

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
    public var background:FlxTypedGroup<OverworldSprite>; //drawn the lowest, fractional scroll factor
    public var tilemaps:FlxTypedGroup<OverworldTilemap>;
    public var decals:FlxTypedGroup<OverworldSprite>; //regular decals with the same scroll factor as the tilemap
    public var foregroundTilemap:OverworldTilemap;
    public var foregroundDecals:FlxTypedGroup<OverworldSprite>;

    //collision
    public var collisionGrid:OverworldTilemap;

    //entities
    public var loadingZones:FlxTypedGroup<LoadingZone>;
    public var interactables:FlxTypedGroup<Interactable>;
    public var triggers:FlxTypedGroup<EventTrigger>;
    public var savePoint:SavePoint; //there's only gonna be at most one of these per room

    //the boundaries of the room
    public var roomBounds:FlxRect;

    public function new(roomName:String)
    {
        super();
        load(roomName);
    }

    public function load(roomName:String)
    {
        parser = new RoomParser(roomName);

        //add the collision grid before the sprites, i think black needs it to prevent null exception
        collisionGrid = parser.loadGridLayer("collision");
        add(collisionGrid);
        roomBounds = collisionGrid.getBounds();

        //sprite/tilemap setup
        black = new FlxSprite().makeGraphic(Std.int(roomBounds.width), Std.int(roomBounds.height), 0xFF000000);
        tilemaps = parser.loadAllTilemapLayers();
        background = parser.loadDecalLayer(parser.getDecalLayerByName("Background"));
        decals = parser.loadDecalLayer(parser.getDecalLayerByName("Decals"));
        foregroundTilemap = parser.initializeTilemap(parser.getTileLayerByName("foreground"));
        foregroundDecals = parser.loadDecalLayer(parser.getDecalLayerByName("Foreground"));

        //add the black backdrop
        //add(black);
        
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
                loadZone.values.toX * 3,
                loadZone.values.toY * 3
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

        var spData:Array<EntityData> = parser.getEntitiesByName("SavePoint"); //getting the first one in the case that there's 2+
        if(spData != null && spData.length >= 1) //if there's no save point in this room, then none will be set up
        {
            var s:EntityData = spData[0];
            savePoint = new SavePoint(
                s.x * 3,
                s.y * 3,
                Std.int(s.values.spawnX * 3),
                Std.int(s.values.spawnY * 3),
                s.values.pointName,
                s.values.skin,
                s.values.dialogue
            );
            savePoint.updateAnim('save');
        }
    }

    override public function destroy()
    {
        super.destroy();
    }
}