package game.session.states
{
	import engine.core.fsm.Fsm;
	import engine.core.fsm.StateData;
	import engine.core.fsm.StatePhase;
	import engine.core.logging.ILogger;

	import game.session.GameState;
	import game.session.actions.AccountInfoTxn;

	public class AccountInfoState extends GameState
	{
		private var action : AccountInfoTxn;

		public function AccountInfoState(_data : StateData, fsm : Fsm, logger : ILogger)
		{
			super(_data, fsm, logger);
		}

		override protected function handleEnteredState() : void
		{
			const auth_require : Boolean = data.getValue(GameStateDataEnum.AUTH_REQUIRE);

			if (!auth_require)
			{
				if (!credentials.valid || !credentials.displayName || !credentials.userId || !credentials.sessionKey)
				{
					logger.info("AccountInfoState skipping due to lack of credentials");
					phase = StatePhase.COMPLETED;
					return;
				}
			}

			action = new AccountInfoTxn(actionHandler, gameFsm.config);
			action.send(communicator);
		}

		private function actionHandler(rhs : AccountInfoTxn) : void
		{
			if (rhs != action)
			{
				return;
			}

			if (!rhs.success)
			{
				phase = StatePhase.FAILED;
				return;
			}
			// do it!
			phase = StatePhase.COMPLETED;
		}

	}
}
