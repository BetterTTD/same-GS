require("version.nut");

class sameGS extends GSController
{
	data			= null;
	last_date		= 0;
	sleeptime		= 74;
	firstrun		= true;
	from_save		= false;
	current_month		= 0;
	current_year		= 0;
	current_date		= 0;
	flow_days		= 0;
	last_month		= 0;
	log			= 0;

	constructor()
	{
		this.clients	= GSClientList();
		this.signlist	= GSList();
		this.companies	= GSList();
	}
}

function sameGS::Start()	{
	// Log("### ___ same-GS starts ___ ###");

	this.log		= GSController.GetSetting("LogLevel");
	if(this.from_save == false) {
		for(local id = 0; id < 4096; id++) {
			if(GSClient.ResolveClientID(id) != GSClient.CLIENT_INVALID) {
				this.clients.append( Client(id) );
			}
		}
		for(local id = 0; id < 16; id++) {
			if(GSCompany.ResolveCompanyID(id) != GSCompany.COMPANY_INVALID) {
				this.companies.append( Company(id) );
			}
		}
	}

	this.__pregs();
	this.__storyinit();

	while (true) {
		// this.__runner();
		this.Sleep(sleeptime);
	}
}

function sameGS::__runner()	{
	this.current_date	= GSDate.GetCurrentDate();
	this.current_month	= GSDate.GetMonth(this.current_date);
	// this.CheckEvents();
	
	if(this.current_date != this.last_date) {
		this.flow_days += (this.current_date - this.last_date);
	}
	
	this.last_date = this.current_date;

	if(this.flow_days >= 1) {
		this.flow_days = 0;
		this.__daycycle();
	}

	if(this.current_month == this.last_month) {
		return;
	}

	this.current_year = GSDate.GetYear(this.current_date);
	this.last_month = this.current_month;
	this.__monthcycle();

	if(this.current_month == 1) {
		this.__yearcycle();
	}
}

