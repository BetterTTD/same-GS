/*
 * This file is part of SuperLib, which is an AI Library for OpenTTD
 * Copyright (C) 2010  Leif Linse
 *
 * SuperLib is free software; you can redistribute it and/or modify it 
 * under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * SuperLib is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with SuperLib; If not, see <http://www.gnu.org/licenses/> or
 * write to the Free Software Foundation, Inc., 51 Franklin Street, 
 * Fifth Floor, Boston, MA 02110-1301 USA.
 *
 */

class _SuperLib_Station
{
	/*
	 * In pax-link mode, potential rail tiles used to reserve slots for
	 * bus stops adjacent to the airport will be removed.
	 *
	 * It is possible that in the future the pax_link_mode gets removed 
	 * as it is really to specific to be in a library.
	 */
	static function DemolishStation(station_id, pax_link_mode = false);

	/*
	 * Returns an GSList with all "front" tiles of all bus/truck stops
	 */
	static function GetRoadFrontTiles(station_id);

	static function IsStation(tile, station_id);

	//////////////////////////////////////////////////////////////////////
	//                                                                  //
	//  Coverage                                                        //
	//                                                                  //
	//////////////////////////////////////////////////////////////////////

	/* Get the largest coverage radius of the sub station types available at
	 * the station. 
	 */
	static function GetMaxCoverageRadius(station_id);

	/* Get a GSTileList containing the tiles that make up the coverage area
	 * with respect of the station acceptance
	 */
	static function GetAcceptanceCoverageTiles(station_id);

	/* Get a GSTileList containing the tiles that make up the coverage area
	 * with respect of the station supply
	 */
	static function GetSupplyCoverageTiles(station_id);

	/* Does the given station accept the given cargo? */
	static function IsCargoAccepted(station_id, cargo_id);

	/* Check if the given station have a coverage that intersects with the given industry
	 * to the extent that the station can accept the given cargo (and deliver
	 * it to the industry)
	 */
	static function IsCargoAcceptedByIndustry(station_id, cargo_id, industry_id);

	/* Does the given station cover enough producing tiles to supply it with the given
	 * cargo?
	 */
	static function IsCargoSupplied(station_id, cargo_id);
	static function IsCargoSuppliedByIndustry(station_id, cargo_id, industry_id);

	/*
	 * Returns the cost to demolish a given station
	 */
	static function CostToDemolishStation(station_id);


	/*
	 * Known limitation: if a different industry is closer than industry_id,
	 * IsCargoAcceptedByIndustry may return a false positive.
	 */


	//////////////////////////////////////////////////////////////////////
	//                                                                  //
	//  Vehicle related                                                 //
	//                                                                  //
	//////////////////////////////////////////////////////////////////////

	static function GetStationTypeOfVehicle(veh_id);

	static function GetListOfVehiclesAtStation(stationId);
}

/*static*/ function _SuperLib_Station::CostToDemolishStation(station_id)
{
	local station_tiles = GSTileList_StationType(station_id, GSStation.STATION_ANY);

	local cost_to_clear = _SuperLib_Tile.CostToClearTiles(station_tiles);
	return cost_to_clear;
}

/*static*/ function _SuperLib_Station::DemolishStation(station_id, pax_link_mode = false)
{
	local station_tiles = GSTileList_StationType(station_id, GSStation.STATION_ANY);
	local succeeded = true;

	foreach(tile, _ in station_tiles)
	{
		if(GSRoad.IsRoadStationTile(tile))
		{
			local front = GSRoad.GetRoadStationFrontTile(tile);

			// Delay demolishing if there is a vehicle on a road stop
			local tile_rect = GSTileList();
			tile_rect.AddRectangle(tile, front);
			if(_SuperLib_Vehicle.HasTileListVehiclesOnIt(tile_rect, GSVehicle.VT_ROAD))
			{
				_SuperLib_Log.Warning("bus stop has vehicles on it (or own vehicle in front) => delay destruction of station", _SuperLib_Log.LVL_DEBUG);

				GSController.Sleep(10);
			}

			local dtrs = GSRoad.IsDriveThroughRoadStationTile(tile);
			local back_tile = dtrs? GSRoad.GetDriveThroughBackTile(tile) : null;

			local day_start = GSDate.GetCurrentDate();
			while(!GSRoad.RemoveRoadStation(tile) && GSError.GetLastError() == GSError.ERR_VEHICLE_IN_THE_WAY && GSDate.GetCurrentDate() - day_start < 20);
			// Only remove the road, if the road station was removed
			day_start = GSDate.GetCurrentDate();
			if(!GSRoad.IsRoadStationTile(tile))
			{
				local remove_list = [{from=tile, to=front}];
				if(dtrs)
					remove_list.append({from=tile, to=back_tile});

				foreach(remove in remove_list)
				{
					local remove_from = remove.from;
					local remove_to = remove.to;

					// Example
					//
					// x------x------x------x
					// | from | to   |  X   |
					// |      |      |      |
					// x------x------x------x
					//
					// if to tile have road that is connected with X,
					// only remove to the center of to, otherwise,
					// use the full remove. Otherwise if [to] is sloped,
					// a road bit may be left at the far end of [to] (in relation
					// to [from])
					local remove_to_center = GSRoad.AreRoadTilesConnected(remove_to,
							_SuperLib_Direction.GetAdjacentTileInDirection(remove_to, 
								_SuperLib_Direction.GetDirectionToTile(remove_from, remove_to)));

					local remove_func = remove_to_center? GSRoad.RemoveRoad : GSRoad.RemoveRoadFull;
					while(!remove_func(remove_from, remove_to) && GSError.GetLastError() == GSError.ERR_VEHICLE_IN_THE_WAY && GSDate.GetCurrentDate() - day_start < 5);
				}
			}
			_SuperLib_Log.Info("Whiles done", _SuperLib_Log.LVL_DEBUG);
		}
		else if(GSAirport.IsAirportTile(tile))
		{
			if(pax_link_mode)
			{
				// Remove the potential rail tracks used to reserve tiles for bus stops by PAXLink version <= 13
				local ap_top_left = _SuperLib_Airport.GetAirportTile(GSStation.GetStationID(tile));
				local ap_type = GSAirport.GetAirportType(ap_top_left);

				local ap_x = GSMap.GetTileX(ap_top_left);
				local ap_y = GSMap.GetTileY(ap_top_left);

				local ap_w = GSAirport.GetAirportWidth(ap_type);
				local ap_h = GSAirport.GetAirportHeight(ap_type);

				local bus_y = ap_y + ap_h;
				for(local bus_x = ap_x; bus_x < ap_x + ap_w; bus_x++)
				{
					local bus_tile = GSMap.GetTileIndex(bus_x, bus_y);
					local bus_front_tile = GSMap.GetTileIndex(bus_x, bus_y + 1);
				
					if(GSRail.IsRailTile(bus_tile));
					{
						_SuperLib_Helper.SetSign(bus_tile, "clear rail");
						GSRail.RemoveRailTrack(bus_tile, GSRail.RAILTRACK_NE_SW);
						GSRail.RemoveRailTrack(bus_tile, GSRail.RAILTRACK_NW_SE);
					}
				}
			}

			// Demolish the airport
			GSTile.DemolishTile(tile);
		}
		else
			GSTile.DemolishTile(tile);

		// In order for this function to return true no parts of the station should be remaining
		succeeded = succeeded && GSStation.IsValidStation(GSStation.GetStationID(tile));
	}

	return succeeded;
}

/*static*/ function _SuperLib_Station::IsStation(tile, station_id)
{
	return GSStation.GetStationID(tile) == station_id;
}

/*static*/ function _SuperLib_Station::GetRoadFrontTiles(station_id)
{
	local station_tiles = GSTileList_StationType(station_id, GSStation.STATION_BUS_STOP);
	station_tiles.AddList(GSTileList_StationType(station_id, GSStation.STATION_TRUCK_STOP));

	local front_tiles = GSList();

	foreach(tile, _ in station_tiles)
	{
		local front = GSRoad.GetRoadStationFrontTile(tile);
		front_tiles.AddItem(front, 0);
	}

	return front_tiles;
}

/*static*/ function _SuperLib_Station::GetMaxCoverageRadius(station_id)
{
	// Get the max coverage radius
	local max_coverage_radius = 0;

	if(GSStation.HasStationType(station_id, GSStation.STATION_AIRPORT))
	{
		local airport_tile = _SuperLib_Airport.GetAirportTile(station_id);  // todo get from pax link
		local airport_type = GSAirport.GetAirportType(airport_tile);
		local coverage_radius = GSAirport.GetAirportCoverageRadius(airport_type);

		if(coverage_radius > max_coverage_radius)
			max_coverage_radius = coverage_radius;
	}

	if(max_coverage_radius < 5 && GSStation.HasStationType(station_id, GSStation.STATION_DOCK))
		max_coverage_radius = 5;

	if(max_coverage_radius < 4 && GSStation.HasStationType(station_id, GSStation.STATION_TRAIN))
		max_coverage_radius = 4;

	if(max_coverage_radius < 3 && GSStation.HasStationType(station_id, GSStation.STATION_BUS_STOP) || GSStation.HasStationType(station_id, GSStation.STATION_TRUCK_STOP))
		max_coverage_radius = 3;

	return max_coverage_radius;
}

/*static*/ function _SuperLib_Station::GetAcceptanceCoverageTiles(station_id)
{
	// Get the max coverage radius
	local max_coverage_radius = _SuperLib_Station.GetMaxCoverageRadius(station_id);

	// Get the coverage tiles
	local station_tiles = GSTileList_StationType(station_id, GSStation.STATION_ANY);
	local acceptance_tiles = _SuperLib_Tile.GrowTileRect(station_tiles, max_coverage_radius);

	return acceptance_tiles;
}

/*static*/ function _SuperLib_Station::GetSupplyCoverageTiles(station_id)
{
	// Get the max coverage radius
	local max_coverage_radius = _SuperLib_Station.GetMaxCoverageRadius(station_id);

	local station_tiles = GSTileList_StationType(station_id, GSStation.STATION_ANY);

	// Supply needs the supply source to be within reach to a station part.
	local supply_tiles = GSTileList();
	foreach(tile, _ in station_tiles)
	{
		supply_tiles.AddList(_SuperLib_Tile.MakeTileRectAroundTile(tile, max_coverage_radius));
	}

	return supply_tiles;
}

/*static*/ function _SuperLib_Station::IsCargoAccepted(station_id, cargo_id)
{
	// Get the acceptance tiles
	local acceptance_tiles = _SuperLib_Station.GetAcceptanceCoverageTiles(station_id);

	// Valuate the list with the acceptance for each individual tile
	acceptance_tiles.Valuate(GSTile.GetCargoAcceptance, cargo_id, 1, 1, 0);

	// Return true if the sum over all tiles is >= 8
	local total_acceptance = _SuperLib_Helper.ListValueSum(acceptance_tiles);
	return total_acceptance >= 8;
}

/*static*/ function _SuperLib_Station::IsCargoAcceptedByIndustry(station_id, cargo_id, industry_id)
{
	local max_coverage_radius = _SuperLib_Station.GetMaxCoverageRadius(station_id);

	local industry_coverage_tiles = GSTileList_IndustryAccepting(industry_id, max_coverage_radius);
	industry_coverage_tiles.Valuate(_SuperLib_Station.IsStation, station_id);
	industry_coverage_tiles.KeepValue(1);

	return !industry_coverage_tiles.IsEmpty() && _SuperLib_Station.IsCargoAccepted(station_id, cargo_id);
}

/*static*/ function _SuperLib_Station::IsCargoSupplied(station_id, cargo_id)
{
	// Get the acceptance tiles
	local supply_tiles = _SuperLib_Station.GetSupplyCoverageTiles(station_id);

	// For supply it is enough to cover any tile of the industry independent on
	// which tiles that actually have the supply coded at them.
	supply_tiles.Valuate(GSIndustry.GetIndustryID);

	foreach(_, industry_id in supply_tiles)
	{
		if(GSIndustry.IsValidIndustry(industry_id))
		{
			local ind_type = GSIndustry.GetIndustryType(industry_id);
			if(_SuperLib_Industry.IsCargoProduced(industry_id, cargo_id))
			{
				// An industry in range produce the cargo, thus the
				// station is considered to be supplied.
				//
				// (neglecting the fact that if there are more than 2
				// stations near the industry, not all of them will
				// be supplied by cargo)
				return true;
			}
		}
	}
	
	// No covered industry found
	return false;
}

/*static*/ function _SuperLib_Station::IsCargoSuppliedByIndustry(station_id, cargo_id, industry_id)
{
	local max_coverage_radius = _SuperLib_Station.GetMaxCoverageRadius(station_id);

	local industry_coverage_tiles = GSTileList_IndustryProducing(industry_id, max_coverage_radius);
	industry_coverage_tiles.Valuate(_SuperLib_Station.IsStation, station_id);
	industry_coverage_tiles.KeepValue(1);

	return !industry_coverage_tiles.IsEmpty() && _SuperLib_Station.IsCargoSupplied(station_id, cargo_id);
}

/*static*/ function _SuperLib_Station::GetStationTypeOfVehicle(veh_id)
{
	local veh_type = GSVehicle.GetVehicleType(veh_id);
	if(veh_type == GSVehicle.VT_RAIL)
		return GSStation.STATION_TRAIN;

	if(veh_type == GSVehicle.VT_ROAD)
	{
		local veh_cargo = _SuperLib_Vehicle.GetVehicleCargoType(veh_id);
		local road_veh_type = GSRoad.GetRoadVehicleTypeForCargo(veh_cargo);
		if(road_veh_type == GSRoad.ROADVEHTYPE_BUS)
			return GSStation.STATION_BUS_STOP;
		else
			return GSStation.STATION_TRUCK_STOP;
	}

	if(veh_type == GSVehicle.VT_WATER)
		return GSStation.STATION_DOCK;

	if(veh_type == GSVehicle.VT_AIR)
		return GSStation.STATION_AIRPORT;
}

/*static*/ function _SuperLib_Station::GetListOfVehiclesAtStation(stationId)
{
	local vehicle_list = GSVehicleList_Station(stationId); // vehicles visiting the station

	// Keep vehicles that has the state AT_STATION
	// and are located at the correct station id
	vehicle_list.Valuate(_SuperLib_Vehicle.IsVehicleAtStation, stationId);
	vehicle_list.KeepValue(1);

	return vehicle_list;
}

