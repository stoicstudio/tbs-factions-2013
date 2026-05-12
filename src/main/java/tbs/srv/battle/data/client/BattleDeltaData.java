package tbs.srv.battle.data.client;

import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Output;

import tbs.srv.battle.data.base.BaseBattleTurnData;

public class BattleDeltaData extends BaseBattleTurnData {

	String caster;
	String target;
	String stat;
	int value;
	boolean killed;
	int sequence;

	public BattleDeltaData() {

	}

	protected String constructReliableMsgId() {
		return battleId + "_sync_" + user + "_" + sequence;
	}

	public String toString() {
		return super.toString();
	}

	@Override
	public void toJSON(Output out) {
		super.toJSON(out);

		out.add("caster", caster);
		out.add("target", target);
		out.add("stat", stat);
		out.add("value", value);
		out.add("killed", killed);
		out.add("sequence", sequence);
	}

	@Override
	public void fromJSON(@SuppressWarnings("rawtypes") Map jo) {
		super.fromJSON(jo);

		caster = (String) jo.get("caster");
		target = (String) jo.get("target");
		stat = (String) jo.get("stat");
		value = ((Number) jo.get("caster")).intValue();
		killed = (Boolean) jo.get("killed");
		sequence = ((Number) jo.get("sequence")).intValue();
	}
}