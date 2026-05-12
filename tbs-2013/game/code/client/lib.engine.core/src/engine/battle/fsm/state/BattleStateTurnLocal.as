package engine.battle.fsm.state
{
	import flash.events.TimerEvent;

	import engine.battle.ability.model.BattleAbility;
	import engine.battle.fsm.BattleFsm;
	import engine.battle.fsm.BattleMoveEvent;
	import engine.battle.fsm.BattleTurnEvent;
	import engine.battle.fsm.state.turn.cmd.BattleTurnCmdAction;
	import engine.battle.fsm.state.turn.cmd.BattleTurnCmdMove;
	import engine.core.fsm.StateData;
	import engine.core.logging.ILogger;

	public class BattleStateTurnLocal extends BattleStateTurnLocalBase
	{
		public function BattleStateTurnLocal(_data : StateData, fsm : BattleFsm, logger : ILogger)
		{
			super(_data, fsm, logger, true);
		}

		override protected function handleEnteredState() : void
		{
			turn.entity.playGoAnimation();
			turn.move.addEventListener(BattleMoveEvent.COMMITTED, moveCommittedHandler);
			turn.addEventListener(BattleTurnEvent.COMMITTED, turnCommittedHandler);

			super.handleEnteredState();
		}

		private function turnCommittedHandler(event : BattleTurnEvent) : void
		{
			turn.removeEventListener(BattleTurnEvent.COMMITTED, turnCommittedHandler);

			if (turn.suspended)
			{
				// something else is responsible for us now!
				return;
			}

			if (turn.ability)
			{
				cmdSeq.addCmd(new BattleTurnCmdAction(this, 0, true, turn.ability, true));
			}
			else
			{
				skip();
			}
		}

		private function moveCommittedHandler(event : BattleMoveEvent) : void
		{
			turn.move.removeEventListener(BattleMoveEvent.COMMITTED, moveCommittedHandler);
			cmdSeq.addCmd(new BattleTurnCmdMove(this, 0, true, turn.move));
		}

		override protected function handleCleanup() : void
		{
			turn.move.removeEventListener(BattleMoveEvent.COMMITTED, moveCommittedHandler);
			turn.removeEventListener(BattleTurnEvent.COMMITTED, turnCommittedHandler);

			super.handleCleanup();
		}

		override public function skip() : void
		{
			turn.move.removeEventListener(BattleMoveEvent.COMMITTED, moveCommittedHandler);
			turn.removeEventListener(BattleTurnEvent.COMMITTED, turnCommittedHandler);

			super.skip();

		}

		override protected function timeoutTimerCompleteHandler(event : TimerEvent) : void
		{
			logger.info("BattleStateTurnLocal Timed out");
			skip();
		}

		public function performAction(action : BattleAbility) : void
		{
			// not terminating
			cmdSeq.addCmd(new BattleTurnCmdAction(this, 0, true, action, false));
		}
	}
}
