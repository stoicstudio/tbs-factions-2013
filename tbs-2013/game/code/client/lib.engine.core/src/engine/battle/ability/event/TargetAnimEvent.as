package engine.battle.ability.event
{
	import engine.anim.view.IAnim;
	import engine.battle.board.model.IBattleEntity;

	import flash.events.Event;

	public class TargetAnimEvent extends Event
	{
		public static const EVENT : String = "TargetAnimEvent.EVENT";

		public var animId : String;
		public var eventId : String;

		public function TargetAnimEvent(type : String, animId : String, eventId : String)
		{
			super(type);

			this.animId = animId;
			this.eventId = eventId;
		}

		public function get entity() : IBattleEntity
		{
			return target as IBattleEntity;
		}
	}
}
