package engine.battle.fsm.state
{
	import com.greensock.TweenMax;

	import engine.battle.fsm.BattleFsm;
	import engine.battle.fsm.BattleMoveEvent;
	import engine.battle.fsm.aimodule.AiModuleBase;
	import engine.battle.fsm.aimodule.AiModuleDredge;
	import engine.core.fsm.StateData;
	import engine.core.fsm.StatePhase;
	import engine.core.logging.ILogger;

	public class BattleStateTurnAi extends BattleStateTurnLocalBase
	{
		protected var aiModule : AiModuleBase = null;

		public function BattleStateTurnAi(_data : StateData, fsm : BattleFsm, logger : ILogger)
		{

			super(_data, fsm, logger, true);

			// TODO: right now there is only Dredge AI
			aiModule = new AiModuleDredge(this);

		}

		override protected function handleEnteredState() : void
		{
			super.handleEnteredState();

			battleFsm.turn.move.addEventListener(BattleMoveEvent.EXECUTED, moveExecutedHandler);
			battleFsm.turn.move.addEventListener(BattleMoveEvent.INTERRUPTED, moveInterruptedHandler);

			TweenMax.delayedCall(0.5, aiModule.performMove);
			//aiModule.performMove();

		}

		override protected function handleCleanup() : void
		{
			super.handleCleanup();
			TweenMax.killDelayedCallsTo(aiModule.performMove);
			TweenMax.killDelayedCallsTo(aiModule.performAction);
			aiModule.cleanup();
		}

		private function moveExecutedHandler(event : BattleMoveEvent) : void
		{
			logger.debug("BattleStateTurnAI.moveExecutedHandler");

			TweenMax.delayedCall(0.5, aiModule.performAction);
			//aiModule.performAction();

//			phase = StatePhase.COMPLETED;

		}

		private function moveInterruptedHandler(event : BattleMoveEvent) : void
		{
			logger.debug("BattleStateTurnLocal.moveInterruptedHandler");

			// TODO let the server know that we interrupted the move
			// all remotes should have interrupted the same way, but this could be used for sanity checking

			// TODO this should not ACTUALLY COMPLETE until whatever side effects have occurred
			phase = StatePhase.COMPLETED;
		}
	}
}
