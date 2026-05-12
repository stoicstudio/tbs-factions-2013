package engine.core.util
{
	import engine.scene.def.SceneDef;

	public class StringUtil
	{
		public static function padRight(str : String, p : String, w : int) : String
		{
			if (str.length >= w)
			{
				return str;
			}

			var r : String = str;

			var a : int = (w - r.length) / p.length;
			for (var i : int = 0; i < a; ++i)
			{
				r += p;
			}

			return r;
		}

		public static function stripSurroundingSpace(str : String) : String
		{
			var start : int = 0;
			var end : int = str.length;

			var c : String;
			for (start; start < str.length; ++start)
			{

				c = str.charAt(start);
				if (c != " " && c != "\n")
				{
					break;
				}
			}

			for (end; end > start; --end)
			{
				c = str.charAt(end - 1);
				if (c != " " && c != "\n")
				{
					break;
				}
			}

			if (start == 0 && end == str.length)
			{
				return str;
			}

			return str.substring(start, end);
		}

		public static function getShortPath(str : String) : String
		{
			if (!str)
			{
				return str;
			}

			var slash : int = str.lastIndexOf("/");
			if (slash >= 0)
			{
				var dot : int = str.indexOf(".", slash);

				if (dot > slash)
				{
					return str.substring(slash + 1, dot);
				}
				else
				{
					return str.substring(slash + 1);
				}
			}

			return str;
		}

		public static function truncate(str : String, max : int) : String
		{
			if (max < str.length)
			{
				var s : String = str.substring(0, max);
				s = stripSurroundingSpace(s);
				s += "⋯";
				return s;
			}

			return str;
		}

		public static function stripSuffix(str : String, suff : String) : String
		{
			var i : int = str.lastIndexOf(suff);
			if (i < 0)
			{
				return str;
			}

			return str.substring(0, i);
		}

		public static function numberWithSign(n : Number) : String
		{
			if (n < 0)
			{
				return n.toString();
			}

			return "+" + n;
		}

		public static function endsWith(str : String, suffix : String) : Boolean
		{
			return str.lastIndexOf(suffix) == (str.length - suffix.length);
		}

		public static function getFilename(s : String) : String
		{
			var li : int = s.lastIndexOf("/");
			if (li >= 0)
			{
				return s.substring(li + 1);
			}
			return s;
		}
	}
}
