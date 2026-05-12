package engine.path
{

	public interface IPathGraphNode
	{
		function get cost() : Number;
		function get key() : Object;
		function get links() : Vector.<IPathGraphLink>;
		function get islandId() : int;
		function get enabled() : Object;
		function getLink(dst : IPathGraphNode) : IPathGraphLink;
		function addLink(dst : IPathGraphNode, cost : Number) : IPathGraphLink;
	}

}
