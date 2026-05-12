package engine.battle.fsm.txn
{
	import engine.battle.board.model.IBattleEntity;
	import engine.battle.fsm.BattleFsm;
	import engine.battle.fsm.BattleTurnOrder;
	import engine.core.http.HttpRequestMethod;
	import engine.core.logging.ILogger;
	import engine.math.Hash;
	import engine.session.Credentials;
	import engine.stat.model.Stat;
	import engine.stat.model.StatsVars;

	public class BattleTxnTurnInitSend extends BattleTxn_Base
	{
		public static const PATH : String = "services/battle/sync";
		public var entityId : String;
		public var team : String;
		public var turnNumber : int;
		public var divergence : Boolean;
		public var hashStr : String;

		public function BattleTxnTurnInitSend(battleId : String, turnNumber : int, hashStr : String, hash : int, entity : IBattleEntity, cred : Credentials, callback : Function, battleFsm : BattleFsm,
			logger : ILogger)
		{
			this.turnNumber = turnNumber;

			var body : Object = null;

			if (entity)
			{
				entityId = entity.id;
				team = entity.team;
			}

			body = {};

			body.battle_id = battleFsm.battleId;
			body.entity = entityId;
			body.team = team;
			body.turn = turnNumber;
			//body.hash_str = hashStr;

			body.entities = [];

			body.randomSampleCount = entity.board.abilityManager.rng.sampleCount;

			body.hash = hash;

			super(PATH + cred.urlCred, HttpRequestMethod.POST, body, callback, battleFsm, logger);
		}

		override protected function handleJsonResponseProcessing() : void
		{
			super.handleJsonResponseProcessing();
			if (success)
			{
				if (jsonObject)
				{
					divergence = jsonObject.divergence;
				}
			}
		}

	}
}
