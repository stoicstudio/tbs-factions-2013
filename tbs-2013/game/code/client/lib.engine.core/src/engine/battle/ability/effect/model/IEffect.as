package engine.battle.ability.effect.model
{
	import engine.battle.ability.model.BattleAbilityRetargetInfo;
	import engine.battle.ability.model.IBattleAbility;
	import engine.battle.board.model.IBattleEntity;

	import flash.events.IEventDispatcher;
	import flash.utils.Dictionary;

	public interface IEffect extends IEventDispatcher
	{
		function casterStartTurn() : Boolean;
		function targetStartTurn() : Boolean;
		function onAbilityExecutingOnTarget(abl : IBattleAbility) : BattleAbilityRetargetInfo;
		function get ability() : IBattleAbility;
		function get phase() : EffectPhase;
		function get tags() : Dictionary;
		function cleanup() : void;
		function get target() : IBattleEntity;
		function remove() : void;
	}
}
