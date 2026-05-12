package tbs.srv.util
{
	import engine.core.logging.ILogger;

	import flash.events.Event;
	import flash.events.EventDispatcher;

	public class TourneyProgressData extends EventDispatcher
	{
		public var tourney_id : int;
		public var tourney_name : String;
		public var battle_count : int;
		public var rank : int;
		public var clock_skew : Number = 0;

		public function TourneyProgressData()
		{
		}

		override public function toString() : String
		{
			return "TourneyProgressData " + tourney_id + " [" + tourney_name + " ] " + battle_count + " " + rank;
		}

		public function parseJson(json : Object, logger : ILogger) : void
		{
			tourney_id = json.tourney_id;
			tourney_name = json.tourney_name;
			battle_count = json.battle_count;
			rank = json.rank;

			dispatchEvent(new Event(Event.CHANGE));
		}

		public function get joined() : Boolean
		{
			return tourney_id != 0;
		}

	}
}
