class TeamDuude extends GSInfo {
	function GetAuthor()			{ return "same-f"; }
	function GetName()				{ return "TeamDuude"; }
	function GetDescription()		{ return "Game script by TG_OTTD, and for TG_OTTD servers."; }
	function GetVersion()			{ return 3; }
	function MinVersionToLoad()		{ return 1; }
	function GetDate()				{ return "2022-14-07"; }
	function CreateInstance()		{ return "TeamDuude"; }
	function GetShortName()			{ return "DUUD"; }
	function GetAPIVersion()		{ return "12"; }
	function GetUrl()				{ return "https://github.com/TG-OpenTTD/same-GS"; }
	function GetSettings() {
		AddSetting({name = "serverName",
			description = "Set serverName for storyPages",
			easy_value = 1,
			medium_value = 1,
			hard_value = 1,
			custom_value = 1,
			min_value = 0,
			max_value = 3,
			flags = CONFIG_NONE
		});
		AddLabels("serverName", {_0 = "default server", _1 = "TG Vanilla server", _2 = "TG Welcome server", _3 = "TG Public server"});
	}
}
RegisterGS(TeamDuude());