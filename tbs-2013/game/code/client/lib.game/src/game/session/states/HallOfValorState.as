package game.session.states
{
	import engine.core.fsm.Fsm;
	import engine.core.fsm.StateData;
	import engine.core.logging.ILogger;

	import game.session.GameState;

	public class HallOfValorState extends GameState
	{
		public function HallOfValorState(_data : StateData, fsm : Fsm, logger : ILogger)
		{
			super(_data, fsm, logger);
		}
		
		override protected function handleEnteredState() : void
		{
			gameFsm.updateGameLocation("loc_hall_of_valor");
		}
	}
}
