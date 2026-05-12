package engine.battle.ability.phantasm.def
{
	import engine.core.logging.ILogger;
	import engine.def.BooleanVars;
	import engine.def.EngineJsonDef;
	import engine.def.NumberVars;

	public class PhantasmDefSprite extends PhantasmDef
	{
		public static const schema : Object =
			{
				name: "PhantasmDefSprite",
				description: "PhantasmDefSprite Definition",
				type: "object",
				properties: {
					spriteName: {type: "string", optional: true},
					vfx: {type: VfxSequenceDefVars.schema, optional: true},
					parameter: {type: "string", optional: true},
					parameter_value: {type: "number", optional: true},
					oriented: {type: "boolean", optional: true},
					rotate: {
						type: "boolean",
						optional: true,
						description: "vfx rotate to target or caster based on target mode"
					},
					color: {
						type: "number",
						optional: true
					},
					alpha: {
						type: "number",
						optional: true
					},
					height: {
						type: "number", optional: true
					},
					base:
					{
						type: PhantasmDefVars.schema
					}
				}
			};

		public var rotate : Boolean;
		public var color : uint = 0xffffffff;
		public var alpha : Number = 1;
		public var height : Number = 0.5;
		public var vfx : VfxSequenceDef;
		public var parameter : String;
		public var parameter_value : Number = 0;

		public function PhantasmDefSprite(vars : Object, logger : ILogger)
		{
			EngineJsonDef.validateThrow(vars, schema, logger);
			PhantasmDefVars.parse(this, vars.base, logger);

			this.rotate = BooleanVars.parse(vars.rotate, true);
			this.color = vars.color != undefined ? vars.color : this.color;
			this.alpha = vars.alpha != undefined ? vars.alpha : this.alpha;
			this.height = vars.height != undefined ? vars.height : this.height;

			this.parameter = vars.parameter;
			this.parameter_value = NumberVars.parse(vars.parameter_value, parameter_value);

			if (vars.vfx != undefined)
			{
				vfx = new VfxSequenceDefVars(vars.vfx, logger);
			}
			else if (vars.spriteName == undefined)
			{
				throw new ArgumentError("Needs a vfx or spriteName");
			}
			else
			{
				// pseudo-vfx
				vfx = new VfxSequenceDef;
				vfx.start = vars.spriteName;
				if (vars.oriented)
				{
					vfx.oriented = vars.oriented;
				}
			}
		}

		override public function toString() : String
		{
			return "PDSprite " + super.toString() + " vfx=" + vfx + " rotate=" + rotate + " color=" + color + " alpha=" + alpha;
		}

	}
}
