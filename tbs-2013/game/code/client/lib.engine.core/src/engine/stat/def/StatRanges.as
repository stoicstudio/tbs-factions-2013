package engine.stat.def
{
	import engine.stat.model.Stats;
	
	import flash.utils.Dictionary;

	public class StatRanges
	{
		private var _statsRangesByType : Dictionary = new Dictionary;
		private var _statRanges : Vector.<StatRange> = new Vector.<StatRange>;

		public function StatRanges()
		{
		}

		public function getStatRange(type : StatType) : StatRange
		{
			return _statsRangesByType[type];
		}

		public function getStatRangeByIndex(index : int) : StatRange
		{
			return _statRanges[index];
		}

		public function get numStatRanges() : int
		{
			return _statRanges.length;
		}

		public function hasStatRange(type : StatType) : Boolean
		{
			return type in _statsRangesByType;
		}

		public function addStatRange(type : StatType, min : int, max : int) : void
		{
			if (hasStatRange(type))
			{
				throw new ArgumentError("already hasStat " + type);
			}

			var sr : StatRange = new StatRange(type, min, max);
			_statRanges.push(sr);
			_statsRangesByType[sr.type] = sr;
		}

		public static function GetMaxUpgrades(rank : int) : int
		{
			return 9 + rank;
		}

		public function GetMaxStats(statTypes : Array) : int
		{
			var ret : int = 0;
			for each (var index : StatType in statTypes)
			{
				ret += _statsRangesByType[index].max;
			}
			return ret;
		}

		public function GetTotalMaxStats() : int
		{
			var ret : int = 0;
			for each (var statRange : StatRange in _statRanges)
			{
				ret += statRange.max;
			}
			return ret;
		}
	}
}
