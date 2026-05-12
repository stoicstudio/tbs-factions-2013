package engine.tile.def
{
	import flash.geom.Point;
	import flash.utils.Dictionary;

	public class TileLocationArea
	{

		public var rect : TileRect;
		public var locations : Dictionary = new Dictionary;
		public var sorted : Vector.<TileLocation> = new Vector.<TileLocation>;

		public function TileLocationArea()
		{
		}

		public function addTile(loc : TileLocation) : Boolean
		{
			if (locations[loc] != loc)
			{
				locations[loc] = loc;
				return true;
			}
			return false;
		}

		public function removeTile(loc : TileLocation) : Boolean
		{
			if (loc in locations)
			{
				delete locations[loc];
				return true;
			}
			return false;
		}

		public function toggleTile(loc : TileLocation) : Boolean
		{
			if (hasTile(loc))
			{
				removeTile(loc);
				return false;
			}
			else
			{
				addTile(loc);
				return true;
			}
		}

		public function hasTile(loc : TileLocation) : Boolean
		{
			return loc in locations;
		}

		public function fit() : void
		{
			var min : Point = new Point(Number.MAX_VALUE, Number.MAX_VALUE);
			var max : Point = new Point(-Number.MAX_VALUE, -Number.MAX_VALUE);

			for each (var loc : TileLocation in locations)
			{
				min.x = Math.min(loc.x, min.x);
				min.y = Math.min(loc.y, min.y);
				max.x = Math.max(loc.x, max.x);
				max.y = Math.max(loc.y, max.y);
			}

			rect = new TileRect(TileLocation.fetch(min.x, min.y), 1 + max.x - min.x, 1 + max.y - min.y);
		}

		public function sortByDistance(toward : TileLocation) : void
		{
			sorted.splice(0, sorted.length);

			for each (var loc : TileLocation in locations)
			{
				sorted.push(loc);
			}

			sorted.sort(function(a : TileLocation, b : TileLocation) : Number
			{
				var da : int = TileLocation.manhattanDistance(a.x, a.y, toward.x, toward.y);
				var db : int = TileLocation.manhattanDistance(b.x, b.y, toward.x, toward.y);

				return da - db;
			});
		}

		public function sortByRow(toward : TileLocation, front : Boolean) : void
		{
			sorted.splice(0, sorted.length);

			for each (var loc : TileLocation in locations)
			{
				sorted.push(loc);
			}

			var fa : int = front ? 1 : -1;
			var axis : Point;
			var len : int;
			if (Math.abs(rect.center.x - toward.x) > Math.abs(rect.center.y - toward.y))
			{
				axis = new Point(fa, 0);
				len = rect.length;
			}
			else
			{
				axis = new Point(0, fa);
				len = rect.width;
			}

			sorted.sort(function(a : TileLocation, b : TileLocation) : Number
			{

				var da : int = Math.abs(a.x - toward.x) * (1 + axis.x * len) + Math.abs(a.y - toward.y) * (1 + axis.y * len);
				var db : int = Math.abs(b.x - toward.x) * (1 + axis.x * len) + Math.abs(b.y - toward.y) * (1 + axis.y * len);

				return da - db;
			});
		}
	}
}
