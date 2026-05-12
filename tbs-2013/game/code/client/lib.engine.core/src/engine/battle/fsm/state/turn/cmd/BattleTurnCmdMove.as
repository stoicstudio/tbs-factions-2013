package engine.battle.fsm.state.turn.cmd
{
	import engine.battle.fsm.BattleMove;
	import engine.battle.fsm.state.BattleStateTurnBase;
	import engine.battle.fsm.txn.BattleTxnMoveSend;

	public class BattleTurnCmdMove extends BattleTurnCmd
	{
		public var move : BattleMove;

		public function BattleTurnCmdMove(state : BattleStateTurnBase, ordinal : int, requiresOrdering : Boolean, move : BattleMove)
		{
			super(state, ordinal, requiresOrdering);
			if (move != turn.move)
			{
				throw new ArgumentError("bad move");
			}
			this.move = move;
		}

		override protected function handleBattleExecute() : void
		{
			if (turn.entity.playerControlled && battleFsm.isOnline)
			{
				const txn : BattleTxnMoveSend = new BattleTxnMoveSend(battleFsm.battleId, turn.number, move, ordinal, battleFsm.session.credentials, null, battleFsm, logger);
				txn.send(battleFsm.session.communicator);
			}

			turn.entity.mobility.executeMove(move);
			battleComplete();
		}
	}
}
