package engine.battle.board.model
{
	import engine.battle.ability.model.BattleAbilityManager;
	import engine.battle.board.def.BattleBoardDef;
	import engine.battle.fsm.BattleFsm;
	import engine.battle.sim.IBattleParty;
	import engine.core.logging.ILogger;
	import engine.resource.ResourceManager;
	import engine.tile.Tiles;
	import engine.tile.def.TileLocation;
	import engine.tile.def.TileLocationArea;
	
	import flash.events.IEventDispatcher;
	import flash.utils.Dictionary;

	public interface IBattleBoard extends IEventDispatcher
	{
		function get def() : BattleBoardDef;
		function get numParties() : int;
		function getParty(index : int) : IBattleParty;
		function getPartyById(id : String) : IBattleParty;
		function getPartyIndex(party : IBattleParty) : int;
		function get entities() : Dictionary;
		function get logger() : ILogger;
		function get tiles() : Tiles;
		function get triggers() : IBattleBoardTriggers;
		function get abilityManager() : BattleAbilityManager;
		function set fake(value : Boolean) : void;
		function getEntity(id : String) : IBattleEntity;

		function get deathOffset() : Number;
		function set deathOffset(value : Number) : void;

		function get boardSetup() : Boolean;
		function set boardSetup(value : Boolean) : void;

		function get fsm() : BattleFsm;
		function get resman() : ResourceManager;

		function findAllRectIntersectionEntities(x : Number, y : Number, w : Number, l : Number, ignore : IBattleEntity, results : Vector.<IBattleEntity>) : Boolean;
		function findAllAdjacentEntities(sourceEntity : IBattleEntity, results : Vector.<IBattleEntity>) : void
		function findEntityOnTile(x : Number, y : Number, aliveOnly : Boolean, ignore : *) : IBattleEntity;
		function find2RectIntersections(x0 : Number, y0 : Number, w0 : Number, l0 : Number, x1 : Number, y1 : Number, w1 : Number, l1 : Number) : uint;

		function attemptDeploy(c : IBattleEntity, area : TileLocationArea, tile : TileLocation) : Boolean;
		function autoDeployPartyById(id : String) : void;
	}
}
