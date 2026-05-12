package tbs.srv.worker;

import java.io.IOException;
import java.util.Set;

import org.apache.log4j.Logger;

import tbs.srv.auth.AccountData;
import tbs.srv.db.models.SessionStartedData;
import tbs.srv.util.GameConfig;
import tbs.srv.util.MsgSystem;
import tbs.srv.util.steam.Steam;
import tbs.srv.util.steam.SteamDlc;

import com.rabbitmq.client.AMQP;
import com.rabbitmq.client.Channel;
import com.rabbitmq.client.DefaultConsumer;
import com.rabbitmq.client.Envelope;

public class SteamDlcWorker extends BaseWorker {

	private static final String QUEUE = "q_steam_dlc";
	private static final Logger logger = Logger.getLogger(SteamDlcWorker.class.getSimpleName());

	public SteamDlcWorker(GameConfig config) throws IOException {
		super(logger, config, 0);
	}

	@Override
	protected void startWorker() throws Exception {

		final Channel channel = GameConfig.instance.rabbit.createChannel(this);
		logger.debug("ENTER SteamDlcWorker.startWorker()");

		channel.queueDeclare(QUEUE, true, false, false, null);
		channel.queueBind(QUEUE, "amq.direct", SessionStartedData.KEY);

		channel.basicConsume(QUEUE, true, "steam_dlc_consumer", new DefaultConsumer(channel) {
			@Override
			public void handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties, byte[] body) throws IOException {

				logger.debug("ENTER SteamDlcWorker.handleDelivery()");

				final Object data = MsgSystem.parseResponseConsume(body, properties, consumerTag);

				if (data instanceof SessionStartedData) {
					handleSessionStartedData((SessionStartedData) data);
				}
			}

		});

	}

	private void handleSessionStartedData(final SessionStartedData data) {
		updateAllSteamDlc(data.account_id);
	}

	private void updateAllSteamDlc(final long account_id) {
		final long steamid = AccountData.getSteamId(account_id);
		final Integer[] owned_dlc_appids = Steam.SteamUser.getPublisherAppOwnership(steamid);
		if (owned_dlc_appids == null) {
			return;
		}

		final Set<Integer> processed = SteamDlc.getProcessedDlc(account_id);
		for (Integer appid : owned_dlc_appids) {
			if (processed.contains(appid)) {
				// already processed
				continue;
			}

			if (appid == GameConfig.instance.STEAM_APP_ID) {
				continue;
			}

			SteamDlc.processDlc(account_id, appid);
		}
	}

	@Override
	protected void runWorker(long deltaMs) throws Exception {
		// TODO Auto-generated method stub

	}

	@Override
	protected void stopWorker() throws Exception {
		// TODO Auto-generated method stub

	}

}
