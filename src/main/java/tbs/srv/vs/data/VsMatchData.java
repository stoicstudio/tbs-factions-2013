package tbs.srv.vs.data;

import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Convertible;
import org.eclipse.jetty.util.ajax.JSON.Output;

public class VsMatchData implements Convertible {
	String battleId;

	public VsMatchData() {

	}

	public VsMatchData(String battleId) {
		this.battleId = battleId;
	}

	public String toString() {
		return battleId;
	}

	@Override
	public void toJSON(Output out) {
		out.addClass(getClass());
		out.add("battle_id", battleId);
	}

	@Override
	public void fromJSON(@SuppressWarnings("rawtypes") Map jo) {
		battleId = (String) jo.get("battle_id");
	}
}