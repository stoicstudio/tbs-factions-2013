package game.cfg
{
	import flash.utils.Dictionary;
	
	import engine.core.logging.ILogger;
	import engine.def.EngineJsonDef;

	public class GameAmbienceDef
	{
		public static const INVALID_LOCATION : Number = -99999;
		public static const schema : Object =
			{
				name: "GameAmbienceDef",
				properties:
				{
					locations: {type: "array", items: {
							name: "GameAmbienceDef_entry",
							properties:
							{
								id: {type: "string"},
								location: {type: "number", optional: true},
								reverb: {type: "string", optional: true}
							}
						}
					}
				}
			};

		private var locations : Dictionary = new Dictionary;
		private var reverbs : Dictionary = new Dictionary;

		public function GameAmbienceDef(vars : Object, logger : ILogger)
		{
			EngineJsonDef.validateThrow(vars, schema, logger);

			for each (var lo : Object in vars.locations)
			{
				const id : String = lo.id;
				if (lo.location != undefined)
				{
					locations[id] = lo.location;
				}

				if (lo.reveb != undefined && lo.reverb != "")
				{
					reverbs[id] = lo.reverb;
				}
			}
		}

		public function getLocation(id : String) : Number
		{
			if (id in locations)
			{
				return locations[id];
			}
			else
			{
				return INVALID_LOCATION;
			}
		}

		public function getReverb(id : String) : String
		{
			return reverbs[id];
		}
	}
}
