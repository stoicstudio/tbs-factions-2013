package engine.battle.fsm
{
	import engine.battle.board.model.IBattleEntity;
	import engine.battle.sim.IBattleParty;

	import flash.errors.IllegalOperationError;

	public class BattleTurnParty
	{
		public var party : IBattleParty;
		public var members : Vector.<IBattleEntity> = new Vector.<IBattleEntity>;
		public var current : IBattleEntity;
		public var _nextIndex : int = 0;

		public function BattleTurnParty(party : IBattleParty)
		{
			this.party = party;
			for (var i : int = 0; i < party.numMembers; ++i)
			{
				var member : IBattleEntity = party.getMember(i);
				if (member.alive)
				{
					members.push(member);
				}
			}
		}

		public function next() : IBattleEntity
		{
			if (_nextIndex < members.length)
			{
				current = members[_nextIndex];
			}
			else
			{
				current = null;
			}

			_nextIndex = ++_nextIndex % members.length;

			return current;
		}

		public function pruneDeadEntities() : int
		{
			var deaders : int = 0;
			for (var i : int = members.length - 1; i >= 0; --i)
			{
				var e : IBattleEntity = members[i];
				if (!e.alive)
				{
					if (i < _nextIndex)
					{
						--_nextIndex;
					}

					for (var j : int = i; j < (members.length - deaders - 1); ++j)
					{
						// slide the living down one in the array
						members[j] = members[j + 1];
					}

					++deaders;
				}
			}

			if (deaders)
			{
				members.splice(members.length - deaders, deaders);
			}

			if (members.length == 0 || _nextIndex >= members.length)
			{
				_nextIndex = 0;
			}

			return deaders;
		}

		public function getAliveMembers(all : Vector.<IBattleEntity>) : Vector.<IBattleEntity>
		{
			for each (var e : IBattleEntity in members)
			{
				if (all == null)
				{
					all = new Vector.<IBattleEntity>;
				}

				if (e.alive)
				{
					all.push(e);
				}
			}
			return all;
		}

		public function getFutureCurrent(offset : int) : IBattleEntity
		{
			if (offset < 0)
			{
				throw new ArgumentError("bad offset");
			}

			var index : int = 0
			if (offset == 0 && members.length > 1)
			{
				return current;
			}

			index = (_nextIndex + offset - 1);
			if (index < 0)
			{
				index = 0;
			}

			index = index % members.length;

			if (index < members.length)
			{
				return members[index];
			}

			return null;
		}

		protected function debug_spewMembers() : void
		{
			current.logger.debug("############################");
			current.logger.debug("_nextIndex = " + _nextIndex);
			for (var i : int = 0; i < members.length; ++i)
			{
				current.logger.debug("[" + i + "] id=" + members[i].id);
			}
		}

		public function bumpToNext(battleEntity : IBattleEntity) : void
		{
			var entIndex : int = members.indexOf(battleEntity);

			//current.logger.debug("entIndex = " + entIndex);
			//debug_spewMembers();

			if (entIndex != -1 && _nextIndex < members.length)
			{
				members.splice(entIndex, 1);

				//current.logger.debug("after first splice:");
				//debug_spewMembers();

				var newCurrentIndex : int = members.indexOf(current);

				_nextIndex = (newCurrentIndex + 1) % (members.length + 1);

				//current.logger.debug("newCurrentIndex=" + newCurrentIndex + " and _nextIndex=" + _nextIndex);

				if (_nextIndex < members.length)
				{
					members.splice(_nextIndex, 0, battleEntity);
				}
				else
				{
					members.push(battleEntity);
				}

			}

			//debug_spewMembers();

		}
	}
}
