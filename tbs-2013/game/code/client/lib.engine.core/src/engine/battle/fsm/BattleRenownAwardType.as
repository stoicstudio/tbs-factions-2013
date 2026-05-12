package engine.battle.fsm
{
	import engine.core.util.Enum;

	public class BattleRenownAwardType extends Enum
	{
		public static const KILLS : BattleRenownAwardType = new BattleRenownAwardType("KILLS", enumCtorKey);
		public static const UNDERDOG : BattleRenownAwardType = new BattleRenownAwardType("UNDERDOG", enumCtorKey);
		public static const DAILY : BattleRenownAwardType = new BattleRenownAwardType("DAILY", enumCtorKey);
		public static const FRIEND : BattleRenownAwardType = new BattleRenownAwardType("FRIEND", enumCtorKey);
		public static const BOOST : BattleRenownAwardType = new BattleRenownAwardType("BOOST", enumCtorKey);
		public static const STREAK : BattleRenownAwardType = new BattleRenownAwardType("STREAK", enumCtorKey);
		public static const EXPERT : BattleRenownAwardType = new BattleRenownAwardType("EXPERT", enumCtorKey);
		public static const WIN : BattleRenownAwardType = new BattleRenownAwardType("WIN", enumCtorKey);

		public function BattleRenownAwardType(name : String, key : Object)
		{
			super(name, key);
		}
	}
}
