package game.session.states
{
	import engine.core.fsm.Fsm;
	import engine.core.fsm.StateData;
	import engine.core.logging.ILogger;

	import game.session.GameState;

	public class MainMenuState extends GameState
	{
		public function MainMenuState(_data : StateData, fsm : Fsm, logger : ILogger)
		{
			super(_data, fsm, logger);

			// TODO the main menu state may receive data from previous states that neads cleanup. 
			// for instance scene or other loaders
		}
	}
}
