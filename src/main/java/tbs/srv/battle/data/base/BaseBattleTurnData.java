package tbs.srv.battle.data.base;

import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Output;

public abstract class BaseBattleTurnData extends BaseBattleEntityData {

	public int turn;
	public int ordinal;

	public BaseBattleTurnData() {
		super();
	}

	public BaseBattleTurnData(final String reliable_msg_id, long user, String battleId, String entity, int turn, int ordinal) {
		super(reliable_msg_id, user, battleId, entity);
		this.turn = turn;
		this.ordinal = ordinal;
	}

	@Override
	public void toJSON(Output out) {
		super.toJSON(out);
		out.add("turn", turn);
		out.add("ordinal", ordinal);
	}

	@Override
	public void fromJSON(@SuppressWarnings("rawtypes") Map jo) {
		super.fromJSON(jo);
		this.turn = ((Number) jo.get("turn")).intValue();
		if (jo.containsKey("ordinal")) {
			this.ordinal = ((Number) jo.get("ordinal")).intValue();
		}
	}

}