package game.session.states
{
	import engine.core.fsm.Fsm;
	import engine.core.fsm.StateData;
	import engine.core.logging.ILogger;

	public class TownLoadState extends SceneLoadState
	{
		public function TownLoadState(_data : StateData, fsm : Fsm, logger : ILogger)
		{
			super(_data, fsm, logger);

			data.setValue(GameStateDataEnum.SCENELOADER_PRESERVE, true);
			data.setValue(GameStateDataEnum.SCENE_IS_TOWN, true);
			data.setValue(GameStateDataEnum.SCENE_URL, "common/town/strand/strand.json.z");
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
