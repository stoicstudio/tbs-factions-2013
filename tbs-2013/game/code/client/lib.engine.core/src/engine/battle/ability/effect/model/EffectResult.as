package engine.battle.ability.effect.model
{
	import engine.core.util.Enum;

	public class EffectResult extends Enum
	{
		public static const OK : EffectResult = new EffectResult("OK", enumCtorKey);
		public static const FAIL : EffectResult = new EffectResult("FAIL", enumCtorKey);
		public static const MISS : EffectResult = new EffectResult("MISS", enumCtorKey);

		public function EffectResult(name : String, key : Object)
		{
			super(name, key);
		}

		public function combineUp(rhs : EffectResult) : EffectResult
		{
			if (this == OK || rhs == OK)
			{
				return OK;
			}
			else
			{
				return this;
			}
		}
	}
}
