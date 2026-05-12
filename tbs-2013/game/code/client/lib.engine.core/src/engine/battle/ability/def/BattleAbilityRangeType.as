package engine.battle.ability.def
{
	import engine.core.util.Enum;

	public class BattleAbilityRangeType extends Enum
	{
		public static const NONE : BattleAbilityRangeType = new BattleAbilityRangeType("NONE", enumCtorKey);
		public static const MELEE : BattleAbilityRangeType = new BattleAbilityRangeType("MELEE", enumCtorKey);
		public static const RANGED : BattleAbilityRangeType = new BattleAbilityRangeType("RANGED", enumCtorKey);

		public function BattleAbilityRangeType(name : String, secret : Object)
		{
			super(name, secret);
		}
	}
}
