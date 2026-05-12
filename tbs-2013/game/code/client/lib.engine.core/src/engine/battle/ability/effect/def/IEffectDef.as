package engine.battle.ability.effect.def
{
	import engine.battle.ability.effect.model.EffectResult;
	import engine.battle.ability.effect.model.EffectTag;
	import engine.battle.ability.effect.op.def.EffectDefOp;
	import engine.battle.ability.phantasm.def.ChainPhantasmsDef;
	import engine.core.logging.ILogger;

	import flash.utils.Dictionary;

	public interface IEffectDef
	{
		function hasTag(tag : EffectTag) : Boolean;

		function getChainPhantasmsForResult(r : EffectResult) : ChainPhantasmsDef;

		function get phantasms() : Vector.<ChainPhantasmsDef>;

		function get conditions() : Vector.<EffectDefConditions>;

		function get persistent() : EffectDefPersistence;

		function get ops() : Vector.<EffectDefOp>;

		function get name() : String;

		function get tags() : Dictionary;

		function get targetCaster() : Boolean;

		function get logger() : ILogger;
	}
}
