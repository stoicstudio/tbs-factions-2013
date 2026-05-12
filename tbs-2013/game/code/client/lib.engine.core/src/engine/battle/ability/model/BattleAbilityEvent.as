package engine.battle.ability.model
{
	import flash.events.Event;

	public class BattleAbilityEvent extends Event
	{
		public static const ABILITY_PRE_COMPLETE : String = "BattleAbilityEvent.ABILITY_PRE_COMPLETE";
		public static const ABILITY_POST_COMPLETE : String = "BattleAbilityEvent.ABILITY_POST_COMPLETE";
		public static const ABILITY_AND_CHILDREN_COMPLETE : String = "BattleAbilityEvent.ABILITY_AND_CHILDREN_COMPLETE";
		public static const FINAL_COMPLETE : String = "BattleAbilityEvent.FINAL_COMPLETE";
		public static const EXECUTING : String = "BattleAbilityEvent.EXECUTING";
		public static const INCOMPLETES_EMPTY : String = "BattleAbilityEvent.INCOMPLETES_EMPTY";

		public var ability : IBattleAbility;

		public function BattleAbilityEvent(type : String, ability : IBattleAbility)
		{
			super(type, false, false);
			this.ability = ability;
		}
	}
}
