package tbs.srv.battle.data.client;

import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Output;

import tbs.srv.battle.data.base.BaseBattleTurnData;

public class BattleKilledData extends BaseBattleTurnData {

	public String killer;
	public long killedparty;
	public long killerparty;

	@Override
	protected String constructReliableMsgId() {
		return battleId + "_killed_" + user + "_" + killedparty + "_" + entity;
	}

	@Override
	public void toJSON(Output out) {
		super.toJSON(out);

		out.add("killer", killer);
		out.add("killedparty", killedparty);
		out.add("killerparty", killerparty);
	}

	@Override
	public void fromJSON(@SuppressWarnings("rawtypes") Map jo) {
		super.fromJSON(jo);

		killer = (String) jo.get("killer");
		killedparty = ((Number) jo.get("killedparty")).longValue();
		killerparty = ((Number) jo.get("killerparty")).longValue();
	}
}
