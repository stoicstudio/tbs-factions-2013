package tbs.srv.web;

import java.io.IOException;

import org.apache.log4j.Logger;

import tbs.srv.db.models.SessionData;
import tbs.srv.db.models.SessionExpiryData;
import tbs.srv.util.MsgSystem;
import tbs.srv.util.RabbitConfig;

import com.rabbitmq.client.AMQP;
import com.rabbitmq.client.AMQP.Queue.DeclareOk;
import com.rabbitmq.client.Channel;
import com.rabbitmq.client.Consumer;
import com.rabbitmq.client.DefaultConsumer;
import com.rabbitmq.client.Envelope;
import com.rabbitmq.client.ShutdownSignalException;

public class WebSessionListener {

	public static final Logger logger = Logger.getLogger(WebSessionListener.class.getSimpleName());

	public WebSessionListener(RabbitConfig _rabbit) {
		try {
			final Channel channel = _rabbit.createChannel(this);

			channel.exchangeDeclare(SessionData.EXCHANGE, "fanout");
			// DeclareO
			final DeclareOk ok = channel.queueDeclare();
			final Consumer consumer = new SessionMsgConsumer(channel);
			channel.queueBind(ok.getQueue(), SessionData.EXCHANGE, "");
			channel.basicConsume(ok.getQueue(), true, consumer);
		} catch (Exception exp) {
			logger.error("Failed to ctor: " + exp);
			exp.printStackTrace();
			throw new Error("Failed to ctor WebSessionListener");
		}
	}

	class SessionMsgConsumer extends DefaultConsumer {

		public SessionMsgConsumer(Channel channel) {
			super(channel);
		}

		@Override
		public void handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties, byte[] body) throws IOException {
			try {
				final SessionExpiryData msg = (SessionExpiryData) MsgSystem.parseResponseConsume(body, properties, consumerTag);
				WebConfig.instance.removeSession(msg.session_key);
			} catch (Exception e) {
				logger.error("Failed to process expiry: " + e);
				e.printStackTrace();
			}
		}

		@Override
		public void handleShutdownSignal(String consumerTag, ShutdownSignalException sig) {
			if (!sig.isInitiatedByApplication()) {
				logger.error("handleShutdownSignal: " + sig);
				sig.printStackTrace();
			}
		}

	}

}
