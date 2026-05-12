package engine.tile
{
	import engine.core.logging.ILogger;
	import engine.def.EngineJsonDef;
	import engine.tile.def.TileLocation;

	public class TileLocationVars
	{
		public static const schema : Object =
			{
				name: "TileLocationVars",
				type: "object",
				properties: {
					x: {type: "number"},
					y: {type: "number"},
					"class": {type: "string", optional: true}
				}
			};

		public function TileLocationVars()
		{
		}

		public static function parse(vars : Object, logger : ILogger) : TileLocation
		{
			EngineJsonDef.validateThrow(vars, schema, logger);

			return TileLocation.fetch(vars.x, vars.y);
		}

		public static function parseString(str : String, logger : ILogger) : TileLocation
		{
			var sp : int = str.indexOf(" ");

			if (sp < 0)
			{
				throw new ArgumentError("invalid tile location string [" + str + "]");
			}

			var x : Number = Number(str.substring(0, sp));
			var y : Number = Number(str.substring(sp + 1));

			return TileLocation.fetch(x, y);
		}

		public static function saveString(loc : TileLocation) : String
		{
			return loc.x.toString() + " " + loc.y.toString();
		}

		public static function save(loc : TileLocation) : Object
		{
			var r : Object = {
					x: loc.x,
					y: loc.y
				};
			return r;
		}
	}
}
