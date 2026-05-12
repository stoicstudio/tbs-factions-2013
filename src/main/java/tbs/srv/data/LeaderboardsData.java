package tbs.srv.data;

import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Convertible;
import org.eclipse.jetty.util.ajax.JSON.Output;

public class LeaderboardsData implements Convertible {

	public Object[] boards;
	public int max_entries;

	public LeaderboardsData() {

	}

	public String toString() {
		return super.toString();
	}

	@Override
	public void toJSON(Output out) {
		out.addClass(getClass());
		out.add("boards", boards);
		out.add("max_entries", max_entries);
	}

	@Override
	public void fromJSON(@SuppressWarnings("rawtypes") Map jo) {
		boards = (Object[]) jo.get("boards");
		max_entries = ((Number) jo.get("max_entries")).intValue();
	}
}