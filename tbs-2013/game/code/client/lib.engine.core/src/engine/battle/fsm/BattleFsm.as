package engine.battle.fsm
{
	import flash.errors.IllegalOperationError;
	import flash.events.Event;
	import flash.utils.Dictionary;

	import engine.battle.ability.def.BattleAbilityDef;
	import engine.battle.ability.model.BattleAbility;
	import engine.battle.ability.model.IBattleAbility;
	import engine.battle.board.BattleBoardEvent;
	import engine.battle.board.model.IBattleBoard;
	import engine.battle.board.model.IBattleEntity;
	import engine.battle.fsm.state.BattleStateAborted;
	import engine.battle.fsm.state.BattleStateDeploy;
	import engine.battle.fsm.state.BattleStateError;
	import engine.battle.fsm.state.BattleStateFinish;
	import engine.battle.fsm.state.BattleStateFinished;
	import engine.battle.fsm.state.BattleStateInit;
	import engine.battle.fsm.state.BattleStateNextTurn;
	import engine.battle.fsm.state.BattleStateRespawn;
	import engine.battle.fsm.state.BattleStateStart;
	import engine.battle.fsm.state.BattleStateSurrender;
	import engine.battle.fsm.state.BattleStateTurnAi;
	import engine.battle.fsm.state.BattleStateTurnLocal;
	import engine.battle.fsm.state.BattleStateTurnRemote;
	import engine.battle.fsm.txn.BattleTxnExitSend;
	import engine.battle.fsm.txn.BattleTxnKillSend;
	import engine.battle.fsm.txn.BattleTxnSurrenderSend;
	import engine.battle.sim.IBattleParty;
	import engine.core.cmd.CmdExec;
	import engine.core.fsm.Fsm;
	import engine.core.logging.ILogger;
	import engine.session.Chat;
	import engine.session.Session;
	import engine.stat.def.StatType;
	import engine.stat.model.Stat;

	import tbs.srv.battle.data.client.BaseBattleTurnData;
	import tbs.srv.battle.data.client.BattleAbortedData;
	import tbs.srv.battle.data.client.BattleCreateData;
	import tbs.srv.battle.data.client.BattleExitData;
	import tbs.srv.battle.data.client.BattleSurrenderData;
	import tbs.srv.battle.data.client.BattleSyncData;

	public class BattleFsm extends Fsm
	{
		public var session : Session;
		public var board : IBattleBoard;
		public var config : BattleFsmConfig;
		public var order : BattleTurnOrder;
		public var participants : Vector.<IBattleEntity> = new Vector.<IBattleEntity>;
		private var _turn : BattleTurn;
		private var _battleId : String;
		public var localBattleOrder : int;
		public var turns : Vector.<BattleTurn> = new Vector.<BattleTurn>;
		private var _isOnline : Boolean;
		public var battleFinished : Boolean;
		private var _interact : IBattleEntity;
		private var _ability : BattleAbility;
		public var chat : Chat;
		private var _parentFsm : Fsm;
		public var battleCreateData : BattleCreateData;
		public var unitsReadyToPromote : Vector.<String> = new Vector.<String>();
		private var surrendered : Boolean;
		public var kills : int;
		public var firstStrike : Boolean;

		public function BattleFsm(session : Session, board : IBattleBoard, logger : ILogger, config : BattleFsmConfig, battleCreateData : BattleCreateData, localBattleOrder : int, isOnline : Boolean, chat : Chat,
			parentFsm : Fsm)
		{
			super("BattleFsm", logger);

			this._isOnline = isOnline;
			this.battleCreateData = battleCreateData;

			if (battleCreateData != null)
			{
				this._battleId = battleCreateData.battle_id;
			}

			if (!_battleId && isOnline)
			{
				throw new ArgumentError("Invalid battleId for online battle.");
			}

			this.localBattleOrder = localBattleOrder;
			this.session = session;
			this.board = board;
			this.config = config;
			this.order = new BattleTurnOrder(logger);
			this.chat = chat;
			this._parentFsm = parentFsm;

			board.addEventListener(BattleBoardEvent.BOARD_ENTITY_KILLING_EFFECT, killingEffectHandler);
			board.addEventListener(BattleBoardEvent.BOARD_ENTITY_DAMAGED, entityDamagedHandler);

			logger.info("BattleFsm CTOR battleId=" + battleId + ", localBattleOrder=" + localBattleOrder);

			if (!_isOnline)
			{
				//config.turnTimeoutMs = 0;
				config.deployTimeoutMs = 0;
			}

			registerState(BattleStateRespawn);
			registerState(BattleStateDeploy);
			registerState(BattleStateFinish);
			registerState(BattleStateFinished);
			registerState(BattleStateStart);
			registerState(BattleStateError);
			registerState(BattleStateAborted);
			registerState(BattleStateNextTurn);
			registerState(BattleStateTurnAi);
			registerState(BattleStateTurnLocal);
			registerState(BattleStateTurnRemote);
			registerState(BattleStateSurrender);
			registerState(BattleStateInit);

			registerTransition(BattleStateTurnAi, BattleStateNextTurn, TRANS_COMPLETE);
			registerTransition(BattleStateTurnLocal, BattleStateNextTurn, TRANS_COMPLETE);
			registerTransition(BattleStateTurnRemote, BattleStateNextTurn, TRANS_COMPLETE);
//			registerTransition(BattleStateTurnLocal, BattleStateError, TRANS_FAILED);

			registerTransition(BattleStateDeploy, BattleStateStart, TRANS_COMPLETE);
			registerTransition(BattleStateStart, BattleStateNextTurn, TRANS_COMPLETE);
			registerTransition(BattleStateRespawn, BattleStateNextTurn, TRANS_COMPLETE);

			registerTransition(BattleStateSurrender, BattleStateFinish, TRANS_COMPLETE);
			registerTransition(BattleStateFinish, BattleStateFinished, TRANS_COMPLETE);

			registerTransition(BattleStateInit, BattleStateDeploy, TRANS_COMPLETE);

			registerTransition(null, BattleStateError, TRANS_FAILED);

			initialState = BattleStateInit;

			shell.add("turn", shellCmdFuncTurn);
			shell.add("ai", shellCmdFuncAi);

			surrendered = false;
		}

		private function entityDamagedHandler(event : BattleBoardEvent) : void
		{
			if (!firstStrike)
			{
				firstStrike = true;
				dispatchEvent(new BattleFsmEvent(BattleFsmEvent.FIRST_STRIKE));
			}
		}

		private function killingEffectHandler(event : BattleBoardEvent) : void
		{
			const entity : IBattleEntity = event.entity;

			if (!entity || !entity.killingEffect)
			{
				logger.error("killingEffectHandler with null entity=" + entity + " or null killingEffect");
				logger.error(new IllegalOperationError().getStackTrace());
				return;
			}

			const abl : IBattleAbility = entity.killingEffect.ability;
			const root : IBattleAbility = abl ? abl.root : null;
			const caster : IBattleEntity = root ? root.caster : null;

			if (!caster)
			{
				logger.error("killingEffectHandler with null caster, " + entity + " or null killingEffect");
			}

			if (isOnline)
			{
				const txn : BattleTxnKillSend = new BattleTxnKillSend(this, turn ? turn.number : -1, entity, caster, logger);
				txn.send(session.communicator);
			}

			++kills;
			dispatchEvent(new BattleFsmEvent(BattleFsmEvent.KILLS));
		}

		override protected function cleanup() : void
		{
			super.cleanup();

			board.removeEventListener(BattleBoardEvent.BOARD_ENTITY_DAMAGED, entityDamagedHandler);
			board.removeEventListener(BattleBoardEvent.BOARD_ENTITY_KILLING_EFFECT, killingEffectHandler);

			session.communicator.removePollTimeRequirement(this);

			if (!battleFinished)
			{
				if (isOnline)
				{
					// auto-exit which will trigger a surrender on the server
					const party : IBattleParty = board.getPartyById(session.credentials.userId.toString());
					if (!party.surrendered)
					{
						party.surrendered = true;
						new BattleTxnSurrenderSend(battleId, session.credentials, null, this, logger).send(session.communicator);
					}

					exitBattle();
				}
			}
		}

		override protected function handleCurrentChanged() : void
		{
			super.handleCurrentChanged();
			_parentFsm.popMessages();
			if (currentClass == BattleStateDeploy)
			{
				dispatchEvent(new BattleFsmEvent(BattleFsmEvent.DEPLOY));
			}
		}

		override public function handleOneMessage(msg : Object) : Boolean
		{

			if (!current)
			{
				return false;
			}

			if (msg.battle_id == undefined)
			{
				// we don't care about non-battle msgs
				return false;
			}

			if ((msg.battleId != undefined && msg.battleId != _battleId) ||
				(msg.battle_id != undefined && msg.battle_id != _battleId))
			{
				logger.debug("BattleFsm " + battleId + " SILENTLY EAT WRONG BATTLE " + JSON.stringify(msg));
				// just silently eat the message
				return true;
			}

			//logger.info("BattleFsm " + battleId + " HANDLE MSG " + (turn ? turn.number : -1) + " current " + currentClass + ": " + msg["class"] + ", battle_id=" + msg.battle_id + " " + JSON.stringify(msg));
			logger.debug("BattleFsm " + battleId + " HANDLE MSG " + (turn ? turn.number : -1) + " current " + currentClass + ": " + msg["class"] + ", battle_id=" + msg.battle_id);

			if (msg["class"] == "tbs.srv.battle.data.client.BattleSyncData")
			{
				var bsyncd : BattleSyncData = new BattleSyncData;
				bsyncd.parseJson(msg, logger);

				if (handleSync(bsyncd))
				{
					return true;
				}
			}
			else if (msg["class"] == "tbs.srv.battle.data.client.BattleAbortData")
			{
				var bad : BaseBattleTurnData = new BaseBattleTurnData;
				bad.parseJson(msg, logger);

				logger.info("BattleFsm GOT ABORT from " + bad);
				if (bad.battle_id)
				{
					const pabort : IBattleParty = board.getPartyById(bad.user_id.toString());
					if (pabort)
					{
						pabort.aborted = true;
					}
				}

				return true;

					// drop the user from the match, and try to keep going
			}
			else if (msg["class"] == "tbs.srv.battle.data.client.BattleAbortedData")
			{
				var baded : BattleAbortedData = new BattleAbortedData;
				baded.parseJson(msg, logger);
				logger.info("BattleFsm GOT ABORTED " + baded);
				transitionTo(BattleStateAborted, current.data);
				return true;
			}
			else if (msg["class"] == "tbs.srv.battle.data.client.BattleSurrenderData")
			{
				var bsd : BattleSurrenderData = new BattleSurrenderData;
				bsd.parseJson(msg, logger);

				const p : IBattleParty = board.getPartyById(bsd.user_id.toString());

				if (p.surrendered)
				{
					return true;
				}

				p.surrendered = true;

				logger.info("SURRENDERING " + p + " duly noted");

				// TODO in the case of a 2v2 should we keep the battle going?
				// hand off control of the surrendered party to the remaining party?

				var localp : IBattleParty = board.getPartyById(session.credentials.userId.toString());
				logger.info("BattleFsm.handleOneMsgInternal VICTORIOUS_TEAM=" + localp.team);

				current.data.setValue(BattleStateDataEnum.VICTORIOUS_TEAM, localp.team);

				transitionTo(BattleStateFinish, current.data);

				return true;
			}
			else if (msg["class"] == "tbs.srv.battle.data.client.BattleExitData")
			{
				var bed : BattleExitData = new BattleExitData;
				bed.parseJson(msg, logger);
				logger.info("BattleFsm GOT EXIT " + bed);

				const party : IBattleParty = board.getPartyById(bed.user_id.toString());
				dispatchEvent(new BattleFsmPlayerExitEvent(BattleFsmPlayerExitEvent.PLAYER_EXIT, bed.user_id, party.partyName));
				return true;
			}
			if (msg.turn != undefined)
			{
				var msg_turn : int = msg.turn;
				if (!turn || msg_turn > turn.number)
				{
					//logger.debug("BattleFsm DEFER FUTURISTIC " + JSON.stringify(msg));
					return false;
				}
				else if (msg_turn < turn.number)
				{
					logger.debug("BattleFsm SILENTLY EAT OLD TURN " + JSON.stringify(msg));
					// old message
					return true;
				}
			}

			if (!super.handleOneMessage(msg))
			{
				if (msg["class"] in _eatAllSubsequent)
				{
					logger.info("BattleFsm.handleOneMessage " + this + " eating subsequent " + JSON.stringify(msg));
					return true;
				}

				//logger.info("BattleFsm.handleOneMessage " + this + " fell through " + JSON.stringify(msg));
				return false;
			}

			return true;
		}

		private var _eatAllSubsequent : Dictionary = new Dictionary;

		public function eatAllSubsequent(clazz : String) : void
		{
			logger.debug("BattleStateInit.eatAllSubsequent " + clazz);
			_eatAllSubsequent[clazz] = true;
		}

		public function stopEatingSubsequent(clazz : String) : void
		{
			logger.debug("BattleStateInit.stopEatingSubsequent " + clazz);
			delete _eatAllSubsequent[clazz];
		}

		private function handleSync(bsd : BattleSyncData) : Boolean
		{
			if (currentClass == BattleStateError || currentClass == BattleStateAborted)
			{
				return false;
			}

			var n : int = bsd.turn;
			var h : int = bsd.hash;

			if (turns.length > n)
			{
				var h_local : int = turns[n].hash;

				if (h != h_local)
				{
					logger.error("BattleSyncData DIVERGENCE detected at turn " + n);
					errors.push("BattleSyncData DIVERGENCE detected at turn " + n);
					transitionTo(BattleStateError, current.data);
				}
				else
				{
					logger.debug("BattleSyncData SYNC OK turn " + n);
				}

				return true;
			}

			logger.debug("BattleSyncData SYNC WAIT turn " + n);

			return false;
		}

		override public function startFsm(data : Object) : void
		{
			if (data)
			{
				data.setValue(BattleStateDataEnum.VICTORIOUS_TEAM, null);
			}
			super.startFsm(data);

			if (isOnline)
			{
				session.communicator.setPollTimeRequirement(this, 1000);
			}
		}

		public function surrender() : void
		{
			if (!surrendered)
			{
				logger.info("BattleFsm.surrender");
				transitionTo(BattleStateSurrender, current.data);
				surrendered = true;
			}
		}

		public function get turn() : BattleTurn
		{
			return _turn;
		}

		public function set turn(value : BattleTurn) : void
		{
			if (_turn == value)
			{
				return;
			}

			if (value)
			{
				if (value.number != turns.length)
				{
					throw new IllegalOperationError("Attempt to set a turn with the wrong number: " + value.number + ", expected: " + turns.length);
				}
			}

			if (_turn)
			{
				_turn.removeEventListener(BattleTurnEvent.ABILITY, turnAbilityHandler);
				_turn.removeEventListener(BattleTurnEvent.ABILITY_EXECUTING, turnAbilityExecutingHandler);

				_turn.removeEventListener(BattleTurnEvent.ABILITY_TARGET, turnAbilityTargetHandler);
				_turn.removeEventListener(BattleTurnEvent.ATTACK_MODE, turnAttackModeHandler);
				_turn.removeEventListener(BattleTurnEvent.COMPLETE, turnCompleteHandler);
				_turn.removeEventListener(BattleTurnEvent.COMMITTED, turnCommittedHandler);
				_turn.removeEventListener(BattleTurnEvent.IN_RANGE, turnInRangeHandler);

				_turn.move.removeEventListener(BattleMoveEvent.COMMITTED, moveCommittedHandler);
				_turn.move.removeEventListener(BattleMoveEvent.EXECUTED, moveExecutedHandler);
			}

			_turn = value;

			if (_turn)
			{
				turns.push(_turn);

				_turn.addEventListener(BattleTurnEvent.ABILITY, turnAbilityHandler);
				_turn.addEventListener(BattleTurnEvent.ABILITY_EXECUTING, turnAbilityExecutingHandler);

				_turn.addEventListener(BattleTurnEvent.ABILITY_TARGET, turnAbilityTargetHandler);
				_turn.addEventListener(BattleTurnEvent.ATTACK_MODE, turnAttackModeHandler);
				_turn.addEventListener(BattleTurnEvent.COMPLETE, turnCompleteHandler);
				_turn.addEventListener(BattleTurnEvent.COMMITTED, turnCommittedHandler);
				_turn.addEventListener(BattleTurnEvent.IN_RANGE, turnInRangeHandler);

				_turn.move.addEventListener(BattleMoveEvent.COMMITTED, moveCommittedHandler);
				_turn.move.addEventListener(BattleMoveEvent.EXECUTED, moveExecutedHandler);

				// drop the interact when we go to the next turn
				_interact = null;
			}

			ability = _turn ? _turn.ability : null;

			logger.info("BattleFsm turnNumber=" + (_turn ? _turn.number : -1));

			dispatchEvent(new BattleFsmEvent(BattleFsmEvent.TURN));
		}

		private function turnAbilityExecutingHandler(event : BattleTurnEvent) : void
		{
			dispatchEvent(new BattleFsmEvent(BattleFsmEvent.TURN_ABILITY_EXECUTING));
		}

		private function moveExecutedHandler(event : BattleMoveEvent) : void
		{
			dispatchEvent(new BattleFsmEvent(BattleFsmEvent.TURN_MOVE_EXECUTED));
		}

		private function moveCommittedHandler(event : BattleMoveEvent) : void
		{
			dispatchEvent(new BattleFsmEvent(BattleFsmEvent.TURN_MOVE_COMMITTED));
		}

		private function turnAbilityTargetHandler(event : BattleTurnEvent) : void
		{
			dispatchEvent(new BattleFsmEvent(BattleFsmEvent.TURN_ABILITY_TARGETS));
		}

		private function turnAttackModeHandler(event : BattleTurnEvent) : void
		{
			dispatchEvent(new BattleFsmEvent(BattleFsmEvent.TURN_ATTACK));
		}

		private function turnAbilityHandler(event : BattleTurnEvent) : void
		{
			ability = _turn ? _turn.ability : null;
			dispatchEvent(new BattleFsmEvent(BattleFsmEvent.TURN_ABILITY));
		}

		private function turnCompleteHandler(event : BattleTurnEvent) : void
		{
			dispatchEvent(new BattleFsmEvent(BattleFsmEvent.TURN_COMPLETE));
		}

		private function turnCommittedHandler(event : BattleTurnEvent) : void
		{
			dispatchEvent(new BattleFsmEvent(BattleFsmEvent.TURN_COMMITTED));
		}

		private function turnInRangeHandler(event : BattleTurnEvent) : void
		{
			dispatchEvent(new BattleFsmEvent(BattleFsmEvent.TURN_IN_RANGE));
		}

		public function get isOnline() : Boolean
		{
			return _isOnline;
		}

		public function get interact() : IBattleEntity
		{
			return _interact;
		}

		public function set interact(value : IBattleEntity) : void
		{
			setInteractNoEvent(value);
			dispatchEvent(new BattleFsmEvent(BattleFsmEvent.INTERACT));
		}

		public function setInteractNoEvent(value : IBattleEntity) : void
		{
			if (turn)
			{
				if (!turn.committed)
				{
					turn.setTurnInteract(value);
				}
			}

			if (_interact != value)
			{
				_interact = value;
			}
		}

		private function shellCmdFuncTurn(c : CmdExec) : void
		{
			var array : Array = c.param;

			if (turn)
			{
				turn.shell.execArgv(array.slice(1));
			}
			else
			{
				logger.info("No turn");
			}
		}

		private function shellCmdFuncAi(c : CmdExec) : void
		{
			BattleFsmConfig.enableAi = !BattleFsmConfig.enableAi;
			logger.info("BattleFsmConfig.enableAi = " + BattleFsmConfig.enableAi);
		}

		public function get ability() : BattleAbility
		{
			return _ability;
		}

		public function set ability(value : BattleAbility) : void
		{
			if (_ability == value)
			{
				return;
			}

			if (_ability)
			{
				_ability.targetSet.removeEventListener(Event.CHANGE, abilityTargetHandler);
			}

			_ability = value;

			if (_ability)
			{
				_ability.targetSet.addEventListener(Event.CHANGE, abilityTargetHandler);
			}

		}

		private function abilityTargetHandler(event : Event) : void
		{
			dispatchEvent(new BattleFsmEvent(BattleFsmEvent.TURN_ABILITY_TARGETS));
		}

		public function get battleId() : String
		{
			return _battleId;
		}

		private var exited : Boolean;

		public function exitBattle() : void
		{
			if (!exited)
			{
				exited = true;

				if (isOnline)
				{
					const txn : BattleTxnExitSend = new BattleTxnExitSend(battleId, session.credentials, null, this, logger);
					txn.send(session.communicator);
				}
			}
		}

		public function respawnBattle() : void
		{
			battleFinished = false;
			transitionTo(BattleStateRespawn, current.data);
			dispatchEvent(new BattleFsmEvent(BattleFsmEvent.BATTLE_RESPAWN));
		}

		public function killall() : void
		{
			if (isOnline)
			{
				return;
			}

			if (!board.boardSetup)
			{
				return;
			}

			for (var i : int = 0; i < board.numParties; ++i)
			{
				var p : IBattleParty = board.getParty(i);
				if (p.isPlayer)
				{
					continue;
				}
				for (var j : int = 0; j < p.numMembers; ++j)
				{
					var e : IBattleEntity = p.getMember(j);
					if (e.alive)
					{
						var str : Stat = e.stats.getStat(StatType.STRENGTH);
						str.setValue(0);
					}
				}
			}
		}

		public function killTarget() : void
		{
			if (isOnline)
			{
				return;
			}

			if (!board.boardSetup)
			{
				return;
			}

			if (!turn || !turn.entity || !turn.turnInteract)
			{
				return;
			}

			var def : BattleAbilityDef = _turn.entity.board.abilityManager.factory.fetchBattleAbilityDef("abl_kill");
			var abl : BattleAbility = new BattleAbility(turn.entity, def, board.abilityManager);
			abl.targetSet.setTarget(turn.turnInteract);
			abl.execute(null);

		}
	}
}
