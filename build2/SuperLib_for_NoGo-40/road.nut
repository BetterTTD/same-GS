/*
 * this file is part of superlib, which is an ai library for openttd
 * copyright (c) 2008-2011  leif linse
 *
 * superlib is free software; you can redistribute it and/or modify it 
 * under the terms of the gnu general public license as published by
 * the free software foundation; version 2 of the license
 *
 * superlib is distributed in the hope that it will be useful,
 * but without any warranty; without even the implied warranty of
 * merchantability or fitness for a particular purpose.  see the
 * gnu general public license for more details.
 *
 * you should have received a copy of the gnu general public license
 * along with superlib; if not, see <http://www.gnu.org/licenses/> or
 * write to the free software foundation, inc., 51 franklin street, 
 * fifth floor, boston, ma 02110-1301 usa.
 *
 */


class _SuperLib_Road {

	static function CanConnectToRoad(road_tile, adjacent_tile_to_connect);

	// This function use a road path finder to check if it is possible to go from tile1 to tile2 by road.
	// Thus as opposed to GSRoad.AreRoadTilesConnected, the road tiles do not need to be adjacent.
	//
	// Warning: Currently this function does fail even if there is a
	// connection if it contains too long detours.
	static function AreDistantRoadTilesConnected(tile1, tile2);

	static function BuildStopInTown(town, road_veh_type, accept_cargo = -1, produce_cargo = -1);
	static function BuildStopForIndustry(industry_id, cargo_id);

	/*
	 * @return a table: { station_id = station id,
	 *                    depot_tile = depot tile
	 *                    result = true or false }
	 */
	static function BuildMagicDTRSInTown(town, road_veh_type, stop_length, accept_cargo = -1, produce_cargo = -1);
	static function BuildMagicDTRSForIndustry(town, road_veh_type, stop_length, accept_cargo = -1, produce_cargo = -1); // Not implemented

	//// Build*NextToRoad functions: /////////////////////////////////////
	// 1. Checks if 'tile' is road
	// 2. If not: it locates nearby road using Tile.FindClosestRoadTile
	// 3. From the starting-point on the road network, search for a suitable 
	//    location to build the building. 
	//    - it prefers to build the building near the starting-point
	//
	// Returns used tile or null if construction failed.
	static function BuildBusStopNextToRoad(tile, min_loops, max_loops); 
	static function BuildTruckStopNextToRoad(tile, min_loops, max_loops); 
	static function BuildDepotNextToRoad(tile, min_loops, max_loops); 

	/*
	 * The magic DTRS has an included depot
	 *
	 * @param stop_type: GSRoad.ROADTYPE_ROAD or GSRoad.ROADVEHTYPE_TRUCK
	 * @param stop_length: [1 .. to station_spread]
	 *
	 * @return a table: { station_id = station id,
	 *                    depot_tile = depot tile
	 *                    result = true or false }
	 */
	static function BuildMagicDTRSNextToRoad(tile, stop_type, stop_length, accept_cargo, produce_cargo, min_loops, max_loops);

	/*
	 * The functions above are convenient ways to call this function instead of
	 * having to put together the "what" string. In addition the MagicDTRS functions
	 * also provide additional return values.
	 *
	 * 'what' can be any of:  ('what' should be a string)
	 *  - "BUS_STOP", 
	 *  - "TRUCK_STOP", 
	 *  - "DEPOT",
	 *  - "BUS_MAGIC_DTRS:" + length    // eg. "BUS_MAGIC_DTRS:2" for length 2
	 *  - "TRUCK_MAGIC_DTRS:" + length  // eg. "TRUCK_MAGIC_DTRS:1" for length 1
	 *
	 * Returns the tile where the 'what' thing was built. If construction fails, the method returns null.
	 */
	static function BuildNextToRoad(tile, what, accept_cargo, produce_cargo, min_loops, max_loops, try_number = 1);

	//////////////////////////////////////////////////////////////////////

	/*
	 * GrowStation and GrowStationParallel use SuperLib::Result return values
	 * To check for success/failure use SuperLib::Result::IsSuccess / IsFail
	 * or look in result.nut for specific error codes like TIME_OUT or NOT_ENOUGH_MONEY.
	 */
	static function GrowStation(station_id, station_type);
	static function GrowStationParallel(station_id, station_type);


	/*
	 * What differs this function from the one in the API, is that
	 * if it encounter a DTRS, it will return the side that
	 * has a road connection.
	 */
	static function GetRoadStationFrontTile(station_tile);

	/* Returns a table which always contain a key 'succeeded' that is true or false depeding
	 * on if the function succeeded or not.
	 *
	 * If succeeded is true then the table also contains
	 * - bridge_start = <tile>
	 * - bridge_end = <tile>
	 *
	 * If succeeded is false then the table also contains
	 * - permanently = <boolean>
	 */
	static function ConvertRailCrossingToBridge(rail_tile, prev_tile);
	//static function RemoveRoad(from_tile, to_tile);

	/*
	 * To remove a road stop or DTRS along with the road connection to front/back tiles,
	 * you can use Station.RemoveStation.
	 *
	 * For depots, demolish the depot and then call RemoveRoadInfrontOfRemovedRoadStopOrDepot
	 * to clean up the road on the front tile. For DTRS this function can be used too. Call it
	 * twice then with the back tile as 'front_tile' the second time.
	 *
	 * If the road station/depot was placed with a road up to a junction with an existing road,
	 * then RemoveRoadUpToRoadCrossing can be used to remove the road stump from your station/depot
	 * up to the main road.
	 */
	static function RemoveRoadInfrontOfRemovedRoadStopOrDepot(stop_depot_tile, front_tile);
	static function RemoveRoadUpToRoadCrossing(start_tile);
	//

	/*
	 * After building a road stop and building a road from the front tile back to it,
	 * it can happen that the road infront of the road stop is a slope. If you then try
	 * to place a depot reachable from the front tile, using BuildDepotNextToRoad, it
	 * will pick the only free connection to the sloped road. This will cause the road
	 * station to be impossible to connect. 
	 *
	 * If you call this function after eg. BuildStopForIndustry, it will try to detect
	 * such situations and extend the road or modify the terrain.
	 */
	static function FixRoadStopFront(road_stop_tile);
}

function _SuperLib_Road::CanConnectToRoad(road_tile, adjacent_tile_to_connect)
{
	// If road_tile don't have road type "road" (ie it is only a tram track), then we can't connect to it
	if(!GSRoad.HasRoadType(road_tile, GSRoad.ROADTYPE_ROAD))
		return false;

	local neighbours = _SuperLib_Tile.GetNeighbours4MainDir(road_tile);
	
	neighbours.Valuate(_SuperLib_Helper.ItemValuator);
	neighbours.RemoveValue(adjacent_tile_to_connect);

	// This function requires that road_tile is connected with at least one other road tile.
	neighbours.Valuate(GSRoad.IsRoadTile);
	if(_SuperLib_Helper.ListValueSum(neighbours) < 1)
		return false;
	
	foreach(neighbour_tile_id in neighbours)
	{
		if(GSRoad.IsRoadTile(neighbour_tile_id))
		{
			local ret = GSRoad.CanBuildConnectedRoadPartsHere(road_tile, neighbour_tile_id, adjacent_tile_to_connect);
			if(ret == 0 || ret == -1)
				return false;
		}
	}

	return true;
}

/*static*/ function _SuperLib_Road::AreDistantRoadTilesConnected(tile1, tile2)
{
	local rpf = _SuperLib_RoadPathFinder(true);

	rpf.InitializePath([tile1], [tile2], false);
	rpf.SetStepSize(100);
	rpf.SetMaxIterations(10000000);
	local path = rpf.FindPath();
	while(path == false)
	{
		path = rpf.FindPath();
		GSController.Sleep(1);
	}
	local status = rpf.GetFindPathError();
	return path != null && path != false && status == _SuperLib_RoadPathFinder.PATH_FIND_NO_ERROR;
}

function _SuperLib_Road::BuildStopInTown(town, road_veh_type, accept_cargo = -1, produce_cargo = -1) // this function is ugly and should ideally be removed
{
	_SuperLib_Log.Info("SuperLib::Road::BuildStopInTown(" + GSTown.GetName(town) + ")", _SuperLib_Log.LVL_DEBUG);

	if(GSTown.IsValidTown(town))
		_SuperLib_Log.Info("Town is valid", _SuperLib_Log.LVL_DEBUG);
	else
		_SuperLib_Log.Warning("Town is NOT valid (SuperLib::Road::BuildStopInTown)", _SuperLib_Log.LVL_INFO);
	
	local location = GSTown.GetLocation(town);

	if(!GSMap.IsValidTile(location))
	{
		_SuperLib_Log.Error("Invalid location! (SuperLib::Road::BuildStopInTown)", _SuperLib_Log.LVL_INFO);
		return false;
	}

	local what = "";

	if(road_veh_type == GSRoad.ROADVEHTYPE_BUS)
		what = "BUS_STOP";
	if(road_veh_type == GSRoad.ROADVEHTYPE_TRUCK)
		what = "TRUCK_STOP";

	return _SuperLib_Road.BuildNextToRoad(location, what, accept_cargo, produce_cargo, 50, 100 + GSTown.GetPopulation(town) / 70, 1);
}

function _SuperLib_Road::BuildStopForIndustry(industry_id, cargo_id)
{
	local road_veh_type = GSRoad.GetRoadVehicleTypeForCargo(cargo_id);
	
	local radius = 3;
	local accept_tile_list = GSTileList_IndustryAccepting(industry_id, radius);
	local produce_tile_list = GSTileList_IndustryProducing(industry_id, radius);

	local tile_list = GSTileList();

	if (!accept_tile_list.IsEmpty() && !produce_tile_list.IsEmpty())
	{
		// Intersection between accept & produce tiles
		tile_list.AddList(accept_tile_list);
		tile_list.KeepList(produce_tile_list);
	}
	else
	{
		// The industry only accepts or produces cargo
		// so intersection would yeild an empty tile list.
		// Instead make a union
		tile_list.AddList(accept_tile_list);
		tile_list.AddList(produce_tile_list);
	}


	// tile_list now contains all tiles around the industry that accept + produce cargo (hopefully all cargos of the industry, but that isn't documented in the API)
	
	tile_list.Valuate(GSTile.IsWaterTile);
	tile_list.KeepValue(0);
	
	tile_list.Valuate(GSTile.IsBuildable);
	tile_list.KeepValue(1);

	tile_list.Valuate(_SuperLib_Tile.IsBuildOnSlope_Flat); // this is a bit more strict than necessary. _FlatInDirection(tile, ANY_DIR) would have been enough
	tile_list.KeepValue(1);

	// Randomize the station location
	tile_list.Valuate(GSBase.RandItem);

	//tile_list.Valuate(GSMap.DistanceManhattan, GSIndustry.GetLocation(industry_id));
	tile_list.Sort(GSList.SORT_BY_VALUE, GSList.SORT_DESCENDING); // place the station as far away as possible from the industry location (in practice -> to the south of the industry)

	// Randomize which direction to try first when constructing to not get a strong bias towards building
	// stations in one particular direction. It is however, enough to randomize once per industry. 
	// (no need to randomize once per tile)
	local dir_list = _SuperLib_Direction.GetMainDirsInRandomOrder();

	// Loop through the remaining tiles and see where we can put down a stop and a road infront of it
	foreach(tile, _ in tile_list)
	{
//		_SuperLib_Helper.SetSign(tile, "ind stn");

		// Go through all dirs and try to build in all directions until one succeeds
		foreach(dir, _ in dir_list)
		{
			
			local front_tile = _SuperLib_Direction.GetAdjacentTileInDirection(tile, dir);

			if(!_SuperLib_Tile.IsBuildOnSlope_FlatForTerminusInDirection(front_tile, _SuperLib_Direction.OppositeDir(dir))) // Check that the front tile can be connected to tile without using any DoCommands.
				continue;

			_SuperLib_Helper.SetSign(tile, "front stn");

			// First test build to see if there is a failure and only if it works build it in reality
			{
				local tm = GSTestMode();

				if(!GSRoad.BuildRoadStation(tile, front_tile, road_veh_type, GSStation.STATION_NEW) &&
						GSRoad.BuildRoad(tile, front_tile))
					continue;
			}
			
			// Build it for real
			local ret = GSRoad.BuildRoadStation(tile, front_tile, road_veh_type, GSStation.STATION_NEW) &&
					GSRoad.BuildRoad(tile, front_tile);

			if (ret)
				return tile;

			// There was a problem to construct some part -> demolish tile + front_tile so that we don't leave anything around
			GSTile.DemolishTile(tile);
			GSTile.DemolishTile(front_tile);
		}
	}

	return -1;
}

function _SuperLib_Road::BuildMagicDTRSInTown(town, road_veh_type, stop_length, accept_cargo = -1, produce_cargo = -1)
{
	_SuperLib_Log.Info("SuperLib::Road::BuildMagicDTRSInTown(" + GSTown.GetName(town) + ")", _SuperLib_Log.LVL_DEBUG);

	if(GSTown.IsValidTown(town))
		_SuperLib_Log.Info("Town is valid", _SuperLib_Log.LVL_DEBUG);
	else
		_SuperLib_Log.Warning("Town is NOT valid (SuperLib::Road::BuildMagicDTRSInTown)", _SuperLib_Log.LVL_INFO);
	
	local location = GSTown.GetLocation(town);

	if(!GSMap.IsValidTile(location))
	{
		_SuperLib_Log.Error("Invalid location! (SuperLib::Road::BuildMagicDTRSInTown)", _SuperLib_Log.LVL_INFO);
		return false;
	}

	local what = "";

	if(road_veh_type == GSRoad.ROADVEHTYPE_BUS)
		what = "BUS_STOP";
	if(road_veh_type == GSRoad.ROADVEHTYPE_TRUCK)
		what = "TRUCK_STOP";

	return _SuperLib_Road.BuildMagicDTRSNextToRoad(location, road_veh_type, stop_length, accept_cargo, produce_cargo, 50, 100 + GSTown.GetPopulation(town) / 70);
}

function _SuperLib_Road::BuildMagicDTRSForIndustry(town, road_veh_type, stop_length, accept_cargo = -1, produce_cargo = -1)
{
}

function _SuperLib_Road::BuildBusStopNextToRoad(tile, min_loops, max_loops)
{
	return _SuperLib_Road.BuildNextToRoad(tile, "BUS_STOP", -1, -1, min_loops, max_loops, 1);
}
function _SuperLib_Road::BuildTruckStopNextToRoad(tile, min_loops, max_loops)
{
	return _SuperLib_Road.BuildNextToRoad(tile, "TRUCK_STOP", -1, -1, min_loops, max_loops, 1);
}
function _SuperLib_Road::BuildDepotNextToRoad(tile, min_loops, max_loops)
{
	return _SuperLib_Road.BuildNextToRoad(tile, "DEPOT", -1, -1, min_loops, max_loops, 1);
}

function _SuperLib_Road::BuildNextToRoad(tile, what, accept_cargo, produce_cargo, min_loops, max_loops, try_number = 1)
{
	local start_tile = tile;

	local green_list = GSList();
	local red_list = [];

	local found_locations = _SuperLib_ScoreList();

	local i = 0;
	local ix, iy;
	local curr_x, curr_y;
	local curr_tile;
	local curr_distance;
	local adjacent_x, adjacent_y;
	local adjacent_tile;

	local adjacent_dir_list = _SuperLib_Direction.GetMainDirsInRandomOrder();

	// If 'what' is a magic DTRS, get the bus/truck type and length
	local magic_dtrs_len = null;
	local magic_dtrs_type = null;
	if(what.find("BUS_MAGIC_DTRS") == 0)
		magic_dtrs_type = GSRoad.ROADVEHTYPE_BUS;
	else if(what.find("TRUCK_MAGIC_DTRS") == 0)
		magic_dtrs_type = GSRoad.ROADVEHTYPE_TRUCK;
	if(magic_dtrs_type != null)
	{
		local parts = _SuperLib_Helper.SplitString(":", what);
		magic_dtrs_len = parts[1].tointeger();
	}

	if(!GSMap.IsValidTile(start_tile))
	{
		_SuperLib_Log.Error("Invalid start_tile!", _SuperLib_Log.LVL_INFO);
		return null;
	}

	if(!GSRoad.IsRoadTile(start_tile))
	{
		start_tile = _SuperLib_Tile.FindClosestRoadTile(start_tile, 4);
		if(!start_tile)
		{
			_SuperLib_Log.Error("failed to find road tile as start_tile was not a road tile! (SuperLib::Road::BuildNextToRoad)", _SuperLib_Log.LVL_INFO);
			return null;
		}
	}

	curr_tile = start_tile;
	curr_distance = 0;

	while( i++ < max_loops )
	{
		/*{
			local exec = GSExecMode(); 
			GSSign.BuildSign(curr_tile, i+"/"+GSMap.DistanceSquare(curr_tile, start_tile));
		}*/
		local testmode = GSTestMode();
		curr_x = GSMap.GetTileX(curr_tile);
		curr_y = GSMap.GetTileY(curr_tile);

		// if we are on a bridge end, add the tile next to other end to green list if it's not in red_list and is accessible from bridge.
		if(GSBridge.IsBridgeTile(curr_tile) || GSTunnel.IsTunnelTile(curr_tile))
		{
			local exec = GSExecMode();	

			//GSSign.BuildSign(curr_tile, "bridge end");
			local other_end = null;
			if(GSBridge.IsBridgeTile(curr_tile))
			{
				other_end = GSBridge.GetOtherBridgeEnd(curr_tile);
			}
			else 
			{
				other_end = GSTunnel.GetOtherTunnelEnd(curr_tile);
			}
			//GSSign.BuildSign(other_end, "other end");

			// Get tile next to bridge/tunnel on the other end
			local next_to_other_end = null;
			local x = GSMap.GetTileX(curr_tile) - GSMap.GetTileX(other_end);
			local y = GSMap.GetTileY(curr_tile) - GSMap.GetTileY(other_end);
			local bridge_tunnel_length = _SuperLib_Helper.Max(abs(x), abs(y));
			
			if(x != 0)
				x = x / abs(x);
			if(y != 0)
				y = y / abs(y);
			next_to_other_end = other_end - GSMap.GetTileIndex(x, y);
			//GSSign.BuildSign(next_to_other_end, "next to other end");
			
			// Add the tile next_to_other_end to green list if it is not in red list and is accessible from the bridge
			if( _SuperLib_Helper.ArrayFind(red_list, next_to_other_end) == null )
			{
				//local test = GSTestMode(); // < let's add a road bit at the other end if there is no so we can use that for building next to if needed.
				if(GSRoad.AreRoadTilesConnected(other_end, next_to_other_end) || GSRoad.BuildRoad(other_end, next_to_other_end))
				{
					local walk_distance = curr_distance + bridge_tunnel_length;
					green_list.AddItem(next_to_other_end, walk_distance + GSMap.DistanceManhattan(next_to_other_end, start_tile));
				}
			}
			
		}
		else
		{
			// scan adjacent tiles
			foreach(adjacent_dir, _ in adjacent_dir_list)
			{
				adjacent_tile = _SuperLib_Direction.GetAdjacentTileInDirection(curr_tile, adjacent_dir);

				if(!GSMap.IsValidTile(adjacent_tile))
				{
					_SuperLib_Log.Warning("Adjacent tile is not valid", _SuperLib_Log.LVL_DEBUG);
					continue;
				}

				_SuperLib_Helper.SetSign(adjacent_tile, "a");

				if(accept_cargo != -1)
				{
					// Make sure the station will accept the given cargo
					local acceptance = GSTile.GetCargoAcceptance(adjacent_tile, accept_cargo, 1, 1, 3); // TODO: take into account DTRS stops with a length > 1
					if(acceptance < 8)
						continue;
				}
				if(produce_cargo != -1)
				{
					// Make sure the station will receive the given produced cargo
					local production = GSTile.GetCargoProduction(adjacent_tile, produce_cargo, 1, 1, 3); // TODO: take into account DTRS stops with a length > 1
					if(production < 1)
						continue;
				}

				if(GSRoad.AreRoadTilesConnected(curr_tile, adjacent_tile))
				{
					if( _SuperLib_Helper.ArrayFind(red_list, adjacent_tile) == null )
					{
						local exec = GSExecMode();	
						green_list.AddItem(adjacent_tile, curr_distance + 1 + GSMap.DistanceManhattan(adjacent_tile, start_tile));
						//GSSign.BuildSign(adjacent_tile, i+":"+GSMap.DistanceSquare(adjacent_tile, start_tile));
					}
				}
				else if(GSRoad.BuildRoad(adjacent_tile, curr_tile))
				{
					local ret;
					

					if(what == "BUS_STOP")
					{
						ret = GSRoad.BuildRoadStation(adjacent_tile, curr_tile, GSRoad.ROADVEHTYPE_BUS, GSStation.STATION_NEW);
					}
					else if(what == "TRUCK_STOP")
					{
						ret = GSRoad.BuildRoadStation(adjacent_tile, curr_tile, GSRoad.ROADVEHTYPE_TRUCK, GSStation.STATION_NEW);
					}
					else if(what == "DEPOT")
					{
						ret = GSRoad.BuildRoadDepot(adjacent_tile, curr_tile)
					}
					else if(magic_dtrs_type != null)
					{
						// Loop over the tiles that the magic DTRS station would use
						ret = true;
						for(local i_dtrs_tile = adjacent_tile, i_dtrs_len = 0, i_prev_tile = curr_tile;
							i_dtrs_len < magic_dtrs_len + 1;
							++i_dtrs_len, i_prev_tile = i_dtrs_tile, i_dtrs_tile = _SuperLib_Direction.GetAdjacentTileInDirection(i_dtrs_tile, adjacent_dir) )
						{
							if(i_dtrs_len < magic_dtrs_len) // dtrs station ?
							{
								ret = ret && _SuperLib_Tile.IsBuildOnSlope_FlatInDirection(i_dtrs_tile, adjacent_dir) && // for stations, direction can be 180 degree 'wrong' as both 180 degree rotations are equally correct.
									GSRoad.BuildDriveThroughRoadStation(i_dtrs_tile, i_prev_tile, magic_dtrs_type, GSStation.STATION_NEW);
							}
							else // depot
							{
								ret = ret && _SuperLib_Tile.IsBuildOnSlope_FlatForTerminusInDirection(i_dtrs_tile, _SuperLib_Direction.OppositeDir(adjacent_dir)) && // for the depot it matters that the direction is correct
									GSRoad.BuildRoadDepot(i_dtrs_tile, i_prev_tile);
							}

							if(!ret)
								break;
						}
					}
					else
					{
						_SuperLib_Log.Info("ERROR: Invalid value of argument 'what' to function BuildNextToRoad(tile, what)", _SuperLib_Log.LVL_INFO);
						GSRoad.RemoveRoad(adjacent_tile, curr_tile);
						return null;
					}

					if(ret)
					{
						found_locations.Push([adjacent_tile, curr_tile], GSMap.DistanceSquare(adjacent_tile, start_tile));
					}
				}
				else
				{
					//local exec = GSExecMode();	
					//GSSign.BuildSign(adjacent_tile, "x");
				}

				if(i%10 == 0)
				{
					GSController.Sleep(1);
				}
			}
		}

		// if found at least one location and we have looped at least min_loops. => don't search more
		if(found_locations.list.len() > 0 && i >= min_loops)
		{
			break;
		}

		red_list.append(curr_tile);

		if(green_list.IsEmpty())
		{
			_SuperLib_Log.Warning("Green list empty in BuildNextToRoad function.", _SuperLib_Log.LVL_SUB_DECISIONS);
			break;
		}

		// select best tile from green_list
		green_list.Sort(GSList.SORT_BY_VALUE, true); // lowest distance first
		curr_tile = green_list.Begin();
		curr_distance = green_list.GetValue(curr_tile) - GSMap.DistanceManhattan(curr_tile, start_tile); // The distance score include the distance to city center as well, so remove it to get the walk distance only as the base for aggregating distance.
		
		green_list.Valuate(_SuperLib_Helper.ItemValuator);
		green_list.RemoveValue(curr_tile);

		if(!GSMap.IsValidTile(curr_tile)) 
		{
			_SuperLib_Log.Warning("Green list contained invalid tile.", _SuperLib_Log.LVL_SUB_DECISIONS);
			break;
		}
	}

	// if there is a accept/produce cargo use that to score the locations
	if(accept_cargo != -1 || produce_cargo != -1)
	{
		// Valuate the list with (acceptance + production of cargoes) * -1
		//
		// By multiplying by -1, PopMin below will pick the best producing/accepting tile first
		found_locations.ScoreValuate(this, _SuperLib_Private_Road_GetTileAcceptancePlusProduction_TimesMinusOne, accept_cargo, produce_cargo);
	}

	// get best built building
	local best_location = found_locations.PopMin();
	if(best_location == null) // return null, if no location at all was found.
	{
		_SuperLib_Log.Info("BuildNextToRoad: failed to build: " + what, _SuperLib_Log.LVL_INFO);
		return null;
	}

	// Build best station
	local road_tile = best_location[1];
	local station_tile = best_location[0];
	
	local ret = false;

	if(!GSRoad.BuildRoad(road_tile, station_tile)) return null;
	if(what == "BUS_STOP")
	{
		ret = GSRoad.BuildRoadStation(station_tile, road_tile, GSRoad.ROADVEHTYPE_BUS, GSStation.STATION_NEW);
	}
	else if(what == "TRUCK_STOP")
	{
		ret = GSRoad.BuildRoadStation(station_tile, road_tile, GSRoad.ROADVEHTYPE_TRUCK, GSStation.STATION_NEW);
	}
	else if(what == "DEPOT")
	{
		ret = GSRoad.BuildRoadDepot(station_tile, road_tile)
	}
	else if(magic_dtrs_type != null)
	{
		// Loop over the tiles that the magic DTRS station would use
		ret = true;
		local adjacent_dir = _SuperLib_Direction.GetDirectionToTile(road_tile, station_tile);
		local station_id = null;
		for(local i_dtrs_tile = station_tile, i_dtrs_len = 0, i_prev_tile = road_tile; 
				i_dtrs_len < magic_dtrs_len + 1; 
				++i_dtrs_len, i_prev_tile = i_dtrs_tile, i_dtrs_tile = _SuperLib_Direction.GetAdjacentTileInDirection(i_dtrs_tile, adjacent_dir))
		{
			// Get join attribute to BuildDriveThroughRoadStation function
			local join = station_id == null? GSStation.STATION_NEW : 
				(GSGameSettings.GetValue("distant_join_stations") == 1? station_id : GSStation.STATION_JOIN_ADJACENT);

			if(i_dtrs_len < magic_dtrs_len) // dtrs station ?
			{
				ret = ret && GSRoad.BuildDriveThroughRoadStation(i_dtrs_tile, i_prev_tile, magic_dtrs_type, join);
				if(ret && station_id == null) // first station part?
				{
					station_id = GSStation.GetStationID(i_dtrs_tile);
				}
			}
			else // depot
			{
				ret = ret && GSRoad.BuildRoadDepot(i_dtrs_tile, i_prev_tile);
			}

			if(!ret)
				break;
		}
	}
	else
	{
		_SuperLib_Log.Error("ERROR: Invalid value of argument 'what' to function BuildNextToRoad(tile, what) at constructing on the best tile", _SuperLib_Log.LVL_INFO);
		return null;
	}

	if(!ret)
	{
		// someone built something on the tile so now it's not possible to build there. :( 
		// make another try a few times and then give up
		if(try_number <= 5)
		{
			_SuperLib_Log.Info("BuildNextToRoad retries by calling itself", _SuperLib_Log.LVL_SUB_DECISIONS);
			return _SuperLib_Road.BuildNextToRoad(tile, what, -1, -1 min_loops, max_loops, try_number+1);
		}
		else
			return null;
	}

	if(GSController.GetSetting("slow_ai") == 1)
		GSController.Sleep(80);
	else
		GSController.Sleep(5);

	//_SuperLib_Helper.ClearAllSigns();
	
	// return the location of the built station
	return station_tile;
	
}

function _SuperLib_Road::BuildMagicDTRSNextToRoad(tile, stop_type, stop_length, accept_cargo, produce_cargo, min_loops, max_loops)
{
	// Compose the what-variable
	local what = null;
	if(stop_type == GSRoad.ROADVEHTYPE_BUS)
		what = "BUS_MAGIC_DTRS:" + stop_length;
	else if(stop_type == GSRoad.ROADVEHTYPE_TRUCK)
		what = "TRUCK_MAGIC_DTRS:" + stop_length;

	// Call BuildNextToRoad
	local station_tile = _SuperLib_Road.BuildNextToRoad(tile, what, accept_cargo, produce_cargo, min_loops, max_loops);

	// Figure out where the depot tile is and respond with the result
	// that this function should have.
	local result = { station_id = null,
		depot_tile = null,
		result = false };

	if(station_tile != null && GSMap.IsValidTile(station_tile))
	{
		// Get station_id and location of depot
		result.station_id = GSStation.GetStationID(station_tile);

		local front_tile = _SuperLib_Road.GetRoadStationFrontTile(station_tile);
		local back_direction = _SuperLib_Direction.GetDirectionToAdjacentTile(front_tile, station_tile);

		result.depot_tile = _SuperLib_Direction.GetTileInDirection(station_tile, back_direction, stop_length)

		result.result = true;
	}

	return result;
}


// Score valuator to be used with the found_locations ScoreList in BuildNextToRoad
function _SuperLib_Private_Road_GetTileAcceptancePlusProduction_TimesMinusOne(pair, accept_cargo, produce_cargo)
{
	local station_tile = pair[0];
	//local front_tile = pair[1]; // not used

	local acceptance = -1;
	local production = -1;

	if(accept_cargo != -1)
		acceptance = GSTile.GetCargoAcceptance(station_tile, accept_cargo, 1, 1, 3);

	if(produce_cargo != -1)
		production = GSTile.GetCargoProduction(station_tile, accept_cargo, 1, 1, 3);

	// Get base score
	local score = (acceptance + production);

	// Add a random component up to a third of the acceptance/production sum
	score = score + GSBase.RandRange(score / 3); 

	// Multiply by -1
	score = score * -1;

	return score;
}

function _SuperLib_Road::GrowStation(station_id, station_type)
{
	_SuperLib_Log.Info("GrowStation: Non-parallel grow function called", _SuperLib_Log.LVL_DEBUG);

	if(!GSStation.IsValidStation(station_id))
	{
		_SuperLib_Log.Error("GrowStation: Can't grow invalid station", _SuperLib_Log.LVL_INFO);
		return _SuperLib_Result.FAIL;
	}

	/* No support for games with distant join = off. GrowStationParallel have support for it though */
	if(GSGameSettings.GetValue("distant_join_stations") == 0)
		return _SuperLib_Result.FAIL;

	local existing_stop_tiles = GSTileList_StationType(station_id, station_type);
	local grow_max_distance = _SuperLib_Helper.Clamp(7, 0, GSGameSettings.GetValue("station_spread") - 1);

	_SuperLib_Helper.SetSign(_SuperLib_Direction.GetAdjacentTileInDirection(GSBaseStation.GetLocation(station_id), _SuperLib_Direction.DIR_E), "<- grow");

	// GSRoad.BuildStation wants another type of enum constant to decide if bus/truck should be built
	local road_veh_type = 0;
	if(station_type == GSStation.STATION_BUS_STOP)
		road_veh_type = GSRoad.ROADVEHTYPE_BUS;
	else if(station_type == GSStation.STATION_TRUCK_STOP)
		road_veh_type = GSRoad.ROADVEHTYPE_TRUCK;
	else
		KABOOOOOOOM_UNSUPPORTED_STATION_TYPE = 0;

	local potential_tiles = GSTileList();

	foreach(stop_tile, _ in existing_stop_tiles)
	{
		potential_tiles.AddList(_SuperLib_Tile.MakeTileRectAroundTile(stop_tile, grow_max_distance));
	}

	potential_tiles.Valuate(GSRoad.IsRoadStationTile);
	potential_tiles.KeepValue(0);

	potential_tiles.Valuate(GSRoad.IsRoadDepotTile);
	potential_tiles.KeepValue(0);

	potential_tiles.Valuate(GSRoad.IsRoadStationTile);
	potential_tiles.KeepValue(0);

	//potential_tiles.Valuate(GSRoad.IsRoadTile);
	//potential_tiles.KeepValue(0);

	potential_tiles.Valuate(GSRoad.GetNeighbourRoadCount);
	potential_tiles.KeepAboveValue(0);
	//potential_tiles.RemoveValue(4);

	potential_tiles.Valuate(GSMap.DistanceManhattan, _SuperLib_Road.GetRoadStationFrontTile(existing_stop_tiles.Begin()) );
	potential_tiles.Sort(GSList.SORT_BY_VALUE, true); // lowest value first

	foreach(try_tile, _ in potential_tiles)
	{
		local neighbours = _SuperLib_Tile.GetNeighbours4MainDir(try_tile);

		neighbours.Valuate(GSRoad.IsRoadTile);
		neighbours.KeepValue(1);

		local road_builder = _SuperLib_RoadBuilder();
		if(GSController.GetSetting("slow_ai")) road_builder.EnableSlowAI();

		foreach(road_tile, _ in neighbours)
		{
			if( (GSRoad.AreRoadTilesConnected(try_tile, road_tile) || _SuperLib_Road.CanConnectToRoad(road_tile, try_tile)) &&
					GSTile.GetMaxHeight(try_tile) == GSTile.GetMaxHeight(road_tile) )
			{
				if(GSRoad.BuildRoadStation(try_tile, road_tile, road_veh_type, station_id))
				{
					// Make sure the new station part is connected with one of the existing parts (which is in turn should be
					// connected with all other existing parts)
					local repair = false;
					road_builder.Init(road_tile, _SuperLib_Road.GetRoadStationFrontTile(existing_stop_tiles.Begin()), repair, 10000);
					if(road_builder.ConnectTiles() != _SuperLib_RoadBuilder.CONNECT_SUCCEEDED)
					{
						GSRoad.RemoveRoadStation(try_tile);
						continue;
					}

					local i = 0;
					while(!GSRoad.AreRoadTilesConnected(try_tile, road_tile) && !GSRoad.BuildRoad(try_tile, road_tile))
					{
						// Try a few times to build the road if a vehicle is in the way
						if(i++ == 10) return _SuperLib_Result.TIME_OUT;

						local last_error = GSError.GetLastError();
						if(last_error != GSError.ERR_VEHICLE_IN_THE_WAY) return false;

						GSController.Sleep(5);
					}

					return _SuperLib_Result.SUCCESS;
				}
			}
		}
	}
	
	return _SuperLib_Result.FAIL;
}

function _SuperLib_Road::GrowStationParallel(station_id, station_type)
{
	if(!GSStation.IsValidStation(station_id))
	{
		_SuperLib_Log.Error("GrowStationParallel: Can't grow invalid station", _SuperLib_Log.LVL_INFO);
		return _SuperLib_Result.FAIL;
	}

	local road_veh_type = 0;
	if(station_type == GSStation.STATION_BUS_STOP)
		road_veh_type = GSRoad.ROADVEHTYPE_BUS;
	else if(station_type == GSStation.STATION_TRUCK_STOP)
		road_veh_type = GSRoad.ROADVEHTYPE_TRUCK;
	else
		KABOOOOOOOM_UNSUPPORTED_STATION_TYPE = 0;

	local existing_stop_tiles = GSTileList_StationType(station_id, station_type);

	local tot_wait_days = 0;
	local MAX_TOT_WAIT_DAYS = 30;
	
	foreach(stop_tile, _ in existing_stop_tiles)
	{
		local is_drive_through = GSRoad.IsDriveThroughRoadStationTile(stop_tile);
		local front_tile = _SuperLib_Road.GetRoadStationFrontTile(stop_tile);

		// Get the direction that the entry points at from the road stop
		local entry_dir = _SuperLib_Direction.GetDirectionToAdjacentTile(stop_tile, front_tile);

		// Try to walk in sideways in both directions
		local walk_dirs = [_SuperLib_Direction.TurnDirClockwise45Deg(entry_dir, 2), _SuperLib_Direction.TurnDirClockwise45Deg(entry_dir, 6)];
		foreach(walk_dir in walk_dirs)
		{
			_SuperLib_Log.Info( GSError.GetLastErrorString(), _SuperLib_Log.LVL_DEBUG );

			local parallel_stop_tile = _SuperLib_Direction.GetAdjacentTileInDirection(stop_tile, walk_dir);
			local parallel_front_tile = _SuperLib_Direction.GetAdjacentTileInDirection(front_tile, walk_dir);

			local opposite_walk_dir = _SuperLib_Direction.TurnDirClockwise45Deg(walk_dir, 4);
			local dir_from_front_to_station = _SuperLib_Direction.TurnDirClockwise45Deg(entry_dir, 4);

			local parallel_back_tile = _SuperLib_Direction.GetAdjacentTileInDirection(parallel_stop_tile, dir_from_front_to_station);

			// cache if we own the parallel front tile or not as it is checked at at least 3 places.
			local own_parallel_front_tile = GSCompany.IsMine(GSTile.GetOwner(parallel_front_tile));

			_SuperLib_Helper.SetSign(parallel_stop_tile, "par stop");

			// Check that we don't have built anything on the parallel stop tile
			if(!GSCompany.IsMine(GSTile.GetOwner(parallel_stop_tile)) &&

					// Check that the parallel front tile doesn't contain anything that we own. (with the exception that road is allowed)
					!(own_parallel_front_tile && !GSRoad.IsRoadTile(parallel_front_tile)) &&

					// Does slopes allow construction
					_SuperLib_Tile.IsBuildOnSlope_FlatForTerminusInDirection(front_tile, walk_dir) && // from front tile to parallel front tile
					_SuperLib_Tile.IsBuildOnSlope_FlatForTerminusInDirection(parallel_front_tile, opposite_walk_dir) && // from parallel front tile to front tile
					_SuperLib_Tile.IsBuildOnSlope_FlatForTerminusInDirection(parallel_front_tile, dir_from_front_to_station) && // from parallel front tile to parallel station tile
					_SuperLib_Tile.IsBuildOnSlope_FlatForTerminusInDirection(parallel_stop_tile, entry_dir) && // from parallel station tile to parallel front tile
					// Is the max heigh equal to allow construction
					GSTile.GetMaxHeight(front_tile) == GSTile.GetMaxHeight(parallel_front_tile) && 
					GSTile.GetMaxHeight(front_tile) == GSTile.GetMaxHeight(parallel_stop_tile)
					)
				
			{
				_SuperLib_Log.Info("Landscape allow grow in parallel", _SuperLib_Log.LVL_DEBUG);

				// Get the number of connections from the parallel stop tile to its adjacent tiles
				local num_stop_tile_connections = 0;
				if(GSRoad.AreRoadTilesConnected(parallel_stop_tile, parallel_back_tile))  num_stop_tile_connections++;
				if(GSRoad.AreRoadTilesConnected(parallel_stop_tile, parallel_front_tile)) num_stop_tile_connections++;
				if(GSRoad.AreRoadTilesConnected(parallel_stop_tile, _SuperLib_Direction.GetAdjacentTileInDirection(parallel_stop_tile, walk_dir))) num_stop_tile_connections++;

				_SuperLib_Log.Info("Num stop tile connections: " + num_stop_tile_connections, _SuperLib_Log.LVL_DEBUG);

				// If the parallel tile has more than one connection to adjacent tiles, then it is possible
				// that an opponent is using the road tile as part of his/her/its route. Since we don't want
				// to annoy our opponents by unfair play, don't use this parallel tile
				if(num_stop_tile_connections > 1)
				{
					_SuperLib_Log.Info("Parallel stop tile is (by road) connected to > 1 other tile => bail out (otherwise we could destroy someones road)", _SuperLib_Log.LVL_DEBUG);
					continue;
				}

				// Check if no buildings / unremovable / vehicles are in the way
				local build = false;
				{
					local tm = GSTestMode();
					local am = GSAccounting();
					build = GSTile.DemolishTile(parallel_stop_tile) && 
							(
								// road can already exists or can be built
								// OR 
								// parallel front is not my property but can be demolished.
								(
									(GSRoad.AreRoadTilesConnected(front_tile, parallel_front_tile) || GSRoad.BuildRoad(front_tile, parallel_front_tile)) &&
									(GSRoad.AreRoadTilesConnected(parallel_stop_tile, parallel_front_tile) || GSRoad.BuildRoad(parallel_stop_tile, parallel_front_tile))
									|| (!own_parallel_front_tile && GSTile.DemolishTile(parallel_front_tile))
								) 
							);

					// Wait up to 10 days until we have enough money to demolish + construct
					local start = GSDate.GetCurrentDate();
					while(am.GetCosts() * 2 > GSCompany.GetBankBalance(GSCompany.COMPANY_SELF))
					{
						local now = GSDate.GetCurrentDate();
						local wait_time = now - start;
						if(wait_time > 10 || tot_wait_days + wait_time > MAX_TOT_WAIT_DAYS)
						{
							return _SuperLib_Result.NOT_ENOUGH_MONEY;
						}
					}
					
				}

				if(build)
				{
					if(!GSRoad.AreRoadTilesConnected(front_tile, parallel_front_tile))
					{	
						// Wait untill there are no vehicles at front_tile
						local tm = GSTestMode();
						local start = GSDate.GetCurrentDate();
						local fail = false;
						while(!GSTile.DemolishTile(front_tile) && GSError.GetLastError() == GSError.ERR_VEHICLE_IN_THE_WAY)
						{ 
							// Keep track of the time
							local now = GSDate.GetCurrentDate();
							local wait_time = now - start;

							// Stop if waited more than allowed in total
							if(tot_wait_days + wait_time > MAX_TOT_WAIT_DAYS) 
							{
								return _SuperLib_Result.TIME_OUT;
							}

							// Wait maximum 10 days
							if(wait_time > 10)
							{
								fail = true;
								break;
							}

							GSController.Sleep(5);
						}

						tot_wait_days += GSDate.GetCurrentDate() - start;

						if(fail)
						{
							_SuperLib_Log.Info("Failed to grow to a specific parallel tile because the front_tile had vehicles in the way for too long time.", _SuperLib_Log.LVL_DEBUG);
							continue;
						}
					}

					// Force clearing of the parallel_stop_tile if it has some road on it since it could have a single road connection to another 
					// road tile which would make it impossible to build a road stop on it after having built a road from the parallel_front_tile.
					if( (!GSTile.IsBuildable(parallel_stop_tile) || GSRoad.IsRoadTile(parallel_stop_tile))  && !GSTile.DemolishTile(parallel_stop_tile))
					{
						_SuperLib_Log.Info("Failed to grow to a specific parallel tile because the parallel_stop_tile couldn't be cleared", _SuperLib_Log.LVL_DEBUG);
						continue;
					}

					// Clear the parallel front tile if it is needed
					// Forbid clearing the tile if we own it
					if(!GSRoad.AreRoadTilesConnected(front_tile, parallel_front_tile) && !GSRoad.BuildRoad(front_tile, parallel_front_tile) && (own_parallel_front_tile || !GSTile.DemolishTile(parallel_front_tile)))
					{
						_SuperLib_Log.Info("Failed to grow to a specific parallel tile because the parallel_front_tile couln't be cleared", _SuperLib_Log.LVL_DEBUG);
						continue;
					}

					if(!GSRoad.AreRoadTilesConnected(front_tile, parallel_front_tile) && !GSRoad.BuildRoad(front_tile, parallel_front_tile))
					{
						_SuperLib_Log.Info("Failed to grow to a specific parallel tile because couldn't connect front_tile and parallel_front_tile", _SuperLib_Log.LVL_DEBUG);
						continue;
					}

					if(!GSRoad.AreRoadTilesConnected(parallel_stop_tile, parallel_front_tile) && !GSRoad.BuildRoad(parallel_stop_tile, parallel_front_tile))
					{
						_SuperLib_Log.Info("Failed to grow to a specific parallel tile because couldn't connect the parallel_stop_tile with the parallel_front_tile", _SuperLib_Log.LVL_DEBUG);
						continue;
					}

					local join = station_id;
					if(GSGameSettings.GetValue("distant_join_stations") == 0) // if distant join is off, use the flag to join with adjacent station. If no other station is nearby, it can work
							join = GSStation.STATION_JOIN_ADJACENT;

					if(!GSRoad.BuildRoadStation(parallel_stop_tile, parallel_front_tile, road_veh_type, join))
					{
						_SuperLib_Log.Info("Failed to grow to a specific parallel tile because the road station couldn't be built at parallel_stop_tile", _SuperLib_Log.LVL_DEBUG);
						continue;
					}

					_SuperLib_Log.Info("Growing to a specific parallel tile succeeded", _SuperLib_Log.LVL_DEBUG);

					// Succeeded to grow station
					return _SuperLib_Result.SUCCESS;
				}
			}
		}
		_SuperLib_Log.Info( GSError.GetLastErrorString(), _SuperLib_Log.LVL_DEBUG);
	}

	return _SuperLib_Result.FAIL;
}

function _SuperLib_Road::GetRoadStationFrontTile(station_tile)
{
	if(!GSRoad.IsDriveThroughRoadStationTile(station_tile))
		return GSRoad.GetRoadStationFrontTile(station_tile);

	//
	// OpenTTD don't remember which end that you set as 'front'
	// when you built the DTRS station. So we need to look for
	// which end is most likely to be the front side of the
	// station.
	//

	// Search in 'front' direction
	local search_failed = false;
	local prev_front_tile = station_tile;
	local front = GSRoad.GetRoadStationFrontTile(station_tile);
	local front_dir = _SuperLib_Direction.GetDirectionToTile(station_tile, front);
	while(GSCompany.IsMine(GSTile.GetOwner(front)) &&  // make sure to not find an opponent station
			GSRoad.IsDriveThroughRoadStationTile(front) &&  // is front another station?
			_SuperLib_Direction.GetDirectionToAdjacentTile(prev_front_tile, front) == front_dir) // Check if we found a DTRS with another direction
	{
		prev_front_tile = front;
		front = GSRoad.GetRoadStationFrontTile(front);
	}

	local front_is_blocked = GSTile.IsStationTile(front) || GSRoad.IsRoadDepotTile(front) ||
		(!GSTile.HasTransportType(front, GSTile.TRANSPORT_ROAD) && !GSTile.IsBuildable(front))

	// Search in 'back' direction
	search_failed = false;
	local prev_back_tile = station_tile;
	local back = GSRoad.GetDriveThroughBackTile(station_tile);
	local back_dir = _SuperLib_Direction.GetDirectionToTile(station_tile, back);
	while(GSCompany.IsMine(GSTile.GetOwner(back)) &&  // make sure to not find an opponent station
			GSRoad.IsDriveThroughRoadStationTile(back) &&  // is back another station?
			_SuperLib_Direction.GetDirectionToAdjacentTile(prev_back_tile, back) == back_dir) // Check if we found a DTRS with another direction
	{
		prev_back_tile = back;
		back = GSRoad.GetDriveThroughBackTile(back);
	}

	local back_is_blocked = GSTile.IsStationTile(back) || GSRoad.IsRoadDepotTile(back) ||
		(!GSTile.HasTransportType(back, GSTile.TRANSPORT_ROAD) && !GSTile.IsBuildable(back))

	// decide which is the real front
	if(back_is_blocked && front_is_blocked)
	{
		_SuperLib_Log.Warning("GetRoadStationFrontTile: DTRS tile " + _SuperLib_Tile.GetTileString(station_tile) + " is blocked in both directions", _SuperLib_Log.LVL_INFO);
		return front;
	}
	else if(back_is_blocked)
	{
		return front;
	}
	else if(front_is_blocked)
	{
		return back;
	}
	else
	{
		// both back and front is clear from road stations

		// is one of them connected to road?
		if(GSRoad.AreRoadTilesConnected(front, prev_front_tile))
			return back;

		if(GSRoad.AreRoadTilesConnected(back, prev_back_tile))
			return front;

		// does one of them have road?
		if(GSRoad.IsRoadTile(back))
			return back;

		if(GSRoad.IsRoadTile(front))
			return front;

		// default to OpenTTD front tile if there is no clear benefit to use either of the sides
		return front; 

	}
}


/////

function _SuperLib_Road::ConvertRailCrossingToBridge(rail_tile, prev_tile)
{
	local forward_dir = _SuperLib_Direction.GetDirectionToAdjacentTile(prev_tile, rail_tile);
	local backward_dir = _SuperLib_Direction.TurnDirClockwise45Deg(forward_dir, 4);

	local tile_after = _SuperLib_Direction.GetAdjacentTileInDirection(rail_tile, forward_dir);
	local tile_before = _SuperLib_Direction.GetAdjacentTileInDirection(rail_tile, backward_dir);

	// Check if the tile before rail is a rail-tile. If so, go to prev tile for a maximum of 10 times
	local i = 0;
	while (GSTile.HasTransportType(tile_before, GSTile.TRANSPORT_RAIL) && i < 10)
	{
		tile_before = _SuperLib_Direction.GetAdjacentTileInDirection(tile_before, backward_dir);
		i++;
	}

	// Check if the tile after rail is a rail-tile. If so, go to next tile for a maximum of 10 times (in total with going backwards)
	while (GSTile.HasTransportType(tile_after, GSTile.TRANSPORT_RAIL) && i < 10)
	{
		tile_after = _SuperLib_Direction.GetAdjacentTileInDirection(tile_after, forward_dir);
		i++;
	}

	_SuperLib_Helper.SetSign(tile_after, "after");
	_SuperLib_Helper.SetSign(tile_before, "before");

	// rail-before shouldn't be a rail tile as we came from it, but if it is then it is a multi-rail that
	// previously failed to be bridged
	if (GSTile.HasTransportType(tile_before, GSTile.TRANSPORT_RAIL) ||
			GSBridge.IsBridgeTile(tile_before) ||
			GSTunnel.IsTunnelTile(tile_before))
	{
		_SuperLib_Log.Info("Fail 1", _SuperLib_Log.LVL_INFO);
		return { succeeded = false, permanently = true };
	}

	// If after moving 10 times, there is still a rail-tile, abort
	if (GSTile.HasTransportType(tile_after, GSTile.TRANSPORT_RAIL) ||
			GSBridge.IsBridgeTile(tile_after) ||
			GSTunnel.IsTunnelTile(tile_after))
	{
		_SuperLib_Log.Info("Fail 2", _SuperLib_Log.LVL_INFO);
		return { succeeded = false, permanently = true };
	}


	/* Now tile_before and tile_after are the tiles where the bridge would begin/end */

	// Check that we own those tiles. NoAI 1.0 do not have any constants for checking if a owner is a company or
	// not. -1 seems to indicate that it is not a company. ( = town )
	local tile_after_owner = GSTile.GetOwner(tile_after);
	local tile_before_owner = GSTile.GetOwner(tile_before);
	if ( (tile_before_owner != -1 && !GSCompany.IsMine(tile_before_owner)) || 
			(tile_after_owner != -1 && !GSCompany.IsMine(tile_after_owner)) )
	{
		_SuperLib_Log.Info("Not my road - owned by " + tile_before_owner + ": " + GSCompany.GetName(tile_before_owner) + " and " + tile_after_owner + ":" + GSCompany.GetName(tile_after_owner), _SuperLib_Log.LVL_INFO);
		_SuperLib_Log.Info("Fail 3", _SuperLib_Log.LVL_INFO);
		return { succeeded = false, permanently = true };
	}

	// Check that those tiles do not have 90-deg turns, T-crossings or 4-way crossings
	local left_dir = _SuperLib_Direction.TurnDirAntiClockwise45Deg(forward_dir, 2);
	local right_dir = _SuperLib_Direction.TurnDirClockwise45Deg(forward_dir, 2);

	local bridge_ends = [tile_before, tile_after];
	foreach(end_tile in bridge_ends)
	{
		local left_tile = _SuperLib_Direction.GetAdjacentTileInDirection(end_tile, left_dir);
		local right_tile = _SuperLib_Direction.GetAdjacentTileInDirection(end_tile, right_dir);

		if (GSRoad.AreRoadTilesConnected(end_tile, left_tile) || GSRoad.AreRoadTilesConnected(end_tile, right_tile))
		{
			_SuperLib_Log.Info("Fail 4", _SuperLib_Log.LVL_INFO);
			return { succeeded = false, permanently = true };
		}
	}

	/* Now we know that we can demolish the road on tile_before and tile_after without destroying any road intersections */
	
	/* Check the landscape if it allows for a tunnel or a bridge */ 

	local tunnel = false;
	local bridge = false;

	//local after_dn_slope = _SuperLib_Tile.IsDownSlope(tile_after, forward_dir);
	local after_dn_slope = _SuperLib_Tile.IsUpSlope(tile_after, backward_dir);
	local before_dn_slope = _SuperLib_Tile.IsDownSlope(tile_before, backward_dir);
	local same_height = GSTile.GetMaxHeight(tile_after) == GSTile.GetMaxHeight(tile_before);

	_SuperLib_Log.Info("after_dn_slope = " + after_dn_slope + " | before_dn_slope = " + before_dn_slope + " | same_height = " + same_height, _SuperLib_Log.LVL_INFO);

	if (_SuperLib_Tile.IsDownSlope(tile_after, forward_dir) && _SuperLib_Tile.IsDownSlope(tile_before, backward_dir) &&
		GSTile.GetMaxHeight(tile_after) == GSTile.GetMaxHeight(tile_before)) // Make sure the tunnel entrances are at the same height
	{
		// The rail is on a hill with down slopes at both sides -> can tunnel under the railway.
		tunnel = true;
	}
	else
	{
		if (GSTile.GetMaxHeight(tile_before) == GSTile.GetMaxHeight(tile_after)) // equal (max) height
		{
			// either 
			// _______      _______
			//        \____/
			//         rail
			//
			// or flat 
			// ____________________
			//         rail
			bridge = (_SuperLib_Tile.IsBuildOnSlope_UpSlope(tile_before, backward_dir) && _SuperLib_Tile.IsBuildOnSlope_UpSlope(tile_after, forward_dir)) ||
					(_SuperLib_Tile.IsBuildOnSlope_FlatForBridgeInDirection(tile_before, forward_dir) && _SuperLib_Tile.IsBuildOnSlope_FlatForBridgeInDirection(tile_after, forward_dir));
		}
		else if (GSTile.GetMaxHeight(tile_before) == GSTile.GetMaxHeight(tile_after) + 1) // tile before is one higher
		{
			// _______
			//        \____________
			//         rail

			bridge = _SuperLib_Tile.IsBuildOnSlope_UpSlope(tile_before, backward_dir) && _SuperLib_Tile.IsBuildOnSlope_FlatForBridgeInDirection(tile_after, forward_dir);

		}
		else if (GSTile.GetMaxHeight(tile_before) + 1 == GSTile.GetMaxHeight(tile_after)) // tile after is one higher
		{
			//              _______
			// ____________/
			//         rail

			bridge = _SuperLib_Tile.IsBuildOnSlope_FlatForBridgeInDirection(tile_before, forward_dir) && _SuperLib_Tile.IsBuildOnSlope_UpSlope(tile_after, forward_dir);
		}
		else // more than one level of height difference
		{
		}
	}

	if (!tunnel && !bridge)
	{
		// Can neither make tunnel or build bridge
		_SuperLib_Log.Info("Fail 5", _SuperLib_Log.LVL_INFO);
		return { succeeded = false, permanently = true };
	}

	local bridge_length = GSMap.DistanceManhattan(tile_before, tile_after) + 1;
	local bridge_list = GSBridgeList_Length(bridge_length);
	if (bridge)
	{
		if (bridge_list.IsEmpty())
		{
			_SuperLib_Log.Info("Fail 6", _SuperLib_Log.LVL_INFO);
			return { succeeded = false, permanently = true };
		}
	}

	/* Check that there isn't a bridge that crosses the tile_before or tile_after */

	if (_SuperLib_Tile.GetBridgeAboveStart(tile_before, backward_dir) != -1 || // check for bridge that goes above parallel with the road 
			_SuperLib_Tile.GetBridgeAboveStart(tile_before, _SuperLib_Direction.TurnDirClockwise45Deg(backward_dir, 2)) != -1 || // check for bridge over the tile before rail orthogonal to the road dir
			_SuperLib_Tile.GetBridgeAboveStart(tile_after, _SuperLib_Direction.TurnDirClockwise45Deg(backward_dir, 2)) != -1)    // check for bridge over the tile after rail orthogonal to the road dir
	{
		_SuperLib_Log.Info("There is a nearby bridge that blocks the new bridge", _SuperLib_Log.LVL_INFO);
		_SuperLib_Log.Info("Fail 6.5", _SuperLib_Log.LVL_INFO);
		return { succeeded = false, permanently = true };
	}

	/* Now we know it is possible to bridge/tunnel the rail from tile_before to tile_after */
	
	// Make sure we can afford the construction
	local old_balance = null;
	if(GSCompany.GetBankBalance(GSCompany.COMPANY_SELF) < GSCompany.GetMaxLoanAmount() * 2)
	{
		// Take max loan if our bank balance is less than twice the max loan amount
		old_balance = _SuperLib_Money.MaxLoan();
	}
	if (GSCompany.GetBankBalance(GSCompany.COMPANY_SELF) < _SuperLib_Money.Inflate(20000))
	{
		_SuperLib_Log.Info("Found railway crossing that can be replaced, but bail out because of low founds.", _SuperLib_Log.LVL_INFO);
		_SuperLib_Log.Info("Fail 7", _SuperLib_Log.LVL_INFO);
		if (old_balance != null)  _SuperLib_Money.RestoreLoan(old_balance);
		return { succeeded = false, permanently = false };
	}

	/* Now lets get started removing the old road! */

	{
		// Since it is a railway crossing it is a good idea to remove the entire road in one go.

		/* However in OpenTTD 1.0 removing road will not fail if removing rail at rail crossings
		 * fails. So therefore, remove road one by one and always make sure the road actually got
		 * removed before moving forward so that there is a way out for vehicles.
		 */

		//_SuperLib_Helper.ClearAllSigns();

		local i = 0;
		local forigin_veh_in_the_way_counter = 0;
		local tile1 = tile_before;
		local tile2 = _SuperLib_Direction.GetAdjacentTileInDirection(tile1, forward_dir);
		local up_to_and_tile1 = GSTileList();
		up_to_and_tile1.AddTile(tile1);
		local prev_tile = -1; // the tile before tile1 ( == -1 the first round )

		local MAX_I = 20 + 10 * bridge_length;

		while(i < MAX_I)
		{
			// Reduce the risk of vehicle movements after checking their locations by getting a fresh
			// oopcodes quota
			GSController.Sleep(1);

			// Get a list of all (our) non-crashed vehicles
			local veh_locations = _SuperLib_Vehicle.GetNonCrashedVehicleLocations();

			// Check that no vehicle will become stuck on tile1 or any previous tile because they could have moved to a previous tile during processing/sleep time.
			// Both because previous tiles could have a crashed vehicle so that the road couln't be removed but also because when the vehicles are at the very end
			// of a tile and turns back they are actually on the other tile.
			veh_locations.KeepList(up_to_and_tile1);
			if(!veh_locations.IsEmpty())
			{
				// There is a non-crashed vehicle in the first of two tiles to remove -> wait so it does not get stuck
				_SuperLib_Log.Info("Detected own vehicle in the way -> delay removing road", _SuperLib_Log.LVL_INFO);
				GSController.Sleep(5);
				i++;

				// Check again before trying to remove the road
				continue;
			}

			_SuperLib_Log.Info("Tile is clear -> remove road", _SuperLib_Log.LVL_INFO);
			//_SuperLib_Helper.SetSign(tile1, "clear");

			// Try to remove from tile 1 to tile 2 since tile 1 is clear from own non-crashed vehicles
			local result = GSRoad.RemoveRoadFull(tile1, tile2);
			local last_error = GSError.GetLastError();

			local go_to_next_tile = false;

			// If there were a vehicle in the way
			if(!result && last_error == GSError.ERR_NOT_ENOUGH_CASH)
			{
				_SuperLib_Log.Info("Not enough cach -> wait a little bit", _SuperLib_Log.LVL_INFO);
				GSController.Sleep(5);
				i++;
				continue;
			}
			else if( (tile2 == tile_after) && (!result || GSTile.HasTransportType(tile2, GSTile.TRANSPORT_ROAD)) ) // if failed to remove road at tile_after
			{
				// Special care need to be taken when tile2 is the last tile.
				// Then we can't just move on and check the next iteration when
				// it becomes tile1 if it is ok to skip it or not. In fact
				// we can never skip tile_after as the bridge need to come down
				// there.
				if(last_error == GSError.ERR_VEHICLE_IN_THE_WAY)
				{
					_SuperLib_Log.Info("Failed to remove last tile because vehicle in the way", _SuperLib_Log.LVL_INFO)
					i++;
					GSController.Sleep(5);
					continue;
				}
				else if(last_error = GSError.ERR_UNKNOWN)
				{
					_SuperLib_Log.Info("Couldn't remove last road bit because of unknown error - strange -> wait and try again", _SuperLib_Log.LVL_INFO);
					i++;
					GSController.Sleep(5);
					continue;
				}
				else
				{
					_SuperLib_Log.Info("Couldn't remove last road bit because of unhandled error: " + GSError.GetLastErrorString() + " -> abort", _SuperLib_Log.LVL_INFO);
					break;
				}
			}
			else if( (!result && last_error == GSError.ERR_VEHICLE_IN_THE_WAY) || result && GSTile.HasTransportType(tile1, GSTile.TRANSPORT_ROAD) )
			{	
				_SuperLib_Log.Info("Road was not removed, possible because a vehicle in the way", _SuperLib_Log.LVL_INFO);

				if(tile1 == tile_before)
				{
					// We can never skip to remove road from the tile before the railway crossing(s)
					// as the bridge will start here
					_SuperLib_Log.Info("Since this is the tile before the railway crossing the road MUST be removed -> wait and hope the vehicles go away", _SuperLib_Log.LVL_INFO);
					i++;
					GSController.Sleep(5);
					continue;
				}

				// If the vehicle that is in the way is a crashed vehicle then move on
				// if not, it is possible a competitor vehicle which could be kind to
				// save from being trapped.
				local own_vehicle_locations = _SuperLib_Vehicle.GetVehicleLocations();
				own_vehicle_locations.Valuate(_SuperLib_Helper.ItemValuator);
				own_vehicle_locations.KeepValue(tile1);
				if(own_vehicle_locations.IsEmpty() && forigin_veh_in_the_way_counter < 5)
				{
					// The vehicle in the way is not one of our own crashed vehicles
					_SuperLib_Log.Info("Detected vehicle in the way that is not our own. Wait a bit to see if it moves == non-crashed.", _SuperLib_Log.LVL_INFO);
					forigin_veh_in_the_way_counter++;
					i++
					GSController.Sleep(5);
					continue;
				}

				_SuperLib_Log.Info("Road was not removed, most likely because a crashed vehicle in the way -> move on", _SuperLib_Log.LVL_INFO);

				go_to_next_tile = true;
			}
			else if(!result)
			{
				if (last_error == GSError.ERR_UNKNOWN)
				{
					_SuperLib_Log.Info("Couldn't remove road because of unknown error - strange -> wait and try again", _SuperLib_Log.LVL_INFO);
					_SuperLib_Helper.SetSign(tile1, "strange");
					i++;
					GSController.Sleep(5);
					continue;
				}
				else
				{
					_SuperLib_Log.Info("Couldn't remove road because " + GSError.GetLastErrorString(), _SuperLib_Log.LVL_INFO);
					break;
				}
			}
			else
			{
				// Road was removed
				go_to_next_tile = true;
			}

			if(go_to_next_tile)
			{
				// End _after_ the road has been removed up to tile_after
				if(tile2 == tile_after)
				{
					_SuperLib_Log.Info("Road has been removed up to tile_after -> stop", _SuperLib_Log.LVL_INFO);
					break;
				}

				// Next tile pair
				prev_tile = tile1;
				tile1 = tile2;
				tile2 = _SuperLib_Direction.GetAdjacentTileInDirection(tile1, forward_dir);
				up_to_and_tile1.AddTile(tile1);
			}
		}

		//_SuperLib_Helper.ClearAllSigns();
		
		// Do not just check that tile2 has reached the end -> check that all tiles from tile_before to tile_after do not have
		// transport mode road.
		local remove_failed = false;
		local tile_after_after = _SuperLib_Direction.GetAdjacentTileInDirection(tile_after, forward_dir);
		for(local tile = tile_before; tile != tile_after_after; tile = _SuperLib_Direction.GetAdjacentTileInDirection(tile, forward_dir))
		{
			//_SuperLib_Helper.SetSign(tile, "test");
			if(GSTile.HasTransportType(tile, GSTile.TRANSPORT_ROAD))
			{
				if(tile == tile_before || tile == tile_after)
				{
					// Don't check the end tiles for crashed vehicles as they are not rail tiles
					// Checking them could give false positives from vehicles turning around at the tiles adjacent to the end tiles at the outside of the tiles to be removed.
					remove_failed = true;
					//_SuperLib_Helper.SetSign(tile, "fail");
					break;
				}
				else
				{
					//_SuperLib_Helper.SetSign(tile, "road");

					// Get a list of all (our) non-crashed vehicles
					local veh_locations = _SuperLib_Vehicle.GetNonCrashedVehicleLocations();
					veh_locations.Valuate(_SuperLib_Helper.ItemValuator);

					// Check if there are any non-crashed vehicles on the current tile
					veh_locations.KeepValue(tile);

					if(!veh_locations.IsEmpty()) // Only fail to remove road, if the road bit has a non-crashed (own) vehicle on it
					{
						_SuperLib_Log.Info("One of our own vehicles got stuck while removing the road. -> removing failed", _SuperLib_Log.LVL_INFO);
						remove_failed = true;
						//_SuperLib_Helper.SetSign(tile, "fail");
						break;
					}
				}
			}
		}

		if(remove_failed)
		{
			_SuperLib_Log.Info("Tried to remove road over rail for a while, but failed", _SuperLib_Log.LVL_INFO);

			GSRoad.BuildRoadFull(tile_before, tile_after);
			GSRoad.BuildRoadFull(tile_after, tile_before);

			_SuperLib_Log.Info("Fail 8", _SuperLib_Log.LVL_INFO);
		}
	}

	/* Now lets get started building bridge / tunnel! */

	local build_failed = false;	

	if (tunnel)
	{
		if(!GSTunnel.BuildTunnel(GSVehicle.VT_ROAD, tile_before))
			build_failed = true;
	}
	else if (bridge)
	{
		bridge_list.Valuate(GSBridge.GetMaxSpeed);
		if (!GSBridge.BuildBridge(GSVehicle.VT_ROAD, bridge_list.Begin(), tile_before, tile_after))
			build_failed = true;
	}

	if (build_failed)
	{
		local what = tunnel == true? "tunnel" : "bridge";
		_SuperLib_Log.Warning("Failed to build " + what + " to cross rail because " + GSError.GetLastErrorString() + ". Now try to build road to repair the road.", _SuperLib_Log.LVL_INFO);
		if(GSRoad.BuildRoadFull(tile_before, tile_after))
		{
			_SuperLib_Log.Error("Failed to repair road crossing over rail by building road because " + GSError.GetLastErrorString(), _SuperLib_Log.LVL_INFO);
		}

		_SuperLib_Log.Info("Fail 9", _SuperLib_Log.LVL_INFO);
		if (old_balance != null)  _SuperLib_Money.RestoreLoan(old_balance);
		return { succeeded = false, permanently = false };
	}

	if (old_balance != null)  _SuperLib_Money.RestoreLoan(old_balance);
	return { succeeded = true, bridge_start = tile_before, bridge_end = tile_after };
}

function _SuperLib_Road::RemoveRoadInfrontOfRemovedRoadStopOrDepot(stop_depot_tile, front_tile)
{
	local remove_to_center = GSRoad.AreRoadTilesConnected(front_tile,
			_SuperLib_Direction.GetAdjacentTileInDirection(front_tile, 
				_SuperLib_Direction.GetDirectionToTile(stop_depot_tile, front_tile)));

	local remove_func = remove_to_center? GSRoad.RemoveRoad : GSRoad.RemoveRoadFull;

	local day_start = GSDate.GetCurrentDate();
	local result = remove_func(stop_depot_tile, front_tile);
	while(!result && GSError.GetLastError() == GSError.ERR_VEHICLE_IN_THE_WAY && GSDate.GetCurrentDate() - day_start < 5);
	{
		result = remove_func(stop_depot_tile, front_tile);
	}

	return result;
}

// TODO: Handle bridges/tunnels (perhaps leave long ones)
// TODO: Manage to cross railways
function _SuperLib_Road::RemoveRoadUpToRoadCrossing(start_tile)
{
	//if (!GSTile.HasTransportType(start_tile, GSTile.TRANSPORT_ROAD))
	if (!GSRoad.IsRoadTile(start_tile) || GSRoad.IsDriveThroughRoadStationTile(start_tile))
	{
		_SuperLib_Log.Info("RemoveRoadUpToRoadCrossing fails because start tile do not have road", _SuperLib_Log.LVL_DEBUG);
		return false;
	}

	local curr_tile = start_tile;
	local next_tile = 0;

	//while(GSTile.HasTransportType(curr_tile, GSTile.TRANSPORT_ROAD))
	while(GSCompany.IsMine(GSTile.GetOwner(curr_tile)) &&
			(
				// Is road or bridge/tunnel
				(GSRoad.IsRoadTile(curr_tile) && !GSRoad.IsDriveThroughRoadStationTile(curr_tile)) ||
				GSTile.HasTransportType(curr_tile, GSTile.TRANSPORT_ROAD) ||
				GSBridge.IsBridgeTile(curr_tile) || GSTunnel.IsTunnelTile(curr_tile)
			))
	{
		// Check for bridge/tunnel
		local has_bridge_tunnel = false;
		local bridge_tunnel_other_end = -1;
		if(GSBridge.IsBridgeTile(curr_tile))
		{
			has_bridge_tunnel = true;
			bridge_tunnel_other_end = GSBridge.GetOtherBridgeEnd(curr_tile);
		}
		else if(GSTunnel.IsTunnelTile(curr_tile))
		{
			has_bridge_tunnel = true;
			bridge_tunnel_other_end = GSTunnel.GetOtherTunnelEnd(curr_tile);
		}

		if(has_bridge_tunnel) // has bridge or tunnel -> go to other end
		{
			_SuperLib_Helper.SetSign(curr_tile, "bridge|tunnel");
			local dir = _SuperLib_Direction.GetDirectionToTile(curr_tile, bridge_tunnel_other_end);
			local length = GSMap.DistanceManhattan(curr_tile, bridge_tunnel_other_end) + 1;

			// Go to the tile after the bridge
			curr_tile = bridge_tunnel_other_end; 
			next_tile = _SuperLib_Direction.GetAdjacentTileInDirection(curr_tile, dir); // next tile after bridge

			// Remove bridges/tunnels shorter than length 8
			if(length < 8)
			{
				GSTile.DemolishTile(curr_tile);
			}
			_SuperLib_Helper.SetSign(curr_tile, "curr");
			_SuperLib_Helper.SetSign(next_tile, "next");
		}
		else
		{
			_SuperLib_Helper.SetSign(curr_tile, "curr");

			// Curr tile is neither a bridge nor a tunnel
			// Find next tile
			local neighbours = _SuperLib_Tile.GetNeighbours4MainDir(curr_tile);
			neighbours.Valuate(GSRoad.AreRoadTilesConnected, curr_tile);
			neighbours.KeepValue(1);

			// > 1 neighbours -> curr_tile is a road crossing tile
			if(neighbours.Count() > 1)
			{
				_SuperLib_Log.Info("RemoveRoadUpToRoadCrossing stops because road crossing found", _SuperLib_Log.LVL_DEBUG);
				break;
			}

			if(neighbours.Count() == 0)
			{
				// This should really only happen if the start tile contains a road bit that is not connected with anything
				_SuperLib_Log.Info("RemoveRoadUpToRoadCrossing stops because no connected neighbours found", _SuperLib_Log.LVL_DEBUG);
				break;
			}

			// Set next tile
			next_tile = neighbours.Begin();
		}

		// Remove road from curr_tile
		if(!GSRoad.RemoveRoad(curr_tile, next_tile)) 
		{
			// Abort if road removal fails
			_SuperLib_Log.Info("RemoveRoadUpToRoadCrossing: Remove road failed", _SuperLib_Log.LVL_INFO);
			break;
		}

		// In case the road tile has partial connections to neighbour tiles remove them
		local neighbours = _SuperLib_Tile.GetNeighbours4MainDir(curr_tile);
		foreach(tile, _ in neighbours)
		{
			// Just try once; no wait for vehicles to move away.
			GSRoad.RemoveRoad(curr_tile, tile);
		}

		// If next tile is rail, then we need to go to the next tile after that, since there won't be
		// a road stump at the rail.
		if(GSTile.HasTransportType(next_tile, GSTile.TRANSPORT_RAIL))
		{
			local dir = _SuperLib_Direction.GetDirectionToTile(curr_tile, next_tile);

			_SuperLib_Log.Info("RemoveRoadUpToRoadCrossing: rail move " + _SuperLib_Direction.GetDirString(dir), _SuperLib_Log.LVL_INFO);
			next_tile = _SuperLib_Direction.GetAdjacentTileInDirection(next_tile, dir);

			_SuperLib_Helper.SetSign(next_tile, "new next");
		}

		// Go to next tile
		curr_tile = next_tile;

	}

	_SuperLib_Helper.SetSign(curr_tile, "end");

	_SuperLib_Log.Info("RemoveRoadUpToRoadCrossing done", _SuperLib_Log.LVL_DEBUG);

	return true;
}

/* static */ function _SuperLib_Road::FixRoadStopFront(road_stop_tile)
{
	_SuperLib_Log.Info("FixRoadStopFront start", _SuperLib_Log.LVL_DEBUG);


	
	{
		// First test if already flat?
		local flat = false;
		local curr_tile = GSRoad.GetRoadStationFrontTile(road_stop_tile);
		if(GSRoad.GetNeighbourRoadCount(curr_tile) >= 2) return false; // Don't attempt to do anything if front tile is connected to anything more than the road stop
		local dir = _SuperLib_Direction.GetDirectionToAdjacentTile(road_stop_tile, curr_tile);
		local flat = _SuperLib_Tile.IsBuildOnSlope_FlatInDirection(curr_tile, dir);

		if(flat)
		{
			_SuperLib_Log.Info("FixRoadStopFront already flat : " + GSTile.GetSlope(curr_tile) +
					" ne: " + GSTile.SLOPE_NE +
					" " + GSTile.SLOPE_NW +
					" " + GSTile.SLOPE_SW +
					" " + GSTile.SLOPE_SE +
					" steep n: " + GSTile.SLOPE_STEEP_N +
					" " + GSTile.SLOPE_STEEP_W +
					" " + GSTile.SLOPE_STEEP_S +
					" " + GSTile.SLOPE_STEEP_E
					, _SuperLib_Log.LVL_DEBUG);
			return true;
		}

		// Next, try to build road without modifying the landscape
		local next_tile = _SuperLib_Direction.GetAdjacentTileInDirection(curr_tile, dir);
		if(GSRoad.GetNeighbourRoadCount(next_tile) >= 2) return false;
		local n = 0;
		while(!flat && GSRoad.BuildRoad(curr_tile, next_tile))
		{
			_SuperLib_Log.Info("FixRoadStopFront road build", _SuperLib_Log.LVL_DEBUG);
			curr_tile = next_tile;
			next_tile = _SuperLib_Direction.GetAdjacentTileInDirection(curr_tile, dir);
			if(GSRoad.GetNeighbourRoadCount(next_tile) >= 2) return false;
			flat = _SuperLib_Tile.IsBuildOnSlope_FlatInDirection(curr_tile, dir);
			++n;

			// Abort attempt to extend road if no success after a few tiles
			if(!flat && n > 3)
			{
				// clean up road
				_SuperLib_Log.Info("FixRoadStopFront road cleanup", _SuperLib_Log.LVL_DEBUG);
				_SuperLib_Road.RemoveRoadUpToRoadCrossing(curr_tile);
				_SuperLib_Log.Info("FixRoadStopFront road cleanup done", _SuperLib_Log.LVL_DEBUG);
				break;
			}
		}

		// Succeeded?
		if(flat) return true;
	}
		
	// Remove the curr_tile tile road and try some landscaping
	{
		local prev_tile = road_stop_tile;
		local curr_tile = GSRoad.GetRoadStationFrontTile(road_stop_tile);

		// Try to adjust curr tile
		for(local n = 0; n < 3; n++)
		{
			_SuperLib_Log.Info("FixRoadStopFront pre fix tile", _SuperLib_Log.LVL_DEBUG);

			if(GSRoad.GetNeighbourRoadCount(curr_tile) >= 2) return false; // don't destroy connected road bits
			GSTile.DemolishTile(curr_tile);
			local target_height = GSTile.GetMaxHeight(prev_tile);
			foreach(corner_slope in [
						[GSTile.CORNER_W, GSTile.SLOPE_W], 
						[GSTile.CORNER_S, GSTile.SLOPE_S], 
						[GSTile.CORNER_E, GSTile.SLOPE_E], 
						[GSTile.CORNER_N, GSTile.SLOPE_N]
					])
			{
				local corner = corner_slope[0];
				local slope = corner_slope[1];

				local height = GSTile.GetCornerHeight(curr_tile, corner);
				if(height > target_height)
					GSTile.LowerTile(curr_tile, slope);
				else if(height < target_height)
					GSTile.RaiseTile(curr_tile, slope);
			}

			GSRoad.BuildRoad(curr_tile, prev_tile);

			_SuperLib_Log.Info("FixRoadStopFront post fix tile", _SuperLib_Log.LVL_DEBUG);

			local dir = _SuperLib_Direction.GetDirectionToAdjacentTile(prev_tile, curr_tile);
			local flat = _SuperLib_Tile.IsBuildOnSlope_FlatInDirection(curr_tile, dir);

			if(flat) return true;

			prev_tile = curr_tile;
			curr_tile = _SuperLib_Direction.GetAdjacentTileInDirection(curr_tile, dir);

			// Ensure next tile can be connected back to the road that connects to the bus stop
			if(!GSRoad.BuildRoad(curr_tile, prev_tile)) return false;
		}
	}

	return false;
}
