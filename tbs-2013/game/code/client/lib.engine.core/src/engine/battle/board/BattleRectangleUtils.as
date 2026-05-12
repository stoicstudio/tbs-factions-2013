package engine.battle.board
{

	import flash.geom.Point;
	import flash.geom.Rectangle;

	public class BattleRectangleUtils
	{
		public function BattleRectangleUtils()
		{
		}

		public static function test2RectIntersection(
			x0 : Number, y0 : Number, w0 : Number, l0 : Number,
			x1 : Number, y1 : Number, w1 : Number, l1 : Number
			) : Boolean
		{
			if (x0 >= (x1 + w1) ||
				(x0 + w0) <= x1 ||
				y0 >= (y1 + l1) ||
				(y0 + l0) <= y1)
			{
				return false;
			}

			return true;
		}

		public static function testPointInRect(
			x0 : Number, y0 : Number,
			x1 : Number, y1 : Number, w1 : Number, l1 : Number
			) : Boolean
		{
			if (x0 >= (x1 + w1) ||
				(x0) <= x1 ||
				y0 >= (y1 + l1) ||
				(y0) <= y1)
			{
				return false;
			}

			return true;
		}

		public static function shrinkRectangle(r : Rectangle, factor : Number, createNew : Boolean = false) : Rectangle
		{
			var rw : Number = r.width * factor;
			var rh : Number = r.height * factor;
			var rx : Number = r.x + (r.width - rw) / 2;
			var ry : Number = r.y + (r.height - rh) / 2;

			if (createNew)
			{
				return new Rectangle(rx, ry, rw, rh);
			}
			else
			{
				r.setTo(rx, ry, rw, rh);
				return r;
			}
		}

	}
}
