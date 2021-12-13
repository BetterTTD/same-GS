require("version.nut");

class sameGSInfo extends GSInfo {
    function GetAuthor()        { return "same-f" ; }
    function GetName()          { return "same-GS"; }
    function GetDescription()   { return "TeamGame script for our game servers"; }
    function GetVersion()       { return SELF_VERSION; }
    function GetDate()          { return "2021-12-14"; }
    function CreateInstance()   { return "sameGS"; }
    function GetShortName()     { return "TGGS"; }
    function GetAPIVersion()    { return "1.12"; }
    function GetURL()           { return "https://github.com/same-f/same-GS"; }

    function GetSettings()      {
        AddSetting({ // loglevel
            name                = "LogLevel",
            description         = "Level of logging script",
            easy_value          = 0,
            medium_value        = 1,
            hard_value          = 2,
            custom_value        = 3,
            min_value           = 0,
            max_value           = 2,
            flags               = CONFIG_NONE | CONFIG_INGAME
        });
        AddLabels(
            "LogLevel", {0 = "Minimal", 1 = "Warnings", 2 = "INeedMoreLogs"}
        );
        
         AddSetting({ // servname
            name                = "ServerName",
            description         = "Init which one of servers",
            easy_value          = 0,
            medium_value        = 1,
            hard_value          = 2,
            custom_value        = 0,
            min_value           = 0,
            max_value           = 2,
            flags               = CONFIG_NONE | CONFIG_INGAME
        });
        AddLabels(
            "ServerName", {0 = "TG_Vanilla", 1 = "TG_Welcome", 2 = "TG_Public"}
        );

        // AddSetting({ // pause
            name                = "PauseOnReset",
            description         = "Set game on pause after reset or start",
            easy_value          = 0,
            medium_value        = 0,
            hard_value          = 0,
            custom_value        = 0,
            flags               = CONFIG_BOOLEAN | CONFIG_INGAME
        // });      
    }        
}

RegisterGS(sameGSInfo());