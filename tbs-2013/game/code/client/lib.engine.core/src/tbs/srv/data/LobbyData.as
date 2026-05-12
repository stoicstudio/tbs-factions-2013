package tbs.srv.data
{
	import engine.core.logging.ILogger;

	public class LobbyData
	{
		public var lobby_id : int;
		public var account_id : int;
		public var account_display_name : String;
		public var type : String;

		public function LobbyData()
		{
		}

		public function parseJson(json : Object, logger : ILogger) : void
		{
			lobby_id = json.lobby_id;
			account_id = json.account_id;
			account_display_name = json.account_display_name;
			type = json.type;
		}
	}
}
