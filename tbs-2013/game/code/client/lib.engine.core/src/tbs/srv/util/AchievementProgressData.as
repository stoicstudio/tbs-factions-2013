package tbs.srv.util
{
	import engine.core.logging.ILogger;

	public class AchievementProgressData
	{
		public var account_id : int;
		public var session_id : int;
		public var achievement_type : String;
		public var delta : int;
		public var total : int;
		public var handle : String;
		public var acquired : Vector.<String> = new Vector.<String>;

		public function AchievementProgressData()
		{
		}

		public function toString() : String
		{
			return "AchievementProgressData{account_id:" + account_id + ", session_id:" + session_id + ", achievement_type:\"" + achievement_type + "\", delta:" + delta + ", total:" + total + ", handle:\"" +
				handle + "\", acquired:[" + acquired + "]}";
		}

		public function parseJson(json : Object, logger : ILogger) : void
		{
			account_id = json.account_id;
			session_id = json.session_id;
			achievement_type = json.achievement_type;
			delta = json.delta;
			total = json.total;
			handle = json.handle;

			for each (var s : String in json.acquired)
			{
				acquired.push(s);
			}
		}
	}
}
