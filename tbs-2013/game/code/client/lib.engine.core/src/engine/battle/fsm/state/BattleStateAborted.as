package engine.battle.fsm.state
{
	import engine.battle.fsm.BattleFsm;
	import engine.core.fsm.StateData;
	import engine.core.logging.ILogger;

	public class BattleStateAborted extends BaseBattleState
	{
		public function BattleStateAborted(_data : StateData, fsm : BattleFsm, logger : ILogger)
		{
			super(_data, fsm, logger);
		}
	}
}
