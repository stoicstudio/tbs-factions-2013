package game.session.states
{
	import engine.core.fsm.Fsm;
	import engine.core.fsm.State;
	import engine.core.fsm.StateData;
	import engine.core.logging.ILogger;
	import engine.entity.def.IEntityDef;

	import game.gui.page.GuiMeadHouseConfig;
	import game.session.GameState;

	public class MeadHouseState extends GameState
	{
		public var guiConfig : GuiMeadHouseConfig = new GuiMeadHouseConfig;

		public function MeadHouseState(_data : StateData, fsm : Fsm, logger : ILogger)
		{
			super(_data, fsm, logger);
		}

		override protected function handleEnteredState() : void
		{
			gameFsm.updateGameLocation("loc_mead_house");
		}

		public function handleHired(e : IEntityDef) : void
		{

		}

		public function handleGoToProvingGrounds() : void
		{
			var current : State = config.fsm.current;
			config.fsm.transitionTo(ProvingGroundsState, current.data);
		}

	}
}
