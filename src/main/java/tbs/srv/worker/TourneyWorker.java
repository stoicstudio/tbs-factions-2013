package tbs.srv.worker;

import java.io.IOException;

import org.apache.log4j.Logger;

import tbs.srv.data.TourneyDef;
import tbs.srv.util.GameConfig;
import tbs.srv.util.MsgSystem;
import tbs.srv.util.Tourney;
import tbs.srv.util.TourneySendToUserMsg;

import com.rabbitmq.client.AMQP;
import com.rabbitmq.client.Channel;
import com.rabbitmq.client.DefaultConsumer;
import com.rabbitmq.client.Envelope;

public class TourneyWorker extends BaseWorker {

	private boolean stopping = false;

	private static final Logger logger = Logger.getLogger(TourneyWorker.class.getSimpleName());
	private static final String QUEUE = "q_tourney";

	//

	public TourneyWorker(GameConfig config) throws IOException {
		super(logger, config, 0);
	}

	@Override
	protected void startWorker() throws IOException {

		logger.info("startWorker iterating tourney defs: " + GameConfig.instance.tourney_defs.defs.length);

		for (TourneyDef def : GameConfig.instance.tourney_defs.defs) {

			logger.info("startWorker processing " + def);

			if (def.meta) {
				logger.info("startWorker skipping meta tourney " + def);
				continue;
			}

			final Tourney t = Tourney.get(def.name, false);
			if (t == null || t.ended) {
				// schedule a new one. meta parents will get created
				scheduleTourneyDefStart(def);
			} else if (t.started) {
				scheduleTourneyEnd(t);
			} else {
				checkTourneyStart(t);
			}
		}

		final Channel channel = config.rabbit.createChannel(this);
		channel.queueDeclare(QUEUE, false, false, true, null);
		channel.queueBind(QUEUE, "amq.direct", TourneySendToUserMsg.KEY);

		channel.basicConsume(QUEUE, true, "tourney_consumer", new DefaultConsumer(channel) {
			@Override
			public void handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties, byte[] body) throws IOException {

				Object data = MsgSystem.parseResponseConsume(body, properties, consumerTag);

				if (data instanceof TourneySendToUserMsg) {
					handleTourneySendToUserMsg((TourneySendToUserMsg) data);
				}
			}
		});
	}

	private void handleTourneySendToUserMsg(final TourneySendToUserMsg msg) {
		Tourney.sendStateToPlayer(msg.account_id, msg.request_time);
	}

	private void scheduleTourneyDefStart(final TourneyDef def) {
		logger.info("scheduleTourneyDefStart BEGIN " + def);

		final Tourney t = new Tourney();

		t.create(def);

		scheduleTourneyStart(t);
	}

	private void scheduleTourneyStart(final Tourney t) {

		logger.info("scheduleTourneyStart BEGIN " + t);

		new Thread() {
			@Override
			public void run() {
				try {
					final long wait = Math.max(0, t.start_time - System.currentTimeMillis());
					logger.info("scheduleTourneyStart WAIT " + wait + " ms " + (wait / (1000 * 60 * 60)) + " hours for " + t);
					Thread.sleep(wait);
					if (!stopping) {
						t.start();
						scheduleTourneyEnd(t);
					}
				} catch (InterruptedException e) {
					logger.error("failed to execute tourney start schedule for " + t + ":  " + e);
					e.printStackTrace();
				}
			}
		}.start();
	}

	private void scheduleTourneyEnd(final Tourney t) {

		logger.info("scheduleTourneyEnd BEGIN " + t);

		t.broadcast();

		new Thread() {
			@Override
			public void run() {
				try {
					final long wait = Math.max(0, t.end_time - System.currentTimeMillis());
					logger.info("scheduleTourneyEnd WAIT " + wait + " ms " + (wait / (1000 * 60 * 60)) + " hours for " + t);
					Thread.sleep(wait);
					if (!stopping) {
						t.end();
						final TourneyDef def = t.def;
						scheduleTourneyDefStart(def);
					}
				} catch (InterruptedException e) {
					logger.error("failed to execute tourney end schedule for " + t + ":  " + e);
					e.printStackTrace();
				}
			}
		}.start();
	}

	private void checkTourneyStart(final Tourney t) {

		logger.info("checkTourneyStart BEGIN " + t);

		if (!t.started) {
			final long cur = System.currentTimeMillis();
			if (t.start_time < cur) {
				// should have already started, start it!
				t.start();
				scheduleTourneyEnd(t);
			} else {
				scheduleTourneyStart(t);
			}
		}
	}

	@Override
	protected void runWorker(long deltaMs) {
	}

	@Override
	synchronized protected void stopWorker() {
		stopping = true;
	}
}
