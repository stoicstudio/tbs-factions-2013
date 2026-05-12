package tbs.srv.data;

import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Output;

public class LobbyUnitVariationData extends LobbyData {

	public LobbyUnitVariationData(long lobby_id, long account_id, String account_display_name, String unit_id, int variation) {
		super(lobby_id, account_id, account_display_name, Type.VARIATION);
		this.unit_id = unit_id;
		this.variation = variation;
	}

	public String unit_id;
	public int variation;

	public LobbyUnitVariationData() {
		super.type = Type.VARIATION.name();
	}

	public String toString() {
		return super.toString();
	}

	@Override
	public void toJSON(Output out) {
		super.toJSON(out);
		out.add("unit_id", unit_id);
		out.add("variation", variation);
	}

	@Override
	public void fromJSON(@SuppressWarnings("rawtypes") Map jo) {
		super.fromJSON(jo);
		unit_id = (String) jo.get("unit_id");
		variation = ((Number) jo.get("variation")).intValue();
	}
}