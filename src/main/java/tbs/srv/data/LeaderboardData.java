package tbs.srv.data;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import org.apache.log4j.Logger;
import org.eclipse.jetty.util.ajax.JSON.Convertible;
import org.eclipse.jetty.util.ajax.JSON.Output;

import tbs.srv.battle.BattleRanking;
import tbs.srv.db.DbHelper;
import tbs.srv.util.GameConfig;

public class LeaderboardData implements Convertible {

	private static final Logger logger = Logger.getLogger(LeaderboardData.class.getSimpleName());

	public LeaderboardType leaderboard_type;

	public Object[] account_ids;
	public Object[] display_names;
	public Object[] values;
	public String user_display_name;
	public float user_value;
	public int user_rank;
	public int tourney_id;
	public String tourney_name;

	public LeaderboardData() {

	}

	public LeaderboardData(final LeaderboardType leaderboard_type, final int tourney_id, final String tourney_name, final ResultSet rs) throws SQLException {

		this.leaderboard_type = leaderboard_type;
		this.tourney_id = tourney_id;
		this.tourney_name = tourney_name;

		List<Long> ais = new ArrayList<Long>();
		List<String> dns = new ArrayList<String>();
		List<Number> vls = new ArrayList<Number>();

		while (rs.next()) {
			final long r_account_id = rs.getLong("account_id");
			final String r_display_name = rs.getString("display_name");
			final float r_value = rs.getFloat("value");

			ais.add(r_account_id);
			dns.add(r_display_name);
			vls.add(r_value);
		}

		display_names = dns.toArray();
		values = vls.toArray();
	}

	public LeaderboardData(final LeaderboardData rhs) {
		this.leaderboard_type = rhs.leaderboard_type;
		this.tourney_id = rhs.tourney_id;
		this.tourney_name = rhs.tourney_name;
		this.account_ids = rhs.account_ids;
		this.display_names = rhs.display_names;
		this.values = rhs.values;
		this.tourney_id = rhs.tourney_id;
		this.tourney_name = rhs.tourney_name;
	}

	public LeaderboardData createUserData(final ResultSet rs) throws SQLException {
		if (rs.next()) {
			final LeaderboardData other = new LeaderboardData(this);
			other.user_display_name = rs.getString("display_name");
			other.user_value = rs.getFloat("value");
			other.user_rank = rs.getInt("rank");
			return other;
		}
		return this;
	}

	public String toString() {
		return super.toString();
	}

	@Override
	public void toJSON(Output out) {
		out.addClass(getClass());
		out.add("leaderboard_type", leaderboard_type.name());
		out.add("display_names", display_names);
		out.add("values", values);
		out.add("user_value", user_value);
		out.add("user_rank", user_rank);
		out.add("user_display_name", user_display_name);
		out.add("tourney_id", tourney_id);
		out.add("account_ids", account_ids);
		out.add("tourney_name", tourney_name);
	}

	@Override
	public void fromJSON(@SuppressWarnings("rawtypes") Map jo) {
		leaderboard_type = LeaderboardType.valueOf((String) jo.get("leaderboard_type"));
		display_names = (Object[]) jo.get("display_names");
		values = (Object[]) jo.get("values");
		user_value = ((Number) jo.get("user_value")).intValue();
		user_rank = ((Number) jo.get("user_rank")).intValue();
		user_display_name = (String) jo.get("user_display_name");
		tourney_id = ((Number) jo.get("tourney_id")).intValue();
		account_ids = (Object[]) jo.get("account_ids");
		tourney_name = (String) jo.get("tourney_name");

	}

	public final static int GET_BOARD_LEN = 20;

	public static LeaderboardData getLeaderboard(final LeaderboardType leaderboard_type, final long userid, final int tourney_id, final String tourney_name) {
		return getLeaderboard(leaderboard_type, userid, tourney_id, tourney_name, GET_BOARD_LEN);
	}

	private static LeaderboardCache cache = new LeaderboardCache();

	public static LeaderboardData getLeaderboard(final LeaderboardType leaderboard_type, final long account_id, final int tourney_id,
			final String tourney_name, final int limit) {

		LeaderboardData data = cache.get(leaderboard_type, tourney_id, tourney_name);

		if (data == null) {
			return null;
		}

		if (account_id == 0) {
			return data;
		}

		BattleRanking br = null;
		Connection con = null;
		PreparedStatement ps = null;
		try {

			con = GameConfig.instance.rdsDatasource.getConnection();
			{
				ps = con.prepareStatement("SELECT rank, value, account_id, display_name from leaderboard where tourney_id=? AND leaderboard_type=? AND account_id = ?");
				int index = 0;
				ps.setInt(++index, tourney_id);
				ps.setInt(++index, leaderboard_type.ordinal());
				ps.setLong(++index, account_id);
				final ResultSet rs = ps.executeQuery();

				data = data.createUserData(rs);
				rs.close();
				ps.close();
			}

			// didn't find his rank, so just get the data from his raw ranking
			if (data.user_rank == 0) {
				data.user_rank = GameConfig.instance.LEADERBOARD_MAX_ENTRIES + 1;
				if (br == null) {
					br = BattleRanking.get(account_id, tourney_id, true);
					switch (leaderboard_type) {
					case BEST_WIN_STREAK:
						data.user_value = br.best_win_streak;
						break;
					case ELO:
						data.user_value = br.elo;
						break;
					case LOSSES:
						data.user_value = br.losses;
						break;
					case NONE:
						break;
					case TOTAL:
						data.user_value = br.losses + br.wins;
						break;
					case WINLOSS:
						data.user_value = (br.losses > 0) ? br.wins / br.losses : br.wins;
						break;
					case WINS:
						data.user_value = br.wins;
						break;
					case WIN_STREAK:
						data.user_value = br.win_streak;
						break;
					default:
						break;
					}
				}
			}

			return data;

		} catch (SQLException exp) {
			logger.error("Failed to read leaderboard " + leaderboard_type + ": " + exp);
			exp.printStackTrace();
		} finally {
			DbHelper.cleanup(con, ps);
		}
		return null;
	}

	public static int getRank(final long account_id, final int tourney_id) {
		Connection con = null;
		CallableStatement cs = null;
		try {
			con = GameConfig.instance.rdsDatasource.getConnection();
			final String sql = "call ranking_get_elo (?,?,?,?)";

			cs = con.prepareCall(sql);
			cs.setString(1, Long.toString(account_id));
			cs.setInt(2, tourney_id);
			cs.setInt(3, 0);
			cs.setInt(4, 1);
			final ResultSet rs = cs.executeQuery();
			if (rs.next()) {
				return rs.getInt("rank");
			}
			cs.close();

		} catch (SQLException exp) {
			logger.error("getRank fail: " + exp);
			exp.printStackTrace();
		} finally {
			DbHelper.cleanup(con, cs);
		}

		return 0;
	}
	
	public static void cacheLeaderboards(Integer[] tourney_ids, LeaderboardType[] types) {
		Connection con = null;
		CallableStatement cs = null;
		try {
			con = GameConfig.instance.rdsDatasource.getConnection();

			for (Integer tourney_id : tourney_ids) {
				for (LeaderboardType lt : types) {
					if (lt == LeaderboardType.NONE) {
						continue;
					}
					cs = con.prepareCall("call leaderboard_update_tourney(?, ?, ?)");
					cs.setInt(1, tourney_id);
					cs.setInt(2, lt.ordinal());
					cs.setInt(3, GameConfig.instance.LEADERBOARD_MAX_ENTRIES);
					cs.execute();
					cs.close();
				}
			}

		} catch (SQLException e) {
			logger.error("runWorker FAILED: " + e);
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, cs);
		}
	}

}