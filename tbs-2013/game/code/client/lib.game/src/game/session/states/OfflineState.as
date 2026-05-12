package game.session.states
{
	import engine.core.fsm.Fsm;
	import engine.core.fsm.StateData;
	import engine.core.fsm.StatePhase;
	import engine.core.logging.ILogger;

	import game.session.GameState;

	public class OfflineState extends GameState
	{
		public function OfflineState(_data : StateData, fsm : Fsm, logger : ILogger)
		{
			super(_data, fsm, logger);
		}

		override protected function handleEnteredState() : void
		{
			config.createOfflineAccountInfo();
			credentials.offline = true;
			if (communicator)
			{
				communicator.connected = false;
			}
			config.fsm.session.communicator = null;
			phase = StatePhase.COMPLETED;
		}
	}
}
