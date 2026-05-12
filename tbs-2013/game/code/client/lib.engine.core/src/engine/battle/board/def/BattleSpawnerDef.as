package engine.battle.board.def
{
	import flash.events.Event;
	import flash.events.EventDispatcher;

	import engine.battle.ability.effect.model.BattleFacing;
	import engine.stat.model.Stats;
	import engine.tile.def.TileLocation;

	public class BattleSpawnerDef extends EventDispatcher
	{
		public static const EVENT_LOCATION : String = "BattleSpawnerDef.EVENT_LOCATION";

		protected var _location : TileLocation = TileLocation.fetch(0, 0);
		public var character : String;
		public var entityClassId : String;
		public var tags : String;
		public var facing : BattleFacing = BattleFacing.SE;
		public var team : String;
		public var prop : Boolean = false;
		public var isAlly : Boolean;
		public var stats : Stats;

		public function BattleSpawnerDef()
		{
			stats = new Stats(null, false);
		}

		public function get labelString() : String
		{
			return team + " " + tags;
		}

		public function get location() : TileLocation
		{
			return _location;
		}

		public function set location(value : TileLocation) : void
		{
			if (_location == value)
			{
				return;
			}
			_location = value;

			dispatchEvent(new Event(EVENT_LOCATION));
		}

	}
}
