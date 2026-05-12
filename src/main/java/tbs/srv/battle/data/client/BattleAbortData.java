package tbs.srv.battle.data.client;

import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Output;

import tbs.srv.battle.data.base.BaseBattleData;

public class BattleAbortData extends BaseBattleData {

	public int match_handle;

	public BattleAbortData() {
	}

	public BattleAbortData(long user, final String battleId, final int match_handle) {
		super(null, user, battleId);
		this.match_handle = match_handle;
	}

	public String toString() {
		return super.toString();
	}

	@Override
	public void toJSON(Output out) {
		super.toJSON(out);
		out.add("match_handle", match_handle);
	}

	@Override
	public void fromJSON(@SuppressWarnings("rawtypes") Map jo) {
		super.fromJSON(jo);
		this.match_handle = ((Number) jo.get("match_handle")).intValue();
	}

	protected String constructReliableMsgId() {
		return battleId + "_abort_" + user + "_" + match_handle;
	}
}