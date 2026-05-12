package game.session.states.tutorial
{
	import engine.core.fsm.Fsm;
	import engine.core.fsm.StateData;
	import engine.core.logging.ILogger;

	import game.session.states.TownLoadState;

	public class TutorialTownLoadState extends TownLoadState
	{
		public function TutorialTownLoadState(_data : StateData, fsm : Fsm, logger : ILogger)
		{
			super(_data, fsm, logger);
		}

		override protected function handleEnteredState() : void
		{
			super.handleEnteredState();
		}

		override protected function handleCleanup() : void
		{
			super.handleCleanup();

		}
	}
}
