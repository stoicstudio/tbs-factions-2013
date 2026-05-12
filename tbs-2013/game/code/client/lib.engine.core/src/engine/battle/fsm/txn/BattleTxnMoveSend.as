package engine.battle.fsm.txn
{
	import engine.battle.fsm.BattleFsm;
	import engine.battle.fsm.BattleMove;
	import engine.battle.fsm.BattleMoveVars;
	import engine.core.http.HttpRequestMethod;
	import engine.core.logging.ILogger;
	import engine.session.Credentials;

	public class BattleTxnMoveSend extends BattleTxn_Base
	{
		public static const PATH : String = "services/battle/move";

		public function BattleTxnMoveSend(battleId : String, turnNumber : int, move : BattleMove, ordinal : int, cred : Credentials, callback : Function, battleFsm : BattleFsm, logger : ILogger)
		{
			var body : Object = BattleMoveVars.save(move);
			body.turn = turnNumber;
			body.battle_id = battleFsm.battleId;
			body.ordinal = ordinal;
//			body.entity = battleFsm.turn.entity.id;

			super(PATH + cred.urlCred, HttpRequestMethod.POST, body, callback, battleFsm, logger);

			logger.debug("BattleTxnMoveSend " + JSON.stringify(body));

			if (battleFsm.turn.entity != move.entity)
			{
				throw new ArgumentError("BattleTxnMoveSend really invalid move entity");
			}

			if (battleFsm.turn.entity.tile != move.first)
			{
				throw new ArgumentError("BattleTxnMoveSend really invalid move tile " + move.first + " should be " + move.entity.tile);
			}

			resendOnFail = true;
		}

	}
}
