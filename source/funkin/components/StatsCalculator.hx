package funkin.components;

import flixel.math.FlxMath;

//a class that contains gameplay mechanic functions, particularly in regards to damage calculations.
class StatsCalculator
{
    //compares the player's AT and the enemy's DF, returns how much health should be restored.
    //enemies with significantly higher DF than the player's AT will impede health recovery significantly.
    public static function calculateRecoverHP(playerAT:Int, enemyDF:Int):Float
    {
        var dif:Int = playerAT - enemyDF;
        //when they are equal, restore 1 HP.
        if(dif == 0) return 1;
        //when the player's AT is higher, return 1+ HP (decreases exponentially, capping off at around 4.)
        if(dif > 0)
        {
            return Math.pow(((2.5 * dif) + 2) / (dif + 2), 1.5);
        }
        //when the enemy's DF is higher, the difference determines how many notes it takes to restore 1 HP.
        else if(dif < 0)
        {
            dif = -dif;
            return 1/(dif + 1);
        }
        else return 0;
    }

    public static function calculateDamage(enemyAT:Int, playerDF:Int, maxHP:Int):Int
    {
        //player takes +1 damage after max HP is greater than 20, and +1 more for every increment of +10 HP. (21, 30, 40, 50...)
        var hpDamageBonus:Int = Math.floor(maxHP / 10) - 1;
		if(maxHP <= 20) hpDamageBonus = 0;

		var damage:Int = enemyAT - playerDF + hpDamageBonus;
        if(damage <= 1) damage = 1;
        return damage;
    }
}