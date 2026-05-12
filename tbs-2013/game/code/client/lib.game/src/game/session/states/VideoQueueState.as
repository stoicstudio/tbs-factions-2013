package game.session.states
{
	import engine.core.fsm.Fsm;
	import engine.core.fsm.StateData;
	import engine.core.fsm.StatePhase;
	import engine.core.logging.ILogger;

	import game.session.GameState;

	public class VideoQueueState extends GameState
	{
		public function VideoQueueState(_data : StateData, fsm : Fsm, logger : ILogger)
		{
			super(_data, fsm, logger);
		}

		override protected function handleEnteredState() : void
		{
			phase = StatePhase.COMPLETED;
		}

	}
}
