package tbs.srv.util;

import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Convertible;
import org.eclipse.jetty.util.ajax.JSON.Output;

public class TourneyProgressData implements Convertible {

	public int tourney_id;
	public String tourney_name;
	public int battle_count;
	public int rank;
	public int max_rank;

	public TourneyProgressData() {

	}

	@Override
	public void toJSON(Output out) {
		out.addClass(getClass());
		out.add("tourney_id", tourney_id);
		out.add("tourney_name", tourney_name);
		out.add("battle_count", battle_count);
		out.add("rank", rank);
		out.add("max_rank", max_rank);
	}

	@SuppressWarnings("rawtypes")
	@Override
	public void fromJSON(Map object) {
		tourney_id = ((Number) object.get("tourney_id")).intValue();
		tourney_name = (String) object.get("tourney_name");
		battle_count = ((Number) object.get("battle_count")).intValue();
		rank = ((Number) object.get("rank")).intValue();
		max_rank = ((Number) object.get("max_rank")).intValue();
	}
}
