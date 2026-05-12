package engine.stat.model
{
	import flash.events.Event;

	public class StatEvent extends Event
	{
		public static const CHANGE : String = "StatEvent.CHANGE";
		public static const BASE_CHANGE : String = "StatEvent.BASE_CHANGE";

		public var delta : *;

		public function StatEvent(type : String, delta : *)
		{
			super(type);
			this.delta = delta;
		}

		public function get stat() : Stat
		{
			return target as Stat;
		}
	}
}
