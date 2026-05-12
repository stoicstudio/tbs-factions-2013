package engine.battle.board.model
{
	import engine.tile.Tile;

	public interface IBattleMove
	{
		function get numSteps() : int;
		function getStep(index : int) : Tile;
		function get first() : Tile;
		function get last() : Tile;
		function hasStep(tile : Tile) : Boolean;
		function get executed() : Boolean;
		function setExecuted() : void;
		function get executing() : Boolean;
		function setExecuting() : void;
		function get committed() : Boolean;
		function setCommitted(reason : String) : void;
		function get interrupted() : Boolean;
		function setInterrupted() : void;
		function get forcedMove() : Boolean;
		function set forcedMove(val : Boolean) : void;
		function get reactToEntityIntersect() : Boolean;
		function set reactToEntityIntersect(val : Boolean) : void;
		function handleIntersectEntity() : void;
	}
}
