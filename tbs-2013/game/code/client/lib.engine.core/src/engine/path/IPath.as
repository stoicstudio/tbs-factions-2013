package engine.path
{
	import flash.events.EventDispatcher;

	public interface IPath
	{
		function get status() : PathStatus;
		function get src() : IPathGraphNode;
		function get dst() : IPathGraphNode;
		function get links() : Vector.<IPathGraphLink>;
		function get dispatcher() : EventDispatcher;
		function get nodes() : Vector.<IPathGraphNode>;

		function set links(rhs : Vector.<IPathGraphLink>) : void;
		function set status(s : PathStatus) : void;

		function get elapsed() : int;
		function set elapsed(e : int) : void;
	}
}
