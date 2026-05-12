package tbs.srv.battle.data.client
{
	import engine.core.logging.ILogger;

	public class BattleKilledData extends BaseBattleTurnData
	{
		public var killer : String;
		public var killedparty : int;
		public var killerparty : int;

		public function BattleKilledData()
		{
		}

		override public function parseJson(json : Object, logger : ILogger) : void
		{
			super.parseJson(json, logger);

			killer = json.killer;
			killedparty = json.killedparty;
			killerparty = json.killerparty;
		}
	}
}
