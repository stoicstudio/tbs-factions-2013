package engine.battle.fsm.state.turn.cmd
{
	import engine.battle.ability.model.BattleAbility;
	import engine.battle.fsm.state.BattleStateTurnBase;
	import engine.battle.fsm.txn.BattleTxnActionSend;

	public class BattleTurnCmdAction extends BattleTurnCmd
	{
		public var action : BattleAbility;
		public var terminator : Boolean;

		public function BattleTurnCmdAction(tb : BattleStateTurnBase, sequence : int, requiresSequence : Boolean, action : BattleAbility, terminator : Boolean)
		{
			super(tb, sequence, requiresSequence);
			this.action = action;
			this.terminator = terminator;

			if (turn.entity.playerControlled)
			{
				// hurry up so we can execute this action
				turn.entity.mobility.fastForwardMove();
			}
		}

		override protected function handleBattleExecute() : void
		{
			if (turn.entity.playerControlled)
			{
				if (!action.checkCosts(true))
				{
					logger.error("Action cannot be completed due to checkCosts: " + action);
					battleComplete();
					return;
				}

				if (battleFsm.isOnline)
				{
					const txn : BattleTxnActionSend = new BattleTxnActionSend(battleFsm.battleId, turn.number, action, ordinal, terminator, battleFsm.session.credentials, null, battleFsm, logger);
					txn.send(battleFsm.session.communicator);
				}
			}

			if (terminator)
			{
				if (turn.ability && (turn.ability.executed || turn.ability.executing))
				{
					logger.error("Attempting to re-terminate with: " + action);
					battleComplete();
					return;
				}
				turn.ability = action;
				turn.committed = true;
			}

			action.execute(null);
			battleComplete();
		}

		override protected function handleBattleCompleting() : void
		{
			if (terminator)
			{
				state.turnCompleting();
			}
		}

		override protected function handleBattleCompleted() : void
		{
			if (terminator)
			{
				state.turnCompleted();
			}
		}
	}
}
