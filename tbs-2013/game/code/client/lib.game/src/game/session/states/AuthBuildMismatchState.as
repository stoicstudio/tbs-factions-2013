package game.session.states
{
	import engine.core.fsm.Fsm;
	import engine.core.fsm.StateData;
	import engine.core.fsm.StatePhase;
	import engine.core.logging.ILogger;
	import engine.session.Credentials;

	import game.session.GameState;

	public class AuthBuildMismatchState extends GameState
	{
		public var buildNumber : String;

		public function AuthBuildMismatchState(_data : StateData, fsm : Fsm, logger : ILogger)
		{
			super(_data, fsm, logger);
		}

		override protected function handleCleanup() : void
		{
		}

		override protected function handleEnteredState() : void
		{
			buildNumber = data.getValue(GameStateDataEnum.BUILD_NUMBER);
		}

		public function set overrideBuildNumber(value : Boolean) : void
		{
			if (value)
			{
				phase = StatePhase.COMPLETED;
			}
			else
			{
				config.context.appInfo.terminateError("Build Number Mismatch");
			}
		}
	}
}
