package game.session.states
{
	import engine.battle.fsm.txn.BattleTxnSurrenderSend;
	import engine.core.fsm.Fsm;
	import engine.core.fsm.StateData;
	import engine.core.logging.ILogger;

	import game.session.GameState;

	import tbs.srv.battle.data.client.BattleCreateData;

	public class VersusCancelState extends GameState
	{
		private var txn : BattleTxnSurrenderSend;

		public function VersusCancelState(_data : StateData, fsm : Fsm, logger : ILogger)
		{
			super(_data, fsm, logger);
		}

		override protected function handleCleanup() : void
		{
			if (txn)
			{
				txn.abort();
				txn = null;
			}
		}

		override protected function handleEnteredState() : void
		{
			const bcd : BattleCreateData = data.getValue(GameStateDataEnum.BATTLE_CREATE_DATA);
			if (bcd)
			{
				logger.info("VersusCancelState SENDING SURRENDER: " + bcd.battle_id);
				txn = new BattleTxnSurrenderSend(bcd.battle_id, credentials, surrenderSendHandler, null, logger);
				txn.send(communicator);
			}
			else
			{
				logger.info("VersusCancelState NO BATTLE, FINISHING");
				doFinish();
			}
		}

		private function doFinish() : void
		{
			const lobby_id : int = data.getValue(GameStateDataEnum.BATTLE_FRIEND_LOBBY_ID);

			var restart : Boolean = data.getValue(GameStateDataEnum.VERSUS_RESTART);
			data.removeValue(GameStateDataEnum.VERSUS_RESTART);

			if (restart)
			{
				config.fsm.transitionTo(VersusFindMatchState, config.fsm.current.data);
			}
			else if (config.factions && lobby_id == config.factions.lobbyManager.current.options.lobby_id)
			{
				config.fsm.transitionTo(FriendLobbyState, null);
			}
			else if (config.runMode.town)
			{
				config.fsm.transitionTo(GreatHallState, config.fsm.current.data);
			}
			else
			{
				config.context.appInfo.exitGame("VersusCancelState.doFinish runMode=" + config.runMode);
			}
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
