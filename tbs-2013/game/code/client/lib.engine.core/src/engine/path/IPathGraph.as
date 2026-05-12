package engine.path
{
	import flash.utils.Dictionary;

	public interface IPathGraph
	{
		function getNode(key : Object) : IPathGraphNode;
		function addNode(key : Object, cost : Number) : IPathGraphNode;
		function addLink(src : Object, dst : Object, linkCost : Number, directed : Boolean) : void;
		function getPath(src : Object, dst : Object, nodeBlockedFunc : Function = null) : IPath;
		function getLinks(src : Object) : Vector.<IPathGraphLink>;
		function getLink(src : Object, dst : Object) : IPathGraphLink;
		function update(limitMs : int) : void;

		function setUpdateRate(delay : int, limitMs : int) : void;
		function stopUpdate() : void;
		function startUpdate() : void;

		function get nodes() : Dictionary;
		function finishGraphGeneration(maxIslands : int, nodeCullCallback : Function) : void;
		function setNodeEnabled(node : IPathGraphNode, enabled : Boolean) : void;
	}
}
