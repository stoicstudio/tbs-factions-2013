package tbs.srv.data;

import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Output;

public class BattleFinishedReport implements org.eclipse.jetty.util.ajax.JSON.Convertible {
	public String victor;
	public int victorIndex;
	public int renown0;
	public int renown1;
	public boolean surrender;
	public String cancelledBy;

	public BattleFinishedReport(int victorIndex, String victor, int renown0, int renown1, boolean surrender, String cancelledBy) {
		this.victor = victor;
		this.victorIndex = victorIndex;
		this.renown0 = renown0;
		this.renown1 = renown1;
		this.surrender = surrender;
		this.cancelledBy = cancelledBy;
	}

	@Override
	public void toJSON(Output out) {
		out.add("victor", victor);
		out.add("victorIndex", victorIndex);
		out.add("renown0", renown0);
		out.add("renown1", renown1);
		out.add("renown1", renown1);
		out.add("cancelledBy", cancelledBy);
	}

	@SuppressWarnings("rawtypes")
	@Override
	public void fromJSON(Map object) {

		victor = (String) object.get("victor");
		victorIndex = Integer.parseInt((String) object.get("victorIndex"));
		renown0 = Integer.parseInt((String) object.get("renown0"));
		renown1 = Integer.parseInt((String) object.get("renown1"));
		surrender = Boolean.parseBoolean((String) object.get("surrender"));
		cancelledBy = (String) object.get("victor");
	}

}
