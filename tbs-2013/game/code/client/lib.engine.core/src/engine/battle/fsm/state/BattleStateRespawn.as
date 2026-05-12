package engine.battle.fsm.state
{
	import engine.battle.board.model.BattleBoard;
	import engine.battle.board.model.IBattleEntity;
	import engine.battle.fsm.BattleFsm;
	import engine.battle.fsm.BattleStateDataEnum;
	import engine.battle.sim.IBattleParty;
	import engine.core.fsm.StateData;
	import engine.core.fsm.StatePhase;
	import engine.core.logging.ILogger;

	public class BattleStateRespawn extends BaseBattleState
	{
		public function BattleStateRespawn(_data : StateData, fsm : BattleFsm, logger : ILogger)
		{
			super(_data, fsm, logger);
		}

		override protected function handleEnteredState() : void
		{
			super.handleEnteredState();

			// local party is already spawned and added to the thing

			data.removeValue(BattleStateDataEnum.FINISHED);
			
			var board : BattleBoard = battleFsm.board as BattleBoard;
			board.boardSetup = false;

			board.spawn("bucket_respawn", "bucket_respawn");

			for each (var p : IBattleParty in board.parties)
			{
				if (p.isPlayer)
				{
					continue;
				}
				battleFsm.order.removeParty(p);
				battleFsm.order.addParty(p);

				for (var i : int = 0; i < p.numMembers; ++i)
				{
					var e : IBattleEntity = p.getMember(i);
					if (battleFsm.participants.indexOf(e) < 0)
					{
						battleFsm.participants.push(e);
					}
				}
			}

			battleFsm.order.reset();

//			if (battleFsm.participants.length <= 0)
//			{
//				battleFsm.addErrorMsg("No eligible party members for battle");
//				phase = StatePhase.FAILED;
//				return;
//			}

			phase = StatePhase.COMPLETED;

			board.boardSetup = true;
		}
	}
}
