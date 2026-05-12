package engine.battle.fsm.txn
{
	import engine.battle.fsm.BattleFsm;
	import engine.core.http.HttpRequestMethod;
	import engine.core.logging.ILogger;
	import engine.session.Credentials;

	import tbs.srv.battle.data.client.BattleExitData;

	public class BattleTxnExitSend extends BattleTxn_Base
	{
		public static const PATH : String = "services/battle/exit";

		public function BattleTxnExitSend(battleId : String, cred : Credentials, callback : Function, battleFsm : BattleFsm, logger : ILogger)
		{
			const msg : BattleExitData = new BattleExitData;
			msg.battle_id = battleFsm.battleId;
			super(PATH + cred.urlCred, HttpRequestMethod.POST, msg, callback, battleFsm, logger);
			resendOnFail = true;
		}
	}
}
