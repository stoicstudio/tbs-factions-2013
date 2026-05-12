package tbs.srv.data
{
	import engine.core.logging.ILogger;

	public class LeaderboardData
	{
		public var leaderboard_type : String;
		public var tourney_id : int;
		public var tourney_name : String;
		public var display_names : Vector.<String> = new Vector.<String>;
		public var values : Vector.<Number> = new Vector.<Number>;
		public var user_display_name : String;
		public var user_value : Number;
		public var user_rank : int;

		public function LeaderboardData()
		{
		}

		public function parseJson(json : Object, logger : ILogger) : void
		{
			leaderboard_type = json.leaderboard_type;

			for each (var display_name : String in json.display_names)
			{
				display_names.push(display_name);
			}

			for each (var value : Number in json.values)
			{
				values.push(value);
			}

			user_display_name = json.user_display_name;
			user_value = json.user_value;
			user_rank = json.user_rank;
			tourney_id = json.tourney_id;
			tourney_name = json.tourney_name;
		}
	}
}
