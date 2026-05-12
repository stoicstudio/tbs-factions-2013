package engine.path
{
	public interface IPathGraphLink
	{
		function get src() : IPathGraphNode;
		function get dst() : IPathGraphNode;
		function get cost() : Number;
	}
}