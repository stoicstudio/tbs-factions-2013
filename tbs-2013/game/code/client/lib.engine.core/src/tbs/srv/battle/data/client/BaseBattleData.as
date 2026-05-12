package tbs.srv.battle.data.client
{
	import avmplus.getQualifiedClassName;

	import engine.core.logging.ILogger;

	public class BaseBattleData
	{
		public var user_id : int;
		public var battle_id : String;

		public function BaseBattleData()
		{
		}

		public function setupBattleData(user_id : int, battle_id : String) : void
		{
			this.user_id = user_id;
			this.battle_id = battle_id;
		}

		public function parseJson(json : Object, logger : ILogger) : void
		{
			user_id = json.user_id;
			battle_id = json.battle_id;
		}

		public function toString() : String
		{
			return getQualifiedClassName(this) + " [user=" + user_id + " battle=" + battle_id + "]";
		}
	}
}
