package tbs.srv.util;

import org.apache.log4j.Logger;

import tbs.srv.data.FriendOnlineData;
import tbs.srv.data.GameLocationData;

import com.rabbitmq.client.Channel;
import com.rabbitmq.client.MessageProperties;

public class FriendSystem {

	private static final Logger logger = Logger.getLogger(FriendSystem.class.getSimpleName());

	public static final String KEY_COLLECT = "key_friend_collect";
	public static final String KEY_LOCATION = "key_friend_location";
	public static final String KEY_FRIEND_ = "key_friend_";

	public static final boolean ENABLED = true;

	public static void collectFriends(RabbitConfig rabbit, final long account_id) {

		if (!ENABLED) {
			return;
		}

		try {
			final Channel c = GameConfig.instance.rabbit.createTemporaryChannel("collectFriends_" + account_id);
			c.basicPublish("amq.direct", KEY_COLLECT, MessageProperties.TEXT_PLAIN, Long.toString(account_id).getBytes());
			c.close();
		} catch (Exception e) {
			logger.warn("Failed to publish collectFriends: " + e.getLocalizedMessage());

		}
	}

	public static void notifyLocation(RabbitConfig rabbit, final long account_id, final String location) {

		if (!ENABLED) {
			return;
		}

		logger.debug("notifyLocation " + account_id + " " + location);

		final GameLocationData gld = new GameLocationData();
		gld.account_id = account_id;
		gld.location = location;

		GameConfig.instance.msg.send("amq.direct", gld, MsgSystem.ZIP, KEY_LOCATION);
		GameConfig.instance.msg.send("amq.direct", gld, MsgSystem.ZIP, getFriendKey(account_id));
	}

	public static void notifyOnline(RabbitConfig rabbit, final long account_id, final boolean online) {

		if (!ENABLED) {
			return;
		}

		logger.debug("notifyOnline " + account_id + " " + online);

		final FriendOnlineData msg = new FriendOnlineData(account_id, online);
		GameConfig.instance.msg.send("amq.direct", msg, MsgSystem.ZIP, getFriendKey(account_id));

	}

	public static String getFriendKey(final long account_id) {
		return KEY_FRIEND_ + Long.toString(account_id);
	}
}
