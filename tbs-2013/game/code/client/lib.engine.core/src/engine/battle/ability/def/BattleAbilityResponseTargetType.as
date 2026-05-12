package engine.battle.ability.def
{
	import engine.core.util.Enum;

	public class BattleAbilityResponseTargetType extends Enum
	{
		public static const SELF : BattleAbilityResponseTargetType = new BattleAbilityResponseTargetType("SELF", enumCtorKey);
		public static const CASTER : BattleAbilityResponseTargetType = new BattleAbilityResponseTargetType("CASTER", enumCtorKey);
		public static const TARGET : BattleAbilityResponseTargetType = new BattleAbilityResponseTargetType("TARGET", enumCtorKey);

		public function BattleAbilityResponseTargetType(name : String, key : *) : void
		{
			super(name, key);
		}
	}

}
