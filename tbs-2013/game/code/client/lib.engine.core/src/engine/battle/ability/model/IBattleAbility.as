package engine.battle.ability.model
{
	import flash.events.IEventDispatcher;
	
	import engine.battle.ability.def.BattleAbilityDef;
	import engine.battle.ability.effect.def.IEffectDef;
	import engine.battle.ability.effect.model.Effect;
	import engine.battle.board.model.IBattleEntity;

	public interface IBattleAbility extends IEventDispatcher
	{
		function get targetSet() : BattleTargetSet;
		function get def() : BattleAbilityDef;
		function get caster() : IBattleEntity;
		function get executed() : Boolean;
		function get executing() : Boolean;
		function get completed() : Boolean;
		function get finalCompleted() : Boolean;
		function execute(callback : Function) : void;
		function addChildAbility(child : IBattleAbility) : void;
		function get parent() : IBattleAbility;
		function set parent(value : IBattleAbility) : void;
		function get root() : IBattleAbility;
		function checkCompletion() : void;
		function onEffectPhaseChange(e : Effect) : void;
		function getEffectByDef(ed : IEffectDef) : Effect;
		function getEffectByName(en : String) : Effect;
		function get manager() : BattleAbilityManager;
		function get fake() : Boolean;
		function get executedId() : int;
		function removeAllEffects() : void;
		function onEffectUnblocked(effect : Effect) : void;
	}
}
