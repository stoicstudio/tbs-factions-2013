package tbs.srv.battle.data
{
	import engine.core.logging.ILogger;

	public class BattlePartyData
	{
		public var user : int;
		public var team : String;
		public var display_name : String;
		public var defs : Array = [];
		public var match_handle : int;
		// in seconds
		public var timer : int;
		public var party_index : int;

		public function BattlePartyData()
		{
		}

		public function parseJson(json : Object, logger : ILogger) : void
		{
			user = json.user;
			team = json.team;
			display_name = json.display_name;
			defs = json.defs;
			match_handle = json.match_handle;
			timer = json.timer;
			party_index = json.party_index;
		}
	}
}
