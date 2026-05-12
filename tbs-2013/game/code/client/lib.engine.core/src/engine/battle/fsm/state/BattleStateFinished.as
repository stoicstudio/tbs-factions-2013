package engine.battle.fsm.state
{
	import engine.battle.fsm.BattleFinishedData;
	import engine.battle.fsm.BattleFsm;
	import engine.battle.fsm.BattleRenownAwardType;
	import engine.battle.fsm.BattleStateDataEnum;
	import engine.core.fsm.StateData;
	import engine.core.logging.ILogger;
	import engine.core.util.Enum;

	public class BattleStateFinished extends BaseBattleState
	{
		public var finishedData : BattleFinishedData;

		public function BattleStateFinished(_data : StateData, fsm : BattleFsm, logger : ILogger)
		{
			super(_data, fsm, logger);
		}

		override protected function handleEnteredState() : void
		{
			finishedData = data.getValue(BattleStateDataEnum.FINISHED);
			if (!finishedData)
			{
				logger.info("BattleStateFinished finished but no finishedData!");
			}
			else
			{
				const total_renown : int = finishedData.getReward(battleFsm.localBattleOrder).total_renown;
				logger.info("BattleStateFinished victoriousTeam=" + finishedData.victoriousTeam + ", total_renown=" + total_renown);

				for each (var type : BattleRenownAwardType in Enum.getVector(BattleRenownAwardType))
				{
					const a : int = finishedData.getAward(battleFsm.localBattleOrder, type);
					if (a != 0)
					{
						logger.info("-----> AWARD " + type + " " + a);
					}
				}
			}
		}
	}
}
