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
	CacheDuude.FindCargoUsage();
	local caching = CompanyDuude();
	caching = CacheDuude("companyDate", 0);
	caching = CacheDuude("supply_town", 0);
	caching = CacheDuude("supply_industry", 0);
	caching = CacheDuude("reward", 0);
	caching = CacheDuude("reward_balance", 0);
	caching = CacheDuude("gabriel", 0);
	CompanyDuude.Init();
	GSLog.Info("Welcome use page "+CompanyDuude.GetPageID(15,0));
	local wait = 0 * 30 * 74
	wait = true;
	while(wait)
		for ( local i = 0; i < 15; i++ ) {
			if (GSCompany.ResolveCompanyID(i) != GSCompany.COMPANY_INVALID) {
				wait = false;
				break;
			}
		}
	GSStoryPage.Show(CompanyDuude.GetPageID(15,0));
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
					GSLog.Warning("New company incoming " + GSCompany.GetName(c));
					CompanyDuude.NewCompany(c);
					GSStoryPage.Show(CompanyDuude.GetPageID(c, 0));
					break;
			}

		}
	}
}