package engine.battle.fsm
{
	import engine.core.fsm.StateDataEnum;

	public class BattleStateDataEnum extends StateDataEnum
	{
		public static const BOARD : BattleStateDataEnum = new BattleStateDataEnum("BOARD", enumCtorKey);
		public static const ERROR : BattleStateDataEnum = new BattleStateDataEnum("ERROR", enumCtorKey);
		public static const FINISHED : BattleStateDataEnum = new BattleStateDataEnum("FINISHED", enumCtorKey);
		public static const VICTORIOUS_TEAM : BattleStateDataEnum = new BattleStateDataEnum("VICTORIOUS_TEAM", enumCtorKey);

		public function BattleStateDataEnum(name : String, key : Object)
		{
			super(name, key);
		}
	}
}
