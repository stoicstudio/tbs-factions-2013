package engine.battle.sim
{
	import engine.math.MathUtil;
	import engine.tile.def.TileLocation;
	import engine.tile.def.TileRect;
	import engine.tile.def.TileRectRange;

	public class TileDiamond
	{
		public var hugs : Vector.<TileLocation> = new Vector.<TileLocation>;

		public var toward : TileRect;
		public var around : TileRect;
		public var minDist : int;
		public var maxDist : int;

		public function TileDiamond(around : TileRect, minDist : int, maxDist : int, toward : TileRect, maxMove : int)
		{
			if (maxDist < 0)
			{
				throw new ArgumentError("can't use maxDist < 0");
			}

			this.toward = toward;
			this.minDist = minDist;
			this.maxDist = maxDist;
			this.around = around;

			var startX : int = around.left - maxDist - (toward.width - 1);
			var endX : int = around.right + (maxDist - 1);
			var startY : int = around.front - maxDist - (toward.length - 1);
			var endY : int = around.back + (maxDist - 1);

		
			var tr : TileRect = new TileRect(toward.loc, toward.width, toward.length);

			for (var x : int = startX; x <= endX; ++x)
			{
				for (var y : int = startY; y <= endY; ++y)
				{
					var tl : TileLocation = TileLocation.fetch(x, y);
					tr.loc = tl;
					var r : int = TileRectRange.computeRange(tr, around);
					if (r <= maxDist && r >= minDist)
					{
						var md : int = MathUtil.manhattanDistance(tl.x, tl.y, toward.loc.x, toward.loc.y); 							
						if (md <= maxMove)
						{
							// toward can get there
							hugs.push(tl);
						}
					}
				}

			}

			hugs.sort(compare);
		}

		private function compare(a : TileLocation, b : TileLocation) : int
		{
			var dist_a : int = a.manhattanDistanceTo(toward.loc);
			var dist_b : int = b.manhattanDistanceTo(toward.loc);

			return dist_a - dist_b;
		}
	}
}
