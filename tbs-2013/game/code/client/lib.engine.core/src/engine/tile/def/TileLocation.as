package engine.tile.def
{
	import flash.errors.IllegalOperationError;
	import flash.utils.Dictionary;

	public class TileLocation
	{
		private var _x : int;
		private var _y : int;

		private static var cache : Dictionary = new Dictionary;
		private static const bias : int = 10000;
		private static const secret : Object = {};

		public static function fetch(x : int, y : int) : TileLocation
		{
			var key : int = (x + bias) + (y + bias) * bias * 2;
			var tl : TileLocation = cache[key];
			if (!tl)
			{
				tl = new TileLocation(secret, x, y);
				cache[key] = tl;
			}

			return tl;
		}

		public function TileLocation(whisper : *, x : int, y : int)
		{
			if (whisper != secret)
			{
				throw new IllegalOperationError("Use TileLocation.fetch, homie");
			}
			this._x = x;
			this._y = y;
		}

		public function get y() : int
		{
			return _y;
		}

		public function get x() : int
		{
			return _x;
		}

		public static function manhattanDistance(x0 : int, y0 : int, x1 : int, y1 : int) : int
		{
			return Math.abs(x0 - x1) + Math.abs(y0 - y1);
		}

		public function equals(rhs : TileLocation) : Boolean
		{
			return this._x == rhs._x && this._y == rhs._y;

		}

		public function manhattanDistanceTo(rhs : TileLocation) : int
		{
			return Math.abs(x - rhs.x) + Math.abs(y - rhs.y);
		}

		public function toString() : String
		{
			return "[" + x + ", " + y + "]";
		}
	}
}
