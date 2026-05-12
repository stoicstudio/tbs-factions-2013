package engine.tile.def
{

	public class TileRectRange
	{
		public function TileRectRange()
		{
		}

		static public function computeRange(a : TileRect, b : TileRect) : int
		{
			var dx : int = 0;

			if (b.left >= a.right)
			{
				dx = b.left - a.right + 1;
			}
			else if (a.left >= b.right)
			{
				dx = a.left - b.right + 1;
			}

			var dy : int = 0;

			if (b.front >= a.back)
			{
				dy = b.front - a.back + 1;
			}
			else if (a.front >= b.back)
			{
				dy = a.front - b.back + 1;
			}

			return dx + dy;
		}

		static public function computeTileRange(a : TileLocation, b : TileRect) : int
		{
			var dx : int = 0;

			if (b.left >= a.x + 1)
			{
				dx = b.left - (a.x + 1) + 1;
			}
			else if (a.x >= b.right)
			{
				dx = a.x - b.right + 1;
			}

			var dy : int = 0;

			if (b.front >= a.y + 1)
			{
				dy = b.front - (a.y + 1) + 1;
			}
			else if (a.y >= b.back)
			{
				dy = a.y - b.back + 1;
			}

			return dx + dy;
		}

	}
}
