package tbs.srv.util;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Convertible;
import org.eclipse.jetty.util.ajax.JSON.Output;

public class LeaderboardDirtyData implements Convertible {

	public static final String KEY = "key_leaderboard_dirty";
	public int tourney_id;

	public LeaderboardDirtyData() {

	}

	public LeaderboardDirtyData(ResultSet rs) throws SQLException {

		tourney_id = rs.getInt("tourney_id");
	}

	public LeaderboardDirtyData(int tourney_id) {
		super();
		this.tourney_id = tourney_id;
	}

	@Override
	public String toString() {
		return "LeaderboardDirtyData [" + tourney_id + "]";
	}

	@Override
	public void toJSON(Output out) {
		out.addClass(getClass());
		out.add("tourney_id", tourney_id);
	}

	@SuppressWarnings("rawtypes")
	@Override
	public void fromJSON(Map object) {
		tourney_id = ((Number) object.get("tourney_id")).intValue();
	}

}
