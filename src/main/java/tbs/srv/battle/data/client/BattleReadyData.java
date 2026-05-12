package tbs.srv.battle.data.client;

import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Output;

import tbs.srv.battle.data.base.BaseBattleData;

public class BattleReadyData extends BaseBattleData {

	public BattleReadyData() {

	}

	public BattleReadyData(long user, String battleId) {
		super(null, user, battleId);
	}

	protected String constructReliableMsgId() {
		return battleId + "_ready_" + user;
	}

	@Override
	public void toJSON(Output out) {
		super.toJSON(out);
	}

	@Override
	public void fromJSON(@SuppressWarnings("rawtypes") Map jo) {
		super.fromJSON(jo);
	}
}