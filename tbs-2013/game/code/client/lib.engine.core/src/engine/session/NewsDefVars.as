package engine.session
{
	import engine.core.logging.ILogger;
	import engine.def.EngineJsonDef;

	public class NewsDefVars extends NewsDef
	{
		public static const schema : Object =
			{
				name: "NewsEntryDefVars",
				type: "object",
				properties: {
					entries: {type: "array", items: NewsEntryDefVars.schema}
				}
			};

		public function NewsDefVars()
		{
			super();
		}

		public function fromJson(json : Object, logger : ILogger) : NewsDefVars
		{
			EngineJsonDef.validateThrow(json, schema, logger);

			for each (var ev : Object in json.entries)
			{
				var e : NewsEntryDefVars = new NewsEntryDefVars().fromJson(ev, logger);
				entries.push(e);
			}
			
			sortEntries();

			return this;
		}
	}
}
