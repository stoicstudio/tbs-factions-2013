package game.session.states
{
	import engine.core.fsm.Fsm;
	import engine.core.fsm.StateData;
	import engine.core.logging.ILogger;
	import engine.scene.model.SceneEvent;

	public class MapCampState extends SceneState
	{
		public function MapCampState(_data : StateData, fsm : Fsm, logger : ILogger)
		{
			super(_data, fsm, logger);

		}

		override protected function sceneExitHandler(event : SceneEvent) : void
		{
			// Supress superclass handling of town loading
			if (config.saga)
			{
				config.saga.triggerSceneExit(loader.url);
				return;
			}
		}

		override protected function handleEnteredState() : void
		{
			gameFsm.updateGameLocation("map_camp");

			super.handleEnteredState();
		}

		override public function handleLandscapeClick(name : String) : Boolean
		{
			if (super.handleLandscapeClick(name))
			{
				return true;
			}

			switch (name)
			{

			}

			return false;
		}
	}
}
