package tbs.srv.battle.data;

import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Convertible;
import org.eclipse.jetty.util.ajax.JSON.Output;

public class BattleReplayData implements Convertible {

	public String battle_id;
	public Object[] battle_msgs;

	@Override
	public void toJSON(Output out) {
		out.addClass(getClass());
		out.add("battle_id", battle_id);
		out.add("battle_msgs", battle_msgs);
	}

	@Override
	public void fromJSON(@SuppressWarnings("rawtypes") Map object) {
		battle_id = (String) object.get("battle_id");
		battle_msgs = (Object[]) object.get("battle_msgs");
	}
}
