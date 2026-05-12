package engine.battle.entity.model
{
	import flash.events.Event;

	public class BattleEntityEvent extends Event
	{
		public static const ADDED : String = "BattleEntityEvent.ADDED";
		public static const REMOVED : String = "BattleEntityEvent.REMOVED";
		public static const MOVED : String = "BattleEntityEvent.MOVED";
		public static const MOVE_FINISHING : String = "BattleEntityEvent.MOVE_FINISHING";
		public static const SELECTED : String = "BattleEntityEvent.SELECTED";
		public static const HILIGHTED : String = "BattleEntityEvent.HILIGHTED";
		public static const TARGETED : String = "BattleEntityEvent.TARGETED";
		public static const ATTACK_TARGET : String = "BattleEntityEvent.ATTACK_TARGET";
		public static const GO_ANIMATION : String = "BattleEntityEvent.GO_ANIMATION";
		public static const ENOUGH_KILLS_TO_PROMOTE_VFX : String = "BattleEntityEvent.ENOUGH_KILLS_TO_PROMOTE_VFX";
		public static const DAMAGE_FLAG : String = "BattleEntityEvent.DAMAGE_FLAG";
		public static const FLY_TEXT : String = "BattleEntityEvent.FLY_TEXT";
		public static const TRIGGERING : String = "BattleEntityEvent.TRIGGERING";
		public static const FACING : String = "BattleEntityEvent.FACING";
		public static const ALIVE : String = "BattleEntityEvent.ALIVE";
		public static const COLLIDABLE : String = "BattleEntityEvent.COLLIDABLE";
		public static const ENABLED : String = "BattleEntityEvent.ENABLED";
		public static const DEPLOYMENT_READY : String = "BattleEntityEvent.DEPLOYMENT_READY";
		public static const MISSED : String = "BattleEntityEvent.MISSED";
		public static const RESISTED : String = "BattleEntityEvent.RESISTED";
		public static const KILLING_EFFECT : String = "BattleEntityEvent.KILLING_EFFECT";
		public static const DAMAGED : String = "BattleEntityEvent.DAMAGED";

		public var entity : BattleEntity;

		public function BattleEntityEvent(type : String, entity : BattleEntity)
		{
			super(type, false, false);
			this.entity = entity;
		}
	}
}
