package funkin.objects.play;

import funkin.states.PlayState;

enum abstract AllyName(String) to String {
    var NONE = "";
    var CEROBA = "ceroba";
}

typedef AllyData = 
{
    name:AllyName,
    icon:String
}

class Ally 
{
    public var data:AllyData;

    public function new(name:AllyName, ?icon:String = "ceroba")
    {
        data = {
            name: name, 
            icon: icon
        };

        allyFunction();
    }

    //behavior that plays when the ally is created; typically affects the playstate.
    public function allyFunction()
    {
        switch (data.name)
        {
            case CEROBA:
            {
                PlayState.current.enableCerobaShield();
            }
            default:
            {
                
            }
        }
    }
}