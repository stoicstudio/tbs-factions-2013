package tbs.srv.util;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

import org.apache.log4j.Logger;
import org.eclipse.jetty.util.ajax.JSON;
import org.eclipse.jetty.util.ajax.JSON.Convertible;
import org.eclipse.jetty.util.ajax.JSON.Output;

import tbs.srv.battle.BattleRanking;
import tbs.srv.data.LeaderboardData;
import tbs.srv.data.LeaderboardType;
import tbs.srv.data.TourneyDef;
import tbs.srv.db.DbHelper;

public class Tourney implements Convertible {

	private static final Logger logger = Logger.getLogger(Tourney.class.getSimpleName());

	public int tourney_id;
	public long start_time;
	public long end_time;
	public boolean started;
	public boolean ended;
	public int parent_id;
	public TourneyDef def;

	public Tourney() {

	}

	public String toString() {
		return "Tourney [" + tourney_id + " " + def + "]";
	}

	public boolean active() {
		return started && !ended;
	}

	public void create(final TourneyDef entry) {
		this.def = entry;

		start_time = entry.getStartTime();
		end_time = start_time + entry.duration;

		if (entry.parent != null) {
			Tourney parent = get(entry.parent, false);
			if (parent == null) {
				final TourneyDef pe = GameConfig.instance.tourney_defs.find(entry.parent);
				if (pe != null) {
					parent = new Tourney();
					parent.create(pe);
				}
			}

			if (parent == null) {
				logger.error("Tourney.start failed to create parent for " + entry);
			} else {
				parent_id = parent.tourney_id;
			}
		}

		insert();

		broadcast();
	}

	public void broadcast() {
		GameConfig.instance.msg.send("amq.fanout", this, MsgSystem.ZIP);
	}

	public void start() {
		logger.info("start " + this);
		started = true;
		persistStart();
		broadcast();
	}

	public void end() {
		logger.info("end " + this);
		ended = true;

		final TourneyWinnerData msg = getTourneyWinnerMsg();

		if (msg != null) {
			final TourneyDef entry = def;

			for (int i = 0; i < msg.ranked_ids.length; ++i) {
				final long account_id = ((Number) msg.ranked_ids[i]).longValue();

				if (parent_id > 0) {
					final BattleRanking parent_r = BattleRanking.get(account_id, parent_id, true);
					if (i == 0) {
						parent_r.incrementWins();
					} else {
						parent_r.incrementLosses();
					}
					parent_r.save(GameConfig.instance.rdsDatasource);
				}

				if (entry != null) {
					if (entry.rewards.length > i) {
						final int reward = entry.rewards[i];
						// grant renown
						GameConfig.instance.renown.modifyRenown(account_id, reward, RenownReason.TOURNAMENT_REWARD, Integer.toString(tourney_id));
					}
				}
			}
		}

		persistEnd();

		// notify the clients

		GameConfig.instance.msg.send("amq.fanout", this, MsgSystem.ZIP);
		GameConfig.instance.msg.send("amq.fanout", msg, MsgSystem.ZIP);
	}

	private void persistEnd() {
		Connection con = null;
		PreparedStatement s = null;
		try {
			con = GameConfig.instance.rdsDatasource.getConnection();
			s = con.prepareStatement("UPDATE tourney SET ended=1 WHERE tourney_id=?");
			int index = 0;
			s.setInt(++index, tourney_id);
			s.executeUpdate();
			s.close();

		} catch (SQLException e) {
			logger.error("insert: " + e);
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}
	}

	private void persistStart() {
		Connection con = null;
		PreparedStatement s = null;
		try {
			con = GameConfig.instance.rdsDatasource.getConnection();
			s = con.prepareStatement("UPDATE tourney SET started=1 WHERE tourney_id=?");
			int index = 0;
			s.setInt(++index, tourney_id);
			s.executeUpdate();
			s.close();

		} catch (SQLException e) {
			logger.error("insert: " + e);
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}
	}

	private void insert() {

		Connection con = null;
		PreparedStatement s = null;
		try {
			con = GameConfig.instance.rdsDatasource.getConnection();
			s = con.prepareStatement("INSERT INTO tourney (start_time, end_time,  parent_id, def_name, def_rewards, def_entry_fee, def_daily_limit, def_power_requirement) VALUES (?,?,?,?,?,?,?,?)");
			int index = 0;
			s.setLong(++index, start_time);
			s.setLong(++index, end_time);
			s.setInt(++index, parent_id);
			s.setString(++index, def.name);
			s.setString(++index, JSON.toString(def.rewards));
			s.setInt(++index, def.entry_fee);
			s.setInt(++index, def.daily_limit);
			s.setInt(++index, def.power_requirement);
			s.executeUpdate();
			s.close();

			s = con.prepareStatement("SELECT LAST_INSERT_ID()");
			final ResultSet rs = s.executeQuery();

			if (!rs.next()) {
				logger.error("Tournament.start Failed to " + s);
			} else {
				tourney_id = rs.getInt(1);
			}
			s.close();

		} catch (SQLException e) {
			logger.error("insert: " + e);
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}
	}

	public Tourney(ResultSet rs) throws SQLException {
		tourney_id = rs.getInt("tourney_id");
		start_time = rs.getLong("start_time");
		end_time = rs.getLong("end_time");
		started = rs.getBoolean("started");
		ended = rs.getBoolean("ended");
		parent_id = rs.getInt("parent_id");

		final String def_name = rs.getString("def_name");

		this.def = GameConfig.instance.tourney_defs.find(def_name);
		if (def == null) {
			logger.error("No such def: " + def_name);
			return;
		}

		this.def = new TourneyDef(this.def);
		final Object[] rr = (Object[]) JSON.parse((String) rs.getString("def_rewards"));

		this.def.rewards = new int[rr.length];
		for (int i = 0; i < rr.length; ++i) {
			this.def.rewards[i] = ((Number) rr[i]).intValue();
		}

		this.def.entry_fee = rs.getInt("def_entry_fee");
		this.def.daily_limit = rs.getInt("def_daily_limit");
		this.def.power_requirement = rs.getInt("def_power_requirement");
	}

	@Override
	public void toJSON(Output out) {
		out.addClass(getClass());
		out.add("tourney_id", tourney_id);
		out.add("start_time", start_time);
		out.add("end_time", end_time);
		out.add("started", started);
		out.add("ended", ended);
		out.add("parent_id", parent_id);

		out.add("def", def);
	}

	@SuppressWarnings({ "rawtypes", "unchecked" })
	@Override
	public void fromJSON(Map object) {
		tourney_id = ((Number) object.get("tourney_id")).intValue();
		start_time = ((Number) object.get("start_time")).longValue();
		end_time = ((Number) object.get("end_time")).longValue();
		started = ((Boolean) object.get("started")).booleanValue();
		ended = ((Boolean) object.get("ended")).booleanValue();
		parent_id = ((Number) object.get("parent_id")).intValue();

		final Object od = object.get("def");
		if (od instanceof TourneyDef) {
			this.def = (TourneyDef) od;
		} else {
			this.def = new TourneyDef((Map<String, Object>) od);
		}
	}

	public boolean isActive() {
		return started && !ended;
	}

	public static Tourney get(final String tourney_name, final boolean previous) {
		Connection con = null;
		PreparedStatement s = null;
		try {
			con = GameConfig.instance.rdsDatasource.getConnection();
			if (previous) {
				s = con.prepareStatement("SELECT * FROM tourney WHERE def_name=? AND ended=1 ORDER BY tourney_id DESC LIMIT 1");
			} else {
				s = con.prepareStatement("SELECT * FROM tourney WHERE def_name=? ORDER BY tourney_id DESC LIMIT 1");
			}

			s.setString(1, tourney_name);

			final ResultSet rs = s.executeQuery();
			if (rs.next()) {
				return new Tourney(rs);
			}
			s.close();

		} catch (SQLException e) {
			logger.error("Tourney.get :" + e);
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}

		return null;
	}

	public static Tourney get(final int tourney_id) {
		Connection con = null;
		PreparedStatement s = null;
		try {
			con = GameConfig.instance.rdsDatasource.getConnection();
			s = con.prepareStatement("SELECT * FROM tourney WHERE tourney_id=?");
			s.setInt(1, tourney_id);
			final ResultSet rs = s.executeQuery();
			if (rs.next()) {
				return new Tourney(rs);
			}
			s.close();

		} catch (SQLException e) {
			logger.error("Tourney.get :" + e);
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}

		return null;
	}

	public static void requestSendStateToPlayer(final long account_id) {
		final TourneySendToUserMsg msg = new TourneySendToUserMsg(account_id);
		GameConfig.instance.msg.send("amq.direct", msg, MsgSystem.ZIP, TourneySendToUserMsg.KEY);
	}

	private static TourneyProgressData createPlayerProgress(final long account_id, final int tourney_id, final String tourney_name) {
		TourneyProgressData prog = null;

		Connection con = null;
		PreparedStatement s = null;

		try {
			con = GameConfig.instance.rdsDatasource.getConnection();

			{
				s = con.prepareStatement("select battle_wins, battle_losses from ranking where tourney_id=? and account_id=?");
				int index = 0;
				s.setInt(++index, tourney_id);
				s.setLong(++index, account_id);
				final ResultSet rs = s.executeQuery();

				if (rs.next()) {
					prog = new TourneyProgressData();
					prog.tourney_id = tourney_id;
					prog.tourney_name = tourney_name;
					prog.battle_count = rs.getInt("battle_wins") + rs.getInt("battle_losses");
				}

				rs.close();
				s.close();
			}

			if (prog == null) {
				return null;
			}

			{
				s = con.prepareStatement("select count(rank) from leaderboard where tourney_id=? and leaderboard_type=?");
				int index = 0;
				s.setInt(++index, tourney_id);
				s.setInt(++index, LeaderboardType.ELO.ordinal());
				final ResultSet rs = s.executeQuery();

				rs.next();
				prog.max_rank = rs.getInt(1);

				rs.close();
				s.close();
			}

			{
				s = con.prepareStatement("select rank from leaderboard where tourney_id=? and leaderboard_type=? and account_id = ?");
				int index = 0;
				s.setInt(++index, tourney_id);
				s.setInt(++index, LeaderboardType.ELO.ordinal());
				s.setLong(++index, account_id);
				final ResultSet rs = s.executeQuery();

				if (rs.next()) {
					prog.rank = rs.getInt("rank");
				}

				rs.close();
				s.close();
			}

		} catch (SQLException e) {
			logger.error("Tourney.sendProgressToPlayers: " + e);
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}

		return prog;
	}

	public static void sendStateToPlayer(final long account_id, final long request_time) {

		final long start = System.currentTimeMillis();

		final Tourney curr = Tourney.get("weekly", false);
		final Tourney prev = Tourney.get("weekly", true);

		final TourneyWinnerData msg = prev != null ? prev.getTourneyWinnerMsg() : null;

		TourneyProgressData prog = null;

		if (curr != null && curr.active()) {
			prog = createPlayerProgress(account_id, curr.tourney_id, curr.def.name);
		}

		if (prog == null) {
			prog = new TourneyProgressData();
		}

		// notify the clients

		final String q = MsgSystem.getUserQueue(account_id);
		if (curr != null) {
			GameConfig.instance.msg.send("", curr, MsgSystem.ZIP, q);
		}

		GameConfig.instance.msg.send("", prog, MsgSystem.ZIP, q);

		if (msg != null) {
			GameConfig.instance.msg.send("", msg, MsgSystem.ZIP, q);
		}

		final long end = System.currentTimeMillis();
		final long duration = end - start;
		final long delay = end - request_time;

		logger.debug("sendStateToPlayer " + account_id + " duration=" + duration + " delay=" + delay);
	}

	public void sendProgressToPlayers() {

		new Thread() {
			@Override
			public void run() {

				LeaderboardData.cacheLeaderboards(new Integer[] { tourney_id }, new LeaderboardType[] { LeaderboardType.ELO });

				final HashMap<Long, TourneyProgressData> progs = new HashMap<Long, TourneyProgressData>();

				Connection con = null;
				PreparedStatement s = null;

				try {
					con = GameConfig.instance.rdsDatasource.getConnection();

					{
						s = con.prepareStatement("select session.account_id, battle_wins, battle_losses from ranking join session using (account_id) where tourney_id=?");
						int index = 0;
						s.setInt(++index, tourney_id);
						final ResultSet rs = s.executeQuery();

						while (rs.next()) {
							final TourneyProgressData prog = new TourneyProgressData();
							final long account_id = rs.getLong("account_id");
							prog.tourney_id = tourney_id;
							prog.tourney_name = def.name;
							prog.battle_count = rs.getInt("battle_wins") + rs.getInt("battle_losses");
							progs.put(account_id, prog);
						}

						rs.close();
						s.close();
					}

					if (progs.size() == 0) {
						return;
					}

					{

						StringBuffer sb = new StringBuffer();

						boolean comma = false;
						for (Long i : progs.keySet()) {
							if (comma) {
								sb.append(",");
							}
							sb.append(i);
							comma = true;
						}

						s = con.prepareStatement("select account_id, rank from leaderboard where tourney_id=? and leaderboard_type=? and account_id in ("
								+ sb.toString() + ")");
						int index = 0;
						s.setInt(++index, tourney_id);
						s.setInt(++index, LeaderboardType.ELO.ordinal());
						final ResultSet rs = s.executeQuery();

						while (rs.next()) {
							final long account_id = rs.getLong("account_id");
							final TourneyProgressData prog = progs.get(account_id);
							prog.rank = rs.getInt("rank");
						}

						rs.close();
						s.close();
					}

				} catch (SQLException e) {
					logger.error("Tourney.sendProgressToPlayers: " + e);
					e.printStackTrace();
				} finally {
					DbHelper.cleanup(con, s);
				}

				for (Map.Entry<Long, TourneyProgressData> e : progs.entrySet()) {
					final String q = MsgSystem.getUserQueue(e.getKey());
					GameConfig.instance.msg.send("", e.getValue(), MsgSystem.ZIP, q);
				}
			}
		}.start();

	}

	private TourneyWinnerData getTourneyWinnerMsg() {

		LeaderboardData.cacheLeaderboards(new Integer[] { tourney_id }, new LeaderboardType[] { LeaderboardType.ELO });

		Connection con = null;
		PreparedStatement s = null;

		ArrayList<Long> rankedIds = new ArrayList<Long>();
		ArrayList<String> rankedDisplayNames = new ArrayList<String>();

		try {
			con = GameConfig.instance.rdsDatasource.getConnection();

			{
				s = con.prepareStatement("select account_id, display_name from leaderboard where tourney_id=? and leaderboard_type=? LIMIT 3");
				int index = 0;
				s.setInt(++index, tourney_id);
				s.setInt(++index, LeaderboardType.ELO.ordinal());
				final ResultSet rs = s.executeQuery();

				while (rs.next()) {
					rankedIds.add(rs.getLong("account_id"));
					rankedDisplayNames.add(rs.getString("display_name"));
				}

				rs.close();
				s.close();
			}

		} catch (SQLException e) {
			logger.error("getTourneyWinnerMsg: " + e);
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}

		final Object[] ranked_ids = rankedIds.toArray();
		final Object[] ranked_display_names = rankedDisplayNames.toArray();

		final TourneyWinnerData msg = new TourneyWinnerData(tourney_id, def, ranked_ids, ranked_display_names);
		return msg;
	}

	public TourneyProgressData join(final long account_id) {

		final BattleRanking br = new BattleRanking(account_id, tourney_id);
		br.save(GameConfig.instance.rdsDatasource);
		LeaderboardData.cacheLeaderboards(new Integer[] { tourney_id }, new LeaderboardType[] { LeaderboardType.ELO });
		final TourneyProgressData prog = createPlayerProgress(account_id, tourney_id, def.name);

		return prog;
	}

	public int day() {
		final long cur = System.currentTimeMillis();
		final double elapsed = cur - start_time;
		return (int) Math.ceil(elapsed / (1000 * 60 * 60 * 24));
	}

	public boolean canUserBattle(final long account_id) {
		if (!started || ended) {
			return false;
		}

		final BattleRanking br = BattleRanking.get(account_id, tourney_id, false);

		if (br == null) {
			return false;
		}

		final TourneyDef td = this.def;

		final int total = br.wins + br.losses;
		final int allowed = day() * td.daily_limit;

		if (total >= allowed) {
			return false;
		}

		return true;
	}
}
