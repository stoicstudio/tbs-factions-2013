package tbs.srv.battle.data.base;

import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Output;

import tbs.srv.util.ReliableMsg;

abstract public class BaseBattleData extends ReliableMsg {

	public long user;
	public String battleId;

	public BaseBattleData() {

	}

	public BaseBattleData(final String reliable_msg_id, long user, String battleId) {
		super(reliable_msg_id);
		this.user = user;
		this.battleId = battleId;
	}

	@Override
	public void toJSON(Output out) {
		super.toJSON(out);
		out.add("user_id", user);
		out.add("battle_id", battleId);
	}

	@Override
	public void fromJSON(@SuppressWarnings("rawtypes") Map jo) {
		super.fromJSON(jo);
		user = ((Number) jo.get("user_id")).longValue();
		battleId = (String) jo.get("battle_id");

	}
}