package engine.battle.sim
{
	import flash.events.IEventDispatcher;
	
	import engine.battle.board.model.BattlePartyType;
	import engine.battle.board.model.IBattleBoard;
	import engine.battle.board.model.IBattleEntity;

	public interface IBattleParty extends IEventDispatcher
	{
		function get numMembers() : int;
		function getMember(index : int) : IBattleEntity;
		function get board() : IBattleBoard;
		function get id() : String;
		function get team() : String;
		function get deployment() : String;
		function get deployed() : Boolean;
		function set deployed(value : Boolean) : void;
		function get type() : BattlePartyType;
		function get isPlayer() : Boolean;
		function get isEnemy() : Boolean;
		function get isAlly() : Boolean;
		function get surrendered() : Boolean;
		function set surrendered(value : Boolean) : void;
		function get aborted() : Boolean;
		function set aborted(value : Boolean) : void;
		function get partyName() : String;
		function get hornSize() : int;
		function set hornSize(value : int) : void;
		function getAllMembers(all : Vector.<IBattleEntity>) : Vector.<IBattleEntity>;
		function get timer() : int;
		
		function get numAlive() : int;
		
		function get trauma() : Number;
		function get vitality() : Number;
		function get initialVitality() : Number;
	}
}
