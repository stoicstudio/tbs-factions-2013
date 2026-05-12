package engine.battle.ability.phantasm.def
{
	import engine.core.logging.ILogger;
	import engine.core.util.EngineCoreContext;
	import engine.def.EngineJsonDef;

	public class PhantasmDefAnim extends PhantasmDef
	{
		public static const schema : Object =
			{
				name: "PhantasmDefAnim",
				type: "object",
				properties: {
					anim: {type: "string"},
					killingAnim: {type: "string", optional: true},
					base: {type: PhantasmDefVars.schema}
				}
			};

		public var anim : String;
		public var killingAnim : String;

		public function PhantasmDefAnim(vars : Object, logger : ILogger)
		{
			EngineJsonDef.validateThrow(vars, schema, logger);
			PhantasmDefVars.parse(this, vars.base, logger);

			this.anim = vars.anim;
			this.killingAnim = vars.killingAnim;
		}

		override public function toString() : String
		{
			return "PDAnim " + super.toString() + " anim=" + anim + " killing=" + killingAnim;
		}
	}
}
