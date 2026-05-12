package engine.battle.fsm.state
{
	import engine.battle.fsm.BattleFsm;
	import engine.core.fsm.StateData;
	import engine.core.logging.ILogger;

	public class BattleStateError extends BaseBattleState
	{

		public var message : String = "";

		public function BattleStateError(_data : StateData, fsm : BattleFsm, logger : ILogger)
		{
			super(_data, fsm, logger);
		}

		override protected function handleEnteredState() : void
		{
			super.handleEnteredState();

			for each (var msg : String in battleFsm.errors)
			{
				logger.error("BattleStateError: " + msg);
				message += msg + "\n";
			}

			// tell the server that we errored out

			battleFsm.exitBattle();
		}
	}
}
