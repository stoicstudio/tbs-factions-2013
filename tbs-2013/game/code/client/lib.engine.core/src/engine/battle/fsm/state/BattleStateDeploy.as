package engine.battle.fsm.state
{
	import flash.errors.IllegalOperationError;
	import flash.events.TimerEvent;
	import flash.utils.Dictionary;

	import engine.battle.board.model.BattlePartyType;
	import engine.battle.board.model.IBattleBoard;
	import engine.battle.board.model.IBattleEntity;
	import engine.battle.fsm.BattleFsm;
	import engine.battle.fsm.txn.BattleTxnDeploySend;
	import engine.battle.sim.BattlePartyEvent;
	import engine.battle.sim.IBattleParty;
	import engine.core.fsm.StateData;
	import engine.core.fsm.StatePhase;
	import engine.core.logging.ILogger;
	import engine.tile.TileLocationVars;
	import engine.tile.def.TileLocation;

	import tbs.srv.battle.data.client.BattleDeployData;

	public class BattleStateDeploy extends BaseBattleState
	{
		private var txnSends : Dictionary = new Dictionary;
		private var txnSendsCount : int = 0;
		private var txnSendsResponseCount : int = 0;
		private var localCount : int = 0;
		private var remoteCount : int = 0;

		private var deployments : Vector.<Vector.<TileLocation>> = new Vector.<Vector.<TileLocation>>;

		public function BattleStateDeploy(_data : StateData, fsm : BattleFsm, logger : ILogger)
		{
			super(_data, fsm, logger, fsm.config.deployTimeoutMs);
		}

		override protected function handleEnteredState() : void
		{
			battleFsm.stopEatingSubsequent("tbs.srv.battle.data.client.BattleDeployData");

			var board : IBattleBoard = battleFsm.board;

			for (var i : int = 0; i < board.numParties; ++i)
			{
				var party : IBattleParty = board.getParty(i);
				party.addEventListener(BattlePartyEvent.DEPLOYED, partyDeployedHandler);

				if (party.type == BattlePartyType.LOCAL)
				{
					++localCount;
					// preliminary deployment of local parties
					if (!party.deployed)
					{
						board.autoDeployPartyById(party.id);
						deployments.push(null);
					}
					else
					{
						deployments.push(new Vector.<TileLocation>());
					}
				}
				else if (party.type == BattlePartyType.REMOTE)
				{
					deployments.push(null);
					++remoteCount;
				}
			}

			timeoutMs = battleFsm.config.deployTimeoutMs;

			super.handleEnteredState();

			sendLocalDeployments();
		}

		override protected function handleCleanup() : void
		{
			super.handleCleanup();
			battleFsm.eatAllSubsequent("tbs.srv.battle.data.client.BattleDeployData");
		}

		override protected function timeoutTimerCompleteHandler(event : TimerEvent) : void
		{
			logger.info("BattleStateDeploy force timeout deploy");
			var board : IBattleBoard = battleFsm.board;

			for (var i : int = 0; i < board.numParties; ++i)
			{
				var party : IBattleParty = board.getParty(i);

				if (party.type == BattlePartyType.LOCAL)
				{
					board.autoDeployPartyById(party.id);
					party.deployed = true;
				}
			}
		}

		protected function partyDeployedHandler(event : BattlePartyEvent) : void
		{
			var party : IBattleParty = event.party;

			if (party.type == BattlePartyType.LOCAL)
			{
				sendLocalDeployment(party);
			}
		}

		private function sendLocalDeployments() : void
		{
			var board : IBattleBoard = (fsm as BattleFsm).board;

			for (var i : int = 0; i < board.numParties; ++i)
			{
				var party : IBattleParty = board.getParty(i);
				if (party.type == BattlePartyType.LOCAL && party.deployed)
				{
					sendLocalDeployment(party);
				}
			}
		}

		private function sendLocalDeployment(party : IBattleParty) : void
		{
			if (party.type == BattlePartyType.LOCAL && party.deployed)
			{
				if (party in txnSends)
				{
					throw new IllegalOperationError("Try to send again?  no.");
				}

				isLocalDeployed = true;
				if (battleFsm.isOnline)
				{
					logger.info("SENDING DEPLOYMENT for " + battleFsm.session.credentials.userId + ", index " + battleFsm.localBattleOrder + ", party=" + party);

					var txnSend : BattleTxnDeploySend = new BattleTxnDeploySend(battleFsm.battleId, battleFsm.localBattleOrder, party, battleFsm.session.credentials, sendHandler, battleFsm, logger);
					addTxn(txnSend);
					txnSends[party] = txnSend;
					txnSend.send(battleFsm.session.communicator);
				}
				else
				{
					txnSends[party] = null;
					// fake response because there is no need to send our deployments unless there are remotes
					++txnSendsResponseCount;
				}

				checkDeploymentComplete();
			}
		}

		private function sendHandler(txn : BattleTxnDeploySend) : void
		{
			checkDeploymentComplete();
//			fetchWithDelay(0);
		}

		public var isLocalDeployed : Boolean;

		public function get isRemoteWaiting() : Boolean
		{
			return isLocalDeployed && remoteCount;
		}

//		private function fetchHandler(txn : BattleTxnGet) : void
//		{
//			fetchWithDelay(500);
//		}

		public function autoDeployLocal() : void
		{
			// deploy all local parties

			for (var i : int = 0; i < battleFsm.board.numParties; ++i)
			{
				var party : IBattleParty = battleFsm.board.getParty(i);

				if (party.type == BattlePartyType.LOCAL)
				{
					battleFsm.board.autoDeployPartyById(party.id);

					for (var j : int = 0; j < party.numMembers; ++j)
					{
						var m : IBattleEntity = party.getMember(j);
						// HACK they might not be actually ready
						m.deploymentReady = true;
					}

					party.deployed = true;
				}
			}

			checkDeploymentComplete();
		}

		override public function handleMessage(msg : Object) : Boolean
		{
			if (msg["class"] == "tbs.srv.battle.data.client.BattleDeployData")
			{
				var bdd : BattleDeployData = new BattleDeployData;
				bdd.parseJson(msg, logger);

				var tiles : Vector.<TileLocation> = new Vector.<TileLocation>;
				for each (var locv : Object in bdd.tiles)
				{
					var loc : TileLocation = TileLocationVars.parse(locv, logger);
					tiles.push(loc);
				}

				var party : IBattleParty = battleFsm.board.getPartyById(bdd.user_id.toString());

				if (party)
				{
					var index : int = battleFsm.board.getPartyIndex(party);
					logger.info("RECEIVED DEPLOYMENT for " + bdd);
					deployments[index] = tiles;
					checkDeploymentComplete();
				}
				return true;
			}

			logger.info("BattleStateDeploy can't handle " + msg ? msg["class"] : null);
			return false;
		}

		private function finishDeployment() : void
		{
			phase = StatePhase.COMPLETED;
		}

		private function checkDeploymentComplete() : Boolean
		{
			if (!isLocalDeployed)
			{
				return false;
			}

			var ok : Boolean = true;

			for (var i : int = 0; i < battleFsm.board.numParties; ++i)
			{
				var party : IBattleParty = battleFsm.board.getParty(i);
				if ((deployments.length - 1) < i)
				{
					finishDeployment();

					return true;
				}
				var deployment : Vector.<TileLocation> = deployments[i];

				if (deployment == null && !party.deployed)
				{
					ok = false;
					continue;
				}

				if (party.type != BattlePartyType.LOCAL && !party.deployed)
				{
					logger.info("DEPLOYING REMOTE " + i + ", party=" + party);
					for (var j : int = 0; j < party.numMembers; ++j)
					{
						var m : IBattleEntity = party.getMember(j);
						var tl : TileLocation = deployment[j];
						m.setPos(tl.x, tl.y);
						m.deploymentReady = true;
					}

					party.deployed = true;
				}
			}

			if (ok)
			{
				finishDeployment();

				return true;
			}

			return false;
		}

	}
}
