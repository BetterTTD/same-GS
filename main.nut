/** Import SuperLib for GameScript **/
import("util.superlib", "SuperLib", 36);
Result <- SuperLib.Result;
Log <- SuperLib.Log;
Helper <- SuperLib.Helper;
Tile <- SuperLib.Tile;
Direction <- SuperLib.Direction;
Town <- SuperLib.Town;
Industry <- SuperLib.Industry;
Story <- SuperLib.Story;

require("version.nut"); // get SELF_VERSION

class MainClass extends GSController 
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

function MainClass::Start()
{

  if (Helper.HasWorldGenBug()) GSController.Sleep(1);

  // this.Init();

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

/*
 * This method is called during the initialization of your Game Script.
 * As long as you never call Sleep() and the user got a new enough OpenTTD
 * version, all initialization happens while the world generation screen
 * is shown. This means that even in single player, company 0 doesn't yet
 * exist. The benefit of doing initialization in world gen is that commands
 * that alter the game world are much cheaper before the game starts.
 */
function MainClass::Init()
{
  if (this._loaded_data != null) {
    // Copy loaded data from this._loaded_data to this.*
    // or do whatever you like with the loaded data
  } else {
    // construct goals etc.
  }

  // Indicate that all data structures has been initialized/restored.
  this._init_done = true;
  this._loaded_data = null; // the loaded data has no more use now after that _init_done is true.
}

/*
 * This method handles incoming events from OpenTTD.
 */
function MainClass::HandleEvents()
{
  if(GSEventController.IsEventWaiting()) {
    local ev = GSEventController.GetNextEvent();
    if (ev == null) return;

    local ev_type = ev.GetEventType();
    switch (ev_type) {
      case GSEvent.ET_COMPANY_NEW: {
        local company_event = GSEventCompanyNew.Convert(ev);
        local company_id = "255";

        // Here you can welcome the new company
        Story.ShowMessage(company_id, GSText(GSText.STR_MOTD, company_id));
        break;
      }

      // other events ...
    }
  }
}


 // * Called by our main loop when a new month has been reached.
 
function MainClass::EndOfMonth()
{
}

/*
 * Called by our main loop when a new year has been reached.
 */
function MainClass::EndOfYear()
{
}

/*
 * This method is called by OpenTTD when an (auto)-save occurs. You should
 * return a table which can contain nested tables, arrays of integers,
 * strings and booleans. Null values can also be stored. Class instances and
 * floating point values cannot be stored by OpenTTD.
 */
function MainClass::Save()
{
  Log.Info("Saving data to savegame", Log.LVL_INFO);

  // In case (auto-)save happens before we have initialized all data,
  // save the raw _loaded_data if available or an empty table.
  if (!this._init_done) {
    return this._loaded_data != null ? this._loaded_data : {};
  }

  return { 
    some_data = null,
    //some_other_data = this._some_variable,
  };
}

/*
 * When a game is loaded, OpenTTD will call this method and pass you the
 * table that you sent to OpenTTD in Save().
 */
function MainClass::Load(version, tbl)
{
  Log.Info("Loading data from savegame made with version " + version + " of the game script", Log.LVL_INFO);

  // Store a copy of the table from the save game
  // but do not process the loaded data yet. Wait with that to Init
  // so that OpenTTD doesn't kick us for taking too long to load.
  this._loaded_data = {}
    foreach(key, val in tbl) {
    this._loaded_data.rawset(key, val);
  }

  this._loaded_from_version = version;
}
