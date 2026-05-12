package engine.battle.sim
{
	import engine.tile.def.TileLocation;
	import engine.tile.def.TileRect;

	public class TileRectHugger
	{
		public var hugs : Vector.<TileLocation> = new Vector.<TileLocation>;

		public var from : TileRect;
		public var rect : TileRect;
		private var bloat : TileRect;

		public function TileRectHugger(from : TileRect, rect : TileRect)
		{
			this.from = from;
			this.rect = rect;

			// top and bottom edges

			bloat = new TileRect(
				TileLocation.fetch(rect.left - from.width, rect.front - from.length),
				rect.width + from.width,
				rect.length + from.length);

			for (var x : int = bloat.left + 1; x < bloat.right; ++x)
			{
				hugs.push(TileLocation.fetch(x, bloat.front));
				hugs.push(TileLocation.fetch(x, bloat.back));
			}

			// left and right edges (not including top and bottom)

			for (var y : int = bloat.front + 1; y < bloat.back; ++y)
			{
				hugs.push(TileLocation.fetch(bloat.left, y));
				hugs.push(TileLocation.fetch(bloat.right, y));
			}

			hugs.sort(compare);
		}

		private function compare(a : TileLocation, b : TileLocation) : int
		{
			var dist_a : int = a.manhattanDistanceTo(from.loc);
			var dist_b : int = b.manhattanDistanceTo(from.loc);

			// bias up the ones at the corners since they aren't strictly adjacent
			var in_a : Boolean = (a.y > bloat.front && a.y < bloat.back) || (a.x > bloat.left && a.x < bloat.right);
			var in_b : Boolean = (b.y > bloat.front && b.y < bloat.back) || (b.x > bloat.left && b.x < bloat.right);

			var bias : int = bloat.width * bloat.length;
			var bias_a : int = !in_a ? bias : 0;
			var bias_b : int = !in_b ? bias : 0;

			return (dist_a + bias_a) - (dist_b + bias_b);
		}
	}
}
