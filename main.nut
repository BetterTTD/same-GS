
require("version.nut"); // get SELF_VERSION

class MainClass extends GSController {
  constructor() {
    this._init_done = false;
    this._loaded_data = null;
    this._loaded_from_version = null;
  }
}

function MainClass::Start() {
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
        GSController.Sleep(max(1, 5 * 74 - ticks_used));
    }
}

function MainClass::Init() {
    if (this._loaded_data != null) {
    }
    else {
    }
    this._init_done = true;
    this._loaded_data = null;
}

function MainClass::HandleEvents() {
    if(GSEventController.IsEventWaiting()) {
        local ev = GSEventController.GetNextEvent();
        if (ev == null) return;

        local ev_type = ev.GetEventType();
        switch (ev_type) {
            case GSEvent.ET_COMPANY_NEW: {
                local company_event = GSEventCompanyNew.Convert(ev);
                local company_id = "255";
                Story.ShowMessage(company_id, GSText(GSText.STR_MOTD, company_id));
                break;
            }
        }
    }
}