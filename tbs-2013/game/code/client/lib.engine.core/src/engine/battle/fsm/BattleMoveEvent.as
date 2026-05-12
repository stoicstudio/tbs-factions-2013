package engine.battle.fsm
{
	import flash.events.Event;

	public class BattleMoveEvent extends Event
	{
		public static const MOVE_CHANGED : String = "BattleMoveEvent.MOVE_CHANGED";
		public static const EXECUTED : String = "BattleMoveEvent.EXECUTED";
		public static const WAYPOINT : String = "BattleMoveEvent.WAYPOINT";
		public static const COMMITTED : String = "BattleMoveEvent.COMMITTED";
		public static const INTERRUPTED : String = "BattleMoveEvent.INTERRUPTED";
		public static const EXECUTING : String = "BattleMoveEvent.EXECUTING";
		public static const FLOOD_CHANGED : String = "BattleMoveEvent.FLOOD_CHANGED";
		public static const INTERSECT_ENTITY : String = "BattleMoveEvent.INTERSECT_ENTITY";

		public function BattleMoveEvent(type : String)
		{
			super(type);
		}
	}
}
