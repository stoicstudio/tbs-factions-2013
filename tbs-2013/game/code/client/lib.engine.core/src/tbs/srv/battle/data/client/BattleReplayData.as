package tbs.srv.battle.data.client
{

	import engine.core.logging.ILogger;

	public class BattleReplayData extends BaseBattleData
	{
		//public var battle_msgs : Vector.<Object> = new Vector.<Object>;
		public var battle_msgs : Array = [];

		public function BattleReplayData()
		{
		}

		override public function parseJson(json : Object, logger : ILogger) : void
		{
			super.parseJson(json, logger);
			battle_msgs = json.battle_msgs;
		}
	}
}
