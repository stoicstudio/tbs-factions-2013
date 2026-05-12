package engine.battle.fsm
{
	import flash.errors.IllegalOperationError;
	import flash.events.EventDispatcher;

	import engine.battle.board.model.IBattleEntity;
	import engine.battle.sim.IBattleParty;
	import engine.core.logging.ILogger;

	public class BattleTurnOrder extends EventDispatcher
	{
		private var _index : int = -1;
		public var turnTeams : Vector.<BattleTurnTeam> = new Vector.<BattleTurnTeam>;
		public var _aliveOrder : Vector.<IBattleEntity> = new Vector.<IBattleEntity>;

		private var _numTeamsRemaining : int = 0;
		private var _dirty : Boolean = false;

		//public var rounds : int;
		private var logger : ILogger;

		public var currentTeam : BattleTurnTeam;

		private var _pillage : Boolean;

		public function BattleTurnOrder(logger : ILogger)
		{
			this.logger = logger;
		}

		public function get pillage() : Boolean
		{
			return _pillage;
		}

		public function reset() : void
		{
			_pillage = false;
			setDirty();
		}

		public function commencePillaging() : void
		{
			if (_pillage)
			{
				return;
			}

			checkDirty();

			if (_aliveOrder.length == 0)
			{
				throw new IllegalOperationError("must have alives");
			}

			_pillage = true;

			const rem : Vector.<IBattleEntity> = new Vector.<IBattleEntity>;

			for each (var e : IBattleEntity in _aliveOrder)
			{
				// yes i know it is n^2 but n is small
				if (rem.indexOf(e) >= 0)
				{
					continue;
				}
				rem.push(e);
			}

			_aliveOrder = rem;
			currentTeam = null;
			_index = -1;

			dispatchEvent(new BattleTurnOrderEvent(BattleTurnOrderEvent.PILLAGE));

		}

		public function get index() : int
		{
			return _index;
		}

		public function addParty(party : IBattleParty) : void
		{
			for each (var btt : BattleTurnTeam in turnTeams)
			{
				if (btt.team == party.team)
				{
					btt.addParty(party);
					return;
				}
			}

			btt = new BattleTurnTeam(party.team);
			btt.addParty(party);
			turnTeams.push(btt);
		}

		public function removeParty(party : IBattleParty) : void
		{
			for each (var btt : BattleTurnTeam in turnTeams)
			{
				if (btt.team == party.team)
				{
					btt.removeParty(party);
					return;
				}
			}
		}

		public function setDirty() : void
		{
			_dirty = true;
		}

		public function next() : IBattleEntity
		{
			if (_pillage)
			{
				const f : IBattleEntity = _aliveOrder.shift();
				_aliveOrder.push(f);
				return f;
			}
			_index = ++_index % turnTeams.length;
			currentTeam = turnTeams[_index];

			if (currentTeam)
			{
				currentTeam.next();
			}

			setDirty();

			dispatchEvent(new BattleTurnOrderEvent(BattleTurnOrderEvent.CHANGED));

			return (currentTeam && currentTeam.currents.length > 0) ? currentTeam.currents[0] : null;
		}

		public function get numTeams() : int
		{
			checkDirty();
			return _numTeamsRemaining;
		}

		private function computeMaxPartySize() : int
		{
			var maxPartySize : int = 0;
			for (var i : int = 0; i < turnTeams.length; ++i)
			{
				var index : int = (i + index) % turnTeams.length;
				var btt : BattleTurnTeam = turnTeams[index];
				for each (var btp : BattleTurnParty in btt.turnParties)
				{
					maxPartySize = Math.max(maxPartySize, btp.members.length);
				}
			}
			return maxPartySize;
		}

		private function checkDirty() : void
		{
			if (!_dirty)
			{
				return;
			}

			_dirty = false;

			if (pillage)
			{
				return;
			}

			if (_index < 0)
			{
				_index = 0;				
			}
			
			_aliveOrder.splice(0, _aliveOrder.length);

			var remaining : int = 0;

			var maxPartySize : int = computeMaxPartySize();

			for (var i : int = 0; i < maxPartySize; ++i)
			{
				for (var j : int = 0; j < turnTeams.length; ++j)
				{
					var teamIndex : int = (j + _index) % turnTeams.length;
					var btt : BattleTurnTeam = turnTeams[teamIndex];

					for (var k : int = 0; k < btt.turnParties.length; ++k)
					{
						var btp : BattleTurnParty = btt.turnParties[k];

						var memberIndex : int = i;
						if (teamIndex != _index)
						{
							++memberIndex;
						}
						var e : IBattleEntity = btp.getFutureCurrent(memberIndex);
						if (e)
						{
							_aliveOrder.push(e);
						}
					}
				}
			}

		}

		public function get aliveOrder() : Vector.<IBattleEntity>
		{
			checkDirty();
			return _aliveOrder;
		}

		public function getAllParticipants(all : Vector.<IBattleEntity>) : Vector.<IBattleEntity>
		{
			for each (var btt : BattleTurnTeam in turnTeams)
			{
				all = btt.getAllTeamMembers(all);
			}

			return all;
		}

		public function getAliveParticipants(all : Vector.<IBattleEntity>) : Vector.<IBattleEntity>
		{
			for each (var btt : BattleTurnTeam in turnTeams)
			{
				all = btt.getAliveMembers(all);
			}
			return all;
		}

		public function pruneDeadEntities() : int
		{
			var deaders : int = 0;
			for each (var btt : BattleTurnTeam in turnTeams)
			{
				deaders += btt.pruneDeadEntities();
			}

			if (deaders)
			{
				setDirty();
				if (pillage)
				{
					checkDirty();

					for (var i : int = 0; i < _aliveOrder.length; )
					{
						var e : IBattleEntity = _aliveOrder[i];
						if (e.alive)
						{
							++i;
							continue;
						}
						else
						{
							_aliveOrder.splice(i, 1);
						}
					}
				}
			}

			return deaders;
		}

		protected function battleTurnTeamForEntity(battleEntity : IBattleEntity) : BattleTurnTeam
		{
			for each (var battleTurnTeam : BattleTurnTeam in turnTeams)
			{
				if (battleEntity.team == battleTurnTeam.team)
				{
					return battleTurnTeam;
				}
			}
			return null;
		}

		protected function debug_spewAliveOrder() : void
		{
			logger.debug("############################");
			logger.debug("alive order:");

			for (var i : int = 0; i < _aliveOrder.length; ++i)
			{
				logger.debug("[" + i + "] id=" + _aliveOrder[i].id);
			}
		}

		public function bumpToNext(battleEntity : IBattleEntity) : void
		{
			if (pillage == false)
			{
				var battleTurnTeam : BattleTurnTeam = battleTurnTeamForEntity(battleEntity);

				if (battleTurnTeam != null)
				{
					battleTurnTeam.bumpToNext(battleEntity);
				}

				setDirty();
				checkDirty();
			}
			else
			{
				// in pillage mode, _aliveOrder is authoritive

				//logger.debug("before bumpToNext");
				//debug_spewAliveOrder();

				var entIndex : int = _aliveOrder.indexOf(battleEntity);
				_aliveOrder.splice(entIndex, 1);
				_aliveOrder.splice(1, 0, battleEntity);

					//logger.debug("after bumpToNext");
					//debug_spewAliveOrder();
			}

			dispatchEvent(new BattleTurnOrderEvent(BattleTurnOrderEvent.REFRESH_INITIATIVE));

			if (pillage == false)
			{
				dispatchEvent(new BattleTurnOrderEvent(BattleTurnOrderEvent.PLAY_FORGE_AHEAD_VFX));
			}
			else
			{
				dispatchEvent(new BattleTurnOrderEvent(BattleTurnOrderEvent.PLAY_FORGE_AHEAD_PILLAGE_VFX));
			}

		}
	}
}
