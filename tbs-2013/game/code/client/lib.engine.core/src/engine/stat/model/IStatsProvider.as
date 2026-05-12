package engine.stat.model
{
	import engine.stat.def.StatType;

	public interface IStatsProvider
	{
		function get stats() : Stats;
	}
}
