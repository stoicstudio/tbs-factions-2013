package tbs.srv.data
{
	import engine.core.logging.ILogger;

	public class LobbyPartyData extends LobbyData
	{
		public var party : Array = [];

		public function LobbyPartyData()
		{
		}

		override public function parseJson(json : Object, logger : ILogger) : void
		{
			super.parseJson(json, logger);
			party = json.party;
		}
	}
}
