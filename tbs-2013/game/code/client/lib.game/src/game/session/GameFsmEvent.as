package game.session
{
	import flash.events.Event;
	
	public class GameFsmEvent extends Event
	{
		public static const PLAYERS_ONLINE : String = "GameFsmEvent.PLAYERS_ONLINE";
		
		public function GameFsmEvent(type : String, bubbles : Boolean = false, cancelable : Boolean = false)
		{
			super(type, bubbles, cancelable);
		}
	}
}