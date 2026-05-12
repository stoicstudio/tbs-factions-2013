package engine.entity.def
{
	import engine.core.logging.ILogger;
	import engine.def.EngineJsonDef;

	public class PartyDefVars extends PartyDef
	{
		public static const schema : Object =
			{
				name: "PartyDefVars",
				type: "object",
				properties: {
					ids: {type: "array", items: "string"}
				}
			};

		public function PartyDefVars(vars : Object, roster : IEntityListDef, logger : ILogger)
		{
			super(roster);
			EngineJsonDef.validateThrow(vars, schema, logger);

			for each (var id : String in vars.ids)
			{
				addMember(id);
			}
		}

		public static function save(rhs : IPartyDef) : Object
		{
			var r : Object = {};

			r.ids = [];

			for each (var id : String in(rhs as PartyDef).memberIds)
			{
				r.ids.push(id);
			}
			return r;
		}
	}
}
