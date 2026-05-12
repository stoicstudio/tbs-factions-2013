package engine.stat.def
{

	public class StatPurchaseInfo
	{
		public var stat : StatType;
		public var delta : int;

		public function StatPurchaseInfo(stat : StatType, delta : int)
		{
			this.stat = stat;
			this.delta = delta;
			super();
		}

	}
}
