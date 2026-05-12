package engine.battle.fsm.txn
{
	import engine.battle.board.model.IBattleEntity;
	import engine.battle.fsm.BattleFsm;
	import engine.core.http.HttpRequestMethod;
	import engine.core.logging.ILogger;

	import tbs.srv.battle.data.client.BattleKilledData;

	public class BattleTxnKillSend extends BattleTxn_Base
	{
		public static const PATH : String = "services/battle/killed";

		public function BattleTxnKillSend(battleFsm : BattleFsm, turn : int, killed : IBattleEntity, killer : IBattleEntity, logger : ILogger)
		{
			const msg : BattleKilledData = new BattleKilledData;
			msg.turn = turn;
			msg.entity = killed.def.id;
			msg.killedparty = int(killed.party.id);

			if (killer)
			{
				msg.killerparty = int(killer.party.id);
				msg.killer = killer.def.id;
			}
			else
			{
				msg.killerparty = 0;
				msg.killer = null;
			}

			msg.battle_id = battleFsm.battleId;

			logger.info("BattleTxnKillSend " + msg.battle_id + ", killed=" + msg.killedparty + "/" + msg.entity + " by " + msg.killerparty + "/" + msg.killer);

			super(PATH + battleFsm.session.credentials.urlCred, HttpRequestMethod.POST, msg, null, battleFsm, battleFsm.logger);
			resendOnFail = true;
		}
	}
}
