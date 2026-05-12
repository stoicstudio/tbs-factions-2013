package engine.battle.board.model
{
	import engine.core.IUpdateable;

	import flash.events.IEventDispatcher;

	public interface IBattleEntityMobility extends IEventDispatcher, IUpdateable
	{
		function get entity() : IBattleEntity;
		function executeMove(move : IBattleMove) : void;
		function stopMoving() : void;
		function get moving() : Boolean;
		function set moving(val : Boolean) : void;
		function get moved() : Boolean;
		function set moved(val : Boolean) : void;
		function get numStepsMoved() : int;

		function fastForwardMove() : void;
	}
}
