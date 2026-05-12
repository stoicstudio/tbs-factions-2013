package engine.battle.ability.effect.def
{
	import engine.core.logging.ILogger;
	import engine.def.EngineJsonDef;

	public class EffectTagReqsVars extends EffectTagReqs
	{
		public static const schema : Object =
			{
				properties: {
					all: {type: "array", items: "string"},
					any: {type: "array", items: "string"},
					none: {type: "array", items: "string"}
				}
			};

		public function EffectTagReqsVars(vars : Object, logger : ILogger)
		{
			EngineJsonDef.validateThrow(vars, schema, logger);

			captureTagSet(vars.all, all);
			captureTagSet(vars.any, any);
			captureTagSet(vars.none, none);
		}
	}
}
