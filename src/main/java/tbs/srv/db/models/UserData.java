package tbs.srv.db.models;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;

import javax.sql.DataSource;

import org.apache.log4j.Logger;
import org.eclipse.jetty.util.ajax.JSON;

import tbs.srv.data.EntityDef;
import tbs.srv.data.StatType;
import tbs.srv.db.DbHelper;
import tbs.srv.util.AchievementType;
import tbs.srv.util.GameConfig;
import tbs.srv.util.ICharacterClassProvider;
import tbs.srv.util.PurchaseCountData;
import tbs.srv.util.UnlockData;

import com.newrelic.api.agent.Trace;

public class UserData {

	private static final Logger logger = Logger.getLogger(UserData.class.getSimpleName());

	public long account_id;
	public Object[] party = new Object[0];
	public HashMap<String, EntityDef> rosterDefs = new HashMap<String, EntityDef>();
	public int renown;
	public int battle_count;
	public int daily_login_streak;
	public long daily_login_time;
	public int daily_login_bonus;
	public int login_count;
	public Object[] unlocks = new Object[0];
	public Object[] purchases = new Object[0];
	public int roster_rows = 0;
	public boolean completed_tutorial;

	public UserData() {

	}

	public UserData(final DataSource ds, final ICharacterClassProvider provider, final long aid) throws SQLException {

		if (provider == null) {
			throw new IllegalArgumentException("No provider");
		}

		if (aid == 0) {
			throw new IllegalArgumentException("Invalid account id");
		}

		this.account_id = aid;

		boolean found = false;

		Connection con = null;
		PreparedStatement s = null;
		try {

			con = ds.getConnection();

			{
				final String sql = "SELECT * FROM `account_info` WHERE `account_id` = ?";
				s = con.prepareStatement(sql);
				s.setLong(1, account_id);
				final ResultSet rs = s.executeQuery();

				if (rs.next()) {
					renown = rs.getInt("account_renown");
					battle_count = rs.getInt("battle_count");
					daily_login_streak = rs.getInt("daily_login_streak");
					daily_login_time = rs.getLong("daily_login_time");
					daily_login_bonus = rs.getInt("daily_login_bonus");
					login_count = rs.getInt("login_count");
					roster_rows = rs.getInt("roster_rows");
					completed_tutorial = rs.getBoolean("completed_tutorial");
					found = true;
				}
				rs.close();
				s.close();
			}

			{
				s = con.prepareStatement("SELECT * FROM unlocks WHERE account_id=?");
				s.setLong(1, account_id);
				final ResultSet rs = s.executeQuery();

				ArrayList<UnlockData> ula = null;
				while (rs.next()) {
					final UnlockData data = new UnlockData(rs);
					if (ula == null) {
						ula = new ArrayList<UnlockData>();
					}

					ula.add(data);
				}
				rs.close();
				s.close();

				if (ula != null) {
					unlocks = ula.toArray();
				}
			}

			{
				s = con.prepareStatement("SELECT * FROM iap WHERE account_id=?");
				s.setLong(1, account_id);
				final ResultSet rs = s.executeQuery();

				ArrayList<PurchaseCountData> a = null;
				while (rs.next()) {
					final PurchaseCountData data = new PurchaseCountData(rs);
					if (a == null) {
						a = new ArrayList<PurchaseCountData>();
					}

					a.add(data);
				}
				rs.close();
				s.close();

				if (a != null) {
					purchases = a.toArray();
				}
			}

			if (!found) {
				// create a new entry with defaults

				s = con.prepareStatement("INSERT INTO account_info (account_id) VALUES (?)");
				s.setLong(1, account_id);
				s.executeUpdate();
				s.close();
				return;
			}

			if (!loadParty(con)) {
				return;
			}

			if (!loadRoster(con)) {
				return;
			}

		} catch (SQLException e) {
			logger.error("ctor: " + e);
			e.printStackTrace();
			throw e;
		} finally {
			DbHelper.cleanup(con, s);
		}
	}

	private boolean loadRoster(Connection con) {
		PreparedStatement s = null;
		try {
			final String sql = "SELECT * FROM `unit_roster` WHERE `account_id` = ?";
			s = con.prepareStatement(sql);
			s.setLong(1, account_id);
			final ResultSet rs = s.executeQuery();

			while (rs.next()) {
				EntityDef def = new EntityDef(rs, GameConfig.instance);
				rosterDefs.put(def.id, def);
			}
			rs.close();
			s.close();
			return true;
		} catch (SQLException e) {
			return false;
		} finally {
			DbHelper.cleanup(null, s);
		}
	}

	private boolean loadParty(Connection con) {
		PreparedStatement s = null;
		try {
			final String sql = "SELECT `party_json` FROM `unit_party` WHERE `account_id` = ?";
			s = con.prepareStatement(sql);
			s.setLong(1, account_id);
			final ResultSet rs = s.executeQuery();

			if (rs.next()) {
				final String partyJsonString = rs.getString("party_json");
				party = (Object[]) JSON.parse(partyJsonString);
			}
			rs.close();
			s.close();
			return true;
		} catch (SQLException e) {
			return false;
		} finally {
			DbHelper.cleanup(null, s);
		}
	}

	public static Object[] getPartyIds(final Connection con, final long account_id) throws SQLException {
		final String sql = "SELECT `party_json` FROM `unit_party` WHERE `account_id` = ?";
		PreparedStatement s = con.prepareStatement(sql);
		s.setLong(1, account_id);
		ResultSet rs = s.executeQuery();

		if (rs.next()) {
			final String partyJsonString = rs.getString("party_json");
			return (Object[]) JSON.parse(partyJsonString);
		}
		s.close();
		return null;
	}

	public String toString() {
		return Long.toString(account_id);
	}

	public EntityDef getRosterDef(String id) {
		return rosterDefs.get(id);
	}

	public EntityDef[] getPartyDefs() {

		EntityDef[] defs = new EntityDef[party.length];

		for (int i = 0; i < party.length; ++i) {
			String pid = (String) party[i];
			EntityDef def = getRosterDef((String) pid);
			if (def == null) {
				throw new IllegalArgumentException("No such party member: " + pid);
			}

			defs[i] = def;
		}

		return defs;
	}

	private static final String sqlReplaceRoster = "REPLACE INTO `unit_roster` "
			+ "(account_id,unit_id,unit_key,entity_class,unit_name,start_date,appearance_index,appearance_acquires,stat_str,stat_arm,stat_wil,stat_exe,stat_brk,stat_rnk,stat_kil,stat_bat) VALUES "
			+ "(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";

	private static PreparedStatement prepareStatement(PreparedStatement ps, final long account_id, final EntityDef member) throws SQLException {
		final String unit_key = Long.toString(account_id) + "_" + member.id;
		int index = 1;
		ps.setLong(index++, account_id);
		ps.setString(index++, member.id);
		ps.setString(index++, unit_key);
		ps.setString(index++, member.entityClass);
		ps.setString(index++, member.getName());
		ps.setLong(index++, member.start_date);

		ps.setInt(index++, member.appearance_index);
		ps.setInt(index++, member.appearance_acquires);

		final int str = member.getStatValue(StatType.STRENGTH.name());
		final int arm = member.getStatValue(StatType.ARMOR.name());
		final int wil = member.getStatValue(StatType.WILLPOWER.name());
		final int exe = member.getStatValue(StatType.EXERTION.name());
		final int abk = member.getStatValue(StatType.ARMOR_BREAK.name());
		final int rnk = member.getStatValue(StatType.RANK.name());
		final int kil = member.getStatValue(StatType.KILLS.name());
		final int bat = member.getStatValue(StatType.BATTLES.name());
		ps.setInt(index++, str);
		ps.setInt(index++, arm);
		ps.setInt(index++, wil);
		ps.setInt(index++, exe);
		ps.setInt(index++, abk);
		ps.setInt(index++, rnk);
		ps.setInt(index++, kil);
		ps.setInt(index++, bat);
		return ps;
	}

	@Trace
	public void saveRoster(DataSource ds) throws SQLException {

		Connection con = null;
		PreparedStatement s = null;
		try {
			con = ds.getConnection();
			con.setAutoCommit(false);

			HashSet<String> olds = new HashSet<String>();
			{
				s = con.prepareStatement("SELECT `unit_key` from `unit_roster` where `account_id` = ?");
				s.setLong(1, account_id);
				final ResultSet rs = s.executeQuery();

				while (rs.next()) {
					olds.add(rs.getString(1));
				}

				s.close();
			}

			for (EntityDef member : rosterDefs.values()) {
				s = con.prepareStatement(sqlReplaceRoster);
				prepareStatement(s, account_id, member);
				s.executeUpdate();
				s.close();

				final String key = member.getUnitKey(account_id);
				olds.remove(key);
			}

			if (olds.size() > 0) {
				// delete the old and in the way
				final String[] keys = olds.toArray(new String[olds.size()]);
				s = con.prepareStatement("DELETE FROM `unit_roster` where `account_id` = ? and `unit_key` IN (?)");
				s.setLong(1, account_id);
				s.setObject(2, keys);
				s.executeUpdate();
				s.close();
			}

			con.commit();

		} catch (SQLException e) {
			logger.error("saveRoster: " + e);
			e.printStackTrace();
			throw e;
		} finally {
			DbHelper.cleanup(con, s);
		}
	}

	@Trace
	public void saveParty(DataSource ds) throws SQLException {

		Connection con = null;
		Statement s = null;
		try {
			con = ds.getConnection();
			final PreparedStatement ps = con.prepareStatement("REPLACE INTO `unit_party` (`account_id`,`party_json`) VALUES (?,?)");
			s = ps;
			ps.setLong(1, account_id);
			ps.setString(2, JSON.toString(party));
			ps.executeUpdate();
			s.close();

		} catch (SQLException e) {
			logger.error("saveParty: " + e);
			e.printStackTrace();
			throw e;
		} finally {
			DbHelper.cleanup(con, s);
		}
	}

	@Trace
	public void saveRosterMember(DataSource ds, final String unit_id) throws SQLException {

		final EntityDef member = getRosterDef(unit_id);
		if (member == null) {
			throw new IllegalArgumentException("No such member: " + unit_id);
		}

		saveRosterMember(ds, account_id, member);
	}

	public static void saveRosterMember(DataSource ds, final long account_id, final EntityDef member) throws SQLException {

		Connection con = null;
		PreparedStatement ps = null;
		try {
			con = ds.getConnection();
			ps = con.prepareStatement(sqlReplaceRoster);
			prepareStatement(ps, account_id, member);
			ps.executeUpdate();
			ps.close();

		} catch (SQLException e) {
			logger.error("saveRosterMember: " + e);
			e.printStackTrace();
			throw e;
		} finally {
			DbHelper.cleanup(con, ps);
		}
	}

	public static String getNextRosterId(DataSource ds, final long account_id, final String baseId) {

		HashSet<String> ids = new HashSet<String>();

		Connection con = null;
		PreparedStatement ps = null;
		try {
			con = ds.getConnection();
			ps = con.prepareStatement("SELECT unit_id from unit_roster where account_id=? AND unit_id LIKE ?");
			ps.setLong(1, account_id);
			ps.setString(2, baseId + "%");
			final ResultSet rs = ps.executeQuery();
			while (rs.next()) {
				ids.add(rs.getString(1));
			}
			ps.close();

		} catch (SQLException e) {
			e.printStackTrace();
			return null;
		} finally {
			DbHelper.cleanup(con, ps);
		}

		for (int i = 0; i < ids.size() + 1; ++i) {
			final String id = baseId + i;
			if (!ids.contains(id)) {
				return id;
			}
		}

		return null;
	}

	public boolean setParty(Object[] pids) {
		if (!Arrays.equals(party, pids)) {
			party = pids.clone();
			return true;
		}
		return false;
	}

	public static void incrementBattleCount(GameConfig config, final long account_id) {
		Connection con = null;
		PreparedStatement s = null;
		try {
			con = config.rdsDatasource.getConnection();
			s = con.prepareStatement("UPDATE `account_info` SET `battle_count`=(`battle_count`+1) WHERE `account_id`=?");
			s.setLong(1, account_id);
			s.executeUpdate();
			s.close();
		} catch (SQLException e) {
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}
	}

	public static int getBattleCount(final long account_id) {
		Connection con = null;
		PreparedStatement s = null;
		try {
			con = GameConfig.instance.rdsDatasource.getConnection();
			s = con.prepareStatement("SELECT battle_count from `account_info` WHERE `account_id`=?");
			s.setLong(1, account_id);
			final ResultSet rs = s.executeQuery();
			if (rs.next()) {
				return rs.getInt(1);
			}
			rs.close();
			s.close();
		} catch (SQLException e) {
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}
		return 0;
	}

	public static int incrementAchievementCount_AccountInfo(GameConfig config, final long account_id, AchievementType achievementType, int amount) // returns
																																					// value
																																					// prior to
	// increment
	{
		Connection con = null;
		PreparedStatement s = null;

		String columnName = "";

		switch (achievementType) {
		case TEST:
			columnName = "ach_tst";
			break;
		case BATTLES:
			columnName = "ach_bat";
			break;
		case WINS:
			columnName = "ach_win";
			break;
		case KILLS:
			columnName = "ach_kil";
			break;
		default:
			columnName = "";
			break;
		}

		int oldValue = 0;

		try {

			con = config.rdsDatasource.getConnection();
			con.setAutoCommit(false);

			String selectStatement = "SELECT " + columnName + " from account_info where account_id = ?";
			s = con.prepareStatement(selectStatement);
			s.setLong(1, account_id);
			final ResultSet rs = s.executeQuery();

			if (rs.next()) {
				oldValue = rs.getInt(columnName);
			}

			s.close();

			//
			final int newValue = oldValue + amount;
			String updateStatement = "UPDATE account_info SET " + columnName + "=? WHERE `account_id`=?";
			s = con.prepareStatement(updateStatement);
			s.setInt(1, newValue);
			s.setLong(2, account_id);
			s.executeUpdate();
			s.close();

			con.commit();

		} catch (SQLException e) {
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}

		return oldValue;
	}

	// updates only if amount is greater than the current value
	public static int updateAchievementMaxCount_AccountInfo(GameConfig config, final long account_id, AchievementType achievementType, int amount) {
		Connection con = null;
		PreparedStatement s = null;

		String columnName = "";

		switch (achievementType) {

		case ELO:
			columnName = "ach_elo";
			break;
		case STREAK:
			columnName = "ach_streak";
			break;
		case UNIT_KILL:
			columnName = "ach_unit_kill";
			break;
		default:
			return 0;
		}

		int oldValue = 0;

		try {

			con = config.rdsDatasource.getConnection();
			con.setAutoCommit(false);

			String selectStatement = "SELECT " + columnName + " from account_info where account_id = ?";
			s = con.prepareStatement(selectStatement);
			s.setLong(1, account_id);
			final ResultSet rs = s.executeQuery();

			if (rs.next()) {
				oldValue = rs.getInt(columnName);
			}

			s.close();

			//
			// final int newValue = oldValue + amount;

			if (amount > oldValue) {
				String updateStatement = "UPDATE account_info SET " + columnName + "=? WHERE `account_id`=?";
				s = con.prepareStatement(updateStatement);
				s.setInt(1, amount);
				s.setLong(2, account_id);
				s.executeUpdate();
				s.close();
			}
			con.commit();

		} catch (SQLException e) {
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}

		return oldValue;
	}

	public static void awardAchievement(GameConfig config, final long account_id, String achievement_id, long session_key) {

		logger.info("awardAchievement " + account_id + "/" + session_key + " " + achievement_id);

		Connection con = null;
		PreparedStatement s = null;

		try {

			con = config.rdsDatasource.getConnection();
			String insertStatement = "INSERT INTO achievement (account_id,achievement,session_key,date) VALUES(?,?,?,?)";
			s = con.prepareStatement(insertStatement);

			final long date = System.currentTimeMillis();

			int index = 0;
			s.setLong(++index, account_id);
			s.setString(++index, achievement_id);
			s.setLong(++index, session_key);
			s.setLong(++index, date);

			s.executeUpdate();
			s.close();

		} catch (SQLException e) {
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}

	}

	public static ArrayList<String> getAchievements(GameConfig config, final long account_id) {

		ArrayList<String> achievements = new ArrayList<String>();
		Connection con = null;
		PreparedStatement s = null;

		try {
			con = config.rdsDatasource.getConnection();

			final String selectStatement = "SELECT `achievement` FROM `achievement` WHERE `account_id` = ?";
			s = con.prepareStatement(selectStatement);
			s.setLong(1, account_id);
			ResultSet rs = s.executeQuery();

			while (rs.next()) {
				final String achievementId = rs.getString("achievement");
				achievements.add(achievementId);
			}

		} catch (SQLException e) {
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}

		return achievements;

	}

	public static HashMap<String, Integer> getAchievementProgress(final long account_id) {

		final HashMap<String, Integer> progress = new HashMap<String, Integer>();
		Connection con = null;
		PreparedStatement s = null;

		try {
			con = GameConfig.instance.rdsDatasource.getConnection();

			final String selectStatement = "SELECT ach_bat, ach_kil, ach_win, ach_elo, ach_unit_kill, ach_streak FROM account_info WHERE account_id = ?";
			s = con.prepareStatement(selectStatement);
			s.setLong(1, account_id);
			final ResultSet rs = s.executeQuery();

			if (rs.next()) {
				progress.put(AchievementType.BATTLES.name(), rs.getInt("ach_bat"));
				progress.put(AchievementType.ELO.name(), rs.getInt("ach_elo"));
				progress.put(AchievementType.KILLS.name(), rs.getInt("ach_kil"));
				progress.put(AchievementType.STREAK.name(), rs.getInt("ach_streak"));
				progress.put(AchievementType.UNIT_KILL.name(), rs.getInt("ach_unit_kill"));
				progress.put(AchievementType.WINS.name(), rs.getInt("ach_win"));
			}

		} catch (SQLException e) {
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}

		return progress;

	}

	public void incrementLoginCount(GameConfig config) {
		++login_count;
		Connection con = null;
		PreparedStatement s = null;
		try {
			con = config.rdsDatasource.getConnection();
			s = con.prepareStatement("UPDATE `account_info` SET `login_count`=?, last_online=? WHERE `account_id`=?");
			s.setInt(1, login_count);
			s.setLong(2, System.currentTimeMillis());
			s.setLong(3, account_id);
			s.executeUpdate();
			s.close();
		} catch (SQLException e) {
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}
	}

	public static void touchLastOnline(final long account_id) {

		Connection con = null;
		PreparedStatement s = null;
		try {
			con = GameConfig.instance.rdsDatasource.getConnection();
			s = con.prepareStatement("UPDATE `account_info` SET `last_online`=? WHERE `account_id`=?");
			s.setLong(1, System.currentTimeMillis());
			s.setLong(2, account_id);
			s.executeUpdate();
			s.close();
		} catch (SQLException e) {
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}
	}

	public void retireUnit(final DataSource ds, final String entity) throws SQLException {

		logger.info("retireUnit " + this + " " + entity);
		Connection con = null;
		PreparedStatement ps = null;
		final String key = EntityDef.getUnitKey(this.account_id, entity);
		try {
			con = ds.getConnection();
			ps = con.prepareStatement("DELETE FROM unit_roster WHERE unit_key=?");
			ps.setString(1, key);
			ps.executeUpdate();
			ps.close();
		} catch (SQLException e) {
			e.printStackTrace();
			throw e;
		} finally {
			DbHelper.cleanup(con, ps);
		}

		ArrayList<String> np = new ArrayList<String>(party.length);
		for (Object o : party) {
			final String pid = (String) o;
			if (pid.equals(entity)) {
				continue;
			}
			np.add(pid);
		}

		if (np.size() < party.length) {
			saveParty(ds);
		}
	}

	@Trace
	public void checkDailyLoginStreak(final boolean force) {

		checkDailyLoginStreak(account_id, daily_login_time, daily_login_streak, force);
	}

	public static void checkDailyLoginStreak(final long account_id, final boolean force) {

		long daily_login_time = 0;
		int daily_login_streak = 0;

		Connection con = null;
		PreparedStatement s = null;
		try {

			con = GameConfig.instance.rdsDatasource.getConnection();

			{
				s = con.prepareStatement("SELECT daily_login_time, daily_login_streak from account_info WHERE account_id = ?");
				s.setLong(1, account_id);
				ResultSet rs = s.executeQuery();

				if (rs.next()) {
					daily_login_time = rs.getLong("daily_login_time");
					daily_login_streak = rs.getInt("daily_login_streak");
				}
				s.close();
			}
		} catch (SQLException e) {
			logger.error("checkDailyLoginStreak: " + e);
			e.printStackTrace();
			return;
		} finally {
			DbHelper.cleanup(con, s);
		}

		checkDailyLoginStreak(account_id, daily_login_time, daily_login_streak, force);
	}

	public static void checkDailyLoginStreak(final long account_id, long daily_login_time, int daily_login_streak, final boolean force) {
		final long dayms = GameConfig.instance.DAILY_LOGIN_STREAK_MS;
		// round down to 00:00:00 of the current day
		final long thisDay = dayms * (System.currentTimeMillis() / dayms);

		// daily_login_time is already rounded down to the day
		final long deltaDay = (thisDay - daily_login_time) / dayms;
		daily_login_time = thisDay;

		logger.debug("checkDailyLoginStreak " + account_id + " DELTA " + deltaDay);

		if (deltaDay == 0) {
			return;
		}

		daily_login_time = thisDay;
		if (deltaDay == 1 || force) {
			++daily_login_streak;
			logger.debug("checkDailyLoginStreak " + account_id + " INCREMENTED " + daily_login_streak);
		} else {
			// resetting streak back to 1
			logger.debug("checkDailyLoginStreak " + account_id + " RESET " + daily_login_streak + " DELTA DAYS " + deltaDay);
			daily_login_streak = 1;
		}

		int daily_login_bonus = (int) daily_login_streak;

		saveDailyLoginStreak(account_id, daily_login_time, daily_login_streak, daily_login_bonus);
	}

	public static void saveDailyLoginStreak(final long account_id, final long daily_login_time, final int daily_login_streak, final int daily_login_bonus) {
		Connection con = null;
		PreparedStatement s = null;
		try {
			con = GameConfig.instance.rdsDatasource.getConnection();
			s = con.prepareStatement("UPDATE `account_info` SET `daily_login_time`=?, `daily_login_streak`=?, `daily_login_bonus`=? WHERE `account_id`=?");
			s.setLong(1, daily_login_time);
			s.setInt(2, daily_login_streak);
			s.setInt(3, daily_login_bonus);
			s.setLong(4, account_id);
			s.executeUpdate();
			s.close();
		} catch (SQLException e) {
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}
	}

	public static int consumeLoginStreakBonus(final GameConfig config, final long account_id) {

		Connection con = null;
		PreparedStatement s = null;
		try {

			int bonus = 0;

			con = config.rdsDatasource.getConnection();

			{
				s = con.prepareStatement("SELECT daily_login_bonus from account_info WHERE account_id = ?");
				s.setLong(1, account_id);
				ResultSet rs = s.executeQuery();

				if (rs.next()) {
					bonus = rs.getInt("daily_login_bonus");
				}
				s.close();
			}

			if (bonus <= 0) {
				return 0;
			}

			--bonus;

			{
				s = con.prepareStatement("UPDATE account_info SET daily_login_bonus=? WHERE account_id = ?");
				s.setInt(1, bonus);
				s.setLong(2, account_id);
				s.executeUpdate();
				s.close();
			}

			return 1;

		} catch (SQLException e) {
			logger.error("consumeLoginStreakBonus: " + e);
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}

		return 0;
	}

	public static boolean hasUnlock(final GameConfig config, final long account_id, final String bst) {
		Connection con = null;
		PreparedStatement s = null;
		try {

			con = config.rdsDatasource.getConnection();

			{
				s = con.prepareStatement("SELECT unlock_time, unlock_duration from unlocks WHERE account_id = ? AND unlock_id = ?");
				s.setLong(1, account_id);
				s.setString(2, bst);
				ResultSet rs = s.executeQuery();

				if (rs.next()) {
					final long unlock_time = rs.getLong("unlock_time");
					final long unlock_duration = rs.getLong("unlock_duration");
					if (unlock_duration <= 0) {
						return true;
					}

					final long now = System.currentTimeMillis();
					return (unlock_time + unlock_duration) > now;
				}
				s.close();
			}

		} catch (SQLException e) {
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}

		return false;
	}

	public static EntityDef loadRosterUnit(final long account_id, final String unit_id) throws SQLException {

		EntityDef unit = null;
		Connection con = null;
		PreparedStatement ps = null;
		final String key = EntityDef.getUnitKey(account_id, unit_id);
		try {
			con = GameConfig.instance.rdsDatasource.getConnection();
			ps = con.prepareStatement("SELECT * FROM unit_roster WHERE unit_key=?");
			ps.setString(1, key);
			final ResultSet rs = ps.executeQuery();

			if (rs.next()) {
				unit = new EntityDef(rs, GameConfig.instance);
			}

			rs.close();
			ps.close();
		} catch (SQLException e) {
			e.printStackTrace();
			throw e;
		} finally {
			DbHelper.cleanup(con, ps);
		}

		return unit;
	}

	public static int loadRosterCount(final long account_id) throws SQLException {

		Connection con = null;
		PreparedStatement ps = null;

		try {
			con = GameConfig.instance.rdsDatasource.getConnection();
			ps = con.prepareStatement("SELECT count(*) FROM unit_roster WHERE account_id=?");
			ps.setLong(1, account_id);
			final ResultSet rs = ps.executeQuery();

			if (rs.next()) {
				return rs.getInt(1);
			}

			rs.close();
			ps.close();
		} catch (SQLException e) {
			e.printStackTrace();
			throw e;
		} finally {
			DbHelper.cleanup(con, ps);
		}

		return 0;
	}

	public static int loadRenown(final long account_id) throws SQLException {

		Connection con = null;
		PreparedStatement ps = null;

		try {
			con = GameConfig.instance.rdsDatasource.getConnection();
			ps = con.prepareStatement("SELECT account_renown FROM account_info WHERE account_id=?");
			ps.setLong(1, account_id);
			final ResultSet rs = ps.executeQuery();

			if (rs.next()) {
				return rs.getInt("account_renown");
			}

			ps.close();
		} catch (SQLException e) {
			logger.error(ps);
			e.printStackTrace();
			throw e;
		} finally {
			DbHelper.cleanup(con, ps);
		}

		return 0;
	}

	public static int loadRosterRows(final long account_id) throws SQLException {

		Connection con = null;
		PreparedStatement ps = null;

		try {
			con = GameConfig.instance.rdsDatasource.getConnection();
			ps = con.prepareStatement("SELECT roster_rows FROM account_info WHERE account_id=?");
			ps.setLong(1, account_id);
			final ResultSet rs = ps.executeQuery();

			if (rs.next()) {
				return rs.getInt("roster_rows");
			}

			ps.close();
		} catch (SQLException e) {
			e.printStackTrace();
			throw e;
		} finally {
			DbHelper.cleanup(con, ps);
		}

		return 0;
	}

	public static void saveRosterRows(final long account_id, final int roster_rows) throws SQLException {

		Connection con = null;
		PreparedStatement ps = null;

		try {
			con = GameConfig.instance.rdsDatasource.getConnection();
			ps = con.prepareStatement("UPDATE account_info SET roster_rows=? WHERE account_id=?");
			ps.setInt(1, roster_rows);
			ps.setLong(2, account_id);
			ps.executeUpdate();

			ps.close();
		} catch (SQLException e) {
			e.printStackTrace();
			throw e;
		} finally {
			DbHelper.cleanup(con, ps);
		}
	}

	public static void saveTutorialCompleted(final long account_id) throws SQLException {

		Connection con = null;
		PreparedStatement ps = null;

		try {
			con = GameConfig.instance.rdsDatasource.getConnection();
			ps = con.prepareStatement("UPDATE account_info SET completed_tutorial=1 WHERE account_id=?");
			ps.setLong(1, account_id);
			ps.executeUpdate();

			ps.close();
		} catch (SQLException e) {
			e.printStackTrace();
			throw e;
		} finally {
			DbHelper.cleanup(con, ps);
		}
	}

}
