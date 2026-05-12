package game.session.states
{
	import engine.core.fsm.Fsm;
	import engine.core.fsm.StateData;
	import engine.core.logging.ILogger;


	public class VideoTutorial1State extends VideoState
	{
		public function VideoTutorial1State(_data : StateData, fsm : Fsm, logger : ILogger)
		{
			super(_data, fsm, logger);
		}

		override protected function handleEnteredState() : void
		{
			super.handleEnteredState();
			url = "common/video/tutorial_basic.mp4";
		}

	}
}
