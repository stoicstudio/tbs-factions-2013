package engine.stat.def
{

	public class StatRange
	{
		public var type : StatType;
		public var min : int;
		public var max : int;

		public function StatRange(type : StatType, min : int, max : int)
		{
			this.type = type;
			this.min = min;
			this.max = max;
		}
	}
}
