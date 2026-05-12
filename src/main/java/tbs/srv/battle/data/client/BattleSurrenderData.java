package tbs.srv.battle.data.client;

import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Output;

import tbs.srv.battle.data.base.BaseBattleTurnData;

public class BattleSurrenderData extends BaseBattleTurnData {

	public BattleSurrenderData() {

	}

	public BattleSurrenderData(long user, String battleId, final int turn) {
		super(null, user, battleId, null, turn, 0);
	}

	protected String constructReliableMsgId() {
		return battleId + "_surrender_" + user + "_" + turn;
	}

	public String toString() {
		return super.toString();
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