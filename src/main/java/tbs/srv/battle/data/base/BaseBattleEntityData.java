package tbs.srv.battle.data.base;

import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Output;

public abstract class BaseBattleEntityData extends BaseBattleData {

	public String entity;

	public BaseBattleEntityData() {
		super();
	}

	public BaseBattleEntityData(final String reliable_msg_id, long user, String battleId, String entity) {
		super(reliable_msg_id, user, battleId);
		this.entity = entity;
	}

	@Override
	public String toString() {
		return super.toString() + " ent=" + entity;
	}

	@Override
	public void toJSON(Output out) {
		super.toJSON(out);
		out.add("entity", entity);
	}

	@Override
	public void fromJSON(@SuppressWarnings("rawtypes") Map jo) {
		super.fromJSON(jo);
		entity = (String) jo.get("entity");
	}

}