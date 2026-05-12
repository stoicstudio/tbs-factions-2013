package engine.battle.fsm.state
{
	import flash.errors.IllegalOperationError;

	import engine.battle.board.model.IBattleBoard;
	import engine.battle.board.model.IBattleEntity;
	import engine.battle.entity.model.BattleEntityEvent;
	import engine.battle.fsm.BattleFsm;
	import engine.battle.fsm.BattleStateDataEnum;
	import engine.battle.fsm.BattleTurn;
	import engine.battle.fsm.state.turn.cmd.TurnSeqCmds;
	import engine.battle.sim.IBattleParty;
	import engine.core.fsm.StateData;
	import engine.core.fsm.StatePhase;
	import engine.core.logging.ILogger;

	public class BattleStateTurnBase extends BaseBattleState
	{
		protected var _turn : BattleTurn;
		protected var _board : IBattleBoard;
		public var cmdSeq : TurnSeqCmds;
		private var _completing : Boolean;

		public function BattleStateTurnBase(_data : StateData, fsm : BattleFsm, logger : ILogger, autoOrdering : Boolean)
		{
			super(_data, fsm, logger, fsm.turn.timerSecs * 1000);
			this._board = battleFsm.board;
			this._turn = battleFsm.turn;
			this.cmdSeq = new TurnSeqCmds(autoOrdering);
		}

		override protected function handleEnteredState() : void
		{
			super.handleEnteredState();

			for each (var e : IBattleEntity in battleFsm.board.entities)
			{
				e.addEventListener(BattleEntityEvent.ALIVE, aliveHandler);
			}

			turn.entity.onStartTurn();
		}

		public function get entity() : IBattleEntity
		{
			return turn ? turn.entity : null;
		}

		override protected function handleCleanup() : void
		{
			cmdSeq.cleanup();
			cmdSeq = null;

			super.handleCleanup();

			for each (var e : IBattleEntity in battleFsm.board.entities)
			{
				e.removeEventListener(BattleEntityEvent.ALIVE, aliveHandler);
			}

			_board = null;
			_turn = null;
		}

		protected var readyToFinishBattle : Boolean;

//		battleFsm.transitionTo(BattleStateFinish, data);

		protected function aliveHandler(event : BattleEntityEvent) : void
		{
			if (phase != StatePhase.ENTERED)
			{
				//logger.debug("BattleStateTurnBase.aliveHandler() event.entity.alive=" + event.entity.alive + " ... aborting due to phase != StatePhase.ENTERED");
				return;
			}

			if (!event.entity.alive)
			{

				/*
				// potential fix for fg: 608. friendly kill doesn't trip off pillage on that turn
				this.pruneDeadEntities();
				if (this.shouldPillage() == true)
				{
					battleFsm.order.commencePillaging();
					battleFsm.order.dispatchEvent(new BattleTurnOrderEvent(BattleTurnOrderEvent.REFRESH_INITIATIVE));
				}
				*/

				// enemies get horn points

				const p : IBattleParty = event.entity.party;
				for (var i : int = 0; i < board.numParties; ++i)
				{
					const po : IBattleParty = board.getParty(i);
					if (p.team != po.team)
					{
						// the horn is growing
						++po.hornSize;
					}
				}

				var survivor : String = null;

				for each (var e : IBattleEntity in battleFsm.participants)
				{
					if (e.alive)
					{
						if (survivor != null && survivor != e.team)
						{
							// more than one survivor
							return;
						}
						survivor = e.team;
					}
				}

				logger.info("BattleStateTurnBase.aliveHandler VICTORIOUS_TEAM=" + survivor);

				data.setValue(BattleStateDataEnum.VICTORIOUS_TEAM, survivor);
				readyToFinishBattle = true;
			}
			else
			{
				throw new IllegalOperationError("We don't currently support resurrections.");
			}
		}

		protected function get turn() : BattleTurn
		{
			return _turn;
		}

		protected function get board() : IBattleBoard
		{
			return _board;
		}

		public function turnCompleting() : void
		{
			_completing = true;
			cmdSeq.completing();
		}

		public function turnCompleted() : void
		{
			entity.onEndTurn();

			if (readyToFinishBattle)
			{
				battleFsm.transitionTo(BattleStateFinish, data);
			}
			else
			{
				phase = StatePhase.COMPLETED;
			}
		}
	}
}
