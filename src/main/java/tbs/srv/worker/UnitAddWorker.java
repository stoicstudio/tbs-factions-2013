package tbs.srv.worker;

import java.io.IOException;
import java.sql.SQLException;

import org.apache.log4j.Logger;

import tbs.srv.db.models.UserData;
import tbs.srv.util.GameConfig;
import tbs.srv.util.MsgSystem;
import tbs.srv.util.UnitAddData;
import tbs.srv.util.UnitAddSystem;

import com.rabbitmq.client.AMQP;
import com.rabbitmq.client.Channel;
import com.rabbitmq.client.DefaultConsumer;
import com.rabbitmq.client.Envelope;

public class UnitAddWorker extends BaseWorker {

	private static final String QUEUE = "q_unit_add";
	private static final Logger logger = Logger.getLogger(UnitAddWorker.class.getSimpleName());

	//

	public UnitAddWorker(GameConfig config) throws IOException {
		super(logger, config, 0);
	}

	private boolean handleUnitAdd(final UnitAddData data) {

		logger.info("handleUnitAdd " + data);
		
		data.unit.start_date = System.currentTimeMillis();
		final String id = UserData.getNextRosterId(config.rdsDatasource, data.account_id, data.unit.id);
		if (id == null) {
			logger.error("Failed to generate id for " + data.unit);
			return false;
		}

		data.unit.id = id;
		try {
			UserData.saveRosterMember(config.rdsDatasource, data.account_id, data.unit);
		} catch (SQLException e) {
			logger.error("handleUnitAdd failed to add " + data.account_id + " unit " + data.unit);
			return false;
		}
		notifyUser(data);
		return true;
	}

	private void notifyUser(final UnitAddData data) {
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
		
		logger.info("startWorker");
		
		final Channel channel = config.rabbit.createChannel(this);
		channel.queueDeclare(QUEUE, true, false, false, null);
		channel.queueBind(QUEUE, "amq.direct", UnitAddSystem.KEY);

		channel.basicConsume(QUEUE, true, "unit_add_consumer", new DefaultConsumer(channel) {
			@Override
			public void handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties, byte[] body) throws IOException {

				Object data = MsgSystem.parseResponseConsume(body, properties, consumerTag);

				if (data instanceof UnitAddData) {
					handleUnitAdd((UnitAddData) data);
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
