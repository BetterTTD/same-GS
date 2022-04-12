require("company.nut");
require("utility.nut");

class TeamDuude extends GSController {
		constructor() {
		}
}

function TeamDuude::Start() {
	this.Init();
	this.Sleep(1);
	while (true) {
		HandleEvents();
		this.Sleep(1);
	}
}

function TeamDuude::Init() {
	for (local i = 0; i < 15; i++)	{ CacheDuude.cargo_handle.AddItem(i, 0);	CacheDuude.vehicle[i] = GSList(); }
	local caching = CompanyDuude();
	caching = CacheDuude("companyDate", 0);
	caching = CacheDuude("supply_town", 0);
	caching = CacheDuude("supply_industry", 0);
	caching = CacheDuude("reward", 0);
	caching = CacheDuude("reward_balance", 0);
	caching = CacheDuude("gabriel", 0);
	CacheDuude.FindCargoUsage();
	
	CompanyDuude.Init();
	GSLog.Info("Welcome use page "+CompanyDuude.GetPageID(15,0));
	GSLog.Info("Rules use page "+CompanyDuude.GetPageID(16,0));
	GSLog.Info("Settings use page "+CompanyDuude.GetPageID(17,0));
	GSLog.Info("Stuff use page "+CompanyDuude.GetPageID(18,0));
	GSLog.Info("Links use page "+CompanyDuude.GetPageID(19,0));
	// GSLog.Info("Goals use page "+CompanyDuude.GetPageID(20,0));
	CacheDuude.GetSnowTown();
	local wait = 0 * 30 * 74
	wait = true;
	GSLog.Warning("Waiting companies...");
	while(wait)
		for ( local i = 0; i < 15; i++ ) {
			if (GSCompany.ResolveCompanyID(i) != GSCompany.COMPANY_INVALID) {
				CompanyDuude.StoryUpgrade();
				wait = false;
				GSLog.Warning("Company found.");
				break;
			}
		}
	// GSStoryPage.Show(CompanyDuude.GetPageID(15,0));
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
						CompanyDuude.Question(c);
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
						// local c = e.GetCompanyID();
						local b = e.GetButton();
						if (b == GSGoal.BUTTON_ACCEPT) {
							if (GSGoal.IsValidGoal(i)) {
								GSGoal.SetText(GSCompany.ResolveCompanyID(i), GSText(GSText.STR_ACCEPTED_RULES, i));
								GSGoal.SetCompleted(GSCompany.ResolveCompanyID(i), true);
								// GSStoryPage.Show(CompanyDuude.GetPageID(15, 0));
							}
						} else if (b == GSGoal.BUTTON_DECLINE) {
								TeamDuude.FeedTheDuude(i);
						} else {
							
						}
					}
					break;
			}
		}
	}

function TeamDuude::FeedTheDuude(i) {
	if (GSCompany.ResolveCompanyID(i) != GSCompany.COMPANY_INVALID) { 
		GSCompany.ChangeBankBalance(GSCompany.ResolveCompanyID(i), - GSCompany.GetBankBalance(GSCompany.ResolveCompanyID(i))*99, GSCompany.EXPENSES_OTHER, GSMap.TILE_INVALID);
			if (GSGoal.IsValidGoal(i)) {
				GSGoal.SetText(GSCompany.ResolveCompanyID(i), GSText(GSText.STR_DECLINED_RULES, i));
				GSGoal.SetCompleted(GSCompany.ResolveCompanyID(i), true);
			}
	}
}