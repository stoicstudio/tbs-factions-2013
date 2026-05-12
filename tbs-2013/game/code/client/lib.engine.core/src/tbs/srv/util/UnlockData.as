package tbs.srv.util
{
	import engine.core.logging.ILogger;

	public class UnlockData
	{
		public static const schema : Object =
			{
				name: "UnlockData",
				type: "object",
				properties: {
					account_id: {type: "number"},
					unlock_id: {type: "string"},
					unlock_time: {type: "number"},
					unlock_duration: {type: "number"}
				}
			};

		public var account_id : int;
		public var unlock_id : String;
		public var unlock_time : Number;
		public var unlock_duration : Number;

		public function UnlockData()
		{
		}

		public function parseJson(json : Object, logger : ILogger) : void
		{
			account_id = json.account_id;
			unlock_id = json.unlock_id;
			unlock_time = json.unlock_time;
			unlock_duration = json.unlock_duration;		
		}
	}
}
