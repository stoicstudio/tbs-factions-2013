package engine.battle.ability.model
{
	import engine.battle.board.model.IBattleEntity;

	public class BattleAbilityRetargetInfo
	{
		public var target : IBattleEntity;
		public var insert : IBattleAbility;

		public function BattleAbilityRetargetInfo(target : IBattleEntity, insert : IBattleAbility) : void
		{
			this.target = target;
			this.insert = insert;
		}

		public function toString() : String
		{
			return "[" + target + " " + insert + "]";
		}
	}
}
