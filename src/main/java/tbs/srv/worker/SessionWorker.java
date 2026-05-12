package tbs.srv.worker;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

import org.apache.log4j.Logger;

import tbs.srv.db.DbHelper;
import tbs.srv.db.models.SessionData;
import tbs.srv.db.models.UserData;
import tbs.srv.util.GameConfig;
import tbs.srv.util.MsgSystem;

import com.rabbitmq.client.Channel;

public class SessionWorker extends BaseWorker {

	private static final Logger logger = Logger.getLogger(SessionWorker.class.getSimpleName());

	//

	final static float timeoutGrace = 1.5f;
	final static int CHECK_MS = (int) (GameConfig.instance.SESSION_TIMEOUT_SECS * 1000 * timeoutGrace);

	long loginStreakCheckTime = 0;

	// check hourly
	final int LOGIN_STREAK_CHECK_MS;

	public SessionWorker(GameConfig config) {

		// at least every 45 seconds
		super(logger, config, Math.min(45, Math.min(config.DAILY_LOGIN_STREAK_MS / 24, CHECK_MS)));
		LOGIN_STREAK_CHECK_MS = config.DAILY_LOGIN_STREAK_MS / 24;
	}

	@Override
	protected void startWorker() {

		if (config.GAME_REBOOTING) {
			logger.info("Expiring all sessions");
			SessionData.expireSessions(WorkerConfig.instance, true);
			deleteRecentRabbitQueues();
		} else {
			touchLoginStreaks();
		}
	}

	private void deleteRecentRabbitQueues() {
		final ArrayList<Long> account_ids = new ArrayList<Long>();
		PreparedStatement s = null;
		Connection con = null;
		try {
			con = config.rdsDatasource.getConnection();

			s = con.prepareStatement("select distinct account_id from session_history order by session_start desc limit 1000");
			final ResultSet rs = s.executeQuery();

			while (rs.next()) {
				final long account_id = rs.getLong("account_id");
				account_ids.add(account_id);
			}
			s.close();

		} catch (SQLException e) {
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}

		for (Long account_id : account_ids) {
			try {
				final Channel channel = config.rabbit.createTemporaryChannel("deleteRecentRabbitQueues");
				final String q = MsgSystem.getUserQueue(account_id);
				channel.queueDelete(q);
				channel.close();
			} catch (Exception e) {
				// TODO Auto-generated catch block
				// e.printStackTrace();
			}
		}
	}

	@Override
	protected void runWorker(long deltaMs) {
		if (config.GAME_REBOOTING) {
			return;
		}

		SessionData.recordSessionConcurrency();

		SessionData.expireSessions(WorkerConfig.instance, false);
		touchLoginStreaks();
	}

	private void touchLoginStreaks() {

		final long cur = System.currentTimeMillis();
		final long delta = cur - loginStreakCheckTime;
		if (delta < LOGIN_STREAK_CHECK_MS) {
			return;
		}

		loginStreakCheckTime = cur;

		final List<Long> sessions = new ArrayList<Long>();
		Statement s = null;
		Connection con = null;
		try {
			con = config.rdsDatasource.getConnection();

			{
				s = con.createStatement();
				final ResultSet rs = s.executeQuery("SELECT account_id FROM session");

				while (rs.next()) {
					final long account_id = rs.getLong("account_id");
					sessions.add(account_id);
				}
				s.close();
			}
		} catch (SQLException e) {
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}

		for (Long session : sessions) {

			UserData.checkDailyLoginStreak(session, true);
		}
	}

	@Override
	protected void stopWorker() {
	}
}
