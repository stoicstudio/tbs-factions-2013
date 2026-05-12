package tbs.srv.web;

import java.io.IOException;

import tbs.srv.util.MsgSystem;
import tbs.srv.util.RabbitConfig;
import tbs.srv.util.SystemMsg;

import com.rabbitmq.client.AMQP;
import com.rabbitmq.client.AMQP.Queue.DeclareOk;
import com.rabbitmq.client.Channel;
import com.rabbitmq.client.Consumer;
import com.rabbitmq.client.DefaultConsumer;
import com.rabbitmq.client.Envelope;

public class SystemMsgListener {

	public SystemMsgListener(RabbitConfig _rabbit) throws IOException {
		final Channel channel = _rabbit.createChannel(this);

		// DeclareO
		final DeclareOk ok = channel.queueDeclare();
		final Consumer consumer = new SessionMsgConsumer(channel);
		channel.queueBind(ok.getQueue(), "amq.fanout", SystemMsgSystem.KEY);
		channel.basicConsume(ok.getQueue(), true, consumer);
	}

	class SessionMsgConsumer extends DefaultConsumer {

		public SessionMsgConsumer(Channel channel) {
			super(channel);
		}

		@Override
		public void handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties, byte[] body) throws IOException {
			final SystemMsg msg = (SystemMsg) MsgSystem.parseResponseConsume(body, properties, consumerTag);
			WebConfig.instance.systemMessage.setSystemMessage(msg.msg, false);
		}
	}

}
