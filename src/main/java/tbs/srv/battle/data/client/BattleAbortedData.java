package tbs.srv.battle.data.client;

import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Output;

import tbs.srv.battle.data.base.BaseBattleData;

public class BattleAbortedData extends BaseBattleData {

	public BattleAbortedData() {
	}

	public BattleAbortedData(final String battleId) {
		super(null, 0, battleId);
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

	protected String constructReliableMsgId() {
		return battleId + "_aborted";
	}
}