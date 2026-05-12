package tbs.srv.battle.data.client;

import tbs.srv.battle.data.base.BaseBattleData;

public class BattleExitData extends BaseBattleData {

	@Override
	protected String constructReliableMsgId() {
		return battleId + "_exit_" + user;
	}

}
