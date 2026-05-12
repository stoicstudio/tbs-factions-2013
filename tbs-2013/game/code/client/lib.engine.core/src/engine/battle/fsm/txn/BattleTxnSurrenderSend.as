package engine.battle.fsm.txn
{
	import engine.battle.fsm.BattleFsm;
	import engine.core.http.HttpRequestMethod;
	import engine.core.logging.ILogger;
	import engine.session.Credentials;

	public class BattleTxnSurrenderSend extends BattleTxn_Base
	{
		public static const PATH : String = "services/battle/surrender";

		public function BattleTxnSurrenderSend(battleId : String, cred : Credentials, callback : Function, battleFsm : BattleFsm, logger : ILogger)
		{
			const body : Object =
				{
					battle_id: battleId,
					turn: battleFsm ? (battleFsm.turns.length - 1) : 0
				};
			super(PATH + cred.urlCred, HttpRequestMethod.POST, body, callback, battleFsm, logger);

			resendOnFail = true;
		}
	}
}
