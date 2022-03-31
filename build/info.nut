require("version.nut");

class SameGS extends GSInfo
{
    function GetAuthor()        { return "same-f" ; }
    function GetName()          { return "same-GS"; }
    function GetDescription()   { return "TeamGame script for our game servers"; }
    function GetVersion()       { return SELF_VERSION; }
    function GetDate()          { return "2021-12-14"; }
    function CreateInstance()   { return "sameGS"; }
    function GetShortName()     { return "s-GS"; }
    function GetAPIVersion()    { return "12.0"; }
    function GetURL()           { return "https://github.com/same-f/same-GS"; }
}

RegisterGS(SameGS());