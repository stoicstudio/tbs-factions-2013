package engine.battle.fsm.txn
{
	import engine.battle.ability.model.IBattleAbility;
	import engine.battle.fsm.BattleFsm;
	import engine.core.http.HttpRequestMethod;
	import engine.core.logging.ILogger;
	import engine.session.Credentials;

	import tbs.srv.battle.data.client.BattleActionData;

	public class BattleTxnActionSend extends BattleTxn_Base
	{
		public static const PATH : String = "services/battle/action";

		public function BattleTxnActionSend(battleId : String, turnNumber : int, ability : IBattleAbility, ordinal : int, terminator : Boolean, cred : Credentials, callback : Function, battleFsm : BattleFsm,
			logger : ILogger)
		{
			var body : BattleActionData = new BattleActionData();
			body.setupBattleActionData(0, battleFsm.turn.number, battleFsm.battleId, ability, ordinal, terminator);

//			var body : Object = BattleAbilityVars.save(ability);
//			body.turn = turnNumber;
//			body.battle_id = battleFsm.battleId;
//			body.entity = battleFsm.turn.entity.id;

			logger.debug("BattleTxnActionSend " + body);

			super(PATH + cred.urlCred, HttpRequestMethod.POST, body, callback, battleFsm, logger);

			resendOnFail = true;
		}
	}
}
