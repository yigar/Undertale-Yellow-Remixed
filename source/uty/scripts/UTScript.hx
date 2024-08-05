package uty.scripts;

import forever.core.scripting.HScript;

//a custom script class that comes with common classes for convenience.
class UTScript extends HScript
{
    public function new(file:String, ?localPath:String = null)
    {
        super(file, localPath);
    }

    override function preset():Void
    {
        super.preset();

        //playstate functionality
        set("PlayState", funkin.states.PlayState);
        set("PlaySong", funkin.states.PlayState.PlaySong);
        //overworld functionality
        set("Overworld", uty.states.Overworld);
        set("OverworldCharacter", uty.objects.OverworldCharacter);
        set("DialogueSubState", uty.substates.DialogueSubState);
        set("DialogueGroup", uty.components.DialogueParser);
        //game data/save manipulation
        set("StoryData", uty.components.StoryData);
        set("StoryUtil", uty.components.StoryData.StoryUtil);
        set("StoryProgress", uty.components.StoryData.StoryProgress);
    }
}