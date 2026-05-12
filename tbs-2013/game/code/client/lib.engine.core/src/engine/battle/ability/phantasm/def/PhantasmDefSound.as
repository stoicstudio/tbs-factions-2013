package engine.battle.ability.phantasm.def
{
	import engine.core.logging.ILogger;
	import engine.def.EngineJsonDef;

	public class PhantasmDefSound extends PhantasmDef
	{
		public static const schema : Object =
			{
				name: "PhantasmDefSound",
				type: "object",
				properties: {
					sound: {
						type: "string"
					},
					base:
					{
						type: PhantasmDefVars.schema
					}
				}
			};

		public var sound : String;

		public function PhantasmDefSound(vars : Object, logger : ILogger)
		{
			EngineJsonDef.validateThrow(vars, schema, logger);
			PhantasmDefVars.parse(this, vars.base, logger);

			this.sound = vars.sound;
		}

		override public function toString() : String
		{
			return "PDSound " + super.toString() + " sound=" + sound;
		}

	}
}
