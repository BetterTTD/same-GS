class CacheDuude {
    static cargo = GSList();
    static vehicle = array(17, -1);
    static snowtown = GSList();
    static powerplant = GSList();
    static cargo_handle = GSList();
    static cargo_town = GSList();
    static cargo_industry = GSList();
    static cargo_tracker = ["WOOD", "OIL_", "TOYS", "WATR", "GOOD", "DIAM"];
    static bigarray = [];
    static indexer = {};
	    id	= null;
    	index = null;
            constructor(strid, defvalue = 0) {
                this.id = strid;
                if (this.id in CacheDuude.indexer)	{ GSLog.Info(strid+" is already index"); return; }
                this.index = CacheDuude.bigarray.len();
                for (local i = 0; i < 15; i++)	{ CacheDuude.bigarray.push(defvalue); }
                GSLog.Info("New entry "+this.id+" at index "+this.index);
                CacheDuude.indexer[this.id] <- this;
            }
            function Resolver();
}

function CacheDuude::Resolver() {
    local comp = [];
    for (local r = 0; r < 15; r++) {
        local rc = GSCompany.ResolveCompanyID(r);
        if (rc != GSCompany.COMPANY_INVALID)    { comp.push(rc); }
    }
    return comp;
}

function CacheDuude::Vehicle_Helper_Counter(v_str)
{
	local vlist = CacheDuude.Vehicle_Helper();
	local company = CacheDuude.Company_Helper();
	local retvalue = GSList();
	for (local j = 0; j < 15; j++)	{ retvalue.AddItem(j, 0); }
	local v_type = null;
	foreach (comp in company)
		{
		local tl = GSList();
		tl.AddList(vlist[comp]);
		tl.Valuate(GSVehicle.GetVehicleType);
		if (v_str == "train" || v_str == "boat")
				{
				if (v_str == "train")	{ tl.KeepValue(GSVehicle.VT_RAIL); }
								else	{ tl.KeepValue(GSVehicle.VT_WATER); }
				}
		else	{ // air & road
				if (v_str == "bus" || v_str == "truck")
						{
						tl.KeepValue(GSVehicle.VT_ROAD);
						local pass = CacheDuude.GetPassengerCargo();
						local filter = GSList();
						foreach (veh, _ in tl)
							{
							filter.AddItem(veh, 0); // add as truck
							foreach (pcargo, _ in pass)
								{
								if (GSVehicle.GetCapacity(veh, pcargo) > 0)	{ filter.SetValue(veh, 1); }
								}
							}
						if (v_str == "bus")	{ filter.KeepValue(1); }
									else	{ filter.KeepValue(0); }
						tl.Clear();
						tl.AddList(filter);
						}
				else	{
						tl.KeepValue(GSVehicle.VT_AIR);
						local filter = GSList();
						foreach (veh, _ in tl)
							{
							filter.AddItem(veh, 0); // plane are 0
							local eng = GSVehicle.GetEngineType(veh);
							if (GSEngine.GetPlaneType(eng) == GSAirport.PT_HELICOPTER)	{ filter.SetValue(veh, 1); }
							}
						if (v_str == "aircraft")	{ filter.KeepValue(0); }
											else	{ filter.KeepValue(1); }
						tl.Clear();
						tl.AddList(filter);
						}
				}
		retvalue.SetValue(comp, tl.Count());
		}
	return retvalue;
}

function CacheDuude::GetPassengerCargo() {
	if (!CacheDuude.cargo.IsEmpty())	{ return CacheDuude.cargo; }
	local cargolist = GSCargoList();
	foreach (cargo, dummy in cargolist)
			{
			if (GSCargo.GetTownEffect(cargo) == GSCargo.TE_PASSENGERS) { CacheDuude.cargo.AddItem(cargo, 0); }
			}
	return CacheDuude.cargo;
}

function CacheDuude::GetSnowTown(addnew = false) {
	if (!CacheDuude.snowtown.IsEmpty() && !addnew)	{ return CacheDuude.snowtown; }
	local town_list = GSTownList();
	town_list.RemoveList(CacheDuude.snowtown);
	local terrain = GSTileList();
	foreach (town, _ in town_list)
		{
		terrain.Clear();
		local location = GSTown.GetLocation(town);
	    terrain.AddRectangle(location + GSMap.GetTileIndex(-8, -8), location + GSMap.GetTileIndex(8, 8));
		terrain.Valuate(GSTile.GetTerrainType);
		terrain.KeepValue(GSTile.TERRAIN_SNOW);
		if (!terrain.IsEmpty())	{
								CacheDuude.snowtown.AddItem(town, 0);
								}
		}
	return CacheDuude.snowtown;
}

function CacheDuude::GetPowerPlant(addnew = false)
{
	if (!CacheDuude.powerplant.IsEmpty() && !addnew && CacheDuude.powerplant.GetValue(0) != -1)	{ return CacheDuude.powerplant; }
	local cargolabel = ["COAL"];
	local cargo_list = GSCargoList();
	local energy_list = GSList();
	if (CacheDuude.powerplant.HasItem(0))	{ CacheDuude.powerplant.RemoveItem(0); }
	foreach (cargoid, _ in cargo_list)
		{
		local t_list = GSList();
		if (Utils.INArray(GSCargo.GetCargoLabel(cargoid), cargolabel) != -1)
			{
			t_list = GSIndustryList_CargoAccepting(cargoid);
			foreach (indID, _ in t_list)
				{
				CacheDuude.powerplant.AddItem(indID, cargoid);
				}
			}
		}
	if (CacheDuude.powerplant.IsEmpty())	{ CacheDuude.powerplant.AddItem(0, -1); }
	return CacheDuude.powerplant;
}

function CacheDuude::GetCompetitorStationAround(IndustryID)
{
	local comp_list = GSList();
	local counter=0;
	local place = GSIndustry.GetLocation(IndustryID);
	local radius = GSStation.GetCoverageRadius(GSStation.STATION_TRAIN);
	local tiles = GSTileList();
	local produce = GSTileList_IndustryAccepting(IndustryID, radius);
	local accept = GSTileList_IndustryProducing(IndustryID, radius);
	tiles.AddList(produce);
	tiles.AddList(accept);
	tiles.Valuate(GSTile.IsStationTile); // force keeping only station tile
	tiles.KeepValue(1);
	tiles.Valuate(GSStation.GetStationID);
	foreach (tile, stationID in tiles)
		{ // remove duplicate id
		if (!comp_list.HasItem(stationID))	{ comp_list.AddItem(stationID, GSStation.GetOwner(stationID)); }
		}
	return comp_list;
}

function CacheDuude::Infrastructure_helper(inftype)
{
	local comp_list = CacheDuude.Company_Helper();
	local ret = GSList();
	foreach (comp in comp_list)
		{
		local k = GSInfrastructure.GetInfrastructurePieceCount(comp, inftype);
		ret.AddItem(comp, k);
		}
	return ret;
}

function CacheDuude::FindCargoUsage()
{
	if (!CacheDuude.cargo_town.IsEmpty())	{ return; }
	local indtype_list = GSIndustryTypeList();
	foreach (item, value in indtype_list)
		{
        local cargolist = GSIndustryType.GetAcceptedCargo(item);
		foreach (cargo, _ in cargolist)
			{
			if (!CacheDuude.cargo_industry.HasItem(cargo))	{ CacheDuude.cargo_industry.AddItem(cargo, item); }
			}
		}
	local cargo_list = GSCargoList();
	CacheDuude.cargo_town.AddList(cargo_list);
	foreach (cargo, _ in cargo_list)
		{
		if (GSCargo.GetTownEffect(cargo) == GSCargo.TE_NONE)	{ CacheDuude.cargo_town.RemoveItem(cargo); }
		local label = GSCargo.GetCargoLabel(cargo);
		if (Utils.INArray(label, CacheDuude.cargo_tracker) != -1)	{ local entry = CacheDuude(label, 0); }
		}
	local o_str = [];
	foreach (cargo, _ in CacheDuude.cargo_town)	{ o_str.push(GSCargo.GetCargoLabel(cargo)); }
    //	GSLog.Info("Towns accept cargo : "+Utils.ArrayListToString(CacheDuude.cargo_town));
    GSLog.Info("Towns accept cargo : "+Utils.ArrayListToString(o_str));
	//GSLog.Info("Industries accept cargo : "+Utils.ArrayListToString(CacheDuude.cargo_industry));
	o_str = [];
	foreach (cargo, _ in CacheDuude.cargo_industry)	{ o_str.push(GSCargo.GetCargoLabel(cargo)); }
	GSLog.Info("Industries accept cargo : "+Utils.ArrayListToString(o_str));
}

function CacheDuude::Monitoring()
{
	local companies = CacheDuude.Company_Helper();
	local town_list = GSTownList();
	foreach (company in companies) // Insane loops !
		{
		local stown = CacheDuude.GetData("supply_town", company);
		if (stown < 1000000)
			{
			foreach (town, _ in town_list)
				{
				if (GSTown.GetRating(town, company) != 0)
					{
					foreach (cargo, _ in CacheDuude.cargo_town)
						{
						local z = GSCargoMonitor.GetTownDeliveryAmount(company, cargo, town, true);
						if (z > 0)	{
									local k = CacheDuude.cargo_handle.GetValue(company);
									k = (k | (1 << cargo));
									CacheDuude.cargo_handle.SetValue(company, k);
									}
						if (GSCargo.GetCargoLabel(cargo) == "GOOD") // special monitoring of good
							{
							local p = CacheDuude.GetData("GOOD", company);
							p += z;
							CacheDuude.SetData("GOOD", company, p);
							}
						stown += z;
						if (stown > 1000000)	{ GSCargoMonitor.GetTownDeliveryAmount(company, cargo, town, false); }
						CacheDuude.SetData("supply_town", company, stown);
						}
					}
				}
			}
		local sind = CacheDuude.GetData("supply_industry", company);
		if (sind < 1000000)
			{
			foreach (cargo, _ in CacheDuude.cargo_industry)
				{
				local ind_list = GSIndustryList_CargoAccepting(cargo);
				foreach (industry, iii in ind_list)
					{
					local z = GSCargoMonitor.GetIndustryDeliveryAmount(company, cargo, industry, true);
					if (z > 0)	{
								local k = CacheDuude.cargo_handle.GetValue(company);
								k = (k | (1 << cargo));
								CacheDuude.cargo_handle.SetValue(company, k);
								}
					local hh = GSCargo.GetCargoLabel(cargo);
					if (Utils.INArray(hh, CacheDuude.cargo_tracker) != -1)  // special monitoring of specific cargos
						{
						local p = CacheDuude.GetData(hh, company);
						p += z;
						CacheDuude.SetData(hh, company, p);
						}
					sind += z;
					if (sind > 1000000)	{ GSCargoMonitor.GetIndustryDeliveryAmount(company, cargo, industry, false); }
					CacheDuude.SetData("supply_industry", company, sind);
					}
				}
			}
		}
}

function CacheDuude::DeliveryAwardGeneric(number, comp)
{
	if (Awards.HaveAward(number, comp))	{ return; }
	local awd = Awards.Get(number);
	if (awd == false)	{ return; }
	local everyone = [];
	everyone.extend(awd.Own_By_Company);
	everyone.push(comp);
	Awards.GrantAward(number, everyone);
}

function CacheDuude::SetData(strID, companyID, data)
{
	if (!(strID in CacheDuude.indexer))	{ return -1; }
	local goal = CacheDuude.indexer[strID];
	CacheDuude.bigarray[goal.index + companyID] = data;
}

function CacheDuude::GetData(strID, companyID)
{
	if (!(strID in CacheDuude.indexer))	{ return -1; }
	local goal = CacheDuude.indexer[strID];
	return (CacheDuude.bigarray[goal.index + companyID]);
}

function CacheDuude::GetIndex(strID)
{
	if (!(strID in CacheDuude.indexer))	{ return -1; }
	local goal = CacheDuude.indexer[strID];
	return goal.index;
}

function CacheDuude::CalcCompanyValue(companyID)
{
	local cmode = GSCompanyMode(companyID);
	local value = GSCompany.GetBankBalance(companyID);
	value -= GSCompany.GetLoanAmount();
	local vlist = CacheDuude.Vehicle_Helper();
	vlist[companyID].Valuate(GSVehicle.GetCurrentValue);
	foreach (veh, price in vlist[companyID])	{ value += price; }
	return value;
}

function CacheDuude::Company_Helper()
{
	local company = [];
	for (local j = 0; j < 15; j++)
		{
		local c_idx = GSCompany.ResolveCompanyID(j);
		if (c_idx != GSCompany.COMPANY_INVALID)	{ company.push(c_idx); }
		}
	return company;
}

function CacheDuude::Vehicle_Helper()
{
	local d = CacheDuude.vehicle[16];
	local now = GSDate.GetCurrentDate();
	if ((now - d) < 10)	{ return CacheDuude.vehicle; }
	local vlist = GSVehicleList();
	vlist.Valuate(GSVehicle.GetOwner);
	CacheDuude.vehicle[15].Clear();
	CacheDuude.vehicle[15].AddList(vlist);
	for (local i = 0; i < 15; i++)
		{
		CacheDuude.vehicle[i].Clear();
		CacheDuude.vehicle[i].AddList(vlist);
		CacheDuude.vehicle[i].KeepValue(i);
		}
	CacheDuude.vehicle[16] = GSDate.GetCurrentDate();
	return CacheDuude.vehicle;
}

class Utils
{
	constructor()
	{
	}
}

function Utils::ArrayListToString(list)
{
	local ret = "[";
	local check = false;
	if (typeof(list) == "array")	{ check = (list.len() == 0); }
							else	{ check = list.IsEmpty(); }
	if (!check)
			{
			local contents = "";
			foreach (a, b in list)
				{
				if (contents != "") contents += ", ";
				if (b != -1)	contents += a + " = " + b;
				}
			ret += contents;
			}
	ret += "]";
	return ret;
}

function Utils::GSListToArray(list)
{
	local ar = [];
	foreach (item, value in list)	{ ar.push(item); ar.push(value); }
	return ar;
}

function Utils::ArrayToGSList(ar)
{
	local list = GSList();
	for (local i = 0; i < ar.len(); i++)
		{
		list.AddItem(i, i+1);
		i++;
		}
	return list;
}

function Utils::INArray(seek, data)
{
	foreach (item, value in data)	{ if (value == seek)	{ return item; } }
	return -1;
}
