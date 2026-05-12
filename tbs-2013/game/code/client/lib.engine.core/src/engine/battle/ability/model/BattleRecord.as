package engine.battle.ability.model
{
	import engine.stat.model.IStatHistoryTurnProvider;
	import engine.stat.model.StatHistoryTimeline;

	public class BattleRecord implements IStatHistoryTurnProvider
	{
		public var strengthDamageDone : StatHistoryTimeline;
		public var armorDamageDone : StatHistoryTimeline;
		public var strengthDamageTaken : StatHistoryTimeline;
		public var armorDamageTaken : StatHistoryTimeline;
		public var kills : StatHistoryTimeline;

		private var _turn : int;

		public function BattleRecord()
		{
			strengthDamageDone = new StatHistoryTimeline(this);
			armorDamageDone = new StatHistoryTimeline(this);
			strengthDamageTaken = new StatHistoryTimeline(this);
			armorDamageTaken = new StatHistoryTimeline(this);
			kills = new StatHistoryTimeline(this);
		}

		public function get turn() : int
		{
			return _turn;
		}

		public function nextTurn() : void
		{
			++_turn;
		}

	}
}
