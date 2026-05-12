package engine.tile.def
{
	import flash.geom.Point;

	public class TileRect
	{
		public var center : Point;
		public var loc : TileLocation;
		public var width : int;
		public var length : int;

		public function TileRect(loc : TileLocation, width : int, length : int)
		{
			if (loc == null)
			{
				loc = TileLocation.fetch(0, 0);
			}
			this.loc = loc;
			this.width = width;
			this.length = length;
			center = new Point(loc.x + width / 2, loc.y + length / 2);
		}

		public function grow(n : int) : TileRect
		{
			return new TileRect(TileLocation.fetch(loc.x - n, loc.y - n), width + n * 2, length + n * 2);
		}

		public function contains(x : int, y : int) : Boolean
		{
			return (x >= left && x < right && y >= front && y < back);
		}

		public function get right() : int
		{
			return loc.x + width;
		}

		public function get back() : int
		{
			return loc.y + length;
		}

		public function get left() : int
		{
			return loc.x;
		}

		public function get front() : int
		{
			return loc.y;
		}

		public function toString() : String
		{
			return loc.toString() + " & " + width + "x" + length;
		}
	}
}
