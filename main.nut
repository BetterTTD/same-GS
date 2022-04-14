require("company.nut");
require("utility.nut");

class TeamDuude extends GSController {
	loadedgame = null;
	constructor() {
		loadedgame = null;
	}
}

function TeamDuude::Start() {
	this.Init(loadedgame);
	// this.Sleep(74);
	local loop = 0;
	while (true) {
		loop++;
		if ((loop % 10) == 0) {
			CheckAccept();
		}
		HandleEvents();
		this.Sleep(7);
	}
}

function TeamDuude::Init(loaded) {
	for (local i = 0; i < 15; i++) {
		// CacheDuude.cargo_handle.AddItem(i, 0);
		CacheDuude.vehicle[i] = GSList();
	}
	local caching = CompanyDuude();
	// CacheDuude.FindCargoUsage();
	local loadlimit = (loaded != null);
	if (loadlimit) {
		for (local i = 0; i < loaded.ccPage.len(); i++)	{ CompanyDuude.cPage[i] = loaded.ccPage[i]; }
		for (local i = 0; i < loaded.ccRank.len(); i++)	{ CompanyDuude.gElement[i] = loaded.ccRank[i]; }
		for (local i = 0; i < 15; i++)	{ CompanyDuude.NewCompany(i); }
		// GSLog.Info("savegame type="+typeof(loaded.element)+" datasize="+loaded.element.len());
		// for (local i = 0; i < loaded.bigdata.len(); i++)	{ CacheDuude.bigarray[i] = loaded.bigdata[i]; }
		local x = 0;
		local buff = [];
		}
	CompanyDuude.Init();
	GSLog.Info("Welcome use page " + CompanyDuude.GetPageID(15, 0));
	GSLog.Info("Rules use page " + CompanyDuude.GetPageID(16, 0));
	GSLog.Info("Settings use page " + CompanyDuude.GetPageID(17, 0));
	GSLog.Info("Stuff use page " + CompanyDuude.GetPageID(18, 0));
	GSLog.Info("Links use page " + CompanyDuude.GetPageID(19, 0));
	// GSLog.Info("Goals use page "+CompanyDuude.GetPageID(20,0));
	CacheDuude.GetSnowTown();
	local wait = 0 * 30 * 74
	wait = true;
	GSLog.Warning("Waiting companies...");
	while (wait) 
		for (local i = 0; i < 15; i++) {
			if (GSCompany.ResolveCompanyID(i) != GSCompany.COMPANY_INVALID) {
				CompanyDuude.StoryUpgrade();
				wait = false;
				GSLog.Warning("Company found.");
				break;
			}
		}
}

function TeamDuude::HandleEvents() {
	if (GSEventController.IsEventWaiting()) {
		local event = GSEventController.GetNextEvent();
		if (event == null) return;
		local eventType = event.GetEventType();
		switch (eventType) {
			case	GSEvent.ET_COMPANY_NEW: {
					local e = GSEventCompanyNew.Convert(event);
					local c = e.GetCompanyID();
					CompanyDuude.NewCompany(c);
					GSController.Sleep(7);
					CompanyDuude.Question(c);
					// if (!GSWindow.IsOpen(GSWindow.WC_GOAL_QUESTION, 0)) {
						// GSWindow.Highlight(GSWindow.WC_MAIN_TOOLBAR, 0, GSWindow.WID_TN_STORY, GSWindow.TC_WHITE);
					// }
					break;
					}

			case	GSEvent.ET_COMPANY_BANKRUPT: {
					local e = GSEventCompanyBankrupt.Convert(event);
					local c = e.GetCompanyID();
					CompanyDuude.RemoveCompany(c);
					GSLog.Warning("Bankrupt company removing " + GSCompany.GetName(c));
					break;
					}

			case	GSEvent.ET_GOAL_QUESTION_ANSWER: {
					local e = GSEventGoalQuestionAnswer.Convert(event);
					local i = e.GetUniqueID();
					local c = e.GetCompany();
					local b = e.GetButton();
					if (GSStoryPage.IsValidStoryPage(CompanyDuude.GetPageID(c, 0))) {
						CompanyDuude.gElement[i] = GSStoryPage.NewElement(CompanyDuude.GetPageID(c, 0), )
					}
					if (b == GSGoal.BUTTON_ACCEPT) {
						if (GSGoal.IsValidGoal(i)) {
							GSGoal.SetText(i, GSText(GSText.STR_ACCEPTED_RULES, c));
							GSGoal.SetCompleted(i, true);
						}
						if (GSGoal.IsValidGoal(CompanyDuude.GetGoalID(15))) {
							GSGoal.SetText(CompanyDuude.GetGoalID(15), GSText(GSText.STR_ACCEPTED_RULES, c));
							GSGoal.SetCompleted(CompanyDuude.GetGoalID(15), true);
						}
						GSStoryPage.Show(CompanyDuude.GetPageID(c, 0));
						GSLog.Warning("Company #" + c + " " + GSCompany.GetName(c) + " accepted rules");
					} else if (b == GSGoal.BUTTON_DECLINE) {
						TeamDuude.FeedTheDuude(c, i);
						GSLog.Warning("Company #" + c + " " + GSCompany.GetName(c) + " declined rules muahhhahaha");
					} else {
					}
					}
					break;
		}
	}
}

function TeamDuude::CheckAccept() {
}

function TeamDuude::FeedTheDuude(c, i) {
	if (GSCompany.ResolveCompanyID(c) != GSCompany.COMPANY_INVALID) {
		GSCompany.ChangeBankBalance(GSCompany.ResolveCompanyID(c), -GSCompany.GetBankBalance(GSCompany.ResolveCompanyID(c)) * 99, GSCompany.EXPENSES_OTHER, GSMap.TILE_INVALID);
		if (GSGoal.IsValidGoal(i)) {
			GSGoal.SetText(i, "Well... Try to survive");
			GSGoal.SetCompleted(i, true);
		}
		if (GSGoal.IsValidGoal(CompanyDuude.GetGoalID(15))) {
			GSGoal.SetText(CompanyDuude.GetGoalID(15), GSText(GSText.STR_DECLINED_RULES, c));
			GSGoal.SetCompleted(CompanyDuude.GetGoalID(15), true);
		}
	}
}

function TeamDuude::Load(version, data) {
	GSLog.Info("Loading savegame version "+version);
	loadedgame = data;
}

function TeamDuude::Save() {
	GSLog.Info("saving...");
	local table = {
		ccPage = null,
		ccRank = null,
	}
	table.ccPage = CompanyDuude.cPage;
	table.ccRank = CompanyDuude.gElement;
	return table;
}