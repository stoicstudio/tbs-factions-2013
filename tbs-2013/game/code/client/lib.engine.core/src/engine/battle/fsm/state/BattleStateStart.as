package engine.battle.fsm.state
{
	import engine.battle.board.model.IBattleBoard;
	import engine.battle.fsm.BattleFsm;
	import engine.battle.sim.IBattleParty;
	import engine.core.fsm.StateData;
	import engine.core.fsm.StatePhase;
	import engine.core.logging.ILogger;

	public class BattleStateStart extends BaseBattleState
	{
		public function BattleStateStart(_data : StateData, fsm : BattleFsm, logger : ILogger)
		{
			super(_data, fsm, logger);
		}

		override protected function handleEnteredState() : void
		{
			super.handleEnteredState();

			var board : IBattleBoard = battleFsm.board;
			var p : IBattleParty = board.getPartyById(battleFsm.config.startPartyId);
			if (!p)
			{
				battleFsm.addErrorMsg("Could not find start party: " + battleFsm.config.startPartyId);
				phase = StatePhase.FAILED;
				return;
			}

			battleFsm.order.addParty(p);

			for (var i : int = 0; i < board.numParties; ++i)
			{
				var t : IBattleParty = board.getParty(i);

				// TODO this won't necessarily preserve inter-team ordering if there are more than 2 teams!

				if (t != p)
				{
					battleFsm.order.addParty(t);
				}
			}

			battleFsm.order.getAllParticipants(battleFsm.participants);

			if (battleFsm.participants.length <= 0)
			{
				battleFsm.addErrorMsg("No eligible party members for battle");
				phase = StatePhase.FAILED;
				return;
			}

			phase = StatePhase.COMPLETED;

			board.boardSetup = true;
		}
	}
}
