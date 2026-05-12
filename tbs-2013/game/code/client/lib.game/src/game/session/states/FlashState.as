package game.session.states
{
	import engine.core.fsm.Fsm;
	import engine.core.fsm.StateData;
	import engine.core.fsm.StatePhase;
	import engine.core.logging.ILogger;

	import game.session.GameState;

	public class FlashState extends GameState
	{
		public var url : String;
		public var time : Number;
		public var msg : String;

		public function FlashState(_data : StateData, fsm : Fsm, logger : ILogger)
		{
			super(_data, fsm, logger);
		}

		override protected function handleEnteredState() : void
		{
			url = data.getValue(GameStateDataEnum.FLASH_URL);
			time = data.getValue(GameStateDataEnum.FLASH_TIME);
			msg = data.getValue(GameStateDataEnum.FLASH_MSG);

			//config.soundConfig.ambienceEnabled = false;
		}

		public function handleFlashComplete() : void
		{
//			config.soundConfig.ambienceEnabled = config.globalPrefs.getPref(GameConfig.PREF_OPTION_SFX);

			phase = StatePhase.COMPLETED;

			if (config.saga)
			{
				config.saga.triggerFlashPageFinished(url);
			}
		}
	}
}
