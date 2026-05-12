package engine.battle.fsm
{
	import flash.errors.IllegalOperationError;

	import engine.battle.board.model.IBattleEntity;
	import engine.battle.sim.IBattleParty;

	public class BattleTurnTeam
	{
		public var turnParties : Vector.<BattleTurnParty> = new Vector.<BattleTurnParty>;
		public var currents : Vector.<IBattleEntity> = new Vector.<IBattleEntity>;
		public var team : String;

		public function BattleTurnTeam(team : String)
		{
			this.team = team;
		}

		public function addParty(party : IBattleParty) : void
		{
			if (party.team != team)
			{
				throw new ArgumentError("Invalid team for party " + party);
			}

			for each (var btp : BattleTurnParty in turnParties)
			{
				if (btp.party == party)
				{
					throw new ArgumentError("Already added party " + party);
				}
			}

			btp = new BattleTurnParty(party);
			turnParties.push(btp);
		}

		public function removeParty(party : IBattleParty) : void
		{
			for (var i : int = 0; i < turnParties.length; ++i)
			{
				var btp : BattleTurnParty = turnParties[i];
				if (btp.party == party)
				{
					turnParties.splice(i, 1);
					break;
				}
			}

			removePartyFromCurrents(party);
		}

		private function removePartyFromCurrents(party : IBattleParty) : void
		{
			for (var j : int = 0; j < party.numMembers; ++j)
			{
				var e : IBattleEntity = party.getMember(j);
				var index : int = currents.indexOf(e);
				if (index >= 0)
				{
					currents.splice(index, 1);
				}
			}
		}

		public function next() : Vector.<IBattleEntity>
		{
			currents.splice(0, currents.length);

			for each (var btp : BattleTurnParty in turnParties)
			{
				var c : IBattleEntity = btp.next();

				if (c)
				{
					currents.push(c);
				}
			}

			return currents;
		}

		public function getAllTeamMembers(all : Vector.<IBattleEntity>) : Vector.<IBattleEntity>
		{
			if (!all)
			{
				all = new Vector.<IBattleEntity>;
			}

			for each (var btp : BattleTurnParty in turnParties)
			{
				btp.party.getAllMembers(all);
			}

			return all;
		}

		public function getAliveMembers(all : Vector.<IBattleEntity>) : Vector.<IBattleEntity>
		{
			for each (var btp : BattleTurnParty in turnParties)
			{
				all = btp.getAliveMembers(all);
			}
			return all;
		}

		public function pruneDeadEntities() : int
		{
			var deaders : int = 0;
			for each (var btp : BattleTurnParty in turnParties)
			{
				deaders += btp.pruneDeadEntities();
			}

			return deaders;
		}

		protected function battleTurnPartyForEntity(battleEntity : IBattleEntity) : BattleTurnParty
		{
			for each (var battleTurnParty : BattleTurnParty in turnParties)
			{
				for each (var memberEntity : IBattleEntity in battleTurnParty.members)
				{
					if (battleEntity == memberEntity)
					{
						return battleTurnParty;
					}
				}

			}

			throw new IllegalOperationError("Could not find BattleTurnParty for IBattleEntity");

			return null;
		}

		public function bumpToNext(battleEntity : IBattleEntity) : void
		{
			var battleTurnParty : BattleTurnParty = battleTurnPartyForEntity(battleEntity);

			if (battleTurnParty != null)
			{
				battleTurnParty.bumpToNext(battleEntity);
			}
		}
	}
}
