package game.session.states
{
	import engine.core.fsm.Fsm;
	import engine.core.fsm.StateData;
	import engine.core.logging.ILogger;

	public class VideoTutorial2State extends VideoState
	{
		public function VideoTutorial2State(_data : StateData, fsm : Fsm, logger : ILogger)
		{
			super(_data, fsm, logger);
		}

		override protected function handleEnteredState() : void
		{
			super.handleEnteredState();
			url = "common/video/tutorial_advanced.mp4";
		}

	}
}
