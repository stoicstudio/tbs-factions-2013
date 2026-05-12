package engine.battle.ability.effect.def
{
	import flash.utils.Dictionary;

	import engine.battle.ability.def.BattleAbilityDefFactory;
	import engine.battle.ability.effect.model.EffectResult;
	import engine.battle.ability.effect.model.EffectTag;
	import engine.battle.ability.effect.model.IEffectTagProvider;
	import engine.battle.ability.effect.op.def.EffectDefOp;
	import engine.battle.ability.phantasm.def.ChainPhantasmsDef;
	import engine.core.logging.ILogger;

	public class EffectDef implements IEffectTagProvider, IEffectDef
	{
		protected var _phantasms : Vector.<ChainPhantasmsDef> = new Vector.<ChainPhantasmsDef>;
		protected var _conditions : Vector.<EffectDefConditions> = new Vector.<EffectDefConditions>;
		protected var _persistent : EffectDefPersistence;
		protected var _ops : Vector.<EffectDefOp> = new Vector.<EffectDefOp>;
		protected var _name : String;
		protected var _tags : Dictionary = new Dictionary;
		protected var _targetCaster : Boolean;
		protected var _logger : ILogger;

		public function EffectDef() : void
		{

		}

		public function hasTag(tag : EffectTag) : Boolean
		{
			return tags[tag] != null;
		}

		public function toString() : String
		{
			return "[name=" + name + "]";
		}

		public function getChainPhantasmsForResult(r : EffectResult) : ChainPhantasmsDef
		{
			for each (var cpd : ChainPhantasmsDef in phantasms)
			{
				if (cpd.isResultOk(r))
				{
					return cpd;
				}
			}

			return null;
		}

		public function link(factory : BattleAbilityDefFactory) : void
		{
			for each (var op : EffectDefOp in ops)
			{
				op.link(factory);
			}
		}

		public function get phantasms() : Vector.<ChainPhantasmsDef>
		{
			return _phantasms;
		}

		public function get conditions() : Vector.<EffectDefConditions>
		{
			return _conditions;
		}

		public function get persistent() : EffectDefPersistence
		{
			return _persistent;
		}

		public function get ops() : Vector.<EffectDefOp>
		{
			return _ops;
		}

		public function get name() : String
		{
			return _name;
		}

		public function get tags() : Dictionary
		{
			return _tags;
		}

		public function get targetCaster() : Boolean
		{
			return _targetCaster;
		}

		public function get logger() : ILogger
		{
			return _logger;
		}

	}
}
