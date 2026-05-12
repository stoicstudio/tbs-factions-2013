package engine.battle.fsm.state
{
	import engine.battle.ability.def.BattleAbilityDef;
	import engine.battle.ability.model.BattleAbility;
	import engine.battle.fsm.BattleFsm;
	import engine.battle.fsm.state.turn.cmd.BattleTurnCmdAction;
	import engine.core.fsm.StateData;
	import engine.core.logging.ILogger;

	public class BattleStateTurnLocalBase extends BattleStateTurnBase
	{
		public function BattleStateTurnLocalBase(_data : StateData, fsm : BattleFsm, logger : ILogger, autoOrdering:Boolean)
		{
			super(_data, fsm, logger, autoOrdering);
		}

		public var skipped : Boolean;

		public function skip() : void
		{
			logger.debug("BattleStateTurnLocal.skip");

			if (turn.ability && (turn.ability.executing || turn.ability.executed))
			{
				logger.debug("BattleStateTurnLocal.skip IGNORE, already ability executing/ed");
				return;
			}

			if (skipped)
			{
				logger.debug("BattleStateTurnLocal.skip already skipped");
				return;
			}

			skipped = true;

			const abl_end : BattleAbilityDef = turn.entity.board.abilityManager.factory.fetchBattleAbilityDef("abl_end");
			const action : BattleAbility = new BattleAbility(turn.entity, abl_end, turn.entity.board.abilityManager);

			cmdSeq.addCmd(new BattleTurnCmdAction(this, 0, true, action, true));
		}

	}
}
