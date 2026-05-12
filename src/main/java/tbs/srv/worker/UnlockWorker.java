package tbs.srv.worker;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import org.apache.log4j.Logger;

import tbs.srv.db.DbHelper;
import tbs.srv.util.GameConfig;
import tbs.srv.util.MsgSystem;
import tbs.srv.util.UnlockData;
import tbs.srv.util.UnlockSystem;

import com.rabbitmq.client.AMQP;
import com.rabbitmq.client.Channel;
import com.rabbitmq.client.DefaultConsumer;
import com.rabbitmq.client.Envelope;

public class UnlockWorker extends BaseWorker {

	private static final String QUEUE = "q_unlock";
	private static final Logger logger = Logger.getLogger(UnlockWorker.class.getSimpleName());

	//

	public UnlockWorker(GameConfig config) throws IOException {
		super(logger, config, 0);
	}

	private boolean handleUnlock(final UnlockData data) {

		logger.info("handleUnlock " + data);
		
		Connection con = null;
		PreparedStatement ps = null;
		try {
			con = config.rdsDatasource.getConnection();

			long cur_duration = 0;
			boolean found = false;

			{
				ps = con.prepareStatement("SELECT * FROM unlocks WHERE account_id=? AND unlock_id=?");
				ps.setLong(1, data.account_id);
				ps.setString(2, data.unlock_id);
				ResultSet rs = ps.executeQuery();
				final long cur = System.currentTimeMillis();
				if (rs.next()) {
					final long unlock_time = rs.getLong("unlock_time");
					cur_duration = rs.getLong("unlock_duration");
					final long elapsed = cur - unlock_time;
					if (data.unlock_duration > 0) {
						final long remainder = Math.max(0, cur_duration - elapsed);
						data.unlock_duration += remainder;
					}
					data.unlock_time = cur;
					found = true;
				} else {
					data.unlock_time = cur;
				}
				ps.close();
			}

			// prevent permanent unlocks from expiring
			if (found && cur_duration <= 0) {
				data.unlock_duration = cur_duration;
			}

			{
				ps = con.prepareStatement("REPLACE INTO unlocks (account_id, unlock_id, unlock_time, unlock_duration) VALUES (?,?,?,?)");
				ps.setLong(1, data.account_id);
				ps.setString(2, data.unlock_id);
				ps.setLong(3, data.unlock_time);
				ps.setLong(4, data.unlock_duration);
				ps.executeUpdate();
				ps.close();
			}

			notifyUser(data);

		} catch (SQLException e) {
			logger.error("handleUnlock FAILED: " + e);
			e.printStackTrace();
			return false;
		} finally {
			DbHelper.cleanup(con, ps);
		}

		return true;
	}

	private void notifyUser(final UnlockData data) {
		try {
			final Channel channel = config.rabbit.createChannel(this);
			MsgSystem.send(channel, "", data, MsgSystem.ZIP, MsgSystem.getUserQueue(data.account_id));
			channel.close();
		} catch (Exception e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}

	@Override
	protected void startWorker() throws IOException {
		final Channel channel = config.rabbit.createChannel(this);
		channel.queueDeclare(QUEUE, true, false, false, null);
		channel.queueBind(QUEUE, "amq.direct", UnlockSystem.KEY);

		channel.basicConsume(QUEUE, true, "unlock_consumer", new DefaultConsumer(channel) {
			@Override
			public void handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties, byte[] body) throws IOException {

				final Object data = MsgSystem.parseResponseConsume(body, properties, consumerTag);

				if (data instanceof UnlockData) {
					if (!handleUnlock((UnlockData) data)) {
						
					}
					
					return;
				}
				
				logger.error("handleDelivery unknown msg " + data);
			}
		});

	}

	@Override
	protected void runWorker(long deltaMs) {
	}

	@Override
	protected void stopWorker() {

	}
}
