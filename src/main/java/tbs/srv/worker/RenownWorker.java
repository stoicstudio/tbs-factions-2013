package tbs.srv.worker;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import org.apache.log4j.Logger;

import tbs.srv.db.DbHelper;
import tbs.srv.util.GameConfig;
import tbs.srv.util.ModifyRenownData;
import tbs.srv.util.MsgSystem;
import tbs.srv.util.RenownMsg;
import tbs.srv.util.RenownReason;
import tbs.srv.util.RenownSystem;

import com.newrelic.api.agent.NewRelic;
import com.rabbitmq.client.AMQP;
import com.rabbitmq.client.Channel;
import com.rabbitmq.client.DefaultConsumer;
import com.rabbitmq.client.Envelope;

public class RenownWorker extends BaseWorker {

	private static final String QUEUE = "q_renown";
	private static final Logger logger = Logger.getLogger(RenownWorker.class.getSimpleName());

	//

	public RenownWorker(GameConfig config) throws IOException {
		super(logger, config, 0);

	}

	private boolean handleModifyRenown(final ModifyRenownData data) {

		Connection con = null;
		PreparedStatement ps = null;
		try {
			con = config.rdsDatasource.getConnection();

			con.setAutoCommit(false);

			int total = 0;

			{
				ps = con.prepareStatement("SELECT account_renown FROM account_info WHERE account_id=?");
				ps.setLong(1, data.user);
				ResultSet rs = ps.executeQuery();
				if (rs.next()) {
					total = rs.getInt("account_renown");
				} else {
					logger.info("User " + data.user + " has no account_info, skipping.");
					con.setAutoCommit(true);
					return true;
				}
				ps.close();
			}

			if (data.reset) {
				if (total > 0) {
					logger.info("MODIFY RENOWN RESETTING " + data.user + " " + total);
				}
				total = 0;
			}

			total += data.delta;

			{
				ps = con.prepareStatement("INSERT INTO `renown` (`account_id`, renown_delta, renown_total, renown_reason, renown_note, renown_time) VALUES (?,?,?,?,?,?)");

				int index = 0;

				ps.setLong(++index, data.user);
				ps.setInt(++index, data.delta);
				ps.setInt(++index, total);
				ps.setString(++index, data.reason.name());
				ps.setString(++index, data.note);
				ps.setLong(++index, System.currentTimeMillis());
				ps.executeUpdate();
				ps.close();
			}

			ps = con.prepareStatement("UPDATE `account_info` SET account_renown=? WHERE account_id=?");
			int index = 0;
			ps.setInt(++index, total);
			ps.setLong(++index, data.user);
			ps.executeUpdate();
			ps.close();

			con.commit();
			con.setAutoCommit(true);

			logger.info("MODIFY RENOWN user=" + data.user + " delta=" + data.delta + " total=" + total + " reason=" + data.reason + " note=" + data.note);

			config.msg.send("", new RenownMsg(data.user, total), MsgSystem.ZIP, MsgSystem.getUserQueue(data.user));

		} catch (SQLException e) {
			logger.error("MODIFY RENOWN FAILED: " + e);
			e.printStackTrace();
			return false;
		} finally {
			DbHelper.cleanup(con, ps);
		}

		if (data.reason == RenownReason.IAP || data.reason == RenownReason.ADMIN) {
			NewRelic.incrementCounter("Custom/renown/total/" + data.reason.name(), data.delta);
		} else if (data.delta > 0) {
			NewRelic.incrementCounter("Custom/renown/faucets/" + data.reason.name(), data.delta);
			NewRelic.incrementCounter("Custom/renown/total/faucet", data.delta);
		} else {
			NewRelic.incrementCounter("Custom/renown/sinks/" + data.reason.name(), -data.delta);
			NewRelic.incrementCounter("Custom/renown/total/sink", -data.delta);
		}

		return true;

	}

	@Override
	protected void startWorker() throws IOException {
		final Channel channel = config.rabbit.createChannel(this);
		channel.queueDeclare(QUEUE, true, false, false, null);
		channel.queueBind(QUEUE, RenownSystem.EXCHANGE, "");

		channel.basicConsume(QUEUE, true, "renown_consumer", new DefaultConsumer(channel) {
			@Override
			public void handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties, byte[] body) throws IOException {

				Object data = MsgSystem.parseResponseConsume(body, properties, consumerTag);

				if (data instanceof ModifyRenownData) {
					if (!handleModifyRenown((ModifyRenownData) data)) {

					}
				}
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
