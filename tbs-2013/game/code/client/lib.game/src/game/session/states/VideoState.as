package game.session.states
{
	import engine.core.fsm.Fsm;
	import engine.core.fsm.StateData;
	import engine.core.fsm.StatePhase;
	import engine.core.logging.ILogger;
	
	import game.cfg.GameConfig;
	import game.session.GameState;

	public class VideoState extends GameState
	{
		public var url : String;

		public function VideoState(_data : StateData, fsm : Fsm, logger : ILogger)
		{
			super(_data, fsm, logger);
		}

		override protected function handleEnteredState() : void
		{
			url = data.getValue(GameStateDataEnum.VIDEO_URL);

			config.soundSystem.ambienceEnabled = false;
		}

		public function handleVideoComplete() : void
		{
			config.soundSystem.ambienceEnabled = config.globalPrefs.getPref(GameConfig.PREF_OPTION_SFX);

			const ns : Class = data.getValue(GameStateDataEnum.VIDEO_NEXT_STATE);
			if (ns)
			{
				fsm.transitionTo(ns, data);
			}
			else
			{
				phase = StatePhase.COMPLETED;
			}
		}
	}
}
