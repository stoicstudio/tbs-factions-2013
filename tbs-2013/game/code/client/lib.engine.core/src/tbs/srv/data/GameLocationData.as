package tbs.srv.data
{
	import engine.core.logging.ILogger;

	public class GameLocationData
	{
		public var account_id : int;
		public var location : String;

		public function GameLocationData()
		{
		}

		public function parseJson(json : Object, logger : ILogger) : void
		{
			account_id = json.account_id;
			location = json.location;
		}
	}
}
