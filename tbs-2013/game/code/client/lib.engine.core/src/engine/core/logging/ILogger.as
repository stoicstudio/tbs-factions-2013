package engine.core.logging
{

	public interface ILogger
	{
		function get name() : String;
		function debug(str : String) : void;
		function info(str : String) : void;
		function error(str : String) : void;
		function addTarget(target : ILogTarget) : ILogger;
		function get debugEnabled() : Boolean;
		function set debugEnabled(value : Boolean) : void;
		function get frameNumber() : int;
		function set frameNumber(value : int) : void;
	}
}
