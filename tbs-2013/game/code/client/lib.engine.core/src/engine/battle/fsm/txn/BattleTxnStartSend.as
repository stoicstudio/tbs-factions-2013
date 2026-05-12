package engine.battle.fsm.txn
{
	import engine.battle.fsm.BattleFsm;
	import engine.core.http.HttpRequestMethod;
	import engine.core.logging.ILogger;
	import engine.session.Credentials;

	public class BattleTxnStartSend extends BattleTxn_Base
	{
		public static const PATH : String = "services/battle/ready";

		public function BattleTxnStartSend(battleId : String, cred : Credentials, callback : Function, battleFsm : BattleFsm, logger : ILogger)
		{
			super(PATH + cred.urlCred, HttpRequestMethod.POST, {battle_id: battleId}, callback, battleFsm, logger);
		}
	}
}
