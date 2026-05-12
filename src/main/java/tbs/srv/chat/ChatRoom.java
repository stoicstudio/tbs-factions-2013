package tbs.srv.chat;

import java.io.IOException;

import org.apache.log4j.Logger;

import tbs.srv.util.GameConfig;
import tbs.srv.util.MsgSystem;
import tbs.srv.util.RabbitConfig;

import com.rabbitmq.client.Channel;

public class ChatRoom {

	public static final Logger logger = Logger.getLogger(ChatRoom.class.getSimpleName());

	public String id;

	private boolean created;
	public boolean authoritative;
	public GameConfig config;

	public ChatRoom(final String id, final GameConfig config, boolean authoritative, final boolean doCreate) {
		this.id = id;
		this.config = config;

		this.authoritative = authoritative;
		if (doCreate) {
			create();
		}
	}

	public String toString() {
		return id;
	}

	public void addMember(long userId, final String display_name) {

		if (!id.equals("global")) {
			final ChatRoomMsg crm = new ChatRoomMsg(id, display_name, true, false);
			GameConfig.instance.msg.send(ChatSystem.EXCHANGE, crm, MsgSystem.ZIP, id);
		}

		logger.debug(id + " adding member " + userId);
		final String q = MsgSystem.getUserQueue(userId);
		try {
			final Channel channel = config.rabbit.createTemporaryChannel(this, RabbitConfig.Consume.NO);
			MsgSystem.declareUserQueue(channel, q, false);
			channel.queueBind(q, ChatSystem.EXCHANGE, id);
			channel.close();
		} catch (Exception e) {
			logger.error("binding " + q + " to chat room : " + id + ": " + e);
			e.printStackTrace();
		}

	}

	public void removeMember(long userId, final String display_name) {
		try {

			logger.debug(id + " removing member " + userId);
			final String q = MsgSystem.getUserQueue(userId);
			final Channel channel = config.rabbit.createTemporaryChannel(this, RabbitConfig.Consume.NO);
			channel.queueUnbind(q, ChatSystem.EXCHANGE, id);
			channel.close();

		} catch (Exception e) {
			// logger.error("Failed to remove member " + userId + " from room " + id + ": " + e);
			// e.printStackTrace();
		}

		if (!id.equals("global")) {
			final ChatRoomMsg crm = new ChatRoomMsg(id, display_name, false, true);
			GameConfig.instance.msg.send(ChatSystem.EXCHANGE, crm, MsgSystem.ZIP, id);
		}

	}

	public void create() {
		if (created) {
			return;
		}

		try {
			final Channel c = GameConfig.instance.rabbit.createTemporaryChannel("chat_create_" + id);
			c.queueBind(ChatSystem.MONITOR_Q, ChatSystem.EXCHANGE, id);
			c.close();
		} catch (Exception e) {
			logger.warn("Failed to bind chatroom q: " + e.getMessage());
		}

	}

	public void destroy() throws IOException {
		if (!authoritative) {
			throw new IllegalAccessError();
		}

		logger.debug("Destroying chatroom " + this);
		final Channel channel = config.rabbit.createTemporaryChannel(this, RabbitConfig.Consume.NO);
		channel.queueUnbind(ChatSystem.MONITOR_Q, ChatSystem.EXCHANGE, id);
		channel.close();
		// TODO ensure that all room members are also unbound -- read from db perhaps?
	}
}
