require("version.nut");



class sameGS extends GSController
{
	_loaded_data = null;
	_loaded_from_version = null;
	_init_done = null;



	constructor()
	{
		this._init_done = false;
		this._loaded_data = null;
		this._loaded_from_version = null;
	}
}

function sameGS::Start()
{
	GSController.Sleep(1);
	local last_loop_date = GSDate.GetCurrentDate();
	while (true) {
		local loop_start_tick = GSController.GetTick();
		this.HandleEvents();
		local current_date = GSDate.GetCurrentDate();
		if (last_loop_date != null) {
			local year = GSDate.GetYear(current_date);
			local month = GSDate.GetMonth(current_date);
			if (year != GSDate.GetYear(last_loop_date)) {
				this.EndOfYear();
			}
			if (month != GSDate.GetMonth(last_loop_date)) {
				this.EndOfMonth();
			}
		}
		last_loop_date = current_date;
		local ticks_used = GSController.GetTick() - loop_start_tick;
		GSController.Sleep(10);
	}
}



function sameGS::Init()
{
	if (this._loaded_data != null) {
		} else {
	}
	this._init_done = true;
	this._loaded_data = null;
}



function sameGS::HandleEvents()
{
	if(GSEventController.IsEventWaiting()) {
		local ev = GSEventController.GetNextEvent();
		if (ev == null) return;
		local ev_type = ev.GetEventType();
		switch (ev_type) {
			case GSEvent.ET_COMPANY_NEW: {
				local company_event = GSEventCompanyNew.Convert(ev);
				local company_id = company_event.GetCompanyID();
				Story.ShowMessage(company_id, GSText(GSText.STR_MOTD, company_id));
				break;
			}
		}
	}
}