package engine.battle.ability.phantasm.def
{

	public class VfxSequenceDef
	{
		public var id : String;
		public var start : String;
		public var loop : String;
		public var end : String;
		public var depth : String = "main0";
		public var delay : int;
		public var oriented : Boolean = false;

		public function VfxSequenceDef()
		{
		}

		public function toString() : String
		{
			return "VfxSequenceDef [id=" + id + "]";
		}
	}
}
