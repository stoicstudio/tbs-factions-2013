package tbs.srv.data
{
	import engine.core.logging.ILogger;

	public class LobbyVariationData extends LobbyData
	{
		public var unit_id : String;
		public var variation : int;

		public function LobbyVariationData()
		{
		}

		override public function parseJson(json : Object, logger : ILogger) : void
		{
			super.parseJson(json, logger);
			unit_id = json.unit_id;
			variation = json.variation;
		}
	}
}
