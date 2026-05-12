package engine.tile
{

	import engine.tile.def.TileDef;
	import engine.tile.def.TileLocation;
	import engine.tile.def.TileRect;

	import flash.utils.Dictionary;

	public class Tile
	{
		public var def : TileDef;
		public var tiles : Tiles;
		private var _residents : Dictionary = new Dictionary;
		private var _numResidents : int;

		public function Tile(def : TileDef, tiles : Tiles)
		{
			this.def = def;
			this.tiles = tiles;
		}

		public function equals(rhs : Tile) : Boolean
		{
			return location.equals(rhs.location);
		}

		public function get id() : String
		{
			return "tile_" + def.id;
		}

		public function get name() : String
		{
			return "Tile";
		}

		public function toString() : String
		{
			return def.toString();
		}

		public function addResident(e : ITileResident) : void
		{
			if (_residents[e] == null)
			{
				if (e.collidable)
				{
					++_numResidents;
					_residents[e] = e;
				}
			}
		}

		public function removeResident(e : ITileResident) : void
		{
			if (_residents[e] != null)
			{
				--_numResidents;
				delete _residents[e];
			}
		}

		public function hasResident(e : ITileResident) : Boolean
		{
			return _residents[e] != null;
		}

		public function findResident(ignore : ITileResident) : ITileResident
		{
			for each (var a : ITileResident in _residents)
			{
				if (a != ignore)
				{
					return a;
				}
			}

			return null;
		}

		public function get numResidents() : int
		{
			return _numResidents;
		}

		public function get location() : TileLocation
		{
			return def.location;
		}

		public function get rect() : TileRect
		{
			return def.rect;
		}

		public function get y() : int
		{
			return location.y;
		}

		public function get x() : int
		{
			return location.x;
		}

		public function get centerX() : Number
		{
			return location.x + 0.5;
		}

		public function get centerY() : Number
		{
			return location.y + 0.5;
		}

		public function get residents() : Dictionary
		{
			return _residents;
		}

	}
}
