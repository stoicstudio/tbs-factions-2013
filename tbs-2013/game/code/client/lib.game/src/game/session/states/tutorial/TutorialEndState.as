package game.session.states.tutorial
{
	import engine.core.fsm.Fsm;
	import engine.core.fsm.StateData;
	import engine.core.fsm.StatePhase;
	import engine.core.logging.ILogger;

	import game.session.GameState;
	import game.session.actions.TutorialCompletedTxn;

	public class TutorialEndState extends GameState
	{

		public function TutorialEndState(_data : StateData, fsm : Fsm, logger : ILogger)
		{
			super(_data, fsm, logger);
		}

		override protected function handleEnteredState() : void
		{
			logger.info("TutorialEndState DONE");

			if (config.stashed_account_info)
			{
				config.accountInfo = config.stashed_account_info;
				config.stashed_account_info = null;
			}

			config.accountInfo.completed_tutorial = true;

			const txn : TutorialCompletedTxn = new TutorialCompletedTxn(config.fsm.credentials, null, config.logger);
			txn.send(config.fsm.communicator);

			phase = StatePhase.COMPLETED;
		}
	}
}
