package engine.battle.ability.phantasm.model
{

	import flash.events.Event;

	public class PhantasmsEvent extends Event
	{
		public static const CHAIN_STARTED : String = "CombatPhantasmsEvent.CHAIN_STARTED";

		public var chain : ChainPhantasms;

		public function PhantasmsEvent(type : String, chain : ChainPhantasms)
		{
			super(type);

			this.chain = chain;
		}
	}
}
