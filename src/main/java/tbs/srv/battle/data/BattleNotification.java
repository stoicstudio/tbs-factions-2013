package tbs.srv.battle.data;

import java.util.Arrays;
import java.util.List;
import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Convertible;
import org.eclipse.jetty.util.ajax.JSON.Output;

public class BattleNotification implements Convertible {

	public boolean start;
	public String victor;
	public Object[] teams;
	public Object[] members;

	public BattleNotification() {

	}

	public BattleNotification(final boolean start, final String victor, final Map<String, List<String>> allMembers) {

		this.start = start;
		this.victor = victor;
		teams = allMembers.keySet().toArray();
		members = new Object[teams.length];

		for (int i = 0; i < teams.length; ++i) {
			final String t = (String) teams[i];
			final List<String> teamMembers = allMembers.get(t);
			members[i] = teamMembers.toArray();
		}
	}

	@Override
	public String toString() {
		return "BattleNotification [start=" + start + ", victor=" + victor + ", teams=" + Arrays.toString(teams) + ", members=" + Arrays.toString(members)
				+ "]";
	}

	@Override
	public void toJSON(Output out) {
		out.addClass(this.getClass());

		out.add("start", start);
		out.add("victor", victor);
		out.add("teams", teams);
		out.add("members", members);
	}

	@Override
	public void fromJSON(@SuppressWarnings("rawtypes") Map jo) {

		start = ((Boolean) jo.get("start")).booleanValue();
		victor = (String) jo.get("victor");
		teams = (Object[]) jo.get("teams");
		members = (Object[]) jo.get("members");

	}
}