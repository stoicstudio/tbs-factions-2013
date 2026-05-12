package game.session.states
{
	import engine.core.fsm.Fsm;
	import engine.core.fsm.StateData;
	import engine.core.logging.ILogger;
	import engine.saga.Saga;

	public class MapCampLoadState extends SceneLoadState
	{
		public function MapCampLoadState(_data : StateData, fsm : Fsm, logger : ILogger)
		{
			super(_data, fsm, logger);

			data.setValue(GameStateDataEnum.SCENELOADER_PRESERVE, true);
			data.setValue(GameStateDataEnum.SCENE_URL, Saga.MAP_CAMP_URL);
		}

	}
}
