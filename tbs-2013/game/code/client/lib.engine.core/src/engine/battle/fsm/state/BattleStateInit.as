package engine.battle.fsm.state
{
	import engine.battle.fsm.BattleFsm;
	import engine.battle.fsm.txn.BattleTxnStartSend;
	import engine.core.fsm.StateData;
	import engine.core.fsm.StatePhase;
	import engine.core.logging.ILogger;

	public class BattleStateInit extends BaseBattleState
	{
		private var localReady : Boolean;
		private var txnSend : BattleTxnStartSend;
		private var remotesReady : Boolean = false

		public function BattleStateInit(_data : StateData, fsm : BattleFsm, logger : ILogger)
		{
			super(_data, fsm, logger, fsm.config.deployTimeoutMs);
		}

		override protected function handleEnteredState() : void
		{
			logger.debug("BattleStateInit.handleEnteredState");
			battleFsm.stopEatingSubsequent("tbs.srv.battle.data.client.BattleReadyData");
			checkReady();
		}

		private function checkReady() : void
		{			
			logger.debug("BattleStateInit.checkReady localReady=" + localReady + " phase=" + phase);
			
			if (localReady && phase == StatePhase.ENTERED)
			{
				if (battleFsm.isOnline)
				{
					if (!txnSend)
					{
						logger.debug("BattleStateInit LOCAL READY: " + battleFsm.battleId);

						txnSend = new BattleTxnStartSend(battleFsm.battleId, battleFsm.session.credentials, sendHandler, battleFsm, logger);
						addTxn(txnSend);
						txnSend.send(battleFsm.session.communicator, null, 0);
						checkComplete();
					}
				}
				else
				{
					phase = StatePhase.COMPLETED;
				}
			}
		}

		public function setReady() : void
		{
			logger.info("BattleStateInit.setReady");
			localReady = true;
			checkReady();
		}

		override protected function handleCleanup() : void
		{
			super.handleCleanup();
			battleFsm.eatAllSubsequent("tbs.srv.battle.data.client.BattleReadyData");
		}

		private function sendHandler(txn : BattleTxnStartSend) : void
		{
			if (txn.success)
			{
				checkComplete();
//				fetchWithDelay(0);
			}
		}

//
//		private function fetchHandler(txn : BattleTxnGet) : void
//		{
//			fetchWithDelay(500);
//		}

		override public function handleMessage(msg : Object) : Boolean
		{
			if (msg["class"] == "tbs.srv.battle.data.client.BattleReadyData")
			{
				logger.info("BattleStateInit REMOTE READY: " + msg.user_id);
				remotesReady = true;
				// TODO handle more than one opponent
				checkComplete();
				return true;
			}

			return false;
		}

		public function checkComplete() : void
		{
			logger.debug("BattleStateInit.checkComplete remotesReady=" + remotesReady + " localReady=" + localReady + " + txnSend=" + txnSend + " txnSend.success=" + (txnSend ? txnSend.success : "<>"));

			// we do want to gate game starting until we hear back from the server that our message got through
			if (remotesReady && localReady && txnSend && txnSend.success)
			{
				phase = StatePhase.COMPLETED;
			}
		}
	}
}
