package engine.entity.def
{
	import flash.events.EventDispatcher;

	import engine.ability.IAbilityDefLevels;
	import engine.ability.def.AbilityDef;
	import engine.ability.def.AbilityDefFactory;
	import engine.battle.ability.def.BattleAbilityDefLevels;
	import engine.core.locale.Locale;
	import engine.core.locale.LocaleCategory;
	import engine.core.logging.ILogger;
	import engine.math.MathUtil;
	import engine.saga.Variable;
	import engine.saga.VariableBag;
	import engine.stat.def.StatRange;
	import engine.stat.def.StatRanges;
	import engine.stat.def.StatType;
	import engine.stat.model.Stat;
	import engine.stat.model.Stats;

	public class EntityDef extends EventDispatcher implements IEntityDef
	{
		protected var _id : String;
		protected var _name : String;
		protected var _entityClass : IEntityClassDef;
		protected var _stats : Stats;

		protected var _actives : IAbilityDefLevels = new BattleAbilityDefLevels;
		protected var _attacks : IAbilityDefLevels = new BattleAbilityDefLevels;
		protected var _passives : IAbilityDefLevels = new BattleAbilityDefLevels;
		protected var _appearanceIndex : int = 0;
		protected var _startDate : Number;
		protected var _nameToken : String;
		protected var _appearance_acquires : int = 0;
		protected var _appearance : EntityAppearanceDef;
		protected var _vars : VariableBag;

		public var locale : Locale;

		public function EntityDef(locale : Locale)
		{
			this.locale = locale;
			this._stats = new Stats(this, true);
		}

		public function get startDate() : Number
		{
			return _startDate;
		}

		public function set startDate(value : Number) : void
		{
			_startDate = value;
		}

		public function duplicate(id : String) : IEntityDef
		{
			const d : EntityDef = new EntityDef(locale);
			d._id = id;
			d._name = _name;
			d._entityClass = _entityClass;
			d._stats = _stats.clone(this);
			d._actives = _actives.clone();
			d._attacks = _attacks.clone();
			d._passives = _passives.clone();
			d._startDate = _startDate;
			return d;
		}

		public function get entityClass() : IEntityClassDef
		{
			return _entityClass;
		}

		public function set entityClass(value : IEntityClassDef) : void
		{
			if (!value || value == _entityClass)
			{
				return;
			}

			_entityClass = value;
		}

		public function get id() : String
		{
			return _id;
		}

		public function set id(value : String) : void
		{
			_id = value;
			_nameToken = makeNameToken();
			localizeName();
		}

		public function get name() : String
		{
			return _name ? _name : id;
		}

		public function get nameToken() : String
		{
			return _nameToken;
		}

		public function makeNameToken() : String
		{
			return "ent_" + id;
		}

		public function set localizedName(value : String) : void
		{
			_name = null;
			if (value)
			{
				_nameToken = makeNameToken();
				locale.getLocalizer(LocaleCategory.ENTITY).setValue(_nameToken, value);
			}
			else
			{
				_nameToken = null;
			}

			localizeName();
		}

		public function set name(value : String) : void
		{
			_name = value;
		}

		public function get stats() : Stats
		{
			return _stats;
		}

		public function get power() : int
		{
			return stats.GetTotalPower(_entityClass.statRanges);
		}

		public function get appearanceIndex() : int
		{
			return _appearanceIndex;
		}

		public function set appearanceIndex(val : int) : void
		{
			if (_appearanceIndex != val)
			{
				_appearanceIndex = val;
				_appearance_acquires != (1 << val);
				dispatchEvent(new EntityDefEvent(EntityDefEvent.APPEARANCE, this));
			}
		}

		public function get appearance() : IEntityAppearanceDef
		{
			if (_appearance)
			{
				return _appearance;
			}
			return classAppearance;
		}

		public function get classAppearance() : IEntityAppearanceDef
		{
			return _entityClass ? _entityClass.getEntityClassAppearanceDef(appearanceIndex) : null;
		}

		public function get overrideAppearance() : IEntityAppearanceDef
		{
			return _appearance;
		}

		public function set overrideAppearance(value : IEntityAppearanceDef) : void
		{
			if (_appearance == value)
			{
				return;
			}
			_appearance = value as EntityAppearanceDef;
		}

		public function clampStats(logger : ILogger) : void
		{
			// TODO: in future if we rebalance, we don't want to penalize characters without compensating them so they can respec
			// we should auto-clamp them on the server side

			if (!_entityClass)
			{
				return;
			}

			for (var i : int = 0; i < _stats.numStats; ++i)
			{
				var stat : Stat = _stats.getStatByIndex(i);
				var sr : StatRange = _entityClass.statRanges.getStatRange(stat.type);

				if (sr)
				{
					if (stat.base < sr.min || stat.base > sr.max)
					{
						if (logger)
						{
							// stats should already have been clamped by the server
							logger.error("EntityDef.clampStats " + id + " " + stat.type + " " + stat.base + " was out of range " + sr.min + "," + sr.max);
						}

						stat.base = Math.max(sr.min, Math.min(sr.max, stat.base));
					}
				}
			}
		}

		public function applyClassStats(autoLevel : Number) : void
		{
			if (!entityClass)
			{
				return;
			}

			var sr : StatRange;

			// if Stats number more than 32, then this will break
			var allowedStats : uint = 0x000000;

			for (var i : int = 0; i < _entityClass.statRanges.numStatRanges; ++i)
			{
				sr = _entityClass.statRanges.getStatRangeByIndex(i);
				// only set the class stat if the stats does not already have the stat
				if (_stats.getStat(sr.type, false) == null)
				{
					_stats.addStat(sr.type, sr.min);
					allowedStats |= (1 << sr.type.value);
				}
			}

			var nnn : int = StatRanges.GetMaxUpgrades(this.stats.rank) - _stats.GetTotalUpgrades(_entityClass.statRanges);
			var additionalStats : int = MathUtil.lerp(0, nnn, autoLevel);

			while (additionalStats > 0)
			{
				var found : Boolean = false;

				for each (var statType : StatType in Stats.userChangedStatTypes)
				{
					if ((allowedStats & (1 << statType.value)) == 0)
					{
						// this stat was not set from the class defaults, meaning it was set explicitly already.  we can't autolevel it
						continue;
					}
					sr = _entityClass.statRanges.getStatRange(statType);
					var stat : Stat = _stats.getStat(statType);

					if (stat.value < sr.max)
					{
						found = true;
						++stat.base;
						--additionalStats;
					}

					if (additionalStats <= 0)
					{
						break;
					}
				}

				if (!found)
				{
					// no stats to allocate, just give up
					break;
				}
			}
			sr = null;
			sr = _entityClass.statRanges.getStatRange(StatType.ACTIVE_0);
			if (sr != null)
			{
				_stats.setBase(StatType.ACTIVE_0, MathUtil.clampValue(_stats.rank - 1, sr.min, sr.max));
			}
			else
			{
				_entityClass.statRanges.getStatRange(StatType.ACTIVE_0);
					//fpooo
			}

			_stats.addStat(StatType.INJURY, 0);
			_stats.addStat(StatType.INJURY_DAYS, 3);

		}

		public function get attacks() : IAbilityDefLevels
		{
			return _attacks;
		}

		public function get actives() : IAbilityDefLevels
		{
			return _actives;
		}

		public function get passives() : IAbilityDefLevels
		{
			return _passives;
		}

		public function get upgrades() : int
		{
			return stats.GetTotalUpgrades(_entityClass.statRanges);
		}

		public function resetAbilities() : void
		{
			_attacks = new BattleAbilityDefLevels;
			_passives = new BattleAbilityDefLevels;
			_actives = new BattleAbilityDefLevels;
		}

		public function setupClassAbilities(abilityFactory : AbilityDefFactory) : void
		{
			if (!entityClass)
			{
				return;
			}

			for each (var aid : String in _entityClass.actives)
			{
				if (!actives.hasAbility(aid))
				{
					actives.setAbilityDefLevel(abilityFactory.fetch(aid), 1);
				}
			}

			// attacks can always be used up to max level (limited by exertion and willpower of course)
			for each (var kid : String in _entityClass.attacks)
			{
				var k : AbilityDef = abilityFactory.fetch(kid);
				attacks.setAbilityDefLevel(k, k.maxLevel);
			}

			if (_entityClass.passive)
			{
				if (!actives.hasAbility(_entityClass.passive))
				{
					passives.setAbilityDefLevel(abilityFactory.fetch(_entityClass.passive), 1);
				}
			}

		}

		public function isAppearanceAcquired(index : int) : Boolean
		{
			if (index == 0)
			{
				return true;
			}

			return (_appearance_acquires & (1 << index)) != 0;
		}

		public function acquireAppearance(index : int) : void
		{
			_appearance_acquires |= (1 << index);
		}

		public function readyToPromote(killsToPromote : int) : Boolean
		{
			const kills : int = stats.getValue(StatType.KILLS);
			if (stats.rank < _entityClass.statRanges.getStatRange(StatType.RANK).max || _entityClass.playerOnlyChildEntityClasses.length)
			{
				if (kills >= killsToPromote)
				{
					return true;
				}
			}

			return false;
		}

		public function get killRenown() : int
		{
			return 1; //Math.max(1, stats.getValue(StatType.RANK) - 1);
		}

		public function get vars() : VariableBag
		{
			return _vars;
		}

		public function synchronizeToVars() : void
		{
			for each (var s : Stat in stats)
			{
				var v : Variable = _vars.fetch(s.type.name, null);
				if (v)
				{
					v.asNumber = s.value;
				}
			}
		}

		protected function localizeName() : void
		{
			if (this._nameToken)
			{
				this._name = locale.translate(LocaleCategory.ENTITY, _nameToken);
			}

			if (!this._name && this._entityClass)
			{
				this._name = this._entityClass.name;
			}
		}
	}
}
