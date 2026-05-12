package tbs.srv.data;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.HashMap;

import org.apache.log4j.Logger;

import tbs.srv.db.DbHelper;
import tbs.srv.util.GameConfig;

public class LeaderboardCache {

	final static Logger logger = Logger.getLogger(LeaderboardCache.class.getSimpleName());

	final static long TTL = 10;

	private final HashMap<String, Entry> entries = new HashMap<String, Entry>();

	private final HashMap<String, Object[]> locks = new HashMap<String, Object[]>();

	private Object getLock(final String key) {
		synchronized (locks) {
			if (!locks.containsKey(key)) {
				locks.put(key, new Object[1]);
			}
			return locks.get(key);
		}
	}

	private String getKey(final LeaderboardType type, final int tourney_id) {
		return type.name() + "_" + tourney_id;
	}

	public LeaderboardData get(final LeaderboardType type, final int tourney_id, final String tourney_name) {
		final Entry entry = getEntry(type, tourney_id, tourney_name);
		return entry != null ? entry.data : null;
	}

	public Entry getEntry(final LeaderboardType type, final int tourney_id, final String tourney_name) {

		final String key = getKey(type, tourney_id);

		final Object lock = getLock(key);

		synchronized (lock) {
			Entry entry = entries.get(key);
			if (entry == null) {
				entry = new Entry(type, tourney_id, tourney_name);
				entries.put(key, entry);
			}

			final Entry fresh = entry.fresh(TTL * 1000);
			if (entry != fresh) {
				entries.put(key, fresh);
			}

			return fresh;
		}
	}

	public static class Entry {
		final public LeaderboardData data;
		final private long timestamp;

		public Entry(final LeaderboardType type, final int tourney_id, final String tourney_name) {
			super();

			this.data = getLeaderboard(type, tourney_id, tourney_name, LeaderboardData.GET_BOARD_LEN);
			this.timestamp = System.currentTimeMillis();
		}

		private static LeaderboardData getLeaderboard(final LeaderboardType leaderboard_type, final int tourney_id, final String tourney_name, final int limit) {

			Connection con = null;
			PreparedStatement ps = null;
			try {

				con = GameConfig.instance.rdsDatasource.getConnection();
				ps = con.prepareStatement(//
				"SELECT leaderboard.rank, leaderboard.value, leaderboard.account_id, leaderboard.display_name " + //
						"from leaderboard " + //
						"where tourney_id=? AND leaderboard_type=? limit " + limit);
				int index = 0;
				ps.setInt(++index, tourney_id);
				ps.setInt(++index, leaderboard_type.ordinal());
				final ResultSet rs = ps.executeQuery();
				final LeaderboardData data = new LeaderboardData(leaderboard_type, tourney_id, tourney_name, rs);

				rs.close();
				ps.close();
				con.close();

				return data;

			} catch (SQLException exp) {
				logger.error("Failed to read leaderboard " + leaderboard_type + ": " + exp);
				exp.printStackTrace();
			} finally {
				DbHelper.cleanup(con, ps);
			}
			return null;
		}

		public Entry fresh(final long ttl) {
			final long cur = System.currentTimeMillis();
			final long delta = cur - timestamp;
			if (delta > ttl) {
				// too old!
				return new Entry(data.leaderboard_type, data.tourney_id, data.tourney_name);
			}

			return this;
		}
	}

}
