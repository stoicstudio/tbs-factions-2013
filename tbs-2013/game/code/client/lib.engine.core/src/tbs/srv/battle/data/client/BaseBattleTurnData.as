package tbs.srv.battle.data.client
{

	import engine.core.logging.ILogger;

	import flash.utils.getQualifiedClassName;

	public class BaseBattleTurnData extends BaseBattleData
	{
		public var turn : int;
		public var entity : String;
		public var ordinal : int;

		public function BaseBattleTurnData()
		{
		}

		public function setupBattleTurnData(user_id : int, battle_id : String, turn : int, entity : String, ordinal : int) : void
		{
			setupBattleData(user_id, battle_id);
			this.turn = turn;
			this.entity = entity;
			this.ordinal = ordinal;
		}

		override public function parseJson(json : Object, logger : ILogger) : void
		{
			super.parseJson(json, logger);
			turn = json.turn;
			entity = json.entity;
			ordinal = json.ordinal;
		}

		override public function toString() : String
		{
			return getQualifiedClassName(this) + " [" + super.toString() + ", turn=" + turn + " entity=" + entity + "]";
		}
	}
}
