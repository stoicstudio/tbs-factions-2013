package engine.stat.model
{
	import flash.utils.Dictionary;

	import engine.stat.def.StatRange;
	import engine.stat.def.StatRanges;
	import engine.stat.def.StatType;

	public class Stats
	{
		private var _statsByType : Dictionary = new Dictionary;
		private var _stats : Vector.<Stat> = new Vector.<Stat>;
		private var _provider : IStatsProvider;
		private var locked : Boolean = true;
		public static const userChangedStatTypes : Array =
			[
			StatType.STRENGTH,
			StatType.ARMOR,
			StatType.WILLPOWER,
			StatType.EXERTION,
			StatType.ARMOR_BREAK
			];

		public function Stats(provider : IStatsProvider, locked : Boolean)
		{
			this._provider = provider;			
			this.locked = locked;
		}

		public function get rank() : int
		{
			return this.getValue(StatType.RANK);
		}

		public function set rank(value : int) : void
		{
			this.setBase(StatType.RANK, value);
		}

		public function clone(provider : IStatsProvider) : Stats
		{
			var ret : Stats = new Stats(provider, locked);
			for (var index : Object in _stats)
			{
				ret.internalAddStat(_stats[index].clone());
			}
			return ret;
		}

		public function get provider() : IStatsProvider
		{
			return _provider;
		}

		public function getStat(type : StatType, required : Boolean = true) : Stat
		{
			var s : Stat = _statsByType[type];
			if (!s && required)
			{
				throw new ArgumentError("No such stat: " + type + " on " + _provider);
			}
			return s;
		}

		public function getBase(type : StatType, base : int = 0) : int
		{
			var s : Stat = getStat(type, false);
			if (s)
			{
				return s.base;
			}

			return base;
		}

		public function getValue(type : StatType, value : int = 0) : int
		{
			var s : Stat = getStat(type, false);
			if (s)
			{
				return s.value;
			}

			return value;
		}

		public function GetMaxAbilityLevel(ability : StatType) : int
		{
			return getValue(ability);
		}

		public function GetTotalUpgrades(statRanges : StatRanges) : int
		{
			var ret : int = 0;

			for each (var statType : StatType in userChangedStatTypes)
			{
				var sr : StatRange = statRanges.getStatRange(statType);
				var st : Stat = getStat(statType, false);
				if (st && sr)
				{
					ret += getValue(statType) - sr.min;
				}
			}

			return ret;
		}

		public function GetTotalPower(ranges : StatRanges) : int
		{
			return getValue(StatType.RANK) - 1;
		}

		private function getSinglePower(stat : StatType, ranges : StatRanges) : int
		{
			return getValue(stat) - ranges.getStatRange(stat).min;
		}

		public function setBase(type : StatType, value : int) : void
		{
			addStat(type, value);
		}

		public function getStatByIndex(index : int) : Stat
		{
			return _stats[index];
		}

		public function get numStats() : int
		{
			return _stats.length;
		}

		public function hasStat(type : StatType) : Boolean
		{
			for (var i : int = 0; i < _stats.length; ++i)
			{
				if (_stats[i].type.name == type.name)
				{
					return true;
				}
			}
			return false;
		}

		public function addStat(type : StatType, value : int) : Stat
		{
			var stat : Stat = getStat(type, false);
			if (stat)
			{
				stat.base = value;
			}
			else
			{
				stat = new Stat(type, value, locked);
				internalAddStat(stat);
			}
			return stat;

		}

		private function internalAddStat(stat : Stat) : void
		{
			if (hasStat(stat.type))
			{
				throw new ArgumentError("already hasStat");
			}

			_stats.push(stat);
			_statsByType[stat.type] = stat;
			stat.provider = provider;
		}

		public function getResistance(type : StatType) : int
		{
			if (type == StatType.STRENGTH)
			{
				return getValue(StatType.RESIST_STRENGTH, 0);
			}
			else if (type == StatType.ARMOR)
			{
				return getValue(StatType.RESIST_ARMOR, 0);
			}

			return 0;
		}
	}
}
