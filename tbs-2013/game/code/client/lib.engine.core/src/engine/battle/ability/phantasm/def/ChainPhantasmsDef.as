package engine.battle.ability.phantasm.def
{
	import engine.battle.ability.effect.def.IEffectDef;
	import engine.battle.ability.effect.model.EffectPhase;
	import engine.battle.ability.effect.model.EffectResult;

	import flash.utils.Dictionary;

	public class ChainPhantasmsDef
	{

		public var applyTriggers : Vector.<PhantasmAnimTriggerDef> = new Vector.<PhantasmAnimTriggerDef>;
		public var endTriggers : Vector.<PhantasmAnimTriggerDef> = new Vector.<PhantasmAnimTriggerDef>;

		public var applyTime : int;
		public var endTime : int;
		public var entries : Vector.<PhantasmDef> = new Vector.<PhantasmDef>;
		public var timedEntries : Vector.<PhantasmDef> = new Vector.<PhantasmDef>;
		public var results : Dictionary = new Dictionary;
		private var resultCount : int;
		public var waitEffect : IEffectDef;
		public var waitEffectPhase : EffectPhase;
		public var rotation : Boolean = true;
		public var animTriggerEntriesMap : Dictionary = new Dictionary;

		public function ChainPhantasmsDef() : void
		{

		}

		protected function addResult(r : EffectResult) : void
		{
			results[r] = r;
			++resultCount;
		}

		public function isResultOk(r : EffectResult) : Boolean
		{
			if (resultCount <= 0)
			{
				return true;
			}

			if (results[r] != null)
			{
				return true;
			}

			return false;
		}
	}
}

