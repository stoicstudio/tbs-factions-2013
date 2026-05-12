package engine.battle.fsm.txn
{
	import engine.battle.board.model.IBattleEntity;
	import engine.battle.fsm.BattleFsm;
	import engine.battle.sim.IBattleParty;
	import engine.core.http.HttpRequestMethod;
	import engine.core.logging.ILogger;
	import engine.session.Credentials;
	import engine.tile.TileLocationVars;

	import flash.errors.IllegalOperationError;

	public class BattleTxnDeploySend extends BattleTxn_Base
	{
		public static const PATH : String = "services/battle/deploy";
		public var party : IBattleParty;

		public function BattleTxnDeploySend(battleId : String, order : int, party : IBattleParty, cred : Credentials, callback : Function, battleFsm : BattleFsm, logger : ILogger)
		{
			this.party = party;

			checkParty(party);

			var body : Object = {
					battle_id: battleId,
					tiles: []
				};

			for (var i : int = 0; i < party.numMembers; ++i)
			{
				var e : IBattleEntity = party.getMember(i);
				body.tiles.push(TileLocationVars.save(e.tile.location));
			}

			super(PATH + cred.urlCred, HttpRequestMethod.POST, body, callback, battleFsm, logger);
		}

		private function checkParty(party : IBattleParty) : void
		{
			if (!party.deployed)
			{
				throw new ArgumentError("Trying to pull a fast one, eh?");
			}

			for (var i : int = 0; i < party.numMembers; ++i)
			{
				var e : IBattleEntity = party.getMember(i);
				if (!e.tile)
				{
					throw new IllegalOperationError("Claimed to be deployed, but null tile");
				}
			}
		}

	}
}
