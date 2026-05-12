package engine.battle.board
{
	import engine.battle.board.model.BattleBoard;
	import engine.battle.board.model.IBattleEntity;

	import flash.events.Event;

	public class BattleBoardEvent extends Event
	{
		public static const TRIGGERS : String = "BattleBoardEvent.TRIGGERS";
		public static const ENABLED : String = "BattleBoardEvent.ENABLED";
		public static const PARTY : String = "BattleBoardEvent.ENABLED";
		public static const BOARDSETUP : String = "BattleBoardEvent.BOARDSETUP";
		public static const SELECT_TILE : String = "BattleBoardEvent.SELECT_TILE";
		public static const BOARD_ENTITY_ALIVE : String = "BattleBoardEvent.BOARD_ENTITY_ALIVE";
		public static const BOARD_ENTITY_KILLING_EFFECT : String = "BattleBoardEvent.BOARD_ENTITY_KILLING_EFFECT";
		public static const BOARD_ENTITY_DAMAGED : String = "BattleBoardEvent.BOARD_ENTITY_DAMAGED";

		public var entity : IBattleEntity;

		public function BattleBoardEvent(type : String, entity : IBattleEntity = null)
		{
			super(type, false, false);

			this.entity = entity;
		}

		public function get board() : BattleBoard
		{
			return target as BattleBoard;
		}
	}
}
