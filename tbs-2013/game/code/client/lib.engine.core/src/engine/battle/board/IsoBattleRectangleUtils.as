package engine.battle.board
{
	import flash.geom.Point;
	import flash.geom.Rectangle;

	import as3isolib.geom.IsoMath;
	import as3isolib.geom.Pt;

	public class IsoBattleRectangleUtils
	{

		public static function getIsoRectScreenRect(units : Number, x : Number, y : Number, width : Number, length : Number) : Rectangle
		{
			var topScreenCorner : Pt = IsoMath.isoToScreen(new Pt(x * units, y * units));
			var leftScreenCorner : Pt = IsoMath.isoToScreen(new Pt((x + width) * units, y * units));
			var w : Number = (topScreenCorner.x - leftScreenCorner.x) * 2;
			var h : Number = (leftScreenCorner.y - topScreenCorner.y) * 2;

			if (width != length)
			{
				throw new ArgumentError("we currently only support entities with square footprints");
			}

			var r : Rectangle = new Rectangle(leftScreenCorner.x, topScreenCorner.y, w, h);
			return r;
		}

		public static function getIsoPointScreenPoint(units : Number, x : Number, y : Number) : Point
		{
			var pt : Pt = IsoMath.isoToScreen(new Pt(x * units, y * units));
			return new Point(pt.x, pt.y);
		}
	}
}
