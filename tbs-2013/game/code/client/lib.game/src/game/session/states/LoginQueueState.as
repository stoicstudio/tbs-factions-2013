package game.session.states
{
	import engine.core.fsm.Fsm;
	import engine.core.fsm.StateData;
	import engine.core.logging.ILogger;

	import game.session.GameState;

	public class LoginQueueState extends GameState
	{
		public function LoginQueueState(_data : StateData, fsm : Fsm, logger : ILogger)
		{
			super(_data, fsm, logger);
		}

		override protected function handleEnteredState() : void
		{
			gameFsm.updateGameLocation("loc_login_queue");
		}
	}
}
