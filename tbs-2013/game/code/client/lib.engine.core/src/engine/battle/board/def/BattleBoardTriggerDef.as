package engine.battle.board.def
{
	import engine.battle.ability.effect.model.EffectTag;

	public class BattleBoardTriggerDef
	{
		public var id : String;
		public var effecttag : EffectTag;
		public var ability : String;
		public var pulse : Boolean;

		public function BattleBoardTriggerDef()
		{
		}
	}
}
