package engine.battle.fsm.state
{
	import flash.errors.IllegalOperationError;

	import engine.battle.board.model.BattlePartyType;
	import engine.battle.board.model.IBattleEntity;
	import engine.battle.fsm.BattleFsm;
	import engine.battle.fsm.BattleFsmConfig;
	import engine.battle.fsm.BattleTurn;
	import engine.battle.fsm.BattleTurnParty;
	import engine.battle.fsm.BattleTurnTeam;
	import engine.battle.fsm.txn.BattleTxnTurnInitSend;
	import engine.core.fsm.StateData;
	import engine.core.fsm.StatePhase;
	import engine.core.logging.ILogger;
	import engine.math.Hash;
	import engine.stat.def.StatType;
	import engine.stat.model.Stat;

	public class BattleStateNextTurn extends BaseBattleState
	{
		private var txnSend : BattleTxnTurnInitSend;
		private var turnNumber : int;
		private var hash : int;

		public function BattleStateNextTurn(_data : StateData, fsm : BattleFsm, logger : ILogger, timeoutMs : int = 0)
		{
			super(_data, fsm, logger, timeoutMs, 700);
			turnNumber = battleFsm.turn ? battleFsm.turn.number + 1 : 0;
		}

		private function initSendHandler(txn : BattleTxnTurnInitSend) : void
		{
			if (txn.success)
			{
				nextTurn();
			}
		}

		private function nextTurn() : void
		{
			// TODO battle turns should deal with the current team as well as the individuals who are current

			var current : IBattleEntity = battleFsm.order.aliveOrder[0];

			logger.debug("BattleStateNextTurn.nextTurn turn=" + turnNumber + " current=" + current);

			battleFsm.turn = new BattleTurn(current, turnNumber, hash, logger);

			var pt : BattlePartyType = current.party.type;
			switch (pt)
			{
				case BattlePartyType.LOCAL:
					fsm.transitionTo(BattleStateTurnLocal, data);
					break;
				case BattlePartyType.REMOTE:
					fsm.transitionTo(BattleStateTurnRemote, data);
					break;
				case BattlePartyType.AI:
					if (BattleFsmConfig.enableAi)
					{
						fsm.transitionTo(BattleStateTurnAi, data);
					}
					else
					{
						fsm.transitionTo(BattleStateTurnLocal, data);
					}
					break;
				default:
					throw new IllegalOperationError("not handled party type " + pt);
			}
		}

		public static const SYNC_STATS : Array = [
			StatType.STRENGTH,
			StatType.ARMOR,
			StatType.WILLPOWER,
			StatType.ARMOR_BREAK,
			StatType.STRENGTH_ATTACK,
			StatType.MIN_STRENGTH_ATTACK,
			StatType.PUNCTURE_ATTACK_BONUS,
			StatType.MALICE_ATTACK_BONUS,
			StatType.BRINGTHEPAIN_COUNTER_BONUS,
			StatType.EXERTION,
			StatType.RESIST_STRENGTH,
			StatType.RESIST_ARMOR,
			];

		private var hashStr : String;

		private function computeHashStr() : void
		{
			const ent : IBattleEntity = battleFsm.turn ? battleFsm.turn.entity : null;

			hashStr = "ending_turn=" + (turnNumber - 1) + " ending_entity=" + ent + " executedAbilityId=" + battleFsm.board.abilityManager.nextExecutedId + "\n";

			var i : int;
			var maxIdLen : int = 0;
			var entity : IBattleEntity = null;

			var btt : BattleTurnTeam;
			var btp : BattleTurnParty;

			var aliveMembers : Vector.<IBattleEntity> = battleFsm.order.getAliveParticipants(null);

			for each (entity in aliveMembers)
			{
				maxIdLen = Math.max(maxIdLen, entity.id.length);
			}

			var pad : String = "                         ";

			for each (entity in aliveMembers)
			{
				hashStr += "sync=" + battleFsm.battleId + " " + entity.id;
				var padSize : int = maxIdLen - entity.id.length;
				if (padSize > 0)
				{
					hashStr += pad.substr(0, padSize);
				}

				var ts : String = entity.tile.toString();
				hashStr += " tile=" + ts;
				padSize = 8 - ts.length;
				if (padSize > 0)
				{
					hashStr += pad.substr(0, padSize);
				}

				for each (var st : StatType in SYNC_STATS)
				{
					var stat : Stat = entity.stats.getStat(st, false);
					if (stat)
					{
						var ss : String = stat.value.toString();
						hashStr += "  " + stat.type.abbrev + "=" + ss;

						padSize = 3 - ss.length;
						if (padSize > 0)
						{
							hashStr += pad.substr(0, padSize);
						}
					}
				}

				hashStr += "\n";
			}
		}

		private function computeHash() : int
		{
			computeHashStr();

			hash = Hash.DJBHash(hashStr);

			logger.debug("Turn Hash: " + hash + "\n" + hashStr);

			return hash;
		}

		override protected function handleEnteredState() : void
		{
			super.handleEnteredState();

			// prune out the dead

			battleFsm.order.pruneDeadEntities();

			// check for enpillagement
			for each (var btt : BattleTurnTeam in battleFsm.order.turnTeams)
			{
				var pillage : Boolean = true;

				for each (var btp : BattleTurnParty in btt.turnParties)
				{
					if (btp.party.numMembers == 1 || btp.members.length > 1)
					{
						pillage = false;
						break;
					}
				}

				if (pillage)
				{
					battleFsm.order.commencePillaging();
					break;
				}
			}

			var c : IBattleEntity = battleFsm.order.next();

			if (!c)
			{
				battleFsm.addErrorMsg("Ragnarok Error");
				// nobody left on the board for some reason
				phase = StatePhase.FAILED;
				return;
			}

			if (battleFsm.order.numTeams == 1)
			{
				battleFsm.addErrorMsg("Nidhogg Error");
				// we should have already finished, something is up
				phase = StatePhase.FAILED;
				return;
			}

			if (battleFsm.isOnline)
			{
				computeHash();

				// TODO battle turns should deal with the current team as well as the individuals who are current
				txnSend = new BattleTxnTurnInitSend(battleFsm.battleId, turnNumber, hashStr, hash, c, battleFsm.session.credentials, initSendHandler, battleFsm, logger);
				addTxn(txnSend);
				txnSend.send(battleFsm.session.communicator, null, 0);
			}
			else
			{
				nextTurn();
			}
		}

	}
}
