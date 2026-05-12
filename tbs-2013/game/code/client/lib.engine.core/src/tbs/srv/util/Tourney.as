package tbs.srv.util
{
	import engine.core.logging.ILogger;
	import engine.tourney.TourneyDef;

	import flash.events.Event;
	import flash.events.EventDispatcher;

	public class Tourney extends EventDispatcher
	{
		public var tourney_id : int;
		public var start_time : Number = 0;
		public var end_time : Number = 0;
		public var started : Boolean;
		public var ended : Boolean;
		public var parent_id : int;

		public var def : TourneyDef;

		public var clock_skew : Number = 0;

		public function Tourney()
		{
		}

		override public function toString() : String
		{
			return "Tourney " + tourney_id + " [" + def + " ] (" + start_time + " " + end_time + ") {" + started + " " + ended + "} " + parent_id;
		}

		public function parseJson(json : Object, logger : ILogger) : void
		{
			tourney_id = json.tourney_id;
			start_time = json.start_time;
			end_time = json.end_time;
			started = json.started;
			ended = json.ended;
			parent_id = json.parent_id;

			if (json.def == undefined)
			{
				throw new ArgumentError("No def");
			}

			def = new TourneyDef;
			def.fromJson(json.def);

			dispatchEvent(new Event(Event.CHANGE));
		}

		public function get end_minutes_remaining() : int
		{
			const cur : Number = new Date().time;
			return Math.ceil((end_time - clock_skew - cur) / (1000 * 60));
		}

		public function get start_minutes_remaining() : int
		{
			const cur : Number = new Date().time;
			return Math.ceil((start_time - clock_skew - cur) / (1000 * 60));
		}

		public function get day() : int
		{
			const cur : Number = new Date().time;
			const elapsed : Number = cur + clock_skew - start_time;
			return Math.ceil(elapsed / (1000 * 60 * 60 * 24));
		}

		public function get active() : Boolean
		{
			return started && !ended;
		}
	}
}
