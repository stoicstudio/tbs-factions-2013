package engine.battle.board.model
{
	import flash.events.IEventDispatcher;

	import engine.battle.ability.def.IBattleAbilityDef;
	import engine.battle.ability.effect.model.BattleFacing;
	import engine.battle.ability.effect.model.IEffect;
	import engine.battle.ability.effect.model.IPersistedEffects;
	import engine.battle.ability.model.BattleRecord;
	import engine.battle.ability.phantasm.model.IChainPhantasms;
	import engine.battle.sim.IBattleParty;
	import engine.core.logging.ILogger;
	import engine.entity.model.IEntity;
	import engine.tile.ITileResident;
	import engine.tile.Tile;

	public interface IBattleEntity extends IEntity, ITileResident
	{
		function get alive() : Boolean;
		function get team() : String;
		function get board() : IBattleBoard;
		function set suppressMoveEvents(value : Boolean) : void;
		function setPos(x : Number, y : Number) : void;
		function get triggering() : Boolean;
		function set triggering(value : Boolean) : void;
		function get party() : IBattleParty;
		function set party(value : IBattleParty) : void;
		function get mobility() : IBattleEntityMobility;
		function get facing() : BattleFacing;
		function set facing(value : BattleFacing) : void;
		function get ignoreTargetRotation() : Boolean;
		function incrementIgnoreTargetRotation() : void;
		function decrementIgnoreTargetRotation() : void;

		function get ignoreFacing() : Boolean;
		function set ignoreFacing(val : Boolean) : void;

		function get ignoreFreezeFrame() : Boolean;
		function set ignoreFreezeFrame(val : Boolean) : void;

		function get record() : BattleRecord;

		function emitFlyText(str : String, color : uint, fontName : String, fontSize : int) : void;

		function playGoAnimation() : void;

		function get animEventDispatcher() : IEventDispatcher;

		function get effects() : IPersistedEffects;

		function createChainForEffect(effect : IEffect) : IChainPhantasms;

		function get logger() : ILogger;

		function set deploymentReady(value : Boolean) : void;
		function get deploymentReady() : Boolean;

		function get enabled() : Boolean;

		function handleMissed(effect : IEffect) : void;

		function handleResisted(effect : IEffect) : void;

		function set locoId(value : String) : void;
		function get locoId() : String;

		// turn stuff TBDestroyed
		/////////////////////////

		function endTurn() : void;
		function setTurnSuspended(value : Boolean) : void;

		/////////////////////////

		function onStartTurn() : void;
		function onEndTurn() : void;

		function get killingEffect() : IEffect;
		function set killingEffect(value : IEffect) : void;
		function highestAvailableAbilityDef() : IBattleAbilityDef;
		function lowestValidAbilityDef(t : IBattleEntity, tile : Tile, move : IBattleMove) : IBattleAbilityDef;
	}
}
