package tbs.srv.worker;

import java.io.IOException;
import java.util.HashSet;

import org.apache.log4j.Logger;

import tbs.srv.data.LeaderboardData;
import tbs.srv.data.LeaderboardType;
import tbs.srv.data.TourneyDef;
import tbs.srv.util.GameConfig;
import tbs.srv.util.LeaderboardDirtyData;
import tbs.srv.util.MsgSystem;
import tbs.srv.util.Tourney;

import com.rabbitmq.client.AMQP;
import com.rabbitmq.client.Channel;
import com.rabbitmq.client.DefaultConsumer;
import com.rabbitmq.client.Envelope;

public class LeaderboardWorker extends BaseWorker {

	private static final String QUEUE = "q_leaderboard";
	private static final Logger logger = Logger.getLogger(LeaderboardWorker.class.getSimpleName());

	private HashSet<Integer> dirtyTourneyIds = new HashSet<Integer>();

	private static final long UPDATE_SEC = 30;

	public LeaderboardWorker(GameConfig config) throws IOException {
		super(logger, config, UPDATE_SEC * 1000);
	}

	synchronized private void handleDirty(final LeaderboardDirtyData data) {
		dirtyTourneyIds.add(data.tourney_id);
	}

	private void dirtyStart() {
		dirtyTourneyIds.add(0);

		for (TourneyDef td : GameConfig.instance.tourney_defs.defs) {
			final Tourney ct = Tourney.get(td.name, false);
			final Tourney pt = Tourney.get(td.name, true);

			if (ct != null) {
				dirtyTourneyIds.add(ct.tourney_id);
			}

			if (pt != null) {
				dirtyTourneyIds.add(pt.tourney_id);
			}
		}

		runWorker(0);
	}

	@Override
	protected void startWorker() throws IOException {

		dirtyStart();

		final Channel channel = config.rabbit.createChannel(this);
		channel.queueDeclare(QUEUE, true, false, false, null);
		channel.queueBind(QUEUE, "amq.direct", LeaderboardDirtyData.KEY);

		channel.basicConsume(QUEUE, true, "leaderboard_consumer", new DefaultConsumer(channel) {
			@Override
			public void handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties, byte[] body) throws IOException {

				final Object data = MsgSystem.parseResponseConsume(body, properties, consumerTag);

				if (data instanceof LeaderboardDirtyData) {
					handleDirty((LeaderboardDirtyData) data);
					return;
				}

				logger.error("handleDelivery unknown msg " + data);
			}
		});

	}

	@Override
	synchronized protected void runWorker(long deltaMs) {

		if (dirtyTourneyIds.isEmpty()) {
			return;
		}

		LeaderboardData.cacheLeaderboards(dirtyTourneyIds.toArray(new Integer[dirtyTourneyIds.size()]), LeaderboardType.values());
		dirtyTourneyIds.clear();

	}

	@Override
	protected void stopWorker() {

	}
}
