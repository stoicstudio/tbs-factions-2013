package tbs.srv.battle.data.client;

import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Output;

import tbs.srv.battle.data.base.BaseBattleTurnData;

public class BattleSyncData extends BaseBattleTurnData {

	public String team;
	public String hash_str;
	public long hash;

	public BattleSyncData() {

	}

	protected String constructReliableMsgId() {
		return battleId + "_sync_" + user + "_" + turn;
	}

	public String toString() {
		return getClass().getSimpleName() + " " + getReliableMsgId() + " turn=" + turn;
	}

	@Override
	public void toJSON(Output out) {
		super.toJSON(out);

		out.add("hash", hash);
		out.add("team", team);
		out.add("turn", turn);
		out.add("hash_str", hash_str);
	}

	@Override
	public void fromJSON(@SuppressWarnings("rawtypes") Map jo) {
		super.fromJSON(jo);

		hash = ((Number) jo.get("hash")).longValue();
		team = (String) jo.get("team");
		hash_str = (String) jo.get("hash_str");
	}
}