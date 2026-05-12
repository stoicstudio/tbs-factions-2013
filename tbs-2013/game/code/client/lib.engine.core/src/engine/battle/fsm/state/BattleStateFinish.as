package engine.battle.fsm.state
{
	import flash.errors.IllegalOperationError;

	import engine.battle.fsm.BattleFinishedData;
	import engine.battle.fsm.BattleFsm;
	import engine.battle.fsm.BattleRenownAwardType;
	import engine.battle.fsm.BattleRewardData;
	import engine.battle.fsm.BattleStateDataEnum;
	import engine.battle.sim.IBattleParty;
	import engine.core.fsm.StateData;
	import engine.core.fsm.StatePhase;
	import engine.core.logging.ILogger;

	public class BattleStateFinish extends BaseBattleState
	{
		public var finishedData : BattleFinishedData;

		public function BattleStateFinish(_data : StateData, fsm : BattleFsm, logger : ILogger, timeoutMs : int = 0)
		{
			super(_data, fsm, logger, timeoutMs, 1000);
		}

		override protected function handleEnteredState() : void
		{
			super.handleEnteredState();

			battleFsm.battleFinished = true;

			doFinish();
		}

		override public function handleMessage(msg : Object) : Boolean
		{
			if (msg["class"] == "tbs.srv.battle.data.client.BattleFinishedData")
			{
				finishedData = new BattleFinishedData;
				finishedData.fromJson(msg);
				doFinish();
				return true;
			}

			return false;
		}

		private function doFinish() : void
		{
			if (phase != StatePhase.ENTERED)
			{
				return;
			}

			if (!battleFsm.isOnline)
			{
				if (finishedData)
				{
					throw new IllegalOperationError("Should not have finished data already");
				}

				finishedData = data.getValue(BattleStateDataEnum.FINISHED);

				if (!finishedData)
				{
					var victor : String = data.getValue(BattleStateDataEnum.VICTORIOUS_TEAM);
					finishedData = new BattleFinishedData;
					finishedData.victoriousTeam = victor;
					for (var i : int = 0; i < battleFsm.board.numParties; ++i)
					{
						var p : IBattleParty = battleFsm.board.getParty(i);
						var reward : BattleRewardData = new BattleRewardData;
						finishedData.rewards.push(reward);
						var kt : int = computePartyKillTotal(p);
						reward.awards[BattleRenownAwardType.KILLS] = kt;
						reward.total_renown += kt;

						if (p.team == victor)
						{
							reward.awards[BattleRenownAwardType.WIN] = 2;
							reward.total_renown += 2;
						}
					}
				}
			}

			if (finishedData)
			{
				data.setValue(BattleStateDataEnum.FINISHED, finishedData);
				phase = StatePhase.COMPLETED;
			}
		}

		private function computePartyKillTotal(p : IBattleParty) : int
		{
			var kt : int = 0;

			for (var j : int = 0; j < battleFsm.board.numParties; ++j)
			{

				var op : IBattleParty = battleFsm.board.getParty(j);
				if (op == p || op.team == p.team)
				{
					continue;
				}

				var kill_renown : int = op.numMembers - op.numAlive;
				kt += kill_renown;
			}

			return kt;
		}

	}
}
