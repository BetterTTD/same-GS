class FMainClass extends GSInfo
{
    function GetAuthor()        { return "same-f" ; }
    function GetName()          { return "same-GS"; }
    function GetDescription()   { return "TeamGame script for our game servers"; }
    function GetVersion()       { return SELF_VERSION; }
    function GetDate()          { return "2022-03-14-31"; }
    function CreateInstance()   { return "sameGS"; }
    function GetShortName()     { return "s-GS"; }
    function GetAPIVersion()    { return "1.2"; }
    function GetURL()           { return "https://github.com/same-f/same-GS"; }
}
RegisterGS(FMainClass());