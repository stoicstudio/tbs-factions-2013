package engine.def
{
	import flash.geom.Point;

	import engine.core.logging.ILogger;

	public class PointVars
	{
		public static const schema : Object =
			{
				name: "PointVars",
				type: "object",
				properties: {
					x: {type: "number"},
					y: {type: "number"}
				}
			};

		public function PointVars()
		{
		}

		public static function parse(vars : Object, logger : ILogger) : Point
		{
			EngineJsonDef.validateThrow(vars, schema, logger);

			var p : Point = new Point(vars.x, vars.y);
			return p;
		}

		public static function parseString(str : String) : Point
		{
			var sp : int = str.indexOf(" ");

			if (sp < 0)
			{
				throw new ArgumentError("invalid tile location string [" + str + "]");
			}

			var x : Number = Number(str.substring(0, sp));
			var y : Number = Number(str.substring(sp + 1));

			return new Point(x, y);
		}

		public static function saveString(p : Point) : String
		{
			return p.x.toString() + " " + p.y.toString();
		}

		public static function save(rhs : Point) : Object
		{
			var r : Object = {
					x: rhs.x,
					y: rhs.y
				};

			return r;
		}
	}
}
