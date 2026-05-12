package engine.stat.model
{
	import engine.core.logging.ILogger;
	import engine.core.util.Enum;
	import engine.def.EngineJsonDef;
	import engine.stat.def.StatType;

	public class StatsVars
	{
		public static const schema : Object =
			{
				name: "StatVars",
				properties: {
					stats: {type: "array",
						items:
						{
							type: "object",
							properties: {
								stat: "string", value: "number"
							}
						}
					}
				}
			};

		public static function parse(provider : IStatsProvider, vars : Object, logger : ILogger) : Stats
		{
			EngineJsonDef.validateThrow(vars, schema, logger);

			var stats : Stats = new Stats(provider, true);
			for each (var statvar : Object in vars.stats)
			{
				var type : StatType = Enum.parse(StatType, statvar.stat) as StatType;
				stats.addStat(type, statvar.value);
			}
			return stats;
		}

		public static function save(rhs : Stats) : Object
		{
			var r : Array = [];

			for (var i : int = 0; i < rhs.numStats; ++i)
			{
				var stat : Stat = rhs.getStatByIndex(i);

				r.push(
					{
						stat: stat.type.name,
						value: stat.value
					});
			}

			return r;
		}
	}
}
