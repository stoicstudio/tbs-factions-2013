package engine.stat.model
{

	public interface IStatModProvider
	{
		function handleUsed() : void;

		function get removed() : Boolean;
	}
}
