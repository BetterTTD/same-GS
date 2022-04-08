class CompanyDuude {
    static cPage = [];
    static gElement = [];
    static cPoints = [];
    static cValue = [];
    static cGoal = [];
    constructor() { 
        for ( local i = 0; i < 21*3; i++ )  { cPage.push(-1); } 
        for ( local i = 0; i < 15; i++ )    { cValue.push(null); cPoints.push(-1); } 
        for ( local i = 0; i < 64; i++ )    { gElement.push(-1); } 
        for ( local i = 0; i < 15; i++ )  	{ cGoal.push(-1); } 
    }
    function GetPageID();
    function NewCompany();
    function Init();
    function StoryUpdate();
    function StoryUpgrade();
}

function CompanyDuude::SetValue(cID, value) {
	CompanyDuude.cValue[cID] = value;
}

function CompanyDuude::AddPoints(cID, points) {
	if (cID == null)	{ return; } // when we remove an award
	local value = CompanyDuude.cPoints[cID];
	if (value == -1)	{ value = 0; CompanyDuude.NewCompany(cID); }
	value += points;
	CompanyDuude.cPoints[cID] = value;
}

function CompanyDuude::RemovePoints(cID, points) {
	local value = CompanyDuude.cPoints[cID];
	if (value == -1)	{ value = 0; CompanyDuude.NewCompany(cID); }
	value -= points;
	if (value < 0)	{ value = 0; }
	CompanyDuude.cPoints[cID] = value;
}

function CompanyDuude::GetPageID(cID, opt) {
    if (cID > 21 || cID < 0)  { GSLog.Error("Error: can't set pageID - Bad Value" + cID); return -1; }
    local x = cID * 3;
    if (cID == 15 || cID > 16)            { opt = 0; }
    return CompanyDuude.cPage[x + opt];
}

function CompanyDuude::RemoveCompany(cID) {
	if (cID == -1)	{ return; }
	local x = cID * 3;
	for (local z = 0; z < 3; z++)	{
									local p = CompanyDuude.GetPageID(cID, z);
									GSStoryPage.Remove(p);
									CompanyDuude.cPage[x + z] = -1;
									}
	CompanyDuude.cValue[cID] = null;
	CompanyDuude.cPoints[cID] = -1;
	GSGoal.Remove(cID);
	CompanyDuude.cGoal[cID] = null;
	CacheDuude.SetData("companyDate", cID, 0);
	GSLog.Info("Removing company #"+cID);
	local cargo_list = GSCargoList();
	foreach (cargo, _ in cargo_list)
		{
		local label = GSCargo.GetCargoLabel(cargo);
		if (Utils.INArray(label, CacheDuude.cargo_tracker) != -1)	{ CacheDuude.SetData(label, cID, 0); } // reset tracked cargos
		}
}

function CompanyDuude::ValueReset(company) {
	CompanyDuude.cPoints[company] = 0;
	CacheDuude.cargo_handle.SetValue(company, 0);
	CacheDuude.vehicle[16] = 0; // force dirty vehicle cache
	CacheDuude.vehicle[15] = GSList(); // force dirty vehicle cache
	CacheDuude.vehicle[company] = GSList();
	CacheDuude.SetData("town_supply", company, 0);
	CacheDuude.SetData("industry_supply", company, 0);
	CacheDuude.SetData("reward", company, 0);
	CacheDuude.SetData("reward_balance", company, 0);
	CacheDuude.SetData("gabriel", company, 0);
}

function CompanyDuude::NewCompany(cID) {
    if (GSCompany.ResolveCompanyID(cID) == GSCompany.COMPANY_INVALID)    return;
    local x = cID * 3;
    if (!GSStoryPage.IsValidStoryPage(CompanyDuude.cPage[x+0])) {
        CompanyDuude.cPage[x+0] =  GSStoryPage.New(cID, GSText(GSText.STR_COMPANY_TITLE, cID));
    }
    local rnk = GSText(GSText.STR_RANK_COMPANY, GSCompany.ResolveCompanyID(cID)); //GSText(GSText.STR_RANK_COMPANY2));
	CompanyDuude.cPage[x + 1] = CompanyDuude.StoryUpdate(CompanyDuude.GetPageID(cID, 0), CompanyDuude.cPage[x +1], rnk);
			
	// 		local pID = CompanyDuude.GetPageID(cID, 0);
	// 		local eID = -1;
	// 		local txt = "blablabla";
	// 		local type = GSStoryPage.SPET_BUTTON_PUSH;
	// 		local ref = GSStoryPage.MakePushButtonReference(GSStoryPage.SPBC_LIGHT_BLUE, GSStoryPage.SPBF_NONE);			
	// 		if (GSStoryPage.IsValidStoryPageElement(eID)) {
    //     		eID = GSStoryPage.NewElement(pID, type, ref, txt);
    //     		if (eID == GSStoryPage.STORY_PAGE_ELEMENT_INVALID)  { return -1; }
    // 		}
    // CompanyDuude.cPage[x + 2] = GSStoryPage.UpdateElement(eID, ref, txt);
    
	// if (GSGame.IsMultiplayer()) {
	// 	GSGoal.Question(1, GSCompany.ResolveCompanyID(cID), "Hi. Do u read our rules of server?", GSGoal.QT_QUESTION, GSGoal.BUTTON_ACCEPT);
	// }
    // CompanyDuude.cPage[x + 1] = CompanyDuude.StoryUpdate(CompanyDuude.GetPageID(cID, 1), -1, " ");
    // if (!GSStoryPage.IsValidStoryPage(CompanyDuude.cPage[x+1])) {
    //     CompanyDuude.cPage[x+1] = GSStoryPage.New(cID, GSText(GSText.STR_PAGE_TITLE));
    // }
    // if (!GSStoryPage.IsValidStoryPage(CompanyDuude.cPage[x+2])) {
    //     CompanyDuude.cPage[x+2] = GSStoryPage.New(cID, GSText(GSText.STR_PAGE_TITLE));
    // }
    local logpage = " ";
    for (local p = 0; p < 3; p++)   { logpage+="-"+CompanyDuude.cPage[x+p]+" "; }
    GSLog.Info("Added company #"+cID+" "+GSCompany.GetName(cID)+" using pages "+logpage);
    if (CacheDuude.GetData("companyDate", cID) == 0)   { CacheDuude.SetData("companyDate", cID, GSDate.GetCurrentDate()); }
    CompanyDuude.ValueReset(cID);
    CacheDuude.Monitoring();
    // CompanyDuude.StoryUpgrade();
}

function CompanyDuude::Question(cID) {
	if (!GSGoal.IsValidGoal(GSCompany.ResolveCompanyID(cID))) {
		CompanyDuude.cGoal[cID] = GSGoal.New(GSCompany.COMPANY_INVALID, GSText(GSText.STR_QUESTION_RULES2, cID), GSGoal.GT_COMPANY, GSCompany.ResolveCompanyID(cID));
		if (GSGame.IsMultiplayer()) {
			local answer = GSGoal.Question(cID, GSCompany.ResolveCompanyID(cID), GSText(GSText.STR_QUESTION_RULES1), GSGoal.QT_INFORMATION, GSGoal.BUTTON_ACCEPT+GSGoal.BUTTON_DECLINE);
		}
		GSLog.Warning("Company asked about rules "+cID);
	}
}

function CompanyDuude::Init() {
    if (!GSStoryPage.IsValidStoryPage(CompanyDuude.GetPageID(15, 0))) {
    	CompanyDuude.cPage[15 * 3] = GSStoryPage.New(GSCompany.COMPANY_INVALID, GSText(GSText.STR_WELCOME_TITLE));
    }
    local serverName = GSController.GetSetting("serverName");
    if (serverName == 1)                { serverName = GSText(GSText.STR_SERVER_VANILLA, GSText(GSText.STR_VANILLA_AWARE)); }
    else if (serverName == 2)           { serverName = GSText(GSText.STR_SERVER_WELCOME, GSText(GSText.STR_WELCOME_AWARE)); }
    else if (serverName == 3)           { serverName = GSText(GSText.STR_SERVER_PUBLIC, GSText(GSText.STR_PUBLIC_AWARE)); }
    else                                { serverName = GSText(GSText.STR_SERVER_DEFAULT, GSText(GSText.STR_DEFAULT_AWARE)); }
    CompanyDuude.cPage[15 *3 + 1] = CompanyDuude.StoryUpdate(CompanyDuude.GetPageID(15, 0), CompanyDuude.cPage[15 * 3 +1], GSText(GSText.STR_WELCOME_WELCOME, serverName, GSText(GSText.STR_WELCOME_RULES)));
    CompanyDuude.cPage[15 *3 + 2] = CompanyDuude.StoryUpdate(CompanyDuude.GetPageID(15, 0), CompanyDuude.cPage[15 * 3 +2], GSText(GSText.STR_WELCOME_TEXT1, GSText(GSText.STR_WELCOME_TEXT2), GSText(GSText.STR_WELCOME_TEXT3)));

    if (!GSStoryPage.IsValidStoryPage(CompanyDuude.GetPageID(16, 0))) {
    	CompanyDuude.cPage[16 * 3] = GSStoryPage.New(GSCompany.COMPANY_INVALID, GSText(GSText.STR_RULES_TITLE));
    }
    CompanyDuude.cPage[16 *3 + 1] = CompanyDuude.StoryUpdate(CompanyDuude.GetPageID(16, 0), CompanyDuude.cPage[16 * 3 +1], GSText(GSText.STR_RULES_RULES, GSText(GSText.STR_RULES_STEALING), GSText(GSText.STR_RULES_TELEPORT)));
    CompanyDuude.cPage[16 *3 + 2] = CompanyDuude.StoryUpdate(CompanyDuude.GetPageID(16, 0), CompanyDuude.cPage[16 * 3 +2], GSText(GSText.STR_RULES_GRIDS, GSText(GSText.STR_RULES_CENTRAL), GSText(GSText.STR_RULES_FORBIDS)));

    if (!GSStoryPage.IsValidStoryPage(CompanyDuude.GetPageID(19, 0))) {
    	CompanyDuude.cPage[17 * 3] = GSStoryPage.New(GSCompany.COMPANY_INVALID, GSText(GSText.STR_SETTINGS_TITLE));
    }
	local starting_year = 0;
	if (GSGameSettings.IsValid("game_creation.starting_year")) { starting_year = GSGameSettings.GetValue("game_creation.starting_year"); }
    local restart_game_year = 0;
    local game_duration = 0;
	if (GSGameSettings.IsValid("network.restart_game_year")) {
		if (GSGameSettings.GetValue("network.restart_game_year") != 0) {
			restart_game_year = GSGameSettings.GetValue("network.restart_game_year");
			game_duration = GSText(GSText.STR_DUR_GAME, restart_game_year, restart_game_year-starting_year);
		} else {
			game_duration = GSText(GSText.STR_DUR_2GAME);
		}
	}
	local max_trains = 0;
	if (GSGameSettings.IsValid("vehicle.max_trains")) { max_trains = GSGameSettings.GetValue("vehicle.max_trains"); }
	local max_roadveh = 0;
	if (GSGameSettings.IsValid("vehicle.max_roadveh")) { max_roadveh = GSGameSettings.GetValue("vehicle.max_roadveh"); }
	local max_ships = 0;
	if (GSGameSettings.IsValid("vehicle.max_ships")) { max_ships = GSGameSettings.GetValue("vehicle.max_ships"); }
	local max_aircraft = 0;
	if (GSGameSettings.IsValid("vehicle.max_aircraft")) { max_aircraft = GSGameSettings.GetValue("vehicle.max_aircraft"); }
	CompanyDuude.cPage[17 *3 + 1] = CompanyDuude.StoryUpdate(CompanyDuude.GetPageID(17, 0), CompanyDuude.cPage[17 * 3 +1], GSText(GSText.STR_SETTINGS_SET1, starting_year, game_duration, GSText(GSText.STR_SETTINGS_SET2), max_roadveh, max_ships, max_aircraft, GSText(GSText.STR_SETTINGS_SET3), max_trains, GSText(GSText.STR_SETTINGS_SET4)));
    local max_bridge_length = 0;
	if (GSGameSettings.IsValid("construction.max_bridge_length")) { max_bridge_length = GSGameSettings.GetValue("construction.max_bridge_length"); }
	local max_tunnel_length = 0;
	if (GSGameSettings.IsValid("construction.max_tunnel_length")) { max_tunnel_length = GSGameSettings.GetValue("construction.max_tunnel_length"); }
	local station_spread = 0;
	if (GSGameSettings.IsValid("station.station_spread")) { station_spread = GSGameSettings.GetValue("station.station_spread"); }
	local max_loan = 0;
	if (GSGameSettings.IsValid("difficulty.max_loan")) { max_loan = GSGameSettings.GetValue("difficulty.max_loan"); }
	CompanyDuude.cPage[17 *3 + 2] = CompanyDuude.StoryUpdate(CompanyDuude.GetPageID(17, 0), CompanyDuude.cPage[17 * 3 +2], GSText(GSText.STR_SETTINGS_SET5, GSText(GSText.STR_SETTINGS_SET6), GSText(GSText.STR_SETTINGS_SET7), GSText(GSText.STR_SETTINGS_SET8), GSText(GSText.STR_SETTINGS_SET9), max_bridge_length, max_tunnel_length, station_spread, max_loan));

    if (!GSStoryPage.IsValidStoryPage(CompanyDuude.GetPageID(18, 0))) {
        CompanyDuude.cPage[18 * 3] = GSStoryPage.New(GSCompany.COMPANY_INVALID, GSText(GSText.STR_STUFF_TITLE));
    }
    CompanyDuude.cPage[18 *3 + 1] = CompanyDuude.StoryUpdate(CompanyDuude.GetPageID(18, 0), CompanyDuude.cPage[18 * 3 +1], GSText(GSText.STR_STUFF_SET1, GSText(GSText.STR_STUFF_SET2), GSText(GSText.STR_STUFF_SET3)));
    CompanyDuude.cPage[18 *3 + 2] = CompanyDuude.StoryUpdate(CompanyDuude.GetPageID(18, 0), CompanyDuude.cPage[18 * 3 +2], GSText(GSText.STR_STUFF_SET4, GSText(GSText.STR_STUFF_SET5), GSText(GSText.STR_STUFF_SET6)));

    if (!GSStoryPage.IsValidStoryPage(CompanyDuude.GetPageID(19, 0))) {
        CompanyDuude.cPage[19 * 3] = GSStoryPage.New(GSCompany.COMPANY_INVALID, GSText(GSText.STR_LINKS_TITLE));
    }
    CompanyDuude.cPage[19 *3 + 1] = CompanyDuude.StoryUpdate(CompanyDuude.GetPageID(19, 0), CompanyDuude.cPage[19 * 3 +1], GSText(GSText.STR_LINK_PRE));
    CompanyDuude.cPage[19 *3 + 2] = CompanyDuude.StoryUpdate(CompanyDuude.GetPageID(19, 0), CompanyDuude.cPage[19 * 3 +2], GSText(GSText.STR_LINK_TELEGRAM, GSText(GSText.STR_LINK_DISCORD), GSText(GSText.STR_LINK_WEB)));

	// if (!GSStoryPage.IsValidStoryPage(CompanyDuude.GetPageID(20, 0))) {
    //     CompanyDuude.cPage[20 * 3] = GSStoryPage.New(GSCompany.COMPANY_INVALID, GSText(GSText.STR_GOALS_TITLE));
    // }
    // CompanyDuude.cPage[20 *3 + 1] = CompanyDuude.StoryUpdate(CompanyDuude.GetPageID(20, 0), CompanyDuude.cPage[20 * 3 +1], GSText(GSText.STR_GOALS_PRE));
    // CompanyDuude.cPage[20 *3 + 2] = CompanyDuude.StoryUpdate(CompanyDuude.GetPageID(20, 0), CompanyDuude.cPage[20 * 3 +2], GSText(GSText.STR_GOALS_FIRST));

	// if (!GSGoal.IsValidGoal(1)) {
	// 	CompanyDuude.cGoal[1] = GSGoal.New(GSCompany.COMPANY_INVALID, "I READ THE RULES", GSGoal.GT_STORY_PAGE, CompanyDuude.GetPageID(16, 0));
	// }
	

    CompanyDuude.StoryUpgrade();
}

function CompanyDuude::StoryUpdate(pID, eID, txt, type = GSStoryPage.SPET_TEXT, ref = 0) {
    if (!GSStoryPage.IsValidStoryPageElement(eID)) {
        eID = GSStoryPage.NewElement(pID, type, 0, "TEXT");
        if (eID == GSStoryPage.STORY_PAGE_ELEMENT_INVALID)  { return -1; }
    }
    GSStoryPage.UpdateElement(eID, ref, txt);
    return eID;
}

function CompanyDuude::StoryUpgrade() {
	local rank = GSList();
	for (local i = 0; i < 15; i++)
		{
		rank.AddItem(i, CompanyDuude.cPoints[i]);
		}
	rank.Sort(GSList.SORT_BY_VALUE, GSList.SORT_DESCENDING);
	local counter = 0;
	local draw = -1;
	local result = [];
	local points = -1;
	foreach (cID, top in rank) {
		if (GSCompany.ResolveCompanyID(cID) == GSCompany.COMPANY_INVALID) {
			points = -1;
			CompanyDuude.cPoints[cID] = -1;
		} else {
			if (top == -1) {
				points = 0;
				CompanyDuude.cPoints[cID] = 0;
				CompanyDuude.NewCompany(cID);
		} else  { points = top; }
		}
    if (points != draw && points != -1)	{ counter++; draw = points; }
    local res = null;
    switch (counter) {
		case	1 :
			res = GSText(GSText.STR_GREEN);
			break;
		case	2:
			res = GSText(GSText.STR_YELLOW);
			break;
		case	3:
			res = GSText(GSText.STR_ORANGE);
			break;
		default:
			res = GSText(GSText.STR_RED);
	}
	if (points == -1) {
		res = " "; }
	else {
		res.AddParam(GSText(GSText.STR_RANK));
		res.AddParam(counter);
		res.AddParam(cID);
		res.AddParam(points);
	}
    result.push(res);
	}
	for (local i = 0; i < result.len(); i++) {
		GSStoryPage.UpdateElement(CompanyDuude.gElement[i], 0, result[i]);
		}
} 
