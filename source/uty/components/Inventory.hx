package uty.components;

import openfl.display.IBitmapDrawable;
import uty.components.StoryData;

enum abstract ItemType(String) to String{
    var FOOD = "FOOD";
    var WEAPON = "WEAPON";
    var ARMOR = "ARMOR";
    var AMMO = "AMMO";
    var ACCE = "ACCE";
    var KEY = "KEY";
} 

typedef Item =
{
    name:String,
    abbreviation:String,
    info:String,
    type:String,
    stats:ItemStats
}

typedef ItemStats = {
    hp:Int, 
    at:Int, 
    df:Int, 
    inv:Int
}

typedef InventoryItems = {
    food:Array<Item>,
    weapon:Item,
    armor:Item,
    ammo:Item,
    acce:Item
}

//a static inventory class for managing the player's items and equipment.
//should be part of a larger static player info class.
class Inventory
{
    public static final _inventorySpace:Int = 8;

    public static function getActiveAT():Int
    {
        var at:Int = 0;
        at += StoryData.getActiveData().playerSave.inventory.weapon.stats.at ?? 0;
        at += StoryData.getActiveData().playerSave.inventory.ammo.stats.at ?? 0;
        return at;
    }

    public static function getActiveDF():Int
    {
        var df:Int = 0;
        df += StoryData.getActiveData().playerSave.inventory.armor.stats.df ?? 0;
        df += StoryData.getActiveData().playerSave.inventory.acce.stats.df ?? 0;
        return df;
    }

    public static function returnDefault():InventoryItems
    {
        var dummyInvt:InventoryItems = {
            food: [],
            weapon: getItemFromFile('ToyGun'),
            armor: getItemFromFile('WornHat'),
            ammo: getItemFromFile('RubberAmmo'),
            acce: getItemFromFile('Patch')
        }
        return dummyInvt;
    }

    public static function launderData(invt:InventoryItems):InventoryItems
    {
        var newInvt:InventoryItems = {
            food: invt.food,
            weapon: _launderItem(invt.weapon),
            armor: _launderItem(invt.armor),
            ammo: _launderItem(invt.ammo),
            acce: _launderItem(invt.acce)
        }
        return newInvt;
    }

    public static function getItemFromFile(file:String, ?folder:String):Item
    {
        //i don't know why but parsing yaml causes the game to not even load
        //"unsupported radix 10" whatever that means
        folder = (folder != null ? (folder + "/") : '');
        var dir = 'data/items/${folder}${file}';
        var itemData = AssetHelper.parseAsset(dir, YAML);
        var item:Item;
        if(itemData == null)
        {
            trace("ERROR: item yaml could not be found.");
            item = {
                name: "N/A",
                abbreviation: "N/A",
                info: "INVALID ITEM",
                type: FOOD,
                stats: {hp: 0, at: 0, df: 0, inv: 0}
            }
        }
        else item = {
            name: itemData.name,
            abbreviation: itemData.abbreviation,
            info: itemData.info,
            type: itemData.type,
            stats: itemData.stats
        };
        //trace(item);
        return item;
    }

    public static function addItemFromFile(file:String, ?folder:String)
    {
        return addItem(getItemFromFile(file, folder));
    }

    public static function addItem(item:Item):Bool
    {
        if(StoryData.getActiveData().playerSave.inventory.food.length >= _inventorySpace)
            return false;
        StoryData.getActiveData().playerSave.inventory.food.push(item);
        return true;
    }

    public static function removeItemByName(itemName:String):Null<Item>
    {
        for(i in 0...StoryData.getActiveData().playerSave.inventory.food.length)
        {
            if(StoryData.getActiveData().playerSave.inventory.food[i].name == itemName)
            {
                return removeItemAtIndex(i);
            }
        }
        return null;
    }

    public static function removeItemAtIndex(itemIndex:Int):Item
    {
        return StoryData.activeData.playerSave.inventory.food.splice(itemIndex, 0)[0]; //it's long isn't it
    }

    private static function _launderItem(item:Item):Item
    {
        var newItem = {
            name: item.name,
            abbreviation: item.abbreviation,
            info: item.info,
            type: item.type,
            stats: {
                hp: item.stats.hp,
                at: item.stats.at,
                df: item.stats.df,
                inv: item.stats.inv
            }
        };
        return newItem;
    }
}