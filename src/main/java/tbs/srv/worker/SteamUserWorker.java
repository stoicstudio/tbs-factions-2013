package tbs.srv.worker;

import java.io.IOException;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import org.apache.log4j.Logger;

import tbs.srv.db.DbHelper;
import tbs.srv.db.models.SessionData;
import tbs.srv.util.GameConfig;
import tbs.srv.util.MsgSystem;
import tbs.srv.util.SteamUserLoadMsg;
import tbs.srv.util.steam.Steam;

import com.rabbitmq.client.AMQP;
import com.rabbitmq.client.Channel;
import com.rabbitmq.client.DefaultConsumer;
import com.rabbitmq.client.Envelope;

public class SteamUserWorker extends BaseWorker {

	private static final Logger logger = Logger.getLogger(SteamUserWorker.class.getSimpleName());

	private static final String QUEUE = "q_steam_user";
	//

	private ExecutorService pool;

	public SteamUserWorker(GameConfig config) {

		super(logger, config, 0);

		pool = Executors.newFixedThreadPool(10);
	}

	private Channel channel;

	@Override
	protected void startWorker() throws IOException {

		if (config.GAME_REBOOTING) {
			// nothing to do
			return;
		}

		if (config.STEAM_API_KEY == null) {
			logger.info("NO STEAM_API_KEY, nothing to do");
			return;
		}

		channel = config.rabbit.createChannel(this);
		channel.queueDeclare(QUEUE, false, false, true, null);
		channel.queueBind(QUEUE, "amq.direct", SteamUserLoadMsg.KEY);

		channel.basicConsume(QUEUE, true, "steam_user_consumer", new DefaultConsumer(channel) {
			@Override
			public void handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties, byte[] body) throws IOException {

				Object data = null;
				try {
					data = MsgSystem.parseResponseConsume(body, properties, consumerTag);

					if (data instanceof SteamUserLoadMsg) {
						handleSteamUserLoadMsg((SteamUserLoadMsg) data);
					}
				} catch (Exception exp) {
					logger.error("handleDelivery fail for " + data + ": " + exp);
				}
			}
		});

		// init steam user info for currently logged in players
		requestCurrentSessionInfos();
	}

	private void requestCurrentSessionInfos() {

		ArrayList<SteamUserLoadMsg> msgs = new ArrayList<SteamUserLoadMsg>();

		Connection con = null;
		Statement s = null;
		try {
			con = config.rdsDatasource.getConnection();

			{
				s = con.createStatement();
				String query = "select session.account_id, session.session_key, steam_id, client_language "
						+ " from session join (session_history, auth_account) "
						+ " on (session.session_key = session_history.session_key AND session.account_id = auth_account.account_id) "
						+ " where country is null OR currency is null";

				final ResultSet rs = s.executeQuery(query);

				while (rs.next()) {

					long account_id = rs.getLong(1);
					long session_key = rs.getLong(2);
					long steam_id = rs.getLong(3);
					String client_language = rs.getString(4);
					SteamUserLoadMsg msg = new SteamUserLoadMsg(account_id, session_key, steam_id, client_language);
					msgs.add(msg);
				}

				s.close();
			}

		} catch (SQLException e) {
			logger.error("SessionData.save: " + e);
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}

		for (SteamUserLoadMsg msg : msgs) {
			logger.info("requestCurrentSessionInfos FRESHENING " + msg);
			handleSteamUserLoadMsg(msg);
		}
	}

	private void handleSteamUserLoadMsg(final SteamUserLoadMsg msg) {
		pool.execute(new Runnable() {
			@Override
			public void run() {
				while (true) {
					if (updateSteamUserInfo(msg)) {
						return;
					}

					logger.warn("Retrying " + msg);

					try {
						Thread.sleep(1000);
					} catch (InterruptedException e) {
						logger.error("Retry INTERRUPTED " + msg);
						return;
					}
				}
			}
		});

	}

	public boolean updateSteamUserInfo(final SteamUserLoadMsg msg) {

		final long start = System.currentTimeMillis();

		logger.info("updateSteamUserinfo START " + msg);

		final Steam.ISteamMicroTxn.SteamUserInfo sui = Steam.ISteamMicroTxn.getUserInfo(msg.steam_id, msg.language);
		if (sui == null) {
			logger.warn("updateSteamUserInfo FAIL getUserInfo " + msg.steam_id);
			return false;
		}

		if (sui.error) {
			if (sui.errorcode == Steam.ISteamMicroTxn.SteamUserInfo.ERROR_CODE_NOT_LOGGED_IN) {
				logger.warn("updateSteamUserInfo FAIL " + msg.steam_id + " not logged in, quitting");
				return true;
			}
		}

		if (!SessionData.persistSteamUserInfo(msg.account_id, msg.session_key, sui)) {
			logger.error("updateSteamUserInfo FAIL persistSteamUserInfo " + msg.steam_id);
			return false;
		}

		final long delta = System.currentTimeMillis() - start;
		logger.info("updateSteamUserInfo OK " + msg + " duration " + delta);

		return true;
	}

	@Override
	protected void stopWorker() {

		if (channel != null) {
			try {
				channel.close();
			} catch (IOException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		}
		pool.shutdownNow();
		pool = null;
	}

	@Override
	protected void runWorker(long deltaMs) throws Exception {
		// nothing to do

	}
}
