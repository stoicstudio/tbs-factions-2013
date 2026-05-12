package tbs.srv.battle.data;

import tbs.srv.battle.data.base.BaseBattleTurnData;

public class BattleQueryData extends BaseBattleTurnData {

	@Override
	protected String constructReliableMsgId() {
		return battleId + "_query_" + user + "_" + battleId + "_" + turn;
	}

}
