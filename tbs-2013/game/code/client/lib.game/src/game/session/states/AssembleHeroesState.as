package game.session.states
{
	import engine.core.fsm.Fsm;
	import engine.core.fsm.StateData;
	import engine.core.logging.ILogger;

	import game.gui.page.GuiProvingGroundsConfig;
	import game.session.GameState;

	public class AssembleHeroesState extends GameState
	{
		public static const EVENT_AUTO_NAME : String = "ProvingGroundsState.EVENT_AUTO_NAME";
		public static const EVENT_SHOW_CLASS : String = "ProvingGroundsState.EVENT_SHOW_CLASS";

		public var guiConfig : GuiProvingGroundsConfig = new GuiProvingGroundsConfig;

		public function AssembleHeroesState(_data : StateData, fsm : Fsm, logger : ILogger)
		{
			super(_data, fsm, logger);
		}

		override protected function handleEnteredState() : void
		{
			gameFsm.updateGameLocation("loc_assemble_heroes");

		}

		override protected function handleCleanup() : void
		{
			guiConfig.reset();
		}

	}
}
