package engine.entity.def
{
	import engine.ability.def.AbilityDefFactory;
	import engine.core.locale.Locale;
	import engine.core.logging.ILogger;
	import engine.def.EngineJsonDef;

	public class EntityListDefVars extends EntityListDef
	{
		public static const schema : Object =
			{
				name: "EntityListDefVars",
				type: "object",
				properties: {
					defs: {type: "array", items: EntityDefVars.schema}
				}
			};

		public function EntityListDefVars(locale : Locale) : void
		{
			super(locale, null);
		}

		public function fromJson(
			vars : Object, logger : ILogger, abilityDefFactory : AbilityDefFactory, classes : EntityClassDefList, warnStats : Boolean = true) : EntityListDefVars
		{
			EngineJsonDef.validateThrow(vars, schema, logger);

			this._classes = classes;
			var errors : int = 0;
			for each (var cdv : Object in vars.defs)
			{
				try
				{
					var ed : EntityDef = new EntityDefVars(locale).fromJson(cdv, logger, abilityDefFactory, classes, warnStats);
					addEntityDef(ed);
				}
				catch (e : Error)
				{
					++errors;
					logger.error("EntityListDefVars Failed to load entity def: " + e.getStackTrace());
				}
			}

			if (errors)
			{
				throw new Error("Failed to load entity list.  Errors: " + errors);
			}

			return this;
		}

		public static function save(rhs : EntityListDef) : Object
		{
			var r : Object =
				{
					defs: []
				};

			for (var i : int = 0; i < rhs.numEntityDefs; ++i)
			{
				var cd : EntityDef = rhs.getEntityDef(i) as EntityDef;
				r.defs.push(EntityDefVars.save(cd));
			}

			return r;
		}
	}
}
