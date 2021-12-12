require("version.nut");

class sameGSInfo extends GSInfo {
    function GetAuthor()        { return "same-f" ; }
    function GetName()          { return "same-GS"; }
    function GetDescription()   { return "TeamGame script for our game servers"; }
    function GetVersion()       { return SELF_VERSION; }
    function GetDate()          { return "2021-12-12"; }
    function CreateInstance()   { return "sameGS"; }
    function GetShortName()     { return "TGGS"; }
    function GetAPIVersion()    { return "1.2"; }
    function GetURL()           { return "https://github.com/same-f/same-GS"; }

    function GetSettings()      {
        AddSetting({
            name                = "LogLevel",
            description         = "Level of logging script",
            easy_value          = 0,
            medium_value        = 0,
            hard_value          = 0,
            custom_value        = 0,
            min_value           = 0,
            max_value           = 2,
            flags               = CONFIG_NONE | CONFIG_INGAME
        });
        AddLabels(
            "LogLevel", {__0 = "Minimal", __1 = "Warnings", __2 = "INeedMoreLogs"}
        );


    }        
}

RegisterGS(sameGSInfo());