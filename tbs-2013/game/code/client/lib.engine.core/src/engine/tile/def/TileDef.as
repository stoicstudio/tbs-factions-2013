package engine.tile.def
{

	public class TileDef
	{
		private var _location : TileLocation;
		public var walkable : Boolean = true;
		private var _rect : TileRect;

		public function TileDef(x : int, y : int, walkable : Boolean)
		{
			location = TileLocation.fetch(x, y);
			_rect = new TileRect(location, 1, 1);
			this.walkable = walkable;
		}

		public function get id() : String
		{
			return x + "_" + y;
		}

		public function toString() : String
		{
			return _location.toString();
		}

		public function get rect() : TileRect
		{
			return _rect;
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

		public function get location() : TileLocation
		{
			return _location;
		}

		public function set location(value : TileLocation) : void
		{
			_location = value;
		}
	}
}
