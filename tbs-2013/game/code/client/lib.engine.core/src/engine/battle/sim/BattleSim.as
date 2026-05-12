package engine.battle.sim
{
	import engine.battle.board.model.BattleBoard;
	import engine.battle.fsm.BattleFsm;

	public class BattleSim
	{
		public var board : BattleBoard;
		public var started : Boolean;
		public var fsm : BattleFsm;

		public function BattleSim(board : BattleBoard, fsm : BattleFsm)
		{
			this.board = board;
			this.fsm = fsm;
		}

		public function cleanup() : void
		{
			board = null;
		}

	}
}
