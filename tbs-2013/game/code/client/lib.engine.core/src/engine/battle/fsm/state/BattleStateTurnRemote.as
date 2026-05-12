package engine.battle.fsm.state
{
	import engine.battle.ability.model.BattleAbility;
	import engine.battle.ability.model.BattleAbilityVars;
	import engine.battle.fsm.BattleFsm;
	import engine.battle.fsm.BattleMove;
	import engine.battle.fsm.BattleMoveVars;
	import engine.battle.fsm.state.turn.cmd.BattleTurnCmdAction;
	import engine.battle.fsm.state.turn.cmd.BattleTurnCmdMove;
	import engine.battle.fsm.txn.BattleTxnQuery;
	import engine.core.fsm.StateData;
	import engine.core.fsm.StatePhase;
	import engine.core.logging.ILogger;

	import flash.events.TimerEvent;

	import tbs.srv.battle.data.client.BattleActionData;
	import tbs.srv.battle.data.client.BattleMoveData;

	public class BattleStateTurnRemote extends BattleStateTurnBase
	{
		public static const DEFAULT_FETCH_TIME_MS : int = 500;

		private var txnQuery : BattleTxnQuery;

		public function BattleStateTurnRemote(_data : StateData, fsm : BattleFsm, logger : ILogger)
		{
			super(_data, fsm, logger, false);
		}

		override protected function handleEnteredState() : void
		{
			super.handleEnteredState();
		}

		override protected function handleCleanup() : void
		{
			if (txnQuery)
			{
				txnQuery.abort();
				txnQuery = null;
			}
		}

		override public function handleMessage(msg : Object) : Boolean
		{
			if (msg["class"] == "tbs.srv.battle.data.client.BattleMoveData")
			{
				var bmd : BattleMoveData = new BattleMoveData;
				bmd.parseJson(msg, logger);

				handleMoveMsg(bmd);
				return true;
			}
			else if (msg["class"] == "tbs.srv.battle.data.client.BattleActionData")
			{
				var bad : BattleActionData = new BattleActionData();
				bad.parseJson(msg, logger);

				handleActionMsg(bad);
				return true;
			}

			return super.handleMessage(msg);
		}

		private function handleMoveMsg(msg : BattleMoveData) : void
		{
			logger.debug("BattleStateTurnRemote.handleMoveMsg got MOVE " + msg);

			if (turn.move.committed)
			{
				// silently ignore re-sends
				return;
			}

			if (cmdSeq.hasOrdinal(msg.ordinal))
			{
				return;
			}

			if (msg.entity != turn.entity)
			{
				logger.error("BattleStateTurnRemote.handleMoveMsg IGNORE attempt " + msg);
				return;
			}

			if (msg.tiles[0] != turn.entity.tile.location)
			{
				logger.error("BattleStateTurnRemote.handleMoveMsg INVALID move " + msg);
				return;
			}

			const move : BattleMove = new BattleMoveVars(battleFsm.board, msg, logger);
			const ordinal : int = msg.ordinal;

			turn.move.copy(move);
			turn.move.setCommitted("BattleStateTurnRemote");
			cmdSeq.addCmd(new BattleTurnCmdMove(this, ordinal, false, turn.move));

		}

		private function handleActionMsg(msg : BattleActionData) : void
		{

			if (cmdSeq.hasOrdinal(msg.ordinal))
			{
				return;
			}

			logger.debug("BattleStateTurnRemote.handleActionMsg got ACTION " + msg);

			if (msg.entity != turn.entity)
			{
				logger.error("BattleStateTurnRemote.handleActionMsg IGNORE attempt " + msg);
				return;
			}

			const action : BattleAbility = BattleAbilityVars.parse(msg, battleFsm.board, logger, battleFsm.board.abilityManager);

			cmdSeq.addCmd(new BattleTurnCmdAction(this, msg.ordinal, false, action, msg.terminator));
		}

		override protected function timeoutTimerCompleteHandler(event : TimerEvent) : void
		{
			logger.debug("BattleStateTurnRemote Timed out");

			// start asking the server wtf is going on

			checkTurnQuery();
		}

		private function checkTurnQuery() : void
		{
			if (!txnQuery)
			{
				txnQuery = new BattleTxnQuery(battleFsm.battleId, turn.number, checkTurnHandler, battleFsm, logger);
				txnQuery.send(battleFsm.session.communicator);
			}
		}

		private function checkTurnHandler(rhs : BattleTxnQuery) : void
		{
			if (phase == StatePhase.ENTERED)
			{
				if (rhs && rhs.success)
				{
					txnQuery.resend(battleFsm.session.communicator, 5000);
				}
			}
		}
	}
}
