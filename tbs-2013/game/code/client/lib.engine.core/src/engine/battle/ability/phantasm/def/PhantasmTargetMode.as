package engine.battle.ability.phantasm.def
{
	import engine.core.util.Enum;

	public class PhantasmTargetMode extends Enum
	{
		public static const CASTER : PhantasmTargetMode = new PhantasmTargetMode("CASTER", enumCtorKey);
		public static const TARGET : PhantasmTargetMode = new PhantasmTargetMode("TARGET", enumCtorKey);
		public static const TILE : PhantasmTargetMode = new PhantasmTargetMode("TILE", enumCtorKey);
		public static const ALL_TARGETS : PhantasmTargetMode = new PhantasmTargetMode("ALL_TARGETS", enumCtorKey);
		public static const GUI : PhantasmTargetMode = new PhantasmTargetMode("GUI", enumCtorKey);

		public function PhantasmTargetMode(name : String, key : Object) : void
		{
			super(name, key);
		}

	}
}
