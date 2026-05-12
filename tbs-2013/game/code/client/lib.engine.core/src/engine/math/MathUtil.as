package engine.math
{

	public class MathUtil
	{
		public function MathUtil()
		{
		}

		public static function clampValue(value : Number, min : Number, max : Number) : Number
		{
			if (value < min)
			{
				return min;
			}
			else if (value > max)
			{
				return max
			}
			else
			{
				return value;
			}
		}

		public static function hash(str : String) : uint
		{
			var result : uint = 5381;

			for (var i : int = 0; i < str.length; ++i)
			{
				result = ((result << 5) + result) + str.charCodeAt(i); /* hash * 33 + c */
			}

			return result;
		}

		public static function lerp(a : Number, b : Number, t : Number) : Number
		{
			return a + (b - a) * t;
		}

		public static function mungeRadians(a : Number) : Number
		{
			var c : int;

			if (a > Math.PI)
			{
				c = int((a + Math.PI) / (Math.PI * 2));
				return a - c * (Math.PI * 2);
			}
			else if (a < -Math.PI)
			{
				c = int(-(a - Math.PI) / (Math.PI * 2));
				return a + c * (Math.PI * 2);
			}
			return a;
		}

		public static function radians2Pi(a : Number) : Number
		{
			var c : int;

			if (a > (Math.PI * 2))
			{
				return a % (Math.PI * 2);
			}
			else if (a < 0)
			{
				c = int(-(a - Math.PI * 2) / (Math.PI * 2));
				return a + c * (Math.PI * 2);
			}
			return a;
		}

		public static function degrees2Radians(degrees : Number) : Number
		{
			return degrees * Math.PI / 180;
		}

		public static function radians2Degrees(radians : Number) : Number
		{
			return radians * 180 / Math.PI;
		}

		public static function randomInt(from : int, to : int) : int
		{
			if (to < from)
			{
				throw new ArgumentError("MathUtil.randomInt invalid range");
			}

			var range : int = to - from;
			return Math.round(Math.random() * range) + from;
		}

		public static function manhattanDistance(ax : Number, ay : Number, bx : Number, by : Number) : Number
		{
			var dx : Number = Math.abs(ax - bx);
			var dy : Number = Math.abs(ay - by);
			return dx + dy;
		}

		public static function distanceSquared(ax : Number, ay : Number, bx : Number, by : Number) : Number
		{
			var dx : Number = ax - bx;
			var dy : Number = ay - by;
			return dx * dx + dy * dy;
		}

		public static function shuffle(a : Array) : void
		{
			for (var i : int = 0; i < a.length; ++i)
			{
				var j : int = Math.round(Math.random() * (a.length - 1));
				if (i != j)
				{
					var t : * = a[i];
					a[i] = a[j];
					a[j] = t;
				}
			}
		}
	}
}
