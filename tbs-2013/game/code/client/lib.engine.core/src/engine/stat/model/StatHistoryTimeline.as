package engine.stat.model
{

	public class StatHistoryTimeline
	{
		public var points : Vector.<StatHistoryPoint> = new Vector.<StatHistoryPoint>;
		public var turnProvider : IStatHistoryTurnProvider;

		public function StatHistoryTimeline(turnProvider : IStatHistoryTurnProvider)
		{
			this.turnProvider = turnProvider;
		}

		public function get cumulative() : int
		{
			return points.length > 0 ? points[points.length - 1].cumulative : 0;
		}

		public function addDelta(delta : int) : void
		{
			var ihp : StatHistoryPoint = new StatHistoryPoint(turnProvider.turn, delta, cumulative);
			points.push(ihp);
		}
	}
}
