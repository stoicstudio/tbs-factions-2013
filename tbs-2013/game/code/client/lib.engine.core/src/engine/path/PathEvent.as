package engine.path
{
	import flash.events.Event;

	public class PathEvent extends Event
	{
		public static const EVENT_PATH_STATUS_CHANGED : String = "EVENT_PATH_STATUS_CHANGED";

		public function PathEvent(type : String, bubbles : Boolean = false, cancelable : Boolean = false)
		{
			super(type, bubbles, cancelable);
		}

		public function get path() : IPath
		{
			return this.target as IPath;
		}
	}
}
