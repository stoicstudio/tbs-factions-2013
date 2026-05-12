package game.session.states.tutorial
{
	import engine.core.fsm.Fsm;
	import engine.core.fsm.StateData;
	import engine.core.fsm.StatePhase;
	import engine.core.logging.ILogger;
	
	import game.cfg.GameConfig;
	import game.session.GameState;

	public class TutorialStartState extends GameState
	{
		public function TutorialStartState(_data : StateData, fsm : Fsm, logger : ILogger)
		{
			super(_data, fsm, logger);
		}

		override protected function handleEnteredState() : void
		{
			staticSetup(config);
			phase = StatePhase.COMPLETED;
		}

		public static function staticSetup(config : GameConfig) : void
		{
			config.stashed_account_info = config.accountInfo;
			config.accountInfo = config.generateStartingRoster(true);
			config.alerts.enabled = false;
		}
	}
}
