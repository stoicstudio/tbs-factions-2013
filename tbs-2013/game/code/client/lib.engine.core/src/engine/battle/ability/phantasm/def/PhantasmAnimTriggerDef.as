package engine.battle.ability.phantasm.def
{
	import engine.core.logging.ILogger;

	public class PhantasmAnimTriggerDef
	{
		public var animTargetMode : PhantasmTargetMode;
		public var animId : String;
		public var animEventId : String;
		public var guaranteed : Boolean;
		public var deltaMs : int;

		public function PhantasmAnimTriggerDef()
		{
		}

		public static function getKey(animTargetMode : PhantasmTargetMode, animId : String, animEventId : String) : String
		{
			return animTargetMode.name + "_" + animId + "_" + animEventId;
		}

		public function get key() : String
		{
			return getKey(animTargetMode, animId, animEventId);
		}

		public function toString() : String
		{
			return key;
		}
	}
}
