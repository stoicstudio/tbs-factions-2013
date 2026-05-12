package engine.battle.ability.phantasm.def
{
	import engine.battle.ability.effect.def.EffectTagReqs;

	public class PhantasmDef
	{
		public var time : int;
		public var targetMode : PhantasmTargetMode;
		public var animTrigger : PhantasmAnimTriggerDef;
		public var sync : String;
		public var casterTagReqs : EffectTagReqs = null;

		public function PhantasmDef()
		{
		}

		public function toString() : String
		{
			return "time=" + time + " target=" + targetMode + " trigger=" + animTrigger + " sync=" + sync;
		}

	}

}
