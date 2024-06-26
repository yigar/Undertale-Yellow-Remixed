package uty.components;

import funkin.components.parsers.*;
import flixel.tile.FlxTilemap;
import flixel.group.FlxGroup;
import flixel.util.FlxSort;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import uty.states.Overworld;

class RoomParser
{
    //look i know it's probably stupid to not just import the ogmo addons
    //but i don't necessarily want to fuck with these addons for a game mod

    var json:LevelData;

    private static final _pixelRatio:Float = 3.0;
    private final _defaultRoom:String = "darkRuins_0";

    // **FILEPATHS**
    public static final _defaultDecalDirectory:String = 'images/overworld/decals/';

    public function new(?jsonFile:String)
    {
        if(jsonFile != null) 
            updateRoomJson(jsonFile);
    }

    public function updateRoomJson(jsonFile:String, ?folder:String = "")
    {
        if(folder == null) folder = "";
        if(folder != "") folder += "/";

        if(roomFileExists(folder + jsonFile))
            json = cast(AssetHelper.parseAsset('funkin/data/rooms/${folder}${jsonFile}', JSON));
        else
        {
            json = cast(AssetHelper.parseAsset('funkin/data/rooms/${_defaultRoom}', JSON));
        }
    }

    public function roomFileExists(filePath:String):Bool
    {
        return Tools.fileExists(AssetHelper.getPath('funkin/data/rooms/${filePath}', JSON));
    }
    
    public function getRoomValues():Dynamic
    {
        return json.values ?? {
            music: "none",
            ambience: "none"
        };
    }

    public function loadAllTilemapLayers():FlxTypedGroup<FlxTilemap>
    {
        //returns all tilemap layers from the json as tilemaps.
        //outside of creating them in the proper order, their distinctions are not really important because they're purely visual.
        //collision, entities, etc. are meant to be handled by grid layers and instance layers.

        var mapGroup:FlxTypedGroup<FlxTilemap> = new FlxTypedGroup<FlxTilemap>();
        //this reverse for-loop returns layers bottom to top, so the uppermost layers in the .json file are drawn on top.
        for(i in 0...json.layers.length)
        {
            var j = json.layers.length - 1 - i;
            if(Reflect.hasField(json.layers[j], "tileset"))
            {
                mapGroup.add(initializeTilemap(cast json.layers[j]));
            }
        }
        return mapGroup;
    }

    public function loadAllGridLayers():FlxTypedGroup<FlxTilemap>
    {
        var mapGroup:FlxTypedGroup<FlxTilemap> = new FlxTypedGroup<FlxTilemap>();
        for(i in 0...json.layers.length)
        {
            var j = json.layers.length - 1 - i;
            if(Reflect.hasField(json.layers[j], "grid"))
            {
                mapGroup.add(initializeTilemap(cast json.layers[j]));
            }
        }
        return mapGroup;
    }

    public function loadGridLayer(layerName:String):FlxTilemap
        {
            //loads a specific grid layer by name
            var map:FlxTilemap = new FlxTilemap();
            for(i in 0...json.layers.length)
            {
                var j = json.layers.length - 1 - i;
                if(Reflect.hasField(json.layers[j], "grid") && json.layers[j].name == layerName)
                {
                    map = initializeGridmap(cast json.layers[j]);
                }
            }
            return map;
        }

    //loading entities and retrieving entities are different
    public function loadAllEntities(callback:EntityData -> Void, ?layer:String = "entities")
    {
        for (entityLayer in getEntityLayers())
        {
            for (entity in entityLayer.entities)
                callback(entity);
        }
            
    }

    public function loadAllDecals(callback:DecalData -> Void, ?layer:String = "decals")
    {
        for (decalLayer in getDecalLayers())
        {
            for (decal in decalLayer.decals)
                callback(decal);
        }
            
    }

    //not sure if i really even need multiple entity layers... probably good to have this as a safecheck regardless.
    public function getEntityLayers():Array<EntityLayer>
    {
        //am i doing it right
        var entityLayers:Array<EntityLayer> = new Array<EntityLayer>();
        for(layer in json.layers)
        {
            if(Reflect.hasField(layer, "entities"))
            {
                entityLayers.push(cast layer);
            }
        }
        return entityLayers;
    }

    public function getAllEntities():Array<EntityData>
    {
        //flattens all entity layers into one array of entitydatas and returns it
        var entityList:Array<EntityData> = new Array<EntityData>();
        var layers:Array<EntityLayer> = getEntityLayers();
        for(layer in layers)
        {
            for(entity in layer.entities)
            {
                entityList.push(cast entity);
            }
        }
        return entityList;
    }

    public function getEntitiesByName(name:String, ?additionalValueField:String):Array<EntityData>
    {
        // will return an array of all entities with the provided name, and with a certain value field if provided
        // good for parsing types of entities into arrays and spawning them (like all the loading zones in a room)
        var typedEntities:Array<EntityData> = new Array<EntityData>();
        var entities:Array<EntityData> = getAllEntities(); //retrieve the entities
        for(entity in entities)
        {
            if(Reflect.hasField(entity, "name") && entity.name == name)
            {
                //if no special value is specified, just push the entity.
                //if a special value IS specified, check if it's there and only push the entity if it is.
                if(additionalValueField != null)
                {
                    if(Reflect.hasField(entity.values, additionalValueField))
                    {
                        typedEntities.push(entity);
                    }
                }
                else
                {
                    typedEntities.push(entity);
                }
                
            }
        }
        return typedEntities;
    }

    //from what I understand, decals are just sections of a map that are untiled and use png assets
    //e.g. the first room in undertale
    public function getDecalLayers():Array<DecalLayer>
    {
        var decalLayers:Array<DecalLayer> = new Array<DecalLayer>();
        for(layer in json.layers)
        {
            if(Reflect.hasField(layer, "decals"))
            {
                decalLayers.push(cast layer);
            }
        }
        return decalLayers;
    }

    public function getAllDecals():Array<DecalData>
    {
        //flattens all decal layers into one array of decaldatas and returns it
        var decalList:Array<DecalData> = new Array<DecalData>();
        var layers:Array<DecalLayer> = getDecalLayers();
        for(layer in layers)
        {
            for(decal in layer.decals)
            {
                decalList.push(cast decal);
            }
        }
        return decalList;
    }

    public function getDecalLayerByName(name:String):DecalLayer
    {
        var decalLayer:DecalLayer = null;
        for(layer in json.layers)
        {
            if(Reflect.hasField(layer, "decals")) //if it's a decal layer
            {
                if(Reflect.hasField(layer, "name") && layer.name == name) //if its name is correct
                {
                    decalLayer = cast layer;
                }
            }
        }
        if(decalLayer == null) trace ("RoomParser 207: decalLayer is null");
        return decalLayer;
    }

    public function initializeTilemap(layer:TileLayer):FlxTilemap
    {
        if(!Reflect.hasField(layer, "tileset"))
        {
            trace("ERROR: layer is not a tilemap");
            return new FlxTilemap();
        }
        

        //NOTE: THE NAME OF THE TILESET IN OGMO HAS TO BE EXACTLY THE SAME AS THE TILESHEET FILE.
        var graphic = null;
        graphic = AssetHelper.getAsset('images/overworld/tile/${layer.tileset}', IMAGE);
        if(graphic == null) //backup
            graphic = AssetHelper.getAsset('images/overworld/tile/darkRuins_sheet', IMAGE);

        var tilemap:FlxTilemap = new FlxTilemap();

        tilemap.loadMapFromArray(
            layer.data,
            layer.gridCellsX,
            layer.gridCellsY,
            graphic,
            layer.gridCellWidth,
            layer.gridCellHeight
        );
        
        tilemap.antialiasing = false;
        var pixelScale = Overworld.pixelRatio;
        tilemap.scale.set(pixelScale, pixelScale);

        return tilemap;
    }

    public function initializeGridmap(layer:GridLayer):FlxTilemap
    {
        if(!Reflect.hasField(layer, "grid"))
            {
                trace("ERROR: layer is not a gridmap");
                return new FlxTilemap();
            }
            
            var gridmap:FlxTilemap = new FlxTilemap();

            //kind of annoying that ogmo saves this as strings but whatever
            var csv:Array<Int> = new Array<Int>();
            for(i in layer.grid)
            {
                csv.push(Std.parseInt(i));
            }
            //and i guess you need a graphic too
            var graphic = AssetHelper.getAsset('images/overworld/tile/empty_grid', IMAGE);
            //the loadMapFromCSV doesn't work but this one does... just don't question it
            gridmap.loadMapFromArray(
                csv,
                layer.gridCellsX,
                layer.gridCellsY,
                graphic,
                layer.gridCellWidth,
                layer.gridCellHeight
            );
            
            gridmap.antialiasing = false;
            var pixelScale = Overworld.pixelRatio;
            gridmap.scale.set(pixelScale, pixelScale);
    
            return gridmap;
    }

    public function loadDecalLayer(layer:DecalLayer):Array<FlxSprite>
    {
        var decalGrp:Array<FlxSprite> = new Array<FlxSprite>();

        var lowestHeight:Int = 9999;
        var lowestDecalIndex:Int = 0;

        //stores the draw heights into an array for optimization
        var drawHeightArray:Array<Int> = new Array<Int>(); 
        for (decal in layer.decals)
        {
            var h:Int = 0;
            if(Reflect.hasField(decal, "values") && Reflect.hasField(decal.values, "drawHeight")) //if this decal has a valid drawHeight value
            {
                h = decal.values.drawHeight;
            }
            drawHeightArray.push(h);
        }

        //adds decals to decalGrp in order of least to greatest height
        while(layer.decals.length > 0 && drawHeightArray.length > 0) //run this until everything is sorted
        {
            for(i in 0...drawHeightArray.length)
            {
                if(drawHeightArray[i] <= lowestHeight)
                {
                    //this is the new lowest decal
                    lowestDecalIndex = i; 
                    lowestHeight = drawHeightArray[i];
                }
            }
            //now we add the lowest decal to the sprite array and check it off the list
            decalGrp.push(loadDecal(layer.decals[lowestDecalIndex]));
            layer.decals.splice(lowestDecalIndex, 1);
            drawHeightArray.splice(lowestDecalIndex, 1);
            lowestHeight = 9999;
        }

        return decalGrp;
    }

    public function loadDecal(decal:DecalData):FlxSprite
    {
        var sprite:FlxSprite = new FlxSprite(0, 0, AssetHelper.getAsset(_defaultDecalDirectory + decal.texture, IMAGE));
        sprite.x = decal.x * _pixelRatio;
        sprite.y = decal.y * _pixelRatio;

        //set anything relevant in the values field
        if(Reflect.hasField(decal, "values"))
        {
            //scrollFactor
            if((Reflect.hasField(decal.values, "scrollFactorX") && decal.values.scrollFactorX != null) &&
                (Reflect.hasField(decal.values, "scrollFactorY") && decal.values.scrollFactorY != null))
            {
                sprite.scrollFactor.set(decal.values.scrollFactorX, decal.values.scrollFactorY);
            }
            //animated. only do this stuff if the variable exists and is true.
            if(Reflect.hasField(decal.values, "animated") && decal.values.animated)
            {
                sprite.frames = AssetHelper.getAsset(_defaultDecalDirectory + decal.texture, ATLAS);
                //not gonna make a very modular animation system for decals right now
                //if they have an animation, it plays on loop. that's it.
                sprite.animation.addByPrefix("anim", "anim", 
                    (Reflect.hasField(decal.values, "frameRate") && decal.values.frameRate != null) ?
                        decal.values.frameRate : 12, true);
            }
        }
        
        sprite.setGraphicSize(Std.int(sprite.width * _pixelRatio));
        sprite.updateHitbox();
        sprite.antialiasing = false;

        return sprite;
    }
}

//imported from ogmoLoader lol

typedef LevelData =
{
	width:Int,
	height:Int,
	offsetX:Int,
	offsetY:Int,
	layers:Array<LayerData>,
	?values:Dynamic,
}

/**
 * Level Layer data
 */
typedef LayerData =
{
	name:String,
	_eid:String,
	offsetX:Int,
	offsetY:Int,
	gridCellWidth:Int,
	gridCellHeight:Int,
	gridCellsX:Int,
	gridCellsY:Int,
	?entities:Array<EntityData>,
	?decals:Array<DecalData>,
	?tileset:String,
	?data:Array<Int>,
	?data2D:Array<Array<Int>>,
	?dataCSV:String,
	?exportMode:Int,
	?arrayMode:Int,
}

/**
 * Tile subset of LayerData
 */
typedef TileLayer =
{
	name:String,
	_eid:String,
	offsetX:Int,
	offsetY:Int,
	gridCellWidth:Int,
	gridCellHeight:Int,
	gridCellsX:Int,
	gridCellsY:Int,
	tileset:String,
	exportMode:Int,
	arrayMode:Int,
	?data:Array<Int>,
	?tileFlags:Array<Int>,
	?data2D:Array<Array<Int>>,
	?tileFlags2D:Array<Array<Int>>,
	?dataCSV:String,
	?dataCoords:Array<Array<Int>>,
	?dataCoords2D:Array<Array<Array<Int>>>,
}

/**
 * Grid subset of LayerData
 */
typedef GridLayer =
{
	name:String,
	_eid:String,
	offsetX:Int,
	offsetY:Int,
	gridCellWidth:Int,
	gridCellHeight:Int,
	gridCellsX:Int,
	gridCellsY:Int,
	arrayMode:Int,
	?grid:Array<String>,
	?grid2D:Array<Array<String>>,
}

/**
 * Entity subset of LayerData
 */
typedef EntityLayer =
{
	name:String,
	_eid:String,
	offsetX:Int,
	offsetY:Int,
	gridCellWidth:Int,
	gridCellHeight:Int,
	gridCellsX:Int,
	gridCellsY:Int,
	entities:Array<EntityData>,
}

/**
 * Individual Entity data
 */
typedef EntityData =
{
	name:String,
	id:Int,
	_eid:String,
	x:Int,
	y:Int,
	?width:Int,
	?height:Int,
	?originX:Int,
	?originY:Int,
	?rotation:Float,
	?flippedX:Bool,
	?flippedY:Bool,
	?nodes:Array<{x:Float, y:Float}>,
	?values:Dynamic,
}

/**
 * Decal subset of LayerData
 */
typedef DecalLayer =
{
	name:String,
	_eid:String,
	offsetX:Int,
	offsetY:Int,
	gridCellWidth:Int,
	gridCellHeight:Int,
	gridCellsX:Int,
	gridCellsY:Int,
	decals:Array<DecalData>,
}

/**
 * Individual Decal data
 */
typedef DecalData =
{
	x:Int,
	y:Int,
	texture:String,
	?scaleX:Float,
	?scaleY:Float,
	?rotation:Float,
    ?values:DecalValues
}

//a typedef for storing additional values assigned to the decal in Ogmo.
//typically for use in converting the decal to an FlxSprite (for instance, scroll factors for background decals)
typedef DecalValues = 
{
    drawHeight:Int,
    ?scrollFactorX:Float,
    ?scrollFactorY:Float,
    ?animated:Bool,
    ?frameRate:Int
}