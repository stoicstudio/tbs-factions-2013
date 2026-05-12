package tbs.srv.util
{
	import engine.core.logging.ILogger;
	import engine.tourney.TourneyDef;

	import flash.events.Event;
	import flash.events.EventDispatcher;

	public class TourneyWinnerData extends EventDispatcher
	{
		public var tourney_id : int;
		public var ranked_ids : Vector.<int> = new Vector.<int>;
		public var ranked_display_names : Vector.<String> = new Vector.<String>;
		public var def : TourneyDef;

		public function TourneyWinnerData()
		{
		}

		override public function toString() : String
		{
			return "TourneyProgressData " + tourney_id + " [" + def + " ] " + ranked_ids + " " + ranked_display_names;
		}

		public function parseJson(json : Object, logger : ILogger) : void
		{
			tourney_id = json.tourney_id;

			ranked_ids.splice(0, ranked_ids.length);
			for each (var id : int in json.ranked_ids)
			{
				ranked_ids.push(id);
			}

			ranked_display_names.splice(0, ranked_display_names.length);
			for each (var name : String in json.ranked_display_names)
			{
				ranked_display_names.push(name);
			}

			if (json.def == undefined)
			{
				throw new ArgumentError("No def");
			}

			def = new TourneyDef;
			def.fromJson(json.def);

			dispatchEvent(new Event(Event.CHANGE));
		}

		public function get winnerName() : String
		{
			return ranked_display_names.length > 0 ? ranked_display_names[0] : "";
		}

		public function get winnerId() : int
		{
			return ranked_ids.length > 0 ? ranked_ids[0] : 0;
		}

		public function isAWinner(account_id : int) : Boolean
		{
			for each (var id : int in ranked_ids)
			{
				if (id == account_id)
				{
					return true;
				}
			}

			return false;
		}
	}
}
