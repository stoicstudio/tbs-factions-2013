package engine.entity.def
{
	import engine.ability.IAbilityDef;
	import engine.ability.def.AbilityDef;
	import engine.ability.def.AbilityDefFactory;
	import engine.ability.def.AbilityDefLevels;
	import engine.core.locale.Locale;
	import engine.core.logging.ILogger;
	import engine.core.util.Enum;
	import engine.def.EngineJsonDef;
	import engine.saga.VariableBag;
	import engine.stat.def.StatType;
	import engine.stat.model.StatsVars;

	public class EntityDefVars extends EntityDef
	{
		public static const schema : Object =
			{
				name: "EntityDef",
				description: "EntityDef Definition",
				type: "object",
				properties: {
					id: {type: "string", description: "unique entity def id"},
					name: {description: "english name", type: "string", optional: true},
					name_token: {description: "localization token", type: "string", optional: true},
					entityClass: {type: "string"},
					stats: {type: "array", optional: true,
						items: {type: "object",
							properties: {stat: "string", value: "number"}}
					},
					actives: {type: "array", optional: true, items: {properties: {id: {type: "string"}, level: {type: "number"}}}},
					passives: {type: "array", optional: true, items: {properties: {id: {type: "string"}, level: {type: "number"}}}},
					autoLevel: {type: "number", optional: true},
					power: {type: "number", skip: true, optional: true},
					"class": {type: "string", skip: true, optional: true},
					start_date: {type: "number", optional: true},
					appearance_acquires: {type: "number", optional: true},
					appearance_index: {type: "number", optional: true},
					appearance: {type: EntityAppearanceDefVars.schema, optional: true}

				}
			};

		public function EntityDefVars(locale : Locale) : void
		{
			super(locale);
		}

		public function fromJson(vars : Object, logger : ILogger, abilityFactory : AbilityDefFactory, classes : EntityClassDefList, warnStats : Boolean) : EntityDefVars
		{
			EngineJsonDef.validateThrow(vars, schema, logger);

			this._id = vars.id;
			this._vars = new VariableBag(_id);

			if (classes)
			{
				this._entityClass = classes.fetch(vars.entityClass);
			}
			this._name = vars.name;
			this._nameToken = vars.name_token;

			localizeName();

			this.startDate = vars.start_date = !undefined ? vars.start_date : 0;

			this._appearance_acquires = vars.appearance_acquires;
			this._appearanceIndex = vars.appearance_index;

			var activesOk : Boolean = parseAbilityDefLevels(vars.actives, actives as AbilityDefLevels, abilityFactory, logger);
			var passivesOk : Boolean = parseAbilityDefLevels(vars.passives, passives as AbilityDefLevels, abilityFactory, logger);

			if (!activesOk || !passivesOk)
			{
				throw new ArgumentError("CharacterDef " + id + " failed loading abilities");
			}

			if (!_entityClass && classes)
			{
				throw new ArgumentError("EntityDef " + id + " no such entity class: " + vars.entityClass);
			}

			// setup the default ability levels if needed

			setupClassAbilities(abilityFactory);

			// explicitly set stats
			for each (var statvar : Object in vars.stats)
			{
				var type : StatType = Enum.parse(StatType, statvar.stat) as StatType;
				_stats.addStat(type, statvar.value);
			}

			// autolevel up
			var autolevel : Number = vars.autoLevel != undefined ? vars.autoLevel : 0;
			applyClassStats(vars.autoLevel);

			if (vars.appearance)
			{
				_appearance = new EntityAppearanceDefVars(this._entityClass as EntityClassDef).fromJson(vars.appearance, logger);
			}
			clampStats(warnStats ? logger : null);

			return this;
		}

		public static function save(rhs : EntityDef) : Object
		{
			var r : Object = {
					id: rhs.id,
					entityClass: rhs.entityClass.id,
					appearance_index: rhs.appearanceIndex
				};

			if (rhs.name)
			{
				//r.name = rhs.name;
			}

			if (rhs.actives && rhs.actives.numAbilities > 0)
			{
				var tmpAbilities : AbilityDefLevels = new AbilityDefLevels();
				for (var i : int = 0; i < rhs.actives.numAbilities; ++i)
				{
					var abilityDef : IAbilityDef = rhs.actives.getAbilityDef(i);
					if (abilityDef.level != 1 || rhs.entityClass.actives.indexOf(abilityDef.id) == -1)
					{
						tmpAbilities.setAbilityDefLevel(abilityDef, abilityDef.level);
					}
				}

				r.actives = AbilityDefLevels.save(tmpAbilities);
			}

			//r.passives = AbilityDefLevels.save(rhs.passives);
			// don't write out passives for now
			//r.passives = [];

			// write out the stats
			// TODO determine if we should strip out the class-defaulted stats from this list
			// note that the server receiving a list of defs may have different needs than a character editor
			r.stats = StatsVars.save(rhs.stats);

			if (rhs.nameToken)
			{
				r.name_token = rhs.nameToken;
			}

			if (rhs.overrideAppearance)
			{
				r.appearance = EntityAppearanceDefVars.save(rhs.overrideAppearance as EntityAppearanceDef);
			}

			return r;
		}

		private static function parseAbilityDefLevels(vars : Array, levels : AbilityDefLevels, abilityFactory : AbilityDefFactory, logger : ILogger) : Boolean
		{
			if (!vars)
			{
				// quite alright!
				return true;
			}

			if (!levels)
			{
				throw new ArgumentError("no such levels");
			}

			var errors : int;

			for each (var kvp : Object in vars)
			{
				try
				{
					var ad : AbilityDef = abilityFactory.fetch(kvp.id);
					levels.setAbilityDefLevel(ad, kvp.level);
				}
				catch (e : Error)
				{
					logger.error("Character ability: " + e);
					++errors;
				}
			}

			return errors == 0;
		}
	}
}
