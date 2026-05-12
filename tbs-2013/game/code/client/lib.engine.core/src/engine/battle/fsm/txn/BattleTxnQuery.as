package engine.battle.fsm.txn
{
	import engine.battle.fsm.BattleFsm;
	import engine.core.http.HttpRequestMethod;
	import engine.core.logging.ILogger;

	import tbs.srv.battle.data.client.BattleActionData;

	public class BattleTxnQuery extends BattleTxn_Base
	{
		public static const PATH : String = "services/battle/query";

		public function BattleTxnQuery(battleId : String, turnNumber : int, callback : Function, battleFsm : BattleFsm, logger : ILogger)
		{
			const body : Object = {
				battle_id : battleFsm.battleId,
				turn : turnNumber
			}

			super(PATH + battleFsm.session.credentials.urlCred, HttpRequestMethod.POST, body, callback, battleFsm, logger);

			resendOnFail = true;
		}
	}
}
