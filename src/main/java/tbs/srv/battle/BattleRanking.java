package tbs.srv.battle;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;

import javax.sql.DataSource;

import org.apache.log4j.Logger;

import tbs.srv.db.DbHelper;
import tbs.srv.util.GameConfig;

public class BattleRanking {

	private static final Logger logger = Logger.getLogger(BattleRanking.class.getSimpleName());

	public long account_id;
	public long steam_id;
	public int wins;
	public int losses;
	public int win_streak;
	public int best_win_streak;
	public int elo = ELO_BEGIN;
	public int friend_battles;
	public int tourney_id;

	public static final int ELO_BEGIN = 1000;
	public static final int ELO_MIN = 100;

	public static final int K_MAX = 32;
	public static final int K_MIN = 16;

	public static final int K_ELO_MAX = 2400;
	public static final int K_ELO_MIN = 2100;

	public static final int TOURNEY_ID_GLOBAL = 0;

	// public static final int tourney_id_TOURNEY_HISTORY = 2;

	public BattleRanking(final ResultSet rs) throws SQLException {
		account_id = rs.getLong("account_id");
		steam_id = rs.getLong("steam_id");
		wins = rs.getInt("battle_wins");
		losses = rs.getInt("battle_losses");
		win_streak = rs.getInt("win_streak");
		best_win_streak = rs.getInt("best_win_streak");
		friend_battles = rs.getInt("friend_battles");
		tourney_id = rs.getInt("tourney_id");
		elo = rs.getInt("battle_elo");
		if (elo == 0) {
			elo = ELO_BEGIN;
		}

		elo = Math.max(ELO_MIN, elo);
	}

	public BattleRanking(final long account_id, final int tourney_id) {
		this.account_id = account_id;
		this.tourney_id = tourney_id;
	}

	public String toString() {
		return "[" + account_id + ", wins=" + wins + ", losses=" + losses + ", elo=" + elo + "]";
	}

	public static BattleRanking get(final long account_id, final int tourney_id, boolean must) {
		Connection con = null;
		PreparedStatement s = null;
		try {
			con = GameConfig.instance.rdsDatasource.getConnection();
			s = con.prepareStatement("SELECT *, NULL `steam_id` from `ranking` WHERE account_id=? AND tourney_id=?");
			s.setLong(1, account_id);
			s.setInt(2, tourney_id);

			final ResultSet rs = s.executeQuery();

			if (rs.next()) {
				return new BattleRanking(rs);
			}

		} catch (SQLException e) {
			logger.error("get: " + e);
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}

		if (must) {
			return new BattleRanking(account_id, tourney_id);
		}

		return null;
	}

	public void save(DataSource ds) {
		Connection con = null;
		try {
			con = ds.getConnection();
			save(con);
		} catch (SQLException e) {
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, null);
		}
	}

	public void save(Connection con) {
		PreparedStatement s = null;
		try {

			s = con.prepareStatement("REPLACE INTO ranking (account_id,battle_wins,battle_losses,battle_elo,win_streak,best_win_streak,friend_battles,tourney_id) VALUES (?,?,?,?,?,?,?,?)");
			int index = 0;
			s.setLong(++index, account_id);
			s.setInt(++index, wins);
			s.setInt(++index, losses);
			s.setInt(++index, elo);
			s.setInt(++index, win_streak);
			s.setInt(++index, best_win_streak);
			s.setInt(++index, friend_battles);
			s.setInt(++index, tourney_id);
			s.executeUpdate();
			s.close();

		} catch (SQLException e) {
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(null, s);
		}
	}

	public double getEloKFactor() {
		return getEloKFactor(elo);
	}

	public static double getEloKFactor(final int elo) {
		final double K_RANGE = K_MAX - K_MIN;
		final double K_ELO_RANGE = K_ELO_MAX - K_ELO_MIN;

		// interpolate domain [K_ELO_MIN,K_ELO_MAX] into [0,1]
		final double t = 1.0 - Math.max(0, Math.min(1, (elo - K_ELO_MIN) / K_ELO_RANGE));
		// and into range [K_MIN, K_MAX]
		return K_MIN + K_RANGE * t;
	}

	public static int calculateNewElo(final int myElo, final int otherElo, final float score) {
		final double k = getEloKFactor(myElo);
		final double ea = 1 / (1 + Math.pow(10, (otherElo - myElo) / 400.0)); // expected score for player a
		final int newElo = myElo + (int) (k * (score - ea));
		return Math.max(ELO_MIN, newElo);
	}

	public int getNewElo(final int opponentElo, final float score) {
		return calculateNewElo(elo, opponentElo, score);
	}

	public static BattleRanking[] getRankingsForTourney(final int tourney_id, final int limit) {

		ArrayList<BattleRanking> rankings = new ArrayList<BattleRanking>();
		Connection con = null;
		PreparedStatement s = null;
		try {
			con = GameConfig.instance.rdsDatasource.getConnection();
			s = con.prepareStatement("SELECT *, NULL `steam_id` from `ranking` WHERE tourney_id=? ORDER BY battle_elo DESC, battle_wins DESC, battle_losses ASC LIMIT "
					+ limit);
			s.setInt(1, tourney_id);

			final ResultSet rs = s.executeQuery();

			while (rs.next()) {
				final BattleRanking br = new BattleRanking(rs);
				rankings.add(br);
			}

			s.close();
		} catch (SQLException e) {
			logger.error("get: " + e);
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}

		return rankings.toArray(new BattleRanking[rankings.size()]);
	}

	public void incrementWins() {
		++wins;
		win_streak = Math.max(1, ++win_streak);
	}

	public void incrementLosses() {
		++losses;
		win_streak = Math.min(-1, --win_streak);
	}
}