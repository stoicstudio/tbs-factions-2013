package tbs.srv.chat;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.HashMap;

import org.apache.log4j.Logger;

import tbs.srv.db.DbHelper;
import tbs.srv.util.GameConfig;
import tbs.srv.util.MsgSystem;

import com.newrelic.api.agent.NewRelic;
import com.newrelic.api.agent.Trace;
import com.rabbitmq.client.AMQP;
import com.rabbitmq.client.Channel;
import com.rabbitmq.client.DefaultConsumer;
import com.rabbitmq.client.Envelope;

public class ChatSystem {
	public static final Logger logger = Logger.getLogger(ChatSystem.class.getSimpleName());
	public static final String ROOM_GLOBAL = "global";

	// public static final String EXCHANGE = "chat";
	private boolean created;
	private boolean zip;
	private boolean authoritative;
	private HashMap<String, ChatRoom> rooms = new HashMap<String, ChatRoom>();
	final public GameConfig config;

	public static final String MONITOR_Q = "q_chat_monitor";

	public static final String EXCHANGE = "chat";

	public ChatSystem(GameConfig _config, boolean zip, boolean authoritative) throws IOException {

		this.config = _config;

		final Channel channel = config.rabbit.createChannel(getClass().getSimpleName());
		channel.exchangeDeclare(EXCHANGE, "direct");
		channel.queueDeclare(MONITOR_Q, false, false, false, null);
		if (authoritative) {
			monitorConsumer = new ChatMonitorConsumer(channel);
			channel.basicConsume(MONITOR_Q, true, monitorConsumer);
		}

		this.zip = zip;
		this.authoritative = authoritative;
		create();
	}

	class ChatMonitorConsumer extends DefaultConsumer {
		public ChatMonitorConsumer(final Channel channel) {
			super(channel);
		}

		@Override
		public void handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties, byte[] body) throws IOException {

			// TODO monitor for spamming and disconnect the user if necessary

			// TODO stick this in a log somewhere if appropriate

			try {
				final Object data = MsgSystem.parseResponseConsume(body, properties, consumerTag);

				if (data instanceof ChatMsg) {
					final ChatMsg msg = (ChatMsg) data;
					logger.debug("MONITOR " + msg);

					persistChat(msg);
				}
			} catch (Exception exp) {
				logger.warn("handleDelivery failed: " + exp);
				exp.printStackTrace();
			}
		}
	};

	private ChatMonitorConsumer monitorConsumer;

	private void persistChat(final ChatMsg msg) {
		Connection con = null;
		PreparedStatement s = null;

		try {
			con = config.rdsDatasource.getConnection();

			long session_key = 0;

			s = con.prepareStatement("SELECT `session_key` from `session` where account_id=?");
			s.setLong(1, msg.user);
			final ResultSet rs = s.executeQuery();
			if (rs.next()) {
				session_key = rs.getLong(1);
			}

			s = con.prepareStatement("INSERT INTO chat (session_key, room, chat_time, msg) VALUES (?,?,?,?)");
			int index = 0;
			s.setLong(++index, session_key);
			s.setString(++index, msg.room);
			s.setLong(++index, System.currentTimeMillis());
			s.setString(++index, msg.msg);
			s.executeUpdate();
		} catch (SQLException e) {
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}
	}

	public void create() throws IOException {
		if (created) {
			return;
		}

		// declare global

		getRoom(ROOM_GLOBAL, true);
	}

	public void sendToRoom(final long session_key, long user, String username, String room, String str) throws IOException {
		ChatMsg msg = new ChatMsg(user, room, username, str);
		sendMessage(room, msg);
	}

	public boolean sendMessage(String roomId, ChatMsg msg) throws IOException {

		final String nr = roomId.equals(ROOM_GLOBAL) ? roomId : (roomId.startsWith("lobby_") ? "lobby" : "battle");
		NewRelic.incrementCounter("Custom/chat/send/" + nr);

		final Boolean sent = GameConfig.instance.msg.send(EXCHANGE, msg, zip, roomId);

		if (!sent) {
			logger.error("Failed to sendToRoom [" + roomId + "] " + msg);
			return false;
		}

		return true;
	}

	public ChatRoom getRoom(String roomId, final boolean create) {
		return getRoomInternal(roomId, create, authoritative);
	}

	public ChatRoom getAuthoritativeRoom(String roomId) {
		return getRoomInternal(roomId, true, true);
	}

	public ChatRoom getRoomInternal(String roomId, final boolean create, final boolean room_authority) {
		ChatRoom room = rooms.get(roomId);
		if (room == null || (room_authority && !room.authoritative)) {
			room = new ChatRoom(roomId, config, authoritative || room_authority, create);
			if (create) {
				rooms.put(roomId, room);
			}
		}
		return room;
	}

	@Trace
	public void sessionStarted(long userId, final String display_name) throws IOException {

		// add to global

		getRoom(ROOM_GLOBAL, true).addMember(userId, display_name);
	}

	public void sessionEnded(long userId, final String display_name) {
		// remove from global

		logger.debug("sessionEnded removing from global room " + userId + " " + display_name);
		getRoom(ROOM_GLOBAL, true).removeMember(userId, display_name);
	}

}
