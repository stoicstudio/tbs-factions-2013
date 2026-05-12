package engine.battle.ability.effect.model
{
	import flash.events.IEventDispatcher;
	
	import engine.battle.ability.model.BattleAbilityRetargetInfo;
	import engine.battle.ability.model.IBattleAbility;
	import engine.battle.board.model.IBattleEntity;

	public interface IPersistedEffects extends IEffectTagProvider, IEventDispatcher
	{
		function get effects() : Vector.<IEffect>;
		function addCastedEffect(effect : IEffect) : void;
		function addEffect(effect : IEffect) : void;
		function findCastedChildEffects(parent : IBattleAbility, target : IBattleEntity) : IEffect;
		function handleEndTurn() : void;
		function handleStartTurn() : void;
		function hasEffect(e : IEffect) : Boolean;
		function hasCastedEffect(e : IEffect) : Boolean;
		function onCasterEffectPhaseChange(effect : IEffect) : void;
		function onTargetEffectPhaseChange(effect : IEffect) : void;
		function onAbilityExecutingOnTarget(abl : IBattleAbility) : BattleAbilityRetargetInfo;
		function removeTag(tag : EffectTag) : void;
		function addTag(tag : EffectTag) : void;
		function clearTag(tag : EffectTag) : void;
	}
}
