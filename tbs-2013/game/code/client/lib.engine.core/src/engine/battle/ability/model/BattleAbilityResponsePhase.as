package engine.battle.ability.model
{
	import engine.core.util.Enum;

	public class BattleAbilityResponsePhase extends Enum
	{
		public static const PRE_COMPLETE : BattleAbilityResponsePhase = new BattleAbilityResponsePhase("PRE_COMPLETE", enumCtorKey);
		public static const POST_COMPLETE : BattleAbilityResponsePhase = new BattleAbilityResponsePhase("POST_COMPLETE", enumCtorKey);

		public function BattleAbilityResponsePhase(name : String, key : *) : void
		{
			super(name, key);
		}
	}

}
