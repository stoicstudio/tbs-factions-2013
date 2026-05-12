package tbs.srv.db.models;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.concurrent.atomic.AtomicInteger;

import javax.sql.DataSource;

import org.apache.log4j.Logger;

import tbs.srv.auth.AccountData;
import tbs.srv.battle.BattleSystem;
import tbs.srv.battle.data.client.BattleAbortData;
import tbs.srv.data.ClientConfigData;
import tbs.srv.db.DbHelper;
import tbs.srv.util.CurrencyData;
import tbs.srv.util.FriendSystem;
import tbs.srv.util.GameConfig;
import tbs.srv.util.LobbySystem;
import tbs.srv.util.MsgSystem;
import tbs.srv.util.RabbitConfig;
import tbs.srv.util.SteamUserLoadMsg;
import tbs.srv.util.steam.Steam;
import tbs.srv.web.WebConfig;

import com.newrelic.api.agent.NewRelic;
import com.newrelic.api.agent.Trace;
import com.rabbitmq.client.Channel;

public class SessionData {

	private static final Logger logger = Logger.getLogger(SessionData.class.getSimpleName());

	public static final AtomicInteger sessionCount = new AtomicInteger();

	public String display_name;
	public long session_date;
	private long session_key;
	public long account_id;
	public long keepalive_date;
	public int login_count;

	private static long lastUpdatedSessionCountTime = System.currentTimeMillis();
	private static long SESSION_COUNT_UPDATE_TIME = 30000;

	public static String EXCHANGE = "session";

	synchronized public static int getSessionCount(DataSource ds) {
		final long time = System.currentTimeMillis();
		final long delta = time - lastUpdatedSessionCountTime;

		if (delta > SESSION_COUNT_UPDATE_TIME) {
			logger.debug("SessionData.getSessionCount REFRESHING");
			Connection con = null;
			Statement s = null;
			try {
				con = ds.getConnection();
				s = con.createStatement();
				ResultSet rs = s.executeQuery("SELECT COUNT(*) FROM session");
				rs.next();
				final int count = rs.getInt(1);
				sessionCount.set(count);
				s.close();

			} catch (SQLException e) {
				logger.error("SessionData.save :" + e);
				e.printStackTrace();
			} finally {
				DbHelper.cleanup(con, s);
			}

			lastUpdatedSessionCountTime = time;
		}

		return sessionCount.get();
	}

	public SessionData() {
		session_date = System.currentTimeMillis();
		keepalive_date = session_date + GameConfig.instance.SESSION_TIMEOUT_SECS * 1000;
	}

	public SessionData(ResultSet rs) throws SQLException {

		session_key = rs.getLong("session_key");
		account_id = rs.getLong("account_id");
		display_name = rs.getString("display_name");
		session_date = rs.getLong("session_date");
		keepalive_date = rs.getLong("keepalive_date");
		login_count = rs.getInt("login_count");
	}

	public long getSessionKey() {
		return session_key;
	}

	public String getSessionKeyString() {
		return getSessionKeyString(session_key);
	}

	public static String getSessionKeyString(final long session_key) {
		return Long.toString(session_key, 16);
	}

	public String toString() {
		return Long.toString(account_id) + "/" + display_name + "/" + session_key;
	}

	public boolean isValid() {
		return session_key != 0;
	}

	public void maybeTouch(DataSource ds) {
		final long remainingMs = keepalive_date - System.currentTimeMillis();
		final long touchThreshold = (GameConfig.instance.SESSION_TIMEOUT_SECS * 1000) / 2;
		if (remainingMs < touchThreshold) {
			touch(ds);
		}
	}

	public void touch(DataSource ds) {

		keepalive_date = System.currentTimeMillis() + (GameConfig.instance.SESSION_TIMEOUT_SECS * 1000);

		Connection con = null;
		PreparedStatement s = null;
		try {
			con = ds.getConnection();
			s = con.prepareStatement("UPDATE session SET `keepalive_date` = ? WHERE `session_key` = ?");
			s.setLong(1, keepalive_date);
			s.setLong(2, session_key);
			s.executeUpdate();
			s.close();

		} catch (SQLException e) {
			logger.error("SessionData.save :" + e);
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}
	}

	@Trace
	private static int incrementSessionCount() {
		return sessionCount.incrementAndGet();
	}

	@Trace
	public static SessionData generate(GameConfig config, AccountData account, final String ip, ClientConfigData ccd, final int login_count) throws IOException {
		SessionData session = new SessionData();
		session.account_id = account.account_id;
		session.display_name = account.display_name;
		session.login_count = login_count;

		// TODO make this non-collidable!!!
		int r = (int) (Math.random() * Integer.MAX_VALUE);
		int b = (int) (Math.random() * 32);
		// keep them positive just for readability and formatting
		session.session_key = Math.abs(Long.rotateRight(account.account_id, b) | r);

		incrementSessionCount();

		stopUser(config, account.account_id);
		if (!session.save(config.rdsDatasource, ip, ccd)) {
			return null;
		}

		if (account.steam_id != 0) {
			if (!session.updateSteamUserInfo(config, account.steam_id, ccd.client_language)) {
				session.stop(config, false);
				return null;
			}
		}

		logger.debug("Pre-Purging user queue " + account.account_id);
		GameConfig.instance.msg.purgeUser(account.account_id);

		WebConfig.instance.putSession(session);

		WebConfig.instance.chat.getRoom(LobbySystem.getChatRoomId(session.account_id), true).addMember(account.account_id, account.display_name);

		WebConfig.instance.chat.sessionStarted(session.account_id, session.display_name);

		FriendSystem.notifyOnline(WebConfig.instance.rabbit, session.account_id, true);

		final SessionStartedData msg = new SessionStartedData(session.session_key, account.account_id);
		WebConfig.instance.msg.send("amq.direct", msg, MsgSystem.ZIP, SessionStartedData.KEY);

		logger.info("generate " + session);

		return session;
	}

	@Trace
	private boolean save(DataSource ds, final String ipaddress, final ClientConfigData ccd) {

		Connection con = null;
		PreparedStatement ps = null;
		try {
			con = ds.getConnection();

			ps = con.prepareStatement("INSERT INTO session (session_key,account_id,session_date,display_name,keepalive_date,login_count) VALUES (?,?,?,?,?,?)");
			ps.setLong(1, session_key);
			ps.setLong(2, account_id);
			ps.setLong(3, session_date);
			ps.setString(4, display_name);
			ps.setLong(5, keepalive_date);
			ps.setInt(6, login_count);
			ps.executeUpdate();
			ps.close();

			ps = con.prepareStatement("INSERT INTO session_history (session_key, account_id, display_name, session_start, login_count, ipaddress, client_language, os, screen_w, screen_h, os_language) VALUES (?,?,?,?,?,?,?,?,?,?,?)");

			int index = 0;
			ps.setLong(++index, session_key);
			ps.setLong(++index, account_id);
			ps.setString(++index, display_name);
			ps.setLong(++index, session_date);
			ps.setInt(++index, login_count);
			ps.setString(++index, ipaddress);
			ps.setString(++index, ccd.client_language);
			ps.setString(++index, ccd.os);
			ps.setInt(++index, ccd.screen_width);
			ps.setInt(++index, ccd.screen_height);
			ps.setString(++index, ccd.os_language);

			ps.executeUpdate();
			ps.close();

		} catch (SQLException e) {
			e.printStackTrace();
			return false;
		} finally {
			DbHelper.cleanup(con, ps);
		}

		return true;
	}

	@Trace
	public static void stopUser(GameConfig config, final long userId) throws IOException {

		Connection con = null;
		Statement s = null;
		ArrayList<SessionData> olds = null;
		try {
			con = config.rdsDatasource.getConnection();
			{
				s = con.createStatement();
				final String query = "SELECT * FROM session WHERE `account_id` = " + userId;
				final ResultSet rs = s.executeQuery(query);
				while (rs.next()) {
					final SessionData sd = new SessionData(rs);
					if (olds == null) {
						olds = new ArrayList<SessionData>();
					}
					olds.add(sd);
				}
				s.close();
			}
		} catch (SQLException e) {
			logger.error("stopUser :" + e);
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}

		if (olds != null) {
			for (SessionData sd : olds) {
				try {
					logger.info("stopUser " + sd);
					sd.stop(config, true);
				} catch (Exception e) {
					e.printStackTrace();
				}
			}
		}

	}

	private static void notifyExpiry(GameConfig config, final long session_key, final long account_id) {
		if (WebConfig.instance != null) {
			WebConfig.instance.removeSession(session_key);
		}
		logger.info("Expiring " + account_id + "/" + getSessionKeyString(session_key));

		FriendSystem.notifyOnline(config.rabbit, account_id, false);

		// if we are canceling, we don't know the battle id
		BattleSystem.send(new BattleAbortData(account_id, (String) null, 0));

		config.msg.send(EXCHANGE, new SessionExpiryData(session_key, account_id), false, "");
	}

	private void cleanupRabbit(final GameConfig config, final long account_id) {
		try {
			Channel channel = config.rabbit.createTemporaryChannel("SessionData.cleanupRabbit_" + account_id, RabbitConfig.Consume.NO);
			final String q = MsgSystem.getUserQueue(account_id);
			// channel.queuePurge(q);
			channel.queueDelete(q);
			// channel.queueDelete(q);
			channel.close();
		} catch (Exception exp) {
			logger.error("cleanupRabbit FAILED for user " + account_id + ": " + exp);
			// exp.printStackTrace();
		}
	}

	@Trace
	public void stop(GameConfig config, final boolean timeout) throws IOException {

		logger.info("stop " + this);

		config.vs.cancel(account_id, 0);

		UserData.checkDailyLoginStreak(account_id, true);
		UserData.touchLastOnline(account_id);

		config.chat.sessionEnded(account_id, display_name);

		LobbySystem.terminateSession(config, account_id, display_name);

		cleanupRabbit(config, account_id);

		notifyExpiry(config, session_key, account_id);

		Connection con = null;
		PreparedStatement s = null;
		try {
			con = config.rdsDatasource.getConnection();
			s = con.prepareStatement("DELETE FROM session WHERE `session_key` = ?");
			s.setLong(1, session_key);
			s.executeUpdate();
			s.close();

			s = con.prepareStatement("UPDATE session_history SET session_end=?, session_timeout=? WHERE session_key=?");
			s.setLong(1, Math.min(keepalive_date, System.currentTimeMillis()));
			s.setBoolean(2, timeout);
			s.setLong(3, session_key);
			s.executeUpdate();
			s.close();

		} catch (SQLException e) {
			logger.error("stop: " + e);
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}

		sessionCount.decrementAndGet();

	}

	public static SessionData load(DataSource ds, final long key) {
		Connection con = null;
		Statement s = null;
		try {

			final long NOW = System.currentTimeMillis();
			con = ds.getConnection();
			s = con.createStatement();

			final String query = "SELECT * FROM session WHERE `session_key` = " + key + " AND `keepalive_date` > " + NOW;
			ResultSet rs = s.executeQuery(query);
			rs.beforeFirst();

			if (rs.next()) {
				return new SessionData(rs);
			}

		} catch (SQLException e) {
			logger.error("SessionData.load: " + e);
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}

		return null;
	}

	public static SessionData loadUserSession(DataSource ds, final long userid) {
		Connection con = null;
		PreparedStatement s = null;
		try {
			final long NOW = System.currentTimeMillis();
			con = ds.getConnection();
			s = con.prepareStatement("SELECT * FROM session WHERE `account_id` = ?  AND `keepalive_date` > ?");
			s.setLong(1, userid);
			s.setLong(2, NOW);
			ResultSet rs = s.executeQuery();
			rs.beforeFirst();

			if (rs.next()) {
				return new SessionData(rs);
			}

		} catch (SQLException e) {
			logger.error("SessionData.loadUser: " + e);
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}

		return null;
	}

	public static void expireSessions(GameConfig config, final boolean force) {
		// performed on the worker

		ArrayList<SessionData> olds = null;

		final long NOW = force ? Long.MAX_VALUE : System.currentTimeMillis();

		Connection con = null;
		Statement s = null;
		try {
			con = config.rdsDatasource.getConnection();

			{
				s = con.createStatement();
				String query = "SELECT * FROM session WHERE `keepalive_date` <= " + NOW;
				final ResultSet rs = s.executeQuery(query);

				while (rs.next()) {

					final SessionData sd = new SessionData(rs);
					if (olds == null) {
						olds = new ArrayList<SessionData>();
					}
					olds.add(sd);
				}

				s.close();
			}

		} catch (SQLException e) {
			logger.error("SessionData.save: " + e);
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}

		if (olds != null) {
			for (SessionData sd : olds) {
				try {
					logger.info("expireSessions OLD " + sd + " timeout=" + (NOW - sd.keepalive_date) / 1000);
					sd.stop(config, true);
				} catch (Exception e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
			}
		}
	}

	public static boolean persistSteamUserInfo(final long account_id, final long session_key, final Steam.ISteamMicroTxn.SteamUserInfo sui) {
		Connection con = null;
		PreparedStatement ps = null;
		try {
			con = GameConfig.instance.rdsDatasource.getConnection();
			ps = con.prepareStatement("UPDATE session_history SET state=?, country=?, currency=? WHERE session_key=?");

			int index = 0;
			ps.setString(++index, sui.state);
			ps.setString(++index, sui.country);
			ps.setString(++index, sui.currency);
			ps.setLong(++index, session_key);

			ps.executeUpdate();
			ps.close();

		} catch (SQLException e) {
			logger.error("updateSteamUserInfo Failed for steamid=" + sui.steamid);
			e.printStackTrace();
			return false;
		} finally {
			DbHelper.cleanup(con, ps);
		}

		final CurrencyData cd = new CurrencyData(sui.currency);
		GameConfig.instance.msg.send("", cd, MsgSystem.ZIP, MsgSystem.getUserQueue(account_id));

		return true;

	}

	public boolean updateSteamUserInfo(final GameConfig config, final long steam_id, final String language) {

		final SteamUserLoadMsg msg = new SteamUserLoadMsg(account_id, session_key, steam_id, language);
		return config.msg.send("amq.direct", msg, MsgSystem.ZIP, SteamUserLoadMsg.KEY);
	}

	public void setSteamOverlay(final boolean steamOverlay) {
		Connection con = null;
		PreparedStatement ps = null;
		try {
			con = GameConfig.instance.rdsDatasource.getConnection();
			ps = con.prepareStatement("UPDATE session_history SET steam_overlay=? WHERE session_key=? AND steam_overlay IS NULL");

			int index = 0;
			ps.setBoolean(++index, steamOverlay);
			ps.setLong(++index, session_key);

			ps.executeUpdate();
			ps.close();

		} catch (SQLException e) {
			logger.error("setSteamOverlay Failed for sessionKey=" + session_key);
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, ps);
		}

	}

	public Steam.ISteamMicroTxn.SteamUserInfo getSteamUserInfo(final DataSource ds) {
		Connection con = null;
		PreparedStatement ps = null;
		try {
			con = ds.getConnection();
			ps = con.prepareStatement(//
			"SELECT session_history.state, session_history.country, session_history.currency, session_history.client_language, auth_account.steam_id, session_history.ipaddress "
					+ //
					"FROM session_history JOIN auth_account ON session_history.account_id = auth_account.account_id WHERE session_key=?");

			int index = 0;
			ps.setLong(++index, session_key);

			final ResultSet rs = ps.executeQuery();

			final Steam.ISteamMicroTxn.SteamUserInfo sui = new Steam.ISteamMicroTxn.SteamUserInfo();
			if (rs.next()) {
				sui.state = rs.getString("state");
				sui.country = rs.getString("country");
				sui.currency = rs.getString("currency");
				sui.language = rs.getString("client_language");
				sui.steamid = rs.getLong("steam_id");
				sui.ipaddress = rs.getString("ipaddress");
				return sui;
			}

		} catch (SQLException e) {
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, ps);
		}

		return null;
	}

	public static void recordSessionConcurrency() {
		final int[] cc = getSessionConcurrency();
		NewRelic.recordMetric("Custom/session/count", cc[0]);
		NewRelic.recordMetric("Custom/session/first", cc[1]);
	}

	public static int[] getSessionConcurrency() {
		Statement s = null;
		Connection con = null;
		int[] cc = new int[2];
		try {
			con = GameConfig.instance.rdsDatasource.getConnection();

			{
				s = con.createStatement();
				final ResultSet rs = s.executeQuery("SELECT count(*), count(IF(login_count=1, session_key, NULL)) from session");

				if (rs.next()) {					
					cc[0] = rs.getInt(1);
					cc[1] = rs.getInt(2);
				}
				s.close();
			}
		} catch (SQLException e) {
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}
		return cc;
	}

	public static Long[] getSessionAccountIds() {

		final HashSet<Long> account_ids = new HashSet<Long>();

		Connection con = null;
		PreparedStatement s = null;

		try {
			con = GameConfig.instance.rdsDatasource.getConnection();

			{
				s = con.prepareStatement("select account_id from session");
				final ResultSet rs = s.executeQuery();
				while (rs.next()) {
					account_ids.add(rs.getLong(1));
				}
				rs.close();
				s.close();
			}
		} catch (SQLException e) {
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}

		return account_ids.toArray(new Long[account_ids.size()]);
	}

}
