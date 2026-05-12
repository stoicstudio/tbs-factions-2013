package engine.tile
{
	import flash.events.Event;

	public class TilesEvent extends Event
	{
		public static const TILE_FLYTEXT : String = "TilesEvent.TILE_FLYTEXT";

		public function TilesEvent(type : String)
		{
			super(type, false, false);
		}
	}
}
