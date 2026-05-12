package tbs.srv.util;

import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Convertible;
import org.eclipse.jetty.util.ajax.JSON.Output;

import tbs.srv.data.TourneyDef;

public class TourneyWinnerData implements Convertible {

	public int tourney_id;
	public Object[] ranked_ids;
	public Object[] ranked_display_names;
	public TourneyDef def;

	public TourneyWinnerData() {

	}

	public TourneyWinnerData(int tourney_id, final TourneyDef def, Object[] ranked_ids, Object[] ranked_display_names) {
		super();
		this.tourney_id = tourney_id;
		this.def = def;
		this.ranked_ids = ranked_ids;
		this.ranked_display_names = ranked_display_names;
	}

	@Override
	public void toJSON(Output out) {
		out.addClass(getClass());
		out.add("tourney_id", tourney_id);
		out.add("def", def);
		out.add("ranked_ids", ranked_ids);
		out.add("ranked_display_names", ranked_display_names);
	}

	@SuppressWarnings({ "rawtypes", "unchecked" })
	@Override
	public void fromJSON(Map object) {
		tourney_id = ((Number) object.get("tourney_id")).intValue();
		ranked_ids = (Object[]) object.get("ranked_ids");
		ranked_display_names = (Object[]) object.get("ranked_display_names");

		final Object od = object.get("def");
		if (od instanceof TourneyDef) {
			this.def = (TourneyDef) od;
		} else {
			this.def = new TourneyDef((Map<String, Object>) od);
		}
	}
}
