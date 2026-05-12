package tbs.srv.data
{
	import engine.core.logging.ILogger;

	public class FriendData
	{
		public var id : int;
		public var display_name : String;
		public var location : String;
		public var online : Boolean;
		public var steam_id : String;
		public var avatar128 : String;
		public var avatar64 : String;
		public var avatar32 : String;
		public var wins : int;
		public var losses : int;
		public var last_battle_time : uint;

		public function FriendData()
		{
		}

		public function toString() : String
		{
			return "FriendData: [id=" + id + ", display_name=" + display_name + ", location=" + location + ", online=" + online + ", record=" + wins + ":" + losses + "]";
		}

		public function parseJson(json : Object, logger : ILogger) : void
		{
			id = json.id;

			display_name = json.display_name;
			location = json.location;
			online = json.online;
			steam_id = json.steam_id;
			avatar128 = json.avatar128;
			avatar64 = json.avatar64;
			avatar32 = json.avatar32;
			wins = json.wins;
			losses = json.losses;
			last_battle_time = json.last_battle_time;
		}
	}
}
