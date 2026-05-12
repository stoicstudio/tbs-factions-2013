package engine.battle.ability.effect.model
{
	import flash.events.Event;

	public class EffectEvent extends Event
	{
		public static const REMOVED : String = "EffectEvent.REMOVED";

		public function EffectEvent(type : String, bubbles : Boolean = false, cancelable : Boolean = false)
		{
			super(type, bubbles, cancelable);
		}
	}
}
