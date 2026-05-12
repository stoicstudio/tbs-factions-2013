package engine.battle.fsm.state
{
	import engine.battle.fsm.BattleFsm;
	import engine.battle.fsm.BattleStateDataEnum;
	import engine.battle.fsm.txn.BattleTxnSurrenderSend;
	import engine.battle.sim.IBattleParty;
	import engine.core.fsm.StateData;
	import engine.core.fsm.StatePhase;
	import engine.core.logging.ILogger;

	public class BattleStateSurrender extends BaseBattleState
	{
		public function BattleStateSurrender(_data : StateData, fsm : BattleFsm, logger : ILogger, timeoutMs : int = 0)
		{
			super(_data, fsm, logger, timeoutMs);
		}

		override protected function handleEnteredState() : void
		{
			super.handleEnteredState();

			var party : IBattleParty = battleFsm.board.getPartyById(battleFsm.session.credentials.userId.toString());
			party.surrendered = true;

			if (battleFsm.isOnline)
			{
				var txn : BattleTxnSurrenderSend = new BattleTxnSurrenderSend(battleFsm.battleId, battleFsm.session.credentials, surrenderSendHandler, battleFsm, logger);
				txn.send(battleFsm.session.communicator);
			}
			else
			{
				doFinish();
			}
		}

		private function doFinish() : void
		{

			for (var i : int = 0; i < battleFsm.board.numParties; ++i)
			{
				// TODO, we may still have an ally left and the battle is not actually finished for him
				var p : IBattleParty = battleFsm.board.getParty(i);
				if (p.isEnemy)
				{
					logger.info("BattleStateSurrender.doFinish VICTORIOUS_TEAM=" + p.team);

					data.setValue(BattleStateDataEnum.VICTORIOUS_TEAM, p.team);
					break;
				}
			}

			battleFsm.battleFinished = true;
			phase = StatePhase.COMPLETED;
		}

		private function surrenderSendHandler(txn : BattleTxnSurrenderSend) : void
		{
			if (txn.success)
			{
				doFinish();
			}
		}
	}
}
