package engine.battle.ability.effect.op.def
{
	import engine.battle.ability.def.BattleAbilityDefFactory;
	import engine.battle.ability.effect.model.Effect;
	import engine.battle.ability.effect.op.model.Op;
	import engine.core.logging.ILogger;
	import engine.core.util.Enum;

	public class EffectDefOp
	{

		public var id : IdEffectOp;
		public var params : Object;
		public var name : String;
		public var enabled : Boolean = true;

		public function EffectDefOp()
		{

		}

		public function toString() : String
		{
			return "DefOp [" + id + ", " + name + "]";
		}

		public function construct(effect : Effect) : Op
		{
			return new id.clazz(this, effect) as Op;
		}

		public static function constructDef(vars : Object, logger : ILogger) : EffectDefOp
		{
			var id : IdEffectOp = Enum.parse(IdEffectOp, vars.id) as IdEffectOp;
			return new id.defClazz(vars, logger) as EffectDefOp;
		}

		public function link(factory : BattleAbilityDefFactory) : void
		{

		}
	}
}
