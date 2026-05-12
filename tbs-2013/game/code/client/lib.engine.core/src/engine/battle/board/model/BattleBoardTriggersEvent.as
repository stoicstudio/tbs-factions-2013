package engine.battle.board.model
{
	import flash.events.Event;

	public class BattleBoardTriggersEvent extends Event
	{
		public static const ADDED : String = "BattleBoardTriggerEvent.ADDED";
		public static const REMOVED : String = "BattleBoardTriggerEvent.REMOVED";

		public var trigger : BattleBoardTrigger;

		public function BattleBoardTriggersEvent(type : String, trigger : BattleBoardTrigger)
		{
			super(type);
			this.trigger = trigger;
		}
	}
}
