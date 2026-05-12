package tbs.srv.battle.data.client
{
	import engine.core.logging.ILogger;

	public class BattleSyncData extends BaseBattleTurnData
	{
		public var team : String;
		public var hash : int;

		public function BattleSyncData()
		{
		}

		override public function parseJson(json : Object, logger : ILogger) : void
		{
			super.parseJson(json, logger);

			team = json.team;
			hash = json.hash;
		}

	}
}
