package game.session.states
{
	import engine.core.fsm.Fsm;
	import engine.core.fsm.StateData;
	import engine.core.logging.ILogger;

	import game.session.GameState;

	public class AuthFailedState extends GameState
	{
		public var message : String;

		public function AuthFailedState(_data : StateData, fsm : Fsm, logger : ILogger)
		{
			super(_data, fsm, logger);
		}

		override protected function handleCleanup() : void
		{
		}

		override protected function handleEnteredState() : void
		{
			message = data.getValue(GameStateDataEnum.SERVER_MESSAGE);

			config.fsm.current.data.setValue(GameStateDataEnum.SHOW_LOGIN_SCREEN, true);

		}

	}
}
