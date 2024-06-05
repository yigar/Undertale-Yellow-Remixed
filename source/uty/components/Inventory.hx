package uty.components;

import openfl.display.IBitmapDrawable;

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
    stats:Stats
}

typedef Stats = {
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

//an inventory class for managing the player's items and equipment.
//should be part of a larger static player info class.
class Inventory
{
    public final _inventorySpace:Int = 8;

    public static final _defaultInventory:InventoryItems = {
        food: [],
        weapon: getItemFromFile('ToyGun'),
        armor: getItemFromFile('WornHat'),
        ammo: getItemFromFile('RubberAmmo'),
        acce: getItemFromFile('Patch')
    }

    public function new()
    {
        items = [];
        weapon = getItemFromFile('ToyGun');
        armor = getItemFromFile('WornHat');
        ammo = getItemFromFile('RubberAmmo');
        acce = getItemFromFile('Patch');
    }

    public static function getItemFromFile(file:String, ?folder:String):Item
    {
        //i don't know why but parsing yaml causes the game to not even load
        //"unsupported radix 10" whatever that means
        folder = (folder != null ? (folder + "/") : '');
        var dir = 'data/items/${folder}${file}';
        trace(dir);
        dir = 'data/items/ToyGun';
        var itemData = AssetHelper.parseAsset(dir, JSON);
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
        trace(item);
        return item;
    }

    public function addItemFromFile(file:String, ?folder:String)
    {
        return addItem(getItemFromFile(file, folder));
    }

    public function addItem(item:Item):Bool
    {
        if(items.length >= _inventorySpace)
            return false;

        items.push(item);
        return true;
    }

    public function removeItemByName(itemName:String):Null<Item>
    {
        for(i in 0...items.length)
        {
            if(items[i].name == itemName)
            {
                return removeItemAtIndex(i);
            }
        }
        return null;
    }

    public function removeItemAtIndex(itemIndex:Int):Item
    {
        return items.splice(itemIndex, 0)[0];
    }
}