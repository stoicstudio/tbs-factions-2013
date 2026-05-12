package game.session.states
{
	import flash.events.Event;

	import engine.core.fsm.Fsm;
	import engine.core.fsm.StateData;
	import engine.core.fsm.StatePhase;
	import engine.core.logging.ILogger;

	import game.cfg.GameConfig;
	import game.session.GameState;

	public class SagaState extends GameState
	{
		public function SagaState(_data : StateData, fsm : Fsm, logger : ILogger)
		{
			super(_data, fsm, logger);
		}

		override protected function handleEnteredState() : void
		{
			config.addEventListener(GameConfig.EVENT_SAGA, sagaHandler);
			var url : String = data.getValue(GameStateDataEnum.SAGA_URL);
			var happening : String = data.getValue(GameStateDataEnum.HAPPENING_ID);
			data.removeValue(GameStateDataEnum.HAPPENING_ID);
			config.loadSaga(url, happening);
		}

		private function sagaHandler(event : Event) : void
		{
			phase = StatePhase.COMPLETED;
		}

	}
}
