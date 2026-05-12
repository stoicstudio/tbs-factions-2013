package engine.battle.ability.phantasm.model
{
	import engine.battle.ability.phantasm.def.PhantasmDef;

	import flash.events.Event;

	public class ChainPhantasmsEvent extends Event
	{
		/**
		 * This means it is ok go ignore the rest of the sequence, but it may keep playing for a while
		 */
		public static const STARTED : String = "ChainPhantasmsEvent.STARTED";
		public static const APPLIED : String = "ChainPhantasmsEvent.APPLIED";
		public static const ENDED : String = "ChainPhantasmsEvent.ENDED";
		public static const PHANTASM : String = "ChainPhantasmsEvent.PHANTASM";

		public var chain : ChainPhantasms;
		public var phantasmDef : PhantasmDef;

		public function ChainPhantasmsEvent(type : String, chain : ChainPhantasms, phantasmDef : PhantasmDef) : void
		{
			super(type);
			this.chain = chain;
			this.phantasmDef = phantasmDef;
		}
	}
}
