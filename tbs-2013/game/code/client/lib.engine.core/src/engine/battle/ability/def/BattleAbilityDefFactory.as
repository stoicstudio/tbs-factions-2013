package engine.battle.ability.def
{
	import engine.ability.def.AbilityDefFactory;

	public class BattleAbilityDefFactory extends AbilityDefFactory
	{

		public function BattleAbilityDefFactory()
		{
		}

		public function fetchBattleAbilityDef(id : String) : BattleAbilityDef
		{
			return fetch(id) as BattleAbilityDef;
		}
	}
}
