package tbs.srv.data
{
	import engine.core.logging.ILogger;

	public class FriendOnlineData
	{
		public var account_id : int;
		public var online : Boolean;

		public function FriendOnlineData()
		{
		}

		public function parseJson(json : Object, logger : ILogger) : void
		{
			account_id = json.account_id;
			online = json.online;
		}
	}
}
